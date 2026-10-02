// -----// IR Dump After CSEPass: cse //----- //
util.func private @__rowsum_memoize_apply(%arg0: !hal.device, %arg1: i64) -> !hal.command_buffer attributes {inlining_policy = #util.inline.never} {
  %c2 = arith.constant 2 : index
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c3200 = arith.constant 3200 : index
  %c32 = arith.constant 32 : index
  %cmd = hal.command_buffer.create device(%arg0 : !hal.device) mode("None") categories("Transfer|Dispatch") affinity(%arg1) bindings(%c2) : !hal.command_buffer
  %__device_0_executable_0_rowsum_dispatch_0 = util.global.load @__device_0_executable_0_rowsum_dispatch_0 : !hal.executable
  %function_id = hal.executable.lookup.function target(%__device_0_executable_0_rowsum_dispatch_0 : !hal.executable) function(@rowsum_dispatch_0::@vulkan_spirv_fb::@rowsum_dispatch_0_reduction_8x100_f32) : i64
  hal.command_buffer.dispatch<%cmd : !hal.command_buffer> target(%__device_0_executable_0_rowsum_dispatch_0 : !hal.executable)[%function_id] workgroups([%c1, %c1, %c1]) bindings([
    (%c0 : index)[%c0, %c3200], 
    (%c1 : index)[%c0, %c32]
  ]) flags("None")
  hal.command_buffer.execution_barrier<%cmd : !hal.command_buffer> source("Dispatch|Transfer|CommandRetire") target("CommandIssue|Dispatch|Transfer") flags("None")
  hal.command_buffer.finalize<%cmd : !hal.command_buffer>
  util.return %cmd : !hal.command_buffer
}

