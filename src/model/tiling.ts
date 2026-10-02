// Pure tiling geometry: DispatchInfo -> rects, hatches and derived numbers.
// Shared by the webview (rendering) and unit tests (golden rect lists).

import {
  DimRef, DispatchInfo, HatchRegion, LevelStats, OperandFootprint, TileRect, TilingCheck, TilingGeometry,
} from './types';

export interface GeometryOptions {
  /** Size in px of the longer drawing axis. */
  canvasPx: number;
  /** Tiles smaller than this (px) on either axis are drawn as a hatch. */
  minTilePx: number;
  /** Cap on rects + hatches drawn. */
  maxRects: number;
  /** Width in px of the reduction strip. */
  stripPx: number;
}

export const DEFAULT_GEOMETRY_OPTIONS: GeometryOptions = {
  canvasPx: 480,
  minTilePx: 3,
  maxRects: 2000,
  stripPx: 480,
};

const WORKGROUP_LEVEL_NAMES = new Set(['workgroup', 'distribution', 'level 0']);
const REDUCTION_LEVEL_NAMES = ['reduction', 'vector_reduction', 'cache_reduction', 'partial_reduction'];

/** Iteration-space box on the two drawing axes. */
interface Box { x: number; y: number; w: number; h: number }

/** Effective tile per dim: 0 inherits the parent extent; clamp to parent. */
function effectiveTiles(sizes: number[], parent: number[]): number[] {
  return parent.map((p, d) => {
    const s = sizes[d] ?? 0;
    return s > 0 ? Math.min(s, p) : p;
  });
}

export function computeLevelStats(dispatch: DispatchInfo): { levels: LevelStats[]; warnings: string[] } {
  const warnings: string[] = [];
  const levels: LevelStats[] = [];
  const cfg = dispatch.config;
  const domain = dispatch.iterationDomain;
  if (!cfg) {
    return { levels, warnings };
  }
  let parent = domain.slice();
  for (const lvl of cfg.levels) {
    if (domain.length > 0 && lvl.sizes.length > domain.length) {
      warnings.push(`${lvl.name}: ${lvl.sizes.length} tile sizes for a ${domain.length}-D iteration space; extra entries ignored.`);
    }
    if (domain.length === 0) {
      levels.push({ name: lvl.name, sizes: lvl.sizes, effective: [], tilesPerDim: [], tilesTotal: 0, raggedDims: [] });
      continue;
    }
    lvl.sizes.forEach((s, d) => {
      if (d < parent.length && s > parent[d]) {
        warnings.push(
          `${lvl.name}: tile ${s} on d${d} exceeds the enclosing extent ${parent[d]}; clamped. ` +
          (cfg.form === 'gpu' ? '(GPU subgroup/thread sizes may be in intrinsic or thread units rather than elements.)' : ''),
        );
      }
    });
    const eff = effectiveTiles(lvl.sizes, parent);
    const tilesPerDim = parent.map((p, d) => Math.ceil(p / eff[d]));
    const raggedDims = parent.map((_, d) => d).filter((d) => (lvl.sizes[d] ?? 0) > 0 && parent[d] % eff[d] !== 0);
    levels.push({
      name: lvl.name,
      sizes: lvl.sizes,
      effective: eff,
      tilesPerDim,
      tilesTotal: tilesPerDim.reduce((a, b) => a * b, 1),
      raggedDims,
    });
    for (const d of raggedDims) {
      warnings.push(`${lvl.name}: d${d} extent ${parent[d]} is not divisible by tile ${eff[d]}; remainder tile of ${parent[d] % eff[d]}.`);
    }
    parent = eff;
  }
  return { levels, warnings };
}

/**
 * Picks the first two parallel dims with extent > 1 (falling back to any
 * parallel dims). Returned as [x, y] with the first dim on the vertical axis,
 * the way matrices are written (rows = M, columns = N).
 */
