// Targeted extraction of lowering_config / translation_info / iteration
// domains from dumped executable IR. This is NOT an MLIR parser: it pulls out
// specific attributes with a balanced-delimiter scanner and regexes, and every
// function returns undefined (or an empty result) instead of throwing.

import {
  DimRef, DispatchInfo, LoweringConfig, OperandInfo, TargetHardware, TileLevel, TranslationInfo,
} from './types';

// ---------------------------------------------------------------------------
// Scanning primitives
// ---------------------------------------------------------------------------

const OPEN: Record<string, string> = { '<': '>', '[': ']', '{': '}', '(': ')' };
const CLOSE = new Set(['>', ']', '}', ')']);

/**
 * Given text[start] is an opener, returns the index one past its matching
 * closer, or undefined if unbalanced. Understands string literals and treats
 * `->` (affine_map arrows) and `>=` as non-closers.
 */
export function scanBalanced(text: string, start: number): number | undefined {
  if (!(text[start] in OPEN)) {
    return undefined;
  }
  const stack: string[] = [];
  for (let i = start; i < text.length; i++) {
    const c = text[i];
    if (c === '"') {
      i = skipString(text, i);
      if (i < 0) {
        return undefined;
      }
      continue;
    }
    if (c === '>' && (text[i - 1] === '-' || text[i + 1] === '=')) {
      continue;
    }
    if (c === '<' && text[i + 1] === '=') {
      continue;
    }
    if (c in OPEN) {
      stack.push(OPEN[c]);
    } else if (CLOSE.has(c)) {
      if (stack.pop() !== c) {
        return undefined;
      }
      if (stack.length === 0) {
        return i + 1;
      }
    }
  }
  return undefined;
}

function skipString(text: string, i: number): number {
  for (let j = i + 1; j < text.length; j++) {
    if (text[j] === '\\') {
      j++;
    } else if (text[j] === '"') {
      return j;
    }
  }
  return -1;
}

/** Splits on `sep` at nesting depth 0. */
export function splitTopLevel(text: string, sep: string): string[] {
  const out: string[] = [];
  let depth = 0;
  let last = 0;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (c === '"') {
      const e = skipString(text, i);
      if (e < 0) {
        break;
      }
      i = e;
      continue;
    }
    if (c === '>' && (text[i - 1] === '-' || text[i + 1] === '=')) {
      continue;
    }
    if (c in OPEN) {
      depth++;
    } else if (CLOSE.has(c)) {
      depth--;
    } else if (depth === 0 && text.startsWith(sep, i)) {
      out.push(text.slice(last, i));
      last = i + sep.length;
    }
  }
  out.push(text.slice(last));
  return out.map((s) => s.trim()).filter((s) => s.length > 0);
}

/**
 * Reads one attribute value starting at `start` (after `key = `): a `#alias`,
 * `#dialect.attr<...>`, `[...]`, `{...}`, `"..."` or a bare token.
 */
