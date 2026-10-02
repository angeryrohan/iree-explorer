// -----// IR Dump After CanonicalizerPass: canonicalize{cse-between-iterations=false    max-iterations=10 max-num-rewrites=-1 region-simplify=normal test-convergence=false top-down=true} //----- //
hal.executable private @rowsum_dispatch_0 {
  hal.executable.variant public @vulkan_spirv_fb target(<"vulkan-spirv", "vulkan-spirv-fb", {iree_codegen.target_info = #iree_gpu.target<arch = "rdna3", features = "spirv:v1.6,cap:Shader", wgp = <compute = fp64|fp32|fp16|int64|int32|int16|int8, storage = b64|b32|b16|b8, subgroup = shuffle|arithmetic, dot = dp4xi8toi32, mma = [<WMMAR3_F32_16x16x16_F16>, <WMMAR3_F16_16x16x16_F16>, <WMMAR3_F32_16x16x16_BF16>, <WMMAR3_BF16_16x16x16_BF16>, <WMMAR3_I32_16x16x16_I8>], subgroup_size_choices = [32, 64], max_workgroup_sizes = [1024, 1024, 1024], max_thread_count_per_workgroup = 1024, max_workgroup_memory_bytes = 65536, max_workgroup_counts = [2147483647, 2147483647, 2147483647], max_load_instruction_bits = 128, simds_per_wgp = 4, vgpr_space_bits = 8192, workgroup_memory_bank_count = 64>>}>) {
    hal.executable.export public @rowsum_dispatch_0_reduction_8x100_f32 ordinal(0) layout(#hal.pipeline.layout<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) attributes {workgroup_size = [32 : index, 1 : index, 1 : index]}
    builtin.module attributes {hal.executable.target = #hal.executable.target<"vulkan-spirv", "vulkan-spirv-fb", {iree_codegen.target_info = #iree_gpu.target<arch = "rdna3", features = "spirv:v1.6,cap:Shader", wgp = <compute = fp64|fp32|fp16|int64|int32|int16|int8, storage = b64|b32|b16|b8, subgroup = shuffle|arithmetic, dot = dp4xi8toi32, mma = [<WMMAR3_F32_16x16x16_F16>, <WMMAR3_F16_16x16x16_F16>, <WMMAR3_F32_16x16x16_BF16>, <WMMAR3_BF16_16x16x16_BF16>, <WMMAR3_I32_16x16x16_I8>], subgroup_size_choices = [32, 64], max_workgroup_sizes = [1024, 1024, 1024], max_thread_count_per_workgroup = 1024, max_workgroup_memory_bytes = 65536, max_workgroup_counts = [2147483647, 2147483647, 2147483647], max_load_instruction_bits = 128, simds_per_wgp = 4, vgpr_space_bits = 8192, workgroup_memory_bank_count = 64>>}>, spirv.target_env = #spirv.target_env<#spirv.vce<v1.6, [Shader, Float64, Float16, Int64, Int16, Int8, StorageBuffer16BitAccess, StorageUniform16, StoragePushConstant16, StorageBuffer8BitAccess, UniformAndStorageBuffer8BitAccess, StoragePushConstant8, GroupNonUniformShuffle, GroupNonUniformShuffleRelative, GroupNonUniformArithmetic, DotProduct, DotProductInput4x8BitPacked, DotProductInputAll, DotProductInput4x8Bit, CooperativeMatrixKHR], [SPV_KHR_16bit_storage, SPV_KHR_8bit_storage, SPV_KHR_integer_dot_product, SPV_KHR_cooperative_matrix]>, AMD, #spirv.resource_limits<max_compute_shared_memory_size = 65536, max_compute_workgroup_invocations = 1024, max_compute_workgroup_size = [1024 : i32, 1024 : i32, 1024 : i32], min_subgroup_size = 32, max_subgroup_size = 64, cooperative_matrix_properties_khr = [#spirv.coop_matrix_props_khr<m_size = 16, n_size = 16, k_size = 16, a_type = f16, b_type = f16, c_type = f32, result_type = f32, acc_sat = false, scope = <Subgroup>>, #spirv.coop_matrix_props_khr<m_size = 16, n_size = 16, k_size = 16, a_type = f16, b_type = f16, c_type = f16, result_type = f16, acc_sat = false, scope = <Subgroup>>, #spirv.coop_matrix_props_khr<m_size = 16, n_size = 16, k_size = 16, a_type = i8, b_type = i8, c_type = i32, result_type = i32, acc_sat = false, scope = <Subgroup>>]>>} {
      spirv.module Logical GLSL450 requires #spirv.vce<v1.0, [Shader, Matrix], [SPV_KHR_storage_buffer_storage_class]> {
        spirv.GlobalVariable @__builtin__LocalInvocationId__ built_in("LocalInvocationId") : !spirv.ptr<vector<3xi32>, Input>
        spirv.GlobalVariable @__resource_var_0_0_ bind(0, 0) : !spirv.ptr<!spirv.struct<(!spirv.rtarray<f32, stride=4> [0])>, StorageBuffer>
        spirv.GlobalVariable @__resource_var_0_1_ bind(0, 1) : !spirv.ptr<!spirv.struct<(!spirv.rtarray<f32, stride=4> [0])>, StorageBuffer>
        spirv.func @rowsum_dispatch_0_reduction_8x100_f32() "None" attributes {gpu.known_block_size = array<i32: 32, 1, 1>, hal.executable.target = #hal.executable.target<"vulkan-spirv", "vulkan-spirv-fb", {iree_codegen.target_info = #iree_gpu.target<arch = "rdna3", features = "spirv:v1.6,cap:Shader", wgp = <compute = fp64|fp32|fp16|int64|int32|int16|int8, storage = b64|b32|b16|b8, subgroup = shuffle|arithmetic, dot = dp4xi8toi32, mma = [<WMMAR3_F32_16x16x16_F16>, <WMMAR3_F16_16x16x16_F16>, <WMMAR3_F32_16x16x16_BF16>, <WMMAR3_BF16_16x16x16_BF16>, <WMMAR3_I32_16x16x16_I8>], subgroup_size_choices = [32, 64], max_workgroup_sizes = [1024, 1024, 1024], max_thread_count_per_workgroup = 1024, max_workgroup_memory_bytes = 65536, max_workgroup_counts = [2147483647, 2147483647, 2147483647], max_load_instruction_bits = 128, simds_per_wgp = 4, vgpr_space_bits = 8192, workgroup_memory_bank_count = 64>>}>} {
          %cst1_i32 = spirv.Constant 1 : i32
          %cst100_i32 = spirv.Constant 100 : i32
          %cst0_i32 = spirv.Constant 0 : i32
          %cst8_i32 = spirv.Constant 8 : i32
          %cst_f32 = spirv.Constant 0.000000e+00 : f32
          %__resource_var_0_0__addr = spirv.mlir.addressof @__resource_var_0_0_ : !spirv.ptr<!spirv.struct<(!spirv.rtarray<f32, stride=4> [0])>, StorageBuffer>
          %__resource_var_0_1__addr = spirv.mlir.addressof @__resource_var_0_1_ : !spirv.ptr<!spirv.struct<(!spirv.rtarray<f32, stride=4> [0])>, StorageBuffer>
          %__builtin__LocalInvocationId___addr = spirv.mlir.addressof @__builtin__LocalInvocationId__ : !spirv.ptr<vector<3xi32>, Input>
          %0 = spirv.Load "Input" %__builtin__LocalInvocationId___addr : vector<3xi32>
          %1 = spirv.CompositeExtract %0[0 : i32] : vector<3xi32>
          %2 = spirv.SLessThan %1, %cst8_i32 : i32
          spirv.mlir.selection {
            spirv.BranchConditional %2, ^bb1, ^bb2
          ^bb1:  // pred: ^bb0
            %3 = spirv.AccessChain %__resource_var_0_1__addr[%cst0_i32, %1] : !spirv.ptr<!spirv.struct<(!spirv.rtarray<f32, stride=4> [0])>, StorageBuffer>, i32, i32 -> !spirv.ptr<f32, StorageBuffer>
            spirv.Store "StorageBuffer" %3, %cst_f32 : f32
            spirv.mlir.loop {
              spirv.Branch ^bb1(%cst0_i32 : i32)
            ^bb1(%4: i32):  // 2 preds: ^bb0, ^bb2
              %5 = spirv.SLessThan %4, %cst100_i32 : i32
              spirv.BranchConditional %5, ^bb2, ^bb3
            ^bb2:  // pred: ^bb1
              %6 = spirv.IMul %1, %cst100_i32 {no_signed_wrap} : i32
              %7 = spirv.IAdd %4, %6 : i32
              %8 = spirv.AccessChain %__resource_var_0_0__addr[%cst0_i32, %7] : !spirv.ptr<!spirv.struct<(!spirv.rtarray<f32, stride=4> [0])>, StorageBuffer>, i32, i32 -> !spirv.ptr<f32, StorageBuffer>
              %9 = spirv.Load "StorageBuffer" %8 : f32
              %10 = spirv.Load "StorageBuffer" %3 : f32
              %11 = spirv.FAdd %9, %10 : f32
              spirv.Store "StorageBuffer" %3, %11 : f32
              %12 = spirv.IAdd %4, %cst1_i32 : i32
              spirv.Branch ^bb1(%12 : i32)
            ^bb3:  // pred: ^bb1
              spirv.mlir.merge
            }
            spirv.Branch ^bb2
          ^bb2:  // 2 preds: ^bb0, ^bb1
            spirv.mlir.merge
          }
          spirv.Return
        }
        spirv.EntryPoint "GLCompute" @rowsum_dispatch_0_reduction_8x100_f32, @__resource_var_0_0_, @__resource_var_0_1_, @__builtin__LocalInvocationId__
        spirv.ExecutionMode @rowsum_dispatch_0_reduction_8x100_f32 "LocalSize", 32, 1, 1
      }
    }
  }
}

