// -----// IR Dump After VerifyLoweringToTensorsPass: iree-stream-verify-lowering-to-tensors //----- //
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
        %c0 = arith.constant 0 : index
        %0 = stream.binding.subspan %arg0[%c0] : !stream.binding -> !iree_tensor_ext.dispatch.tensor<readonly:tensor<8x100xf32>>
        %1 = stream.binding.subspan %arg1[%c0] : !stream.binding -> !iree_tensor_ext.dispatch.tensor<writeonly:tensor<8xf32>>
        %cst = arith.constant 0.000000e+00 : f32
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
    %element_type_f32 = hal.element_type<f32> : i32
    %dense_row_major = hal.encoding_type<dense_row_major> : i32
    %c8 = arith.constant 8 : index
    %c100 = arith.constant 100 : index
    hal.buffer_view.assert<%arg0 : !hal.buffer_view> message("input0") shape([%c8, %c100]) type(%element_type_f32) encoding(%dense_row_major)
    %0 = stream.tensor.sizeof on(#hal.device.affinity<@__device_0>) tensor<8x100xf32> : index
    %1 = stream.tensor.import on(#hal.device.affinity<@__device_0>) %arg0 : !hal.buffer_view -> tensor<8x100xf32> in !stream.resource<external>{%0}
    %2 = stream.async.cast on(#hal.device.affinity<@__device_0>) %1 : !stream.resource<external>{%0} -> !stream.resource<*>{%0}
    %3 = stream.tensor.sizeof on(#hal.device.affinity<@__device_0>) tensor<8xf32> : index
    %4 = stream.tensor.dispatch on(#hal.device.affinity<@__device_0>) @rowsum_dispatch_0::@rowsum_dispatch_0_reduction_8x100_f32(%2) : (tensor<8x100xf32> in !stream.resource<*>{%0}) -> tensor<8xf32> in !stream.resource<*>{%3}
    %5 = stream.async.cast on(#hal.device.affinity<@__device_0>) %4 : !stream.resource<*>{%3} -> !stream.resource<external>{%3}
    %6 = stream.tensor.export on(#hal.device.affinity<@__device_0>) %5 : tensor<8xf32> in !stream.resource<external>{%3} -> !hal.buffer_view
    util.return %6 : !hal.buffer_view
  }
}


