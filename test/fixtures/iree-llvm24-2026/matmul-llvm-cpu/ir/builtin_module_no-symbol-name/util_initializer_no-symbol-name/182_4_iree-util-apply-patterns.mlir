// -----// IR Dump After ApplyPatternsPass: iree-util-apply-patterns //----- //
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