export function pickAxes(dispatch: DispatchInfo): [number, number] | undefined {
  const par = dispatch.iteratorTypes
    .map((t, d) => ({ t, d }))
    .filter((x) => x.t === 'parallel')
    .map((x) => x.d);
  const big = par.filter((d) => (dispatch.iterationDomain[d] ?? 0) > 1);
  const pool = big.length > 0 ? big : par;
  if (pool.length === 0) {
    return undefined;
  }
  return pool.length > 1 ? [pool[1], pool[0]] : [pool[0], -1];
}

function tileBox(parent: Box, tx: number, ty: number): Array<{ box: Box; ragged: boolean }> {
  const out: Array<{ box: Box; ragged: boolean }> = [];
  for (let y = parent.y; y < parent.y + parent.h; y += ty) {
    for (let x = parent.x; x < parent.x + parent.w; x += tx) {
      const w = Math.min(tx, parent.x + parent.w - x);
      const h = Math.min(ty, parent.y + parent.h - y);
      out.push({ box: { x, y, w, h }, ragged: w < tx || h < ty });
    }
  }
  return out;
}

export function computeTilingGeometry(
  dispatch: DispatchInfo,
  opts: GeometryOptions = DEFAULT_GEOMETRY_OPTIONS,
): TilingGeometry | undefined {
  const domain = dispatch.iterationDomain;
  if (domain.length === 0 || domain.some((d) => !(d > 0)) || dispatch.iteratorTypes.length !== domain.length) {
    return undefined;
  }
  const axes = pickAxes(dispatch);
  if (!axes) {
    return undefined;
  }
  const [xd, yd] = axes;
  const { levels, warnings } = computeLevelStats(dispatch);
  const reductionDims = dispatch.iteratorTypes.map((t, d) => ({ t, d })).filter((x) => x.t === 'reduction').map((x) => x.d);

  const X = domain[xd];
  const Y = yd >= 0 ? domain[yd] : 1;
  const scale = opts.canvasPx / Math.max(X, yd >= 0 ? Y : 1);
  // In 1-D mode the y axis is a fixed-height band; only x matters for px size.
  const pxW = (w: number) => w * scale;
  const pxH = (h: number) => (yd >= 0 ? h * scale : Infinity);

  const rects: TileRect[] = [];
  const hatches: HatchRegion[] = [];
  let budget = opts.maxRects;
  let truncated = false;
  let parents: Box[] = [{ x: 0, y: 0, w: X, h: Y }];

  levels.forEach((lvl, li) => {
    const tx = lvl.effective[xd];
    const ty = yd >= 0 ? lvl.effective[yd] : 1;
    const subdivides = parents.some((p) => tx < p.w || ty < p.h);
    const next: Box[] = [];
    if (!subdivides) {
      // Level doesn't tile the drawn axes; outline its (== parent) tiles only
      // if nothing has been drawn yet, so level 0 is always visible.
      if (li === 0) {
        rects.push({ level: 0, ...parents[0], ragged: false });
        budget--;
      }
      return;
    }
    const tooSmall = pxW(tx) < opts.minTilePx || pxH(ty) < opts.minTilePx;
    const perParent = parents.map((p) => Math.ceil(p.w / tx) * Math.ceil(p.h / ty));
    const needed = tooSmall ? parents.length : perParent.reduce((a, b) => a + b, 0);

    if (needed > budget) {
      truncated = true;
      // One hatch over the whole domain with the total count.
      const total = perParent.reduce((a, b) => a + b, 0);
      hatches.push({ level: li, x: 0, y: 0, w: X, h: Y, count: total });
      budget--;
      parents = []; // deeper levels can't be placed either
      return;
    }
    for (let pi = 0; pi < parents.length; pi++) {
      const p = parents[pi];
      if (tooSmall) {
        hatches.push({ level: li, ...p, count: perParent[pi] });
        budget--;
        continue;
      }
      for (const t of tileBox(p, tx, ty)) {
        rects.push({ level: li, ...t.box, ragged: t.ragged });
        budget--;
        next.push(t.box);
      }
    }
    parents = tooSmall ? [] : next;
  });

  // Reduction strip along the first reduction dim.
  const reductionRects: TileRect[] = [];
  const reductionHatches: HatchRegion[] = [];
  if (reductionDims.length > 0) {
    const rd = reductionDims[0];
    const K = domain[rd];
    const sScale = opts.stripPx / K;
    levels.forEach((lvl, li) => {
      const s = lvl.sizes[rd] ?? 0;
      if (s <= 0) {
        return;
      }
      const t = Math.min(s, K);
      if (t * sScale < opts.minTilePx || Math.ceil(K / t) > 256) {
        reductionHatches.push({ level: li, x: 0, y: li, w: K, h: 1, count: Math.ceil(K / t) });
        return;
      }
      for (let x = 0; x < K; x += t) {
        const w = Math.min(t, K - x);
        reductionRects.push({ level: li, x, y: li, w, h: 1, ragged: w < t });
      }
    });
  }

  const wgLevel = levels.find((l) => WORKGROUP_LEVEL_NAMES.has(l.name)) ?? (dispatch.config?.form === 'codegen' ? levels[0] : undefined);
  const workgroupCount = wgLevel
    // Only parallel dims are distributed; a reduction tile at this level is a loop.
    ? wgLevel.tilesPerDim.reduce(
      (acc, n, d) => ((wgLevel.sizes[d] ?? 0) > 0 && dispatch.iteratorTypes[d] === 'parallel' ? acc * n : acc), 1)
    : undefined;

  const { footprints, total } = computeFootprints(dispatch, levels);
  const budgetBytes = dispatch.sharedMemoryBudgetBytes;

  if (truncated) {
    warnings.push(`More than ${opts.maxRects} tiles; deeper levels are summarised as hatched regions.`);
  }

  return {
    axes,
    domain,
    reductionDims,
    levels,
    rects,
    hatches,
    reductionRects,
    reductionHatches,
    workgroupCount,
    footprints,
    footprintTotalBytes: total,
    fitsSharedMemory: total !== undefined && budgetBytes !== undefined ? total <= budgetBytes : undefined,
    truncated,
    warnings,
  };
}

