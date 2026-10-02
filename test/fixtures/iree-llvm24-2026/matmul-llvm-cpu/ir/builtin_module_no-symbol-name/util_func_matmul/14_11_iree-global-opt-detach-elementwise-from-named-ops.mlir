// -----// IR Dump After DetachElementwiseFromNamedOpsPass: iree-global-opt-detach-elementwise-from-named-ops //----- //
util.func public @matmul(%arg0: !hal.buffer_view, %arg1: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @matmul(%input0: tensor<64x64xf32>, %input1: tensor<64x64xf32>) -> (%output0: tensor<64x64xf32>)"}} {
  %cst = arith.constant 0.000000e+00 : f32
  %0 = hal.tensor.import %arg0 "input0" : !hal.buffer_view -> tensor<64x64xf32>
  %1 = hal.tensor.import %arg1 "input1" : !hal.buffer_view -> tensor<64x64xf32>
  %2 = tensor.empty() : tensor<64x64xf32>
  %3 = linalg.fill ins(%cst : f32) outs(%2 : tensor<64x64xf32>) -> tensor<64x64xf32>
  %4 = linalg.matmul ins(%0, %1 : tensor<64x64xf32>, tensor<64x64xf32>) outs(%3 : tensor<64x64xf32>) -> tensor<64x64xf32>
  %5 = hal.tensor.export %4 "output0" : tensor<64x64xf32> -> !hal.buffer_view
  util.return %5 : !hal.buffer_view
}

