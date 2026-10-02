// -----// IR Dump After CanonicalizerPass: canonicalize{cse-between-iterations=false    max-iterations=10 max-num-rewrites=-1 region-simplify=normal test-convergence=false top-down=true} //----- //
func.func @rowsum_dispatch_0_reduction_8x100_f32(%arg0: !stream.binding, %arg1: !stream.binding) {
  %cst = arith.constant 0.000000e+00 : f32
  %c0 = arith.constant 0 : index
  %0 = stream.binding.subspan %arg0[%c0] : !stream.binding -> !iree_tensor_ext.dispatch.tensor<readonly:tensor<8x100xf32>>
  %1 = stream.binding.subspan %arg1[%c0] : !stream.binding -> !iree_tensor_ext.dispatch.tensor<writeonly:tensor<8xf32>>
  %2 = iree_tensor_ext.dispatch.tensor.load %0, offsets = [0, 0], sizes = [8, 100], strides = [1, 1] : !iree_tensor_ext.dispatch.tensor<readonly:tensor<8x100xf32>> -> tensor<8x100xf32>
  %3 = tensor.empty() : tensor<8xf32>
  %4 = linalg.fill ins(%cst : f32) outs(%3 : tensor<8xf32>) -> tensor<8xf32>
  %5 = linalg.generic {indexing_maps = [affine_map<(d0, d1) -> (d0, d1)>, affine_map<(d0, d1) -> (d0)>], iterator_types = ["parallel", "reduction"]} ins(%2 : tensor<8x100xf32>) outs(%4 : tensor<8xf32>) {
  ^bb0(%in: f32, %out: f32):
    %6 = arith.addf %in, %out : f32
    linalg.yield %6 : f32
  } -> tensor<8xf32>
  iree_tensor_ext.dispatch.tensor.store %5, %1, offsets = [0], sizes = [8], strides = [1] : tensor<8xf32> -> !iree_tensor_ext.dispatch.tensor<writeonly:tensor<8xf32>>
  return
}

