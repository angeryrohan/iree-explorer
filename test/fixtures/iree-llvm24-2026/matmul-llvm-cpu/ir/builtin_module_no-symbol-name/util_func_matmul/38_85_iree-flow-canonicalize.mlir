// -----// IR Dump After CanonicalizePass: iree-flow-canonicalize{cse-constants=true test-convergence=false} //----- //
util.func public @matmul(%arg0: !hal.buffer_view, %arg1: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @matmul(%input0: tensor<64x64xf32>, %input1: tensor<64x64xf32>) -> (%output0: tensor<64x64xf32>)"}} {
  %0 = hal.tensor.import %arg0 "input0" : !hal.buffer_view -> tensor<64x64xf32>
  %1 = hal.tensor.import %arg1 "input1" : !hal.buffer_view -> tensor<64x64xf32>
  %2 = flow.dispatch.workgroups(%0, %1) : (tensor<64x64xf32>, tensor<64x64xf32>) -> tensor<64x64xf32> =
      (%arg2: !iree_tensor_ext.dispatch.tensor<readonly:tensor<64x64xf32>>, %arg3: !iree_tensor_ext.dispatch.tensor<readonly:tensor<64x64xf32>>, %arg4: !iree_tensor_ext.dispatch.tensor<writeonly:tensor<64x64xf32>>) {
    %cst = arith.constant 0.000000e+00 : f32
    %4 = iree_tensor_ext.dispatch.tensor.load %arg2, offsets = [0, 0], sizes = [64, 64], strides = [1, 1] : !iree_tensor_ext.dispatch.tensor<readonly:tensor<64x64xf32>> -> tensor<64x64xf32>
    %5 = iree_tensor_ext.dispatch.tensor.load %arg3, offsets = [0, 0], sizes = [64, 64], strides = [1, 1] : !iree_tensor_ext.dispatch.tensor<readonly:tensor<64x64xf32>> -> tensor<64x64xf32>
    %6 = tensor.empty() : tensor<64x64xf32>
    %7 = linalg.fill ins(%cst : f32) outs(%6 : tensor<64x64xf32>) -> tensor<64x64xf32>
    %8 = linalg.matmul ins(%4, %5 : tensor<64x64xf32>, tensor<64x64xf32>) outs(%7 : tensor<64x64xf32>) -> tensor<64x64xf32>
    iree_tensor_ext.dispatch.tensor.store %8, %arg4, offsets = [0, 0], sizes = [64, 64], strides = [1, 1] : tensor<64x64xf32> -> !iree_tensor_ext.dispatch.tensor<writeonly:tensor<64x64xf32>>
    flow.return
  } count() -> (index, index, index) {
    %x, %y, %z = iree_tensor_ext.dispatch.workgroup_count_from_slice()
    flow.return %x, %y, %z : index, index, index
  }
  %3 = hal.tensor.export %2 "output0" : tensor<64x64xf32> -> !hal.buffer_view
  util.return %3 : !hal.buffer_view
}

