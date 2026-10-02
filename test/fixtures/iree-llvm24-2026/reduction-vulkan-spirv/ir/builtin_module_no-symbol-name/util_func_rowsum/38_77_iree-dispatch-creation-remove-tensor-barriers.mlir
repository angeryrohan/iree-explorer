// -----// IR Dump After RemoveTensorBarriersPass: iree-dispatch-creation-remove-tensor-barriers //----- //
util.func public @rowsum(%arg0: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @rowsum(%input0: tensor<8x100xf32>) -> (%output0: tensor<8xf32>)"}} {
  %0 = hal.tensor.import %arg0 "input0" : !hal.buffer_view -> tensor<8x100xf32>
  %1 = flow.dispatch.region -> (tensor<8xf32>) {
    %3 = tensor.empty() : tensor<8xf32>
    %cst = arith.constant 0.000000e+00 : f32
    %4 = linalg.fill ins(%cst : f32) outs(%3 : tensor<8xf32>) -> tensor<8xf32>
    %5 = linalg.generic {indexing_maps = [affine_map<(d0, d1) -> (d0, d1)>, affine_map<(d0, d1) -> (d0)>], iterator_types = ["parallel", "reduction"]} ins(%0 : tensor<8x100xf32>) outs(%4 : tensor<8xf32>) {
    ^bb0(%in: f32, %out: f32):
      %6 = arith.addf %in, %out : f32
      linalg.yield %6 : f32
    } -> tensor<8xf32>
    flow.return %5 : tensor<8xf32>
  }
  %2 = hal.tensor.export %1 "output0" : tensor<8xf32> -> !hal.buffer_view
  util.return %2 : !hal.buffer_view
}

