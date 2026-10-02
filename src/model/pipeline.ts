// Parses `--mlir-print-ir-tree-dir` output into PassNodes. Pure: the file walk
// happens in artifacts.ts and hands us PassFileEntry records.
//
// Observed layout (IREE / LLVM 24, 2026):
//   ir/builtin_module_no-symbol-name/7_inline.mlir
//   ir/builtin_module_no-symbol-name/util_func_matmul/7_3_cse.mlir
//   ir/.../hal_executable_X/hal_executable_variant_Y/builtin_module_no-symbol-name/
//        func_func_Z/157_1_2_6_14_iree-codegen-tile-and-distribute-....mlir
// The first number is the top-level pass index; further numbers index nested
// pass instances. Files start with a header:
//   // -----// IR Dump After CSEPass: cse //----- //
// Older MLIR used a single `NNNN_PassName.mlir` prefix; both parse here.

import { PassFileEntry, PassNode } from './types';

export interface ParsedPassFileName {
  ordinalPath: number[];
  passName: string;
}

export function parsePassFileName(fileName: string): ParsedPassFileName | undefined {
  const m = /^((?:\d+[_-])+)(.+)\.mlir$/.exec(fileName);
  if (!m) {
    return undefined;
  }
  const ordinalPath = m[1].split(/[_-]/).filter((s) => s.length > 0).map(Number);
  if (ordinalPath.some((n) => !Number.isFinite(n))) {
    return undefined;
  }
  return { ordinalPath, passName: m[2] };
}

export interface DumpHeader {
  when: 'After' | 'Before';
  className: string;
  pipelineText: string;
  failed: boolean;
}

/** Parses `// -----// IR Dump After CSEPass: cse //----- //`. */
export function parseDumpHeader(line: string): DumpHeader | undefined {
  const m = /^\/\/ -----\/\/ IR Dump (After|Before) (.+?)(?: Failed)?(?:: (.+?)|\s\((.+?)\))? \/\/----- \/\/\s*$/.exec(line.trim());
  if (!m) {
    return undefined;
  }
  return {
    when: m[1] as 'After' | 'Before',
    className: m[2],
    pipelineText: (m[3] ?? m[4] ?? '').trim(),
    failed: / Failed/.test(line),
  };
}

export function compareOrdinalPaths(a: number[], b: number[]): number {
  const n = Math.min(a.length, b.length);
  for (let i = 0; i < n; i++) {
    if (a[i] !== b[i]) {
      return a[i] - b[i];
    }
  }
  // A parent pass prints after its nested passes complete, so the longer
  // (nested) path sorts first.
  return b.length - a.length;
}

// ---------------------------------------------------------------------------
// Phase inference. The tree dir does not encode compile phases, so they're
// inferred from pass names per top-level ordinal and forced to be monotonic.
// ---------------------------------------------------------------------------

export const PHASES = [
  'input', 'abi', 'preprocessing', 'global-optimization', 'dispatch-creation',
  'flow', 'stream', 'executable-sources', 'executable-configurations',
  'executable-targets', 'hal', 'vm',
] as const;

const PHASE_RULES: Array<[RegExp, (typeof PHASES)[number]]> = [
  [/^iree-(auto-input-conversion|import-|input-|sanitize-module-names)/, 'input'],
  [/^iree-abi-/, 'abi'],
  [/^iree-preprocessing-/, 'preprocessing'],
  [/^iree-global-opt-/, 'global-optimization'],
  [/^iree-dispatch-creation-/, 'dispatch-creation'],
  [/^iree-flow-(outline|annotate|deduplicate|initialize-empty|capture-dynamic|cleanup-tensor-shapes|export-benchmark)/, 'flow'],
  [/^iree-stream-/, 'stream'],
  [/^iree-hal-materialize-interfaces/, 'executable-sources'],
  [/(select-lowering-strategy|materialize-user-configs|iree-hal-configure-)/, 'executable-configurations'],
  [/^iree-hal-(conversion|link-|serialize-|resolve-export-ordinals|materialize-resource-caches|memoize-|initialize-devices|outline-memoize)|link-executables$/, 'hal'],
  [/^(iree-(codegen|llvmcpu|llvmgpu|spirv|rocdl|nvvm|vmvx)-|iree-hal-translate-|iree-convert-to-llvm)/, 'executable-targets'],
  [/^iree-vm-/, 'vm'],
];

