// -----// IR Dump After FoldGlobalsPass: iree-util-fold-globals //----- //
#executable_target_vulkan_spirv_fb = #hal.executable.target<"vulkan-spirv", "vulkan-spirv-fb", {iree_codegen.target_info = #iree_gpu.target<arch = "rdna3", features = "spirv:v1.6,cap:Shader", wgp = <compute = fp64|fp32|fp16|int64|int32|int16|int8, storage = b64|b32|b16|b8, subgroup = shuffle|arithmetic, dot = dp4xi8toi32, mma = [<WMMAR3_F32_16x16x16_F16>, <WMMAR3_F16_16x16x16_F16>, <WMMAR3_F32_16x16x16_BF16>, <WMMAR3_BF16_16x16x16_BF16>, <WMMAR3_I32_16x16x16_I8>], subgroup_size_choices = [32, 64], max_workgroup_sizes = [1024, 1024, 1024], max_thread_count_per_workgroup = 1024, max_workgroup_memory_bytes = 65536, max_workgroup_counts = [2147483647, 2147483647, 2147483647], max_load_instruction_bits = 128, simds_per_wgp = 4, vgpr_space_bits = 8192, workgroup_memory_bank_count = 64>>}>
#map = affine_map<(d0, d1) -> (d0, d1)>
#map1 = affine_map<(d0, d1) -> (d0)>
#device_target_vulkan = #hal.device.target<"vulkan", [#executable_target_vulkan_spirv_fb]> : !hal.device
module attributes {iree.fixedpoint.iteration = 0 : index, stream.affinity.default = #hal.device.affinity<@__device_0>} {
  util.global private @__device_0 = #device_target_vulkan
  flow.executable private @rowsum_dispatch_0 {
    flow.executable.export public @rowsum_dispatch_0_reduction_8x100_f32 workgroups() -> (index, index, index) {
      %x, %y, %z = iree_tensor_ext.dispatch.workgroup_count_from_slice()
      flow.return %x, %y, %z : index, index, index
    }
    builtin.module {
      func.func @rowsum_dispatch_0_reduction_8x100_f32(%arg0: !iree_tensor_ext.dispatch.tensor<readonly:tensor<8x100xf32>>, %arg1: !iree_tensor_ext.dispatch.tensor<writeonly:tensor<8xf32>>) {
        %cst = arith.constant 0.000000e+00 : f32
        %0 = iree_tensor_ext.dispatch.tensor.load %arg0, offsets = [0, 0], sizes = [8, 100], strides = [1, 1] : !iree_tensor_ext.dispatch.tensor<readonly:tensor<8x100xf32>> -> tensor<8x100xf32>
        %1 = tensor.empty() : tensor<8xf32>
        %2 = linalg.fill ins(%cst : f32) outs(%1 : tensor<8xf32>) -> tensor<8xf32>
        %3 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "reduction"]} ins(%0 : tensor<8x100xf32>) outs(%2 : tensor<8xf32>) {
        ^bb0(%in: f32, %out: f32):
          %4 = arith.addf %in, %out : f32
          linalg.yield %4 : f32
        } -> tensor<8xf32>
        iree_tensor_ext.dispatch.tensor.store %3, %arg1, offsets = [0], sizes = [8], strides = [1] : tensor<8xf32> -> !iree_tensor_ext.dispatch.tensor<writeonly:tensor<8xf32>>
        return
      }
    }
  }
  util.func public @rowsum(%arg0: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @rowsum(%input0: tensor<8x100xf32>) -> (%output0: tensor<8xf32>)"}} {
    %0 = hal.tensor.import %arg0 "input0" : !hal.buffer_view -> tensor<8x100xf32>
    %1 = flow.dispatch @rowsum_dispatch_0::@rowsum_dispatch_0_reduction_8x100_f32(%0) : (tensor<8x100xf32>) -> tensor<8xf32>
    %2 = hal.tensor.export %1 "output0" : tensor<8xf32> -> !hal.buffer_view
    util.return %2 : !hal.buffer_view
  }
}


