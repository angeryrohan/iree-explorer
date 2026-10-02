module attributes {stream.affinity.default = #hal.device.affinity<@__device_0>} {
  util.global private @__device_0 = #hal.device.target<"local", [#hal.executable.target<"llvm-cpu", "embedded-elf-arm_64", {cpu = "", cpu_features = "+reserve-x18", data_layout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-Fn32", iree.encoding.resolver = #iree_cpu.cpu_encoding_resolver<>, max_stack_allocation_size = 32768 : i64, native_vector_size = 16 : i64, target_triple = "arm64-unknown-unknown-eabi-elf"}>]> : !hal.device
  flow.executable private @mlp_dispatch_0 {
    flow.executable.export public @mlp_dispatch_0_matmul_4x128x64_f32 workgroups() -> (index, index, index) {
      %x, %y, %z = iree_tensor_ext.dispatch.workgroup_count_from_slice()
      flow.return %x, %y, %z : index, index, index
    }
    builtin.module {
      func.func @mlp_dispatch_0_matmul_4x128x64_f32(%arg0: !iree_tensor_ext.dispatch.tensor<readonly:tensor<4x64xf32>>, %arg1: !iree_tensor_ext.dispatch.tensor<readonly:tensor<64x128xf32>>, %arg2: !iree_tensor_ext.dispatch.tensor<writeonly:tensor<4x128xf32>>) {
        %cst = arith.constant 0.000000e+00 : f32
        %0 = iree_tensor_ext.dispatch.tensor.load %arg0, offsets = [0, 0], sizes = [4, 64], strides = [1, 1] : !iree_tensor_ext.dispatch.tensor<readonly:tensor<4x64xf32>> -> tensor<4x64xf32>
        %1 = iree_tensor_ext.dispatch.tensor.load %arg1, offsets = [0, 0], sizes = [64, 128], strides = [1, 1] : !iree_tensor_ext.dispatch.tensor<readonly:tensor<64x128xf32>> -> tensor<64x128xf32>
        %2 = tensor.empty() : tensor<4x128xf32>
        %3 = linalg.fill ins(%cst : f32) outs(%2 : tensor<4x128xf32>) -> tensor<4x128xf32>
        %4 = linalg.matmul ins(%0, %1 : tensor<4x64xf32>, tensor<64x128xf32>) outs(%3 : tensor<4x128xf32>) -> tensor<4x128xf32>
        %5 = linalg.generic {indexing_maps = [affine_map<(d0, d1) -> (d0, d1)>, affine_map<(d0, d1) -> (d0, d1)>], iterator_types = ["parallel", "parallel"]} ins(%4 : tensor<4x128xf32>) outs(%2 : tensor<4x128xf32>) {
        ^bb0(%in: f32, %out: f32):
          %6 = math.tanh %in : f32
          linalg.yield %6 : f32
        } -> tensor<4x128xf32>
        iree_tensor_ext.dispatch.tensor.store %5, %arg2, offsets = [0, 0], sizes = [4, 128], strides = [1, 1] : tensor<4x128xf32> -> !iree_tensor_ext.dispatch.tensor<writeonly:tensor<4x128xf32>>
        return
      }
    }
  }
  flow.executable private @mlp_dispatch_1 {
    flow.executable.export public @mlp_dispatch_1_matmul_4x10x128_f32 workgroups() -> (index, index, index) {
      %x, %y, %z = iree_tensor_ext.dispatch.workgroup_count_from_slice()
      flow.return %x, %y, %z : index, index, index
    }
    builtin.module {
      func.func @mlp_dispatch_1_matmul_4x10x128_f32(%arg0: !iree_tensor_ext.dispatch.tensor<readonly:tensor<4x128xf32>>, %arg1: !iree_tensor_ext.dispatch.tensor<readonly:tensor<128x10xf32>>, %arg2: !iree_tensor_ext.dispatch.tensor<writeonly:tensor<4x10xf32>>) {
        %cst = arith.constant 0.000000e+00 : f32
        %0 = iree_tensor_ext.dispatch.tensor.load %arg0, offsets = [0, 0], sizes = [4, 128], strides = [1, 1] : !iree_tensor_ext.dispatch.tensor<readonly:tensor<4x128xf32>> -> tensor<4x128xf32>
        %1 = iree_tensor_ext.dispatch.tensor.load %arg1, offsets = [0, 0], sizes = [128, 10], strides = [1, 1] : !iree_tensor_ext.dispatch.tensor<readonly:tensor<128x10xf32>> -> tensor<128x10xf32>
        %2 = tensor.empty() : tensor<4x10xf32>
        %3 = linalg.fill ins(%cst : f32) outs(%2 : tensor<4x10xf32>) -> tensor<4x10xf32>
        %4 = linalg.matmul ins(%0, %1 : tensor<4x128xf32>, tensor<128x10xf32>) outs(%3 : tensor<4x10xf32>) -> tensor<4x10xf32>
        iree_tensor_ext.dispatch.tensor.store %4, %arg2, offsets = [0, 0], sizes = [4, 10], strides = [1, 1] : tensor<4x10xf32> -> !iree_tensor_ext.dispatch.tensor<writeonly:tensor<4x10xf32>>
        return
      }
    }
  }
  util.func public @mlp(%arg0: !hal.buffer_view, %arg1: !hal.buffer_view, %arg2: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @mlp(%input0: tensor<4x64xf32>, %input1: tensor<64x128xf32>, %input2: tensor<128x10xf32>) -> (%output0: tensor<4x10xf32>)"}} {
    %0 = hal.tensor.import %arg0 "input0" : !hal.buffer_view -> tensor<4x64xf32>
    %1 = hal.tensor.import %arg1 "input1" : !hal.buffer_view -> tensor<64x128xf32>
    %2 = hal.tensor.import %arg2 "input2" : !hal.buffer_view -> tensor<128x10xf32>
    %3 = flow.dispatch @mlp_dispatch_0::@mlp_dispatch_0_matmul_4x128x64_f32(%0, %1) : (tensor<4x64xf32>, tensor<64x128xf32>) -> tensor<4x128xf32>
    %4 = flow.dispatch @mlp_dispatch_1::@mlp_dispatch_1_matmul_4x10x128_f32(%3, %2) : (tensor<4x128xf32>, tensor<128x10xf32>) -> tensor<4x10xf32>
    %5 = hal.tensor.export %4 "output0" : tensor<4x10xf32> -> !hal.buffer_view
    util.return %5 : !hal.buffer_view
  }
}