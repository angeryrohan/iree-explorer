// -----// IR Dump After LLVMCPUSelectLoweringStrategyPass: iree-llvmcpu-select-lowering-strategy //----- //
module {
  func.func @matmul_dispatch_0_matmul_64x64x64_f32() attributes {translation_info = #iree_codegen.translation_info<pipeline = #iree_cpu.pipeline<DoubleTilingExpert>, {enable_loop_peeling}>} {
    %cst = arith.constant 0.000000e+00 : f32
    %c0 = arith.constant 0 : index
    %0 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(0) alignment(64) offset(%c0) flags("ReadOnly|Indirect") : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
    %1 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(1) alignment(64) offset(%c0) flags("ReadOnly|Indirect") : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
    %2 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(2) alignment(64) offset(%c0) flags(Indirect) : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
    %3 = iree_codegen.load_from_buffer %0 : memref<64x64xf32, #hal.descriptor_type<storage_buffer>> -> tensor<64x64xf32>
    %4 = iree_codegen.load_from_buffer %1 : memref<64x64xf32, #hal.descriptor_type<storage_buffer>> -> tensor<64x64xf32>
    %5 = tensor.empty() : tensor<64x64xf32>
    %6 = linalg.fill {lowering_config = #iree_cpu.lowering_config<cache_parallel = [8, 64], vector_common_parallel = [8, 8]>} ins(%cst : f32) outs(%5 : tensor<64x64xf32>) -> tensor<64x64xf32>
    %7 = linalg.matmul {lowering_config = #iree_cpu.lowering_config<cache_parallel = [8, 64, 0], distribution = [8, 64, 0], vector_common_parallel = [8, 8, 0], vector_reduction = [0, 0, 4]>} ins(%3, %4 : tensor<64x64xf32>, tensor<64x64xf32>) outs(%6 : tensor<64x64xf32>) -> tensor<64x64xf32>
    iree_codegen.store_to_buffer %7, %2 : tensor<64x64xf32> into memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
    return
  }
  iree_codegen.dispatch_config @matmul_dispatch_0_matmul_64x64x64_f32 {
  ^bb0(%arg0: !hal.device):
    %x, %y, %z = iree_tensor_ext.dispatch.workgroup_count_from_slice()
    iree_codegen.yield %x, %y, %z : index, index, index
  }
}

