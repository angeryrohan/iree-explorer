// -----// IR Dump After SimplifyGlobalAccessesPass: iree-util-simplify-global-accesses //----- //
util.func public @rowsum(%arg0: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @rowsum(%input0: tensor<8x100xf32>) -> (%output0: tensor<8xf32>)"}} {
  %0 = hal.tensor.import %arg0 "input0" : !hal.buffer_view -> tensor<8x100xf32>
  %1 = flow.dispatch @rowsum_dispatch_0::@rowsum_dispatch_0_reduction_8x100_f32(%0) : (tensor<8x100xf32>) -> tensor<8xf32>
  %2 = hal.tensor.export %1 "output0" : tensor<8xf32> -> !hal.buffer_view
  util.return %2 : !hal.buffer_view
}

