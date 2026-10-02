// Op-level diff between two IR dumps: which ops were added, removed or
// modified, and how the count of each op kind changed. Works on the
// pretty-printed form IREE dumps (one op per line):
//   %0 = arith.addf %a, %b : f32
//   %ok, %value = hal.device.query<...> key(...) : i1, i1 = false
//   cf.br ^bb1(%c0 : index)
//   "dialect.op"(%x) : (i32) -> ()
// SSA value and block names are normalized before comparing, so a pass that
// only renumbers values reports no changes. Pure; never throws.

export interface OpInstance {
  /** Full op name, e.g. "linalg.matmul". */
  name: string;
  /** 1-based line in the dump. */
  line: number;
  /** The op's source line, trimmed. */
  text: string;
  /** Normalized text used for matching. */
  key: string;
}

export interface OpCount {
  name: string;
  dialect: string;
  before: number;
  after: number;
  /** Instances that exist on both sides but whose text changed. */
  modified: number;
}

export type OpChangeKind = 'added' | 'removed' | 'modified';

export interface OpChange {
  kind: OpChangeKind;
  name: string;
  before?: { line: number; text: string };
  after?: { line: number; text: string };
}

export interface OpDiff {
  totalBefore: number;
  totalAfter: number;
  added: number;
  removed: number;
  modified: number;
  /** Op kinds whose count changed or that have modified instances. */
  counts: OpCount[];
  /** Changed instances in file order, capped at MAX_CHANGES. */
  changes: OpChange[];
  /** True when `changes` was capped. */
  truncated: boolean;
}

/** What the Op Changes panel renders: two dumps and their diff. */
export interface OpDiffView {
  before: { label: string; file: string };
  after: { label: string; file: string };
  diff: OpDiff;
}

export const MAX_CHANGES = 2000;

