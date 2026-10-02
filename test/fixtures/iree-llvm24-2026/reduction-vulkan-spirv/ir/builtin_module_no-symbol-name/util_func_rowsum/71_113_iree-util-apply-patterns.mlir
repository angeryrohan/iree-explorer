// -----// IR Dump After ApplyPatternsPass: iree-util-apply-patterns //----- //
util.func public @rowsum(%arg0: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @rowsum(%input0: tensor<8x100xf32>) -> (%output0: tensor<8xf32>)"}} {
  %c100 = arith.constant 100 : index
  %c8 = arith.constant 8 : index
  %element_type_f32 = hal.element_type<f32> : i32
  %dense_row_major = hal.encoding_type<dense_row_major> : i32
  hal.buffer_view.assert<%arg0 : !hal.buffer_view> message("input0") shape([%c8, %c100]) type(%element_type_f32) encoding(%dense_row_major)
  %0 = stream.tensor.sizeof on(#hal.device.affinity<@__device_0>) tensor<8x100xf32> : index
  %1 = stream.tensor.import on(#hal.device.affinity<@__device_0>) %arg0 : !hal.buffer_view -> tensor<8x100xf32> in !stream.resource<external>{%0}
  %2 = stream.async.cast on(#hal.device.affinity<@__device_0>) %1 : !stream.resource<external>{%0} -> !stream.resource<*>{%0}
  %3 = stream.tensor.sizeof on(#hal.device.affinity<@__device_0>) tensor<8xf32> : index
  %4 = stream.tensor.dispatch on(#hal.device.affinity<@__device_0>) @rowsum_dispatch_0::@rowsum_dispatch_0_reduction_8x100_f32(%2) : (tensor<8x100xf32> in !stream.resource<*>{%0}) -> tensor<8xf32> in !stream.resource<*>{%3}
  %5 = stream.async.cast on(#hal.device.affinity<@__device_0>) %4 : !stream.resource<*>{%3} -> !stream.resource<external>{%3}
  %6 = stream.tensor.export on(#hal.device.affinity<@__device_0>) %5 : tensor<8xf32> in !stream.resource<external>{%3} -> !hal.buffer_view
  util.return %6 : !hal.buffer_view
}

