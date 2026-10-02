// -----// IR Dump After SinkReshapesPass: iree-dispatch-creation-sink-reshapes //----- //
util.func public @rowsum(%arg0: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @rowsum(%input0: tensor<8x100xf32>) -> (%output0: tensor<8xf32>)"}} {
  %cst = arith.constant 0.000000e+00 : f32
  %0 = hal.tensor.import %arg0 "input0" : !hal.buffer_view -> tensor<8x100xf32>
  %1 = iree_tensor_ext.compute_barrier.start %0 : tensor<8x100xf32> -> tensor<8x100xf32>
  %2 = tensor.empty() : tensor<8xf32>
  %3 = linalg.fill ins(%cst : f32) outs(%2 : tensor<8xf32>) -> tensor<8xf32>
  %4 = linalg.generic {indexing_maps = [affine_map<(d0, d1) -> (d0, d1)>, affine_map<(d0, d1) -> (d0)>], iterator_types = ["parallel", "reduction"]} ins(%1 : tensor<8x100xf32>) outs(%3 : tensor<8xf32>) {
  ^bb0(%in: f32, %out: f32):
    %7 = arith.addf %in, %out : f32
    linalg.yield %7 : f32
  } -> tensor<8xf32>
  %5 = iree_tensor_ext.compute_barrier.end %4 : tensor<8xf32> -> tensor<8xf32>
  %6 = hal.tensor.export %5 "output0" : tensor<8xf32> -> !hal.buffer_view
  util.return %6 : !hal.buffer_view
}

