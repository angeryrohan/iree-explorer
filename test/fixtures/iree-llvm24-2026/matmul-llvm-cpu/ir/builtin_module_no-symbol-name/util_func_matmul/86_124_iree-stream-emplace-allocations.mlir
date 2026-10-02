// -----// IR Dump After EmplaceAllocationsPass: iree-stream-emplace-allocations //----- //
util.func public @matmul(%arg0: !hal.buffer_view, %arg1: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @matmul(%input0: tensor<64x64xf32>, %input1: tensor<64x64xf32>) -> (%output0: tensor<64x64xf32>)"}} {
  %c0 = arith.constant 0 : index
  %c16384 = arith.constant 16384 : index
  %c64 = arith.constant 64 : index
  %element_type_f32 = hal.element_type<f32> : i32
  %dense_row_major = hal.encoding_type<dense_row_major> : i32
  hal.buffer_view.assert<%arg0 : !hal.buffer_view> message("input0") shape([%c64, %c64]) type(%element_type_f32) encoding(%dense_row_major)
  %0 = stream.tensor.import on(#hal.device.affinity<@__device_0>) %arg0 : !hal.buffer_view -> tensor<64x64xf32> in !stream.resource<external>{%c16384}
  %1 = stream.async.cast on(#hal.device.affinity<@__device_0>) %0 : !stream.resource<external>{%c16384} -> !stream.resource<*>{%c16384}
  hal.buffer_view.assert<%arg1 : !hal.buffer_view> message("input1") shape([%c64, %c64]) type(%element_type_f32) encoding(%dense_row_major)
  %2 = stream.tensor.import on(#hal.device.affinity<@__device_0>) %arg1 : !hal.buffer_view -> tensor<64x64xf32> in !stream.resource<external>{%c16384}
  %3 = stream.async.cast on(#hal.device.affinity<@__device_0>) %2 : !stream.resource<external>{%c16384} -> !stream.resource<*>{%c16384}
  %4 = stream.async.dispatch on(#hal.device.affinity<@__device_0>) @matmul_dispatch_0::@matmul_dispatch_0_matmul_64x64x64_f32(%1[%c0 to %c16384 for %c16384], %3[%c0 to %c16384 for %c16384]) : (!stream.resource<*>{%c16384}, !stream.resource<*>{%c16384}) -> !stream.resource<*>{%c16384}
  %5 = stream.async.cast on(#hal.device.affinity<@__device_0>) %4 : !stream.resource<*>{%c16384} -> !stream.resource<external>{%c16384}
  %6 = stream.tensor.export on(#hal.device.affinity<@__device_0>) %5 : tensor<64x64xf32> in !stream.resource<external>{%c16384} -> !hal.buffer_view
  util.return %6 : !hal.buffer_view
}

