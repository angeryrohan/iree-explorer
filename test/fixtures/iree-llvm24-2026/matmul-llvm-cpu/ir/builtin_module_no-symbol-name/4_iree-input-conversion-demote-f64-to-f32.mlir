// -----// IR Dump After DemoteF64ToF32Pass: iree-input-conversion-demote-f64-to-f32 //----- //
module {
  util.func public @matmul(%arg0: tensor<64x64xf32>, %arg1: tensor<64x64xf32>) -> tensor<64x64xf32> {
    %cst = arith.constant 0.000000e+00 : f32
    %0 = tensor.empty() : tensor<64x64xf32>
    %1 = linalg.fill ins(%cst : f32) outs(%0 : tensor<64x64xf32>) -> tensor<64x64xf32>
    %2 = linalg.matmul ins(%arg0, %arg1 : tensor<64x64xf32>, tensor<64x64xf32>) outs(%1 : tensor<64x64xf32>) -> tensor<64x64xf32>
    util.return %2 : tensor<64x64xf32>
  }
}