/**
 * Per-workgroup operand tile footprint. Parallel dims use the workgroup tile;
 * a reduction dim uses the first level that tiles it (else its full extent),
 * since that's the slice staged per iteration of the reduction loop.
 */
export function computeFootprints(
  dispatch: DispatchInfo,
  levels: LevelStats[],
): { footprints: OperandFootprint[]; total?: number } {
  const domain = dispatch.iterationDomain;
  if (domain.length === 0 || levels.length === 0) {
    return { footprints: [] };
  }
  const wg = levels.find((l) => WORKGROUP_LEVEL_NAMES.has(l.name)) ?? levels[0];
  const tile = domain.map((ext, d) => {
    if (dispatch.iteratorTypes[d] === 'reduction') {
      const named = REDUCTION_LEVEL_NAMES.map((n) => levels.find((l) => l.name === n)).find((l) => l && (l.sizes[d] ?? 0) > 0);
      const lvl = named ?? levels.find((l) => (l.sizes[d] ?? 0) > 0);
      return lvl ? Math.min(lvl.sizes[d], ext) : ext;
    }
    const s = wg.sizes[d] ?? 0;
    return s > 0 ? Math.min(s, ext) : ext;
  });
  const extentOf = (ref: DimRef): number | undefined => {
    if (typeof ref === 'number') {
      return ref >= 0 ? tile[ref] : undefined;
    }
    return (tile[ref.out] - 1) * ref.stride + (tile[ref.win] - 1) * ref.dilation + 1;
  };
  const footprints: OperandFootprint[] = [];
  let total: number | undefined = 0;
  for (const o of dispatch.operands) {
    if (o.shape.length === 0) {
      continue; // scalars
    }
    const shape = o.dimMap
      ? o.dimMap.map((r, k) => extentOf(r) ?? o.shape[k])
      : o.shape.slice();
    const valid = shape.every((s) => s > 0);
    const bytes = valid && o.elementBytes !== undefined ? shape.reduce((a, b) => a * b, 1) * o.elementBytes : undefined;
    footprints.push({ name: o.name, role: o.role, tileShape: shape, bytes });
    total = bytes !== undefined && total !== undefined ? total + bytes : undefined;
  }
  return { footprints, total };
}

