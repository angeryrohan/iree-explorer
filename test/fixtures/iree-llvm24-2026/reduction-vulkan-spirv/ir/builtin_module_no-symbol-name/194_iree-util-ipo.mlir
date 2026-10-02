// -----// IR Dump After IPOPass: iree-util-ipo //----- //
module attributes {iree.fixedpoint.iteration = 2 : index, iree.fixedpoint.modified} {
  util.global private @__device_0 : !hal.device
  util.initializer {
    %c18_i32 = arith.constant 18 : i32
    %false = arith.constant false
    %c0 = arith.constant 0 : index
    %c1 = arith.constant 1 : index
    %0 = util.null : !hal.device
    %device_count = hal.devices.count : index
    cf.br ^bb1(%c0, %c0, %0 : index, index, !hal.device)
  ^bb1(%1: index, %2: index, %3: !hal.device):  // 2 preds: ^bb0, ^bb4
    %4 = util.cmp.eq %3, %0 : !hal.device
    %5 = arith.cmpi slt, %1, %device_count : index
    %6 = arith.andi %4, %5 : i1
    cf.cond_br %6, ^bb2, ^bb5
  ^bb2:  // pred: ^bb1
    %device_n = hal.devices.get %1 : !hal.device
    %ok, %value = hal.device.query<%device_n : !hal.device> key("hal.device.id" :: "vulkan") : i1, i1 = false
    cf.cond_br %value, ^bb3, ^bb4(%false : i1)
  ^bb3:  // pred: ^bb2
    %ok_0, %value_1 = hal.device.query<%device_n : !hal.device> key("hal.executable.format" :: "vulkan-spirv-fb") : i1, i1 = false
    cf.br ^bb4(%value_1 : i1)
  ^bb4(%7: i1):  // 2 preds: ^bb2, ^bb3
    %8 = arith.cmpi eq, %2, %c0 : index
    %9 = arith.select %7, %c1, %c0 : index
    %10 = arith.addi %2, %9 : index
    %11 = arith.andi %7, %8 : i1
    %12 = arith.select %11, %device_n, %0 : !hal.device
    %13 = arith.addi %1, %c1 : index
    cf.br ^bb1(%13, %10, %12 : index, index, !hal.device)
  ^bb5:  // pred: ^bb1
    cf.cond_br %4, ^bb6, ^bb7
  ^bb6:  // pred: ^bb5
    util.status.check_ok %c18_i32, "HAL device `__device_0` not found or unavailable: #hal.device.target<\22vulkan\22, [#hal.executable.target<\22vulkan-spirv\22, \22vulkan-spirv-fb\22, {iree_codegen.target_info = #iree_gpu.target<arch = \22rdna3\22, features = \22spirv:v1.6,cap:Shader\22, wgp = <compute = fp64|fp32|fp16|int64|int32|int16|int8, storage = b64|b32|b16|b8, subgroup = shuffle|arithmetic, dot = dp4xi8toi32, mma = [<WMMAR3_F32_16x16x16_F16>, <WMMAR3_F16_16x16x16_F16>, <WMMAR3_F32_16x16x16_BF16>, <WMMAR3_BF16_16x16x16_BF16>, <WMMAR3_I32_16x16x16_I8>], subgroup_size_choices = [32, 64], max_workgroup_sizes = [1024, 1024, 1024], max_thread_count_per_workgroup = 1024, max_workgroup_memory_bytes = 65536, max_workgroup_counts = [2147483647, 2147483647, 2147483647], max_load_instruction_bits = 128, simds_per_wgp = 4, vgpr_space_bits = 8192, workgroup_memory_bank_count = 64>>}>]>"
    cf.br ^bb7
  ^bb7:  // 2 preds: ^bb5, ^bb6
    util.global.store %3, @__device_0 : !hal.device
    util.return
  }
  util.global private @__device_0_query_0_hal_executable_format_vulkan_spirv_fb : i1
  util.initializer {
    %__device_0 = util.global.load @__device_0 : !hal.device
    %ok, %value = hal.device.query<%__device_0 : !hal.device> key("hal.executable.format" :: "vulkan-spirv-fb") : i1, i1 = false
    util.global.store %value, @__device_0_query_0_hal_executable_format_vulkan_spirv_fb : i1
    util.return
  }
  util.global private @__device_0_executable_0_rowsum_dispatch_0 : !hal.executable
  util.initializer {
    %0 = util.null : !hal.executable
    %c14_i32 = arith.constant 14 : i32
    %c0 = arith.constant 0 : index
    %c-1 = arith.constant -1 : index
    %c-1_i64 = arith.constant -1 : i64
    %__device_0_query_0_hal_executable_format_vulkan_spirv_fb = util.global.load @__device_0_query_0_hal_executable_format_vulkan_spirv_fb : i1
    %__device_0 = util.global.load @__device_0 : !hal.device
    %1 = arith.select %__device_0_query_0_hal_executable_format_vulkan_spirv_fb, %c0, %c-1 : index
    %2 = arith.cmpi eq, %1, %c0 : index
    cf.cond_br %2, ^bb1, ^bb2
  ^bb1:  // pred: ^bb0
    %executable = hal.executable.create device(%__device_0 : !hal.device) affinity(%c-1_i64) target(@rowsum_dispatch_0::@vulkan_spirv_fb) : !hal.executable
    cf.br ^bb3(%executable : !hal.executable)
  ^bb2:  // pred: ^bb0
    util.status.check_ok %c14_i32, "HAL device `__device_0` does not support any variant of executable `rowsum_dispatch_0`; available formats: [vulkan-spirv-fb]"
    cf.br ^bb3(%0 : !hal.executable)
  ^bb3(%3: !hal.executable):  // 2 preds: ^bb1, ^bb2
    util.global.store %3, @__device_0_executable_0_rowsum_dispatch_0 : !hal.executable
    util.return
  }
  hal.executable private @rowsum_dispatch_0 {
    hal.executable.binary public @vulkan_spirv_fb attributes {data = dense_resource<__elided__> : vector<1736xi8>, format = "vulkan-spirv-fb", mime_type = "application/x-flatbuffers"}
  }
  util.func private @__rowsum_memoize_apply() -> !hal.command_buffer attributes {inlining_policy = #util.inline.never} {
    %c32 = arith.constant 32 : index
    %c3200 = arith.constant 3200 : index
    %c1 = arith.constant 1 : index
    %c0 = arith.constant 0 : index
    %c2 = arith.constant 2 : index
    %c-1_i64 = arith.constant -1 : i64
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
  util.global private @__rowsum_memoize_result_0_device_0 : !hal.command_buffer
  util.initializer {
    %0 = util.call @__rowsum_memoize_apply() : () -> !hal.command_buffer
    util.global.store %0, @__rowsum_memoize_result_0_device_0 : !hal.command_buffer
    util.return
  }
  util.func public @rowsum(%arg0: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @rowsum(%input0: tensor<8x100xf32>) -> (%output0: tensor<8xf32>)"}} {
    %buffer_usage = hal.buffer_usage<"TransferSource|TransferTarget|Transfer|DispatchStorageRead|DispatchStorageWrite|DispatchStorage"> : i32
    %memory_type = hal.memory_type<"DeviceVisible|DeviceLocal"> : i32
    %c8 = arith.constant 8 : index
    %c100 = arith.constant 100 : index
    %c3200 = arith.constant 3200 : index
    %c32 = arith.constant 32 : index
    %c0 = arith.constant 0 : index
    %c-1_i64 = arith.constant -1 : i64
    %0 = util.null : !hal.fence
    %c0_i64 = arith.constant 0 : i64
    %c-1_i32 = arith.constant -1 : i32
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