const SSA = /%[\w$.#-]+(?::\d+)?/;
const RESULTS = new RegExp(`^${SSA.source}(?:\\s*,\\s*${SSA.source})*\\s*=\\s*`);
const GENERIC_OP = /^"([\w$.-]+)"/;
const CUSTOM_OP = /^([A-Za-z_][\w$]*(?:\.[\w$]+)+)(?=[\s<({[@"%:]|$)/;
const BUILTIN_OP = /^(module)(?=[\s@{]|$)/;

/** Dialect prefix of an op name; "module" is in builtin. */
export function dialectOf(name: string): string {
  const dot = name.indexOf('.');
  return dot < 0 ? 'builtin' : name.slice(0, dot);
}

/** Op name on a single dump line, or undefined if the line is not an op. */
export function opNameOf(line: string): string | undefined {
  let s = line.trimStart();
  const res = RESULTS.exec(s);
  if (res) {
    s = s.slice(res[0].length);
  } else if (/^[%^}#!)\]/]/.test(s)) {
    return undefined;
  }
  const m = GENERIC_OP.exec(s) ?? CUSTOM_OP.exec(s) ?? (res ? undefined : BUILTIN_OP.exec(s));
  if (!m) {
    return undefined;
  }
  // "iree.fixedpoint.iteration = 3" inside a multi-line attribute dict.
  if (!res && /^\s*=/.test(s.slice(m[0].length))) {
    return undefined;
  }
  return m[1];
}

/** Text with SSA/block names and locations normalized away. */
export function normalizeOp(text: string): string {
  return text
    .replace(/\s+loc\((?:[^()]|\([^()]*\))*\)/g, '')
    .replace(/%[\w$.#-]+/g, '%')
    .replace(/\^[\w$.-]+/g, '^')
    .replace(/\s+/g, ' ')
    .trim();
}

/** Every op in a dump, in file order. */
export function extractOps(text: string): OpInstance[] {
  const out: OpInstance[] = [];
  const lines = text.split('\n');
  for (let i = 0; i < lines.length; i++) {
    const name = opNameOf(lines[i]);
    if (name) {
      const t = lines[i].trim();
      out.push({ name, line: i + 1, text: t, key: normalizeOp(t) });
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// Sequence alignment
// ---------------------------------------------------------------------------

/** Above this many DP cells a segment without anchors is reported as replaced. */
const MAX_LCS_CELLS = 4_000_000;

/**
 * Aligns two key sequences. Returns pairs [i, j] of matched indices in
 * increasing order. Patience-style: anchor on keys unique to both sides,
 * recurse between anchors, and fall back to LCS on small anchorless segments.
 */
export function alignKeys(a: string[], b: string[]): Array<[number, number]> {
  const out: Array<[number, number]> = [];
  // Segments are handled left to right, so `out` stays sorted.
  const rec = (aLo: number, aHi: number, bLo: number, bHi: number): void => {
    while (aLo < aHi && bLo < bHi && a[aLo] === b[bLo]) {
      out.push([aLo++, bLo++]);
    }
    const tail: Array<[number, number]> = [];
    while (aLo < aHi && bLo < bHi && a[aHi - 1] === b[bHi - 1]) {
      tail.push([--aHi, --bHi]);
    }
    if (aLo < aHi && bLo < bHi) {
      const anchors = uniqueAnchors(a, aLo, aHi, b, bLo, bHi);
      if (anchors.length > 0) {
        let pa = aLo;
        let pb = bLo;
        for (const [i, j] of anchors) {
          rec(pa, i, pb, j);
          out.push([i, j]);
          pa = i + 1;
          pb = j + 1;
        }
        rec(pa, aHi, pb, bHi);
      } else if ((aHi - aLo) * (bHi - bLo) <= MAX_LCS_CELLS) {
        out.push(...lcs(a, aLo, aHi, b, bLo, bHi));
      }
    }
    for (let k = tail.length - 1; k >= 0; k--) {
      out.push(tail[k]);
    }
  };
  rec(0, a.length, 0, b.length);
  return out;
}

function uniqueAnchors(a: string[], aLo: number, aHi: number, b: string[], bLo: number, bHi: number): Array<[number, number]> {
  const ca = new Map<string, number>();
  for (let i = aLo; i < aHi; i++) {
    ca.set(a[i], ca.has(a[i]) ? -1 : i);
  }
  const cb = new Map<string, number>();
  for (let j = bLo; j < bHi; j++) {
    cb.set(b[j], cb.has(b[j]) ? -1 : j);
  }
  const pairs: Array<[number, number]> = [];
  for (let j = bLo; j < bHi; j++) {
    const i = ca.get(b[j]);
    if (i !== undefined && i >= 0 && cb.get(b[j]) === j) {
      pairs.push([i, j]);
    }
  }
  // Longest increasing subsequence of i over pairs (already sorted by j).
  const tails: number[] = [];
  const prev = new Array<number>(pairs.length).fill(-1);
  for (let k = 0; k < pairs.length; k++) {
    let lo = 0;
    let hi = tails.length;
    while (lo < hi) {
      const mid = (lo + hi) >> 1;
      if (pairs[tails[mid]][0] < pairs[k][0]) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    prev[k] = lo > 0 ? tails[lo - 1] : -1;
    tails[lo] = k;
  }
  const lis: Array<[number, number]> = [];
  for (let k = tails.length > 0 ? tails[tails.length - 1] : -1; k >= 0; k = prev[k]) {
    lis.push(pairs[k]);
  }
  return lis.reverse();
}

function lcs(a: string[], aLo: number, aHi: number, b: string[], bLo: number, bHi: number): Array<[number, number]> {
  const n = aHi - aLo;
  const m = bHi - bLo;
  const w = m + 1;
  const dp = new Uint32Array((n + 1) * w);
  for (let i = n - 1; i >= 0; i--) {
    for (let j = m - 1; j >= 0; j--) {
      dp[i * w + j] = a[aLo + i] === b[bLo + j]
        ? dp[(i + 1) * w + j + 1] + 1
        : Math.max(dp[(i + 1) * w + j], dp[i * w + j + 1]);
    }
  }
  const out: Array<[number, number]> = [];
  let i = 0;
  let j = 0;
  while (i < n && j < m) {
    if (a[aLo + i] === b[bLo + j]) {
      out.push([aLo + i++, bLo + j++]);
    } else if (dp[(i + 1) * w + j] >= dp[i * w + j + 1]) {
      i++;
    } else {
      j++;
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// Diff
// ---------------------------------------------------------------------------

/** Op-level diff of two dumps. */
export function diffOps(beforeText: string, afterText: string): OpDiff {
  const a = extractOps(beforeText);
  const b = extractOps(afterText);
  const matched = alignKeys(a.map((o) => o.key), b.map((o) => o.key));

  const changes: OpChange[] = [];
  let ai = 0;
  let bi = 0;
  const flush = (aEnd: number, bEnd: number): void => {
    // Within a gap, pair removed and added ops of the same kind as "modified".
    // Order: removed/modified in before-file order, then added in after-file order.
    const removed = a.slice(ai, aEnd);
    const added = b.slice(bi, bEnd);
    const byName = new Map<string, OpInstance[]>();
    for (const op of added) {
      const list = byName.get(op.name) ?? [];
      list.push(op);
      byName.set(op.name, list);
    }
    const pairedAdds = new Set<OpInstance>();
    const gap: OpChange[] = [];
    for (const op of removed) {
      const partner = byName.get(op.name)?.shift();
      if (partner) {
        pairedAdds.add(partner);
        gap.push({ kind: 'modified', name: op.name, before: { line: op.line, text: op.text }, after: { line: partner.line, text: partner.text } });
      } else {
        gap.push({ kind: 'removed', name: op.name, before: { line: op.line, text: op.text } });
      }
    }
    for (const op of added) {
      if (!pairedAdds.has(op)) {
        gap.push({ kind: 'added', name: op.name, after: { line: op.line, text: op.text } });
      }
    }
    changes.push(...gap);
    ai = aEnd;
    bi = bEnd;
  };
  for (const [i, j] of matched) {
    flush(i, j);
    ai = i + 1;
    bi = j + 1;
  }
  flush(a.length, b.length);

  const counts = new Map<string, OpCount>();
  const count = (name: string): OpCount => {
    let c = counts.get(name);
    if (!c) {
      c = { name, dialect: dialectOf(name), before: 0, after: 0, modified: 0 };
      counts.set(name, c);
    }
    return c;
  };
  a.forEach((o) => count(o.name).before++);
  b.forEach((o) => count(o.name).after++);
  let added = 0;
  let removed = 0;
  let modified = 0;
  for (const c of changes) {
    if (c.kind === 'added') {
      added++;
    } else if (c.kind === 'removed') {
      removed++;
    } else {
      modified++;
      count(c.name).modified++;
    }
  }

  return {
    totalBefore: a.length,
    totalAfter: b.length,
    added,
    removed,
    modified,
    counts: [...counts.values()]
      .filter((c) => c.before !== c.after || c.modified > 0)
      .sort((x, y) => Math.abs(y.after - y.before) - Math.abs(x.after - x.before) || y.modified - x.modified || x.name.localeCompare(y.name)),
    changes: changes.slice(0, MAX_CHANGES),
    truncated: changes.length > MAX_CHANGES,
  };
}
