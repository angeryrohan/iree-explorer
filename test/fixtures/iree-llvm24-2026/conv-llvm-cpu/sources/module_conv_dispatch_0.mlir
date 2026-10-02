hal.executable public @conv_dispatch_0 {
  hal.executable.variant public @embedded_elf_arm_64 target(<"llvm-cpu", "embedded-elf-arm_64", {cpu = "generic", cpu_features = "+reserve-x18", data_layout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-Fn32", iree.encoding.resolver = #iree_cpu.cpu_encoding_resolver<>, max_stack_allocation_size = 32768 : i64, native_vector_size = 16 : i64, target_triple = "arm64-unknown-unknown-eabi-elf"}>) {
    hal.executable.export public @conv_dispatch_0_conv_14x14x8x3x3x4_f32 ordinal(0) layout(#hal.pipeline.layout<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) count(%arg0: !hal.device) -> (index, index, index) {
      %x, %y, %z = iree_tensor_ext.dispatch.workgroup_count_from_slice()
      hal.return %x, %y, %z : index, index, index
    }
    builtin.module {
      func.func @conv_dispatch_0_conv_14x14x8x3x3x4_f32() {
        %cst = arith.constant 0.000000e+00 : f32
        %c0 = arith.constant 0 : index
        %0 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(0) alignment(64) offset(%c0) flags("ReadOnly|Indirect") : !iree_tensor_ext.dispatch.tensor<readonly:tensor<16x16x4xf32>>
        %1 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(1) alignment(64) offset(%c0) flags("ReadOnly|Indirect") : !iree_tensor_ext.dispatch.tensor<readonly:tensor<3x3x4x8xf32>>
        %2 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(2) alignment(64) offset(%c0) flags(Indirect) : !iree_tensor_ext.dispatch.tensor<writeonly:tensor<14x14x8xf32>>
        %3 = iree_tensor_ext.dispatch.tensor.load %0, offsets = [0, 0, 0], sizes = [16, 16, 4], strides = [1, 1, 1] : !iree_tensor_ext.dispatch.tensor<readonly:tensor<16x16x4xf32>> -> tensor<16x16x4xf32>
        %4 = iree_tensor_ext.dispatch.tensor.load %1, offsets = [0, 0, 0, 0], sizes = [3, 3, 4, 8], strides = [1, 1, 1, 1] : !iree_tensor_ext.dispatch.tensor<readonly:tensor<3x3x4x8xf32>> -> tensor<3x3x4x8xf32>
        %5 = tensor.empty() : tensor<14x14x8xf32>
        %6 = linalg.fill ins(%cst : f32) outs(%5 : tensor<14x14x8xf32>) -> tensor<14x14x8xf32>
        %7 = linalg.generic {indexing_maps = [affine_map<(d0, d1, d2, d3, d4, d5) -> (d0 + d3, d1 + d4, d5)>, affine_map<(d0, d1, d2, d3, d4, d5) -> (d3, d4, d5, d2)>, affine_map<(d0, d1, d2, d3, d4, d5) -> (d0, d1, d2)>], iterator_types = ["parallel", "parallel", "parallel", "reduction", "reduction", "reduction"]} ins(%3, %4 : tensor<16x16x4xf32>, tensor<3x3x4x8xf32>) outs(%6 : tensor<14x14x8xf32>) {
        ^bb0(%in: f32, %in_0: f32, %out: f32):
          %8 = arith.mulf %in, %in_0 : f32
          %9 = arith.addf %out, %8 : f32
          linalg.yield %9 : f32
        } -> tensor<14x14x8xf32>
        iree_tensor_ext.dispatch.tensor.store %7, %2, offsets = [0, 0, 0], sizes = [14, 14, 8], strides = [1, 1, 1] : tensor<14x14x8xf32> -> !iree_tensor_ext.dispatch.tensor<writeonly:tensor<14x14x8xf32>>
        return
      }
    }
  }
}