export function readValue(text: string, start: number): string | undefined {
  let i = start;
  while (i < text.length && text[i] === ' ') {
    i++;
  }
  if (i >= text.length) {
    return undefined;
  }
  const c = text[i];
  if (c in OPEN) {
    const e = scanBalanced(text, i);
    return e === undefined ? undefined : text.slice(i, e);
  }
  if (c === '"') {
    const e = skipString(text, i);
    return e < 0 ? undefined : text.slice(i, e + 1);
  }
  const m = /^[#!]?[\w.$-]+/.exec(text.slice(i));
  if (!m) {
    return undefined;
  }
  let end = i + m[0].length;
  if (text[end] === '<') {
    const e = scanBalanced(text, end);
    if (e === undefined) {
      return undefined;
    }
    end = e;
  }
  return text.slice(i, end);
}

/** Finds `key = value` (word-bounded) and returns the value text. */
export function findAttr(text: string, key: string, from = 0): string | undefined {
  const re = new RegExp(`(?:^|[^\\w.])${key.replace(/[.$]/g, '\\$&')}\\s*=\\s*`, 'g');
  re.lastIndex = from;
  const m = re.exec(text);
  return m ? readValue(text, m.index + m[0].length) : undefined;
}

/** Body between the outermost `<` and `>` of `#dialect.attr<...>`. */
export function attrBody(attr: string): string | undefined {
  const lt = attr.indexOf('<');
  if (lt < 0) {
    return undefined;
  }
  const e = scanBalanced(attr, lt);
  return e === undefined ? undefined : attr.slice(lt + 1, e - 1);
}

/** Parses `key = value, key = value` (optionally wrapped in `{}`) into pairs. */
export function parseKeyValues(body: string): Array<[string, string]> {
  let b = body.trim();
  if (b.startsWith('{')) {
    const e = scanBalanced(b, 0);
    if (e === b.length) {
      b = b.slice(1, -1);
    }
  }
  const out: Array<[string, string]> = [];
  for (const part of splitTopLevel(b, ',')) {
    const m = /^([\w.$-]+)\s*=\s*([\s\S]+)$/.exec(part);
    if (m) {
      out.push([m[1], m[2].trim()]);
    }
  }
  return out;
}

/**
 * Parses `[128, 128, 0]`. Scalable CPU sizes like `[8, [16], 0]` contribute
 * their base size.
 */
export function parseIntList(text: string): number[] | undefined {
  const t = text.trim();
  if (!t.startsWith('[') || scanBalanced(t, 0) !== t.length) {
    return undefined;
  }
  const inner = t.slice(1, -1).trim();
  if (inner.length === 0) {
    return [];
  }
  const out: number[] = [];
  for (const part of splitTopLevel(inner, ',')) {
    let p = part;
    const scal = /^\[\s*(-?\d+)\s*\]$/.exec(p);
    if (scal) {
      p = scal[1];
    }
    const m = /^(-?\d+)(?:\s*:\s*\w+)?$/.exec(p);
    if (!m) {
      return undefined;
    }
    out.push(Number(m[1]));
  }
  return out;
}

export function parseNestedIntLists(text: string): number[][] | undefined {
  const t = text.trim();
  if (!t.startsWith('[') || scanBalanced(t, 0) !== t.length) {
    return undefined;
  }
  const out: number[][] = [];
  for (const part of splitTopLevel(t.slice(1, -1), ',')) {
    const l = parseIntList(part);
    if (!l) {
      return undefined;
    }
    out.push(l);
  }
  return out;
}

// ---------------------------------------------------------------------------
// Aliases
// ---------------------------------------------------------------------------

/** `#name = value` definitions at the start of a line. */
export function parseAliases(text: string): Map<string, string> {
  const map = new Map<string, string>();
  const re = /^(#[\w$.-]+)\s*=\s*/gm;
  for (let m = re.exec(text); m; m = re.exec(text)) {
    const v = readValue(text, m.index + m[0].length);
    if (v !== undefined) {
      map.set(m[1], v);
    }
  }
  return map;
}

export function resolveAlias(value: string, aliases: Map<string, string>): string {
  let v = value.trim();
  for (let i = 0; i < 8 && /^#[\w$.-]+$/.test(v) && aliases.has(v); i++) {
    v = aliases.get(v) ?? v;
  }
  return v;
}

// ---------------------------------------------------------------------------
// lowering_config
// ---------------------------------------------------------------------------

const GPU_LEVEL_ORDER = ['workgroup', 'subgroup', 'reduction', 'partial_reduction', 'thread', 'lane'];
const CPU_LEVEL_ORDER = [
  'distribution', 'cache_parallel', 'cache_reduction',
  'vector_common_parallel', 'vector_reduction', 'vector_inner_parallel',
];

export function parseLoweringConfig(attr: string): LoweringConfig | undefined {
  const raw = attr.trim();
  const m = /^#(iree_\w+)\.lowering_config</.exec(raw);
  if (!m) {
    return undefined;
  }
  const body = attrBody(raw);
  if (body === undefined) {
    return undefined;
  }
  const kv = parseKeyValues(body);
  const dialect = m[1];

  if (dialect === 'iree_codegen') {
    const ts = kv.find(([k]) => k === 'tile_sizes');
    if (!ts) {
      return undefined;
    }
    const lists = parseNestedIntLists(ts[1]);
    if (!lists) {
      return undefined;
    }
    return { form: 'codegen', levels: lists.map((sizes, i) => ({ name: `level ${i}`, sizes })), raw };
  }

  const order = dialect === 'iree_gpu' ? GPU_LEVEL_ORDER : dialect === 'iree_cpu' ? CPU_LEVEL_ORDER : undefined;
  if (!order) {
    return undefined;
  }
  const levels: TileLevel[] = [];
  for (const name of order) {
    const entry = kv.find(([k]) => k === name);
    if (!entry) {
      continue;
    }
    const sizes = parseIntList(entry[1]);
    if (sizes) {
      levels.push({ name, sizes });
    }
  }
  if (levels.length === 0) {
    return undefined;
  }
  return { form: dialect === 'iree_gpu' ? 'gpu' : 'cpu', levels, raw };
}

// ---------------------------------------------------------------------------
// translation_info
// ---------------------------------------------------------------------------

export function parseTranslationInfo(attr: string): TranslationInfo | undefined {
  const raw = attr.trim();
  if (!/^#iree_codegen\.translation_info</.test(raw)) {
    return undefined;
  }
  const body = attrBody(raw);
  if (body === undefined) {
    return undefined;
  }
  const info: TranslationInfo = { raw };
  const p = findAttr(body, 'pipeline');
  if (p !== undefined) {
    // `#iree_cpu.pipeline<DoubleTilingExpert>` or bare `LLVMGPUTileAndFuse`.
    const inner = p.includes('<') ? attrBody(p) : p;
    info.pipeline = (inner ?? p).trim();
  }
  const wg = findAttr(body, 'workgroup_size');
  if (wg !== undefined) {
    info.workgroupSize = parseIntList(wg);
  }
  const sg = findAttr(body, 'subgroup_size');
  if (sg !== undefined && /^\d+/.test(sg)) {
    info.subgroupSize = parseInt(sg, 10);
  }
  return info;
}

// ---------------------------------------------------------------------------
// Types and affine maps
// ---------------------------------------------------------------------------

export interface ShapedType {
  shape: number[];
  elementType: string;
}

export function parseShapedType(t: string): ShapedType | undefined {
  const s = t.trim();
  const m = /^(tensor|memref|vector|!iree_tensor_ext\.dispatch\.tensor<\w+:tensor)</.exec(s);
  if (!m) {
    // Scalar operand (e.g. linalg.fill's value).
    return /^[a-z]\w*$/.test(s) ? { shape: [], elementType: s } : undefined;
  }
  const lt = s.indexOf('<', m[0].length - 1);
  const e = scanBalanced(s, lt);
  if (e === undefined) {
    return undefined;
  }
  const first = splitTopLevel(s.slice(lt + 1, e - 1), ',')[0];
  if (first === undefined) {
    return undefined;
  }
  const parts = first.split('x').map((p) => p.trim());
  const elementType = parts.pop();
  if (!elementType) {
    return undefined;
  }
  const shape: number[] = [];
  for (const p of parts) {
    if (p === '?') {
      shape.push(-1);
    } else if (/^\d+$/.test(p)) {
      shape.push(Number(p));
    } else {
      // e.g. scalable vector dims `[4]`
      const sc = /^\[(\d+)\]$/.exec(p);
      if (!sc) {
        return undefined;
      }
      shape.push(Number(sc[1]));
    }
  }
  return { shape, elementType };
}

export function elementBytes(t: string): number | undefined {
  if (t === 'index') {
    return 8;
  }
  if (t === 'tf32') {
    return 4;
  }
  const c = /^complex<(?:f|bf|i)(\d+)>$/.exec(t);
  if (c) {
    return (2 * Number(c[1])) / 8;
  }
  // i32, si8, ui16, f16, bf16, f8E4M3FN, f4E2M1FN, ...
  const m = /^(?:i|si|ui|f|bf)(\d+)(?:E\w*)?$/.exec(t);
  if (!m) {
    return undefined;
  }
  const bits = Number(m[1]);
  return bits === 1 ? 1 : bits / 8;
}

export interface AffineMap {
  numDims: number;
  results: DimRef[];
}

/** `affine_map<(d0, d1, d2) -> (d0, d2)>`; non-dim results become -1. */
export function parseAffineMap(text: string): AffineMap | undefined {
  const m = /affine_map<\s*\(([^)]*)\)(?:\[[^\]]*\])?\s*->\s*\(([\s\S]*)\)\s*>$/.exec(text.trim());
  if (!m) {
    return undefined;
  }
  const dims = m[1].split(',').map((s) => s.trim()).filter((s) => s.length > 0);
  const results: DimRef[] = [];
  for (const expr of splitTopLevel(m[2], ',')) {
    results.push(parseAffineExpr(expr));
  }
  return { numDims: dims.length, results };
}