export function classifyPass(passName: string): (typeof PHASES)[number] | undefined {
  for (const [re, phase] of PHASE_RULES) {
    if (re.test(passName)) {
      return phase;
    }
  }
  return undefined;
}

function phaseIndex(p: string): number {
  return (PHASES as readonly string[]).indexOf(p);
}

/**
 * Returns top-level ordinal -> phase. Configuration beats target-translation
 * inside the same top-level ordinal because config selection runs nested
 * under an adaptor that also contains codegen-looking prep passes.
 */
export function inferPhases(nodes: Array<{ ordinalPath: number[]; passName: string }>): Map<number, string> {
  const byTop = new Map<number, Array<{ ordinalPath: number[]; passName: string }>>();
  for (const n of nodes) {
    const t = n.ordinalPath[0];
    const list = byTop.get(t);
    if (list) {
      list.push(n);
    } else {
      byTop.set(t, [n]);
    }
  }
  const tops = [...byTop.keys()].sort((a, b) => a - b);
  const result = new Map<number, string>();
  let current: string = 'start';
  for (const t of tops) {
    const members = byTop.get(t) ?? [];
    const nested = members.filter((m) => m.ordinalPath.length > 1).map((m) => classifyPass(m.passName));
    const top = members.filter((m) => m.ordinalPath.length === 1).map((m) => classifyPass(m.passName)).find((c) => c !== undefined);
    let cls: string | undefined;
    if (nested.includes('executable-configurations')) {
      cls = 'executable-configurations';
    } else if (top !== undefined) {
      cls = top;
    } else {
      // Majority vote over nested passes.
      const votes = new Map<string, number>();
      for (const c of nested) {
        if (c) {
          votes.set(c, (votes.get(c) ?? 0) + 1);
        }
      }
      let best = 0;
      for (const [c, v] of votes) {
        if (v > best) {
          best = v;
          cls = c;
        }
      }
    }
    if (cls !== undefined && phaseIndex(cls) > phaseIndex(current)) {
      current = cls;
    }
    result.set(t, current);
  }
  return result;
}

// ---------------------------------------------------------------------------
// Node construction
// ---------------------------------------------------------------------------

