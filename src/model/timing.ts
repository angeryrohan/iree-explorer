// Parses the `--mlir-timing` report (tree display) from stderr and matches it
// against pass dump nodes. Pure; never throws.

import { PassNode, TimingRow } from './types';

const ROW_RE = /^(\s*)(-?[\d.]+) \(\s*-?[\d.]+%\)\s+(-?[\d.]+) \(\s*-?[\d.]+%\)(\s+)(.+?)\s*$/;

/**
 * Returns rows in report order. Depth is derived from the indentation of the
 * name column (2 spaces per level). With both user and wall columns present
 * the wall column is the second number; with a single column it's the first.
 */
export function parseTiming(stderr: string): TimingRow[] | undefined {
  const lines = stderr.split(/\r?\n/);
  const start = lines.findIndex((l) => /Execution time report/.test(l));
  if (start < 0) {
    return undefined;
  }
  const header = lines.slice(start, start + 10).find((l) => /----Name----/.test(l));
  if (!header) {
    return undefined;
  }
  const nameCol = header.indexOf('----Name----');
  const twoCols = /User Time/.test(header) && /Wall Time/.test(header);
  const rows: TimingRow[] = [];
  const singleRe = /^(\s*)(-?[\d.]+) \(\s*-?[\d.]+%\)(\s+)(.+?)\s*$/;
  for (let i = start + 1; i < lines.length; i++) {
    const line = lines[i];
    if (line.trim().length === 0 && rows.length > 0) {
      break;
    }
    let wall: number;
    let name: string;
    if (twoCols) {
      const m = ROW_RE.exec(line);
      if (!m) {
        continue;
      }
      wall = Number(m[3]);
      name = m[5];
    } else {
      const m = singleRe.exec(line);
      if (!m) {
        continue;
      }
      wall = Number(m[2]);
      name = m[4];
    }
    const nameStart = line.indexOf(name);
    const depth = nameCol >= 0 ? Math.max(0, Math.round((nameStart - nameCol) / 2)) : 0;
    if (name === 'Rest' || name === 'Total') {
      continue;
    }
    rows.push({ depth, name, wallMs: wall * 1000 });
  }
  return rows;
}

function isPassRow(r: TimingRow): boolean {
  return !r.name.startsWith('(A)') && !/^'[^']+' Pipeline$/.test(r.name);
}

/**
 * Matches timing rows to pass nodes by pass class name.
 *
 * The timing tree follows pass-manager structure, not execution order: each
 * nested op pipeline appears once, aggregated over every op (and every
 * fixed-point iteration) it ran on, while the tree-dir dumps interleave
 * top-level and nested passes by execution. So the two sequences are aligned
 * by longest common subsequence of class names — once over everything, once
 * with top-level and nested passes split by depth — and the better alignment
 * wins. Scopes sharing an ordinal path get the same (aggregated) time.
 *
 * TODO(verify): checked against one IREE build (LLVM 24, 2026). If wall times
 * look shifted on another version, compare `--mlir-timing` tree order with
 * the tree-dir ordinals there.
 */
export function attachTimings(nodes: PassNode[], rows: TimingRow[]): number {
  const byOrdinal = new Map<string, PassNode[]>();
  for (const n of nodes) {
    const k = n.ordinalPath.join('_');
    const list = byOrdinal.get(k);
    if (list) {
      list.push(n);
    } else {
      byOrdinal.set(k, [n]);
    }
  }
  const preorder = (a: number[], b: number[]) => {
    for (let i = 0; i < Math.min(a.length, b.length); i++) {
      if (a[i] !== b[i]) {
        return a[i] - b[i];
      }
    }
    return a.length - b.length;
  };
  const instances = [...byOrdinal.values()].sort((a, b) => preorder(a[0].ordinalPath, b[0].ordinalPath));
  const passRows = rows.filter(isPassRow);

  const combined = align(instances, passRows);
  const split = [
    ...align(instances.filter((i) => i[0].ordinalPath.length === 1), passRows.filter((r) => r.depth === 0)),
    ...align(instances.filter((i) => i[0].ordinalPath.length > 1), passRows.filter((r) => r.depth > 0)),
  ];
  const best = split.length > combined.length ? split : combined;
  for (const [inst, row] of best) {
    for (const n of inst) {
      n.wallMs = row.wallMs;
    }
  }
  return best.length;
}

function sameClass(cls: string | undefined, row: string): boolean {
  if (!cls) {
    return false;
  }
  return row === cls || row.endsWith(`::${cls}`) || cls.endsWith(`::${row}`);
}

const MAX_LCS_CELLS = 4_000_000;

/** LCS alignment; falls back to a greedy forward walk for huge inputs. */
function align(instances: PassNode[][], rows: TimingRow[]): Array<[PassNode[], TimingRow]> {
  const n = instances.length;
  const m = rows.length;
  if (n === 0 || m === 0) {
    return [];
  }
  if ((n + 1) * (m + 1) > MAX_LCS_CELLS) {
    return greedy(instances, rows);
  }
  const W = m + 1;
  const dp = new Uint32Array((n + 1) * W);
  for (let i = n - 1; i >= 0; i--) {
    const cls = instances[i][0].className;
    for (let j = m - 1; j >= 0; j--) {
      dp[i * W + j] = sameClass(cls, rows[j].name)
        ? dp[(i + 1) * W + j + 1] + 1
        : Math.max(dp[(i + 1) * W + j], dp[i * W + j + 1]);
    }
  }
  const out: Array<[PassNode[], TimingRow]> = [];
  let i = 0;
  let j = 0;
  while (i < n && j < m) {
    if (sameClass(instances[i][0].className, rows[j].name) && dp[i * W + j] === dp[(i + 1) * W + j + 1] + 1) {
      out.push([instances[i], rows[j]]);
      i++;
      j++;
    } else if (dp[(i + 1) * W + j] >= dp[i * W + j + 1]) {
      i++;
    } else {
      j++;
    }
  }
  return out;
}

function greedy(instances: PassNode[][], rows: TimingRow[], window = 64): Array<[PassNode[], TimingRow]> {
  const out: Array<[PassNode[], TimingRow]> = [];
  let cursor = 0;
  for (const inst of instances) {
    for (let j = cursor; j < Math.min(rows.length, cursor + window); j++) {
      if (sameClass(inst[0].className, rows[j].name)) {
        out.push([inst, rows[j]]);
        cursor = j + 1;
        break;
      }
    }
  }
  return out;
}
