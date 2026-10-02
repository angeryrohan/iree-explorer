// -----// IR Dump After RemoveTensorBarriersPass: iree-dispatch-creation-remove-tensor-barriers //----- //
util.func public @matmul(%arg0: !hal.buffer_view, %arg1: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @matmul(%input0: tensor<64x64xf32>, %input1: tensor<64x64xf32>) -> (%output0: tensor<64x64xf32>)"}} {
  %0 = hal.tensor.import %arg0 "input0" : !hal.buffer_view -> tensor<64x64xf32>
  %1 = hal.tensor.import %arg1 "input1" : !hal.buffer_view -> tensor<64x64xf32>
  %2 = flow.dispatch.region -> (tensor<64x64xf32>) {
    %4 = tensor.empty() : tensor<64x64xf32>
    %cst = arith.constant 0.000000e+00 : f32
    %5 = linalg.fill ins(%cst : f32) outs(%4 : tensor<64x64xf32>) -> tensor<64x64xf32>
    %6 = linalg.matmul ins(%0, %1 : tensor<64x64xf32>, tensor<64x64xf32>) outs(%5 : tensor<64x64xf32>) -> tensor<64x64xf32>
    flow.return %6 : tensor<64x64xf32>
  }
  %3 = hal.tensor.export %2 "output0" : tensor<64x64xf32> -> !hal.buffer_view
  util.return %3 : !hal.buffer_view
}

