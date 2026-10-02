// -----// IR Dump After SPIRVSelectLoweringStrategyPass: iree-spirv-select-lowering-strategy-pass //----- //
module {
  func.func @rowsum_dispatch_0_reduction_8x100_f32() attributes {translation_info = #iree_codegen.translation_info<pipeline = #iree_gpu.spirv_pipeline<BaseDistribute> workgroup_size = [32, 1, 1]>} {
    %cst = arith.constant 0.000000e+00 : f32
    %c0 = arith.constant 0 : index
    %0 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(0) alignment(64) offset(%c0) flags("ReadOnly|Indirect") : !iree_tensor_ext.dispatch.tensor<readonly:tensor<8x100xf32>>
    %1 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(1) alignment(64) offset(%c0) flags(Indirect) : !iree_tensor_ext.dispatch.tensor<writeonly:tensor<8xf32>>
    %2 = iree_tensor_ext.dispatch.tensor.load %0, offsets = [0, 0], sizes = [8, 100], strides = [1, 1] : !iree_tensor_ext.dispatch.tensor<readonly:tensor<8x100xf32>> -> tensor<8x100xf32>
    %3 = tensor.empty() : tensor<8xf32>
    %4 = linalg.fill ins(%cst : f32) outs(%3 : tensor<8xf32>) -> tensor<8xf32>
    %5 = linalg.generic {indexing_maps = [affine_map<(d0, d1) -> (d0, d1)>, affine_map<(d0, d1) -> (d0)>], iterator_types = ["parallel", "reduction"]} ins(%2 : tensor<8x100xf32>) outs(%4 : tensor<8xf32>) attrs =  {lowering_config = #iree_codegen.lowering_config<tile_sizes = [[32], [1]]>} {
    ^bb0(%in: f32, %out: f32):
      %6 = arith.addf %in, %out : f32
      linalg.yield %6 : f32
    } -> tensor<8xf32>
    iree_tensor_ext.dispatch.tensor.store %5, %1, offsets = [0], sizes = [8], strides = [1] : tensor<8xf32> -> !iree_tensor_ext.dispatch.tensor<writeonly:tensor<8xf32>>
    return
  }
  iree_codegen.dispatch_config @rowsum_dispatch_0_reduction_8x100_f32 {
  ^bb0(%arg0: !hal.device):
    %x, %y, %z = iree_tensor_ext.dispatch.workgroup_count_from_slice()
    iree_codegen.yield %x, %y, %z : index, index, index
  }
}

