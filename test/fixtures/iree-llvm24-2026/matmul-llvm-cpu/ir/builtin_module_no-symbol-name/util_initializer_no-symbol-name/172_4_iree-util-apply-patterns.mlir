// -----// IR Dump After ApplyPatternsPass: iree-util-apply-patterns //----- //
util.initializer {
  %c-1_i64 = arith.constant -1 : i64
  %c-1 = arith.constant -1 : index
  %c0 = arith.constant 0 : index
  %c14_i32 = arith.constant 14 : i32
  %0 = util.null : !hal.executable
  %__device_0_query_0_hal_executable_format_embedded_elf_arm_64 = util.global.load @__device_0_query_0_hal_executable_format_embedded_elf_arm_64 : i1
  %__device_0 = util.global.load @__device_0 : !hal.device
  %1 = arith.select %__device_0_query_0_hal_executable_format_embedded_elf_arm_64, %c0, %c-1 : index
  %2 = arith.cmpi eq, %1, %c0 : index
  %3 = scf.if %2 -> (!hal.executable) {
    %executable = hal.executable.create device(%__device_0 : !hal.device) affinity(%c-1_i64) target(@matmul_dispatch_0::@embedded_elf_arm_64) : !hal.executable
    scf.yield %executable : !hal.executable
  } else {
    util.status.check_ok %c14_i32, "HAL device `__device_0` does not support any variant of executable `matmul_dispatch_0`; available formats: [embedded-elf-arm_64]"
    scf.yield %0 : !hal.executable
  }
  util.global.store %3, @__device_0_executable_0_matmul_dispatch_0 : !hal.executable
  util.return
}

