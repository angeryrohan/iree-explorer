// -----// IR Dump After ApplyPatternsPass: iree-util-apply-patterns //----- //
util.func public @matmul(%arg0: !hal.buffer_view, %arg1: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @matmul(%input0: tensor<64x64xf32>, %input1: tensor<64x64xf32>) -> (%output0: tensor<64x64xf32>)"}} {
  %c0_i32 = arith.constant 0 : i32
  %c0 = arith.constant 0 : index
  %c16384 = arith.constant 16384 : index
  %c64 = arith.constant 64 : index
  %element_type_f32 = hal.element_type<f32> : i32
  %dense_row_major = hal.encoding_type<dense_row_major> : i32
  hal.buffer_view.assert<%arg0 : !hal.buffer_view> message("input0") shape([%c64, %c64]) type(%element_type_f32) encoding(%dense_row_major)
  %0 = stream.tensor.import on(#hal.device.affinity<@__device_0>) %arg0 : !hal.buffer_view -> tensor<64x64xf32> in !stream.resource<external>{%c16384}
  hal.buffer_view.assert<%arg1 : !hal.buffer_view> message("input1") shape([%c64, %c64]) type(%element_type_f32) encoding(%dense_row_major)
  %1 = stream.tensor.import on(#hal.device.affinity<@__device_0>) %arg1 : !hal.buffer_view -> tensor<64x64xf32> in !stream.resource<external>{%c16384}
  %result, %result_timepoint = stream.resource.alloca uninitialized on(#hal.device.affinity<@__device_0>) : !stream.resource<external>{%c16384} => !stream.timepoint
  %2 = stream.cmd.execute on(#hal.device.affinity<@__device_0>) await(%result_timepoint) => with(%0 as %arg2: !stream.resource<external>{%c16384}, %1 as %arg3: !stream.resource<external>{%c16384}, %result as %arg4: !stream.resource<external>{%c16384}) {
    stream.cmd.dispatch @matmul_dispatch_0::@matmul_dispatch_0_matmul_64x64x64_f32(%c0_i32, %c0_i32, %c0_i32, %c0_i32, %c0_i32, %c0_i32 : i32, i32, i32, i32, i32, i32) {
      ro %arg2[%c0 for %c16384] : !stream.resource<external>{%c16384},
      ro %arg3[%c0 for %c16384] : !stream.resource<external>{%c16384},
      wo %arg4[%c0 for %c16384] : !stream.resource<external>{%c16384}
    }
  } => !stream.timepoint
  %3 = stream.timepoint.await %2 => %result : !stream.resource<external>{%c16384}
  %4 = stream.tensor.export on(#hal.device.affinity<@__device_0>) %3 : tensor<64x64xf32> in !stream.resource<external>{%c16384} -> !hal.buffer_view
  util.return %4 : !hal.buffer_view
}

