// -----// IR Dump After StripDebugOpsPass: iree-util-strip-debug-ops //----- //
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
      %3 = linalg.generic {indexing_maps = [affine_map<(d0, d1) -> (d0, d1)>, affine_map<(d0, d1) -> (d0)>], iterator_types = ["parallel", "reduction"]} ins(%0 : tensor<8x100xf32>) outs(%2 : tensor<8xf32>) {
      ^bb0(%in: f32, %out: f32):
        %4 = arith.addf %in, %out : f32
        linalg.yield %4 : f32
      } -> tensor<8xf32>
      iree_tensor_ext.dispatch.tensor.store %3, %arg1, offsets = [0], sizes = [8], strides = [1] : tensor<8xf32> -> !iree_tensor_ext.dispatch.tensor<writeonly:tensor<8xf32>>
      return
    }
  }
}

