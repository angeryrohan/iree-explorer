func.func @bad(%a: tensor<4xf32>) -> tensor<4xf32> {
  %x = arith.addf %a, %b : tensor<4xf32>
  return %x : tensor<4xf32>
}
