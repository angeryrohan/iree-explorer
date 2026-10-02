// -----// IR Dump After BufferizeDispatchTensorLoadStorePass: iree-codegen-bufferize-dispatch-tensor-load-store //----- //
func.func @matmul_dispatch_0_matmul_64x64x64_f32() {
  %cst = arith.constant 0.000000e+00 : f32
  %c0 = arith.constant 0 : index
  %0 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(0) alignment(64) offset(%c0) flags("ReadOnly|Indirect") : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
  %1 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(0) alignment(64) offset(%c0) flags("ReadOnly|Indirect") : !iree_tensor_ext.dispatch.tensor<readonly:tensor<64x64xf32>>
  %2 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(1) alignment(64) offset(%c0) flags("ReadOnly|Indirect") : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
  %3 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(1) alignment(64) offset(%c0) flags("ReadOnly|Indirect") : !iree_tensor_ext.dispatch.tensor<readonly:tensor<64x64xf32>>
  %4 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(2) alignment(64) offset(%c0) flags(Indirect) : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
  %5 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(2) alignment(64) offset(%c0) flags(Indirect) : !iree_tensor_ext.dispatch.tensor<writeonly:tensor<64x64xf32>>
  %6 = iree_codegen.load_from_buffer %0 : memref<64x64xf32, #hal.descriptor_type<storage_buffer>> -> tensor<64x64xf32>
  %7 = iree_codegen.load_from_buffer %2 : memref<64x64xf32, #hal.descriptor_type<storage_buffer>> -> tensor<64x64xf32>
  %8 = tensor.empty() : tensor<64x64xf32>
  %9 = linalg.fill ins(%cst : f32) outs(%8 : tensor<64x64xf32>) -> tensor<64x64xf32>
  %10 = linalg.matmul ins(%6, %7 : tensor<64x64xf32>, tensor<64x64xf32>) outs(%9 : tensor<64x64xf32>) -> tensor<64x64xf32>
  iree_codegen.store_to_buffer %10, %4 : tensor<64x64xf32> into memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
  return
}

