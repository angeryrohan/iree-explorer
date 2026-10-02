// -----// IR Dump After SCFToControlFlowPass: convert-scf-to-cf{allow-pattern-rollback=true} //----- //
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
  cf.br ^bb1(%c0 : index)
^bb1(%4: index):  // 2 preds: ^bb0, ^bb5
  %5 = arith.cmpi slt, %4, %c64 : index
  cf.cond_br %5, ^bb2, ^bb6
^bb2:  // pred: ^bb1
  cf.br ^bb3(%c0, %cst : index, vector<8x8xf32>)
^bb3(%6: index, %7: vector<8x8xf32>):  // 2 preds: ^bb2, ^bb4
  %8 = arith.cmpi slt, %6, %c64 : index
  cf.cond_br %8, ^bb4, ^bb5
^bb4:  // pred: ^bb3
  %9 = vector.load %assume_align[%3, %6] : memref<64x64xf32>, vector<4xf32>
  %10 = arith.addi %3, %c1 : index
  %11 = vector.load %assume_align[%10, %6] : memref<64x64xf32>, vector<4xf32>
  %12 = arith.addi %3, %c2 : index
  %13 = vector.load %assume_align[%12, %6] : memref<64x64xf32>, vector<4xf32>
  %14 = arith.addi %3, %c3 : index
  %15 = vector.load %assume_align[%14, %6] : memref<64x64xf32>, vector<4xf32>
  %16 = arith.addi %3, %c4 : index
  %17 = vector.load %assume_align[%16, %6] : memref<64x64xf32>, vector<4xf32>
  %18 = arith.addi %3, %c5 : index
  %19 = vector.load %assume_align[%18, %6] : memref<64x64xf32>, vector<4xf32>
  %20 = arith.addi %3, %c6 : index
  %21 = vector.load %assume_align[%20, %6] : memref<64x64xf32>, vector<4xf32>
  %22 = arith.addi %3, %c7 : index
  %23 = vector.load %assume_align[%22, %6] : memref<64x64xf32>, vector<4xf32>
  %24 = vector.load %assume_align_0[%6, %4] : memref<64x64xf32>, vector<8xf32>
  %25 = arith.addi %6, %c1 : index
  %26 = vector.load %assume_align_0[%25, %4] : memref<64x64xf32>, vector<8xf32>
  %27 = arith.addi %6, %c2 : index
  %28 = vector.load %assume_align_0[%27, %4] : memref<64x64xf32>, vector<8xf32>
  %29 = arith.addi %6, %c3 : index
  %30 = vector.load %assume_align_0[%29, %4] : memref<64x64xf32>, vector<8xf32>
  %31 = vector.extract %9[0] : f32 from vector<4xf32>
  %32 = vector.broadcast %31 : f32 to vector<8xf32>
  %33 = vector.extract %7[0] : vector<8xf32> from vector<8x8xf32>
  %34 = vector.fma %32, %24, %33 : vector<8xf32>
  %35 = vector.extract %11[0] : f32 from vector<4xf32>
  %36 = vector.broadcast %35 : f32 to vector<8xf32>
  %37 = vector.extract %7[1] : vector<8xf32> from vector<8x8xf32>
  %38 = vector.fma %36, %24, %37 : vector<8xf32>
  %39 = vector.extract %13[0] : f32 from vector<4xf32>
  %40 = vector.broadcast %39 : f32 to vector<8xf32>
  %41 = vector.extract %7[2] : vector<8xf32> from vector<8x8xf32>
  %42 = vector.fma %40, %24, %41 : vector<8xf32>
  %43 = vector.extract %15[0] : f32 from vector<4xf32>
  %44 = vector.broadcast %43 : f32 to vector<8xf32>
  %45 = vector.extract %7[3] : vector<8xf32> from vector<8x8xf32>
  %46 = vector.fma %44, %24, %45 : vector<8xf32>
  %47 = vector.extract %17[0] : f32 from vector<4xf32>
  %48 = vector.broadcast %47 : f32 to vector<8xf32>
  %49 = vector.extract %7[4] : vector<8xf32> from vector<8x8xf32>
  %50 = vector.fma %48, %24, %49 : vector<8xf32>
  %51 = vector.extract %19[0] : f32 from vector<4xf32>
  %52 = vector.broadcast %51 : f32 to vector<8xf32>
  %53 = vector.extract %7[5] : vector<8xf32> from vector<8x8xf32>
  %54 = vector.fma %52, %24, %53 : vector<8xf32>
  %55 = vector.extract %21[0] : f32 from vector<4xf32>
  %56 = vector.broadcast %55 : f32 to vector<8xf32>
  %57 = vector.extract %7[6] : vector<8xf32> from vector<8x8xf32>
  %58 = vector.fma %56, %24, %57 : vector<8xf32>
  %59 = vector.extract %23[0] : f32 from vector<4xf32>
  %60 = vector.broadcast %59 : f32 to vector<8xf32>
  %61 = vector.extract %7[7] : vector<8xf32> from vector<8x8xf32>
  %62 = vector.fma %60, %24, %61 : vector<8xf32>
  %63 = vector.extract %9[1] : f32 from vector<4xf32>
  %64 = vector.broadcast %63 : f32 to vector<8xf32>
  %65 = vector.fma %64, %26, %34 : vector<8xf32>
  %66 = vector.extract %11[1] : f32 from vector<4xf32>
  %67 = vector.broadcast %66 : f32 to vector<8xf32>
  %68 = vector.fma %67, %26, %38 : vector<8xf32>
  %69 = vector.extract %13[1] : f32 from vector<4xf32>
  %70 = vector.broadcast %69 : f32 to vector<8xf32>
  %71 = vector.fma %70, %26, %42 : vector<8xf32>
  %72 = vector.extract %15[1] : f32 from vector<4xf32>
  %73 = vector.broadcast %72 : f32 to vector<8xf32>
  %74 = vector.fma %73, %26, %46 : vector<8xf32>
  %75 = vector.extract %17[1] : f32 from vector<4xf32>
  %76 = vector.broadcast %75 : f32 to vector<8xf32>
  %77 = vector.fma %76, %26, %50 : vector<8xf32>
  %78 = vector.extract %19[1] : f32 from vector<4xf32>
  %79 = vector.broadcast %78 : f32 to vector<8xf32>
  %80 = vector.fma %79, %26, %54 : vector<8xf32>
  %81 = vector.extract %21[1] : f32 from vector<4xf32>
  %82 = vector.broadcast %81 : f32 to vector<8xf32>
  %83 = vector.fma %82, %26, %58 : vector<8xf32>
  %84 = vector.extract %23[1] : f32 from vector<4xf32>
  %85 = vector.broadcast %84 : f32 to vector<8xf32>
  %86 = vector.fma %85, %26, %62 : vector<8xf32>
  %87 = vector.extract %9[2] : f32 from vector<4xf32>
  %88 = vector.broadcast %87 : f32 to vector<8xf32>
  %89 = vector.fma %88, %28, %65 : vector<8xf32>
  %90 = vector.extract %11[2] : f32 from vector<4xf32>
  %91 = vector.broadcast %90 : f32 to vector<8xf32>
  %92 = vector.fma %91, %28, %68 : vector<8xf32>
  %93 = vector.extract %13[2] : f32 from vector<4xf32>
  %94 = vector.broadcast %93 : f32 to vector<8xf32>
  %95 = vector.fma %94, %28, %71 : vector<8xf32>
  %96 = vector.extract %15[2] : f32 from vector<4xf32>
  %97 = vector.broadcast %96 : f32 to vector<8xf32>
  %98 = vector.fma %97, %28, %74 : vector<8xf32>
  %99 = vector.extract %17[2] : f32 from vector<4xf32>
  %100 = vector.broadcast %99 : f32 to vector<8xf32>
  %101 = vector.fma %100, %28, %77 : vector<8xf32>
  %102 = vector.extract %19[2] : f32 from vector<4xf32>
  %103 = vector.broadcast %102 : f32 to vector<8xf32>
  %104 = vector.fma %103, %28, %80 : vector<8xf32>
  %105 = vector.extract %21[2] : f32 from vector<4xf32>
  %106 = vector.broadcast %105 : f32 to vector<8xf32>
  %107 = vector.fma %106, %28, %83 : vector<8xf32>
  %108 = vector.extract %23[2] : f32 from vector<4xf32>
  %109 = vector.broadcast %108 : f32 to vector<8xf32>
  %110 = vector.fma %109, %28, %86 : vector<8xf32>
  %111 = vector.extract %9[3] : f32 from vector<4xf32>
  %112 = vector.broadcast %111 : f32 to vector<8xf32>
  %113 = vector.fma %112, %30, %89 : vector<8xf32>
  %114 = vector.extract %11[3] : f32 from vector<4xf32>
  %115 = vector.broadcast %114 : f32 to vector<8xf32>
  %116 = vector.fma %115, %30, %92 : vector<8xf32>
  %117 = vector.extract %13[3] : f32 from vector<4xf32>
  %118 = vector.broadcast %117 : f32 to vector<8xf32>
  %119 = vector.fma %118, %30, %95 : vector<8xf32>
  %120 = vector.extract %15[3] : f32 from vector<4xf32>
  %121 = vector.broadcast %120 : f32 to vector<8xf32>
  %122 = vector.fma %121, %30, %98 : vector<8xf32>
  %123 = vector.extract %17[3] : f32 from vector<4xf32>
  %124 = vector.broadcast %123 : f32 to vector<8xf32>
  %125 = vector.fma %124, %30, %101 : vector<8xf32>
  %126 = vector.extract %19[3] : f32 from vector<4xf32>
  %127 = vector.broadcast %126 : f32 to vector<8xf32>
  %128 = vector.fma %127, %30, %104 : vector<8xf32>
  %129 = vector.extract %21[3] : f32 from vector<4xf32>
  %130 = vector.broadcast %129 : f32 to vector<8xf32>
  %131 = vector.fma %130, %30, %107 : vector<8xf32>
  %132 = vector.extract %23[3] : f32 from vector<4xf32>
  %133 = vector.broadcast %132 : f32 to vector<8xf32>
  %134 = vector.fma %133, %30, %110 : vector<8xf32>
  %135:8 = vector.to_elements %113 : vector<8xf32>
  %136:8 = vector.to_elements %116 : vector<8xf32>
  %137:8 = vector.to_elements %119 : vector<8xf32>
  %138:8 = vector.to_elements %122 : vector<8xf32>
  %139:8 = vector.to_elements %125 : vector<8xf32>
  %140:8 = vector.to_elements %128 : vector<8xf32>
  %141:8 = vector.to_elements %131 : vector<8xf32>
  %142:8 = vector.to_elements %134 : vector<8xf32>
  %143 = vector.from_elements %135#0, %135#1, %135#2, %135#3, %135#4, %135#5, %135#6, %135#7, %136#0, %136#1, %136#2, %136#3, %136#4, %136#5, %136#6, %136#7, %137#0, %137#1, %137#2, %137#3, %137#4, %137#5, %137#6, %137#7, %138#0, %138#1, %138#2, %138#3, %138#4, %138#5, %138#6, %138#7, %139#0, %139#1, %139#2, %139#3, %139#4, %139#5, %139#6, %139#7, %140#0, %140#1, %140#2, %140#3, %140#4, %140#5, %140#6, %140#7, %141#0, %141#1, %141#2, %141#3, %141#4, %141#5, %141#6, %141#7, %142#0, %142#1, %142#2, %142#3, %142#4, %142#5, %142#6, %142#7 : vector<8x8xf32>
  %144 = arith.addi %6, %c4 : index
  cf.br ^bb3(%144, %143 : index, vector<8x8xf32>)
