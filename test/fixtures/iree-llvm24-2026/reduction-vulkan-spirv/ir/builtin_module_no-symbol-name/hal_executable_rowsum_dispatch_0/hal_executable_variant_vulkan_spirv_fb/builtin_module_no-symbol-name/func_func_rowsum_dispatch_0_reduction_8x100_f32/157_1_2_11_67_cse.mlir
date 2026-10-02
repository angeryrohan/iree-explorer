// -----// IR Dump After CSEPass: cse //----- //
func.func @rowsum_dispatch_0_reduction_8x100_f32() attributes {gpu.known_block_size = array<i32: 32, 1, 1>, hal.executable.target = #hal.executable.target<"vulkan-spirv", "vulkan-spirv-fb", {iree_codegen.target_info = #iree_gpu.target<arch = "rdna3", features = "spirv:v1.6,cap:Shader", wgp = <compute = fp64|fp32|fp16|int64|int32|int16|int8, storage = b64|b32|b16|b8, subgroup = shuffle|arithmetic, dot = dp4xi8toi32, mma = [<WMMAR3_F32_16x16x16_F16>, <WMMAR3_F16_16x16x16_F16>, <WMMAR3_F32_16x16x16_BF16>, <WMMAR3_BF16_16x16x16_BF16>, <WMMAR3_I32_16x16x16_I8>], subgroup_size_choices = [32, 64], max_workgroup_sizes = [1024, 1024, 1024], max_thread_count_per_workgroup = 1024, max_workgroup_memory_bytes = 65536, max_workgroup_counts = [2147483647, 2147483647, 2147483647], max_load_instruction_bits = 128, simds_per_wgp = 4, vgpr_space_bits = 8192, workgroup_memory_bank_count = 64>>}>} {
  %c1_i32 = arith.constant 1 : i32
  %c100_i32 = arith.constant 100 : i32
  %c0_i32 = arith.constant 0 : i32
  %c8_i32 = arith.constant 8 : i32
  %c8 = arith.constant 8 : index
  %cst = arith.constant 0.000000e+00 : f32
  %c0 = arith.constant 0 : index
  %c800 = arith.constant 800 : index
  %0 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(0) alignment(64) offset(%c0) flags("ReadOnly|Indirect") : memref<?xf32, #hal.descriptor_type<storage_buffer>>{%c800}
  %1 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(1) alignment(64) offset(%c0) flags(Indirect) : memref<?xf32, #hal.descriptor_type<storage_buffer>>{%c8}
  %thread_id_x = gpu.thread_id x upper_bound 32
  %2 = arith.index_castui %thread_id_x : index to i32
  %3 = arith.cmpi slt, %2, %c8_i32 : i32
  scf.if %3 {
    memref.store %cst, %1[%thread_id_x] : memref<?xf32, #hal.descriptor_type<storage_buffer>>
    scf.for %arg0 = %c0_i32 to %c100_i32 step %c1_i32  : i32 {
      %4 = arith.muli %2, %c100_i32 overflow<nsw> : i32
      %5 = arith.addi %arg0, %4 : i32
      %6 = arith.index_castui %5 : i32 to index
      %7 = memref.load %0[%6] : memref<?xf32, #hal.descriptor_type<storage_buffer>>
      %8 = memref.load %1[%thread_id_x] : memref<?xf32, #hal.descriptor_type<storage_buffer>>
      %9 = arith.addf %7, %8 : f32
      memref.store %9, %1[%thread_id_x] : memref<?xf32, #hal.descriptor_type<storage_buffer>>
    }
  }
  return
}

