// -----// IR Dump After IREELowerAffinePass: iree-lower-affine //----- //
util.func public @matmul(%arg0: !hal.buffer_view, %arg1: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @matmul(%input0: tensor<64x64xf32>, %input1: tensor<64x64xf32>) -> (%output0: tensor<64x64xf32>)"}} {
  %c-1_i32 = arith.constant -1 : i32
  %c0_i64 = arith.constant 0 : i64
  %0 = util.null : !hal.fence
  %c-1_i64 = arith.constant -1 : i64
  %c0 = arith.constant 0 : index
  %c16384 = arith.constant 16384 : index
  %c64 = arith.constant 64 : index
  %memory_type = hal.memory_type<"DeviceVisible|DeviceLocal"> : i32
  %buffer_usage = hal.buffer_usage<"TransferSource|TransferTarget|Transfer|DispatchStorageRead|DispatchStorageWrite|DispatchStorage"> : i32
  %__device_0 = util.global.load immutable @__device_0 : !hal.device
  %__matmul_memoize_result_0_device_0 = util.global.load immutable @__matmul_memoize_result_0_device_0 : !hal.command_buffer
  %element_type_f32 = hal.element_type<f32> : i32
  %dense_row_major = hal.encoding_type<dense_row_major> : i32
  hal.buffer_view.assert<%arg0 : !hal.buffer_view> message("input0") shape([%c64, %c64]) type(%element_type_f32) encoding(%dense_row_major)
  %buffer = hal.buffer_view.buffer<%arg0 : !hal.buffer_view> : !hal.buffer
  %allocator = hal.device.allocator<%__device_0 : !hal.device> : !hal.allocator
  hal.buffer.assert<%buffer : !hal.buffer> message("tensor") allocator(%allocator : !hal.allocator) minimum_length(%c16384) type(DeviceVisible) usage("TransferSource|TransferTarget|Transfer|DispatchStorageRead|DispatchStorageWrite|DispatchStorage")
  hal.buffer_view.assert<%arg1 : !hal.buffer_view> message("input1") shape([%c64, %c64]) type(%element_type_f32) encoding(%dense_row_major)
  %buffer_0 = hal.buffer_view.buffer<%arg1 : !hal.buffer_view> : !hal.buffer
  hal.buffer.assert<%buffer_0 : !hal.buffer> message("tensor") allocator(%allocator : !hal.allocator) minimum_length(%c16384) type(DeviceVisible) usage("TransferSource|TransferTarget|Transfer|DispatchStorageRead|DispatchStorageWrite|DispatchStorage")
  %fence = hal.fence.create device(%__device_0 : !hal.device) flags("None") : !hal.fence
  %transient_buffer = hal.device.queue.alloca<%__device_0 : !hal.device> affinity(%c-1_i64) wait(%0) signal(%fence) pool(%c0_i64) type(%memory_type) usage(%buffer_usage) flags("None") : !hal.buffer{%c16384}
  %fence_1 = hal.fence.create device(%__device_0 : !hal.device) flags("None") : !hal.fence
  hal.device.queue.execute.indirect<%__device_0 : !hal.device> affinity(%c-1_i64) wait(%fence) signal(%fence_1) commands(%__matmul_memoize_result_0_device_0) bindings([
    (%buffer : !hal.buffer)[%c0, %c16384], 
    (%buffer_0 : !hal.buffer)[%c0, %c16384], 
    (%transient_buffer : !hal.buffer)[%c0, %c16384]
  ]) flags("None")
  %status = hal.fence.await until([%fence_1]) timeout_millis(%c-1_i32) flags("None") : i32
  util.status.check_ok %status, "failed to wait on timepoint"
  %view = hal.buffer_view.create buffer(%transient_buffer : !hal.buffer)[%c0, %c16384] shape([%c64, %c64]) type(%element_type_f32) encoding(%dense_row_major) : !hal.buffer_view
  util.return %view : !hal.buffer_view
}

