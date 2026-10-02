// -----// IR Dump After SymbolDCEPass: symbol-dce //----- //
module {
  util.global private @__device_0 : !hal.device
  util.global private @__device_0_query_0_hal_executable_format_vulkan_spirv_fb : i1
  util.global private @__device_0_executable_0_rowsum_dispatch_0 : !hal.executable
  util.global private @__rowsum_memoize_result_0_device_0 : !hal.command_buffer
  util.initializer {
    %0 = util.null : !hal.executable
    %c14_i32 = arith.constant 14 : i32
    %c-1 = arith.constant -1 : index
    %c-1_i64 = arith.constant -1 : i64
    %c18_i32 = arith.constant 18 : i32
    %false = arith.constant false
    %c0 = arith.constant 0 : index
    %c1 = arith.constant 1 : index
    %1 = util.null : !hal.device
    %device_count = hal.devices.count : index
    cf.br ^bb1(%c0, %c0, %1 : index, index, !hal.device)
  ^bb1(%2: index, %3: index, %4: !hal.device):  // 2 preds: ^bb0, ^bb4
    %5 = util.cmp.eq %4, %1 : !hal.device
    %6 = arith.cmpi slt, %2, %device_count : index
    %7 = arith.andi %5, %6 : i1
    cf.cond_br %7, ^bb2, ^bb5
  ^bb2:  // pred: ^bb1
    %device_n = hal.devices.get %2 : !hal.device
    %ok, %value = hal.device.query<%device_n : !hal.device> key("hal.device.id" :: "vulkan") : i1, i1 = false
    cf.cond_br %value, ^bb3, ^bb4(%false : i1)
  ^bb3:  // pred: ^bb2
    %ok_0, %value_1 = hal.device.query<%device_n : !hal.device> key("hal.executable.format" :: "vulkan-spirv-fb") : i1, i1 = false
    cf.br ^bb4(%value_1 : i1)
  ^bb4(%8: i1):  // 2 preds: ^bb2, ^bb3
    %9 = arith.cmpi eq, %3, %c0 : index
    %10 = arith.select %8, %c1, %c0 : index
    %11 = arith.addi %3, %10 : index
    %12 = arith.andi %8, %9 : i1
    %13 = arith.select %12, %device_n, %1 : !hal.device
    %14 = arith.addi %2, %c1 : index
    cf.br ^bb1(%14, %11, %13 : index, index, !hal.device)
  ^bb5:  // pred: ^bb1
    cf.cond_br %5, ^bb6, ^bb7
  ^bb6:  // pred: ^bb5
    util.status.check_ok %c18_i32, "HAL device `__device_0` not found or unavailable: #hal.device.target<\22vulkan\22, [#hal.executable.target<\22vulkan-spirv\22, \22vulkan-spirv-fb\22, {iree_codegen.target_info = #iree_gpu.target<arch = \22rdna3\22, features = \22spirv:v1.6,cap:Shader\22, wgp = <compute = fp64|fp32|fp16|int64|int32|int16|int8, storage = b64|b32|b16|b8, subgroup = shuffle|arithmetic, dot = dp4xi8toi32, mma = [<WMMAR3_F32_16x16x16_F16>, <WMMAR3_F16_16x16x16_F16>, <WMMAR3_F32_16x16x16_BF16>, <WMMAR3_BF16_16x16x16_BF16>, <WMMAR3_I32_16x16x16_I8>], subgroup_size_choices = [32, 64], max_workgroup_sizes = [1024, 1024, 1024], max_thread_count_per_workgroup = 1024, max_workgroup_memory_bytes = 65536, max_workgroup_counts = [2147483647, 2147483647, 2147483647], max_load_instruction_bits = 128, simds_per_wgp = 4, vgpr_space_bits = 8192, workgroup_memory_bank_count = 64>>}>]>"
    cf.br ^bb7
  ^bb7:  // 2 preds: ^bb5, ^bb6
    util.global.store %4, @__device_0 : !hal.device
    %__device_0 = util.global.load @__device_0 : !hal.device
    %ok_2, %value_3 = hal.device.query<%__device_0 : !hal.device> key("hal.executable.format" :: "vulkan-spirv-fb") : i1, i1 = false
    util.global.store %value_3, @__device_0_query_0_hal_executable_format_vulkan_spirv_fb : i1
    %__device_0_query_0_hal_executable_format_vulkan_spirv_fb = util.global.load @__device_0_query_0_hal_executable_format_vulkan_spirv_fb : i1
    %__device_0_4 = util.global.load @__device_0 : !hal.device
    %15 = arith.select %__device_0_query_0_hal_executable_format_vulkan_spirv_fb, %c0, %c-1 : index
    %16 = arith.cmpi eq, %15, %c0 : index
    cf.cond_br %16, ^bb8, ^bb9
  ^bb8:  // pred: ^bb7
    %executable = hal.executable.create device(%__device_0_4 : !hal.device) affinity(%c-1_i64) target(@rowsum_dispatch_0::@vulkan_spirv_fb) : !hal.executable
    cf.br ^bb10(%executable : !hal.executable)
  ^bb9:  // pred: ^bb7
    util.status.check_ok %c14_i32, "HAL device `__device_0` does not support any variant of executable `rowsum_dispatch_0`; available formats: [vulkan-spirv-fb]"
    cf.br ^bb10(%0 : !hal.executable)
  ^bb10(%17: !hal.executable):  // 2 preds: ^bb8, ^bb9
    util.global.store %17, @__device_0_executable_0_rowsum_dispatch_0 : !hal.executable
    %18 = util.call @__rowsum_memoize_apply() : () -> !hal.command_buffer
    util.global.store %18, @__rowsum_memoize_result_0_device_0 : !hal.command_buffer
    util.return
  }
  hal.executable private @rowsum_dispatch_0 {
    hal.executable.binary public @vulkan_spirv_fb attributes {data = dense_resource<__elided__> : vector<1736xi8>, format = "vulkan-spirv-fb", mime_type = "application/x-flatbuffers"}
  }
  util.func private @__rowsum_memoize_apply() -> !hal.command_buffer attributes {inlining_policy = #util.inline.never} {
    %c-1_i64 = arith.constant -1 : i64
    %c2 = arith.constant 2 : index
    %c0 = arith.constant 0 : index
    %c1 = arith.constant 1 : index
    %c3200 = arith.constant 3200 : index
    %c32 = arith.constant 32 : index
    %__device_0 = util.global.load immutable @__device_0 : !hal.device
    %__device_0_executable_0_rowsum_dispatch_0 = util.global.load immutable @__device_0_executable_0_rowsum_dispatch_0 : !hal.executable
    %cmd = hal.command_buffer.create device(%__device_0 : !hal.device) mode("None") categories("Transfer|Dispatch") affinity(%c-1_i64) bindings(%c2) : !hal.command_buffer
    %function_id = hal.executable.lookup.function target(%__device_0_executable_0_rowsum_dispatch_0 : !hal.executable) function(@rowsum_dispatch_0::@vulkan_spirv_fb::@rowsum_dispatch_0_reduction_8x100_f32) : i64
    hal.command_buffer.dispatch<%cmd : !hal.command_buffer> target(%__device_0_executable_0_rowsum_dispatch_0 : !hal.executable)[%function_id] workgroups([%c1, %c1, %c1]) bindings([
      (%c0 : index)[%c0, %c3200], 
      (%c1 : index)[%c0, %c32]
    ]) flags("None")
    hal.command_buffer.execution_barrier<%cmd : !hal.command_buffer> source("Dispatch|Transfer|CommandRetire") target("CommandIssue|Dispatch|Transfer") flags("None")
    hal.command_buffer.finalize<%cmd : !hal.command_buffer>
    util.return %cmd : !hal.command_buffer
  }
  util.func public @rowsum(%arg0: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @rowsum(%input0: tensor<8x100xf32>) -> (%output0: tensor<8xf32>)"}} {
    %c-1_i32 = arith.constant -1 : i32
    %c0_i64 = arith.constant 0 : i64
    %0 = util.null : !hal.fence
    %c-1_i64 = arith.constant -1 : i64
    %c0 = arith.constant 0 : index
    %c32 = arith.constant 32 : index
    %c3200 = arith.constant 3200 : index
    %c100 = arith.constant 100 : index
    %c8 = arith.constant 8 : index
    %memory_type = hal.memory_type<"DeviceVisible|DeviceLocal"> : i32
    %buffer_usage = hal.buffer_usage<"TransferSource|TransferTarget|Transfer|DispatchStorageRead|DispatchStorageWrite|DispatchStorage"> : i32
    %__device_0 = util.global.load immutable @__device_0 : !hal.device
    %__rowsum_memoize_result_0_device_0 = util.global.load immutable @__rowsum_memoize_result_0_device_0 : !hal.command_buffer
    %element_type_f32 = hal.element_type<f32> : i32
    %dense_row_major = hal.encoding_type<dense_row_major> : i32
    hal.buffer_view.assert<%arg0 : !hal.buffer_view> message("input0") shape([%c8, %c100]) type(%element_type_f32) encoding(%dense_row_major)
    %buffer = hal.buffer_view.buffer<%arg0 : !hal.buffer_view> : !hal.buffer
    %allocator = hal.device.allocator<%__device_0 : !hal.device> : !hal.allocator
    hal.buffer.assert<%buffer : !hal.buffer> message("tensor") allocator(%allocator : !hal.allocator) minimum_length(%c3200) type(DeviceVisible) usage("TransferSource|TransferTarget|Transfer|DispatchStorageRead|DispatchStorageWrite|DispatchStorage")
    %fence = hal.fence.create device(%__device_0 : !hal.device) flags("None") : !hal.fence
    %transient_buffer = hal.device.queue.alloca<%__device_0 : !hal.device> affinity(%c-1_i64) wait(%0) signal(%fence) pool(%c0_i64) type(%memory_type) usage(%buffer_usage) flags("None") : !hal.buffer{%c32}
    %fence_0 = hal.fence.create device(%__device_0 : !hal.device) flags("None") : !hal.fence
    hal.device.queue.execute.indirect<%__device_0 : !hal.device> affinity(%c-1_i64) wait(%fence) signal(%fence_0) commands(%__rowsum_memoize_result_0_device_0) bindings([
      (%buffer : !hal.buffer)[%c0, %c3200], 
      (%transient_buffer : !hal.buffer)[%c0, %c32]
    ]) flags("None")
    %status = hal.fence.await until([%fence_0]) timeout_millis(%c-1_i32) flags("None") : i32
    util.status.check_ok %status, "failed to wait on timepoint"
    %view = hal.buffer_view.create buffer(%transient_buffer : !hal.buffer)[%c0, %c32] shape([%c8]) type(%element_type_f32) encoding(%dense_row_major) : !hal.buffer_view
    util.return %view : !hal.buffer_view
  }
}


