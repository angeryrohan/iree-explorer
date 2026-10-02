// -----// IR Dump After StripDebugOpsPass: iree-util-strip-debug-ops //----- //
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

