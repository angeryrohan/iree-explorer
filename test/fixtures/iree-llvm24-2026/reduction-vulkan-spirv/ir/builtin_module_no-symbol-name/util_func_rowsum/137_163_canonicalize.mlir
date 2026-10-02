// -----// IR Dump After CanonicalizerPass: canonicalize{cse-between-iterations=false    max-iterations=10 max-num-rewrites=-1 region-simplify=normal test-convergence=false top-down=true} //----- //
util.func public @rowsum(%arg0: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @rowsum(%input0: tensor<8x100xf32>) -> (%output0: tensor<8xf32>)"}} {
  %c0 = arith.constant 0 : index
  %c32 = arith.constant 32 : index
  %c3200 = arith.constant 3200 : index
  %c100 = arith.constant 100 : index
  %c8 = arith.constant 8 : index
  %element_type_f32 = hal.element_type<f32> : i32
  %dense_row_major = hal.encoding_type<dense_row_major> : i32
  hal.buffer_view.assert<%arg0 : !hal.buffer_view> message("input0") shape([%c8, %c100]) type(%element_type_f32) encoding(%dense_row_major)
  %0 = stream.tensor.import on(#hal.device.affinity<@__device_0>) %arg0 : !hal.buffer_view -> tensor<8x100xf32> in !stream.resource<external>{%c3200}
  %result, %result_timepoint = stream.resource.alloca uninitialized on(#hal.device.affinity<@__device_0>) : !stream.resource<external>{%c32} => !stream.timepoint
  %1 = stream.cmd.execute on(#hal.device.affinity<@__device_0>) await(%result_timepoint) => with(%0 as %arg1: !stream.resource<external>{%c3200}, %result as %arg2: !stream.resource<external>{%c32}) {
    stream.cmd.dispatch @rowsum_dispatch_0::@rowsum_dispatch_0_reduction_8x100_f32 {
      ro %arg1[%c0 for %c3200] : !stream.resource<external>{%c3200},
      wo %arg2[%c0 for %c32] : !stream.resource<external>{%c32}
    }
  } => !stream.timepoint
  %2 = stream.timepoint.await %1 => %result : !stream.resource<external>{%c32}
  %3 = stream.tensor.export on(#hal.device.affinity<@__device_0>) %2 : tensor<8xf32> in !stream.resource<external>{%c32} -> !hal.buffer_view
  util.return %3 : !hal.buffer_view
}