function parseAffineExpr(expr: string): DimRef {
  const e = expr.replace(/\s+/g, ' ').trim();
  const plain = /^d(\d+)$/.exec(e);
  if (plain) {
    return Number(plain[1]);
  }
  // d1 * 2 + d4 * 3  |  d1 + d4  (convolution windows)
  const win = /^d(\d+)(?: \* (\d+))? \+ d(\d+)(?: \* (\d+))?$/.exec(e);
  if (win) {
    return { out: Number(win[1]), stride: win[2] ? Number(win[2]) : 1, win: Number(win[3]), dilation: win[4] ? Number(win[4]) : 1 };
  }
  return -1;
}

// ---------------------------------------------------------------------------
// Named-op iteration spaces (linalg's canonical loop order)
// ---------------------------------------------------------------------------

type W = { out: number; win: number };
interface NamedSpec { iter: string; maps: Array<Array<number | W>>; names?: string[] }

const P = 'parallel';
const R = 'reduction';

const NAMED_OPS: Record<string, NamedSpec> = {
  'linalg.matmul': { iter: 'ppr', maps: [[0, 2], [2, 1], [0, 1]], names: ['M', 'N', 'K'] },
  'linalg.matmul_transpose_a': { iter: 'ppr', maps: [[2, 0], [2, 1], [0, 1]], names: ['M', 'N', 'K'] },
  'linalg.matmul_transpose_b': { iter: 'ppr', maps: [[0, 2], [1, 2], [0, 1]], names: ['M', 'N', 'K'] },
  'linalg.batch_matmul': { iter: 'pppr', maps: [[0, 1, 3], [0, 3, 2], [0, 1, 2]], names: ['B', 'M', 'N', 'K'] },
  'linalg.batch_matmul_transpose_b': { iter: 'pppr', maps: [[0, 1, 3], [0, 2, 3], [0, 1, 2]], names: ['B', 'M', 'N', 'K'] },
  'linalg.matvec': { iter: 'pr', maps: [[0, 1], [1], [0]] },
  'linalg.vecmat': { iter: 'pr', maps: [[1], [1, 0], [0]] },
  'linalg.dot': { iter: 'r', maps: [[0], [0], []] },
  // (n, oh, ow, f, kh, kw, c)
  'linalg.conv_2d_nhwc_hwcf': { iter: 'pppprrr', maps: [[0, { out: 1, win: 4 }, { out: 2, win: 5 }, 6], [4, 5, 6, 3], [0, 1, 2, 3]], names: ['N', 'OH', 'OW', 'F', 'KH', 'KW', 'C'] },
  'linalg.conv_2d_nhwc_fhwc': { iter: 'pppprrr', maps: [[0, { out: 1, win: 4 }, { out: 2, win: 5 }, 6], [3, 4, 5, 6], [0, 1, 2, 3]], names: ['N', 'OH', 'OW', 'F', 'KH', 'KW', 'C'] },
  // (n, f, oh, ow, c, kh, kw)
  'linalg.conv_2d_nchw_fchw': { iter: 'pppprrr', maps: [[0, 4, { out: 2, win: 5 }, { out: 3, win: 6 }], [1, 4, 5, 6], [0, 1, 2, 3]], names: ['N', 'F', 'OH', 'OW', 'C', 'KH', 'KW'] },
  // (n, oh, ow, c, kh, kw)
  'linalg.depthwise_conv_2d_nhwc_hwc': { iter: 'pppprr', maps: [[0, { out: 1, win: 4 }, { out: 2, win: 5 }, 3], [4, 5, 3], [0, 1, 2, 3]], names: ['N', 'OH', 'OW', 'C', 'KH', 'KW'] },
};

