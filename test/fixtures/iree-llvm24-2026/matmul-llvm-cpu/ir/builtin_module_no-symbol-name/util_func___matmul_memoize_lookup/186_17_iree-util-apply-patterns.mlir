// -----// IR Dump After ApplyPatternsPass: iree-util-apply-patterns //----- //
util.func private @__matmul_memoize_lookup() -> !hal.command_buffer {
  %__matmul_memoize_result_0_device_0 = util.global.load immutable @__matmul_memoize_result_0_device_0 : !hal.command_buffer
  util.return %__matmul_memoize_result_0_device_0 : !hal.command_buffer
}

