// -----// IR Dump After CanonicalizerPass: canonicalize{cse-between-iterations=false    max-iterations=10 max-num-rewrites=-1 region-simplify=normal test-convergence=false top-down=true} //----- //
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
      %9 = scf.for %arg4 = %c0 to %c64 step %c4 iter_args(%arg5 = %cst) -> (vector<8x8xf32>) {
        %11 = vector.transfer_read %4[%arg0, %arg4], %0 {in_bounds = [true, true]} : tensor<64x64xf32>, vector<8x4xf32>
        %12 = vector.transfer_read %5[%arg4, %arg2], %0 {in_bounds = [true, true]} : tensor<64x64xf32>, vector<4x8xf32>
        %13 = vector.contract {indexing_maps = [affine_map<(d0, d1, d2) -> (d0, d2)>, affine_map<(d0, d1, d2) -> (d2, d1)>, affine_map<(d0, d1, d2) -> (d0, d1)>], iterator_types = ["parallel", "parallel", "reduction"], kind = #vector.kind<add>} %11, %12, %arg5 : vector<8x4xf32>, vector<4x8xf32> into vector<8x8xf32>
        scf.yield %13 : vector<8x8xf32>
      }
      %10 = vector.transfer_write %9, %arg3[%c0, %arg2] {in_bounds = [true, true]} : vector<8x8xf32>, tensor<8x64xf32>
      scf.yield %10 : tensor<8x64xf32>
    }
    scf.forall.in_parallel {
      tensor.parallel_insert_slice %8 into %arg1[%arg0, 0] [8, 64] [1, 1] : tensor<8x64xf32> into tensor<64x64xf32>
    }
  } {mapping = [#iree_codegen.workgroup_mapping<x>]}
  iree_codegen.store_to_buffer %7, %3 : tensor<64x64xf32> into memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
  return
}

