// -----// IR Dump After PropagateDispatchSizeBoundsPass: iree-codegen-propagate-dispatch-size-bounds //----- //
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
  scf.forall (%arg0) = (0) to (8) step (32) {
    %thread_id_x = gpu.thread_id x upper_bound 32
    %c32 = arith.constant 32 : index
    scf.for %arg1 = %thread_id_x to %c8 step %c32 {
      %subview = memref.subview %assume_align_0[%arg1] [1] [1] : memref<8xf32, #hal.descriptor_type<storage_buffer>> to memref<1xf32, strided<[1], offset: ?>, #hal.descriptor_type<storage_buffer>>
      scf.for %arg2 = %c0 to %c1 step %c1 {
        memref.store %cst, %subview[%arg2] : memref<1xf32, strided<[1], offset: ?>, #hal.descriptor_type<storage_buffer>>
      }
    }
    scf.for %arg1 = %thread_id_x to %c8 step %c32 {
      %subview = memref.subview %assume_align[%arg1, 0] [1, 100] [1, 1] : memref<8x100xf32, #hal.descriptor_type<storage_buffer>> to memref<1x100xf32, strided<[100, 1], offset: ?>, #hal.descriptor_type<storage_buffer>>
      %subview_1 = memref.subview %assume_align_0[%arg1] [1] [1] : memref<8xf32, #hal.descriptor_type<storage_buffer>> to memref<1xf32, strided<[1], offset: ?>, #hal.descriptor_type<storage_buffer>>
      scf.for %arg2 = %c0 to %c1 step %c1 {
        scf.for %arg3 = %c0 to %c100 step %c1 {
          %2 = memref.load %subview[%arg2, %arg3] : memref<1x100xf32, strided<[100, 1], offset: ?>, #hal.descriptor_type<storage_buffer>>
          %3 = memref.load %subview_1[%arg2] : memref<1xf32, strided<[1], offset: ?>, #hal.descriptor_type<storage_buffer>>
          %4 = arith.addf %2, %3 : f32
          memref.store %4, %subview_1[%arg2] : memref<1xf32, strided<[1], offset: ?>, #hal.descriptor_type<storage_buffer>>
        }
      }
    }
  } {mapping = [#iree_codegen.workgroup_mapping<x>]}
  return
}

