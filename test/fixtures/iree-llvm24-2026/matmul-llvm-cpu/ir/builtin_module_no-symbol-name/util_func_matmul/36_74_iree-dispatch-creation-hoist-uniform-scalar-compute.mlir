// -----// IR Dump After HoistUniformScalarComputePass: iree-dispatch-creation-hoist-uniform-scalar-compute //----- //
util.func public @matmul(%arg0: !hal.buffer_view, %arg1: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @matmul(%input0: tensor<64x64xf32>, %input1: tensor<64x64xf32>) -> (%output0: tensor<64x64xf32>)"}} {
  %0 = hal.tensor.import %arg0 "input0" : !hal.buffer_view -> tensor<64x64xf32>
  %1 = iree_tensor_ext.compute_barrier.start %0 : tensor<64x64xf32> -> tensor<64x64xf32>
  %2 = hal.tensor.import %arg1 "input1" : !hal.buffer_view -> tensor<64x64xf32>
  %3 = iree_tensor_ext.compute_barrier.start %2 : tensor<64x64xf32> -> tensor<64x64xf32>
  %4 = flow.dispatch.region -> (tensor<64x64xf32>) {
    %7 = tensor.empty() : tensor<64x64xf32>
    %cst = arith.constant 0.000000e+00 : f32
    %8 = linalg.fill ins(%cst : f32) outs(%7 : tensor<64x64xf32>) -> tensor<64x64xf32>
    %9 = linalg.matmul ins(%1, %3 : tensor<64x64xf32>, tensor<64x64xf32>) outs(%8 : tensor<64x64xf32>) -> tensor<64x64xf32>
    flow.return %9 : tensor<64x64xf32>
  }
  %5 = iree_tensor_ext.compute_barrier.end %4 : tensor<64x64xf32> -> tensor<64x64xf32>
  %6 = hal.tensor.export %5 "output0" : tensor<64x64xf32> -> !hal.buffer_view
  util.return %6 : !hal.buffer_view
}

