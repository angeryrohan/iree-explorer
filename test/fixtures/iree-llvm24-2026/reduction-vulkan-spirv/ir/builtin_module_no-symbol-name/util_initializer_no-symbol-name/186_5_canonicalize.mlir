// -----// IR Dump After CanonicalizerPass: canonicalize{cse-between-iterations=false    max-iterations=10 max-num-rewrites=-1 region-simplify=normal test-convergence=false top-down=true} //----- //
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

