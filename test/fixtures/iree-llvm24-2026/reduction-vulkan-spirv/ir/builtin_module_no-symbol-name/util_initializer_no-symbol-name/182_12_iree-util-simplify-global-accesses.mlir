// -----// IR Dump After SimplifyGlobalAccessesPass: iree-util-simplify-global-accesses //----- //
util.initializer {
  %__device_0 = util.global.load immutable @__device_0 : !hal.device
  %c-1_i64 = arith.constant -1 : i64
  %0 = util.call @__rowsum_memoize_apply(%__device_0, %c-1_i64) : (!hal.device, i64) -> !hal.command_buffer
  util.global.store %0, @__rowsum_memoize_result_0_device_0 : !hal.command_buffer
  util.return
}

