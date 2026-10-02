// -----// IR Dump After CanonicalizerPass: canonicalize{cse-between-iterations=false    max-iterations=10 max-num-rewrites=-1 region-simplify=normal test-convergence=false top-down=true} //----- //
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
    scf.for %arg1 = %c0 to %c64 step %c8 {
      %4 = scf.for %arg2 = %c0 to %c64 step %c4 iter_args(%arg3 = %cst) -> (vector<8x8xf32>) {
        %5 = vector.transfer_read %assume_align[%arg0, %arg2], %0 {in_bounds = [true, true]} : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>, vector<8x4xf32>
        %6 = vector.transfer_read %assume_align_0[%arg2, %arg1], %0 {in_bounds = [true, true]} : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>, vector<4x8xf32>
        %7 = vector.extract %6[0] : vector<8xf32> from vector<4x8xf32>
        %8 = vector.extract %5[0, 0] : f32 from vector<8x4xf32>
        %9 = vector.broadcast %8 : f32 to vector<8xf32>
        %10 = vector.extract %arg3[0] : vector<8xf32> from vector<8x8xf32>
        %11 = vector.fma %9, %7, %10 : vector<8xf32>
        %12 = vector.extract %5[1, 0] : f32 from vector<8x4xf32>
        %13 = vector.broadcast %12 : f32 to vector<8xf32>
        %14 = vector.extract %arg3[1] : vector<8xf32> from vector<8x8xf32>
        %15 = vector.fma %13, %7, %14 : vector<8xf32>
        %16 = vector.extract %5[2, 0] : f32 from vector<8x4xf32>
        %17 = vector.broadcast %16 : f32 to vector<8xf32>
        %18 = vector.extract %arg3[2] : vector<8xf32> from vector<8x8xf32>
        %19 = vector.fma %17, %7, %18 : vector<8xf32>
        %20 = vector.extract %5[3, 0] : f32 from vector<8x4xf32>
        %21 = vector.broadcast %20 : f32 to vector<8xf32>
        %22 = vector.extract %arg3[3] : vector<8xf32> from vector<8x8xf32>
        %23 = vector.fma %21, %7, %22 : vector<8xf32>
        %24 = vector.extract %5[4, 0] : f32 from vector<8x4xf32>
        %25 = vector.broadcast %24 : f32 to vector<8xf32>
        %26 = vector.extract %arg3[4] : vector<8xf32> from vector<8x8xf32>
        %27 = vector.fma %25, %7, %26 : vector<8xf32>
        %28 = vector.extract %5[5, 0] : f32 from vector<8x4xf32>
        %29 = vector.broadcast %28 : f32 to vector<8xf32>
        %30 = vector.extract %arg3[5] : vector<8xf32> from vector<8x8xf32>
        %31 = vector.fma %29, %7, %30 : vector<8xf32>
        %32 = vector.extract %5[6, 0] : f32 from vector<8x4xf32>
        %33 = vector.broadcast %32 : f32 to vector<8xf32>
        %34 = vector.extract %arg3[6] : vector<8xf32> from vector<8x8xf32>
        %35 = vector.fma %33, %7, %34 : vector<8xf32>
        %36 = vector.extract %5[7, 0] : f32 from vector<8x4xf32>
        %37 = vector.broadcast %36 : f32 to vector<8xf32>
        %38 = vector.extract %arg3[7] : vector<8xf32> from vector<8x8xf32>
        %39 = vector.fma %37, %7, %38 : vector<8xf32>
        %40 = vector.extract %6[1] : vector<8xf32> from vector<4x8xf32>
        %41 = vector.extract %5[0, 1] : f32 from vector<8x4xf32>
        %42 = vector.broadcast %41 : f32 to vector<8xf32>
        %43 = vector.fma %42, %40, %11 : vector<8xf32>
        %44 = vector.extract %5[1, 1] : f32 from vector<8x4xf32>
        %45 = vector.broadcast %44 : f32 to vector<8xf32>
        %46 = vector.fma %45, %40, %15 : vector<8xf32>
        %47 = vector.extract %5[2, 1] : f32 from vector<8x4xf32>
        %48 = vector.broadcast %47 : f32 to vector<8xf32>
        %49 = vector.fma %48, %40, %19 : vector<8xf32>
        %50 = vector.extract %5[3, 1] : f32 from vector<8x4xf32>
        %51 = vector.broadcast %50 : f32 to vector<8xf32>
        %52 = vector.fma %51, %40, %23 : vector<8xf32>
        %53 = vector.extract %5[4, 1] : f32 from vector<8x4xf32>
        %54 = vector.broadcast %53 : f32 to vector<8xf32>
        %55 = vector.fma %54, %40, %27 : vector<8xf32>
        %56 = vector.extract %5[5, 1] : f32 from vector<8x4xf32>
        %57 = vector.broadcast %56 : f32 to vector<8xf32>
        %58 = vector.fma %57, %40, %31 : vector<8xf32>
        %59 = vector.extract %5[6, 1] : f32 from vector<8x4xf32>
        %60 = vector.broadcast %59 : f32 to vector<8xf32>
        %61 = vector.fma %60, %40, %35 : vector<8xf32>
        %62 = vector.extract %5[7, 1] : f32 from vector<8x4xf32>
        %63 = vector.broadcast %62 : f32 to vector<8xf32>
        %64 = vector.fma %63, %40, %39 : vector<8xf32>
        %65 = vector.extract %6[2] : vector<8xf32> from vector<4x8xf32>
        %66 = vector.extract %5[0, 2] : f32 from vector<8x4xf32>
        %67 = vector.broadcast %66 : f32 to vector<8xf32>
        %68 = vector.fma %67, %65, %43 : vector<8xf32>
        %69 = vector.extract %5[1, 2] : f32 from vector<8x4xf32>
        %70 = vector.broadcast %69 : f32 to vector<8xf32>
        %71 = vector.fma %70, %65, %46 : vector<8xf32>
        %72 = vector.extract %5[2, 2] : f32 from vector<8x4xf32>
        %73 = vector.broadcast %72 : f32 to vector<8xf32>
        %74 = vector.fma %73, %65, %49 : vector<8xf32>
        %75 = vector.extract %5[3, 2] : f32 from vector<8x4xf32>
        %76 = vector.broadcast %75 : f32 to vector<8xf32>
        %77 = vector.fma %76, %65, %52 : vector<8xf32>
        %78 = vector.extract %5[4, 2] : f32 from vector<8x4xf32>
        %79 = vector.broadcast %78 : f32 to vector<8xf32>
        %80 = vector.fma %79, %65, %55 : vector<8xf32>
        %81 = vector.extract %5[5, 2] : f32 from vector<8x4xf32>
        %82 = vector.broadcast %81 : f32 to vector<8xf32>
        %83 = vector.fma %82, %65, %58 : vector<8xf32>
        %84 = vector.extract %5[6, 2] : f32 from vector<8x4xf32>
        %85 = vector.broadcast %84 : f32 to vector<8xf32>
        %86 = vector.fma %85, %65, %61 : vector<8xf32>
        %87 = vector.extract %5[7, 2] : f32 from vector<8x4xf32>
        %88 = vector.broadcast %87 : f32 to vector<8xf32>
        %89 = vector.fma %88, %65, %64 : vector<8xf32>
        %90 = vector.extract %6[3] : vector<8xf32> from vector<4x8xf32>
        %91 = vector.extract %5[0, 3] : f32 from vector<8x4xf32>
        %92 = vector.broadcast %91 : f32 to vector<8xf32>
        %93 = vector.fma %92, %90, %68 : vector<8xf32>
        %94 = vector.extract %5[1, 3] : f32 from vector<8x4xf32>
        %95 = vector.broadcast %94 : f32 to vector<8xf32>
        %96 = vector.fma %95, %90, %71 : vector<8xf32>
        %97 = vector.extract %5[2, 3] : f32 from vector<8x4xf32>
        %98 = vector.broadcast %97 : f32 to vector<8xf32>
        %99 = vector.fma %98, %90, %74 : vector<8xf32>
        %100 = vector.extract %5[3, 3] : f32 from vector<8x4xf32>
        %101 = vector.broadcast %100 : f32 to vector<8xf32>
        %102 = vector.fma %101, %90, %77 : vector<8xf32>
        %103 = vector.extract %5[4, 3] : f32 from vector<8x4xf32>
        %104 = vector.broadcast %103 : f32 to vector<8xf32>
        %105 = vector.fma %104, %90, %80 : vector<8xf32>
        %106 = vector.extract %5[5, 3] : f32 from vector<8x4xf32>
        %107 = vector.broadcast %106 : f32 to vector<8xf32>
        %108 = vector.fma %107, %90, %83 : vector<8xf32>
        %109 = vector.extract %5[6, 3] : f32 from vector<8x4xf32>
        %110 = vector.broadcast %109 : f32 to vector<8xf32>
        %111 = vector.fma %110, %90, %86 : vector<8xf32>
        %112 = vector.extract %5[7, 3] : f32 from vector<8x4xf32>
        %113 = vector.broadcast %112 : f32 to vector<8xf32>
        %114 = vector.fma %113, %90, %89 : vector<8xf32>
        %115:8 = vector.to_elements %93 : vector<8xf32>
        %116:8 = vector.to_elements %96 : vector<8xf32>
        %117:8 = vector.to_elements %99 : vector<8xf32>
        %118:8 = vector.to_elements %102 : vector<8xf32>
        %119:8 = vector.to_elements %105 : vector<8xf32>
        %120:8 = vector.to_elements %108 : vector<8xf32>
        %121:8 = vector.to_elements %111 : vector<8xf32>
        %122:8 = vector.to_elements %114 : vector<8xf32>
        %123 = vector.from_elements %115#0, %115#1, %115#2, %115#3, %115#4, %115#5, %115#6, %115#7, %116#0, %116#1, %116#2, %116#3, %116#4, %116#5, %116#6, %116#7, %117#0, %117#1, %117#2, %117#3, %117#4, %117#5, %117#6, %117#7, %118#0, %118#1, %118#2, %118#3, %118#4, %118#5, %118#6, %118#7, %119#0, %119#1, %119#2, %119#3, %119#4, %119#5, %119#6, %119#7, %120#0, %120#1, %120#2, %120#3, %120#4, %120#5, %120#6, %120#7, %121#0, %121#1, %121#2, %121#3, %121#4, %121#5, %121#6, %121#7, %122#0, %122#1, %122#2, %122#3, %122#4, %122#5, %122#6, %122#7 : vector<8x8xf32>
        scf.yield %123 : vector<8x8xf32>
      }
      vector.transfer_write %4, %subview[%c0, %arg1] {in_bounds = [true, true]} : vector<8x8xf32>, memref<8x64xf32, strided<[64, 1], offset: ?>, #hal.descriptor_type<storage_buffer>>
    }
  } {mapping = [#iree_codegen.workgroup_mapping<x>]}
  return
}

