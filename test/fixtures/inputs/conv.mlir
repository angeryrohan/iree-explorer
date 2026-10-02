func.func @conv(%in: tensor<1x16x16x4xf32>, %w: tensor<3x3x4x8xf32>) -> tensor<1x14x14x8xf32> {
  %cst = arith.constant 0.0 : f32
  %e = tensor.empty() : tensor<1x14x14x8xf32>
  %f = linalg.fill ins(%cst : f32) outs(%e : tensor<1x14x14x8xf32>) -> tensor<1x14x14x8xf32>
  %r = linalg.conv_2d_nhwc_hwcf {dilations = dense<1> : tensor<2xi64>, strides = dense<1> : tensor<2xi64>}
         ins(%in, %w : tensor<1x16x16x4xf32>, tensor<3x3x4x8xf32>) outs(%f : tensor<1x14x14x8xf32>) -> tensor<1x14x14x8xf32>
  return %r : tensor<1x14x14x8xf32>
}
