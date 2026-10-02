// Golden tests for tiling geometry: assert computed rects and numbers, not SVG.

import { readdirSync, readFileSync } from 'fs';
import * as path from 'path';
import { describe, expect, it } from 'vitest';
import { parseDispatchFile } from '../../src/model/lowering';
import { computeChecks, computeFootprints, computeLevelStats, computeTilingGeometry, pickAxes } from '../../src/model/tiling';
import { parseTargetHardware } from '../../src/model/lowering';
import { DispatchInfo } from '../../src/model/types';
import { dump } from './helpers';

function mk(partial: Partial<DispatchInfo>): DispatchInfo {
  return {
    name: 'd', opName: 'linalg.matmul', iterationDomain: [], iteratorTypes: [], sourceFile: '/x', operands: [], opCount: 1,
    ...partial,
  };
}

function matmul(M: number, N: number, K: number, levels: Array<[string, number[]]>, form: 'gpu' | 'codegen' | 'cpu' = 'gpu'): DispatchInfo {
  return mk({
    iterationDomain: [M, N, K],
    iteratorTypes: ['parallel', 'parallel', 'reduction'],
    config: { form, levels: levels.map(([name, sizes]) => ({ name, sizes })), raw: '' },
    operands: [
      { name: '%a', role: 'input', shape: [M, K], elementType: 'f16', elementBytes: 2, dimMap: [0, 2] },
      { name: '%b', role: 'input', shape: [K, N], elementType: 'f16', elementBytes: 2, dimMap: [2, 1] },
      { name: '%c', role: 'output', shape: [M, N], elementType: 'f32', elementBytes: 4, dimMap: [0, 1] },
    ],
    sharedMemoryBudgetBytes: 65536,
  });
}

describe('512x512x512 matmul on a GPU target, three levels', () => {
  const d = matmul(512, 512, 512, [['workgroup', [128, 128, 0]], ['reduction', [0, 0, 32]], ['thread', [8, 4, 0]]]);
  const g = computeTilingGeometry(d)!;

  it('computes tile counts per level (checked by hand)', () => {
    expect(g.levels.map((l) => [l.name, l.effective, l.tilesPerDim, l.tilesTotal])).toEqual([
      ['workgroup', [128, 128, 512], [4, 4, 1], 16],
      ['reduction', [128, 128, 32], [1, 1, 16], 16],
      ['thread', [8, 4, 32], [16, 32, 1], 512],
    ]);
    expect(g.workgroupCount).toBe(16);
    expect(g.levels.every((l) => l.raggedDims.length === 0)).toBe(true);
    expect(g.warnings).toEqual(['More than 2000 tiles; deeper levels are summarised as hatched regions.']);
  });

  it('draws workgroup tiles as rects and collapses thread tiles past the rect cap', () => {
    // 480px canvas / 512 => 0.9375 px per element: an 8x4 thread tile is ~7.5x3.75px (>= 3px), so drawn...
    // ...but 16 workgroups * 512 threads = 8192 rects exceeds the 2000 cap, so it collapses to one hatch.
    expect(g.rects.filter((r) => r.level === 0)).toHaveLength(16);
    expect(g.rects[0]).toEqual({ level: 0, x: 0, y: 0, w: 128, h: 128, ragged: false });
    expect(g.rects[3]).toEqual({ level: 0, x: 384, y: 0, w: 128, h: 128, ragged: false });
    expect(g.rects.filter((r) => r.level === 1)).toHaveLength(0); // reduction level doesn't tile the axes
    expect(g.hatches).toEqual([{ level: 2, x: 0, y: 0, w: 512, h: 512, count: 8192 }]);
    expect(g.truncated).toBe(true);
    expect(g.rects.length + g.hatches.length).toBeLessThanOrEqual(2000);
  });

  it('draws the reduction strip', () => {
    expect(g.reductionDims).toEqual([2]);
    expect(g.reductionRects.filter((r) => r.level === 1)).toHaveLength(16);
    expect(g.reductionRects[0]).toEqual({ level: 1, x: 0, y: 1, w: 32, h: 1, ragged: false });
  });

  it('computes per-workgroup operand footprints', () => {
    expect(g.footprints).toEqual([
      { name: '%a', role: 'input', tileShape: [128, 32], bytes: 128 * 32 * 2 },
      { name: '%b', role: 'input', tileShape: [32, 128], bytes: 32 * 128 * 2 },
      { name: '%c', role: 'output', tileShape: [128, 128], bytes: 128 * 128 * 4 },
    ]);
    expect(g.footprintTotalBytes).toBe(81920);
    expect(g.fitsSharedMemory).toBe(false);
  });
});

