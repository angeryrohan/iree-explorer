// -----// IR Dump After CanonicalizerPass: canonicalize{cse-between-iterations=false    max-iterations=10 max-num-rewrites=-1 region-simplify=normal test-convergence=false top-down=true} //----- //
spirv.module Logical GLSL450 {
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
        %10 = spirv.AccessChain %__resource_var_0_1__addr[%cst0_i32, %1] : !spirv.ptr<!spirv.struct<(!spirv.rtarray<f32, stride=4> [0])>, StorageBuffer>, i32, i32 -> !spirv.ptr<f32, StorageBuffer>
        %11 = spirv.Load "StorageBuffer" %10 : f32
        %12 = spirv.FAdd %9, %11 : f32
        %13 = spirv.AccessChain %__resource_var_0_1__addr[%cst0_i32, %1] : !spirv.ptr<!spirv.struct<(!spirv.rtarray<f32, stride=4> [0])>, StorageBuffer>, i32, i32 -> !spirv.ptr<f32, StorageBuffer>
        spirv.Store "StorageBuffer" %13, %12 : f32
        %14 = spirv.IAdd %4, %cst1_i32 : i32
        spirv.Branch ^bb1(%14 : i32)
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

