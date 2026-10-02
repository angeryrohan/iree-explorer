// -----// IR Dump After OutlineConstantsPass: iree-flow-outline-constants //----- //
#executable_target_embedded_elf_arm_64 = #hal.executable.target<"llvm-cpu", "embedded-elf-arm_64", {cpu = "generic", cpu_features = "+reserve-x18", data_layout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-Fn32", iree.encoding.resolver = #iree_cpu.cpu_encoding_resolver<>, max_stack_allocation_size = 32768 : i64, native_vector_size = 16 : i64, target_triple = "arm64-unknown-unknown-eabi-elf"}>
#device_target_local = #hal.device.target<"local", [#executable_target_embedded_elf_arm_64]> : !hal.device
module attributes {iree.fixedpoint.iteration = 0 : index, stream.affinity.default = #hal.device.affinity<@__device_0>} {
  util.global private @__device_0 = #device_target_local
  flow.executable private @matmul_dispatch_0 {
    flow.executable.export public @matmul_dispatch_0_matmul_64x64x64_f32 workgroups() -> (index, index, index) {
      %x, %y, %z = iree_tensor_ext.dispatch.workgroup_count_from_slice()
      flow.return %x, %y, %z : index, index, index
    }
    builtin.module {
      func.func @matmul_dispatch_0_matmul_64x64x64_f32(%arg0: !iree_tensor_ext.dispatch.tensor<readonly:tensor<64x64xf32>>, %arg1: !iree_tensor_ext.dispatch.tensor<readonly:tensor<64x64xf32>>, %arg2: !iree_tensor_ext.dispatch.tensor<writeonly:tensor<64x64xf32>>) {
        %cst = arith.constant 0.000000e+00 : f32
        %0 = iree_tensor_ext.dispatch.tensor.load %arg0, offsets = [0, 0], sizes = [64, 64], strides = [1, 1] : !iree_tensor_ext.dispatch.tensor<readonly:tensor<64x64xf32>> -> tensor<64x64xf32>
        %1 = iree_tensor_ext.dispatch.tensor.load %arg1, offsets = [0, 0], sizes = [64, 64], strides = [1, 1] : !iree_tensor_ext.dispatch.tensor<readonly:tensor<64x64xf32>> -> tensor<64x64xf32>
        %2 = tensor.empty() : tensor<64x64xf32>
        %3 = linalg.fill ins(%cst : f32) outs(%2 : tensor<64x64xf32>) -> tensor<64x64xf32>
        %4 = linalg.matmul ins(%0, %1 : tensor<64x64xf32>, tensor<64x64xf32>) outs(%3 : tensor<64x64xf32>) -> tensor<64x64xf32>
        iree_tensor_ext.dispatch.tensor.store %4, %arg2, offsets = [0, 0], sizes = [64, 64], strides = [1, 1] : tensor<64x64xf32> -> !iree_tensor_ext.dispatch.tensor<writeonly:tensor<64x64xf32>>
        return
      }
    }
  }
  util.func public @matmul(%arg0: !hal.buffer_view, %arg1: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @matmul(%input0: tensor<64x64xf32>, %input1: tensor<64x64xf32>) -> (%output0: tensor<64x64xf32>)"}} {
    %0 = hal.tensor.import %arg0 "input0" : !hal.buffer_view -> tensor<64x64xf32>
    %1 = hal.tensor.import %arg1 "input1" : !hal.buffer_view -> tensor<64x64xf32>
    %2 = flow.dispatch @matmul_dispatch_0::@matmul_dispatch_0_matmul_64x64x64_f32(%0, %1) : (tensor<64x64xf32>, tensor<64x64xf32>) -> tensor<64x64xf32>
    %3 = hal.tensor.export %2 "output0" : tensor<64x64xf32> -> !hal.buffer_view
    util.return %3 : !hal.buffer_view
  }
}


