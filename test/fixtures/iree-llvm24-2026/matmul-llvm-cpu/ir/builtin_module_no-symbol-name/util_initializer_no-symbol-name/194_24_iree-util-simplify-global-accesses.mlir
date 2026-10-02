// -----// IR Dump After SimplifyGlobalAccessesPass: iree-util-simplify-global-accesses //----- //
util.initializer {
  %0 = util.call @__matmul_memoize_apply() : () -> !hal.command_buffer
  util.global.store %0, @__matmul_memoize_result_0_device_0 : !hal.command_buffer
  util.return
}

