// -----// IR Dump After CSEPass: cse //----- //
util.func private @__matmul_memoize_lookup() -> !hal.command_buffer {
  %0 = util.null : !hal.command_buffer
  %__device_0 = util.global.load immutable @__device_0 : !hal.device
  %__matmul_memoize_result_0_device_0 = util.global.load immutable @__matmul_memoize_result_0_device_0 : !hal.command_buffer
  %1 = util.cmp.eq %__device_0, %__device_0 : !hal.device
  %2 = arith.select %1, %__matmul_memoize_result_0_device_0, %0 : !hal.command_buffer
  util.return %2 : !hal.command_buffer
}

