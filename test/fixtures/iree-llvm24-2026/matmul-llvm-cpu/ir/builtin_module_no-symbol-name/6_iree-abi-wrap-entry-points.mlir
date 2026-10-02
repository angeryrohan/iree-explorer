// -----// IR Dump After WrapEntryPointsPass: iree-abi-wrap-entry-points{invocation-model=sync} //----- //
module {
  util.func public @matmul(%arg0: !hal.buffer_view, %arg1: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @matmul(%input0: tensor<64x64xf32>, %input1: tensor<64x64xf32>) -> (%output0: tensor<64x64xf32>)"}} {
    %0 = hal.tensor.import %arg0 "input0" : !hal.buffer_view -> tensor<64x64xf32>
    %1 = hal.tensor.import %arg1 "input1" : !hal.buffer_view -> tensor<64x64xf32>
    %2 = util.call @_matmul(%0, %1) : (tensor<64x64xf32>, tensor<64x64xf32>) -> tensor<64x64xf32>
    %3 = hal.tensor.export %2 "output0" : tensor<64x64xf32> -> !hal.buffer_view
    util.return %3 : !hal.buffer_view
  }
  util.func private @_matmul(%arg0: tensor<64x64xf32>, %arg1: tensor<64x64xf32>) -> tensor<64x64xf32> attributes {hal.abi.convention = #hal.abi.convention<synchronous>} {
    %cst = arith.constant 0.000000e+00 : f32
    %0 = tensor.empty() : tensor<64x64xf32>
    %1 = linalg.fill ins(%cst : f32) outs(%0 : tensor<64x64xf32>) -> tensor<64x64xf32>
    %2 = linalg.matmul ins(%arg0, %arg1 : tensor<64x64xf32>, tensor<64x64xf32>) outs(%1 : tensor<64x64xf32>) -> tensor<64x64xf32>
    util.return %2 : tensor<64x64xf32>
  }
}


