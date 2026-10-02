// -----// IR Dump After GenericVectorizationPass: iree-codegen-generic-vectorization{enable-cleanup=true enable-vector-masking=false fold-cast-into-contract=false generate-contract=true max-vector-size=2147483647 use-configured-vector-sizes=true vectorize-copies=true vectorize-map-store=false vectorize-to-transfer-gather=false} //----- //
func.func @matmul_dispatch_0_matmul_64x64x64_f32() attributes {translation_info = #iree_codegen.translation_info<pipeline = #iree_cpu.pipeline<DoubleTilingExpert>, {enable_loop_peeling}>} {
  %cst = arith.constant dense<0.000000e+00> : vector<8x8xf32>
  %0 = ub.poison : f32
  %c8 = arith.constant 8 : index
  %c4 = arith.constant 4 : index
  %c64 = arith.constant 64 : index
  %c0 = arith.constant 0 : index
  %1 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(0) alignment(64) offset(%c0) flags("ReadOnly|Indirect") : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
  %2 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(1) alignment(64) offset(%c0) flags("ReadOnly|Indirect") : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
  %3 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(2) alignment(64) offset(%c0) flags(Indirect) : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
  %4 = iree_codegen.load_from_buffer %1 : memref<64x64xf32, #hal.descriptor_type<storage_buffer>> -> tensor<64x64xf32>
  %5 = iree_codegen.load_from_buffer %2 : memref<64x64xf32, #hal.descriptor_type<storage_buffer>> -> tensor<64x64xf32>
  %6 = tensor.empty() : tensor<64x64xf32>
  %7 = scf.forall (%arg0) = (0) to (64) step (8) shared_outs(%arg1 = %6) -> (tensor<64x64xf32>) {
    %extracted_slice = tensor.extract_slice %arg1[%arg0, 0] [8, 64] [1, 1] : tensor<64x64xf32> to tensor<8x64xf32>
    %8 = scf.for %arg2 = %c0 to %c64 step %c8 iter_args(%arg3 = %extracted_slice) -> (tensor<8x64xf32>) {
      %extracted_slice_0 = tensor.extract_slice %arg3[0, %arg2] [8, 8] [1, 1] : tensor<8x64xf32> to tensor<8x8xf32>
      %9 = vector.transfer_write %cst, %extracted_slice_0[%c0, %c0] {in_bounds = [true, true]} : vector<8x8xf32>, tensor<8x8xf32>
      %10 = scf.for %arg4 = %c0 to %c64 step %c4 iter_args(%arg5 = %9) -> (tensor<8x8xf32>) {
        %extracted_slice_1 = tensor.extract_slice %4[%arg0, %arg4] [8, 4] [1, 1] : tensor<64x64xf32> to tensor<8x4xf32>
        %extracted_slice_2 = tensor.extract_slice %5[%arg4, %arg2] [4, 8] [1, 1] : tensor<64x64xf32> to tensor<4x8xf32>
        %11 = vector.transfer_read %extracted_slice_1[%c0, %c0], %0 {in_bounds = [true, true]} : tensor<8x4xf32>, vector<8x4xf32>
        %12 = vector.transfer_read %extracted_slice_2[%c0, %c0], %0 {in_bounds = [true, true]} : tensor<4x8xf32>, vector<4x8xf32>
        %13 = vector.transfer_read %arg5[%c0, %c0], %0 {in_bounds = [true, true]} : tensor<8x8xf32>, vector<8x8xf32>
        %14 = vector.contract {indexing_maps = [affine_map<(d0, d1, d2) -> (d0, d2)>, affine_map<(d0, d1, d2) -> (d2, d1)>, affine_map<(d0, d1, d2) -> (d0, d1)>], iterator_types = ["parallel", "parallel", "reduction"], kind = #vector.kind<add>} %11, %12, %13 : vector<8x4xf32>, vector<4x8xf32> into vector<8x8xf32>
        %15 = vector.transfer_write %14, %arg5[%c0, %c0] {in_bounds = [true, true]} : vector<8x8xf32>, tensor<8x8xf32>
        scf.yield %15 : tensor<8x8xf32>
      }
      %inserted_slice = tensor.insert_slice %10 into %arg3[0, %arg2] [8, 8] [1, 1] : tensor<8x8xf32> into tensor<8x64xf32>
      scf.yield %inserted_slice : tensor<8x64xf32>
    }
    scf.forall.in_parallel {
      tensor.parallel_insert_slice %8 into %arg1[%arg0, 0] [8, 64] [1, 1] : tensor<8x64xf32> into tensor<64x64xf32>
    }
  } {mapping = [#iree_codegen.workgroup_mapping<x>]}
  iree_codegen.store_to_buffer %7, %3 : tensor<64x64xf32> into memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
  return
}

