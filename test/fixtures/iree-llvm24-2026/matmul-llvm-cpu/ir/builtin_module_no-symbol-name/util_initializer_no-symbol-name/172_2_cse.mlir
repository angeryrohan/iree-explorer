// -----// IR Dump After CSEPass: cse //----- //
util.initializer {
  %0 = util.null : !hal.executable
  %c14_i32 = arith.constant 14 : i32
  %c0 = arith.constant 0 : index
  %c-1 = arith.constant -1 : index
  %c-1_i64 = arith.constant -1 : i64
  %__device_0 = util.global.load @__device_0 : !hal.device
  %__device_0_query_0_hal_executable_format_embedded_elf_arm_64 = util.global.load @__device_0_query_0_hal_executable_format_embedded_elf_arm_64 : i1
  %1 = arith.select %__device_0_query_0_hal_executable_format_embedded_elf_arm_64, %c0, %c-1 : index
  %2 = scf.index_switch %1 -> !hal.executable 
  case 0 {
    %executable = hal.executable.create device(%__device_0 : !hal.device) affinity(%c-1_i64) target(@matmul_dispatch_0::@embedded_elf_arm_64) : !hal.executable
    scf.yield %executable : !hal.executable
  }
  default {
    util.status.check_ok %c14_i32, "HAL device `__device_0` does not support any variant of executable `matmul_dispatch_0`; available formats: [embedded-elf-arm_64]"
    scf.yield %0 : !hal.executable
  }
  util.global.store %2, @__device_0_executable_0_matmul_dispatch_0 : !hal.executable
  util.return
}

