hal.executable public @conv_dispatch_0 {
  hal.executable.variant public @embedded_elf_arm_64 target(<"llvm-cpu", "embedded-elf-arm_64", {cpu = "generic", cpu_features = "+reserve-x18", data_layout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-Fn32", iree.encoding.resolver = #iree_cpu.cpu_encoding_resolver<>, max_stack_allocation_size = 32768 : i64, native_vector_size = 16 : i64, target_triple = "arm64-unknown-unknown-eabi-elf"}>) {
    hal.executable.export public @conv_dispatch_0_conv_14x14x8x3x3x4_f32 ordinal(0) layout(#hal.pipeline.layout<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) count(%arg0: !hal.device) -> (index, index, index) {
      %x, %y, %z = iree_tensor_ext.dispatch.workgroup_count_from_slice()
      hal.return %x, %y, %z : index, index, index
    }
    builtin.module {
      func.func @conv_dispatch_0_conv_14x14x8x3x3x4_f32() attributes {translation_info = #iree_codegen.translation_info<pipeline = #iree_cpu.pipeline<ConvTileAndDecomposeExpert>, {enable_loop_peeling}>} {
        %cst = arith.constant 0.000000e+00 : f32
        %c0 = arith.constant 0 : index
        %0 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(0) alignment(64) offset(%c0) flags("ReadOnly|Indirect") : memref<1x16x16x4xf32, #hal.descriptor_type<storage_buffer>>
        %1 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(1) alignment(64) offset(%c0) flags("ReadOnly|Indirect") : memref<3x3x4x8xf32, #hal.descriptor_type<storage_buffer>>
        %2 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(2) alignment(64) offset(%c0) flags(Indirect) : memref<1x14x14x8xf32, #hal.descriptor_type<storage_buffer>>
        %3 = iree_codegen.load_from_buffer %1 : memref<3x3x4x8xf32, #hal.descriptor_type<storage_buffer>> -> tensor<3x3x4x8xf32>
        %4 = tensor.empty() : tensor<1x14x14x8xf32>
        %5 = linalg.fill {lowering_config = #iree_cpu.lowering_config<vector_common_parallel = [1, 1, 4, 8]>} ins(%cst : f32) outs(%4 : tensor<1x14x14x8xf32>) -> tensor<1x14x14x8xf32>
        %6 = iree_codegen.load_from_buffer %0 : memref<1x16x16x4xf32, #hal.descriptor_type<storage_buffer>> -> tensor<1x16x16x4xf32>
        %7 = linalg.generic {indexing_maps = [affine_map<(d0, d1, d2, d3, d4, d5, d6) -> (d0, d1 + d4, d2 + d5, d6)>, affine_map<(d0, d1, d2, d3, d4, d5, d6) -> (d4, d5, d6, d3)>, affine_map<(d0, d1, d2, d3, d4, d5, d6) -> (d0, d1, d2, d3)>], iterator_types = ["parallel", "parallel", "parallel", "parallel", "reduction", "reduction", "reduction"]} ins(%6, %3 : tensor<1x16x16x4xf32>, tensor<3x3x4x8xf32>) outs(%5 : tensor<1x14x14x8xf32>) attrs =  {lowering_config = #iree_cpu.lowering_config<distribution = [0, 1, 14, 8, 0, 0, 0], vector_common_parallel = [1, 1, 4, 8, 0, 0, 0], vector_reduction = [0, 0, 0, 0, 1, 1, 4]>} {
        ^bb0(%in: f32, %in_0: f32, %out: f32):
          %8 = arith.mulf %in, %in_0 : f32
          %9 = arith.addf %out, %8 : f32
          linalg.yield %9 : f32
        } -> tensor<1x14x14x8xf32>
        iree_codegen.store_to_buffer %7, %2 : tensor<1x14x14x8xf32> into memref<1x14x14x8xf32, #hal.descriptor_type<storage_buffer>>
        return
      }
      iree_codegen.dispatch_config @conv_dispatch_0_conv_14x14x8x3x3x4_f32 {
      ^bb0(%arg0: !hal.device):
        %x, %y, %z = iree_tensor_ext.dispatch.workgroup_count_from_slice()
        iree_codegen.yield %x, %y, %z : index, index, index
      }
    }
  }
}
