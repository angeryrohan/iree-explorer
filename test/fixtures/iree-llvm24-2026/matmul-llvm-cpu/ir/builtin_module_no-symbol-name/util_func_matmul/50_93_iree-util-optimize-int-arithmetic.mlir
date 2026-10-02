// -----// IR Dump After OptimizeIntArithmeticPass: iree-util-optimize-int-arithmetic{index-is-i64=false narrow-to-i32=false} //----- //
util.func public @matmul(%arg0: !hal.buffer_view, %arg1: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @matmul(%input0: tensor<64x64xf32>, %input1: tensor<64x64xf32>) -> (%output0: tensor<64x64xf32>)"}} {
  %0 = hal.tensor.import %arg0 "input0" : !hal.buffer_view -> tensor<64x64xf32>
  %1 = hal.tensor.import %arg1 "input1" : !hal.buffer_view -> tensor<64x64xf32>
  %2 = flow.dispatch @matmul_dispatch_0::@matmul_dispatch_0_matmul_64x64x64_f32(%0, %1) : (tensor<64x64xf32>, tensor<64x64xf32>) -> tensor<64x64xf32>
  %3 = hal.tensor.export %2 "output0" : tensor<64x64xf32> -> !hal.buffer_view
  util.return %3 : !hal.buffer_view
}

