// -----// IR Dump After InitializeEmptyTensorsPass: iree-flow-initialize-empty-tensors{zero-fill=false} //----- //
util.func public @rowsum(%arg0: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @rowsum(%input0: tensor<8x100xf32>) -> (%output0: tensor<8xf32>)"}} {
  %0 = hal.tensor.import %arg0 "input0" : !hal.buffer_view -> tensor<8x100xf32>
  %1 = flow.dispatch.workgroups(%0) : (tensor<8x100xf32>) -> tensor<8xf32> =
      (%arg1: !iree_tensor_ext.dispatch.tensor<readonly:tensor<8x100xf32>>, %arg2: !iree_tensor_ext.dispatch.tensor<writeonly:tensor<8xf32>>) {
    %cst = arith.constant 0.000000e+00 : f32
    %3 = iree_tensor_ext.dispatch.tensor.load %arg1, offsets = [0, 0], sizes = [8, 100], strides = [1, 1] : !iree_tensor_ext.dispatch.tensor<readonly:tensor<8x100xf32>> -> tensor<8x100xf32>
    %4 = tensor.empty() : tensor<8xf32>
    %5 = linalg.fill ins(%cst : f32) outs(%4 : tensor<8xf32>) -> tensor<8xf32>
    %6 = linalg.generic {indexing_maps = [affine_map<(d0, d1) -> (d0, d1)>, affine_map<(d0, d1) -> (d0)>], iterator_types = ["parallel", "reduction"]} ins(%3 : tensor<8x100xf32>) outs(%5 : tensor<8xf32>) {
    ^bb0(%in: f32, %out: f32):
      %7 = arith.addf %in, %out : f32
      linalg.yield %7 : f32
    } -> tensor<8xf32>
    iree_tensor_ext.dispatch.tensor.store %6, %arg2, offsets = [0], sizes = [8], strides = [1] : tensor<8xf32> -> !iree_tensor_ext.dispatch.tensor<writeonly:tensor<8xf32>>
    flow.return
  } count() -> (index, index, index) {
    %x, %y, %z = iree_tensor_ext.dispatch.workgroup_count_from_slice()
    flow.return %x, %y, %z : index, index, index
  }
  %2 = hal.tensor.export %1 "output0" : tensor<8xf32> -> !hal.buffer_view
  util.return %2 : !hal.buffer_view
}

