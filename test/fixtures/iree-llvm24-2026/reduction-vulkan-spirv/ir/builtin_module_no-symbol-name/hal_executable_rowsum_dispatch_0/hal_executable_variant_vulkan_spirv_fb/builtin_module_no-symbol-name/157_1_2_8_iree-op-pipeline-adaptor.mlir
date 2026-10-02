// -----// IR Dump After mlir::iree_compiler::detail::OpPipelineAdaptorPass: iree-op-pipeline-adaptor //----- //
module attributes {hal.executable.target = #hal.executable.target<"vulkan-spirv", "vulkan-spirv-fb", {iree_codegen.target_info = #iree_gpu.target<arch = "rdna3", features = "spirv:v1.6,cap:Shader", wgp = <compute = fp64|fp32|fp16|int64|int32|int16|int8, storage = b64|b32|b16|b8, subgroup = shuffle|arithmetic, dot = dp4xi8toi32, mma = [<WMMAR3_F32_16x16x16_F16>, <WMMAR3_F16_16x16x16_F16>, <WMMAR3_F32_16x16x16_BF16>, <WMMAR3_BF16_16x16x16_BF16>, <WMMAR3_I32_16x16x16_I8>], subgroup_size_choices = [32, 64], max_workgroup_sizes = [1024, 1024, 1024], max_thread_count_per_workgroup = 1024, max_workgroup_memory_bytes = 65536, max_workgroup_counts = [2147483647, 2147483647, 2147483647], max_load_instruction_bits = 128, simds_per_wgp = 4, vgpr_space_bits = 8192, workgroup_memory_bank_count = 64>>}>} {
  func.func @rowsum_dispatch_0_reduction_8x100_f32() attributes {gpu.known_block_size = array<i32: 32, 1, 1>, hal.executable.target = #hal.executable.target<"vulkan-spirv", "vulkan-spirv-fb", {iree_codegen.target_info = #iree_gpu.target<arch = "rdna3", features = "spirv:v1.6,cap:Shader", wgp = <compute = fp64|fp32|fp16|int64|int32|int16|int8, storage = b64|b32|b16|b8, subgroup = shuffle|arithmetic, dot = dp4xi8toi32, mma = [<WMMAR3_F32_16x16x16_F16>, <WMMAR3_F16_16x16x16_F16>, <WMMAR3_F32_16x16x16_BF16>, <WMMAR3_BF16_16x16x16_BF16>, <WMMAR3_I32_16x16x16_I8>], subgroup_size_choices = [32, 64], max_workgroup_sizes = [1024, 1024, 1024], max_thread_count_per_workgroup = 1024, max_workgroup_memory_bytes = 65536, max_workgroup_counts = [2147483647, 2147483647, 2147483647], max_load_instruction_bits = 128, simds_per_wgp = 4, vgpr_space_bits = 8192, workgroup_memory_bank_count = 64>>}>, translation_info = #iree_codegen.translation_info<pipeline = #iree_gpu.spirv_pipeline<BaseDistribute> workgroup_size = [32, 1, 1]>} {
    %c100 = arith.constant 100 : index
    %c1 = arith.constant 1 : index
    %c8 = arith.constant 8 : index
    %cst = arith.constant 0.000000e+00 : f32
    %c0 = arith.constant 0 : index
    %c800 = arith.constant 800 : index
    %0 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(0) alignment(64) offset(%c0) flags("ReadOnly|Indirect") : memref<?xf32, #hal.descriptor_type<storage_buffer>>{%c800}
    %1 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(1) alignment(64) offset(%c0) flags(Indirect) : memref<?xf32, #hal.descriptor_type<storage_buffer>>{%c8}
    %thread_id_x = gpu.thread_id x upper_bound 32
    %2 = arith.cmpi slt, %thread_id_x, %c8 : index
    scf.forall (%arg0) = (0) to (8) step (32) {
      scf.if %2 {
        memref.store %cst, %1[%thread_id_x] : memref<?xf32, #hal.descriptor_type<storage_buffer>>
        scf.for %arg1 = %c0 to %c100 step %c1 {
          %3 = affine.apply affine_map<(d0)[s0] -> (d0 + s0 * 100)>(%arg1)[%thread_id_x]
          %4 = memref.load %0[%3] : memref<?xf32, #hal.descriptor_type<storage_buffer>>
          %5 = memref.load %1[%thread_id_x] : memref<?xf32, #hal.descriptor_type<storage_buffer>>
          %6 = arith.addf %4, %5 : f32
          memref.store %6, %1[%thread_id_x] : memref<?xf32, #hal.descriptor_type<storage_buffer>>
        }
      }
    } {mapping = [#iree_codegen.workgroup_mapping<x>]}
    return
  }
  iree_codegen.dispatch_config @rowsum_dispatch_0_reduction_8x100_f32 {
  ^bb0(%arg0: !hal.device):
    %x, %y, %z = iree_tensor_ext.dispatch.workgroup_count_from_slice()
    iree_codegen.yield %x, %y, %z : index, index, index
  }
}

