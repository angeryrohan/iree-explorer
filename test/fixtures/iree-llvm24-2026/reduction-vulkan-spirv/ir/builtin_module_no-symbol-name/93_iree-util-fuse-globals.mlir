// -----// IR Dump After FuseGlobalsPass: iree-util-fuse-globals //----- //
#executable_target_vulkan_spirv_fb = #hal.executable.target<"vulkan-spirv", "vulkan-spirv-fb", {iree_codegen.target_info = #iree_gpu.target<arch = "rdna3", features = "spirv:v1.6,cap:Shader", wgp = <compute = fp64|fp32|fp16|int64|int32|int16|int8, storage = b64|b32|b16|b8, subgroup = shuffle|arithmetic, dot = dp4xi8toi32, mma = [<WMMAR3_F32_16x16x16_F16>, <WMMAR3_F16_16x16x16_F16>, <WMMAR3_F32_16x16x16_BF16>, <WMMAR3_BF16_16x16x16_BF16>, <WMMAR3_I32_16x16x16_I8>], subgroup_size_choices = [32, 64], max_workgroup_sizes = [1024, 1024, 1024], max_thread_count_per_workgroup = 1024, max_workgroup_memory_bytes = 65536, max_workgroup_counts = [2147483647, 2147483647, 2147483647], max_load_instruction_bits = 128, simds_per_wgp = 4, vgpr_space_bits = 8192, workgroup_memory_bank_count = 64>>}>
#map = affine_map<(d0, d1) -> (d0, d1)>
#map1 = affine_map<(d0, d1) -> (d0)>
#device_target_vulkan = #hal.device.target<"vulkan", [#executable_target_vulkan_spirv_fb]> : !hal.device
module attributes {stream.affinity.default = #hal.device.affinity<@__device_0>} {
  util.global private @__device_0 = #device_target_vulkan
  stream.executable private @rowsum_dispatch_0 {
    stream.executable.export public @rowsum_dispatch_0_reduction_8x100_f32 workgroups() -> (index, index, index) {
      %x, %y, %z = iree_tensor_ext.dispatch.workgroup_count_from_slice()
      stream.return %x, %y, %z : index, index, index
    }
    builtin.module {
      func.func @rowsum_dispatch_0_reduction_8x100_f32(%arg0: !stream.binding, %arg1: !stream.binding) {
        %cst = arith.constant 0.000000e+00 : f32
        %c0 = arith.constant 0 : index
        %0 = stream.binding.subspan %arg0[%c0] : !stream.binding -> !iree_tensor_ext.dispatch.tensor<readonly:tensor<8x100xf32>>
        %1 = stream.binding.subspan %arg1[%c0] : !stream.binding -> !iree_tensor_ext.dispatch.tensor<writeonly:tensor<8xf32>>
        %2 = iree_tensor_ext.dispatch.tensor.load %0, offsets = [0, 0], sizes = [8, 100], strides = [1, 1] : !iree_tensor_ext.dispatch.tensor<readonly:tensor<8x100xf32>> -> tensor<8x100xf32>
        %3 = tensor.empty() : tensor<8xf32>
        %4 = linalg.fill ins(%cst : f32) outs(%3 : tensor<8xf32>) -> tensor<8xf32>
        %5 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "reduction"]} ins(%2 : tensor<8x100xf32>) outs(%4 : tensor<8xf32>) {
        ^bb0(%in: f32, %out: f32):
          %6 = arith.addf %in, %out : f32
          linalg.yield %6 : f32
        } -> tensor<8xf32>
        iree_tensor_ext.dispatch.tensor.store %5, %1, offsets = [0], sizes = [8], strides = [1] : tensor<8xf32> -> !iree_tensor_ext.dispatch.tensor<writeonly:tensor<8xf32>>
        return
      }
    }
  }
  util.func public @rowsum(%arg0: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @rowsum(%input0: tensor<8x100xf32>) -> (%output0: tensor<8xf32>)"}} {
    %c0 = arith.constant 0 : index
    %c32 = arith.constant 32 : index
    %c3200 = arith.constant 3200 : index
    %c100 = arith.constant 100 : index
    %c8 = arith.constant 8 : index
    %element_type_f32 = hal.element_type<f32> : i32
    %dense_row_major = hal.encoding_type<dense_row_major> : i32
    hal.buffer_view.assert<%arg0 : !hal.buffer_view> message("input0") shape([%c8, %c100]) type(%element_type_f32) encoding(%dense_row_major)
    %0 = stream.tensor.import on(#hal.device.affinity<@__device_0>) %arg0 : !hal.buffer_view -> tensor<8x100xf32> in !stream.resource<external>{%c3200}
    %1 = stream.async.dispatch on(#hal.device.affinity<@__device_0>) @rowsum_dispatch_0::@rowsum_dispatch_0_reduction_8x100_f32(%0[%c0 to %c3200 for %c3200]) : (!stream.resource<external>{%c3200}) -> !stream.resource<external>{%c32}
    %2 = stream.tensor.export on(#hal.device.affinity<@__device_0>) %1 : tensor<8xf32> in !stream.resource<external>{%c32} -> !hal.buffer_view
    util.return %2 : !hal.buffer_view
  }
}