^bb5:  // pred: ^bb3
  %145 = vector.extract %7[0] : vector<8xf32> from vector<8x8xf32>
  vector.store %145, %assume_align_1[%3, %4] : memref<64x64xf32>, vector<8xf32>
  %146 = vector.extract %7[1] : vector<8xf32> from vector<8x8xf32>
  %147 = affine.apply affine_map<()[s0] -> (s0 + 1)>()[%3]
  vector.store %146, %assume_align_1[%147, %4] : memref<64x64xf32>, vector<8xf32>
  %148 = vector.extract %7[2] : vector<8xf32> from vector<8x8xf32>
  %149 = affine.apply affine_map<()[s0] -> (s0 + 2)>()[%3]
  vector.store %148, %assume_align_1[%149, %4] : memref<64x64xf32>, vector<8xf32>
  %150 = vector.extract %7[3] : vector<8xf32> from vector<8x8xf32>
  %151 = affine.apply affine_map<()[s0] -> (s0 + 3)>()[%3]
  vector.store %150, %assume_align_1[%151, %4] : memref<64x64xf32>, vector<8xf32>
  %152 = vector.extract %7[4] : vector<8xf32> from vector<8x8xf32>
  %153 = affine.apply affine_map<()[s0] -> (s0 + 4)>()[%3]
  vector.store %152, %assume_align_1[%153, %4] : memref<64x64xf32>, vector<8xf32>
  %154 = vector.extract %7[5] : vector<8xf32> from vector<8x8xf32>
  %155 = affine.apply affine_map<()[s0] -> (s0 + 5)>()[%3]
  vector.store %154, %assume_align_1[%155, %4] : memref<64x64xf32>, vector<8xf32>
  %156 = vector.extract %7[6] : vector<8xf32> from vector<8x8xf32>
  %157 = affine.apply affine_map<()[s0] -> (s0 + 6)>()[%3]
  vector.store %156, %assume_align_1[%157, %4] : memref<64x64xf32>, vector<8xf32>
  %158 = vector.extract %7[7] : vector<8xf32> from vector<8x8xf32>
  %159 = affine.apply affine_map<()[s0] -> (s0 + 7)>()[%3]
  vector.store %158, %assume_align_1[%159, %4] : memref<64x64xf32>, vector<8xf32>
  %160 = arith.addi %4, %c8 : index
  cf.br ^bb1(%160 : index)
^bb6:  // pred: ^bb1
  return
}

