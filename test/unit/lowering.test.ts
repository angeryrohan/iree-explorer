import { readdirSync, readFileSync } from 'fs';
import * as path from 'path';
import { describe, expect, it } from 'vitest';
import {
  elementBytes, parseAffineMap, parseAliases, parseDispatchFile, parseIntList, parseLoweringConfig,
  parseShapedType, parseTranslationInfo, scanBalanced, splitTopLevel,
} from '../../src/model/lowering';
import { dump } from './helpers';

function configOf(name: string) {
  const dir = path.join(dump(name), 'configs');
  const file = path.join(dir, readdirSync(dir).find((f) => f.endsWith('.mlir'))!);
  return parseDispatchFile(readFileSync(file, 'utf8'), file);
}

describe('scanner', () => {
  it('balances nested delimiters and skips affine arrows and strings', () => {
    const s = '#a<x = [1, [2]], m = affine_map<(d0) -> (d0)>, s = "a>b">tail';
    expect(s.slice(0, scanBalanced(s, 2))).toBe('#a<x = [1, [2]], m = affine_map<(d0) -> (d0)>, s = "a>b">');
    expect(scanBalanced('<[>', 0)).toBeUndefined();
    expect(scanBalanced('<<<', 0)).toBeUndefined();
    expect(splitTopLevel('a = [1, 2], b = {c = 3, d = 4}, e', ',')).toEqual(['a = [1, 2]', 'b = {c = 3, d = 4}', 'e']);
  });

  it('parses int lists, including scalable CPU sizes', () => {
    expect(parseIntList('[128, 128, 0]')).toEqual([128, 128, 0]);
    expect(parseIntList('[8, [16], 0]')).toEqual([8, 16, 0]);
    expect(parseIntList('[]')).toEqual([]);
    expect(parseIntList('[1, x]')).toBeUndefined();
    expect(parseIntList('[1, 2')).toBeUndefined();
  });
});

describe('lowering_config forms', () => {
  it('Form A: #iree_codegen tile_sizes', () => {
    expect(parseLoweringConfig('#iree_codegen.lowering_config<tile_sizes = [[128, 128, 0], [32, 32, 0], [0, 0, 8]]>')).toEqual({
      form: 'codegen',
      levels: [
        { name: 'level 0', sizes: [128, 128, 0] },
        { name: 'level 1', sizes: [32, 32, 0] },
        { name: 'level 2', sizes: [0, 0, 8] },
      ],
      raw: '#iree_codegen.lowering_config<tile_sizes = [[128, 128, 0], [32, 32, 0], [0, 0, 8]]>',
    });
  });

  it('Form B: #iree_gpu named levels in display order, ignoring non-tile keys', () => {
    const c = parseLoweringConfig(`#iree_gpu.lowering_config<{workgroup = [128, 128, 0],
                                     reduction = [0, 0, 32],
                                     thread = [8, 4, 0],
                                     mma_kind = #iree_gpu.mma_layout<MFMA_F32_16x16x4_F32>,
                                     promote_operands = [0, 1],
                                     subgroup = [2, 2, 0]}>`);
    expect(c?.form).toBe('gpu');
    expect(c?.levels.map((l) => l.name)).toEqual(['workgroup', 'subgroup', 'reduction', 'thread']);
    expect(c?.levels[0].sizes).toEqual([128, 128, 0]);
  });

  it('CPU form as emitted by real llvm-cpu builds', () => {
    const c = parseLoweringConfig('#iree_cpu.lowering_config<cache_parallel = [8, 64, 0], distribution = [8, 64, 0], vector_common_parallel = [8, 8, 0], vector_reduction = [0, 0, 4]>');
    expect(c?.form).toBe('cpu');
    expect(c?.levels.map((l) => [l.name, l.sizes])).toEqual([
      ['distribution', [8, 64, 0]], ['cache_parallel', [8, 64, 0]],
      ['vector_common_parallel', [8, 8, 0]], ['vector_reduction', [0, 0, 4]],
    ]);
  });

  it('returns undefined for malformed or unknown forms', () => {
    expect(parseLoweringConfig('#iree_codegen.lowering_config<tile_sizes = [[1, 2>')).toBeUndefined();
    expect(parseLoweringConfig('#iree_codegen.lowering_config<tile_sizes = [[a]]>')).toBeUndefined();
    expect(parseLoweringConfig('#iree_foo.lowering_config<x = [1]>')).toBeUndefined();
    expect(parseLoweringConfig('#iree_gpu.lowering_config<{mma_kind = #x<y>}>')).toBeUndefined();
    expect(parseLoweringConfig('')).toBeUndefined();
    expect(parseLoweringConfig('#config')).toBeUndefined();
  });
});

