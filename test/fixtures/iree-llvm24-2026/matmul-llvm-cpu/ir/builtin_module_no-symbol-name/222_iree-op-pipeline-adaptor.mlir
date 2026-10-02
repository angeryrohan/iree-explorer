// -----// IR Dump After mlir::iree_compiler::detail::OpPipelineAdaptorPass: iree-op-pipeline-adaptor //----- //
module attributes {vm.toplevel} {
  vm.module public @module {
    vm.global.ref private @__device_0 : !vm.ref<!hal.device>
    vm.global.ref private @__device_0_executable_0_matmul_dispatch_0 : !vm.ref<!hal.executable>
    vm.global.ref private @__matmul_memoize_result_0_device_0 : !vm.ref<!hal.command_buffer>
    vm.rodata private @_utf8_hal_device_id_C6650FF277232B5A {alignment = 1 : i64} "hal.device.id"
    vm.rodata private @_utf8_local_1A8FF0278D7661D8 {alignment = 1 : i64} "local*"
    vm.rodata private @_utf8_hal_executable_format_E03EECB63A2AAF52 {alignment = 1 : i64} "hal.executable.format"
    vm.rodata private @_utf8_embedded_elf_arm_64_87C64FBD3BCE06F5 {alignment = 1 : i64} "embedded-elf-arm_64"
    vm.rodata private @matmul_dispatch_0_embedded_elf_arm_64 {alignment = 16 : i64, mime_type = "application/x-elf"} dense_resource<__elided__> : vector<4504xi8>
    vm.initializer {
      %c1 = vm.const.i32 1
      %null = vm.const.ref.zero : !vm.buffer
      %c14 = vm.const.i32 14
      %c-1 = vm.const.i64 -1
      %c18 = vm.const.i32 18
      %zero = vm.const.i32.zero
      %zero_0 = vm.const.i64.zero
      %c1_1 = vm.const.i64 1
      %null_2 = vm.const.ref.zero : !vm.ref<!hal.device>
      %0 = vm.call @hal.devices.count() {nosideeffects} : () -> i32
      %1 = vm.ext.i32.i64.s %0 : i32 -> i64
      vm.br ^bb1(%zero_0, %zero_0, %null_2 : i64, i64, !vm.ref<!hal.device>)
    ^bb1(%2: i64, %3: i64, %4: !vm.ref<!hal.device>):  // 2 preds: ^bb0, ^bb4
      %rnz = vm.cmp.nz.ref %4 : !vm.ref<!hal.device>
      %5 = vm.xor.i32 %rnz, %c1 : i32
      %slt = vm.cmp.lt.i64.s %2, %1 : i64
      %6 = vm.and.i32 %5, %slt : i32
      vm.cond_br %6, ^bb2, ^bb5
    ^bb2:  // pred: ^bb1
      %7 = vm.trunc.i64.i32 %2 : i64 -> i32
      %ref = vm.call @hal.devices.get(%7) {nosideeffects} : (i32) -> !vm.ref<!hal.device>
      %_utf8_hal_device_id_C6650FF277232B5A = vm.const.ref.rodata @_utf8_hal_device_id_C6650FF277232B5A : !vm.buffer
      %_utf8_local_1A8FF0278D7661D8 = vm.const.ref.rodata @_utf8_local_1A8FF0278D7661D8 : !vm.buffer
      %8:2 = vm.call @hal.device.query.i64(%ref, %_utf8_hal_device_id_C6650FF277232B5A, %_utf8_local_1A8FF0278D7661D8) {nosideeffects} : (!vm.ref<!hal.device>, !vm.buffer, !vm.buffer) -> (i32, i64)
      %nz = vm.cmp.nz.i64 %8#1 : i64
      %9 = vm.select.i32 %8#0, %nz, %zero : i32
      vm.cond_br %9, ^bb3, ^bb4(%zero : i32)
    ^bb3:  // pred: ^bb2
      %_utf8_hal_executable_format_E03EECB63A2AAF52 = vm.const.ref.rodata @_utf8_hal_executable_format_E03EECB63A2AAF52 : !vm.buffer
      %_utf8_embedded_elf_arm_64_87C64FBD3BCE06F5 = vm.const.ref.rodata @_utf8_embedded_elf_arm_64_87C64FBD3BCE06F5 : !vm.buffer
      %10:2 = vm.call @hal.device.query.i64(%ref, %_utf8_hal_executable_format_E03EECB63A2AAF52, %_utf8_embedded_elf_arm_64_87C64FBD3BCE06F5) {nosideeffects} : (!vm.ref<!hal.device>, !vm.buffer, !vm.buffer) -> (i32, i64)
      %nz_3 = vm.cmp.nz.i64 %10#1 : i64
      %11 = vm.select.i32 %10#0, %nz_3, %zero : i32
      vm.br ^bb4(%11 : i32)
    ^bb4(%12: i32):  // 2 preds: ^bb2, ^bb3
      %eq = vm.cmp.eq.i64 %3, %zero_0 : i64
      %13 = vm.select.i64 %12, %c1_1, %zero_0 : i64
      %14 = vm.add.i64 %3, %13 : i64
      %15 = vm.and.i32 %12, %eq : i32
      %ref_4 = vm.select.ref %15, %ref, %null_2 : !vm.ref<!hal.device>
      %16 = vm.add.i64 %2, %c1_1 : i64
      vm.br ^bb1(%16, %14, %ref_4 : i64, i64, !vm.ref<!hal.device>)
    ^bb5:  // pred: ^bb1
      vm.cond_br %5, ^bb6, ^bb7
    ^bb6:  // pred: ^bb5
      vm.fail %c18, "HAL device `__device_0` not found or unavailable: #hal.device.target<\22local\22, [#hal.executable.target<\22llvm-cpu\22, \22embedded-elf-arm_64\22, {cpu = \22generic\22, cpu_features = \22+reserve-x18\22, data_layout = \22e-m:e-p270:32:32-p271:32:32-p272:64:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-Fn32\22, iree.encoding.resolver = #iree_cpu.cpu_encoding_resolver<>, max_stack_allocation_size = 32768 : i64, native_vector_size = 16 : i64, target_triple = \22arm64-unknown-unknown-eabi-elf\22}>]>"
    ^bb7:  // pred: ^bb5
      %_utf8_hal_executable_format_E03EECB63A2AAF52_5 = vm.const.ref.rodata @_utf8_hal_executable_format_E03EECB63A2AAF52 : !vm.buffer
      %_utf8_embedded_elf_arm_64_87C64FBD3BCE06F5_6 = vm.const.ref.rodata @_utf8_embedded_elf_arm_64_87C64FBD3BCE06F5 : !vm.buffer
      %17:2 = vm.call @hal.device.query.i64(%4, %_utf8_hal_executable_format_E03EECB63A2AAF52_5, %_utf8_embedded_elf_arm_64_87C64FBD3BCE06F5_6) {nosideeffects} : (!vm.ref<!hal.device>, !vm.buffer, !vm.buffer) -> (i32, i64)
      %nz_7 = vm.cmp.nz.i64 %17#1 : i64
      %18 = vm.select.i32 %17#0, %nz_7, %zero : i32
      %19 = vm.select.i64 %18, %zero_0, %c-1 : i64
      %eq_8 = vm.cmp.eq.i64 %19, %zero_0 : i64
      vm.global.store.ref %4, @__device_0 : !vm.ref<!hal.device>
      vm.cond_br %eq_8, ^bb8, ^bb9
    ^bb8:  // pred: ^bb7
      %matmul_dispatch_0_embedded_elf_arm_64 = vm.const.ref.rodata @matmul_dispatch_0_embedded_elf_arm_64 : !vm.buffer
      %_utf8_embedded_elf_arm_64_87C64FBD3BCE06F5_9 = vm.const.ref.rodata @_utf8_embedded_elf_arm_64_87C64FBD3BCE06F5 : !vm.buffer
      %ref_10 = vm.call @hal.executable.create(%4, %c-1, %_utf8_embedded_elf_arm_64_87C64FBD3BCE06F5_9, %matmul_dispatch_0_embedded_elf_arm_64, %null) {nosideeffects} : (!vm.ref<!hal.device>, i64, !vm.buffer, !vm.buffer, !vm.buffer) -> !vm.ref<!hal.executable>
      vm.global.store.ref %ref_10, @__device_0_executable_0_matmul_dispatch_0 : !vm.ref<!hal.executable>
      %ref_11 = vm.call @__matmul_memoize_apply() : () -> !vm.ref<!hal.command_buffer>
      vm.global.store.ref %ref_11, @__matmul_memoize_result_0_device_0 : !vm.ref<!hal.command_buffer>
      vm.return
    ^bb9:  // pred: ^bb7
      vm.fail %c14, "HAL device `__device_0` does not support any variant of executable `matmul_dispatch_0`; available formats: [embedded-elf-arm_64]"
    }
    vm.rodata private @_utf8_matmul_dispatch_0_matmul_6_18BAC40F25B1949B {alignment = 1 : i64} "matmul_dispatch_0_matmul_64x64x64_f32"
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
    vm.import private @hal.buffer.assert(%buffer : !vm.ref<!hal.buffer>, %message : !vm.buffer, %allocator : !vm.ref<!hal.allocator>, %minimum_length : i64, %memory_types : i32, %buffer_usage : i32)
    vm.import private @hal.buffer_view.create(%buffer : !vm.ref<!hal.buffer>, %source_offset : i64, %source_length : i64, %element_type : i32, %encoding_type : i32, %shape : i64 ...) -> !vm.ref<!hal.buffer_view> attributes {nosideeffects}
    vm.import private @hal.buffer_view.assert(%buffer_view : !vm.ref<!hal.buffer_view>, %message : !vm.buffer, %element_type : i32, %encoding_type : i32, %shape : i64 ...)
    vm.import private @hal.buffer_view.buffer(%buffer_view : !vm.ref<!hal.buffer_view>) -> !vm.ref<!hal.buffer> attributes {nosideeffects}
    vm.import private @hal.command_buffer.create(%device : !vm.ref<!hal.device>, %modes : i32, %command_categories : i32, %queue_affinity : i64, %binding_capacity : i32) -> !vm.ref<!hal.command_buffer> attributes {minimum_version = 6 : i32}
    vm.import private @hal.command_buffer.finalize(%command_buffer : !vm.ref<!hal.command_buffer>)
    vm.import private @hal.command_buffer.execution_barrier(%command_buffer : !vm.ref<!hal.command_buffer>, %source_stage_mask : i32, %target_stage_mask : i32, %flags : i64)
    vm.import private @hal.command_buffer.dispatch(%command_buffer : !vm.ref<!hal.command_buffer>, %executable : !vm.ref<!hal.executable>, %function_id : i64, %workgroup_x : i32, %workgroup_y : i32, %workgroup_z : i32, %flags : i64, %constants : i32 ..., %bindings : tuple<i32, i32, !vm.ref<!hal.buffer>, i64, i64> ...) attributes {minimum_version = 7 : i32}
    vm.import private @hal.device.allocator(%device : !vm.ref<!hal.device>) -> !vm.ref<!hal.allocator> attributes {nosideeffects}
    vm.import private @hal.device.query.i64(%device : !vm.ref<!hal.device>, %category : !vm.buffer, %key : !vm.buffer) -> (i32, i64) attributes {nosideeffects}
    vm.import private @hal.device.queue.alloca(%device : !vm.ref<!hal.device>, %queue_affinity : i64, %wait_fence : !vm.ref<!hal.fence>, %signal_fence : !vm.ref<!hal.fence>, %pool : i64, %memory_types : i32, %buffer_usage : i32, %allocation_size : i64, %flags : i64) -> !vm.ref<!hal.buffer>
    vm.import private @hal.device.queue.execute.indirect(%device : !vm.ref<!hal.device>, %queue_affinity : i64, %wait_fence : !vm.ref<!hal.fence>, %signal_fence : !vm.ref<!hal.fence>, %command_buffer : !vm.ref<!hal.command_buffer>, %flags : i64, %binding_table : tuple<!vm.ref<!hal.buffer>, i64, i64> ...)
    vm.import private @hal.devices.count() -> i32 attributes {nosideeffects}
    vm.import private @hal.devices.get(%index : i32) -> !vm.ref<!hal.device> attributes {nosideeffects}
    vm.import private @hal.executable.create(%device : !vm.ref<!hal.device>, %queue_affinity : i64, %executable_format : !vm.buffer, %executable_data : !vm.buffer, %constants : !vm.buffer) -> !vm.ref<!hal.executable> attributes {nosideeffects}
    vm.import private @hal.executable.lookup.function(%executable : !vm.ref<!hal.executable>, %function_name : !vm.buffer) -> i64 attributes {minimum_version = 7 : i32, nosideeffects}
    vm.import private @hal.fence.create(%device : !vm.ref<!hal.device>, %flags : i64) -> !vm.ref<!hal.fence>
    vm.import private @hal.fence.await(%timeout_millis : i32, %flags : i64, %fences : !vm.ref<!hal.fence> ...) -> i32 attributes {vm.yield}
    vm.rodata private @_utf8_input0_DCE99660CEB3F6B {alignment = 1 : i64} "input0"
    vm.rodata private @_utf8_tensor_FC1814BC4A58F22A {alignment = 1 : i64} "tensor"
    vm.rodata private @_utf8_input1_B898B726583C85DA {alignment = 1 : i64} "input1"
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
      vm.cond_br %0, ^bb2, ^bb1
    ^bb1:  // pred: ^bb0
      %ref_7 = vm.call.variadic @hal.buffer_view.create(%ref_5, %zero, %c16384, %c553648160, %c1, [%c64, %c64]) {nosideeffects} : (!vm.ref<!hal.buffer>, i64, i64, i32, i32, i64 ...) -> !vm.ref<!hal.buffer_view>
      vm.return %ref_7 : !vm.ref<!hal.buffer_view>
    ^bb2:  // pred: ^bb0
      vm.fail %0, "failed to wait on timepoint"
    }
    vm.export @matmul attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @matmul(%input0: tensor<64x64xf32>, %input1: tensor<64x64xf32>) -> (%output0: tensor<64x64xf32>)"}}
  }
}


