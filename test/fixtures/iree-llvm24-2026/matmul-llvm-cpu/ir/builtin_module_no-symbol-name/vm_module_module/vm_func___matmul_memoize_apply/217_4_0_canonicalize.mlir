// -----// IR Dump After CanonicalizerPass: canonicalize{cse-between-iterations=false    max-iterations=10 max-num-rewrites=-1 region-simplify=normal test-convergence=false top-down=true} //----- //
vm.func private @__matmul_memoize_apply() -> !vm.ref<!hal.command_buffer> attributes {inlining_policy = #util.inline.never} {
  %c13 = vm.const.i32 13
  %c28 = vm.const.i32 28
  %c2 = vm.const.i32 2
  %null = vm.const.ref.zero : !vm.ref<!hal.buffer>
  %c1 = vm.const.i32 1
  %c8 = vm.const.i32 8
  %c3 = vm.const.i32 3
  %zero = vm.const.i32.zero
  %c16384 = vm.const.i64 16384
  %zero_0 = vm.const.i64.zero
  %c-1 = vm.const.i64 -1
  %__device_0 = vm.global.load.ref immutable @__device_0 : !vm.ref<!hal.device>
  %__device_0_executable_0_matmul_dispatch_0 = vm.global.load.ref immutable @__device_0_executable_0_matmul_dispatch_0 : !vm.ref<!hal.executable>
  %ref = vm.call @hal.command_buffer.create(%__device_0, %zero, %c3, %c-1, %c3) : (!vm.ref<!hal.device>, i32, i32, i64, i32) -> !vm.ref<!hal.command_buffer>
  %_utf8_matmul_dispatch_0_matmul_6_18BAC40F25B1949B = vm.const.ref.rodata @_utf8_matmul_dispatch_0_matmul_6_18BAC40F25B1949B : !vm.buffer
  %0 = vm.call @hal.executable.lookup.function(%__device_0_executable_0_matmul_dispatch_0, %_utf8_matmul_dispatch_0_matmul_6_18BAC40F25B1949B) {nosideeffects} : (!vm.ref<!hal.executable>, !vm.buffer) -> i64
  vm.call.variadic @hal.command_buffer.dispatch(%ref, %__device_0_executable_0_matmul_dispatch_0, %0, %c8, %c1, %c1, %zero_0, [], [(%zero, %zero, %null, %zero_0, %c16384), (%zero, %c1, %null, %zero_0, %c16384), (%zero, %c2, %null, %zero_0, %c16384)]) : (!vm.ref<!hal.command_buffer>, !vm.ref<!hal.executable>, i64, i32, i32, i32, i64, i32 ..., tuple<i32, i32, !vm.ref<!hal.buffer>, i64, i64> ...)
  vm.call @hal.command_buffer.execution_barrier(%ref, %c28, %c13, %zero_0) : (!vm.ref<!hal.command_buffer>, i32, i32, i64) -> ()
  vm.call @hal.command_buffer.finalize(%ref) : (!vm.ref<!hal.command_buffer>) -> ()
  vm.return %ref : !vm.ref<!hal.command_buffer>
}

