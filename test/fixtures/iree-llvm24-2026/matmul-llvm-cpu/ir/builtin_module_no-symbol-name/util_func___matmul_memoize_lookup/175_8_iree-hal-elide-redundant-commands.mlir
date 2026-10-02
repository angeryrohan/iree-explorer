// -----// IR Dump After ElideRedundantCommandsPass: iree-hal-elide-redundant-commands //----- //
util.func private @__matmul_memoize_lookup(%arg0: !hal.device, %arg1: i64) -> !hal.command_buffer {
  %0 = util.null : !hal.command_buffer
  %__device_0 = util.global.load immutable @__device_0 : !hal.device
  %1 = util.cmp.eq %arg0, %__device_0 : !hal.device
  %2 = scf.if %1 -> (!hal.command_buffer) {
    %__matmul_memoize_result_0_device_0 = util.global.load immutable @__matmul_memoize_result_0_device_0 : !hal.command_buffer
    scf.yield %__matmul_memoize_result_0_device_0 : !hal.command_buffer
  } else {
    scf.yield %0 : !hal.command_buffer
  }
  util.return %2 : !hal.command_buffer
}

