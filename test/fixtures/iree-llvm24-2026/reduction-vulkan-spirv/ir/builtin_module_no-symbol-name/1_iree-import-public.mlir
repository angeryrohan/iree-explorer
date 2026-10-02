// -----// IR Dump After IREEImportPublicPass: iree-import-public //----- //
#map = affine_map<(d0, d1) -> (d0, d1)>
#map1 = affine_map<(d0, d1) -> (d0)>
module {
  util.func public @rowsum(%arg0: tensor<8x100xf32>) -> tensor<8xf32> {
    %cst = arith.constant 0.000000e+00 : f32
    %0 = tensor.empty() : tensor<8xf32>
    %1 = linalg.fill ins(%cst : f32) outs(%0 : tensor<8xf32>) -> tensor<8xf32>
    %2 = linalg.generic {indexing_maps = [#map, #map1], iterator_types = ["parallel", "reduction"]} ins(%arg0 : tensor<8x100xf32>) outs(%1 : tensor<8xf32>) {
    ^bb0(%in: f32, %out: f32):
      %3 = arith.addf %in, %out : f32
      linalg.yield %3 : f32
    } -> tensor<8xf32>
    util.return %2 : tensor<8xf32>
  }
}


