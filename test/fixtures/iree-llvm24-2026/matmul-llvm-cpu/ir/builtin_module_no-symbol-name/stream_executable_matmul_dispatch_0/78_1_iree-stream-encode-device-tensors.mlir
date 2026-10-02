// -----// IR Dump After EncodeDeviceTensorsPass: iree-stream-encode-device-tensors //----- //
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

