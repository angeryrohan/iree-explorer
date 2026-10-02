// -----// IR Dump After CanonicalizerPass: canonicalize{cse-between-iterations=false    max-iterations=10 max-num-rewrites=-1 region-simplify=normal test-convergence=false top-down=true} //----- //
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
  vm.cond_br %5, ^bb6, ^bb7
^bb6:  // pred: ^bb5
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
  %_utf8_vulkan_spirv_fb_F1746836E71F8C73_9 = vm.const.ref.rodata @_utf8_vulkan_spirv_fb_F1746836E71F8C73 : !vm.buffer
  %ref_10 = vm.call @hal.executable.create(%4, %c-1, %_utf8_vulkan_spirv_fb_F1746836E71F8C73_9, %rowsum_dispatch_0_vulkan_spirv_fb, %null) {nosideeffects} : (!vm.ref<!hal.device>, i64, !vm.buffer, !vm.buffer, !vm.buffer) -> !vm.ref<!hal.executable>
  vm.global.store.ref %ref_10, @__device_0_executable_0_rowsum_dispatch_0 : !vm.ref<!hal.executable>
  %ref_11 = vm.call @__rowsum_memoize_apply() : () -> !vm.ref<!hal.command_buffer>
  vm.global.store.ref %ref_11, @__rowsum_memoize_result_0_device_0 : !vm.ref<!hal.command_buffer>
  vm.return
^bb9:  // pred: ^bb7
  vm.fail %c14, "HAL device `__device_0` does not support any variant of executable `rowsum_dispatch_0`; available formats: [vulkan-spirv-fb]"
}