export function buildPassNodes(entries: PassFileEntry[]): PassNode[] {
  interface Pending { e: PassFileEntry; scope: string[]; parsed?: ParsedPassFileName; fileName: string }
  const pending: Pending[] = entries.map((e) => {
    const parts = e.relPath.split('/').filter((p) => p.length > 0);
    const fileName = parts[parts.length - 1] ?? e.relPath;
    return { e, scope: parts.slice(0, -1), parsed: parsePassFileName(fileName), fileName };
  });

  // Files that don't match the pattern: order by mtime after the parsed ones.
  const parsed = pending.filter((p) => p.parsed !== undefined);
  const unparsed = pending.filter((p) => p.parsed === undefined).sort((a, b) => a.e.mtimeMs - b.e.mtimeMs);
  parsed.sort((a, b) => {
    const c = compareOrdinalPaths(a.parsed!.ordinalPath, b.parsed!.ordinalPath);
    return c !== 0 ? c : a.e.relPath.localeCompare(b.e.relPath);
  });
  const maxTop = parsed.reduce((m, p) => Math.max(m, p.parsed!.ordinalPath[0]), -1);
  const ordered = [
    ...parsed.map((p) => ({ ...p, ordinalPath: p.parsed!.ordinalPath, passName: p.parsed!.passName })),
    ...unparsed.map((p, i) => ({ ...p, ordinalPath: [maxTop + 1 + i], passName: p.fileName.replace(/\.mlir$/, '') })),
  ];

  const phases = inferPhases(ordered);
  // Every proper prefix of a nested ordinal path is a container instance.
  const containers = new Set<string>();
  for (const p of ordered) {
    for (let k = 1; k < p.ordinalPath.length; k++) {
      containers.add(p.ordinalPath.slice(0, k).join('_'));
    }
  }
  const lastHashByScope = new Map<string, string>();
  return ordered.map((p, i) => {
    const scopeKey = p.scope.join('/');
    const prev = lastHashByScope.get(scopeKey);
    lastHashByScope.set(scopeKey, p.e.hash);
    const header = p.e.header ? parseDumpHeader(p.e.header) : undefined;
    return {
      ordinal: i,
      ordinalPath: p.ordinalPath,
      passName: p.passName,
      className: header?.className,
      pipelineText: header?.pipelineText || undefined,
      scope: p.scope,
      filePath: p.e.absPath,
      sizeBytes: p.e.sizeBytes,
      changed: prev === undefined ? true : prev !== p.e.hash,
      // Adaptor dumps only repeat their nested passes' effect, even when those
      // weren't dumped under their own ordinal.
      container: containers.has(p.ordinalPath.join('_')) || p.passName === 'iree-op-pipeline-adaptor',
      hash: p.e.hash,
      phase: phases.get(p.ordinalPath[0]) ?? 'start',
    };
  });
}

/** Previous node in the same scope, by execution order. */
export function previousInScope(nodes: PassNode[], node: PassNode): PassNode | undefined {
  const key = node.scope.join('/');
  let prev: PassNode | undefined;
  for (const n of nodes) {
    if (n === node || n.filePath === node.filePath) {
      return prev;
    }
    if (n.scope.join('/') === key) {
      prev = n;
    }
  }
  return undefined;
}

// ---------------------------------------------------------------------------
// Scope labels
// ---------------------------------------------------------------------------

// Tree-dir segments are `<op name with . -> _>_<symbol or no-symbol-name>`.
// Op names containing '.' are ambiguous, so known ops are matched first.
const KNOWN_SCOPE_OPS = [
  'hal.executable.variant', 'hal.executable', 'flow.executable', 'stream.executable',
  'builtin.module', 'func.func', 'util.func', 'util.initializer', 'llvm.func',
  'vm.module', 'vm.func', 'vm.initializer', 'gpu.module', 'gpu.func', 'spirv.module',
];

export interface ScopeSegment {
  op: string;
  symbol?: string;
}

export function parseScopeSegment(seg: string): ScopeSegment {
  for (const op of KNOWN_SCOPE_OPS) {
    const prefix = op.replace(/\./g, '_') + '_';
    if (seg.startsWith(prefix)) {
      const sym = seg.slice(prefix.length);
      return { op, symbol: sym === 'no-symbol-name' ? undefined : sym };
    }
  }
  const m = /^([a-z0-9]+)_([a-z0-9]+)_(.*)$/.exec(seg);
  if (m) {
    return { op: `${m[1]}.${m[2]}`, symbol: m[3] === 'no-symbol-name' ? undefined : m[3] };
  }
  return { op: seg };
}

export function formatScopeSegment(seg: string): string {
  const s = parseScopeSegment(seg);
  return s.symbol ? `${s.op} @${s.symbol}` : s.op;
}

// ---------------------------------------------------------------------------
// Repro command
// ---------------------------------------------------------------------------

