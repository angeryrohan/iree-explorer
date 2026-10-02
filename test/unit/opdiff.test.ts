import { readFileSync } from 'fs';
import { describe, expect, it } from 'vitest';
import { alignKeys, diffOps, extractOps, normalizeOp, opNameOf } from '../../src/model/opdiff';
import { dump } from './helpers';

const ir = (name: string) => readFileSync(dump(`matmul-llvm-cpu/ir/builtin_module_no-symbol-name/${name}`), 'utf8');

describe('opNameOf', () => {
  it.each([
    ['    %0 = arith.addf %a, %b : f32', 'arith.addf'],
    ['    %ok, %value = hal.device.query<%d : !hal.device> key("a" :: "b") : i1, i1 = false', 'hal.device.query'],
    ['    %1:3 = scf.while (%arg0 = %c0) : (index) -> (index) {', 'scf.while'],
    ['    cf.br ^bb1(%c0 : index)', 'cf.br'],
    ['  %0 = "test.op"(%x) : (i32) -> i32', 'test.op'],
    ['  "test.side_effect"() : () -> ()', 'test.side_effect'],
    ['module attributes {iree.fixedpoint.iteration = 3 : index} {', 'module'],
    ['  util.global private @__device_0 : !hal.device', 'util.global'],
    ['    spirv.Return', 'spirv.Return'],
  ])('%s', (line, name) => {
    expect(opNameOf(line)).toBe(name);
  });

  it.each([
    '  ^bb1(%1: index):  // 2 preds: ^bb0, ^bb4',
    '  }',
    '  } -> tensor<4xf32>',
    '// -----// IR Dump After CSE //----- //',
    '#map = affine_map<(d0) -> (d0)>',
    '    iree.fixedpoint.iteration = 3 : index,',
    '    ins(%a : tensor<4xf32>) outs(%b : tensor<4xf32>) {',
    '  %arg0: tensor<4xf32>,',
    '',
  ])('not an op: %s', (line) => {
    expect(opNameOf(line)).toBeUndefined();
  });
});

describe('normalizeOp', () => {
  it('ignores value names, block names and locations', () => {
    expect(normalizeOp('%5 = arith.addi %3, %c1 : index loc("x.mlir":3:4)'))
      .toBe(normalizeOp('%12 = arith.addi %9,   %c1_0 : index'));
    expect(normalizeOp('cf.br ^bb3(%7 : i1)')).toBe(normalizeOp('cf.br ^bb1(%2 : i1)'));
  });
});

describe('alignKeys', () => {
  it('matches the longest common subsequence', () => {
    expect(alignKeys(['a', 'b', 'c', 'd'], ['a', 'x', 'c', 'd', 'e'])).toEqual([[0, 0], [2, 2], [3, 3]]);
  });

  it('handles repeated keys with no unique anchors', () => {
    expect(alignKeys(['k', 'k', 'k'], ['k', 'z', 'k'])).toEqual([[0, 0], [2, 2]]);
  });
});

describe('diffOps', () => {
  const before = [
    'func.func @f(%arg0: f32) -> f32 {',
    '  %0 = arith.addf %arg0, %arg0 : f32',
    '  %1 = arith.mulf %0, %0 : f32',
    '  return %1 : f32',
    '}',
  ].join('\n');

  it('reports nothing when only value names change', () => {
    const d = diffOps(before, before.replace(/%0/g, '%x').replace(/%1/g, '%y'));
    expect(d).toMatchObject({ added: 0, removed: 0, modified: 0, counts: [], changes: [] });
  });

  it('classifies added, removed and modified ops', () => {
    const after = [
      'func.func @f(%arg0: f32) -> f32 {',
      '  %0 = arith.addf %arg0, %arg0 fastmath<fast> : f32',
      '  %1 = math.sqrt %0 : f32',
      '  return %1 : f32',
      '}',
    ].join('\n');
    const d = diffOps(before, after);
    expect(d).toMatchObject({ totalBefore: 3, totalAfter: 3, added: 1, removed: 1, modified: 1 });
    expect(d.changes.map((c) => [c.kind, c.name, c.before?.line, c.after?.line])).toEqual([
      ['modified', 'arith.addf', 2, 2],
      ['removed', 'arith.mulf', 3, undefined],
      ['added', 'math.sqrt', undefined, 3],
    ]);
    expect(d.counts).toEqual([
      { name: 'arith.mulf', dialect: 'arith', before: 1, after: 0, modified: 0 },
      { name: 'math.sqrt', dialect: 'math', before: 0, after: 1, modified: 0 },
      { name: 'arith.addf', dialect: 'arith', before: 1, after: 1, modified: 1 },
    ]);
  });

  it('sees iree-import-public turn func.func into util.func', () => {
    const d = diffOps(ir('0_iree-auto-input-conversion.mlir'), ir('1_iree-import-public.mlir'));
    const kinds = Object.fromEntries(d.counts.map((c) => [c.name, c.after - c.before]));
    expect(kinds).toMatchObject({ 'func.func': -1, 'util.func': 1, 'util.return': 1 });
    expect(d.changes.find((c) => c.name === 'util.func')?.after?.text).toMatch(/^util\.func public @matmul\(/);
  });

  it('sees inline remove the call to the wrapped function', () => {
    const d = diffOps(ir('6_iree-abi-wrap-entry-points.mlir'), ir('7_inline.mlir'));
    expect(d.counts.find((c) => c.name === 'util.call')).toMatchObject({ before: 1, after: 0 });
    expect(d.changes.some((c) => c.kind === 'removed' && c.name === 'util.call')).toBe(true);
  });

  it('finds every op in a real dump', () => {
    const ops = extractOps(ir('198_iree-util-ipo.mlir'));
    expect(ops.length).toBeGreaterThan(50);
    expect(ops[0]).toMatchObject({ name: 'module', line: 2 });
    expect(new Set(ops.map((o) => o.name))).toContain('hal.device.query');
  });
});
