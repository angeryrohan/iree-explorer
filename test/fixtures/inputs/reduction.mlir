#map_in = affine_map<(d0, d1) -> (d0, d1)>
#map_out = affine_map<(d0, d1) -> (d0)>
func.func @rowsum(%x: tensor<8x100xf32>) -> tensor<8xf32> {
  %cst = arith.constant 0.0 : f32
  %e = tensor.empty() : tensor<8xf32>
  %f = linalg.fill ins(%cst : f32) outs(%e : tensor<8xf32>) -> tensor<8xf32>
  %r = linalg.generic {indexing_maps = [#map_in, #map_out], iterator_types = ["parallel", "reduction"]}
         ins(%x : tensor<8x100xf32>) outs(%f : tensor<8xf32>) {
  ^bb0(%a: f32, %acc: f32):
    %s = arith.addf %a, %acc : f32
    linalg.yield %s : f32
  } -> tensor<8xf32>
  return %r : tensor<8xf32>
}