const POOLING_NHWC: NamedSpec = { iter: 'pppprr', maps: [[0, { out: 1, win: 4 }, { out: 2, win: 5 }, 3], [4, 5], [0, 1, 2, 3]], names: ['N', 'OH', 'OW', 'C', 'KH', 'KW'] };
const POOLING_NCHW: NamedSpec = { iter: 'pppprr', maps: [[0, 1, { out: 2, win: 4 }, { out: 3, win: 5 }], [4, 5], [0, 1, 2, 3]], names: ['N', 'C', 'OH', 'OW', 'KH', 'KW'] };

const ELEMENTWISE = new Set([
  'add', 'sub', 'mul', 'div', 'div_unsigned', 'max', 'min', 'exp', 'log', 'abs', 'ceil', 'floor',
  'negf', 'copy', 'elementwise', 'square', 'sqrt', 'rsqrt', 'tanh', 'erf', 'powf', 'select', 'reciprocal', 'round',
]);

function namedSpec(opName: string): NamedSpec | undefined {
  if (NAMED_OPS[opName]) {
    return NAMED_OPS[opName];
  }
  if (/^linalg\.pooling_nhwc_/.test(opName)) {
    return POOLING_NHWC;
  }
  if (/^linalg\.pooling_nchw_/.test(opName)) {
    return POOLING_NCHW;
  }
  return undefined;
}

