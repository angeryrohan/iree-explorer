// -----// IR Dump After SCFToControlFlowPass: convert-scf-to-cf{allow-pattern-rollback=true} //----- //
util.func private @__rowsum_memoize_lookup(%arg0: !hal.device, %arg1: i64) -> !hal.command_buffer {
  %0 = util.null : !hal.command_buffer
  %__device_0 = util.global.load immutable @__device_0 : !hal.device
  %1 = util.cmp.eq %arg0, %__device_0 : !hal.device
  cf.cond_br %1, ^bb1, ^bb2
^bb1:  // pred: ^bb0
  %__rowsum_memoize_result_0_device_0 = util.global.load immutable @__rowsum_memoize_result_0_device_0 : !hal.command_buffer
  cf.br ^bb3(%__rowsum_memoize_result_0_device_0 : !hal.command_buffer)
^bb2:  // pred: ^bb0
  cf.br ^bb3(%0 : !hal.command_buffer)
^bb3(%2: !hal.command_buffer):  // 2 preds: ^bb1, ^bb2
  cf.br ^bb4
^bb4:  // pred: ^bb3
  util.return %2 : !hal.command_buffer
}