describe('ragged tiles', () => {
  it('dim 100 with tile 32 flags the remainder', () => {
    const d = matmul(100, 64, 16, [['workgroup', [32, 64, 0]]]);
    const g = computeTilingGeometry(d)!;
    expect(g.levels[0].raggedDims).toEqual([0]);
    expect(g.levels[0].tilesPerDim).toEqual([4, 1, 1]);
    expect(g.workgroupCount).toBe(4);
    expect(g.warnings).toContain('workgroup: d0 extent 100 is not divisible by tile 32; remainder tile of 4.');
    // Rows = M (vertical), columns = N.
    expect(g.axes).toEqual([1, 0]);
    expect(g.rects).toEqual([
      { level: 0, x: 0, y: 0, w: 64, h: 32, ragged: false },
      { level: 0, x: 0, y: 32, w: 64, h: 32, ragged: false },
      { level: 0, x: 0, y: 64, w: 64, h: 32, ragged: false },
      { level: 0, x: 0, y: 96, w: 64, h: 4, ragged: true },
    ]);
  });

  it('nested level ragged against its parent tile, not the domain', () => {
    const d = matmul(64, 64, 8, [['workgroup', [48, 64, 0]], ['thread', [32, 64, 0]]]);
    const s = computeLevelStats(d);
    expect(s.levels[1].raggedDims).toEqual([0]); // 48 % 32
    expect(s.levels[0].raggedDims).toEqual([0]); // 64 % 48
  });
});

describe('sub-3px tiles become hatched regions', () => {
  it('hatches per parent when tiles are too small to draw', () => {
    const d = matmul(512, 512, 8, [['workgroup', [256, 256, 0]], ['thread', [1, 1, 0]]]);
    const g = computeTilingGeometry(d)!;
    expect(g.rects.filter((r) => r.level === 0)).toHaveLength(4);
    expect(g.hatches).toHaveLength(4);
    expect(g.hatches[0]).toEqual({ level: 1, x: 0, y: 0, w: 256, h: 256, count: 65536 });
    expect(g.truncated).toBe(false);
  });
});

describe('fallbacks', () => {
  it('no iteration domain -> undefined geometry (table view), stats still available', () => {
    const d = mk({
      opName: 'linalg.generic',
      config: { form: 'codegen', levels: [{ name: 'level 0', sizes: [4, 8] }], raw: '' },
    });
    expect(computeTilingGeometry(d)).toBeUndefined();
    expect(computeLevelStats(d).levels[0].sizes).toEqual([4, 8]);
  });

  it('only-reduction ops have no drawing axes', () => {
    expect(pickAxes(mk({ iterationDomain: [128], iteratorTypes: ['reduction'] }))).toBeUndefined();
  });

  it('1-D parallel domains draw along x only', () => {
    const d = mk({
      iterationDomain: [8, 100], iteratorTypes: ['parallel', 'reduction'],
      config: { form: 'codegen', levels: [{ name: 'level 0', sizes: [2, 0] }], raw: '' },
    });
    const g = computeTilingGeometry(d)!;
    expect(g.axes).toEqual([0, -1]);
    expect(g.rects.map((r) => [r.x, r.w])).toEqual([[0, 2], [2, 2], [4, 2], [6, 2]]);
  });

  it('tile larger than the domain is clamped with a warning', () => {
    const g = computeTilingGeometry(matmul(64, 64, 64, [['workgroup', [128, 64, 0]]]))!;
    expect(g.levels[0].effective).toEqual([64, 64, 64]);
    expect(g.warnings[0]).toMatch(/exceeds the enclosing extent/);
  });
});

describe('real fixtures', () => {
  const load = (name: string) => {
    const dir = path.join(dump(name), 'configs');
    const f = path.join(dir, readdirSync(dir).find((x) => x.endsWith('.mlir'))!);
    return parseDispatchFile(readFileSync(f, 'utf8'), f)[0];
  };

  it('reduction on llvm-cpu: 8x100 row sum', () => {
    const g = computeTilingGeometry(load('reduction-llvm-cpu'))!;
    expect(g.levels.map((l) => [l.name, l.sizes])).toEqual([
      ['distribution', [1, 0]], ['vector_common_parallel', [1, 0]], ['vector_reduction', [0, 4]],
    ]);
    expect(g.workgroupCount).toBe(8);
    expect(g.reductionRects.filter((r) => r.level === 2)).toHaveLength(25);
  });

  it('reduction on vulkan: a short tile list tiles only the leading dims', () => {
    const g = computeTilingGeometry(load('reduction-vulkan-spirv'))!;
    expect(g.levels[0].sizes).toEqual([32]);
    // Only one tile size for a 2-D op: d0 = 8 is tiled by 32 (clamped), d1 untiled.
    expect(g.levels[0].effective).toEqual([8, 100]);
  });

  it('matmul changes with the target', () => {
    const cpu = computeTilingGeometry(load('matmul-llvm-cpu'))!;
    const gpu = computeTilingGeometry(load('matmul-vulkan-spirv'))!;
    expect(cpu.workgroupCount).toBe(8);
    expect(gpu.workgroupCount).toBe(1); // [64, 64, 16]: the 16 is a reduction loop, not distributed
    expect(cpu.rects).not.toEqual(gpu.rects);
  });

  it('conv footprint includes the window halo', () => {
    const d = load('conv-llvm-cpu');
    const g = computeTilingGeometry(d)!;
    // distribution = [0, 1, 14, 8, 0, 0, 0], vector_reduction = [0, 0, 0, 0, 1, 1, 4]:
    // input rows = (oh 1 - 1) + (kh 1 - 1) + 1 = 1, cols = (ow 14 - 1) + (kw 1 - 1) + 1 = 14.
    expect(g.footprints.map((f) => f.tileShape)).toEqual([[1, 1, 14, 4], [1, 1, 4, 8], [1, 1, 14, 8]]);
    // With a full 3x3 window the halo shows up: rows = 1 + 3 - 1.
    const full = { ...d, config: { ...d.config!, levels: d.config!.levels.filter((l) => l.name === 'distribution') } };
    const g2 = computeTilingGeometry(full)!;
    expect(g2.footprints[0].tileShape).toEqual([1, 3, 16, 4]);
    expect(computeFootprints(d, g.levels).total).toBe(g.footprintTotalBytes);
  });
});