export function formatBytes(n: number): string {
  if (n < 1024) {
    return `${n} B`;
  }
  if (n < 1024 * 1024) {
    return `${(n / 1024).toFixed(n % 1024 === 0 ? 0 : 1)} KiB`;
  }
  return `${(n / (1024 * 1024)).toFixed(1)} MiB`;
}

// ---------------------------------------------------------------------------
// Checklist: common tiling mistakes, judged against the target's own limits
// ---------------------------------------------------------------------------

export function dimLabel(d: DispatchInfo, i: number): string {
  return d.dimNames?.[i] ?? `d${i}`;
}

function product(xs: number[]): number {
  return xs.reduce((a, b) => a * b, 1);
}

/**
 * Up to five checks, each one line of verdict plus one line of numbers.
 * These catch common mistakes; they don't prove a config is optimal (only
 * profiling can).
 */
export function computeChecks(d: DispatchInfo, geo: TilingGeometry | undefined): TilingCheck[] {
  const checks: TilingCheck[] = [];
  const hw = d.hardware;
  if (!d.config) {
    return [{ status: 'info', title: 'No tile sizes on this dispatch', detail: 'Compile to executable-configurations or later.' }];
  }
  if (!geo) {
    return [{ status: 'info', title: 'Problem size unknown', detail: 'Shapes are dynamic or the op form is unsupported, so checks are skipped.' }];
  }

  // 1. Even split.
  const ragged: string[] = [];
  geo.levels.forEach((l, li) => {
    const parent = li === 0 ? geo.domain : geo.levels[li - 1].effective;
    for (const dim of l.raggedDims) {
      ragged.push(`${l.name}: ${dimLabel(d, dim)} = ${parent[dim]} split by ${l.effective[dim]} leaves a last tile of ${parent[dim] % l.effective[dim]}`);
    }
  });
  if (ragged.length === 0) {
    checks.push({ status: 'ok', title: 'Tiles divide the problem evenly', detail: 'No partial tiles at any level.' });
  } else {
    const wg = geo.levels[0];
    const full = product(wg.tilesPerDim.map((n, dim) => (wg.raggedDims.includes(dim) ? n - 1 : n)));
    const partial = wg.raggedDims.length > 0 ? ` ${wg.tilesTotal - full} of ${wg.tilesTotal} ${wg.name} tiles are partial.` : '';
    checks.push({ status: 'warn', title: 'Some tiles are partial (remainder)', detail: `${ragged.join('; ')}.${partial}` });
  }

  if (hw?.kind === 'gpu') {
    // 2. Workgroup memory: the input tiles staged per workgroup.
    const fromIr = hw.maxWorkgroupMemoryBytes;
    const limit = fromIr ?? d.sharedMemoryBudgetBytes;
    const inputs = geo.footprints.filter((f) => f.role === 'input');
    const used = inputs.every((f) => f.bytes !== undefined) ? inputs.reduce((a, f) => a + (f.bytes ?? 0), 0) : undefined;
    if (limit !== undefined && used !== undefined && inputs.length > 0) {
      const parts = inputs.map((f) => `${f.name} ${f.tileShape.join('×')} (${formatBytes(f.bytes ?? 0)})`).join(' + ');
      const src = fromIr !== undefined ? 'limit from the target' : 'limit from settings; the IR has none';
      checks.push(used <= limit
        ? { status: 'ok', title: 'Input tiles fit in workgroup memory', detail: `${parts} = ${formatBytes(used)} of ${formatBytes(limit)} (${src}).` }
        : { status: 'warn', title: 'Input tiles are too big for workgroup memory', detail: `${parts} = ${formatBytes(used)}, limit ${formatBytes(limit)} (${src}). Shrink the workgroup or reduction tile.` });
    }
    // 3. Enough workgroups to fill the chip.
    const wgs = geo.workgroupCount;
    if (wgs !== undefined) {
      if (hw.computeUnits) {
        const pct = Math.min(100, Math.round((100 * wgs) / hw.computeUnits));
        checks.push(wgs >= hw.computeUnits
          ? { status: 'ok', title: 'Enough workgroups to fill the GPU', detail: `${wgs} workgroups for ${hw.computeUnits} compute units.` }
          : { status: 'warn', title: 'Too few workgroups to fill the GPU', detail: `${wgs} workgroups for ${hw.computeUnits} compute units: at most ${pct}% busy. Use smaller workgroup tiles.` });
      } else {
        checks.push({ status: 'info', title: `${wgs} workgroup${wgs === 1 ? '' : 's'} launched`, detail: `The target${hw.arch ? ` (${hw.arch})` : ''} doesn't list its compute-unit count, so occupancy can't be checked. Specific chips (e.g. gfx942) do.` });
      }
    }
    // 4. Threads per workgroup.
    const ws = d.translation?.workgroupSize;
    if (ws && ws.length > 0) {
      const threads = product(ws);
      const sg = d.translation?.subgroupSize ?? hw.subgroupSizes?.find((n) => threads % n === 0) ?? hw.subgroupSizes?.[0];
      const max = hw.maxThreadsPerWorkgroup;
      if (max !== undefined && threads > max) {
        checks.push({ status: 'warn', title: 'Too many threads per workgroup', detail: `[${ws.join(', ')}] = ${threads} threads, limit ${max}.` });
      } else if (sg !== undefined && threads % sg !== 0) {
        checks.push({ status: 'warn', title: 'Threads are not a whole number of subgroups', detail: `[${ws.join(', ')}] = ${threads} threads, subgroup size ${sg}: the last subgroup runs partly empty.` });
      } else {
        checks.push({ status: 'ok', title: 'Workgroup size fits the GPU', detail: `[${ws.join(', ')}] = ${threads} threads${max ? ` (limit ${max})` : ''}${sg ? `, ${threads / sg} subgroups of ${sg}` : ''}.` });
      }
    }
  } else if (hw?.kind === 'cpu') {
    // 2. Vector tile vs SIMD width.
    const vec = hw.nativeVectorBytes;
    const vl = geo.levels.find((l) => l.name === 'vector_common_parallel') ?? geo.levels[geo.levels.length - 1];
    const out = d.operands.find((o) => o.role === 'output');
    const inner = out?.dimMap?.[out.dimMap.length - 1];
    if (vec && vl && out?.elementBytes && typeof inner === 'number' && inner >= 0 && (vl.sizes[inner] ?? 0) > 0) {
      const tile = vl.sizes[inner];
      const bytes = tile * out.elementBytes;
      const what = `${dimLabel(d, inner)}: ${tile} × ${out.elementType} = ${bytes} B; SIMD registers are ${vec} B (from the target)`;
      checks.push(bytes % vec === 0
        ? { status: 'ok', title: 'Vector tile fills whole SIMD registers', detail: `${what} → ${bytes / vec} register${bytes / vec === 1 ? '' : 's'}.` }
        : { status: 'warn', title: bytes < vec ? 'Vector tile is narrower than one SIMD register' : 'Vector tile leaves part of a SIMD register unused', detail: `${what}. Use a multiple of ${vec / out.elementBytes}.` });
    }
    // 3. Workgroups on CPU = parallel chunks for the thread pool.
    if (geo.workgroupCount !== undefined) {
      checks.push({ status: 'info', title: `${geo.workgroupCount} workgroup${geo.workgroupCount === 1 ? '' : 's'} launched`, detail: 'On CPU these are chunks of work shared across threads. You want at least as many as cores.' });
    }
  } else {
    checks.push({ status: 'info', title: 'Hardware limits not found in the IR', detail: 'The dispatch has no recognised target attribute, so only the even-split check applies.' });
  }
  return checks.slice(0, 5);
}
