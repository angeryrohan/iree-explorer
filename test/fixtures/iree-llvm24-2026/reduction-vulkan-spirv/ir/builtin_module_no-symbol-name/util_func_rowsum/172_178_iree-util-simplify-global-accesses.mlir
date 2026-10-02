// -----// IR Dump After SimplifyGlobalAccessesPass: iree-util-simplify-global-accesses //----- //
util.func public @rowsum(%arg0: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @rowsum(%input0: tensor<8x100xf32>) -> (%output0: tensor<8xf32>)"}} {
  %__device_0 = util.global.load immutable @__device_0 : !hal.device
  %buffer_usage = hal.buffer_usage<"TransferSource|TransferTarget|Transfer|DispatchStorageRead|DispatchStorageWrite|DispatchStorage"> : i32
  %memory_type = hal.memory_type<"DeviceVisible|DeviceLocal"> : i32
  %c8 = arith.constant 8 : index
  %c100 = arith.constant 100 : index
  %c3200 = arith.constant 3200 : index
  %c32 = arith.constant 32 : index
  %c0 = arith.constant 0 : index
  %c-1_i64 = arith.constant -1 : i64
  %0 = util.null : !hal.fence
  %c0_i64 = arith.constant 0 : i64
  %c-1_i32 = arith.constant -1 : i32
  %element_type_f32 = hal.element_type<f32> : i32
  %dense_row_major = hal.encoding_type<dense_row_major> : i32
  hal.buffer_view.assert<%arg0 : !hal.buffer_view> message("input0") shape([%c8, %c100]) type(%element_type_f32) encoding(%dense_row_major)
  %buffer = hal.buffer_view.buffer<%arg0 : !hal.buffer_view> : !hal.buffer
  %allocator = hal.device.allocator<%__device_0 : !hal.device> : !hal.allocator
  hal.buffer.assert<%buffer : !hal.buffer> message("tensor") allocator(%allocator : !hal.allocator) minimum_length(%c3200) type(DeviceVisible) usage("TransferSource|TransferTarget|Transfer|DispatchStorageRead|DispatchStorageWrite|DispatchStorage")
  %fence = hal.fence.create device(%__device_0 : !hal.device) flags("None") : !hal.fence
  %transient_buffer = hal.device.queue.alloca<%__device_0 : !hal.device> affinity(%c-1_i64) wait(%0) signal(%fence) pool(%c0_i64) type(%memory_type) usage(%buffer_usage) flags("None") : !hal.buffer{%c32}
  %1 = util.call @__rowsum_memoize_lookup(%__device_0, %c-1_i64) : (!hal.device, i64) -> !hal.command_buffer
  %fence_0 = hal.fence.create device(%__device_0 : !hal.device) flags("None") : !hal.fence
  hal.device.queue.execute.indirect<%__device_0 : !hal.device> affinity(%c-1_i64) wait(%fence) signal(%fence_0) commands(%1) bindings([
    (%buffer : !hal.buffer)[%c0, %c3200], 
    (%transient_buffer : !hal.buffer)[%c0, %c32]
  ]) flags("None")
  %status = hal.fence.await until([%fence_0]) timeout_millis(%c-1_i32) flags("None") : i32
  util.status.check_ok %status, "failed to wait on timepoint"
  %view = hal.buffer_view.create buffer(%transient_buffer : !hal.buffer)[%c0, %c32] shape([%c8]) type(%element_type_f32) encoding(%dense_row_major) : !hal.buffer_view
  util.return %view : !hal.buffer_view
}

