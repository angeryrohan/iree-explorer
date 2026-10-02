// -----// IR Dump After LLVMCPUVectorTransposeLoweringPass: iree-llvmcpu-vector-transpose-lowering{lower-vector-transpose-to-avx2=false} //----- //
func.func @matmul_dispatch_0_matmul_64x64x64_f32() attributes {translation_info = #iree_codegen.translation_info<pipeline = #iree_cpu.pipeline<DoubleTilingExpert>, {enable_loop_peeling}>} {
  %c7 = arith.constant 7 : index
  %c6 = arith.constant 6 : index
  %c5 = arith.constant 5 : index
  %c3 = arith.constant 3 : index
  %c2 = arith.constant 2 : index
  %c1 = arith.constant 1 : index
  %cst = arith.constant dense<0.000000e+00> : vector<8x8xf32>
  %c8 = arith.constant 8 : index
  %c4 = arith.constant 4 : index
  %c64 = arith.constant 64 : index
  %c0 = arith.constant 0 : index
  %0 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(0) alignment(64) offset(%c0) flags("ReadOnly|Indirect") : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
  %assume_align = memref.assume_alignment %0, 64 : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
  %1 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(1) alignment(64) offset(%c0) flags("ReadOnly|Indirect") : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
  %assume_align_0 = memref.assume_alignment %1, 64 : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
  %2 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(2) alignment(64) offset(%c0) flags(Indirect) : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
  %assume_align_1 = memref.assume_alignment %2, 64 : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
  scf.forall (%arg0) = (0) to (64) step (8) {
    %subview = memref.subview %assume_align_1[%arg0, 0] [8, 64] [1, 1] : memref<64x64xf32, #hal.descriptor_type<storage_buffer>> to memref<8x64xf32, strided<[64, 1], offset: ?>, #hal.descriptor_type<storage_buffer>>
    scf.for %arg1 = %c0 to %c64 step %c8 {
      %3 = scf.for %arg2 = %c0 to %c64 step %c4 iter_args(%arg3 = %cst) -> (vector<8x8xf32>) {
        %12 = vector.load %assume_align[%arg0, %arg2] : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>, vector<4xf32>
        %13 = affine.apply affine_map<(d0) -> (d0 + 1)>(%arg0)
        %14 = vector.load %assume_align[%13, %arg2] : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>, vector<4xf32>
        %15 = affine.apply affine_map<(d0) -> (d0 + 2)>(%arg0)
        %16 = vector.load %assume_align[%15, %arg2] : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>, vector<4xf32>
        %17 = affine.apply affine_map<(d0) -> (d0 + 3)>(%arg0)
        %18 = vector.load %assume_align[%17, %arg2] : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>, vector<4xf32>
        %19 = affine.apply affine_map<(d0) -> (d0 + 4)>(%arg0)
        %20 = vector.load %assume_align[%19, %arg2] : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>, vector<4xf32>
        %21 = affine.apply affine_map<(d0) -> (d0 + 5)>(%arg0)
        %22 = vector.load %assume_align[%21, %arg2] : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>, vector<4xf32>
        %23 = affine.apply affine_map<(d0) -> (d0 + 6)>(%arg0)
        %24 = vector.load %assume_align[%23, %arg2] : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>, vector<4xf32>
        %25 = affine.apply affine_map<(d0) -> (d0 + 7)>(%arg0)
        %26 = vector.load %assume_align[%25, %arg2] : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>, vector<4xf32>
        %27 = vector.load %assume_align_0[%arg2, %arg1] : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>, vector<8xf32>
        %28 = affine.apply affine_map<(d0) -> (d0 + 1)>(%arg2)
        %29 = vector.load %assume_align_0[%28, %arg1] : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>, vector<8xf32>
        %30 = affine.apply affine_map<(d0) -> (d0 + 2)>(%arg2)
        %31 = vector.load %assume_align_0[%30, %arg1] : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>, vector<8xf32>
        %32 = affine.apply affine_map<(d0) -> (d0 + 3)>(%arg2)
        %33 = vector.load %assume_align_0[%32, %arg1] : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>, vector<8xf32>
        %34 = vector.extract %12[0] : f32 from vector<4xf32>
        %35 = vector.broadcast %34 : f32 to vector<8xf32>
        %36 = vector.extract %arg3[0] : vector<8xf32> from vector<8x8xf32>
        %37 = vector.fma %35, %27, %36 : vector<8xf32>
        %38 = vector.extract %14[0] : f32 from vector<4xf32>
        %39 = vector.broadcast %38 : f32 to vector<8xf32>
        %40 = vector.extract %arg3[1] : vector<8xf32> from vector<8x8xf32>
        %41 = vector.fma %39, %27, %40 : vector<8xf32>
        %42 = vector.extract %16[0] : f32 from vector<4xf32>
        %43 = vector.broadcast %42 : f32 to vector<8xf32>
        %44 = vector.extract %arg3[2] : vector<8xf32> from vector<8x8xf32>
        %45 = vector.fma %43, %27, %44 : vector<8xf32>
        %46 = vector.extract %18[0] : f32 from vector<4xf32>
        %47 = vector.broadcast %46 : f32 to vector<8xf32>
        %48 = vector.extract %arg3[3] : vector<8xf32> from vector<8x8xf32>
        %49 = vector.fma %47, %27, %48 : vector<8xf32>
        %50 = vector.extract %20[0] : f32 from vector<4xf32>
        %51 = vector.broadcast %50 : f32 to vector<8xf32>
        %52 = vector.extract %arg3[4] : vector<8xf32> from vector<8x8xf32>
        %53 = vector.fma %51, %27, %52 : vector<8xf32>
        %54 = vector.extract %22[0] : f32 from vector<4xf32>
        %55 = vector.broadcast %54 : f32 to vector<8xf32>
        %56 = vector.extract %arg3[5] : vector<8xf32> from vector<8x8xf32>
        %57 = vector.fma %55, %27, %56 : vector<8xf32>
        %58 = vector.extract %24[0] : f32 from vector<4xf32>
        %59 = vector.broadcast %58 : f32 to vector<8xf32>
        %60 = vector.extract %arg3[6] : vector<8xf32> from vector<8x8xf32>
        %61 = vector.fma %59, %27, %60 : vector<8xf32>
        %62 = vector.extract %26[0] : f32 from vector<4xf32>
        %63 = vector.broadcast %62 : f32 to vector<8xf32>
        %64 = vector.extract %arg3[7] : vector<8xf32> from vector<8x8xf32>
        %65 = vector.fma %63, %27, %64 : vector<8xf32>
        %66 = vector.extract %12[1] : f32 from vector<4xf32>
        %67 = vector.broadcast %66 : f32 to vector<8xf32>
        %68 = vector.fma %67, %29, %37 : vector<8xf32>
        %69 = vector.extract %14[1] : f32 from vector<4xf32>
        %70 = vector.broadcast %69 : f32 to vector<8xf32>
        %71 = vector.fma %70, %29, %41 : vector<8xf32>
        %72 = vector.extract %16[1] : f32 from vector<4xf32>
        %73 = vector.broadcast %72 : f32 to vector<8xf32>
        %74 = vector.fma %73, %29, %45 : vector<8xf32>
        %75 = vector.extract %18[1] : f32 from vector<4xf32>
        %76 = vector.broadcast %75 : f32 to vector<8xf32>
        %77 = vector.fma %76, %29, %49 : vector<8xf32>
        %78 = vector.extract %20[1] : f32 from vector<4xf32>
        %79 = vector.broadcast %78 : f32 to vector<8xf32>
        %80 = vector.fma %79, %29, %53 : vector<8xf32>
        %81 = vector.extract %22[1] : f32 from vector<4xf32>
        %82 = vector.broadcast %81 : f32 to vector<8xf32>
        %83 = vector.fma %82, %29, %57 : vector<8xf32>
        %84 = vector.extract %24[1] : f32 from vector<4xf32>
        %85 = vector.broadcast %84 : f32 to vector<8xf32>
        %86 = vector.fma %85, %29, %61 : vector<8xf32>
        %87 = vector.extract %26[1] : f32 from vector<4xf32>
        %88 = vector.broadcast %87 : f32 to vector<8xf32>
        %89 = vector.fma %88, %29, %65 : vector<8xf32>
        %90 = vector.extract %12[2] : f32 from vector<4xf32>
        %91 = vector.broadcast %90 : f32 to vector<8xf32>
        %92 = vector.fma %91, %31, %68 : vector<8xf32>
        %93 = vector.extract %14[2] : f32 from vector<4xf32>
        %94 = vector.broadcast %93 : f32 to vector<8xf32>
        %95 = vector.fma %94, %31, %71 : vector<8xf32>
        %96 = vector.extract %16[2] : f32 from vector<4xf32>
        %97 = vector.broadcast %96 : f32 to vector<8xf32>
        %98 = vector.fma %97, %31, %74 : vector<8xf32>
        %99 = vector.extract %18[2] : f32 from vector<4xf32>
        %100 = vector.broadcast %99 : f32 to vector<8xf32>
        %101 = vector.fma %100, %31, %77 : vector<8xf32>
        %102 = vector.extract %20[2] : f32 from vector<4xf32>
        %103 = vector.broadcast %102 : f32 to vector<8xf32>
        %104 = vector.fma %103, %31, %80 : vector<8xf32>
        %105 = vector.extract %22[2] : f32 from vector<4xf32>
        %106 = vector.broadcast %105 : f32 to vector<8xf32>
        %107 = vector.fma %106, %31, %83 : vector<8xf32>
        %108 = vector.extract %24[2] : f32 from vector<4xf32>
        %109 = vector.broadcast %108 : f32 to vector<8xf32>
        %110 = vector.fma %109, %31, %86 : vector<8xf32>
        %111 = vector.extract %26[2] : f32 from vector<4xf32>
        %112 = vector.broadcast %111 : f32 to vector<8xf32>
        %113 = vector.fma %112, %31, %89 : vector<8xf32>
        %114 = vector.extract %12[3] : f32 from vector<4xf32>
        %115 = vector.broadcast %114 : f32 to vector<8xf32>
        %116 = vector.fma %115, %33, %92 : vector<8xf32>
        %117 = vector.extract %14[3] : f32 from vector<4xf32>
        %118 = vector.broadcast %117 : f32 to vector<8xf32>
        %119 = vector.fma %118, %33, %95 : vector<8xf32>
        %120 = vector.extract %16[3] : f32 from vector<4xf32>
        %121 = vector.broadcast %120 : f32 to vector<8xf32>
        %122 = vector.fma %121, %33, %98 : vector<8xf32>
        %123 = vector.extract %18[3] : f32 from vector<4xf32>
        %124 = vector.broadcast %123 : f32 to vector<8xf32>
        %125 = vector.fma %124, %33, %101 : vector<8xf32>
        %126 = vector.extract %20[3] : f32 from vector<4xf32>
        %127 = vector.broadcast %126 : f32 to vector<8xf32>
        %128 = vector.fma %127, %33, %104 : vector<8xf32>
        %129 = vector.extract %22[3] : f32 from vector<4xf32>
        %130 = vector.broadcast %129 : f32 to vector<8xf32>
        %131 = vector.fma %130, %33, %107 : vector<8xf32>
        %132 = vector.extract %24[3] : f32 from vector<4xf32>
        %133 = vector.broadcast %132 : f32 to vector<8xf32>
        %134 = vector.fma %133, %33, %110 : vector<8xf32>
        %135 = vector.extract %26[3] : f32 from vector<4xf32>
        %136 = vector.broadcast %135 : f32 to vector<8xf32>
        %137 = vector.fma %136, %33, %113 : vector<8xf32>
        %138:8 = vector.to_elements %116 : vector<8xf32>
        %139:8 = vector.to_elements %119 : vector<8xf32>
        %140:8 = vector.to_elements %122 : vector<8xf32>
        %141:8 = vector.to_elements %125 : vector<8xf32>
        %142:8 = vector.to_elements %128 : vector<8xf32>
        %143:8 = vector.to_elements %131 : vector<8xf32>
        %144:8 = vector.to_elements %134 : vector<8xf32>
        %145:8 = vector.to_elements %137 : vector<8xf32>
        %146 = vector.from_elements %138#0, %138#1, %138#2, %138#3, %138#4, %138#5, %138#6, %138#7, %139#0, %139#1, %139#2, %139#3, %139#4, %139#5, %139#6, %139#7, %140#0, %140#1, %140#2, %140#3, %140#4, %140#5, %140#6, %140#7, %141#0, %141#1, %141#2, %141#3, %141#4, %141#5, %141#6, %141#7, %142#0, %142#1, %142#2, %142#3, %142#4, %142#5, %142#6, %142#7, %143#0, %143#1, %143#2, %143#3, %143#4, %143#5, %143#6, %143#7, %144#0, %144#1, %144#2, %144#3, %144#4, %144#5, %144#6, %144#7, %145#0, %145#1, %145#2, %145#3, %145#4, %145#5, %145#6, %145#7 : vector<8x8xf32>
        scf.yield %146 : vector<8x8xf32>
      }
      %4 = vector.extract %3[0] : vector<8xf32> from vector<8x8xf32>
      vector.store %4, %subview[%c0, %arg1] : memref<8x64xf32, strided<[64, 1], offset: ?>, #hal.descriptor_type<storage_buffer>>, vector<8xf32>
      %5 = vector.extract %3[1] : vector<8xf32> from vector<8x8xf32>
      vector.store %5, %subview[%c1, %arg1] : memref<8x64xf32, strided<[64, 1], offset: ?>, #hal.descriptor_type<storage_buffer>>, vector<8xf32>
      %6 = vector.extract %3[2] : vector<8xf32> from vector<8x8xf32>
      vector.store %6, %subview[%c2, %arg1] : memref<8x64xf32, strided<[64, 1], offset: ?>, #hal.descriptor_type<storage_buffer>>, vector<8xf32>
      %7 = vector.extract %3[3] : vector<8xf32> from vector<8x8xf32>
      vector.store %7, %subview[%c3, %arg1] : memref<8x64xf32, strided<[64, 1], offset: ?>, #hal.descriptor_type<storage_buffer>>, vector<8xf32>
      %8 = vector.extract %3[4] : vector<8xf32> from vector<8x8xf32>
      vector.store %8, %subview[%c4, %arg1] : memref<8x64xf32, strided<[64, 1], offset: ?>, #hal.descriptor_type<storage_buffer>>, vector<8xf32>
      %9 = vector.extract %3[5] : vector<8xf32> from vector<8x8xf32>
      vector.store %9, %subview[%c5, %arg1] : memref<8x64xf32, strided<[64, 1], offset: ?>, #hal.descriptor_type<storage_buffer>>, vector<8xf32>
      %10 = vector.extract %3[6] : vector<8xf32> from vector<8x8xf32>
      vector.store %10, %subview[%c6, %arg1] : memref<8x64xf32, strided<[64, 1], offset: ?>, #hal.descriptor_type<storage_buffer>>, vector<8xf32>
      %11 = vector.extract %3[7] : vector<8xf32> from vector<8x8xf32>
      vector.store %11, %subview[%c7, %arg1] : memref<8x64xf32, strided<[64, 1], offset: ?>, #hal.descriptor_type<storage_buffer>>, vector<8xf32>
    }
  } {mapping = [#iree_codegen.workgroup_mapping<x>]}
  return
}