describe('translation_info', () => {
  it('parses spec form', () => {
    expect(parseTranslationInfo(`#iree_codegen.translation_info<pipeline = LLVMGPUTileAndFuse
                                              workgroup_size = [64, 1, 1]
                                              subgroup_size = 64>`)).toMatchObject({
      pipeline: 'LLVMGPUTileAndFuse', workgroupSize: [64, 1, 1], subgroupSize: 64,
    });
  });
  it('parses the nested-pipeline-attr form from real builds', () => {
    const cpu = parseTranslationInfo('#iree_codegen.translation_info<pipeline = #iree_cpu.pipeline<DoubleTilingExpert>, {enable_loop_peeling}>');
    expect(cpu?.pipeline).toBe('DoubleTilingExpert');
    expect(cpu?.workgroupSize).toBeUndefined();
    expect(parseTranslationInfo('#iree_codegen.translation_info<pipeline = #iree_gpu.spirv_pipeline<MatmulPromoteVectorize> workgroup_size = [16, 8, 1], {pipeline_depth = 2 : i64, store_stage = 0 : i64}>'))
      .toMatchObject({ pipeline: 'MatmulPromoteVectorize', workgroupSize: [16, 8, 1] });
  });
  it('rejects junk', () => {
    expect(parseTranslationInfo('#iree_codegen.translation_info<pipeline = ')).toBeUndefined();
    expect(parseTranslationInfo('nope')).toBeUndefined();
  });
});

describe('types and maps', () => {
  it('parses shaped types', () => {
    expect(parseShapedType('tensor<64x64xf32>')).toEqual({ shape: [64, 64], elementType: 'f32' });
    expect(parseShapedType('memref<64x?xf16, #hal.descriptor_type<storage_buffer>>')).toEqual({ shape: [64, -1], elementType: 'f16' });
    expect(parseShapedType('f32')).toEqual({ shape: [], elementType: 'f32' });
    expect(parseShapedType('tensor<64x')).toBeUndefined();
    expect(elementBytes('bf16')).toBe(2);
    expect(elementBytes('i8')).toBe(1);
    expect(elementBytes('f8E4M3FNUZ')).toBe(1);
    expect(elementBytes('weird')).toBeUndefined();
  });
  it('parses affine maps including conv windows', () => {
    expect(parseAffineMap('affine_map<(d0, d1, d2) -> (d0, d2)>')).toEqual({ numDims: 3, results: [0, 2] });
    expect(parseAffineMap('affine_map<(d0, d1, d2, d3, d4, d5, d6) -> (d0, d1 * 2 + d4, d2 + d5 * 2, d6)>')?.results).toEqual([
      0, { out: 1, stride: 2, win: 4, dilation: 1 }, { out: 2, stride: 1, win: 5, dilation: 2 }, 6,
    ]);
    expect(parseAffineMap('affine_map<(d0) -> (d0 floordiv 4)>')?.results).toEqual([-1]);
  });
  it('builds an alias map', () => {
    const a = parseAliases('#map = affine_map<(d0) -> (d0)>\n#config = #iree_codegen.lowering_config<tile_sizes = [[4]]>\nmodule {}');
    expect(a.get('#config')).toBe('#iree_codegen.lowering_config<tile_sizes = [[4]]>');
    expect(a.get('#map')).toBe('affine_map<(d0) -> (d0)>');
  });
});

