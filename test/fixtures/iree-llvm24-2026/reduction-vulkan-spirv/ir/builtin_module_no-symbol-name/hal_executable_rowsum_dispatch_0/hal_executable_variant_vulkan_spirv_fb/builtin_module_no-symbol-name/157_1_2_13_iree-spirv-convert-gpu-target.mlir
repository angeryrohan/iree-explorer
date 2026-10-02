// -----// IR Dump After SPIRVConvertGPUTargetPass: iree-spirv-convert-gpu-target //----- //
module attributes {hal.executable.target = #hal.executable.target<"vulkan-spirv", "vulkan-spirv-fb", {iree_codegen.target_info = #iree_gpu.target<arch = "rdna3", features = "spirv:v1.6,cap:Shader", wgp = <compute = fp64|fp32|fp16|int64|int32|int16|int8, storage = b64|b32|b16|b8, subgroup = shuffle|arithmetic, dot = dp4xi8toi32, mma = [<WMMAR3_F32_16x16x16_F16>, <WMMAR3_F16_16x16x16_F16>, <WMMAR3_F32_16x16x16_BF16>, <WMMAR3_BF16_16x16x16_BF16>, <WMMAR3_I32_16x16x16_I8>], subgroup_size_choices = [32, 64], max_workgroup_sizes = [1024, 1024, 1024], max_thread_count_per_workgroup = 1024, max_workgroup_memory_bytes = 65536, max_workgroup_counts = [2147483647, 2147483647, 2147483647], max_load_instruction_bits = 128, simds_per_wgp = 4, vgpr_space_bits = 8192, workgroup_memory_bank_count = 64>>}>, spirv.target_env = #spirv.target_env<#spirv.vce<v1.6, [Shader, Float64, Float16, Int64, Int16, Int8, StorageBuffer16BitAccess, StorageUniform16, StoragePushConstant16, StorageBuffer8BitAccess, UniformAndStorageBuffer8BitAccess, StoragePushConstant8, GroupNonUniformShuffle, GroupNonUniformShuffleRelative, GroupNonUniformArithmetic, DotProduct, DotProductInput4x8BitPacked, DotProductInputAll, DotProductInput4x8Bit, CooperativeMatrixKHR], [SPV_KHR_16bit_storage, SPV_KHR_8bit_storage, SPV_KHR_integer_dot_product, SPV_KHR_cooperative_matrix]>, AMD, #spirv.resource_limits<max_compute_shared_memory_size = 65536, max_compute_workgroup_invocations = 1024, max_compute_workgroup_size = [1024 : i32, 1024 : i32, 1024 : i32], min_subgroup_size = 32, max_subgroup_size = 64, cooperative_matrix_properties_khr = [#spirv.coop_matrix_props_khr<m_size = 16, n_size = 16, k_size = 16, a_type = f16, b_type = f16, c_type = f32, result_type = f32, acc_sat = false, scope = <Subgroup>>, #spirv.coop_matrix_props_khr<m_size = 16, n_size = 16, k_size = 16, a_type = f16, b_type = f16, c_type = f16, result_type = f16, acc_sat = false, scope = <Subgroup>>, #spirv.coop_matrix_props_khr<m_size = 16, n_size = 16, k_size = 16, a_type = i8, b_type = i8, c_type = i32, result_type = i32, acc_sat = false, scope = <Subgroup>>]>>} {
  func.func @rowsum_dispatch_0_reduction_8x100_f32() attributes {gpu.known_block_size = array<i32: 32, 1, 1>, hal.executable.target = #hal.executable.target<"vulkan-spirv", "vulkan-spirv-fb", {iree_codegen.target_info = #iree_gpu.target<arch = "rdna3", features = "spirv:v1.6,cap:Shader", wgp = <compute = fp64|fp32|fp16|int64|int32|int16|int8, storage = b64|b32|b16|b8, subgroup = shuffle|arithmetic, dot = dp4xi8toi32, mma = [<WMMAR3_F32_16x16x16_F16>, <WMMAR3_F16_16x16x16_F16>, <WMMAR3_F32_16x16x16_BF16>, <WMMAR3_BF16_16x16x16_BF16>, <WMMAR3_I32_16x16x16_I8>], subgroup_size_choices = [32, 64], max_workgroup_sizes = [1024, 1024, 1024], max_thread_count_per_workgroup = 1024, max_workgroup_memory_bytes = 65536, max_workgroup_counts = [2147483647, 2147483647, 2147483647], max_load_instruction_bits = 128, simds_per_wgp = 4, vgpr_space_bits = 8192, workgroup_memory_bank_count = 64>>}>} {
    %c1_i32 = arith.constant 1 : i32
    %c100_i32 = arith.constant 100 : i32
    %c0_i32 = arith.constant 0 : i32
    %c8_i32 = arith.constant 8 : i32
    %c8 = arith.constant 8 : index
    %cst = arith.constant 0.000000e+00 : f32
    %c0 = arith.constant 0 : index
    %c800 = arith.constant 800 : index
    %0 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(0) alignment(64) offset(%c0) flags("ReadOnly|Indirect") : memref<?xf32, #spirv.storage_class<StorageBuffer>>{%c800}
    %1 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(1) alignment(64) offset(%c0) flags(Indirect) : memref<?xf32, #spirv.storage_class<StorageBuffer>>{%c8}
    %thread_id_x = gpu.thread_id x upper_bound 32
    %2 = arith.index_castui %thread_id_x : index to i32
    %3 = arith.cmpi slt, %2, %c8_i32 : i32
    scf.if %3 {
      memref.store %cst, %1[%thread_id_x] : memref<?xf32, #spirv.storage_class<StorageBuffer>>
      scf.for %arg0 = %c0_i32 to %c100_i32 step %c1_i32  : i32 {
        %4 = arith.muli %2, %c100_i32 overflow<nsw> : i32
        %5 = arith.addi %arg0, %4 : i32
        %6 = arith.index_castui %5 : i32 to index
        %7 = memref.load %0[%6] : memref<?xf32, #spirv.storage_class<StorageBuffer>>
        %8 = memref.load %1[%thread_id_x] : memref<?xf32, #spirv.storage_class<StorageBuffer>>
        %9 = arith.addf %7, %8 : f32
        memref.store %9, %1[%thread_id_x] : memref<?xf32, #spirv.storage_class<StorageBuffer>>
      }
    }
    return
  }
  iree_codegen.dispatch_config @rowsum_dispatch_0_reduction_8x100_f32 workgroup_size = [32, 1, 1] {
  ^bb0(%arg0: !hal.device):
    %c1 = arith.constant 1 : index
    %c1_0 = arith.constant 1 : index
    %c1_1 = arith.constant 1 : index
    iree_codegen.yield %c1, %c1_0, %c1_1 : index, index, index
  }
}

