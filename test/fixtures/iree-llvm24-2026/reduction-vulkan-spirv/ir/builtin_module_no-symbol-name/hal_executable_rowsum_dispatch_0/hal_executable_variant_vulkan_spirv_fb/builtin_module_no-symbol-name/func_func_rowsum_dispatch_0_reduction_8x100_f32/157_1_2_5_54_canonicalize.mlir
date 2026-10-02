// -----// IR Dump After CanonicalizerPass: canonicalize{cse-between-iterations=false    max-iterations=10 max-num-rewrites=-1 region-simplify=normal test-convergence=false top-down=true} //----- //
func.func @rowsum_dispatch_0_reduction_8x100_f32() attributes {gpu.known_block_size = array<i32: 32, 1, 1>, hal.executable.target = #hal.executable.target<"vulkan-spirv", "vulkan-spirv-fb", {iree_codegen.target_info = #iree_gpu.target<arch = "rdna3", features = "spirv:v1.6,cap:Shader", wgp = <compute = fp64|fp32|fp16|int64|int32|int16|int8, storage = b64|b32|b16|b8, subgroup = shuffle|arithmetic, dot = dp4xi8toi32, mma = [<WMMAR3_F32_16x16x16_F16>, <WMMAR3_F16_16x16x16_F16>, <WMMAR3_F32_16x16x16_BF16>, <WMMAR3_BF16_16x16x16_BF16>, <WMMAR3_I32_16x16x16_I8>], subgroup_size_choices = [32, 64], max_workgroup_sizes = [1024, 1024, 1024], max_thread_count_per_workgroup = 1024, max_workgroup_memory_bytes = 65536, max_workgroup_counts = [2147483647, 2147483647, 2147483647], max_load_instruction_bits = 128, simds_per_wgp = 4, vgpr_space_bits = 8192, workgroup_memory_bank_count = 64>>}>, translation_info = #iree_codegen.translation_info<pipeline = #iree_gpu.spirv_pipeline<BaseDistribute> workgroup_size = [32, 1, 1]>} {
  %c100 = arith.constant 100 : index
  %c1 = arith.constant 1 : index
  %c8 = arith.constant 8 : index
  %cst = arith.constant 0.000000e+00 : f32
  %c0 = arith.constant 0 : index
  %0 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(0) alignment(64) offset(%c0) flags("ReadOnly|Indirect") : memref<8x100xf32, #hal.descriptor_type<storage_buffer>>
  %assume_align = memref.assume_alignment %0, 64 : memref<8x100xf32, #hal.descriptor_type<storage_buffer>>
  %1 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(1) alignment(64) offset(%c0) flags(Indirect) : memref<8xf32, #hal.descriptor_type<storage_buffer>>
  %assume_align_0 = memref.assume_alignment %1, 64 : memref<8xf32, #hal.descriptor_type<storage_buffer>>
  %thread_id_x = gpu.thread_id x upper_bound 32
  %2 = arith.cmpi slt, %thread_id_x, %c8 : index
  scf.forall (%arg0) = (0) to (8) step (32) {
    scf.if %2 {
      memref.store %cst, %assume_align_0[%thread_id_x] : memref<8xf32, #hal.descriptor_type<storage_buffer>>
      scf.for %arg1 = %c0 to %c100 step %c1 {
        %3 = memref.load %assume_align[%thread_id_x, %arg1] : memref<8x100xf32, #hal.descriptor_type<storage_buffer>>
        %4 = memref.load %assume_align_0[%thread_id_x] : memref<8xf32, #hal.descriptor_type<storage_buffer>>
        %5 = arith.addf %3, %4 : f32
        memref.store %5, %assume_align_0[%thread_id_x] : memref<8xf32, #hal.descriptor_type<storage_buffer>>
      }
    }
  } {mapping = [#iree_codegen.workgroup_mapping<x>]}
  return
}