function vec2(attrText: string | undefined): [number, number] | undefined {
  if (!attrText) {
    return undefined;
  }
  // dense<2> : tensor<2xi64>  |  dense<[2, 1]> : tensor<2xi64>  |  array<i64: 2, 1>
  const splat = /dense<\s*(\d+)\s*>/.exec(attrText);
  if (splat) {
    return [Number(splat[1]), Number(splat[1])];
  }
  const list = /dense<\s*\[\s*(\d+)\s*,\s*(\d+)\s*\]\s*>/.exec(attrText) ?? /array<i64:\s*(\d+)\s*,\s*(\d+)\s*>/.exec(attrText);
  return list ? [Number(list[1]), Number(list[2])] : undefined;
}

// ---------------------------------------------------------------------------
// Op extraction
// ---------------------------------------------------------------------------

export interface LinalgOp {
  opName: string;
  /** Header text: from the op name through outs(...) (and attrs = {...}). */
  text: string;
  line: number; // 1-based
  config?: LoweringConfig;
  configRaw?: string;
  operands: OperandInfo[];
  iterationDomain: number[];
  iteratorTypes: string[];
  dimNames?: string[];
}

const OP_RE = /\b((?:linalg|iree_linalg_ext)\.(?!yield\b|index\b)[a-z_0-9]+)\b/;

function readOperandGroup(text: string, keyword: 'ins' | 'outs'): Array<{ name: string; type: string }> | undefined {
  const re = new RegExp(`\\b${keyword}\\(`);
  const m = re.exec(text);
  if (!m) {
    return undefined;
  }
  const open = m.index + keyword.length;
  const e = scanBalanced(text, open);
  if (e === undefined) {
    return undefined;
  }
  const inner = text.slice(open + 1, e - 1);
  const colon = splitTopLevel(inner, ':');
  if (colon.length < 2) {
    return undefined;
  }
  const names = splitTopLevel(colon[0], ',');
  const types = splitTopLevel(colon.slice(1).join(':'), ',');
  if (names.length !== types.length) {
    return undefined;
  }
  return names.map((name, i) => ({ name, type: types[i] }));
}

/** Collects the op header, joining up to 8 following lines until outs(...) closes. */
function opHeader(lines: string[], idx: number): string {
  let text = lines[idx];
  for (let j = idx + 1; j < Math.min(lines.length, idx + 8); j++) {
    const o = /\bouts\(/.exec(text);
    if (o && scanBalanced(text, o.index + 4) !== undefined) {
      break;
    }
    text += '\n' + lines[j];
  }
  return text;
}

export function extractLinalgOps(fnText: string, aliases: Map<string, string>, lineOffset = 0): LinalgOp[] {
  const lines = fnText.split(/\r?\n/);
  const ops: LinalgOp[] = [];
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const m = OP_RE.exec(line);
    if (!m) {
      continue;
    }
    // Must be an op position: start of statement or after `=`.
    const before = line.slice(0, m.index).trim();
    if (before.length > 0 && !/=$/.test(before)) {
      continue;
    }
    const text = opHeader(lines, i);
    const opName = m[1];
    const op: LinalgOp = {
      opName, text, line: lineOffset + i + 1, operands: [], iterationDomain: [], iteratorTypes: [],
    };
    const cfg = findAttr(text, 'lowering_config');
    if (cfg !== undefined) {
      op.configRaw = resolveAlias(cfg, aliases);
      op.config = parseLoweringConfig(op.configRaw);
    }
    recoverIterationSpace(op, aliases);
    ops.push(op);
  }
  return ops;
}

