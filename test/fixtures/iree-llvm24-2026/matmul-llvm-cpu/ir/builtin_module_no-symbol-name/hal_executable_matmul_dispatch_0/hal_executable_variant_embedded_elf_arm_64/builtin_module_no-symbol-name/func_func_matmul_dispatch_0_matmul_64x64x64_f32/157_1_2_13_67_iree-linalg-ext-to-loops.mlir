// -----// IR Dump After LinalgExtToLoopsPass: iree-linalg-ext-to-loops //----- //
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
  %subview = memref.subview %assume_align_1[%3, 0] [8, 64] [1, 1] : memref<64x64xf32> to memref<8x64xf32, strided<[64, 1], offset: ?>>
  scf.for %arg0 = %c0 to %c64 step %c8 {
    %4 = scf.for %arg1 = %c0 to %c64 step %c4 iter_args(%arg2 = %cst) -> (vector<8x8xf32>) {
      %13 = vector.load %assume_align[%3, %arg1] : memref<64x64xf32>, vector<4xf32>
      %14 = arith.addi %3, %c1 : index
      %15 = vector.load %assume_align[%14, %arg1] : memref<64x64xf32>, vector<4xf32>
      %16 = arith.addi %3, %c2 : index
      %17 = vector.load %assume_align[%16, %arg1] : memref<64x64xf32>, vector<4xf32>
      %18 = arith.addi %3, %c3 : index
      %19 = vector.load %assume_align[%18, %arg1] : memref<64x64xf32>, vector<4xf32>
      %20 = arith.addi %3, %c4 : index
      %21 = vector.load %assume_align[%20, %arg1] : memref<64x64xf32>, vector<4xf32>
      %22 = arith.addi %3, %c5 : index
      %23 = vector.load %assume_align[%22, %arg1] : memref<64x64xf32>, vector<4xf32>
      %24 = arith.addi %3, %c6 : index
      %25 = vector.load %assume_align[%24, %arg1] : memref<64x64xf32>, vector<4xf32>
      %26 = arith.addi %3, %c7 : index
      %27 = vector.load %assume_align[%26, %arg1] : memref<64x64xf32>, vector<4xf32>
      %28 = vector.load %assume_align_0[%arg1, %arg0] : memref<64x64xf32>, vector<8xf32>
      %29 = arith.addi %arg1, %c1 : index
      %30 = vector.load %assume_align_0[%29, %arg0] : memref<64x64xf32>, vector<8xf32>
      %31 = arith.addi %arg1, %c2 : index
      %32 = vector.load %assume_align_0[%31, %arg0] : memref<64x64xf32>, vector<8xf32>
      %33 = arith.addi %arg1, %c3 : index
      %34 = vector.load %assume_align_0[%33, %arg0] : memref<64x64xf32>, vector<8xf32>
      %35 = vector.extract %13[0] : f32 from vector<4xf32>
      %36 = vector.broadcast %35 : f32 to vector<8xf32>
      %37 = vector.extract %arg2[0] : vector<8xf32> from vector<8x8xf32>
      %38 = vector.fma %36, %28, %37 : vector<8xf32>
      %39 = vector.extract %15[0] : f32 from vector<4xf32>
      %40 = vector.broadcast %39 : f32 to vector<8xf32>
      %41 = vector.extract %arg2[1] : vector<8xf32> from vector<8x8xf32>
      %42 = vector.fma %40, %28, %41 : vector<8xf32>
      %43 = vector.extract %17[0] : f32 from vector<4xf32>
      %44 = vector.broadcast %43 : f32 to vector<8xf32>
      %45 = vector.extract %arg2[2] : vector<8xf32> from vector<8x8xf32>
      %46 = vector.fma %44, %28, %45 : vector<8xf32>
      %47 = vector.extract %19[0] : f32 from vector<4xf32>
      %48 = vector.broadcast %47 : f32 to vector<8xf32>
      %49 = vector.extract %arg2[3] : vector<8xf32> from vector<8x8xf32>
      %50 = vector.fma %48, %28, %49 : vector<8xf32>
      %51 = vector.extract %21[0] : f32 from vector<4xf32>
      %52 = vector.broadcast %51 : f32 to vector<8xf32>
      %53 = vector.extract %arg2[4] : vector<8xf32> from vector<8x8xf32>
      %54 = vector.fma %52, %28, %53 : vector<8xf32>
      %55 = vector.extract %23[0] : f32 from vector<4xf32>
      %56 = vector.broadcast %55 : f32 to vector<8xf32>
      %57 = vector.extract %arg2[5] : vector<8xf32> from vector<8x8xf32>
      %58 = vector.fma %56, %28, %57 : vector<8xf32>
      %59 = vector.extract %25[0] : f32 from vector<4xf32>
      %60 = vector.broadcast %59 : f32 to vector<8xf32>
      %61 = vector.extract %arg2[6] : vector<8xf32> from vector<8x8xf32>
      %62 = vector.fma %60, %28, %61 : vector<8xf32>
      %63 = vector.extract %27[0] : f32 from vector<4xf32>
      %64 = vector.broadcast %63 : f32 to vector<8xf32>
      %65 = vector.extract %arg2[7] : vector<8xf32> from vector<8x8xf32>
      %66 = vector.fma %64, %28, %65 : vector<8xf32>
      %67 = vector.extract %13[1] : f32 from vector<4xf32>
      %68 = vector.broadcast %67 : f32 to vector<8xf32>
      %69 = vector.fma %68, %30, %38 : vector<8xf32>
      %70 = vector.extract %15[1] : f32 from vector<4xf32>
      %71 = vector.broadcast %70 : f32 to vector<8xf32>
      %72 = vector.fma %71, %30, %42 : vector<8xf32>
      %73 = vector.extract %17[1] : f32 from vector<4xf32>
      %74 = vector.broadcast %73 : f32 to vector<8xf32>
      %75 = vector.fma %74, %30, %46 : vector<8xf32>
      %76 = vector.extract %19[1] : f32 from vector<4xf32>
      %77 = vector.broadcast %76 : f32 to vector<8xf32>
      %78 = vector.fma %77, %30, %50 : vector<8xf32>
      %79 = vector.extract %21[1] : f32 from vector<4xf32>
      %80 = vector.broadcast %79 : f32 to vector<8xf32>
      %81 = vector.fma %80, %30, %54 : vector<8xf32>
      %82 = vector.extract %23[1] : f32 from vector<4xf32>
      %83 = vector.broadcast %82 : f32 to vector<8xf32>
      %84 = vector.fma %83, %30, %58 : vector<8xf32>
      %85 = vector.extract %25[1] : f32 from vector<4xf32>
      %86 = vector.broadcast %85 : f32 to vector<8xf32>
      %87 = vector.fma %86, %30, %62 : vector<8xf32>
      %88 = vector.extract %27[1] : f32 from vector<4xf32>
      %89 = vector.broadcast %88 : f32 to vector<8xf32>
      %90 = vector.fma %89, %30, %66 : vector<8xf32>
      %91 = vector.extract %13[2] : f32 from vector<4xf32>
      %92 = vector.broadcast %91 : f32 to vector<8xf32>
      %93 = vector.fma %92, %32, %69 : vector<8xf32>
      %94 = vector.extract %15[2] : f32 from vector<4xf32>
      %95 = vector.broadcast %94 : f32 to vector<8xf32>
      %96 = vector.fma %95, %32, %72 : vector<8xf32>
      %97 = vector.extract %17[2] : f32 from vector<4xf32>
      %98 = vector.broadcast %97 : f32 to vector<8xf32>
      %99 = vector.fma %98, %32, %75 : vector<8xf32>
      %100 = vector.extract %19[2] : f32 from vector<4xf32>
      %101 = vector.broadcast %100 : f32 to vector<8xf32>
      %102 = vector.fma %101, %32, %78 : vector<8xf32>
      %103 = vector.extract %21[2] : f32 from vector<4xf32>
      %104 = vector.broadcast %103 : f32 to vector<8xf32>
      %105 = vector.fma %104, %32, %81 : vector<8xf32>
      %106 = vector.extract %23[2] : f32 from vector<4xf32>
      %107 = vector.broadcast %106 : f32 to vector<8xf32>
      %108 = vector.fma %107, %32, %84 : vector<8xf32>
      %109 = vector.extract %25[2] : f32 from vector<4xf32>
      %110 = vector.broadcast %109 : f32 to vector<8xf32>
      %111 = vector.fma %110, %32, %87 : vector<8xf32>
      %112 = vector.extract %27[2] : f32 from vector<4xf32>
      %113 = vector.broadcast %112 : f32 to vector<8xf32>
      %114 = vector.fma %113, %32, %90 : vector<8xf32>
      %115 = vector.extract %13[3] : f32 from vector<4xf32>
      %116 = vector.broadcast %115 : f32 to vector<8xf32>
      %117 = vector.fma %116, %34, %93 : vector<8xf32>
      %118 = vector.extract %15[3] : f32 from vector<4xf32>
      %119 = vector.broadcast %118 : f32 to vector<8xf32>
      %120 = vector.fma %119, %34, %96 : vector<8xf32>
      %121 = vector.extract %17[3] : f32 from vector<4xf32>
      %122 = vector.broadcast %121 : f32 to vector<8xf32>
      %123 = vector.fma %122, %34, %99 : vector<8xf32>
      %124 = vector.extract %19[3] : f32 from vector<4xf32>
      %125 = vector.broadcast %124 : f32 to vector<8xf32>
      %126 = vector.fma %125, %34, %102 : vector<8xf32>
      %127 = vector.extract %21[3] : f32 from vector<4xf32>
      %128 = vector.broadcast %127 : f32 to vector<8xf32>
      %129 = vector.fma %128, %34, %105 : vector<8xf32>
      %130 = vector.extract %23[3] : f32 from vector<4xf32>
      %131 = vector.broadcast %130 : f32 to vector<8xf32>
      %132 = vector.fma %131, %34, %108 : vector<8xf32>
      %133 = vector.extract %25[3] : f32 from vector<4xf32>
      %134 = vector.broadcast %133 : f32 to vector<8xf32>
      %135 = vector.fma %134, %34, %111 : vector<8xf32>
      %136 = vector.extract %27[3] : f32 from vector<4xf32>
      %137 = vector.broadcast %136 : f32 to vector<8xf32>
      %138 = vector.fma %137, %34, %114 : vector<8xf32>
      %139:8 = vector.to_elements %117 : vector<8xf32>
      %140:8 = vector.to_elements %120 : vector<8xf32>
      %141:8 = vector.to_elements %123 : vector<8xf32>
      %142:8 = vector.to_elements %126 : vector<8xf32>
      %143:8 = vector.to_elements %129 : vector<8xf32>
      %144:8 = vector.to_elements %132 : vector<8xf32>
      %145:8 = vector.to_elements %135 : vector<8xf32>
      %146:8 = vector.to_elements %138 : vector<8xf32>
      %147 = vector.from_elements %139#0, %139#1, %139#2, %139#3, %139#4, %139#5, %139#6, %139#7, %140#0, %140#1, %140#2, %140#3, %140#4, %140#5, %140#6, %140#7, %141#0, %141#1, %141#2, %141#3, %141#4, %141#5, %141#6, %141#7, %142#0, %142#1, %142#2, %142#3, %142#4, %142#5, %142#6, %142#7, %143#0, %143#1, %143#2, %143#3, %143#4, %143#5, %143#6, %143#7, %144#0, %144#1, %144#2, %144#3, %144#4, %144#5, %144#6, %144#7, %145#0, %145#1, %145#2, %145#3, %145#4, %145#5, %145#6, %145#7, %146#0, %146#1, %146#2, %146#3, %146#4, %146#5, %146#6, %146#7 : vector<8x8xf32>
      scf.yield %147 : vector<8x8xf32>
    }
    %5 = vector.extract %4[0] : vector<8xf32> from vector<8x8xf32>
    vector.store %5, %subview[%c0, %arg0] : memref<8x64xf32, strided<[64, 1], offset: ?>>, vector<8xf32>
    %6 = vector.extract %4[1] : vector<8xf32> from vector<8x8xf32>
    vector.store %6, %subview[%c1, %arg0] : memref<8x64xf32, strided<[64, 1], offset: ?>>, vector<8xf32>
    %7 = vector.extract %4[2] : vector<8xf32> from vector<8x8xf32>
    vector.store %7, %subview[%c2, %arg0] : memref<8x64xf32, strided<[64, 1], offset: ?>>, vector<8xf32>
    %8 = vector.extract %4[3] : vector<8xf32> from vector<8x8xf32>
    vector.store %8, %subview[%c3, %arg0] : memref<8x64xf32, strided<[64, 1], offset: ?>>, vector<8xf32>
    %9 = vector.extract %4[4] : vector<8xf32> from vector<8x8xf32>
    vector.store %9, %subview[%c4, %arg0] : memref<8x64xf32, strided<[64, 1], offset: ?>>, vector<8xf32>
    %10 = vector.extract %4[5] : vector<8xf32> from vector<8x8xf32>
    vector.store %10, %subview[%c5, %arg0] : memref<8x64xf32, strided<[64, 1], offset: ?>>, vector<8xf32>
    %11 = vector.extract %4[6] : vector<8xf32> from vector<8x8xf32>
    vector.store %11, %subview[%c6, %arg0] : memref<8x64xf32, strided<[64, 1], offset: ?>>, vector<8xf32>
    %12 = vector.extract %4[7] : vector<8xf32> from vector<8x8xf32>
    vector.store %12, %subview[%c7, %arg0] : memref<8x64xf32, strided<[64, 1], offset: ?>>, vector<8xf32>
  }
  return
}

