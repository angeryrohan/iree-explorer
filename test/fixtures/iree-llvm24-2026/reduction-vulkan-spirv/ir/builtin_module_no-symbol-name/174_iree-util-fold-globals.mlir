// -----// IR Dump After FoldGlobalsPass: iree-util-fold-globals //----- //
#executable_target_vulkan_spirv_fb = #hal.executable.target<"vulkan-spirv", "vulkan-spirv-fb", {iree_codegen.target_info = #iree_gpu.target<arch = "rdna3", features = "spirv:v1.6,cap:Shader", wgp = <compute = fp64|fp32|fp16|int64|int32|int16|int8, storage = b64|b32|b16|b8, subgroup = shuffle|arithmetic, dot = dp4xi8toi32, mma = [<WMMAR3_F32_16x16x16_F16>, <WMMAR3_F16_16x16x16_F16>, <WMMAR3_F32_16x16x16_BF16>, <WMMAR3_BF16_16x16x16_BF16>, <WMMAR3_I32_16x16x16_I8>], subgroup_size_choices = [32, 64], max_workgroup_sizes = [1024, 1024, 1024], max_thread_count_per_workgroup = 1024, max_workgroup_memory_bytes = 65536, max_workgroup_counts = [2147483647, 2147483647, 2147483647], max_load_instruction_bits = 128, simds_per_wgp = 4, vgpr_space_bits = 8192, workgroup_memory_bank_count = 64>>}>
#pipeline_layout = #hal.pipeline.layout<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>
#device_target_vulkan = #hal.device.target<"vulkan", [#executable_target_vulkan_spirv_fb]> : !hal.device
module {
  util.global private @__device_0 = #device_target_vulkan
  util.global private @__device_0_query_0_hal_executable_format_vulkan_spirv_fb : i1
  util.initializer {
    %__device_0 = util.global.load @__device_0 : !hal.device
    %ok, %value = hal.device.query<%__device_0 : !hal.device> key("hal.executable.format" :: "vulkan-spirv-fb") : i1, i1 = false
    util.global.store %value, @__device_0_query_0_hal_executable_format_vulkan_spirv_fb : i1
    util.return
  }
  util.global private @__device_0_executable_0_rowsum_dispatch_0 : !hal.executable
  util.initializer {
    %c-1_i64 = arith.constant -1 : i64
    %c-1 = arith.constant -1 : index
    %c0 = arith.constant 0 : index
    %c14_i32 = arith.constant 14 : i32
    %0 = util.null : !hal.executable
    %__device_0_query_0_hal_executable_format_vulkan_spirv_fb = util.global.load @__device_0_query_0_hal_executable_format_vulkan_spirv_fb : i1
    %__device_0 = util.global.load @__device_0 : !hal.device
    %1 = arith.select %__device_0_query_0_hal_executable_format_vulkan_spirv_fb, %c0, %c-1 : index
    %2 = arith.cmpi eq, %1, %c0 : index
    %3 = scf.if %2 -> (!hal.executable) {
      %executable = hal.executable.create device(%__device_0 : !hal.device) affinity(%c-1_i64) target(@rowsum_dispatch_0::@vulkan_spirv_fb) : !hal.executable
      scf.yield %executable : !hal.executable
    } else {
      util.status.check_ok %c14_i32, "HAL device `__device_0` does not support any variant of executable `rowsum_dispatch_0`; available formats: [vulkan-spirv-fb]"
      scf.yield %0 : !hal.executable
    }
    util.global.store %3, @__device_0_executable_0_rowsum_dispatch_0 : !hal.executable
    util.return
  }
  hal.executable private @rowsum_dispatch_0 {
    hal.executable.variant public @vulkan_spirv_fb target(#executable_target_vulkan_spirv_fb) {
      hal.executable.export public @rowsum_dispatch_0_reduction_8x100_f32 ordinal(0) layout(#pipeline_layout) attributes {workgroup_size = [32 : index, 1 : index, 1 : index]}
      builtin.module attributes {hal.executable.target = #executable_target_vulkan_spirv_fb, spirv.target_env = #spirv.target_env<#spirv.vce<v1.6, [Shader, Float64, Float16, Int64, Int16, Int8, StorageBuffer16BitAccess, StorageUniform16, StoragePushConstant16, StorageBuffer8BitAccess, UniformAndStorageBuffer8BitAccess, StoragePushConstant8, GroupNonUniformShuffle, GroupNonUniformShuffleRelative, GroupNonUniformArithmetic, DotProduct, DotProductInput4x8BitPacked, DotProductInputAll, DotProductInput4x8Bit, CooperativeMatrixKHR], [SPV_KHR_16bit_storage, SPV_KHR_8bit_storage, SPV_KHR_integer_dot_product, SPV_KHR_cooperative_matrix]>, AMD, #spirv.resource_limits<max_compute_shared_memory_size = 65536, max_compute_workgroup_invocations = 1024, max_compute_workgroup_size = [1024 : i32, 1024 : i32, 1024 : i32], min_subgroup_size = 32, max_subgroup_size = 64, cooperative_matrix_properties_khr = [#spirv.coop_matrix_props_khr<m_size = 16, n_size = 16, k_size = 16, a_type = f16, b_type = f16, c_type = f32, result_type = f32, acc_sat = false, scope = <Subgroup>>, #spirv.coop_matrix_props_khr<m_size = 16, n_size = 16, k_size = 16, a_type = f16, b_type = f16, c_type = f16, result_type = f16, acc_sat = false, scope = <Subgroup>>, #spirv.coop_matrix_props_khr<m_size = 16, n_size = 16, k_size = 16, a_type = i8, b_type = i8, c_type = i32, result_type = i32, acc_sat = false, scope = <Subgroup>>]>>} {
        spirv.module Logical GLSL450 requires #spirv.vce<v1.0, [Shader, Matrix], [SPV_KHR_storage_buffer_storage_class]> {
          spirv.GlobalVariable @__builtin__LocalInvocationId__ built_in("LocalInvocationId") : !spirv.ptr<vector<3xi32>, Input>
          spirv.GlobalVariable @__resource_var_0_0_ bind(0, 0) : !spirv.ptr<!spirv.struct<(!spirv.rtarray<f32, stride=4> [0])>, StorageBuffer>
          spirv.GlobalVariable @__resource_var_0_1_ bind(0, 1) : !spirv.ptr<!spirv.struct<(!spirv.rtarray<f32, stride=4> [0])>, StorageBuffer>
          spirv.func @rowsum_dispatch_0_reduction_8x100_f32() "None" attributes {gpu.known_block_size = array<i32: 32, 1, 1>, hal.executable.target = #executable_target_vulkan_spirv_fb} {
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
  util.func private @__rowsum_memoize_apply(%arg0: !hal.device, %arg1: i64) -> !hal.command_buffer attributes {inlining_policy = #util.inline.never} {
    %c32 = arith.constant 32 : index
    %c3200 = arith.constant 3200 : index
    %c1 = arith.constant 1 : index
    %c0 = arith.constant 0 : index
    %c2 = arith.constant 2 : index
    %__device_0_executable_0_rowsum_dispatch_0 = util.global.load immutable @__device_0_executable_0_rowsum_dispatch_0 : !hal.executable
    %cmd = hal.command_buffer.create device(%arg0 : !hal.device) mode("None") categories("Transfer|Dispatch") affinity(%arg1) bindings(%c2) : !hal.command_buffer
    %function_id = hal.executable.lookup.function target(%__device_0_executable_0_rowsum_dispatch_0 : !hal.executable) function(@rowsum_dispatch_0::@vulkan_spirv_fb::@rowsum_dispatch_0_reduction_8x100_f32) : i64
    hal.command_buffer.dispatch<%cmd : !hal.command_buffer> target(%__device_0_executable_0_rowsum_dispatch_0 : !hal.executable)[%function_id] workgroups([%c1, %c1, %c1]) bindings([
      (%c0 : index)[%c0, %c3200], 
      (%c1 : index)[%c0, %c32]
    ]) flags("None")
    hal.command_buffer.execution_barrier<%cmd : !hal.command_buffer> source("Dispatch|Transfer|CommandRetire") target("CommandIssue|Dispatch|Transfer") flags("None")
    hal.command_buffer.finalize<%cmd : !hal.command_buffer>
    util.return %cmd : !hal.command_buffer
  }
  util.global private @__rowsum_memoize_result_0_device_0 : !hal.command_buffer
  util.initializer {
    %c-1_i64 = arith.constant -1 : i64
    %__device_0 = util.global.load immutable @__device_0 : !hal.device
    %0 = util.call @__rowsum_memoize_apply(%__device_0, %c-1_i64) : (!hal.device, i64) -> !hal.command_buffer
    util.global.store %0, @__rowsum_memoize_result_0_device_0 : !hal.command_buffer
    util.return
  }
  util.func private @__rowsum_memoize_lookup(%arg0: !hal.device, %arg1: i64) -> !hal.command_buffer {
    %0 = util.null : !hal.command_buffer
    %__device_0 = util.global.load immutable @__device_0 : !hal.device
    %1 = util.cmp.eq %arg0, %__device_0 : !hal.device
    %2 = scf.if %1 -> (!hal.command_buffer) {
      %__rowsum_memoize_result_0_device_0 = util.global.load immutable @__rowsum_memoize_result_0_device_0 : !hal.command_buffer
      scf.yield %__rowsum_memoize_result_0_device_0 : !hal.command_buffer
    } else {
      scf.yield %0 : !hal.command_buffer
    }
    util.return %2 : !hal.command_buffer
  }
  util.func public @rowsum(%arg0: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @rowsum(%input0: tensor<8x100xf32>) -> (%output0: tensor<8xf32>)"}} {
    %c-1_i32 = arith.constant -1 : i32
    %c0_i64 = arith.constant 0 : i64
    %0 = util.null : !hal.fence
    %c-1_i64 = arith.constant -1 : i64
    %c0 = arith.constant 0 : index
    %c32 = arith.constant 32 : index
    %c3200 = arith.constant 3200 : index
    %c100 = arith.constant 100 : index
    %c8 = arith.constant 8 : index
    %memory_type = hal.memory_type<"DeviceVisible|DeviceLocal"> : i32
    %buffer_usage = hal.buffer_usage<"TransferSource|TransferTarget|Transfer|DispatchStorageRead|DispatchStorageWrite|DispatchStorage"> : i32
    %__device_0 = util.global.load immutable @__device_0 : !hal.device
    %element_type_f32 = hal.element_type<f32> : i32
    %dense_row_major = hal.encoding_type<dense_row_major> : i32
    hal.buffer_view.assert<%arg0 : !hal.buffer_view> message("input0") shape([%c8, %c100]) type(%element_type_f32) encoding(%dense_row_major)
    %buffer = hal.buffer_view.buffer<%arg0 : !hal.buffer_view> : !hal.buffer
    %allocator = hal.device.allocator<%__device_0 : !hal.device> : !hal.allocator
    hal.buffer.assert<%buffer : !hal.buffer> message("tensor") allocator(%allocator : !hal.allocator) minimum_length(%c3200) type(DeviceVisible) usage("TransferSource|TransferTarget|Transfer|DispatchStorageRead|DispatchStorageWrite|DispatchStorage")
    %fence = hal.fence.create device(%__device_0 : !hal.device) flags("None") : !hal.fence
    %transient_buffer = hal.device.queue.alloca<%__device_0 : !hal.device> affinity(%c-1_i64) wait(%0) signal(%fence) pool(%c0_i64) type(%memory_type) usage(%buffer_usage) flags("None") : !hal.buffer{%c32}
    %1 = util.call @__rowsum_memoize_lookup(%__device_0, %c-1_i64) : (!hal.device, i64) -> !hal.command_buffer
    %fence_0 = hal.fence.create device(%__device_0 : !hal.device) flags("None") : !hal.fence
    hal.device.queue.execute.indirect<%__device_0 : !hal.device> affinity(%c-1_i64) wait(%fence) signal(%fence_0) commands(%1) bindings([
      (%buffer : !hal.buffer)[%c0, %c3200], 
      (%transient_buffer : !hal.buffer)[%c0, %c32]
    ]) flags("None")
    %status = hal.fence.await until([%fence_0]) timeout_millis(%c-1_i32) flags("None") : i32
    util.status.check_ok %status, "failed to wait on timepoint"
    %view = hal.buffer_view.create buffer(%transient_buffer : !hal.buffer)[%c0, %c32] shape([%c8]) type(%element_type_f32) encoding(%dense_row_major) : !hal.buffer_view
    util.return %view : !hal.buffer_view
  }
}


