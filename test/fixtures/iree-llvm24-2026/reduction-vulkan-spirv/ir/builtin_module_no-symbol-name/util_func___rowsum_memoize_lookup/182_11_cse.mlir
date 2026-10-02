// -----// IR Dump After CSEPass: cse //----- //
util.func private @__rowsum_memoize_lookup(%arg0: !hal.device, %arg1: i64) -> !hal.command_buffer {
  %0 = util.null : !hal.command_buffer
  %__device_0 = util.global.load immutable @__device_0 : !hal.device
  %1 = util.cmp.eq %arg0, %__device_0 : !hal.device
  cf.cond_br %1, ^bb1, ^bb2(%0 : !hal.command_buffer)
^bb1:  // pred: ^bb0
  %__rowsum_memoize_result_0_device_0 = util.global.load immutable @__rowsum_memoize_result_0_device_0 : !hal.command_buffer
  cf.br ^bb2(%__rowsum_memoize_result_0_device_0 : !hal.command_buffer)
^bb2(%2: !hal.command_buffer):  // 2 preds: ^bb0, ^bb1
  util.return %2 : !hal.command_buffer
}

