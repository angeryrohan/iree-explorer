func.func @mlp(%x: tensor<4x64xf32>, %w1: tensor<64x128xf32>, %w2: tensor<128x10xf32>) -> tensor<4x10xf32> {
  %cst = arith.constant 0.0 : f32
  %e1 = tensor.empty() : tensor<4x128xf32>
  %f1 = linalg.fill ins(%cst : f32) outs(%e1 : tensor<4x128xf32>) -> tensor<4x128xf32>
  %h = linalg.matmul ins(%x, %w1 : tensor<4x64xf32>, tensor<64x128xf32>) outs(%f1 : tensor<4x128xf32>) -> tensor<4x128xf32>
  %r = math.tanh %h : tensor<4x128xf32>
  %e2 = tensor.empty() : tensor<4x10xf32>
  %f2 = linalg.fill ins(%cst : f32) outs(%e2 : tensor<4x10xf32>) -> tensor<4x10xf32>
  %o = linalg.matmul ins(%r, %w2 : tensor<4x128xf32>, tensor<128x10xf32>) outs(%f2 : tensor<4x10xf32>) -> tensor<4x10xf32>
  %s = tensor.collapse_shape %o [[0, 1]] : tensor<4x10xf32> into tensor<40xf32>
  %t = tensor.expand_shape %s [[0, 1]] output_shape [4, 10] : tensor<40xf32> into tensor<4x10xf32>
  return %t : tensor<4x10xf32>
}