describe('hardware limits from the IR', () => {
  const text = (name: string) => {
    const dir = path.join(dump(name), 'configs');
    return readFileSync(path.join(dir, readdirSync(dir).find((x) => x.endsWith('.mlir'))!), 'utf8');
  };

  it('reads GPU limits from #iree_gpu.target', () => {
    expect(parseTargetHardware(text('matmul-vulkan-spirv'))).toEqual({
      kind: 'gpu', backend: 'vulkan-spirv', arch: 'rdna3', maxWorkgroupMemoryBytes: 65536,
      maxThreadsPerWorkgroup: 1024, subgroupSizes: [32, 64], computeUnits: undefined,
    });
    expect(parseTargetHardware('#iree_gpu.target<arch = "gfx942", wgp = <max_workgroup_memory_bytes = 65536>, chip = <wgp_count = 304>>')?.computeUnits).toBe(304);
  });

  it('reads CPU SIMD width', () => {
    expect(parseTargetHardware(text('matmul-llvm-cpu'))).toMatchObject({ kind: 'cpu', backend: 'llvm-cpu', arch: 'generic', nativeVectorBytes: 16 });
    expect(parseTargetHardware('nothing here')).toBeUndefined();
  });
});

describe('checklist', () => {
  const load = (name: string) => {
    const dir = path.join(dump(name), 'configs');
    const f = path.join(dir, readdirSync(dir).find((x) => x.endsWith('.mlir'))!);
    return parseDispatchFile(readFileSync(f, 'utf8'), f)[0];
  };
  const run = (d: DispatchInfo) => computeChecks(d, computeTilingGeometry(d));

  it('real CPU matmul: even, vector tile = 2 registers', () => {
    const c = run(load('matmul-llvm-cpu'));
    expect(c.map((x) => [x.status, x.title])).toEqual([
      ['ok', 'Tiles divide the problem evenly'],
      ['ok', 'Vector tile fills whole SIMD registers'],
      ['info', '8 workgroups launched'],
    ]);
    expect(c[1].detail).toBe('N: 8 × f32 = 32 B; SIMD registers are 16 B (from the target) → 2 registers.');
  });

  it('real Vulkan matmul: memory from the target, unknown chip size', () => {
    const c = run(load('matmul-vulkan-spirv'));
    expect(c.map((x) => x.status)).toEqual(['ok', 'ok', 'info', 'ok']);
    expect(c[1].detail).toMatch(/= 8 KiB of 64 KiB \(limit from the target\)/);
    expect(c[3].detail).toBe('[16, 8, 1] = 128 threads (limit 1024), 4 subgroups of 32.');
  });

  it('GPU warnings: too big, too few workgroups, odd thread count', () => {
    const d = matmul(512, 512, 512, [['workgroup', [256, 256, 0]], ['reduction', [0, 0, 128]]]);
    d.hardware = { kind: 'gpu', maxWorkgroupMemoryBytes: 65536, maxThreadsPerWorkgroup: 1024, subgroupSizes: [64], computeUnits: 304 };
    d.translation = { workgroupSize: [96, 1, 1], raw: '' };
    const c = run(d);
    expect(c.map((x) => [x.status, x.title])).toEqual([
      ['ok', 'Tiles divide the problem evenly'],
      ['warn', 'Input tiles are too big for workgroup memory'],
      ['warn', 'Too few workgroups to fill the GPU'],
      ['warn', 'Threads are not a whole number of subgroups'],
    ]);
    expect(c[2].detail).toBe('4 workgroups for 304 compute units: at most 1% busy. Use smaller workgroup tiles.');
  });

  it('uses M/N/K names for named ops', () => {
    const d = matmul(100, 64, 16, [['workgroup', [32, 64, 0]]]);
    d.dimNames = ['M', 'N', 'K'];
    const c = run(d);
    expect(c[0].detail).toBe('workgroup: M = 100 split by 32 leaves a last tile of 4. 1 of 4 workgroup tiles are partial.');
  });

  it('degrades to info when the IR has no target', () => {
    const d = matmul(64, 64, 64, [['workgroup', [32, 32, 0]]]);
    expect(run(d).at(-1)).toMatchObject({ status: 'info', title: 'Hardware limits not found in the IR' });
    expect(computeChecks({ ...d, config: undefined }, undefined)[0].title).toBe('No tile sizes on this dispatch');
  });
});
