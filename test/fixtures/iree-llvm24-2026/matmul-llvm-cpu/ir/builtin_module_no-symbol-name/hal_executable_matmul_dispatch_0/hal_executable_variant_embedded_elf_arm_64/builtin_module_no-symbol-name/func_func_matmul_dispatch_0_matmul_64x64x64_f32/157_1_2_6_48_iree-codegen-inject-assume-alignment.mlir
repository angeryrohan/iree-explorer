// -----// IR Dump After IREEInjectAssumeAlignmentPass: iree-codegen-inject-assume-alignment //----- //
func.func @matmul_dispatch_0_matmul_64x64x64_f32() attributes {translation_info = #iree_codegen.translation_info<pipeline = #iree_cpu.pipeline<DoubleTilingExpert>, {enable_loop_peeling}>} {
  %cst = arith.constant dense<0.000000e+00> : vector<8x8xf32>
  %0 = ub.poison : f32
  %c8 = arith.constant 8 : index
  %c4 = arith.constant 4 : index
  %c64 = arith.constant 64 : index
  %c0 = arith.constant 0 : index
  %1 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(0) alignment(64) offset(%c0) flags("ReadOnly|Indirect") : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
  %assume_align = memref.assume_alignment %1, 64 : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
  %2 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(1) alignment(64) offset(%c0) flags("ReadOnly|Indirect") : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
  %assume_align_0 = memref.assume_alignment %2, 64 : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
  %3 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(2) alignment(64) offset(%c0) flags(Indirect) : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
  %assume_align_1 = memref.assume_alignment %3, 64 : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
  scf.forall (%arg0) = (0) to (64) step (8) {
    %subview = memref.subview %assume_align_1[%arg0, 0] [8, 64] [1, 1] : memref<64x64xf32, #hal.descriptor_type<storage_buffer>> to memref<8x64xf32, strided<[64, 1], offset: ?>, #hal.descriptor_type<storage_buffer>>
    %4 = scf.for %arg1 = %c0 to %c64 step %c8 iter_args(%arg2 = %subview) -> (memref<8x64xf32, strided<[64, 1], offset: ?>, #hal.descriptor_type<storage_buffer>>) {
      %5 = scf.for %arg3 = %c0 to %c64 step %c4 iter_args(%arg4 = %cst) -> (vector<8x8xf32>) {
        %6 = vector.transfer_read %assume_align[%arg0, %arg3], %0 {in_bounds = [true, true]} : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>, vector<8x4xf32>
        %7 = vector.transfer_read %assume_align_0[%arg3, %arg1], %0 {in_bounds = [true, true]} : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>, vector<4x8xf32>
        %8 = vector.contract {indexing_maps = [affine_map<(d0, d1, d2) -> (d0, d2)>, affine_map<(d0, d1, d2) -> (d2, d1)>, affine_map<(d0, d1, d2) -> (d0, d1)>], iterator_types = ["parallel", "parallel", "reduction"], kind = #vector.kind<add>} %6, %7, %arg4 : vector<8x4xf32>, vector<4x8xf32> into vector<8x8xf32>
        scf.yield %8 : vector<8x8xf32>
      }
      vector.transfer_write %5, %arg2[%c0, %arg1] {in_bounds = [true, true]} : vector<8x8xf32>, memref<8x64xf32, strided<[64, 1], offset: ?>, #hal.descriptor_type<storage_buffer>>
      scf.yield %arg2 : memref<8x64xf32, strided<[64, 1], offset: ?>, #hal.descriptor_type<storage_buffer>>
    }
    %subview_2 = memref.subview %assume_align_1[%arg0, 0] [8, 64] [1, 1] : memref<64x64xf32, #hal.descriptor_type<storage_buffer>> to memref<8x64xf32, strided<[64, 1], offset: ?>, #hal.descriptor_type<storage_buffer>>
    linalg.generic {indexing_maps = [affine_map<(d0, d1) -> (d0, d1)>, affine_map<(d0, d1) -> (d0, d1)>], iterator_types = ["parallel", "parallel"]} ins(%4 : memref<8x64xf32, strided<[64, 1], offset: ?>, #hal.descriptor_type<storage_buffer>>) outs(%subview_2 : memref<8x64xf32, strided<[64, 1], offset: ?>, #hal.descriptor_type<storage_buffer>>) {
    ^bb0(%in: f32, %out: f32):
      linalg.yield %in : f32
    }
  } {mapping = [#iree_codegen.workgroup_mapping<x>]}
  linalg.generic {indexing_maps = [affine_map<(d0, d1) -> (d0, d1)>, affine_map<(d0, d1) -> (d0, d1)>], iterator_types = ["parallel", "parallel"]} ins(%assume_align_1 : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>) outs(%assume_align_1 : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>) {
  ^bb0(%in: f32, %out: f32):
    linalg.yield %in : f32
  }
  return
}

