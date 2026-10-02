// -----// IR Dump After ApplyPatternsPass: iree-util-apply-patterns //----- //
util.initializer {
  %__device_0 = util.global.load @__device_0 : !hal.device
  %ok, %value = hal.device.query<%__device_0 : !hal.device> key("hal.executable.format" :: "vulkan-spirv-fb") : i1, i1 = false
  util.global.store %value, @__device_0_query_0_hal_executable_format_vulkan_spirv_fb : i1
  util.return
}

