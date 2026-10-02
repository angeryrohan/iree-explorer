// -----// IR Dump After CanonicalizerPass: canonicalize{cse-between-iterations=false    max-iterations=10 max-num-rewrites=-1 region-simplify=normal test-convergence=false top-down=true} //----- //
vm.func private @matmul(%arg0: !vm.ref<!hal.buffer_view>, %arg1: !vm.ref<!hal.buffer_view>) -> !vm.ref<!hal.buffer_view> attributes {iree.reflection = {iree.abi.declaration = "sync func @matmul(%input0: tensor<64x64xf32>, %input1: tensor<64x64xf32>) -> (%output0: tensor<64x64xf32>)"}} {
  %c16 = vm.const.i32 16
  %c1 = vm.const.i32 1
  %c553648160 = vm.const.i32 553648160
  %c3075 = vm.const.i32 3075
  %c48 = vm.const.i32 48
  %c64 = vm.const.i64 64
  %c16384 = vm.const.i64 16384
  %zero = vm.const.i64.zero
  %c-1 = vm.const.i64 -1
  %null = vm.const.ref.zero : !vm.ref<!hal.fence>
  %c-1_0 = vm.const.i32 -1
  %__device_0 = vm.global.load.ref immutable @__device_0 : !vm.ref<!hal.device>
  %__matmul_memoize_result_0_device_0 = vm.global.load.ref immutable @__matmul_memoize_result_0_device_0 : !vm.ref<!hal.command_buffer>
  %_utf8_input0_DCE99660CEB3F6B = vm.const.ref.rodata @_utf8_input0_DCE99660CEB3F6B : !vm.buffer
  vm.call.variadic @hal.buffer_view.assert(%arg0, %_utf8_input0_DCE99660CEB3F6B, %c553648160, %c1, [%c64, %c64]) : (!vm.ref<!hal.buffer_view>, !vm.buffer, i32, i32, i64 ...)
  %ref = vm.call @hal.buffer_view.buffer(%arg0) {nosideeffects} : (!vm.ref<!hal.buffer_view>) -> !vm.ref<!hal.buffer>
  %ref_1 = vm.call @hal.device.allocator(%__device_0) {nosideeffects} : (!vm.ref<!hal.device>) -> !vm.ref<!hal.allocator>
  %_utf8_tensor_FC1814BC4A58F22A = vm.const.ref.rodata @_utf8_tensor_FC1814BC4A58F22A : !vm.buffer
  vm.call @hal.buffer.assert(%ref, %_utf8_tensor_FC1814BC4A58F22A, %ref_1, %c16384, %c16, %c3075) : (!vm.ref<!hal.buffer>, !vm.buffer, !vm.ref<!hal.allocator>, i64, i32, i32) -> ()
  %_utf8_input1_B898B726583C85DA = vm.const.ref.rodata @_utf8_input1_B898B726583C85DA : !vm.buffer
  vm.call.variadic @hal.buffer_view.assert(%arg1, %_utf8_input1_B898B726583C85DA, %c553648160, %c1, [%c64, %c64]) : (!vm.ref<!hal.buffer_view>, !vm.buffer, i32, i32, i64 ...)
  %ref_2 = vm.call @hal.buffer_view.buffer(%arg1) {nosideeffects} : (!vm.ref<!hal.buffer_view>) -> !vm.ref<!hal.buffer>
  %_utf8_tensor_FC1814BC4A58F22A_3 = vm.const.ref.rodata @_utf8_tensor_FC1814BC4A58F22A : !vm.buffer
  vm.call @hal.buffer.assert(%ref_2, %_utf8_tensor_FC1814BC4A58F22A_3, %ref_1, %c16384, %c16, %c3075) : (!vm.ref<!hal.buffer>, !vm.buffer, !vm.ref<!hal.allocator>, i64, i32, i32) -> ()
  %ref_4 = vm.call @hal.fence.create(%__device_0, %zero) : (!vm.ref<!hal.device>, i64) -> !vm.ref<!hal.fence>
  %ref_5 = vm.call @hal.device.queue.alloca(%__device_0, %c-1, %null, %ref_4, %zero, %c48, %c3075, %c16384, %zero) : (!vm.ref<!hal.device>, i64, !vm.ref<!hal.fence>, !vm.ref<!hal.fence>, i64, i32, i32, i64, i64) -> !vm.ref<!hal.buffer>
  %ref_6 = vm.call @hal.fence.create(%__device_0, %zero) : (!vm.ref<!hal.device>, i64) -> !vm.ref<!hal.fence>
  vm.call.variadic @hal.device.queue.execute.indirect(%__device_0, %c-1, %ref_4, %ref_6, %__matmul_memoize_result_0_device_0, %zero, [(%ref, %zero, %c16384), (%ref_2, %zero, %c16384), (%ref_5, %zero, %c16384)]) : (!vm.ref<!hal.device>, i64, !vm.ref<!hal.fence>, !vm.ref<!hal.fence>, !vm.ref<!hal.command_buffer>, i64, tuple<!vm.ref<!hal.buffer>, i64, i64> ...)
  %0 = vm.call.variadic @hal.fence.await(%c-1_0, %zero, [%ref_6]) : (i32, i64, !vm.ref<!hal.fence> ...) -> i32
  vm.cond_br %0, ^bb2(%0 : i32), ^bb1
^bb1:  // pred: ^bb0
  %ref_7 = vm.call.variadic @hal.buffer_view.create(%ref_5, %zero, %c16384, %c553648160, %c1, [%c64, %c64]) {nosideeffects} : (!vm.ref<!hal.buffer>, i64, i64, i32, i32, i64 ...) -> !vm.ref<!hal.buffer_view>
  vm.return %ref_7 : !vm.ref<!hal.buffer_view>
^bb2(%1: i32):  // pred: ^bb0
  vm.fail %1, "failed to wait on timepoint"
}

