func.func @matmul(%a: tensor<64x64xf32>, %b: tensor<64x64xf32>) -> tensor<64x64xf32> {
  %cst = arith.constant 0.0 : f32
  %e = tensor.empty() : tensor<64x64xf32>
  %f = linalg.fill ins(%cst : f32) outs(%e : tensor<64x64xf32>) -> tensor<64x64xf32>
  %r = linalg.matmul ins(%a, %b : tensor<64x64xf32>, tensor<64x64xf32>) outs(%f : tensor<64x64xf32>) -> tensor<64x64xf32>
  return %r : tensor<64x64xf32>
}
