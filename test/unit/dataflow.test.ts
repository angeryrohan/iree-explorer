import { readFileSync } from 'fs';
import { describe, expect, it } from 'vitest';
import { indexDump } from '../../src/model/artifacts';
import { findFlowDump, parseFlowProgram } from '../../src/model/dataflow';
import { dump, fixture } from './helpers';

describe('data flow', () => {
  it('two-layer MLP: inputs -> matmul -> matmul+tanh... -> output', () => {
    const p = parseFlowProgram(readFileSync(fixture('flow', 'mlp.flow.mlir'), 'utf8'), 'mlp.flow.mlir');
    expect(p.graphs).toHaveLength(1);
    const g = p.graphs[0];
    expect(g.func).toBe('mlp');
    expect(g.nodes.map((n) => [n.kind, n.label])).toEqual([
      ['input', 'input0'], ['input', 'input1'], ['input', 'input2'],
      ['dispatch', expect.stringMatching(/^dispatch_0: matmul/)],
      ['dispatch', expect.stringMatching(/^dispatch_1: matmul/)],
      ['output', 'output0'],
    ]);
    expect(g.nodes[3].results[0]).toEqual({ name: '%3', type: 'tensor<4x128xf32>', bytes: 2048 });
    expect(g.edges.map((e) => [e.from, e.to, e.value.type])).toEqual([
      [0, 3, 'tensor<4x64xf32>'], [1, 3, 'tensor<64x128xf32>'],
      [3, 4, 'tensor<4x128xf32>'], [2, 4, 'tensor<128x10xf32>'],
      [4, 5, 'tensor<4x10xf32>'],
    ]);
  });

  it('fused elementwise ops show up in the dispatch label', () => {
    const g = parseFlowProgram(readFileSync(fixture('flow', 'mlp.flow.mlir'), 'utf8'), 'x').graphs[0];
    const all = g.nodes.filter((n) => n.kind === 'dispatch').flatMap((n) => n.ops ?? []);
    expect(all).toContain('tanh');
  });

  it('finds the flow-level module in a real dump', async () => {
    const idx = await indexDump(dump('matmul-llvm-cpu'));
    const found = await findFlowDump(idx.passes, async (f) => readFileSync(f, 'utf8'));
    expect(found).toBeDefined();
    const g = parseFlowProgram(found!.text, found!.file).graphs[0];
    expect(g.nodes.map((n) => n.kind)).toEqual(['input', 'input', 'dispatch', 'output']);
    expect(g.nodes[2].entry).toBe('matmul_dispatch_0_matmul_64x64x64_f32');
  });

  it('never throws on garbage', () => {
    expect(parseFlowProgram('', 'x').graphs).toEqual([]);
    expect(parseFlowProgram('  util.func public @f(\n    %0 = flow.dispatch @a::@b(%9 : (tensor<', 'x').graphs).toHaveLength(1);
  });
});
