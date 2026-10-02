// -----// IR Dump After IREEExpandStridedMetadataPass: iree-codegen-expand-strided-metadata{allow-subview-expansion=false allow-unresolved=false} //----- //
func.func @matmul_dispatch_0_matmul_64x64x64_f32() {
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
  %0 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(0) alignment(64) offset(%c0) flags("ReadOnly|Indirect") : memref<64x64xf32>
  %assume_align = memref.assume_alignment %0, 64 : memref<64x64xf32>
  %1 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(1) alignment(64) offset(%c0) flags("ReadOnly|Indirect") : memref<64x64xf32>
  %assume_align_0 = memref.assume_alignment %1, 64 : memref<64x64xf32>
  %2 = hal.interface.binding.subspan layout(<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>) binding(2) alignment(64) offset(%c0) flags(Indirect) : memref<64x64xf32>
  %assume_align_1 = memref.assume_alignment %2, 64 : memref<64x64xf32>
  %workgroup_id_x = hal.interface.workgroup.id[0] : index
  %3 = arith.muli %workgroup_id_x, %c8 overflow<nsw> : index
  scf.for %arg0 = %c0 to %c64 step %c8 {
    %4 = scf.for %arg1 = %c0 to %c64 step %c4 iter_args(%arg2 = %cst) -> (vector<8x8xf32>) {
      %20 = vector.load %assume_align[%3, %arg1] : memref<64x64xf32>, vector<4xf32>
      %21 = arith.addi %3, %c1 : index
      %22 = vector.load %assume_align[%21, %arg1] : memref<64x64xf32>, vector<4xf32>
      %23 = arith.addi %3, %c2 : index
      %24 = vector.load %assume_align[%23, %arg1] : memref<64x64xf32>, vector<4xf32>
      %25 = arith.addi %3, %c3 : index
      %26 = vector.load %assume_align[%25, %arg1] : memref<64x64xf32>, vector<4xf32>
      %27 = arith.addi %3, %c4 : index
      %28 = vector.load %assume_align[%27, %arg1] : memref<64x64xf32>, vector<4xf32>
      %29 = arith.addi %3, %c5 : index
      %30 = vector.load %assume_align[%29, %arg1] : memref<64x64xf32>, vector<4xf32>
      %31 = arith.addi %3, %c6 : index
      %32 = vector.load %assume_align[%31, %arg1] : memref<64x64xf32>, vector<4xf32>
      %33 = arith.addi %3, %c7 : index
      %34 = vector.load %assume_align[%33, %arg1] : memref<64x64xf32>, vector<4xf32>
      %35 = vector.load %assume_align_0[%arg1, %arg0] : memref<64x64xf32>, vector<8xf32>
      %36 = arith.addi %arg1, %c1 : index
      %37 = vector.load %assume_align_0[%36, %arg0] : memref<64x64xf32>, vector<8xf32>
      %38 = arith.addi %arg1, %c2 : index
      %39 = vector.load %assume_align_0[%38, %arg0] : memref<64x64xf32>, vector<8xf32>
      %40 = arith.addi %arg1, %c3 : index
      %41 = vector.load %assume_align_0[%40, %arg0] : memref<64x64xf32>, vector<8xf32>
      %42 = vector.extract %20[0] : f32 from vector<4xf32>
      %43 = vector.broadcast %42 : f32 to vector<8xf32>
      %44 = vector.extract %arg2[0] : vector<8xf32> from vector<8x8xf32>
      %45 = vector.fma %43, %35, %44 : vector<8xf32>
      %46 = vector.extract %22[0] : f32 from vector<4xf32>
      %47 = vector.broadcast %46 : f32 to vector<8xf32>
      %48 = vector.extract %arg2[1] : vector<8xf32> from vector<8x8xf32>
      %49 = vector.fma %47, %35, %48 : vector<8xf32>
      %50 = vector.extract %24[0] : f32 from vector<4xf32>
      %51 = vector.broadcast %50 : f32 to vector<8xf32>
      %52 = vector.extract %arg2[2] : vector<8xf32> from vector<8x8xf32>
      %53 = vector.fma %51, %35, %52 : vector<8xf32>
      %54 = vector.extract %26[0] : f32 from vector<4xf32>
      %55 = vector.broadcast %54 : f32 to vector<8xf32>
      %56 = vector.extract %arg2[3] : vector<8xf32> from vector<8x8xf32>
      %57 = vector.fma %55, %35, %56 : vector<8xf32>
      %58 = vector.extract %28[0] : f32 from vector<4xf32>
      %59 = vector.broadcast %58 : f32 to vector<8xf32>
      %60 = vector.extract %arg2[4] : vector<8xf32> from vector<8x8xf32>
      %61 = vector.fma %59, %35, %60 : vector<8xf32>
      %62 = vector.extract %30[0] : f32 from vector<4xf32>
      %63 = vector.broadcast %62 : f32 to vector<8xf32>
      %64 = vector.extract %arg2[5] : vector<8xf32> from vector<8x8xf32>
      %65 = vector.fma %63, %35, %64 : vector<8xf32>
      %66 = vector.extract %32[0] : f32 from vector<4xf32>
      %67 = vector.broadcast %66 : f32 to vector<8xf32>
      %68 = vector.extract %arg2[6] : vector<8xf32> from vector<8x8xf32>
      %69 = vector.fma %67, %35, %68 : vector<8xf32>
      %70 = vector.extract %34[0] : f32 from vector<4xf32>
      %71 = vector.broadcast %70 : f32 to vector<8xf32>
      %72 = vector.extract %arg2[7] : vector<8xf32> from vector<8x8xf32>
      %73 = vector.fma %71, %35, %72 : vector<8xf32>
      %74 = vector.extract %20[1] : f32 from vector<4xf32>
      %75 = vector.broadcast %74 : f32 to vector<8xf32>
      %76 = vector.fma %75, %37, %45 : vector<8xf32>
      %77 = vector.extract %22[1] : f32 from vector<4xf32>
      %78 = vector.broadcast %77 : f32 to vector<8xf32>
      %79 = vector.fma %78, %37, %49 : vector<8xf32>
      %80 = vector.extract %24[1] : f32 from vector<4xf32>
      %81 = vector.broadcast %80 : f32 to vector<8xf32>
      %82 = vector.fma %81, %37, %53 : vector<8xf32>
      %83 = vector.extract %26[1] : f32 from vector<4xf32>
      %84 = vector.broadcast %83 : f32 to vector<8xf32>
      %85 = vector.fma %84, %37, %57 : vector<8xf32>
      %86 = vector.extract %28[1] : f32 from vector<4xf32>
      %87 = vector.broadcast %86 : f32 to vector<8xf32>
      %88 = vector.fma %87, %37, %61 : vector<8xf32>
      %89 = vector.extract %30[1] : f32 from vector<4xf32>
      %90 = vector.broadcast %89 : f32 to vector<8xf32>
      %91 = vector.fma %90, %37, %65 : vector<8xf32>
      %92 = vector.extract %32[1] : f32 from vector<4xf32>
      %93 = vector.broadcast %92 : f32 to vector<8xf32>
      %94 = vector.fma %93, %37, %69 : vector<8xf32>
      %95 = vector.extract %34[1] : f32 from vector<4xf32>
      %96 = vector.broadcast %95 : f32 to vector<8xf32>
      %97 = vector.fma %96, %37, %73 : vector<8xf32>
      %98 = vector.extract %20[2] : f32 from vector<4xf32>
      %99 = vector.broadcast %98 : f32 to vector<8xf32>
      %100 = vector.fma %99, %39, %76 : vector<8xf32>
      %101 = vector.extract %22[2] : f32 from vector<4xf32>
      %102 = vector.broadcast %101 : f32 to vector<8xf32>
      %103 = vector.fma %102, %39, %79 : vector<8xf32>
      %104 = vector.extract %24[2] : f32 from vector<4xf32>
      %105 = vector.broadcast %104 : f32 to vector<8xf32>
      %106 = vector.fma %105, %39, %82 : vector<8xf32>
      %107 = vector.extract %26[2] : f32 from vector<4xf32>
      %108 = vector.broadcast %107 : f32 to vector<8xf32>
      %109 = vector.fma %108, %39, %85 : vector<8xf32>
      %110 = vector.extract %28[2] : f32 from vector<4xf32>
      %111 = vector.broadcast %110 : f32 to vector<8xf32>
      %112 = vector.fma %111, %39, %88 : vector<8xf32>
      %113 = vector.extract %30[2] : f32 from vector<4xf32>
      %114 = vector.broadcast %113 : f32 to vector<8xf32>
      %115 = vector.fma %114, %39, %91 : vector<8xf32>
      %116 = vector.extract %32[2] : f32 from vector<4xf32>
      %117 = vector.broadcast %116 : f32 to vector<8xf32>
      %118 = vector.fma %117, %39, %94 : vector<8xf32>
      %119 = vector.extract %34[2] : f32 from vector<4xf32>
      %120 = vector.broadcast %119 : f32 to vector<8xf32>
      %121 = vector.fma %120, %39, %97 : vector<8xf32>
      %122 = vector.extract %20[3] : f32 from vector<4xf32>
      %123 = vector.broadcast %122 : f32 to vector<8xf32>
      %124 = vector.fma %123, %41, %100 : vector<8xf32>
      %125 = vector.extract %22[3] : f32 from vector<4xf32>
      %126 = vector.broadcast %125 : f32 to vector<8xf32>
      %127 = vector.fma %126, %41, %103 : vector<8xf32>
      %128 = vector.extract %24[3] : f32 from vector<4xf32>
      %129 = vector.broadcast %128 : f32 to vector<8xf32>
      %130 = vector.fma %129, %41, %106 : vector<8xf32>
      %131 = vector.extract %26[3] : f32 from vector<4xf32>
      %132 = vector.broadcast %131 : f32 to vector<8xf32>
      %133 = vector.fma %132, %41, %109 : vector<8xf32>
      %134 = vector.extract %28[3] : f32 from vector<4xf32>
      %135 = vector.broadcast %134 : f32 to vector<8xf32>
      %136 = vector.fma %135, %41, %112 : vector<8xf32>
      %137 = vector.extract %30[3] : f32 from vector<4xf32>
      %138 = vector.broadcast %137 : f32 to vector<8xf32>
      %139 = vector.fma %138, %41, %115 : vector<8xf32>
      %140 = vector.extract %32[3] : f32 from vector<4xf32>
      %141 = vector.broadcast %140 : f32 to vector<8xf32>
      %142 = vector.fma %141, %41, %118 : vector<8xf32>
      %143 = vector.extract %34[3] : f32 from vector<4xf32>
      %144 = vector.broadcast %143 : f32 to vector<8xf32>
      %145 = vector.fma %144, %41, %121 : vector<8xf32>
      %146:8 = vector.to_elements %124 : vector<8xf32>
      %147:8 = vector.to_elements %127 : vector<8xf32>
      %148:8 = vector.to_elements %130 : vector<8xf32>
      %149:8 = vector.to_elements %133 : vector<8xf32>
      %150:8 = vector.to_elements %136 : vector<8xf32>
      %151:8 = vector.to_elements %139 : vector<8xf32>
      %152:8 = vector.to_elements %142 : vector<8xf32>
      %153:8 = vector.to_elements %145 : vector<8xf32>
      %154 = vector.from_elements %146#0, %146#1, %146#2, %146#3, %146#4, %146#5, %146#6, %146#7, %147#0, %147#1, %147#2, %147#3, %147#4, %147#5, %147#6, %147#7, %148#0, %148#1, %148#2, %148#3, %148#4, %148#5, %148#6, %148#7, %149#0, %149#1, %149#2, %149#3, %149#4, %149#5, %149#6, %149#7, %150#0, %150#1, %150#2, %150#3, %150#4, %150#5, %150#6, %150#7, %151#0, %151#1, %151#2, %151#3, %151#4, %151#5, %151#6, %151#7, %152#0, %152#1, %152#2, %152#3, %152#4, %152#5, %152#6, %152#7, %153#0, %153#1, %153#2, %153#3, %153#4, %153#5, %153#6, %153#7 : vector<8x8xf32>
      scf.yield %154 : vector<8x8xf32>
    }
    %5 = vector.extract %4[0] : vector<8xf32> from vector<8x8xf32>
    vector.store %5, %assume_align_1[%3, %arg0] : memref<64x64xf32>, vector<8xf32>
    %6 = vector.extract %4[1] : vector<8xf32> from vector<8x8xf32>
    %7 = affine.apply affine_map<()[s0] -> (s0 + 1)>()[%3]
    vector.store %6, %assume_align_1[%7, %arg0] : memref<64x64xf32>, vector<8xf32>
    %8 = vector.extract %4[2] : vector<8xf32> from vector<8x8xf32>
    %9 = affine.apply affine_map<()[s0] -> (s0 + 2)>()[%3]
    vector.store %8, %assume_align_1[%9, %arg0] : memref<64x64xf32>, vector<8xf32>
    %10 = vector.extract %4[3] : vector<8xf32> from vector<8x8xf32>
    %11 = affine.apply affine_map<()[s0] -> (s0 + 3)>()[%3]
    vector.store %10, %assume_align_1[%11, %arg0] : memref<64x64xf32>, vector<8xf32>
    %12 = vector.extract %4[4] : vector<8xf32> from vector<8x8xf32>
    %13 = affine.apply affine_map<()[s0] -> (s0 + 4)>()[%3]
    vector.store %12, %assume_align_1[%13, %arg0] : memref<64x64xf32>, vector<8xf32>
    %14 = vector.extract %4[5] : vector<8xf32> from vector<8x8xf32>
    %15 = affine.apply affine_map<()[s0] -> (s0 + 5)>()[%3]
    vector.store %14, %assume_align_1[%15, %arg0] : memref<64x64xf32>, vector<8xf32>
    %16 = vector.extract %4[6] : vector<8xf32> from vector<8x8xf32>
    %17 = affine.apply affine_map<()[s0] -> (s0 + 6)>()[%3]
    vector.store %16, %assume_align_1[%17, %arg0] : memref<64x64xf32>, vector<8xf32>
    %18 = vector.extract %4[7] : vector<8xf32> from vector<8x8xf32>
    %19 = affine.apply affine_map<()[s0] -> (s0 + 7)>()[%3]
    vector.store %18, %assume_align_1[%19, %arg0] : memref<64x64xf32>, vector<8xf32>
  }
  return
}

