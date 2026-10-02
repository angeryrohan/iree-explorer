// -----// IR Dump After CSEPass: cse //----- //
util.initializer {
  %__device_0 = util.global.load @__device_0 : !hal.device
  %ok, %value = hal.device.query<%__device_0 : !hal.device> key("hal.executable.format" :: "embedded-elf-arm_64") : i1, i1 = false
  util.global.store %ok, @__device_0_query_0_hal_executable_format_embedded_elf_arm_64_ok : i1
  util.global.store %value, @__device_0_query_0_hal_executable_format_embedded_elf_arm_64 : i1
  util.return
}

