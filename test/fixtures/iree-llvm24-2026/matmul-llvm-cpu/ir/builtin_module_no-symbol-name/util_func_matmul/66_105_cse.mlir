// -----// IR Dump After CSEPass: cse //----- //
util.func public @matmul(%arg0: !hal.buffer_view, %arg1: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @matmul(%input0: tensor<64x64xf32>, %input1: tensor<64x64xf32>) -> (%output0: tensor<64x64xf32>)"}} {
  %c64 = arith.constant 64 : index
  %element_type_f32 = hal.element_type<f32> : i32
  %dense_row_major = hal.encoding_type<dense_row_major> : i32
  hal.buffer_view.assert<%arg0 : !hal.buffer_view> message("input0") shape([%c64, %c64]) type(%element_type_f32) encoding(%dense_row_major)
  %0 = stream.tensor.sizeof on(#hal.device.affinity<@__device_0>) tensor<64x64xf32> : index
  %1 = stream.tensor.import on(#hal.device.affinity<@__device_0>) %arg0 : !hal.buffer_view -> tensor<64x64xf32> in !stream.resource<external>{%0}
  %2 = stream.async.cast on(#hal.device.affinity<@__device_0>) %1 : !stream.resource<external>{%0} -> !stream.resource<*>{%0}
  hal.buffer_view.assert<%arg1 : !hal.buffer_view> message("input1") shape([%c64, %c64]) type(%element_type_f32) encoding(%dense_row_major)
  %3 = stream.tensor.import on(#hal.device.affinity<@__device_0>) %arg1 : !hal.buffer_view -> tensor<64x64xf32> in !stream.resource<external>{%0}
  %4 = stream.async.cast on(#hal.device.affinity<@__device_0>) %3 : !stream.resource<external>{%0} -> !stream.resource<*>{%0}
  %5 = stream.tensor.dispatch on(#hal.device.affinity<@__device_0>) @matmul_dispatch_0::@matmul_dispatch_0_matmul_64x64x64_f32(%2, %4) : (tensor<64x64xf32> in !stream.resource<*>{%0}, tensor<64x64xf32> in !stream.resource<*>{%0}) -> tensor<64x64xf32> in !stream.resource<*>{%0}
  %6 = stream.async.cast on(#hal.device.affinity<@__device_0>) %5 : !stream.resource<*>{%0} -> !stream.resource<external>{%0}
  %7 = stream.tensor.export on(#hal.device.affinity<@__device_0>) %6 : tensor<64x64xf32> in !stream.resource<external>{%0} -> !hal.buffer_view
  util.return %7 : !hal.buffer_view
}