function recoverIterationSpace(op: LinalgOp, aliases: Map<string, string>): void {
  const ins = readOperandGroup(op.text, 'ins') ?? [];
  const outs = readOperandGroup(op.text, 'outs') ?? [];
  const operands: OperandInfo[] = [];
  for (const [group, role] of [[ins, 'input'], [outs, 'output']] as const) {
    for (const o of group) {
      const st = parseShapedType(o.type);
      operands.push({
        name: o.name,
        role,
        shape: st?.shape ?? [],
        elementType: st?.elementType ?? o.type,
        elementBytes: st ? elementBytes(st.elementType) : undefined,
      });
    }
  }
  op.operands = operands;

  let maps: DimRef[][] | undefined;
  let iter: string[] | undefined;

  if (op.opName === 'linalg.generic' || /indexing_maps\s*=/.test(op.text)) {
    const im = findAttr(op.text, 'indexing_maps');
    const it = findAttr(op.text, 'iterator_types');
    if (im !== undefined && it !== undefined) {
      const inner = im.trim().slice(1, -1);
      const parsed = splitTopLevel(inner, ',').map((s) => parseAffineMap(resolveAlias(s, aliases)));
      if (parsed.every((p): p is AffineMap => p !== undefined)) {
        maps = parsed.map((p) => p.results);
        iter = [...it.matchAll(/\b(parallel|reduction|window)\b/g)].map((x) => (x[1] === 'window' ? P : x[1]));
        if (parsed.length > 0 && parsed[0].numDims !== iter.length) {
          maps = undefined;
        }
      }
    }
  } else if (op.opName === 'linalg.fill' || ELEMENTWISE.has(op.opName.replace(/^linalg\./, ''))) {
    const out = operands.find((o) => o.role === 'output');
    if (out) {
      const rank = out.shape.length;
      const ident = Array.from({ length: rank }, (_, i) => i);
      maps = operands.map((o) => (o.shape.length === rank ? ident : []));
      iter = ident.map(() => P);
    }
  } else {
    const spec = namedSpec(op.opName);
    if (spec) {
      const strides = vec2(findAttr(op.text, 'strides')) ?? [1, 1];
      const dilations = vec2(findAttr(op.text, 'dilations')) ?? [1, 1];
      let w = 0;
      maps = spec.maps.map((mp) => mp.map((d) => {
        if (typeof d === 'number') {
          return d;
        }
        const k = Math.min(w++ % 2, 1);
        return { out: d.out, win: d.win, stride: strides[k], dilation: dilations[k] };
      }));
      iter = [...spec.iter].map((c) => (c === 'p' ? P : R));
      op.dimNames = spec.names;
    }
  }

  if (!maps || !iter || maps.length !== operands.length) {
    return;
  }
  op.iteratorTypes = iter;
  operands.forEach((o, i) => { o.dimMap = maps![i]; });

  const domain: number[] = new Array(iter.length).fill(-1);
  operands.forEach((o, i) => {
    maps![i].forEach((d, k) => {
      if (typeof d === 'number' && d >= 0 && d < domain.length && o.shape[k] !== undefined && o.shape[k] >= 0 && domain[d] < 0) {
        domain[d] = o.shape[k];
      }
    });
  });
  // Do not guess: any unresolved or dynamic dim means no domain.
  op.iterationDomain = domain.every((d) => d > 0) ? domain : [];
}

// ---------------------------------------------------------------------------
// Target hardware
// ---------------------------------------------------------------------------

/**
 * Reads hardware limits from the executable target in a dump, e.g.
 *   target(<"llvm-cpu", "embedded-elf-arm_64", {cpu = "apple-m1", native_vector_size = 16 : i64, ...}>)
 *   #iree_gpu.target<arch = "rdna3", ..., wgp = <..., max_thread_count_per_workgroup = 1024,
 *       max_workgroup_memory_bytes = 65536, ...>, chip = <wgp_count = 304>>
 * Field names checked against IREEGPUAttrs.td.
 */