describe('dispatch extraction (inline strings)', () => {
  it('resolves aliases for config, translation info and indexing maps', () => {
    const src = `#config = #iree_gpu.lowering_config<{workgroup = [64, 32, 0], reduction = [0, 0, 16]}>
#translation = #iree_codegen.translation_info<pipeline = LLVMGPUTileAndFuse workgroup_size = [256, 1, 1] subgroup_size = 64>
#map = affine_map<(d0, d1, d2) -> (d0, d2)>
#map1 = affine_map<(d0, d1, d2) -> (d2, d1)>
#map2 = affine_map<(d0, d1, d2) -> (d0, d1)>
hal.executable public @ex {
  hal.executable.variant public @rocm target(#target) {
    builtin.module {
      func.func @mm() attributes {translation_info = #translation} {
        %5 = linalg.generic {indexing_maps = [#map, #map1, #map2], iterator_types = ["parallel", "parallel", "reduction"]} ins(%1, %2 : tensor<256x100xf16>, tensor<100x128xf16>) outs(%4 : tensor<256x128xf32>) attrs =  {lowering_config = #config} {
        ^bb0(%in: f16, %in_0: f16, %out: f32):
          linalg.yield %out : f32
        } -> tensor<256x128xf32>
        return
      }
    }
  }
}`;
    const [d] = parseDispatchFile(src, '/x.mlir');
    expect(d.name).toBe('mm');
    expect(d.executable).toBe('ex');
    expect(d.variant).toBe('rocm');
    expect(d.opName).toBe('linalg.generic');
    expect(d.iterationDomain).toEqual([256, 128, 100]);
    expect(d.iteratorTypes).toEqual(['parallel', 'parallel', 'reduction']);
    expect(d.config?.levels.map((l) => l.name)).toEqual(['workgroup', 'reduction']);
    expect(d.translation).toMatchObject({ pipeline: 'LLVMGPUTileAndFuse', workgroupSize: [256, 1, 1], subgroupSize: 64 });
    expect(d.sourceLine).toBe(10);
    expect(d.operands.map((o) => [o.name, o.role, o.elementBytes])).toEqual([['%1', 'input', 2], ['%2', 'input', 2], ['%4', 'output', 4]]);
  });

  it('leaves the domain empty when it is dynamic (no guessing)', () => {
    const src = `func.func @dyn() {
  %r = linalg.matmul {lowering_config = #iree_codegen.lowering_config<tile_sizes = [[32, 32, 0]]>} ins(%a, %b : tensor<?x64xf32>, tensor<64x?xf32>) outs(%c : tensor<?x?xf32>) -> tensor<?x?xf32>
  return
}`;
    const [d] = parseDispatchFile(src, '/x');
    expect(d.config?.form).toBe('codegen');
    expect(d.iterationDomain).toEqual([]);
  });

  it('never throws on garbage', () => {
    expect(parseDispatchFile('', '/x')).toEqual([]);
    expect(parseDispatchFile('func.func @f( {{{{ <<<< linalg.matmul ins(', '/x')).toHaveLength(1);
    expect(parseDispatchFile(' '.repeat(100), '/x')).toEqual([]);
  });
});

describe('dispatch extraction (real configs dumps)', () => {
  it('matmul / llvm-cpu', () => {
    const [d] = configOf('matmul-llvm-cpu');
    expect(d.opName).toBe('linalg.matmul');
    expect(d.iterationDomain).toEqual([64, 64, 64]);
    expect(d.translation?.pipeline).toBe('DoubleTilingExpert');
    expect(d.config?.levels[0]).toEqual({ name: 'distribution', sizes: [8, 64, 0] });
    expect(d.opCount).toBe(2);
  });

  it('matmul / vulkan-spirv (Form A on a generalised matmul)', () => {
    const [d] = configOf('matmul-vulkan-spirv');
    expect(d.opName).toBe('linalg.generic');
    expect(d.iterationDomain).toEqual([64, 64, 64]);
    expect(d.config).toMatchObject({ form: 'codegen', levels: [{ name: 'level 0', sizes: [64, 64, 16] }] });
    expect(d.translation).toMatchObject({ pipeline: 'MatmulPromoteVectorize', workgroupSize: [16, 8, 1] });
  });

  it('conv / llvm-cpu recovers the domain through window maps', () => {
    const [d] = configOf('conv-llvm-cpu');
    expect(d.iterationDomain).toEqual([1, 14, 14, 8, 3, 3, 4]);
    expect(d.iteratorTypes.filter((t) => t === 'reduction')).toHaveLength(3);
    const input = d.operands[0];
    expect(input.dimMap?.[1]).toEqual({ out: 1, win: 4, stride: 1, dilation: 1 });
  });

  it('conv / vulkan-spirv', () => {
    const [d] = configOf('conv-vulkan-spirv');
    expect(d.iterationDomain).toEqual([14, 14, 8, 3, 3, 4]);
    expect(d.config?.form).toBe('codegen');
  });

  it('reduction / both targets', () => {
    const [cpu] = configOf('reduction-llvm-cpu');
    const [gpu] = configOf('reduction-vulkan-spirv');
    for (const d of [cpu, gpu]) {
      expect(d.opName).toBe('linalg.generic');
      expect(d.iterationDomain).toEqual([8, 100]);
      expect(d.iteratorTypes).toEqual(['parallel', 'reduction']);
      expect(d.config).toBeDefined();
    }
  });
});
