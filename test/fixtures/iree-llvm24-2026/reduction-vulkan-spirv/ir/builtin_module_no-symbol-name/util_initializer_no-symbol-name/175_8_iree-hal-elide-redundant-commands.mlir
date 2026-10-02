// -----// IR Dump After ElideRedundantCommandsPass: iree-hal-elide-redundant-commands //----- //
util.initializer {
  %c-1_i64 = arith.constant -1 : i64
  %__device_0 = util.global.load immutable @__device_0 : !hal.device
  %0 = util.call @__rowsum_memoize_apply(%__device_0, %c-1_i64) : (!hal.device, i64) -> !hal.command_buffer
  util.global.store %0, @__rowsum_memoize_result_0_device_0 : !hal.command_buffer
  util.return
}