export function parseTargetHardware(text: string): TargetHardware | undefined {
  const backend = /(?:target\(<|#hal\.executable\.target<)\s*"([\w-]+)"/.exec(text)?.[1];
  const num = (re: RegExp) => {
    const m = re.exec(text);
    return m ? Number(m[1]) : undefined;
  };
  if (/#iree_gpu\.target</.test(text)) {
    const choices = /subgroup_size_choices = \[([\d,\s]+)\]/.exec(text)?.[1];
    return {
      kind: 'gpu',
      backend,
      arch: /#iree_gpu\.target<\s*arch = "([^"]+)"/.exec(text)?.[1],
      maxWorkgroupMemoryBytes: num(/max_workgroup_memory_bytes = (\d+)/),
      maxThreadsPerWorkgroup: num(/max_thread_count_per_workgroup = (\d+)/),
      subgroupSizes: choices ? choices.split(',').map((x) => Number(x.trim())).filter((n) => n > 0) : undefined,
      computeUnits: num(/wgp_count = (\d+)/),
    };
  }
  const vec = num(/native_vector_size = (\d+)/);
  if (vec !== undefined || backend === 'llvm-cpu') {
    return { kind: 'cpu', backend, arch: /\bcpu = "([^"]+)"/.exec(text)?.[1], nativeVectorBytes: vec };
  }
  return backend ? { kind: 'unknown', backend } : undefined;
}

// ---------------------------------------------------------------------------
// Dispatch extraction
// ---------------------------------------------------------------------------

function pickRootOp(ops: LinalgOp[]): LinalgOp | undefined {
  const withCfg = ops.filter((o) => o.configRaw !== undefined);
  const pool = withCfg.length > 0 ? withCfg : ops;
  let best: LinalgOp | undefined;
  let bestScore = -1;
  for (const o of pool) {
    const reductions = o.iteratorTypes.filter((t) => t === R).length;
    const score = (reductions > 0 ? 1000 : 0) + o.iteratorTypes.length * 10 + (o.opName === 'linalg.fill' ? -500 : 0);
    if (score > bestScore) {
      bestScore = score;
      best = o;
    }
  }
  return best;
}

/**
 * Extracts one DispatchInfo per function in an executable dump (sources,
 * configs, or a codegen pass dump). Never throws.
 */
export function parseDispatchFile(text: string, sourceFile: string): DispatchInfo[] {
  try {
    return parseDispatchFileImpl(text, sourceFile);
  } catch {
    return [];
  }
}

function parseDispatchFileImpl(text: string, sourceFile: string): DispatchInfo[] {
  const aliases = parseAliases(text);
  const executable = /hal\.executable(?:\s+(?:public|private))?\s+@([\w$.-]+)/.exec(text)?.[1];
  const variant = /hal\.executable\.variant(?:\s+(?:public|private))?\s+@([\w$.-]+)/.exec(text)?.[1];
  const hardware = parseTargetHardware(text);
  const out: DispatchInfo[] = [];
  const fnRe = /^[ \t]*func\.func\s+(?:(?:public|private)\s+)?@([\w$.-]+)/gm;
  const starts: Array<{ name: string; index: number }> = [];
  for (let m = fnRe.exec(text); m; m = fnRe.exec(text)) {
    starts.push({ name: m[1], index: m.index });
  }
  for (let i = 0; i < starts.length; i++) {
    const seg = text.slice(starts[i].index, i + 1 < starts.length ? starts[i + 1].index : text.length);
    const lineOffset = text.slice(0, starts[i].index).split('\n').length - 1;
    const firstLineEnd = seg.indexOf('\n');
    const sig = firstLineEnd < 0 ? seg : seg.slice(0, firstLineEnd);
    const tiRaw = findAttr(sig, 'translation_info');
    const translation = tiRaw !== undefined ? parseTranslationInfo(resolveAlias(tiRaw, aliases)) : undefined;
    const ops = extractLinalgOps(seg, aliases, lineOffset);
    const root = pickRootOp(ops);
    out.push({
      name: starts[i].name,
      opName: root?.opName ?? '',
      iterationDomain: root?.iterationDomain ?? [],
      iteratorTypes: root?.iteratorTypes ?? [],
      config: root?.config,
      translation,
      sourceFile,
      sourceLine: root?.line,
      operands: root?.operands ?? [],
      opCount: ops.length,
      executable,
      variant,
      hardware,
      dimNames: root?.dimNames,
    });
  }
  return out;
}
