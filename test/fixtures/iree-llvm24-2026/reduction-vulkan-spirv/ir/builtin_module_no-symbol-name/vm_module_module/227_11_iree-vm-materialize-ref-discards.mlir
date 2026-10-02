// -----// IR Dump After MaterializeRefDiscardsPass: iree-vm-materialize-ref-discards //----- //
vm.module public @module {
  vm.global.ref private mutable @__device_0 : !vm.ref<!hal.device>
  vm.global.ref private mutable @__device_0_executable_0_rowsum_dispatch_0 : !vm.ref<!hal.executable>
  vm.global.ref private mutable @__rowsum_memoize_result_0_device_0 : !vm.ref<!hal.command_buffer>
  vm.rodata private @_utf8_hal_device_id_C6650FF277232B5A {alignment = 1 : i64} "hal.device.id"
  vm.rodata private @_utf8_vulkan_21E229659EF17384 {alignment = 1 : i64} "vulkan"
  vm.rodata private @_utf8_hal_executable_format_E03EECB63A2AAF52 {alignment = 1 : i64} "hal.executable.format"
  vm.rodata private @_utf8_vulkan_spirv_fb_F1746836E71F8C73 {alignment = 1 : i64} "vulkan-spirv-fb"
  vm.rodata private @rowsum_dispatch_0_vulkan_spirv_fb {alignment = 16 : i64, mime_type = "application/x-flatbuffers"} dense_resource<__elided__> : vector<1736xi8>
  vm.rodata private @_utf8_rowsum_dispatch_0_reductio_98347A448C00BBA0 {alignment = 1 : i64} "rowsum_dispatch_0_reduction_8x100_f32"
  vm.func private @__rowsum_memoize_apply() -> !vm.ref<!hal.command_buffer> attributes {inlining_policy = #util.inline.never, vm.unwind} {
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
    %__device_0 = vm.global.load.ref @__device_0 : !vm.ref<!hal.device>
    %__device_0_executable_0_rowsum_dispatch_0 = vm.global.load.ref @__device_0_executable_0_rowsum_dispatch_0 : !vm.ref<!hal.executable>
    %ref = vm.call @hal.command_buffer.create(%__device_0, %zero, %c3, %c-1, %c2) : (!vm.ref<!hal.device>, i32, i32, i64, i32) -> !vm.ref<!hal.command_buffer>
    %_utf8_rowsum_dispatch_0_reductio_98347A448C00BBA0 = vm.const.ref.rodata @_utf8_rowsum_dispatch_0_reductio_98347A448C00BBA0 : !vm.buffer
    %0 = vm.call @hal.executable.lookup.function(%__device_0_executable_0_rowsum_dispatch_0, %_utf8_rowsum_dispatch_0_reductio_98347A448C00BBA0) {nosideeffects} : (!vm.ref<!hal.executable>, !vm.buffer) -> i64
    vm.call.variadic @hal.command_buffer.dispatch(%ref, %__device_0_executable_0_rowsum_dispatch_0, %0, %c1, %c1, %c1, %zero_0, [], [(%zero, %zero, %null, %zero_0, %c3200), (%zero, %c1, %null, %zero_0, %c32)]) : (!vm.ref<!hal.command_buffer>, !vm.ref<!hal.executable>, i64, i32, i32, i32, i64, i32 ..., tuple<i32, i32, !vm.ref<!hal.buffer>, i64, i64> ...)
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
  vm.func private @rowsum(%arg0: !vm.ref<!hal.buffer_view>) -> !vm.ref<!hal.buffer_view> attributes {iree.reflection = {iree.abi.declaration = "sync func @rowsum(%input0: tensor<8x100xf32>) -> (%output0: tensor<8xf32>)"}, vm.unwind, vm.yield} {
    %c16 = vm.const.i32 16
    %c1 = vm.const.i32 1
    %c553648160 = vm.const.i32 553648160
    %c3075 = vm.const.i32 3075
    %c48 = vm.const.i32 48
    %c8 = vm.const.i64 8
    %c100 = vm.const.i64 100
    %c3200 = vm.const.i64 3200
    %c32 = vm.const.i64 32
    %zero = vm.const.i64.zero
    %c-1 = vm.const.i64 -1
    %null = vm.const.ref.zero : !vm.ref<!hal.fence>
    %c-1_0 = vm.const.i32 -1
    %__device_0 = vm.global.load.ref @__device_0 : !vm.ref<!hal.device>
    %__rowsum_memoize_result_0_device_0 = vm.global.load.ref @__rowsum_memoize_result_0_device_0 : !vm.ref<!hal.command_buffer>
    %_utf8_input0_DCE99660CEB3F6B = vm.const.ref.rodata @_utf8_input0_DCE99660CEB3F6B : !vm.buffer
    vm.call.variadic @hal.buffer_view.assert(%arg0, %_utf8_input0_DCE99660CEB3F6B, %c553648160, %c1, [%c8, %c100]) : (!vm.ref<!hal.buffer_view>, !vm.buffer, i32, i32, i64 ...)
    %ref = vm.call @hal.buffer_view.buffer(%arg0) {nosideeffects} : (!vm.ref<!hal.buffer_view>) -> !vm.ref<!hal.buffer>
    %ref_1 = vm.call @hal.device.allocator(%__device_0) {nosideeffects} : (!vm.ref<!hal.device>) -> !vm.ref<!hal.allocator>
    %_utf8_tensor_FC1814BC4A58F22A = vm.const.ref.rodata @_utf8_tensor_FC1814BC4A58F22A : !vm.buffer
    vm.call @hal.buffer.assert(%ref, %_utf8_tensor_FC1814BC4A58F22A, %ref_1, %c3200, %c16, %c3075) : (!vm.ref<!hal.buffer>, !vm.buffer, !vm.ref<!hal.allocator>, i64, i32, i32) -> ()
    %ref_2 = vm.call @hal.fence.create(%__device_0, %zero) : (!vm.ref<!hal.device>, i64) -> !vm.ref<!hal.fence>
    %ref_3 = vm.call @hal.device.queue.alloca(%__device_0, %c-1, %null, %ref_2, %zero, %c48, %c3075, %c32, %zero) : (!vm.ref<!hal.device>, i64, !vm.ref<!hal.fence>, !vm.ref<!hal.fence>, i64, i32, i32, i64, i64) -> !vm.ref<!hal.buffer>
    %ref_4 = vm.call @hal.fence.create(%__device_0, %zero) : (!vm.ref<!hal.device>, i64) -> !vm.ref<!hal.fence>
    vm.call.variadic @hal.device.queue.execute.indirect(%__device_0, %c-1, %ref_2, %ref_4, %__rowsum_memoize_result_0_device_0, %zero, [(%ref, %zero, %c3200), (%ref_3, %zero, %c32)]) : (!vm.ref<!hal.device>, i64, !vm.ref<!hal.fence>, !vm.ref<!hal.fence>, !vm.ref<!hal.command_buffer>, i64, tuple<!vm.ref<!hal.buffer>, i64, i64> ...)
    vm.call.variadic.yieldable @hal.fence.await(%c-1_0, %zero, %ref_4) {segment_sizes = dense<[-1, -1, 1]> : vector<3xi16>, segment_types = [i32, i64, !vm.ref<!hal.fence>]} : (i32, i64, !vm.ref<!hal.fence>) -> ^bb1 (i32)
  ^bb1(%0: i32):  // pred: ^bb0
    vm.cond_br %0, ^bb3, ^bb2
  ^bb2:  // pred: ^bb1
    %ref_5 = vm.call.variadic @hal.buffer_view.create(%ref_3, %zero, %c32, %c553648160, %c1, [%c8]) {nosideeffects} : (!vm.ref<!hal.buffer>, i64, i64, i32, i32, i64 ...) -> !vm.ref<!hal.buffer_view>
    vm.return %ref_5 : !vm.ref<!hal.buffer_view>
  ^bb3:  // pred: ^bb1
    vm.discard.refs %ref_3 : !vm.ref<!hal.buffer>
    vm.fail %0, "failed to wait on timepoint"
  }
  vm.export @rowsum attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @rowsum(%input0: tensor<8x100xf32>) -> (%output0: tensor<8xf32>)"}}
  vm.export @__init
  vm.func private @__init() attributes {vm.unwind} {
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
    vm.discard.refs %4 : !vm.ref<!hal.device>
    %7 = vm.trunc.i64.i32 %2 : i64 -> i32
    %ref = vm.call @hal.devices.get(%7) {nosideeffects} : (i32) -> !vm.ref<!hal.device>
    %_utf8_hal_device_id_C6650FF277232B5A = vm.const.ref.rodata @_utf8_hal_device_id_C6650FF277232B5A : !vm.buffer
    %_utf8_vulkan_21E229659EF17384 = vm.const.ref.rodata @_utf8_vulkan_21E229659EF17384 : !vm.buffer
    %8:2 = vm.call @hal.device.query.i64(%ref, %_utf8_hal_device_id_C6650FF277232B5A, %_utf8_vulkan_21E229659EF17384) {nosideeffects} : (!vm.ref<!hal.device>, !vm.buffer, !vm.buffer) -> (i32, i64)
    %nz = vm.cmp.nz.i64 %8#1 : i64
    %9 = vm.select.i32 %8#0, %nz, %zero : i32
    vm.cond_br %9, ^bb3, ^bb4(%zero : i32)
  ^bb3:  // pred: ^bb2
    %_utf8_hal_executable_format_E03EECB63A2AAF52 = vm.const.ref.rodata @_utf8_hal_executable_format_E03EECB63A2AAF52 : !vm.buffer
    %_utf8_vulkan_spirv_fb_F1746836E71F8C73 = vm.const.ref.rodata @_utf8_vulkan_spirv_fb_F1746836E71F8C73 : !vm.buffer
    %10:2 = vm.call @hal.device.query.i64(%ref, %_utf8_hal_executable_format_E03EECB63A2AAF52, %_utf8_vulkan_spirv_fb_F1746836E71F8C73) {nosideeffects} : (!vm.ref<!hal.device>, !vm.buffer, !vm.buffer) -> (i32, i64)
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
    vm.discard.refs %null_2 : !vm.ref<!hal.device>
    vm.cond_br %5, ^bb6, ^bb7
  ^bb6:  // pred: ^bb5
    vm.discard.refs %null, %4 : !vm.buffer, !vm.ref<!hal.device>
    vm.fail %c18, "HAL device `__device_0` not found or unavailable: #hal.device.target<\22vulkan\22, [#hal.executable.target<\22vulkan-spirv\22, \22vulkan-spirv-fb\22, {iree_codegen.target_info = #iree_gpu.target<arch = \22rdna3\22, features = \22spirv:v1.6,cap:Shader\22, wgp = <compute = fp64|fp32|fp16|int64|int32|int16|int8, storage = b64|b32|b16|b8, subgroup = shuffle|arithmetic, dot = dp4xi8toi32, mma = [<WMMAR3_F32_16x16x16_F16>, <WMMAR3_F16_16x16x16_F16>, <WMMAR3_F32_16x16x16_BF16>, <WMMAR3_BF16_16x16x16_BF16>, <WMMAR3_I32_16x16x16_I8>], subgroup_size_choices = [32, 64], max_workgroup_sizes = [1024, 1024, 1024], max_thread_count_per_workgroup = 1024, max_workgroup_memory_bytes = 65536, max_workgroup_counts = [2147483647, 2147483647, 2147483647], max_load_instruction_bits = 128, simds_per_wgp = 4, vgpr_space_bits = 8192, workgroup_memory_bank_count = 64>>}>]>"
  ^bb7:  // pred: ^bb5
    %_utf8_hal_executable_format_E03EECB63A2AAF52_5 = vm.const.ref.rodata @_utf8_hal_executable_format_E03EECB63A2AAF52 : !vm.buffer
    %_utf8_vulkan_spirv_fb_F1746836E71F8C73_6 = vm.const.ref.rodata @_utf8_vulkan_spirv_fb_F1746836E71F8C73 : !vm.buffer
    %17:2 = vm.call @hal.device.query.i64(%4, %_utf8_hal_executable_format_E03EECB63A2AAF52_5, %_utf8_vulkan_spirv_fb_F1746836E71F8C73_6) {nosideeffects} : (!vm.ref<!hal.device>, !vm.buffer, !vm.buffer) -> (i32, i64)
    %nz_7 = vm.cmp.nz.i64 %17#1 : i64
    %18 = vm.select.i32 %17#0, %nz_7, %zero : i32
    %19 = vm.select.i64 %18, %zero_0, %c-1 : i64
    %eq_8 = vm.cmp.eq.i64 %19, %zero_0 : i64
    vm.global.store.ref %4, @__device_0 : !vm.ref<!hal.device>
    vm.cond_br %eq_8, ^bb8, ^bb9
  ^bb8:  // pred: ^bb7
    %rowsum_dispatch_0_vulkan_spirv_fb = vm.const.ref.rodata @rowsum_dispatch_0_vulkan_spirv_fb : !vm.buffer
    %ref_9 = vm.call @hal.executable.create(%4, %c-1, %_utf8_vulkan_spirv_fb_F1746836E71F8C73_6, %rowsum_dispatch_0_vulkan_spirv_fb, %null) {nosideeffects} : (!vm.ref<!hal.device>, i64, !vm.buffer, !vm.buffer, !vm.buffer) -> !vm.ref<!hal.executable>
    vm.global.store.ref %ref_9, @__device_0_executable_0_rowsum_dispatch_0 : !vm.ref<!hal.executable>
    %ref_10 = vm.call @__rowsum_memoize_apply() : () -> !vm.ref<!hal.command_buffer>
    vm.global.store.ref %ref_10, @__rowsum_memoize_result_0_device_0 : !vm.ref<!hal.command_buffer>
    vm.return
  ^bb9:  // pred: ^bb7
    vm.discard.refs %null, %4, %_utf8_vulkan_spirv_fb_F1746836E71F8C73_6 : !vm.buffer, !vm.ref<!hal.device>, !vm.buffer
    vm.fail %c14, "HAL device `__device_0` does not support any variant of executable `rowsum_dispatch_0`; available formats: [vulkan-spirv-fb]"
  }
}

