// -----// IR Dump After CanonicalizerPass: canonicalize{cse-between-iterations=false    max-iterations=10 max-num-rewrites=-1 region-simplify=normal test-convergence=false top-down=true} //----- //
vm.func private @__rowsum_memoize_apply() -> !vm.ref<!hal.command_buffer> attributes {inlining_policy = #util.inline.never} {
  %c13 = vm.const.i32 13
  %c28 = vm.const.i32 28
  %null = vm.const.ref.zero : !vm.ref<!hal.buffer>
  %c1 = vm.const.i32 1
  %c2 = vm.const.i32 2
  %c3 = vm.const.i32 3
  %zero = vm.const.i32.zero
  %c32 = vm.const.i64 32
  %c3200 = vm.const.i64 3200
  %zero_0 = vm.const.i64.zero
  %c-1 = vm.const.i64 -1
  %__device_0 = vm.global.load.ref immutable @__device_0 : !vm.ref<!hal.device>
  %__device_0_executable_0_rowsum_dispatch_0 = vm.global.load.ref immutable @__device_0_executable_0_rowsum_dispatch_0 : !vm.ref<!hal.executable>
  %ref = vm.call @hal.command_buffer.create(%__device_0, %zero, %c3, %c-1, %c2) : (!vm.ref<!hal.device>, i32, i32, i64, i32) -> !vm.ref<!hal.command_buffer>
  %_utf8_rowsum_dispatch_0_reductio_98347A448C00BBA0 = vm.const.ref.rodata @_utf8_rowsum_dispatch_0_reductio_98347A448C00BBA0 : !vm.buffer
  %0 = vm.call @hal.executable.lookup.function(%__device_0_executable_0_rowsum_dispatch_0, %_utf8_rowsum_dispatch_0_reductio_98347A448C00BBA0) {nosideeffects} : (!vm.ref<!hal.executable>, !vm.buffer) -> i64
  vm.call.variadic @hal.command_buffer.dispatch(%ref, %__device_0_executable_0_rowsum_dispatch_0, %0, %c1, %c1, %c1, %zero_0, [], [(%zero, %zero, %null, %zero_0, %c3200), (%zero, %c1, %null, %zero_0, %c32)]) : (!vm.ref<!hal.command_buffer>, !vm.ref<!hal.executable>, i64, i32, i32, i32, i64, i32 ..., tuple<i32, i32, !vm.ref<!hal.buffer>, i64, i64> ...)
  vm.call @hal.command_buffer.execution_barrier(%ref, %c28, %c13, %zero_0) : (!vm.ref<!hal.command_buffer>, i32, i32, i64) -> ()
  vm.call @hal.command_buffer.finalize(%ref) : (!vm.ref<!hal.command_buffer>) -> ()
  vm.return %ref : !vm.ref<!hal.command_buffer>
}

