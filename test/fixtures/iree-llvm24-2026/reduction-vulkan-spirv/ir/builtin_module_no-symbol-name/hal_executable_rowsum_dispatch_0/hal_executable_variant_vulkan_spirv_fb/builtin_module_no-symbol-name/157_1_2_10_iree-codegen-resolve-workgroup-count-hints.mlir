// -----// IR Dump After ResolveWorkgroupCountHintsPass: iree-codegen-resolve-workgroup-count-hints //----- //
module attributes {hal.executable.target = #hal.executable.target<"vulkan-spirv", "vulkan-spirv-fb", {iree_codegen.target_info = #iree_gpu.target<arch = "rdna3", features = "spirv:v1.6,cap:Shader", wgp = <compute = fp64|fp32|fp16|int64|int32|int16|int8, storage = b64|b32|b16|b8, subgroup = shuffle|arithmetic, dot = dp4xi8toi32, mma = [<WMMAR3_F32_16x16x16_F16>, <WMMAR3_F16_16x16x16_F16>, <WMMAR3_F32_16x16x16_BF16>, <WMMAR3_BF16_16x16x16_BF16>, <WMMAR3_I32_16x16x16_I8>], subgroup_size_choices = [32, 64], max_workgroup_sizes = [1024, 1024, 1024], max_thread_count_per_workgroup = 1024, max_workgroup_memory_bytes = 65536, max_workgroup_counts = [2147483647, 2147483647, 2147483647], max_load_instruction_bits = 128, simds_per_wgp = 4, vgpr_space_bits = 8192, workgroup_memory_bank_count = 64>>}>} {
  func.func @rowsum_dispatch_0_reduction_8x100_f32() attributes {gpu.known_block_size = array<i32: 32, 1, 1>, hal.executable.target = #hal.executable.target<"vulkan-spirv", "vulkan-spirv-fb", {iree_codegen.target_info = #iree_gpu.target<arch = "rdna3", features = "spirv:v1.6,cap:Shader", wgp = <compute = fp64|fp32|fp16|int64|int32|int16|int8, storage = b64|b32|b16|b8, subgroup = shuffle|arithmetic, dot = dp4xi8toi32, mma = [<WMMAR3_F32_16x16x16_F16>, <WMMAR3_F16_16x16x16_F16>, <WMMAR3_F32_16x16x16_BF16>, <WMMAR3_BF16_16x16x16_BF16>, <WMMAR3_I32_16x16x16_I8>], subgroup_size_choices = [32, 64], max_workgroup_sizes = [1024, 1024, 1024], max_thread_count_per_workgroup = 1024, max_workgroup_memory_bytes = 65536, max_workgroup_counts = [2147483647, 2147483647, 2147483647], max_load_instruction_bits = 128, simds_per_wgp = 4, vgpr_space_bits = 8192, workgroup_memory_bank_count = 64>>}>} {
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
    %workgroup_id_x = hal.interface.workgroup.id[0] : index
    %workgroup_count_x = hal.interface.workgroup.count[0] : index
    %3 = affine.apply affine_map<()[s0] -> (s0 * 32)>()[%workgroup_id_x]
    scf.if %2 {
      memref.store %cst, %1[%thread_id_x] : memref<?xf32, #hal.descriptor_type<storage_buffer>>
      scf.for %arg0 = %c0 to %c100 step %c1 {
        %4 = affine.apply affine_map<(d0)[s0] -> (d0 + s0 * 100)>(%arg0)[%thread_id_x]
        %5 = memref.load %0[%4] : memref<?xf32, #hal.descriptor_type<storage_buffer>>
        %6 = memref.load %1[%thread_id_x] : memref<?xf32, #hal.descriptor_type<storage_buffer>>
        %7 = arith.addf %5, %6 : f32
        memref.store %7, %1[%thread_id_x] : memref<?xf32, #hal.descriptor_type<storage_buffer>>
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

