// -----// IR Dump After MaterializeEncodingsPass: iree-stream-materialize-encodings //----- //
#executable_target_embedded_elf_arm_64 = #hal.executable.target<"llvm-cpu", "embedded-elf-arm_64", {cpu = "generic", cpu_features = "+reserve-x18", data_layout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-Fn32", iree.encoding.resolver = #iree_cpu.cpu_encoding_resolver<>, max_stack_allocation_size = 32768 : i64, native_vector_size = 16 : i64, target_triple = "arm64-unknown-unknown-eabi-elf"}>
#device_target_local = #hal.device.target<"local", [#executable_target_embedded_elf_arm_64]> : !hal.device
module attributes {stream.affinity.default = #hal.device.affinity<@__device_0>} {
  util.global private @__device_0 = #device_target_local
  stream.executable private @matmul_dispatch_0 {
    stream.executable.export public @matmul_dispatch_0_matmul_64x64x64_f32 workgroups() -> (index, index, index) {
      %x, %y, %z = iree_tensor_ext.dispatch.workgroup_count_from_slice()
      stream.return %x, %y, %z : index, index, index
    }
    builtin.module {
      func.func @matmul_dispatch_0_matmul_64x64x64_f32(%arg0: !stream.binding, %arg1: !stream.binding, %arg2: !stream.binding) {
        %cst = arith.constant 0.000000e+00 : f32
        %c0 = arith.constant 0 : index
        %0 = stream.binding.subspan %arg0[%c0] : !stream.binding -> !iree_tensor_ext.dispatch.tensor<readonly:tensor<64x64xf32>>
        %1 = stream.binding.subspan %arg1[%c0] : !stream.binding -> !iree_tensor_ext.dispatch.tensor<readonly:tensor<64x64xf32>>
        %2 = stream.binding.subspan %arg2[%c0] : !stream.binding -> !iree_tensor_ext.dispatch.tensor<writeonly:tensor<64x64xf32>>
        %3 = iree_tensor_ext.dispatch.tensor.load %0, offsets = [0, 0], sizes = [64, 64], strides = [1, 1] : !iree_tensor_ext.dispatch.tensor<readonly:tensor<64x64xf32>> -> tensor<64x64xf32>
        %4 = iree_tensor_ext.dispatch.tensor.load %1, offsets = [0, 0], sizes = [64, 64], strides = [1, 1] : !iree_tensor_ext.dispatch.tensor<readonly:tensor<64x64xf32>> -> tensor<64x64xf32>
        %5 = tensor.empty() : tensor<64x64xf32>
        %6 = linalg.fill ins(%cst : f32) outs(%5 : tensor<64x64xf32>) -> tensor<64x64xf32>
        %7 = linalg.matmul ins(%3, %4 : tensor<64x64xf32>, tensor<64x64xf32>) outs(%6 : tensor<64x64xf32>) -> tensor<64x64xf32>
        iree_tensor_ext.dispatch.tensor.store %7, %2, offsets = [0, 0], sizes = [64, 64], strides = [1, 1] : tensor<64x64xf32> -> !iree_tensor_ext.dispatch.tensor<writeonly:tensor<64x64xf32>>
        return
      }
    }
  }
  util.func public @matmul(%arg0: !hal.buffer_view, %arg1: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @matmul(%input0: tensor<64x64xf32>, %input1: tensor<64x64xf32>) -> (%output0: tensor<64x64xf32>)"}} {
    %c0 = arith.constant 0 : index
    %c16384 = arith.constant 16384 : index
    %c64 = arith.constant 64 : index
    %element_type_f32 = hal.element_type<f32> : i32
    %dense_row_major = hal.encoding_type<dense_row_major> : i32
    hal.buffer_view.assert<%arg0 : !hal.buffer_view> message("input0") shape([%c64, %c64]) type(%element_type_f32) encoding(%dense_row_major)
    %0 = stream.tensor.import on(#hal.device.affinity<@__device_0>) %arg0 : !hal.buffer_view -> tensor<64x64xf32> in !stream.resource<external>{%c16384}
    %1 = stream.async.cast on(#hal.device.affinity<@__device_0>) %0 : !stream.resource<external>{%c16384} -> !stream.resource<*>{%c16384}
    hal.buffer_view.assert<%arg1 : !hal.buffer_view> message("input1") shape([%c64, %c64]) type(%element_type_f32) encoding(%dense_row_major)
    %2 = stream.tensor.import on(#hal.device.affinity<@__device_0>) %arg1 : !hal.buffer_view -> tensor<64x64xf32> in !stream.resource<external>{%c16384}
    %3 = stream.async.cast on(#hal.device.affinity<@__device_0>) %2 : !stream.resource<external>{%c16384} -> !stream.resource<*>{%c16384}
    %4 = stream.async.dispatch on(#hal.device.affinity<@__device_0>) @matmul_dispatch_0::@matmul_dispatch_0_matmul_64x64x64_f32(%1[%c0 to %c16384 for %c16384], %3[%c0 to %c16384 for %c16384]) : (!stream.resource<*>{%c16384}, !stream.resource<*>{%c16384}) -> !stream.resource<*>{%c16384}
    %5 = stream.async.cast on(#hal.device.affinity<@__device_0>) %4 : !stream.resource<*>{%c16384} -> !stream.resource<external>{%c16384}
    %6 = stream.tensor.export on(#hal.device.affinity<@__device_0>) %5 : tensor<64x64xf32> in !stream.resource<external>{%c16384} -> !hal.buffer_view
    util.return %6 : !hal.buffer_view
  }
}


