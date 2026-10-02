// -----// IR Dump After ConversionPass: iree-vm-conversion{f32-extension=true f64-extension=true index-bits=64 optimize-for-stack-size=false truncate-unsupported-floats=true} //----- //
module attributes {vm.toplevel} {
  vm.module public @module {
    vm.global.ref private @__device_0 : !vm.ref<!hal.device>
    vm.global.ref private @__device_0_executable_0_matmul_dispatch_0 : !vm.ref<!hal.executable>
    vm.global.ref private @__matmul_memoize_result_0_device_0 : !vm.ref<!hal.command_buffer>
    vm.initializer {
      %null = vm.const.ref.zero : !vm.ref<!hal.executable>
      %c14 = vm.const.i32 14
      %c-1 = vm.const.i64 -1
      %c-1_0 = vm.const.i64 -1
      %c18 = vm.const.i32 18
      %zero = vm.const.i32.zero
      %zero_1 = vm.const.i64.zero
      %c1 = vm.const.i64 1
      %null_2 = vm.const.ref.zero : !vm.ref<!hal.device>
      %0 = vm.call @hal.devices.count() {nosideeffects} : () -> i32
      %1 = vm.ext.i32.i64.s %0 : i32 -> i64
      vm.br ^bb1(%zero_1, %zero_1, %null_2 : i64, i64, !vm.ref<!hal.device>)
    ^bb1(%2: i64, %3: i64, %4: !vm.ref<!hal.device>):  // 2 preds: ^bb0, ^bb4
      %req = vm.cmp.eq.ref %4, %null_2 : !vm.ref<!hal.device>
      %slt = vm.cmp.lt.i64.s %2, %1 : i64
      %5 = vm.and.i32 %req, %slt : i32
      vm.cond_br %5, ^bb2, ^bb5
    ^bb2:  // pred: ^bb1
      %6 = vm.trunc.i64.i32 %2 : i64 -> i32
      %ref = vm.call @hal.devices.get(%6) {nosideeffects} : (i32) -> !vm.ref<!hal.device>
      %buffer = vm.rodata.inline "_utf8_hal_device_id_C6650FF277232B5A" {alignment = 1 : i64} : !vm.buffer = "hal.device.id"
      %buffer_3 = vm.rodata.inline "_utf8_local_1A8FF0278D7661D8" {alignment = 1 : i64} : !vm.buffer = "local*"
      %7:2 = vm.call @hal.device.query.i64(%ref, %buffer, %buffer_3) {nosideeffects} : (!vm.ref<!hal.device>, !vm.buffer, !vm.buffer) -> (i32, i64)
      %nz = vm.cmp.nz.i64 %7#1 : i64
      %zero_4 = vm.const.i32.zero
      %8 = vm.select.i32 %7#0, %nz, %zero_4 : i32
      %c1_5 = vm.const.i32 1
      vm.cond_br %8, ^bb3, ^bb4(%zero : i32)
    ^bb3:  // pred: ^bb2
      %buffer_6 = vm.rodata.inline "_utf8_hal_executable_format_E03EECB63A2AAF52" {alignment = 1 : i64} : !vm.buffer = "hal.executable.format"
      %buffer_7 = vm.rodata.inline "_utf8_embedded_elf_arm_64_87C64FBD3BCE06F5" {alignment = 1 : i64} : !vm.buffer = "embedded-elf-arm_64"
      %9:2 = vm.call @hal.device.query.i64(%ref, %buffer_6, %buffer_7) {nosideeffects} : (!vm.ref<!hal.device>, !vm.buffer, !vm.buffer) -> (i32, i64)
      %nz_8 = vm.cmp.nz.i64 %9#1 : i64
      %zero_9 = vm.const.i32.zero
      %10 = vm.select.i32 %9#0, %nz_8, %zero_9 : i32
      %c1_10 = vm.const.i32 1
      vm.br ^bb4(%10 : i32)
    ^bb4(%11: i32):  // 2 preds: ^bb2, ^bb3
      %eq = vm.cmp.eq.i64 %3, %zero_1 : i64
      %12 = vm.select.i64 %11, %c1, %zero_1 : i64
      %13 = vm.add.i64 %3, %12 : i64
      %14 = vm.and.i32 %11, %eq : i32
      %ref_11 = vm.select.ref %14, %ref, %null_2 : !vm.ref<!hal.device>
      %15 = vm.add.i64 %2, %c1 : i64
      vm.br ^bb1(%15, %13, %ref_11 : i64, i64, !vm.ref<!hal.device>)
    ^bb5:  // pred: ^bb1
      vm.cond_br %req, ^bb6, ^bb7
    ^bb6:  // pred: ^bb5
      vm.cond_fail %c18, "HAL device `__device_0` not found or unavailable: #hal.device.target<"local", [#hal.executable.target<"llvm-cpu", "embedded-elf-arm_64", {cpu = "generic", cpu_features = "+reserve-x18", data_layout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-Fn32", iree.encoding.resolver = #iree_cpu.cpu_encoding_resolver<>, max_stack_allocation_size = 32768 : i64, native_vector_size = 16 : i64, target_triple = "arm64-unknown-unknown-eabi-elf"}>]>"
      vm.br ^bb7
    ^bb7:  // 2 preds: ^bb5, ^bb6
      %buffer_12 = vm.rodata.inline "_utf8_hal_executable_format_E03EECB63A2AAF52" {alignment = 1 : i64} : !vm.buffer = "hal.executable.format"
      %buffer_13 = vm.rodata.inline "_utf8_embedded_elf_arm_64_87C64FBD3BCE06F5" {alignment = 1 : i64} : !vm.buffer = "embedded-elf-arm_64"
      %16:2 = vm.call @hal.device.query.i64(%4, %buffer_12, %buffer_13) {nosideeffects} : (!vm.ref<!hal.device>, !vm.buffer, !vm.buffer) -> (i32, i64)
      %nz_14 = vm.cmp.nz.i64 %16#1 : i64
      %zero_15 = vm.const.i32.zero
      %17 = vm.select.i32 %16#0, %nz_14, %zero_15 : i32
      %c1_16 = vm.const.i32 1
      %18 = vm.select.i64 %17, %zero_1, %c-1 : i64
      %eq_17 = vm.cmp.eq.i64 %18, %zero_1 : i64
      vm.global.store.ref %4, @__device_0 : !vm.ref<!hal.device>
      vm.cond_br %eq_17, ^bb8, ^bb9
    ^bb8:  // pred: ^bb7
      %buffer_18 = vm.rodata.inline "matmul_dispatch_0_embedded_elf_arm_64" {alignment = 16 : i64, mime_type = "application/x-elf"} : !vm.buffer = dense_resource<__elided__> : vector<4504xi8>
      %buffer_19 = vm.rodata.inline "_utf8_embedded_elf_arm_64_87C64FBD3BCE06F5" {alignment = 1 : i64} : !vm.buffer = "embedded-elf-arm_64"
      %null_20 = vm.const.ref.zero : !vm.buffer
      %ref_21 = vm.call @hal.executable.create(%4, %c-1_0, %buffer_19, %buffer_18, %null_20) {nosideeffects} : (!vm.ref<!hal.device>, i64, !vm.buffer, !vm.buffer, !vm.buffer) -> !vm.ref<!hal.executable>
      vm.br ^bb10(%ref_21 : !vm.ref<!hal.executable>)
    ^bb9:  // pred: ^bb7
      vm.cond_fail %c14, "HAL device `__device_0` does not support any variant of executable `matmul_dispatch_0`; available formats: [embedded-elf-arm_64]"
      vm.br ^bb10(%null : !vm.ref<!hal.executable>)
    ^bb10(%19: !vm.ref<!hal.executable>):  // 2 preds: ^bb8, ^bb9
      vm.global.store.ref %19, @__device_0_executable_0_matmul_dispatch_0 : !vm.ref<!hal.executable>
      %ref_22 = vm.call @__matmul_memoize_apply() : () -> !vm.ref<!hal.command_buffer>
      vm.global.store.ref %ref_22, @__matmul_memoize_result_0_device_0 : !vm.ref<!hal.command_buffer>
      vm.return
    }
    vm.func private @__matmul_memoize_apply() -> !vm.ref<!hal.command_buffer> attributes {inlining_policy = #util.inline.never} {
      %c16384 = vm.const.i64 16384
      %c2 = vm.const.i64 2
      %c1 = vm.const.i64 1
      %zero = vm.const.i64.zero
      %c3 = vm.const.i64 3
      %c8 = vm.const.i64 8
      %c-1 = vm.const.i64 -1
      %__device_0 = vm.global.load.ref immutable @__device_0 : !vm.ref<!hal.device>
      %__device_0_executable_0_matmul_dispatch_0 = vm.global.load.ref immutable @__device_0_executable_0_matmul_dispatch_0 : !vm.ref<!hal.executable>
      %zero_0 = vm.const.i32.zero
      %c3_1 = vm.const.i32 3
      %c3_2 = vm.const.i32 3
      %ref = vm.call @hal.command_buffer.create(%__device_0, %zero_0, %c3_1, %c-1, %c3_2) : (!vm.ref<!hal.device>, i32, i32, i64, i32) -> !vm.ref<!hal.command_buffer>
      %buffer = vm.rodata.inline "_utf8_matmul_dispatch_0_matmul_6_18BAC40F25B1949B" {alignment = 1 : i64} : !vm.buffer = "matmul_dispatch_0_matmul_64x64x64_f32"
      %0 = vm.call @hal.executable.lookup.function(%__device_0_executable_0_matmul_dispatch_0, %buffer) {nosideeffects} : (!vm.ref<!hal.executable>, !vm.buffer) -> i64
      %zero_3 = vm.const.i32.zero
      %c8_4 = vm.const.i32 8
      %c1_5 = vm.const.i32 1
      %c1_6 = vm.const.i32 1
      %zero_7 = vm.const.i64 0
      %zero_8 = vm.const.i32.zero
      %null = vm.const.ref.zero : !vm.ref<!hal.buffer>
      %c1_9 = vm.const.i32 1
      %null_10 = vm.const.ref.zero : !vm.ref<!hal.buffer>
      %c2_11 = vm.const.i32 2
      %null_12 = vm.const.ref.zero : !vm.ref<!hal.buffer>
      vm.call.variadic @hal.command_buffer.dispatch(%ref, %__device_0_executable_0_matmul_dispatch_0, %0, %c8_4, %c1_5, %c1_6, %zero_7, [], [(%zero_3, %zero_8, %null, %zero, %c16384), (%zero_3, %c1_9, %null_10, %zero, %c16384), (%zero_3, %c2_11, %null_12, %zero, %c16384)]) : (!vm.ref<!hal.command_buffer>, !vm.ref<!hal.executable>, i64, i32, i32, i32, i64, i32 ..., tuple<i32, i32, !vm.ref<!hal.buffer>, i64, i64> ...)
      %c28 = vm.const.i32 28
      %c13 = vm.const.i32 13
      %zero_13 = vm.const.i64.zero
      vm.call @hal.command_buffer.execution_barrier(%ref, %c28, %c13, %zero_13) : (!vm.ref<!hal.command_buffer>, i32, i32, i64) -> ()
      vm.call @hal.command_buffer.finalize(%ref) : (!vm.ref<!hal.command_buffer>) -> ()
      vm.return %ref : !vm.ref<!hal.command_buffer>
    }
    vm.import private @hal.ex.file.from_memory(%device : !vm.ref<!hal.device>, %queue_affinity : i64, %access : i32, %buffer : !vm.buffer, %offset : i64, %length : i64, %flags : i32) -> !vm.ref<!hal.file>
    vm.import private @hal.allocator.select(%memory_types : i32, %buffer_usage : i32, %flags : i64, %from : tuple<!vm.ref<!hal.device>, i64> ...) -> (!vm.ref<!hal.device>, i64) attributes {nosideeffects}
    vm.import private @hal.allocator.allocate(%allocator : !vm.ref<!hal.allocator>, %queue_affinity : i64, %memory_types : i32, %buffer_usage : i32, %allocation_size : i64) -> !vm.ref<!hal.buffer>
    vm.import private @hal.allocator.import(%allocator : !vm.ref<!hal.allocator>, %try : i32, %queue_affinity : i64, %memory_types : i32, %buffer_usage : i32, %source : !vm.buffer, %offset : i64, %length : i64) -> !vm.ref<!hal.buffer>
    vm.import private @hal.buffer.assert(%buffer : !vm.ref<!hal.buffer>, %message : !vm.buffer, %allocator : !vm.ref<!hal.allocator>, %minimum_length : i64, %memory_types : i32, %buffer_usage : i32)
    vm.import private @hal.buffer.allocation.preserve(%buffer : !vm.ref<!hal.buffer>)
    vm.import private @hal.buffer.allocation.discard(%buffer : !vm.ref<!hal.buffer>) -> i32
    vm.import private @hal.buffer.allocation.is_terminal(%buffer : !vm.ref<!hal.buffer>) -> i32
    vm.import private @hal.buffer.subspan(%source_buffer : !vm.ref<!hal.buffer>, %source_offset : i64, %length : i64) -> !vm.ref<!hal.buffer> attributes {nosideeffects}
    vm.import private @hal.buffer.length(%buffer : !vm.ref<!hal.buffer>) -> i64 attributes {nosideeffects}
    vm.import private @hal.buffer.load(%source_buffer : !vm.ref<!hal.buffer>, %source_offset : i64, %length : i32) -> i32
    vm.import private @hal.buffer.store(%value : i32, %target_buffer : !vm.ref<!hal.buffer>, %target_offset : i64, %length : i32)
    vm.import private @hal.buffer_view.create(%buffer : !vm.ref<!hal.buffer>, %source_offset : i64, %source_length : i64, %element_type : i32, %encoding_type : i32, %shape : i64 ...) -> !vm.ref<!hal.buffer_view> attributes {nosideeffects}
    vm.import private @hal.buffer_view.assert(%buffer_view : !vm.ref<!hal.buffer_view>, %message : !vm.buffer, %element_type : i32, %encoding_type : i32, %shape : i64 ...)
    vm.import private @hal.buffer_view.buffer(%buffer_view : !vm.ref<!hal.buffer_view>) -> !vm.ref<!hal.buffer> attributes {nosideeffects}
    vm.import private @hal.buffer_view.element_type(%buffer_view : !vm.ref<!hal.buffer_view>) -> i32 attributes {nosideeffects}
    vm.import private @hal.buffer_view.encoding_type(%buffer_view : !vm.ref<!hal.buffer_view>) -> i32 attributes {nosideeffects}
    vm.import private @hal.buffer_view.rank(%buffer_view : !vm.ref<!hal.buffer_view>) -> i32 attributes {nosideeffects}
    vm.import private @hal.buffer_view.dim(%buffer_view : !vm.ref<!hal.buffer_view>, %index : i32) -> i64 attributes {nosideeffects}
    vm.import private @hal.buffer_view.trace(%key : !vm.buffer, %operands : !vm.ref<!hal.buffer_view> ...)
    vm.import private @hal.channel.create(%device : !vm.ref<!hal.device>, %queue_affinity : i64, %flags : i64, %id : !vm.buffer, %group : !vm.buffer, %rank : i32, %count : i32) -> !vm.ref<!hal.channel> attributes {nosideeffects}
    vm.import private @hal.channel.split(%channel : !vm.ref<!hal.channel>, %color : i32, %key : i32, %flags : i64) -> !vm.ref<!hal.channel> attributes {nosideeffects}
    vm.import private @hal.channel.rank_and_count(%channel : !vm.ref<!hal.channel>) -> (i32, i32) attributes {nosideeffects}
    vm.import private @hal.command_buffer.create(%device : !vm.ref<!hal.device>, %modes : i32, %command_categories : i32, %queue_affinity : i64, %binding_capacity : i32) -> !vm.ref<!hal.command_buffer> attributes {minimum_version = 6 : i32}
    vm.import private @hal.command_buffer.finalize(%command_buffer : !vm.ref<!hal.command_buffer>)
    vm.import private @hal.command_buffer.begin_debug_group(%command_buffer : !vm.ref<!hal.command_buffer>, %label : !vm.buffer)
    vm.import private @hal.command_buffer.end_debug_group(%command_buffer : !vm.ref<!hal.command_buffer>)
    vm.import private @hal.command_buffer.execution_barrier(%command_buffer : !vm.ref<!hal.command_buffer>, %source_stage_mask : i32, %target_stage_mask : i32, %flags : i64)
    vm.import private @hal.command_buffer.advise_buffer(%command_buffer : !vm.ref<!hal.command_buffer>, %buffer : !vm.ref<!hal.buffer>, %flags : i64, %arg0 : i64, %arg1 : i64, %buffer_slot : i32)
    vm.import private @hal.command_buffer.fill_buffer(%command_buffer : !vm.ref<!hal.command_buffer>, %target_buffer : !vm.ref<!hal.buffer>, %target_offset : i64, %length : i64, %target_buffer_slot : i32, %pattern : i64, %pattern_length : i32, %flags : i64)
    vm.import private @hal.command_buffer.update_buffer(%command_buffer : !vm.ref<!hal.command_buffer>, %source_buffer : !vm.buffer, %source_offset : i64, %target_buffer : !vm.ref<!hal.buffer>, %target_offset : i64, %length : i64, %target_buffer_slot : i32, %flags : i64)
    vm.import private @hal.command_buffer.copy_buffer(%command_buffer : !vm.ref<!hal.command_buffer>, %source_buffer_slot : i32, %target_buffer_slot : i32, %source_buffer : !vm.ref<!hal.buffer>, %source_offset : i64, %target_buffer : !vm.ref<!hal.buffer>, %target_offset : i64, %length : i64, %flags : i64)
    vm.import private @hal.command_buffer.collective(%command_buffer : !vm.ref<!hal.command_buffer>, %channel : !vm.ref<!hal.channel>, %op : i32, %param : i32, %send_buffer_slot : i32, %recv_buffer_slot : i32, %send_buffer : !vm.ref<!hal.buffer>, %recv_buffer : !vm.ref<!hal.buffer>, %send_offset : i64, %send_length : i64, %recv_offset : i64, %recv_length : i64, %element_count : i64)
    vm.import private @hal.command_buffer.dispatch(%command_buffer : !vm.ref<!hal.command_buffer>, %executable : !vm.ref<!hal.executable>, %function_id : i64, %workgroup_x : i32, %workgroup_y : i32, %workgroup_z : i32, %flags : i64, %constants : i32 ..., %bindings : tuple<i32, i32, !vm.ref<!hal.buffer>, i64, i64> ...) attributes {minimum_version = 7 : i32}
    vm.import private @hal.command_buffer.dispatch.indirect(%command_buffer : !vm.ref<!hal.command_buffer>, %executable : !vm.ref<!hal.executable>, %function_id : i64, %workgroups_buffer_slot : i32, %workgroups_buffer : !vm.ref<!hal.buffer>, %workgroups_offset : i64, %flags : i64, %constants : i32 ..., %bindings : tuple<i32, i32, !vm.ref<!hal.buffer>, i64, i64> ...) attributes {minimum_version = 7 : i32}
    vm.import private @hal.device.allocator(%device : !vm.ref<!hal.device>) -> !vm.ref<!hal.allocator> attributes {nosideeffects}
    vm.import private @hal.device.query.i64(%device : !vm.ref<!hal.device>, %category : !vm.buffer, %key : !vm.buffer) -> (i32, i64) attributes {nosideeffects}
    vm.import private @hal.device.queue.alloca(%device : !vm.ref<!hal.device>, %queue_affinity : i64, %wait_fence : !vm.ref<!hal.fence>, %signal_fence : !vm.ref<!hal.fence>, %pool : i64, %memory_types : i32, %buffer_usage : i32, %allocation_size : i64, %flags : i64) -> !vm.ref<!hal.buffer>
    vm.import private @hal.device.queue.dealloca(%device : !vm.ref<!hal.device>, %queue_affinity : i64, %wait_fence : !vm.ref<!hal.fence>, %signal_fence : !vm.ref<!hal.fence>, %buffer : !vm.ref<!hal.buffer>, %flags : i64)
    vm.import private @hal.device.queue.fill(%device : !vm.ref<!hal.device>, %queue_affinity : i64, %wait_fence : !vm.ref<!hal.fence>, %signal_fence : !vm.ref<!hal.fence>, %target_buffer : !vm.ref<!hal.buffer>, %target_offset : i64, %length : i64, %pattern : i64, %pattern_length : i32, %flags : i64)
    vm.import private @hal.device.queue.update(%device : !vm.ref<!hal.device>, %queue_affinity : i64, %wait_fence : !vm.ref<!hal.fence>, %signal_fence : !vm.ref<!hal.fence>, %source_buffer : !vm.buffer, %source_offset : i64, %target_buffer : !vm.ref<!hal.buffer>, %target_offset : i64, %length : i64, %flags : i64)
    vm.import private @hal.device.queue.copy(%device : !vm.ref<!hal.device>, %queue_affinity : i64, %wait_fence : !vm.ref<!hal.fence>, %signal_fence : !vm.ref<!hal.fence>, %source_buffer : !vm.ref<!hal.buffer>, %source_offset : i64, %target_buffer : !vm.ref<!hal.buffer>, %target_offset : i64, %length : i64, %flags : i64)
    vm.import private @hal.device.queue.read(%device : !vm.ref<!hal.device>, %queue_affinity : i64, %wait_fence : !vm.ref<!hal.fence>, %signal_fence : !vm.ref<!hal.fence>, %source_file : !vm.ref<!hal.file>, %source_offset : i64, %target_buffer : !vm.ref<!hal.buffer>, %target_offset : i64, %length : i64, %flags : i64)
    vm.import private @hal.device.queue.write(%device : !vm.ref<!hal.device>, %queue_affinity : i64, %wait_fence : !vm.ref<!hal.fence>, %signal_fence : !vm.ref<!hal.fence>, %source_buffer : !vm.ref<!hal.buffer>, %source_offset : i64, %target_file : !vm.ref<!hal.file>, %target_offset : i64, %length : i64, %flags : i64)
    vm.import private @hal.device.queue.barrier(%device : !vm.ref<!hal.device>, %queue_affinity : i64, %wait_fence : !vm.ref<!hal.fence>, %signal_fence : !vm.ref<!hal.fence>, %flags : i64)
    vm.import private @hal.device.queue.execute(%device : !vm.ref<!hal.device>, %queue_affinity : i64, %wait_fence : !vm.ref<!hal.fence>, %signal_fence : !vm.ref<!hal.fence>, %command_buffer : !vm.ref<!hal.command_buffer>, %flags : i64)
    vm.import private @hal.device.queue.execute.indirect(%device : !vm.ref<!hal.device>, %queue_affinity : i64, %wait_fence : !vm.ref<!hal.fence>, %signal_fence : !vm.ref<!hal.fence>, %command_buffer : !vm.ref<!hal.command_buffer>, %flags : i64, %binding_table : tuple<!vm.ref<!hal.buffer>, i64, i64> ...)
    vm.import private @hal.device.queue.flush(%device : !vm.ref<!hal.device>, %queue_affinity : i64)
    vm.import private @hal.devices.count() -> i32 attributes {nosideeffects}
    vm.import private @hal.devices.get(%index : i32) -> !vm.ref<!hal.device> attributes {nosideeffects}
    vm.import private @hal.executable.create(%device : !vm.ref<!hal.device>, %queue_affinity : i64, %executable_format : !vm.buffer, %executable_data : !vm.buffer, %constants : !vm.buffer) -> !vm.ref<!hal.executable> attributes {nosideeffects}
    vm.import private @hal.executable.lookup.function(%executable : !vm.ref<!hal.executable>, %function_name : !vm.buffer) -> i64 attributes {minimum_version = 7 : i32, nosideeffects}
    vm.import private @hal.fence.create(%device : !vm.ref<!hal.device>, %flags : i64) -> !vm.ref<!hal.fence>
    vm.import private @hal.fence.join(%flags : i64, %fences : !vm.ref<!hal.fence> ...) -> !vm.ref<!hal.fence> attributes {nosideeffects}
    vm.import private @hal.fence.query(%fence : !vm.ref<!hal.fence>) -> i32
    vm.import private @hal.fence.signal(%fence : !vm.ref<!hal.fence>)
    vm.import private @hal.fence.fail(%fence : !vm.ref<!hal.fence>, %status : i32)
    vm.import private @hal.fence.await(%timeout_millis : i32, %flags : i64, %fences : !vm.ref<!hal.fence> ...) -> i32 attributes {vm.yield}
    vm.func private @matmul(%arg0: !vm.ref<!hal.buffer_view>, %arg1: !vm.ref<!hal.buffer_view>) -> !vm.ref<!hal.buffer_view> attributes {iree.reflection = {iree.abi.declaration = "sync func @matmul(%input0: tensor<64x64xf32>, %input1: tensor<64x64xf32>) -> (%output0: tensor<64x64xf32>)"}} {
      %c3075 = vm.const.i32 3075
      %c48 = vm.const.i32 48
      %c64 = vm.const.i64 64
      %c16384 = vm.const.i64 16384
      %zero = vm.const.i64.zero
      %c-1 = vm.const.i64 -1
      %null = vm.const.ref.zero : !vm.ref<!hal.fence>
      %zero_0 = vm.const.i64.zero
      %c-1_1 = vm.const.i32 -1
      %__device_0 = vm.global.load.ref immutable @__device_0 : !vm.ref<!hal.device>
      %__matmul_memoize_result_0_device_0 = vm.global.load.ref immutable @__matmul_memoize_result_0_device_0 : !vm.ref<!hal.command_buffer>
      %c553648160 = vm.const.i32 553648160
      %c1 = vm.const.i32 1
      %buffer = vm.rodata.inline "_utf8_input0_DCE99660CEB3F6B" {alignment = 1 : i64} : !vm.buffer = "input0"
      vm.call.variadic @hal.buffer_view.assert(%arg0, %buffer, %c553648160, %c1, [%c64, %c64]) : (!vm.ref<!hal.buffer_view>, !vm.buffer, i32, i32, i64 ...)
      %ref = vm.call @hal.buffer_view.buffer(%arg0) {nosideeffects} : (!vm.ref<!hal.buffer_view>) -> !vm.ref<!hal.buffer>
      %ref_2 = vm.call @hal.device.allocator(%__device_0) {nosideeffects} : (!vm.ref<!hal.device>) -> !vm.ref<!hal.allocator>
      %buffer_3 = vm.rodata.inline "_utf8_tensor_FC1814BC4A58F22A" {alignment = 1 : i64} : !vm.buffer = "tensor"
      %c16 = vm.const.i32 16
      %c3075_4 = vm.const.i32 3075
      vm.call @hal.buffer.assert(%ref, %buffer_3, %ref_2, %c16384, %c16, %c3075_4) : (!vm.ref<!hal.buffer>, !vm.buffer, !vm.ref<!hal.allocator>, i64, i32, i32) -> ()
      %buffer_5 = vm.rodata.inline "_utf8_input1_B898B726583C85DA" {alignment = 1 : i64} : !vm.buffer = "input1"
      vm.call.variadic @hal.buffer_view.assert(%arg1, %buffer_5, %c553648160, %c1, [%c64, %c64]) : (!vm.ref<!hal.buffer_view>, !vm.buffer, i32, i32, i64 ...)
      %ref_6 = vm.call @hal.buffer_view.buffer(%arg1) {nosideeffects} : (!vm.ref<!hal.buffer_view>) -> !vm.ref<!hal.buffer>
      %buffer_7 = vm.rodata.inline "_utf8_tensor_FC1814BC4A58F22A" {alignment = 1 : i64} : !vm.buffer = "tensor"
      %c16_8 = vm.const.i32 16
      %c3075_9 = vm.const.i32 3075
      vm.call @hal.buffer.assert(%ref_6, %buffer_7, %ref_2, %c16384, %c16_8, %c3075_9) : (!vm.ref<!hal.buffer>, !vm.buffer, !vm.ref<!hal.allocator>, i64, i32, i32) -> ()
      %zero_10 = vm.const.i64.zero
      %ref_11 = vm.call @hal.fence.create(%__device_0, %zero_10) : (!vm.ref<!hal.device>, i64) -> !vm.ref<!hal.fence>
      %zero_12 = vm.const.i64.zero
      %ref_13 = vm.call @hal.device.queue.alloca(%__device_0, %c-1, %null, %ref_11, %zero_0, %c48, %c3075, %c16384, %zero_12) : (!vm.ref<!hal.device>, i64, !vm.ref<!hal.fence>, !vm.ref<!hal.fence>, i64, i32, i32, i64, i64) -> !vm.ref<!hal.buffer>
      %zero_14 = vm.const.i64.zero
      %ref_15 = vm.call @hal.fence.create(%__device_0, %zero_14) : (!vm.ref<!hal.device>, i64) -> !vm.ref<!hal.fence>
      %zero_16 = vm.const.i64 0
      vm.call.variadic @hal.device.queue.execute.indirect(%__device_0, %c-1, %ref_11, %ref_15, %__matmul_memoize_result_0_device_0, %zero_16, [(%ref, %zero, %c16384), (%ref_6, %zero, %c16384), (%ref_13, %zero, %c16384)]) : (!vm.ref<!hal.device>, i64, !vm.ref<!hal.fence>, !vm.ref<!hal.fence>, !vm.ref<!hal.command_buffer>, i64, tuple<!vm.ref<!hal.buffer>, i64, i64> ...)
      %zero_17 = vm.const.i64.zero
      %0 = vm.call.variadic @hal.fence.await(%c-1_1, %zero_17, [%ref_15]) : (i32, i64, !vm.ref<!hal.fence> ...) -> i32
      vm.cond_fail %0, "failed to wait on timepoint"
      %ref_18 = vm.call.variadic @hal.buffer_view.create(%ref_13, %zero, %c16384, %c553648160, %c1, [%c64, %c64]) {nosideeffects} : (!vm.ref<!hal.buffer>, i64, i64, i32, i32, i64 ...) -> !vm.ref<!hal.buffer_view>
      vm.return %ref_18 : !vm.ref<!hal.buffer_view>
    }
    vm.export @matmul attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @matmul(%input0: tensor<64x64xf32>, %input1: tensor<64x64xf32>) -> (%output0: tensor<64x64xf32>)"}}
  }
}