/** Op name of the first operation in a dump file body (after the header). */
export function topLevelOpName(fileText: string): string | undefined {
  for (const raw of fileText.split(/\r?\n/, 50)) {
    const line = raw.trim();
    if (line.length === 0 || line.startsWith('//') || line.startsWith('#') || line.startsWith('!')) {
      continue;
    }
    if (/^module\b/.test(line)) {
      return 'builtin.module';
    }
    const m = /^(?:%[\w#:, ]+=\s*)?"?([a-z_][\w]*\.[\w.]+)"?/.exec(line);
    return m ? m[1] : undefined;
  }
  return undefined;
}

export interface ReproInput {
  optPath: string;
  /** Input IR file for iree-opt. */
  prevFile: string;
  node: PassNode;
  /** Op name at the top of prevFile. */
  anchorOp: string | undefined;
  /**
   * Explicit op nesting under the implicit top-level module, outermost first
   * (e.g. ['hal.executable', 'hal.executable.variant', 'builtin.module']).
   * Overrides anchorOp; used for wrapped executable repros.
   */
  nesting?: string[];
}

function shellQuote(s: string): string {
  return /^[\w@%+=:,./-]+$/.test(s) ? s : `'${s.replace(/'/g, `'\\''`)}'`;
}

/**
 * Emits an iree-opt command that runs just this pass on the previous IR in the
 * same scope. A scope file whose top-level op isn't builtin.module is parsed
 * by iree-opt into an implicit module, so the pass is nested under it.
 *
 * TODO(verify): passes that read global options (target devices etc.) may
 * also need the original target flags appended.
 */
/**
 * Drops pass options that print a process-local pointer and can't be parsed
 * back, e.g. IREE's `target-registry=1`.
 *
 * TODO(verify): only target-registry has been seen (IREE, LLVM 24). Check a
 * failing repro's "failed to add `pass` with options" error for others.
 */
export function sanitizePipelineText(text: string): string {
  return text
    .replace(/(\{|\s)target-registry=\S+?(?=[\s}])/g, '$1')
    .replace(/\{\s*\}/g, '')
    .replace(/\{\s+/g, '{')
    .replace(/\s+\}/g, '}');
}

export function buildReproCommand(r: ReproInput): string {
  const pass = sanitizePipelineText(r.node.pipelineText ?? r.node.passName);
  const nesting = r.nesting ?? (r.anchorOp === undefined || r.anchorOp === 'builtin.module' ? [] : [r.anchorOp]);
  const pipeline = `builtin.module(${nesting.reduceRight((inner, op) => `${op}(${inner})`, pass)})`;
  const parts = [shellQuote(r.optPath), shellQuote(r.prevFile), shellQuote(`--pass-pipeline=${pipeline}`)];
  let cmd = parts.join(' ');
  if (nesting[0] === 'hal.executable.variant') {
    cmd = `# NOTE: hal.executable.variant must be nested in a hal.executable; wrap the input before running.\n${cmd}`;
  }
  return cmd;
}

function stripHeader(text: string): string[] {
  const lines = text.split(/\r?\n/);
  while (lines.length > 0 && lines[0].startsWith('//')) {
    lines.shift();
  }
  while (lines.length > 0 && lines[lines.length - 1].trim() === '') {
    lines.pop();
  }
  return lines;
}

const indent = (lines: string[], n: number) => lines.map((l) => (l.length > 0 ? ' '.repeat(n) + l : l));

/** [start, end] line indices of the block opened at `start` and closed by `closer`. */
function findBlock(lines: string[], open: RegExp, closer: string, from = 0, to = lines.length): [number, number] | undefined {
  for (let i = from; i < to; i++) {
    if (open.test(lines[i])) {
      for (let j = i + 1; j < to; j++) {
        if (lines[j] === closer) {
          return [i, j];
        }
      }
      return undefined;
    }
  }
  return undefined;
}

export interface WrappedRepro {
  text: string;
  nesting: string[];
}

/**
 * Passes that run inside a hal.executable.variant usually need the variant's
 * target attribute, which a module- or function-scope dump doesn't carry.
 * This rebuilds a runnable input: the variant (from its nearest dump) with its
 * inner module (or one function in it) replaced by the scope dump, wrapped in
 * a hal.executable. Textual only: relies on the printer's 2-space indentation
 * and alias-free nested dumps. Returns undefined when the shape isn't found.
 */
export function wrapInExecutable(
  variantDump: string | undefined,
  prevDump: string,
  prevAnchor: string | undefined,
  executableSym: string,
  funcSym?: string,
): WrappedRepro | undefined {
  const prev = stripHeader(prevDump);
  if (prev.length === 0) {
    return undefined;
  }
  // The `module` shorthand only parses at the top level; nested it must be spelled out.
  if (/^module\b/.test(prev[0])) {
    prev[0] = prev[0].replace(/^module\b/, 'builtin.module');
  }
  const wrap = (body: string[]) => [`hal.executable private @${executableSym} {`, ...indent(body, 2), '}', ''].join('\n');
  if (prevAnchor === 'hal.executable.variant') {
    return { text: wrap(prev), nesting: ['hal.executable', 'hal.executable.variant'] };
  }
  const variant = variantDump !== undefined ? stripHeader(variantDump) : [];
  if (!/^hal\.executable\.variant\b/.test(variant[0] ?? '')) {
    return undefined;
  }
  const mod = findBlock(variant, /^ {2}(builtin\.)?module\b.*\{\s*$/, '  }');
  if (!mod) {
    return undefined;
  }
  if (prevAnchor === 'builtin.module') {
    return {
      text: wrap([...variant.slice(0, mod[0]), ...indent(prev, 2), ...variant.slice(mod[1] + 1)]),
      nesting: ['hal.executable', 'hal.executable.variant', 'builtin.module'],
    };
  }
  if (prevAnchor === 'func.func' && funcSym) {
    const sym = funcSym.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const fn = findBlock(variant, new RegExp(`^ {4}func\\.func\\b.*@${sym}\\(`), '    }', mod[0], mod[1]);
    if (!fn) {
      return undefined;
    }
    return {
      text: wrap([...variant.slice(0, fn[0]), ...indent(prev, 4), ...variant.slice(fn[1] + 1)]),
      nesting: ['hal.executable', 'hal.executable.variant', 'builtin.module', 'func.func'],
    };
  }
  return undefined;
}

/** Index of the hal.executable.variant segment enclosing (or equal to) the last scope segment. */
export function enclosingVariantIndex(scope: string[]): number | undefined {
  for (let i = scope.length - 1; i >= 1; i--) {
    if (scope[i].startsWith('hal_executable_variant_') && scope[i - 1].startsWith('hal_executable_')) {
      return i;
    }
  }
  return undefined;
}

/**
 * Function-level dumps directly under the root module reference module-level
 * symbols (globals, callees). Splices the dump back into the nearest root
 * module dump in place of the op with the same name and symbol.
 */
export function spliceIntoModule(moduleDump: string, prevDump: string, scopeSegment: string): string | undefined {
  const mod = stripHeader(moduleDump);
  const prev = stripHeader(prevDump);
  // Root dumps start with attribute/type alias definitions.
  const first = mod.findIndex((l) => !/^[#!]/.test(l) && l.trim().length > 0);
  if (first < 0 || !/^module\b/.test(mod[first]) || prev.length === 0) {
    return undefined;
  }
  const { op, symbol } = parseScopeSegment(scopeSegment);
  const esc = (x: string) => x.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const open = symbol
    ? new RegExp(`^ {2}${esc(op)}\\b.*@${esc(symbol)}\\(`)
    : new RegExp(`^ {2}${esc(op)}\\b`);
  // Candidate blocks; anonymous ops (util.initializer) can occur several
  // times, so pick the block whose lines overlap the dump the most.
  const blocks: Array<[number, number]> = [];
  for (let from = 0; from < mod.length;) {
    const b = findBlock(mod, open, '  }', from);
    if (!b) {
      break;
    }
    blocks.push(b);
    from = b[1] + 1;
  }
  if (blocks.length === 0) {
    return undefined;
  }
  const prevSet = new Set(prev.map((l) => l.trim()));
  const score = ([a, b]: [number, number]) => mod.slice(a, b + 1).filter((l) => prevSet.has(l.trim())).length;
  const blk = blocks.reduce((best, b) => (score(b) > score(best) ? b : best));
  return [...mod.slice(0, blk[0]), ...indent(prev, 2), ...mod.slice(blk[1] + 1), ''].join('\n');
}

export interface PreparedRepro {
  command: string;
  /** When set, the caller writes this text to `inputPath` before use. */
  wrappedInput?: { text: string; fileName: string };
  /** Why a repro couldn't be built, for the user. */
  problem?: string;
}

/**
 * Plans a repro for `node`: finds the previous IR in its scope and, for passes
 * inside a hal.executable.variant, wraps it so iree-opt sees the target.
 * `inputPathFor(fileName)` maps a wrapped-input file name to where the caller
 * will write it.
 */
export async function prepareRepro(
  nodes: PassNode[],
  node: PassNode,
  optPath: string,
  readText: (file: string) => Promise<string | undefined>,
  inputPathFor: (fileName: string) => string,
  /** The compiled source file: the input to the very first pass. */
  originalInput?: string,
): Promise<PreparedRepro> {
  if (node.passName === 'iree-op-pipeline-adaptor') {
    return { command: '', problem: 'iree-op-pipeline-adaptor is an internal wrapper around a nested pipeline; copy a repro for one of its nested passes instead.' };
  }
  // Input IR: the previous dump in the same scope, else the latest earlier
  // dump of the nearest enclosing scope (which contains this scope's op).
  let src = previousInScope(nodes, node);
  let srcDepth = node.scope.length;
  for (let k = node.scope.length - 1; !src && k >= 1; k--) {
    const key = node.scope.slice(0, k).join('/');
    const earlier = nodes.filter((n) => n.ordinal < node.ordinal && n.scope.join('/') === key);
    if (earlier.length > 0) {
      src = earlier[earlier.length - 1];
      srcDepth = k;
    }
  }
  if (!src) {
    const isFirst = node.scope.length === 1 && !nodes.some((n) => n.ordinal < node.ordinal);
    if (isFirst && originalInput) {
      return { command: buildReproCommand({ optPath, prevFile: originalInput, node, anchorOp: 'builtin.module', nesting: [] }) };
    }
    return { command: '', problem: `No earlier IR dump contains the scope of ${node.passName}.` };
  }
  const srcText = await readText(src.filePath);
  if (srcText === undefined) {
    return { command: '', problem: `Could not read ${src.filePath}.` };
  }
  const anchor = topLevelOpName(srcText);
  // Ops between the input's top op and the pass's scope op.
  const inner = node.scope.slice(srcDepth).map((seg) => parseScopeSegment(seg).op);

  const srcScope = node.scope.slice(0, srcDepth);
  const vi = enclosingVariantIndex(srcScope);
  if (vi !== undefined && vi >= 1) {
    const variantKey = srcScope.slice(0, vi + 1).join('/');
    const variantDumps = nodes.filter((n) => n.scope.join('/') === variantKey);
    const before = variantDumps.filter((n) => n.ordinal < node.ordinal);
    const vnode = before[before.length - 1] ?? variantDumps[0];
    const exe = parseScopeSegment(srcScope[vi - 1]).symbol;
    const fnSym = parseScopeSegment(srcScope[srcScope.length - 1]).symbol;
    const vtext = vnode && anchor !== 'hal.executable.variant' ? await readText(vnode.filePath) : undefined;
    const wrapped = exe ? wrapInExecutable(vtext, srcText, anchor, exe, fnSym) : undefined;
    if (wrapped) {
      const fileName = `${node.ordinalPath.join('_')}_${node.passName}.input.mlir`;
      return {
        command: buildReproCommand({ optPath, prevFile: inputPathFor(fileName), node, anchorOp: anchor, nesting: [...wrapped.nesting, ...inner] }),
        wrappedInput: { text: wrapped.text, fileName },
      };
    }
  }
  const base = anchor === undefined || anchor === 'builtin.module' ? [] : [anchor];
  if (srcScope.length === 2 && anchor !== 'builtin.module') {
    const rootKey = srcScope[0];
    const roots = nodes.filter((n) => n.ordinal < node.ordinal && n.scope.length === 1 && n.scope[0] === rootKey);
    const root = roots[roots.length - 1];
    const rootText = root ? await readText(root.filePath) : undefined;
    const spliced = rootText !== undefined ? spliceIntoModule(rootText, srcText, srcScope[1]) : undefined;
    if (spliced) {
      const fileName = `${node.ordinalPath.join('_')}_${node.passName}.input.mlir`;
      return {
        command: buildReproCommand({ optPath, prevFile: inputPathFor(fileName), node, anchorOp: anchor, nesting: [...base, ...inner] }),
        wrappedInput: { text: spliced, fileName },
      };
    }
  }
  return { command: buildReproCommand({ optPath, prevFile: src.filePath, node, anchorOp: anchor, nesting: [...base, ...inner] }) };
}

// ---------------------------------------------------------------------------
// Grouping for the tree view: phase -> (module-scope passes | nested scopes)
// ---------------------------------------------------------------------------

export interface ScopeGroup {
  kind: 'scope';
  /** Scope path key ('/'-joined). */
  key: string;
  label: string;
  /** Formatted parent segments. */
  parent: string;
  passes: PassNode[];
  totalPasses: number;
  changedPasses: number;
}

export interface PhaseGroup {
  kind: 'phase';
  phase: string;
  items: Array<PassNode | ScopeGroup>;
  totalPasses: number;
  changedPasses: number;
  wallMs: number;
}

/**
 * The first scope segment is the root module (the whole program); passes on
 * it are shown directly under the phase, deeper scopes as folders.
 */
export function groupPasses(nodes: PassNode[], showUnchanged: boolean): PhaseGroup[] {
  const phases: PhaseGroup[] = [];
  const phaseByName = new Map<string, PhaseGroup>();
  const scopeByKey = new Map<string, ScopeGroup>();
  for (const n of nodes) {
    let pg = phaseByName.get(n.phase);
    if (!pg) {
      pg = { kind: 'phase', phase: n.phase, items: [], totalPasses: 0, changedPasses: 0, wallMs: 0 };
      phaseByName.set(n.phase, pg);
      phases.push(pg);
    }
    pg.totalPasses++;
    if (n.changed && !n.container) {
      pg.changedPasses++;
    }
    // Containers only repeat their nested passes' changes: hide them with the
    // unchanged passes.
    const visible = showUnchanged || (n.changed && !n.container);
    const nested = n.scope.slice(1);
    if (nested.length === 0) {
      if (visible) {
        pg.items.push(n);
      }
      if (n.ordinalPath.length === 1) {
        pg.wallMs += n.wallMs ?? 0;
      }
      continue;
    }
    const key = `${n.phase}|${n.scope.join('/')}`;
    let sg = scopeByKey.get(key);
    if (!sg) {
      sg = {
        kind: 'scope',
        key,
        label: formatScopeSegment(nested[nested.length - 1]),
        parent: nested.slice(0, -1).map((s) => parseScopeSegment(s).symbol ?? parseScopeSegment(s).op).join(' › '),
        passes: [],
        totalPasses: 0,
        changedPasses: 0,
      };
      scopeByKey.set(key, sg);
      pg.items.push(sg);
    }
    sg.totalPasses++;
    if (n.changed && !n.container) {
      sg.changedPasses++;
    }
    if (visible) {
      sg.passes.push(n);
    }
  }
  for (const pg of phases) {
    pg.items = pg.items.filter((i) => !('kind' in i) || i.passes.length > 0);
  }
  return phases.filter((p) => p.items.length > 0);
}
