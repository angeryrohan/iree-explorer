// -----// IR Dump After CSEPass: cse //----- //
util.initializer {
  %0 = util.call @__rowsum_memoize_apply() : () -> !hal.command_buffer
  util.global.store %0, @__rowsum_memoize_result_0_device_0 : !hal.command_buffer
  util.return
}

