// -----// IR Dump After FoldGlobalsPass: iree-util-fold-globals //----- //
module attributes {iree.fixedpoint.iteration = 2 : index} {
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
    %ok, %value = hal.device.query<%device_n : !hal.device> key("hal.device.id" :: "local*") : i1, i1 = false
    cf.cond_br %value, ^bb3, ^bb4(%false : i1)
  ^bb3:  // pred: ^bb2
    %ok_0, %value_1 = hal.device.query<%device_n : !hal.device> key("hal.executable.format" :: "embedded-elf-arm_64") : i1, i1 = false
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
    util.status.check_ok %c18_i32, "HAL device `__device_0` not found or unavailable: #hal.device.target<\22local\22, [#hal.executable.target<\22llvm-cpu\22, \22embedded-elf-arm_64\22, {cpu = \22generic\22, cpu_features = \22+reserve-x18\22, data_layout = \22e-m:e-p270:32:32-p271:32:32-p272:64:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-Fn32\22, iree.encoding.resolver = #iree_cpu.cpu_encoding_resolver<>, max_stack_allocation_size = 32768 : i64, native_vector_size = 16 : i64, target_triple = \22arm64-unknown-unknown-eabi-elf\22}>]>"
    cf.br ^bb7
  ^bb7:  // 2 preds: ^bb5, ^bb6
    util.global.store %3, @__device_0 : !hal.device
    util.return
  }
  util.global private @__device_0_query_0_hal_executable_format_embedded_elf_arm_64 : i1
  util.initializer {
    %__device_0 = util.global.load @__device_0 : !hal.device
    %ok, %value = hal.device.query<%__device_0 : !hal.device> key("hal.executable.format" :: "embedded-elf-arm_64") : i1, i1 = false
    util.global.store %value, @__device_0_query_0_hal_executable_format_embedded_elf_arm_64 : i1
    util.return
  }
  util.global private @__device_0_executable_0_matmul_dispatch_0 : !hal.executable
  util.initializer {
    %0 = util.null : !hal.executable
    %c14_i32 = arith.constant 14 : i32
    %c0 = arith.constant 0 : index
    %c-1 = arith.constant -1 : index
    %c-1_i64 = arith.constant -1 : i64
    %__device_0_query_0_hal_executable_format_embedded_elf_arm_64 = util.global.load @__device_0_query_0_hal_executable_format_embedded_elf_arm_64 : i1
    %__device_0 = util.global.load @__device_0 : !hal.device
    %1 = arith.select %__device_0_query_0_hal_executable_format_embedded_elf_arm_64, %c0, %c-1 : index
    %2 = arith.cmpi eq, %1, %c0 : index
    cf.cond_br %2, ^bb1, ^bb2
  ^bb1:  // pred: ^bb0
    %executable = hal.executable.create device(%__device_0 : !hal.device) affinity(%c-1_i64) target(@matmul_dispatch_0::@embedded_elf_arm_64) : !hal.executable
    cf.br ^bb3(%executable : !hal.executable)
  ^bb2:  // pred: ^bb0
    util.status.check_ok %c14_i32, "HAL device `__device_0` does not support any variant of executable `matmul_dispatch_0`; available formats: [embedded-elf-arm_64]"
    cf.br ^bb3(%0 : !hal.executable)
  ^bb3(%3: !hal.executable):  // 2 preds: ^bb1, ^bb2
    util.global.store %3, @__device_0_executable_0_matmul_dispatch_0 : !hal.executable
    util.return
  }
  hal.executable private @matmul_dispatch_0 {
    hal.executable.binary public @embedded_elf_arm_64 attributes {data = dense_resource<__elided__> : vector<4504xi8>, format = "embedded-elf-arm_64", mime_type = "application/x-elf"}
  }
  util.func private @__matmul_memoize_apply() -> !hal.command_buffer attributes {inlining_policy = #util.inline.never} {
    %c16384 = arith.constant 16384 : index
    %c2 = arith.constant 2 : index
    %c1 = arith.constant 1 : index
    %c0 = arith.constant 0 : index
    %c3 = arith.constant 3 : index
    %c8 = arith.constant 8 : index
    %c-1_i64 = arith.constant -1 : i64
    %__device_0 = util.global.load immutable @__device_0 : !hal.device
    %__device_0_executable_0_matmul_dispatch_0 = util.global.load immutable @__device_0_executable_0_matmul_dispatch_0 : !hal.executable
    %cmd = hal.command_buffer.create device(%__device_0 : !hal.device) mode("None") categories("Transfer|Dispatch") affinity(%c-1_i64) bindings(%c3) : !hal.command_buffer
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
  util.global private @__matmul_memoize_result_0_device_0 : !hal.command_buffer
  util.initializer {
    %0 = util.call @__matmul_memoize_apply() : () -> !hal.command_buffer
    util.global.store %0, @__matmul_memoize_result_0_device_0 : !hal.command_buffer
    util.return
  }
  util.func private @__matmul_memoize_lookup() {
    util.return
  }
  util.func public @matmul(%arg0: !hal.buffer_view, %arg1: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @matmul(%input0: tensor<64x64xf32>, %input1: tensor<64x64xf32>) -> (%output0: tensor<64x64xf32>)"}} {
    %buffer_usage = hal.buffer_usage<"TransferSource|TransferTarget|Transfer|DispatchStorageRead|DispatchStorageWrite|DispatchStorage"> : i32
    %memory_type = hal.memory_type<"DeviceVisible|DeviceLocal"> : i32
    %c64 = arith.constant 64 : index
    %c16384 = arith.constant 16384 : index
    %c0 = arith.constant 0 : index
    %c-1_i64 = arith.constant -1 : i64
    %0 = util.null : !hal.fence
    %c0_i64 = arith.constant 0 : i64
    %c-1_i32 = arith.constant -1 : i32
    %__device_0 = util.global.load immutable @__device_0 : !hal.device
    %__matmul_memoize_result_0_device_0 = util.global.load immutable @__matmul_memoize_result_0_device_0 : !hal.command_buffer
    %element_type_f32 = hal.element_type<f32> : i32
    %dense_row_major = hal.encoding_type<dense_row_major> : i32
    hal.buffer_view.assert<%arg0 : !hal.buffer_view> message("input0") shape([%c64, %c64]) type(%element_type_f32) encoding(%dense_row_major)
    %buffer = hal.buffer_view.buffer<%arg0 : !hal.buffer_view> : !hal.buffer
    %allocator = hal.device.allocator<%__device_0 : !hal.device> : !hal.allocator
    hal.buffer.assert<%buffer : !hal.buffer> message("tensor") allocator(%allocator : !hal.allocator) minimum_length(%c16384) type(DeviceVisible) usage("TransferSource|TransferTarget|Transfer|DispatchStorageRead|DispatchStorageWrite|DispatchStorage")
    hal.buffer_view.assert<%arg1 : !hal.buffer_view> message("input1") shape([%c64, %c64]) type(%element_type_f32) encoding(%dense_row_major)
    %buffer_0 = hal.buffer_view.buffer<%arg1 : !hal.buffer_view> : !hal.buffer
    hal.buffer.assert<%buffer_0 : !hal.buffer> message("tensor") allocator(%allocator : !hal.allocator) minimum_length(%c16384) type(DeviceVisible) usage("TransferSource|TransferTarget|Transfer|DispatchStorageRead|DispatchStorageWrite|DispatchStorage")
    %fence = hal.fence.create device(%__device_0 : !hal.device) flags("None") : !hal.fence
    %transient_buffer = hal.device.queue.alloca<%__device_0 : !hal.device> affinity(%c-1_i64) wait(%0) signal(%fence) pool(%c0_i64) type(%memory_type) usage(%buffer_usage) flags("None") : !hal.buffer{%c16384}
    util.call @__matmul_memoize_lookup() : () -> ()
    %fence_1 = hal.fence.create device(%__device_0 : !hal.device) flags("None") : !hal.fence
    hal.device.queue.execute.indirect<%__device_0 : !hal.device> affinity(%c-1_i64) wait(%fence) signal(%fence_1) commands(%__matmul_memoize_result_0_device_0) bindings([
      (%buffer : !hal.buffer)[%c0, %c16384], 
      (%buffer_0 : !hal.buffer)[%c0, %c16384], 
      (%transient_buffer : !hal.buffer)[%c0, %c16384]
    ]) flags("None")
    %status = hal.fence.await until([%fence_1]) timeout_millis(%c-1_i32) flags("None") : i32
    util.status.check_ok %status, "failed to wait on timepoint"
    %view = hal.buffer_view.create buffer(%transient_buffer : !hal.buffer)[%c0, %c16384] shape([%c64, %c64]) type(%element_type_f32) encoding(%dense_row_major) : !hal.buffer_view
    util.return %view : !hal.buffer_view
  }
}


