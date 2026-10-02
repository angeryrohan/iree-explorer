// -----// IR Dump After SCFForLoopCanonicalization: scf-for-loop-canonicalization //----- //
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
  %ok, %value = hal.device.query<%device_n : !hal.device> key("hal.device.id" :: "local*") : i1, i1 = false
  cf.cond_br %value, ^bb3, ^bb4(%false : i1)
^bb3:  // pred: ^bb2
  %ok_0, %value_1 = hal.device.query<%device_n : !hal.device> key("hal.executable.format" :: "embedded-elf-arm_64") : i1, i1 = false
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
  util.status.check_ok %c18_i32, "HAL device `__device_0` not found or unavailable: #hal.device.target<\22local\22, [#hal.executable.target<\22llvm-cpu\22, \22embedded-elf-arm_64\22, {cpu = \22generic\22, cpu_features = \22+reserve-x18\22, data_layout = \22e-m:e-p270:32:32-p271:32:32-p272:64:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-Fn32\22, iree.encoding.resolver = #iree_cpu.cpu_encoding_resolver<>, max_stack_allocation_size = 32768 : i64, native_vector_size = 16 : i64, target_triple = \22arm64-unknown-unknown-eabi-elf\22}>]>"
  cf.br ^bb7
^bb7:  // 2 preds: ^bb5, ^bb6
  util.global.store %4, @__device_0 : !hal.device
  cf.br ^bb8
^bb8:  // pred: ^bb7
  %__device_0 = util.global.load @__device_0 : !hal.device
  %ok_2, %value_3 = hal.device.query<%__device_0 : !hal.device> key("hal.executable.format" :: "embedded-elf-arm_64") : i1, i1 = false
  util.global.store %value_3, @__device_0_query_0_hal_executable_format_embedded_elf_arm_64 : i1
  %__device_0_query_0_hal_executable_format_embedded_elf_arm_64 = util.global.load @__device_0_query_0_hal_executable_format_embedded_elf_arm_64 : i1
  %__device_0_4 = util.global.load @__device_0 : !hal.device
  %15 = arith.select %__device_0_query_0_hal_executable_format_embedded_elf_arm_64, %c0, %c-1 : index
  %16 = arith.cmpi eq, %15, %c0 : index
  cf.cond_br %16, ^bb9, ^bb10
^bb9:  // pred: ^bb8
  %executable = hal.executable.create device(%__device_0_4 : !hal.device) affinity(%c-1_i64) target(@matmul_dispatch_0::@embedded_elf_arm_64) : !hal.executable
  cf.br ^bb11(%executable : !hal.executable)
^bb10:  // pred: ^bb8
  util.status.check_ok %c14_i32, "HAL device `__device_0` does not support any variant of executable `matmul_dispatch_0`; available formats: [embedded-elf-arm_64]"
  cf.br ^bb11(%0 : !hal.executable)
^bb11(%17: !hal.executable):  // 2 preds: ^bb9, ^bb10
  util.global.store %17, @__device_0_executable_0_matmul_dispatch_0 : !hal.executable
  cf.br ^bb12
^bb12:  // pred: ^bb11
  %18 = util.call @__matmul_memoize_apply() : () -> !hal.command_buffer
  util.global.store %18, @__matmul_memoize_result_0_device_0 : !hal.command_buffer
  util.return
}

