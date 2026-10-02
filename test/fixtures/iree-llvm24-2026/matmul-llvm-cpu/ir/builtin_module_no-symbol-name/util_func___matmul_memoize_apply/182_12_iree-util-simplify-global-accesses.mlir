// -----// IR Dump After SimplifyGlobalAccessesPass: iree-util-simplify-global-accesses //----- //
util.func private @__matmul_memoize_apply(%arg0: !hal.device, %arg1: i64) -> !hal.command_buffer attributes {inlining_policy = #util.inline.never} {
  %__device_0_executable_0_matmul_dispatch_0 = util.global.load immutable @__device_0_executable_0_matmul_dispatch_0 : !hal.executable
  %c16384 = arith.constant 16384 : index
  %c2 = arith.constant 2 : index
  %c1 = arith.constant 1 : index
  %c0 = arith.constant 0 : index
  %c3 = arith.constant 3 : index
  %c8 = arith.constant 8 : index
  %cmd = hal.command_buffer.create device(%arg0 : !hal.device) mode("None") categories("Transfer|Dispatch") affinity(%arg1) bindings(%c3) : !hal.command_buffer
  %function_id = hal.executable.lookup.function target(%__device_0_executable_0_matmul_dispatch_0 : !hal.executable) function(@matmul_dispatch_0::@embedded_elf_arm_64::@matmul_dispatch_0_matmul_64x64x64_f32) : i64
  hal.command_buffer.dispatch<%cmd : !hal.command_buffer> target(%__device_0_executable_0_matmul_dispatch_0 : !hal.executable)[%function_id] workgroups([%c8, %c1, %c1]) bindings([
    (%c0 : index)[%c0, %c16384], 
    (%c1 : index)[%c0, %c16384], 
    (%c2 : index)[%c0, %c16384]
  ]) flags("None")
  hal.command_buffer.execution_barrier<%cmd : !hal.command_buffer> source("Dispatch|Transfer|CommandRetire") target("CommandIssue|Dispatch|Transfer") flags("None")
  hal.command_buffer.finalize<%cmd : !hal.command_buffer>
  util.return %cmd : !hal.command_buffer
}

