// -----// IR Dump After GlobalLoopInvariantCodeMotionPass: iree-global-opt-loop-invariant-code-motion //----- //
util.func public @matmul(%arg0: !hal.buffer_view, %arg1: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @matmul(%input0: tensor<64x64xf32>, %input1: tensor<64x64xf32>) -> (%output0: tensor<64x64xf32>)"}} {
  %cst = arith.constant 0.000000e+00 : f32
  %0 = hal.tensor.import %arg0 "input0" : !hal.buffer_view -> tensor<64x64xf32>
  %1 = iree_tensor_ext.compute_barrier.start %0 : tensor<64x64xf32> -> tensor<64x64xf32>
  %2 = hal.tensor.import %arg1 "input1" : !hal.buffer_view -> tensor<64x64xf32>
  %3 = iree_tensor_ext.compute_barrier.start %2 : tensor<64x64xf32> -> tensor<64x64xf32>
  %4 = tensor.empty() : tensor<64x64xf32>
  %5 = linalg.fill ins(%cst : f32) outs(%4 : tensor<64x64xf32>) -> tensor<64x64xf32>
  %6 = linalg.matmul ins(%1, %3 : tensor<64x64xf32>, tensor<64x64xf32>) outs(%5 : tensor<64x64xf32>) -> tensor<64x64xf32>
  %7 = iree_tensor_ext.compute_barrier.end %6 : tensor<64x64xf32> -> tensor<64x64xf32>
  %8 = hal.tensor.export %7 "output0" : tensor<64x64xf32> -> !hal.buffer_view
  util.return %8 : !hal.buffer_view
}

