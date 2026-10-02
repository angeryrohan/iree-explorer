// -----// IR Dump After IREEAffineExpandIndexOpsPass: iree-affine-expand-index-ops //----- //
#executable_target_embedded_elf_arm_64 = #hal.executable.target<"llvm-cpu", "embedded-elf-arm_64", {cpu = "generic", cpu_features = "+reserve-x18", data_layout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-Fn32", iree.encoding.resolver = #iree_cpu.cpu_encoding_resolver<>, max_stack_allocation_size = 32768 : i64, native_vector_size = 16 : i64, target_triple = "arm64-unknown-unknown-eabi-elf"}>
#pipeline_layout = #hal.pipeline.layout<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>
module {
  util.global private @__device_0 : !hal.device
  util.initializer {
    %c18_i32 = arith.constant 18 : i32
    %false = arith.constant false
    %c0 = arith.constant 0 : index
    %c1 = arith.constant 1 : index
    %0 = util.null : !hal.device
    %device_count = hal.devices.count : index
    %1:3 = scf.while (%arg0 = %c0, %arg1 = %c0, %arg2 = %0) : (index, index, !hal.device) -> (index, index, !hal.device) {
      %3 = util.cmp.eq %arg2, %0 : !hal.device
      %4 = arith.cmpi slt, %arg0, %device_count : index
      %5 = arith.andi %3, %4 : i1
      scf.condition(%5) %arg0, %arg1, %arg2 : index, index, !hal.device
    } do {
    ^bb0(%arg0: index, %arg1: index, %arg2: !hal.device):
      %device_n = hal.devices.get %arg0 : !hal.device
      %ok, %value = hal.device.query<%device_n : !hal.device> key("hal.device.id" :: "local*") : i1, i1 = false
      %3 = scf.if %value -> (i1) {
        %ok_0, %value_1 = hal.device.query<%device_n : !hal.device> key("hal.executable.format" :: "embedded-elf-arm_64") : i1, i1 = false
        scf.yield %value_1 : i1
      } else {
        scf.yield %false : i1
      }
      %4 = arith.cmpi eq, %arg1, %c0 : index
      %5 = arith.select %3, %c1, %c0 : index
      %6 = arith.addi %arg1, %5 : index
      %7 = arith.andi %3, %4 : i1
      %8 = arith.select %7, %device_n, %0 : !hal.device
      %9 = arith.addi %arg0, %c1 : index
      scf.yield %9, %6, %8 : index, index, !hal.device
    }
    %2 = util.cmp.eq %1#2, %0 : !hal.device
    scf.if %2 {
      util.status.check_ok %c18_i32, "HAL device `__device_0` not found or unavailable: #hal.device.target<\22local\22, [#hal.executable.target<\22llvm-cpu\22, \22embedded-elf-arm_64\22, {cpu = \22generic\22, cpu_features = \22+reserve-x18\22, data_layout = \22e-m:e-p270:32:32-p271:32:32-p272:64:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-Fn32\22, iree.encoding.resolver = #iree_cpu.cpu_encoding_resolver<>, max_stack_allocation_size = 32768 : i64, native_vector_size = 16 : i64, target_triple = \22arm64-unknown-unknown-eabi-elf\22}>]>"
    }
    util.global.store %1#2, @__device_0 : !hal.device
    util.return
  }
  util.global private @__device_0_query_0_hal_executable_format_embedded_elf_arm_64 : i1
  util.initializer {
    %__device_0 = util.global.load @__device_0 : !hal.device
    %ok, %value = hal.device.query<%__device_0 : !hal.device> key("hal.executable.format" :: "embedded-elf-arm_64") : i1, i1 = false
    util.global.store %value, @__device_0_query_0_hal_executable_format_embedded_elf_arm_64 : i1
    util.return
  }
  util.global private @__device_0_executable_0_matmul_dispatch_0 : !hal.executable
  util.initializer {
    %c-1_i64 = arith.constant -1 : i64
    %c-1 = arith.constant -1 : index
    %c0 = arith.constant 0 : index
    %c14_i32 = arith.constant 14 : i32
    %0 = util.null : !hal.executable
    %__device_0_query_0_hal_executable_format_embedded_elf_arm_64 = util.global.load @__device_0_query_0_hal_executable_format_embedded_elf_arm_64 : i1
    %__device_0 = util.global.load @__device_0 : !hal.device
    %1 = arith.select %__device_0_query_0_hal_executable_format_embedded_elf_arm_64, %c0, %c-1 : index
    %2 = arith.cmpi eq, %1, %c0 : index
    %3 = scf.if %2 -> (!hal.executable) {
      %executable = hal.executable.create device(%__device_0 : !hal.device) affinity(%c-1_i64) target(@matmul_dispatch_0::@embedded_elf_arm_64) : !hal.executable
      scf.yield %executable : !hal.executable
    } else {
      util.status.check_ok %c14_i32, "HAL device `__device_0` does not support any variant of executable `matmul_dispatch_0`; available formats: [embedded-elf-arm_64]"
      scf.yield %0 : !hal.executable
    }
    util.global.store %3, @__device_0_executable_0_matmul_dispatch_0 : !hal.executable
    util.return
  }
  hal.executable private @matmul_dispatch_0 {
    hal.executable.variant public @embedded_elf_arm_64 target(#executable_target_embedded_elf_arm_64) {
      hal.executable.export public @matmul_dispatch_0_matmul_64x64x64_f32 ordinal(0) layout(#pipeline_layout) attributes {workgroup_size = [1 : index, 1 : index, 1 : index]}
      builtin.module attributes {llvm.data_layout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-Fn32", llvm.target_triple = "arm64-unknown-unknown-eabi-elf"} {
        llvm.func @matmul_dispatch_0_matmul_64x64x64_f32(%arg0: !llvm.ptr {llvm.align = 16 : i64, llvm.noalias, llvm.nonnull, llvm.noundef}, %arg1: !llvm.ptr {llvm.align = 16 : i64, llvm.noalias, llvm.nonnull, llvm.noundef}, %arg2: !llvm.ptr {llvm.align = 16 : i64, llvm.noalias, llvm.nonnull, llvm.noundef}) -> i32 {
          %0 = llvm.mlir.constant(3 : i64) : i64
          %1 = llvm.mlir.constant(2 : i64) : i64
          %2 = llvm.mlir.constant(1 : i64) : i64
          %3 = llvm.mlir.constant(0 : i32) : i32
          %4 = llvm.mlir.poison : vector<8xf32>
          %5 = llvm.mlir.constant(0 : i64) : i64
          %6 = llvm.mlir.constant(true) : i1
          %7 = llvm.mlir.poison : !llvm.array<8 x vector<8xf32>>
          %8 = llvm.mlir.constant(7 : index) : i64
          %9 = llvm.mlir.constant(6 : index) : i64
          %10 = llvm.mlir.constant(5 : index) : i64
          %11 = llvm.mlir.constant(3 : index) : i64
          %12 = llvm.mlir.constant(2 : index) : i64
          %13 = llvm.mlir.constant(1 : index) : i64
          %14 = llvm.mlir.constant(dense<0.000000e+00> : vector<8x8xf32>) : !llvm.array<8 x vector<8xf32>>
          %15 = llvm.mlir.constant(8 : index) : i64
          %16 = llvm.mlir.constant(4 : index) : i64
          %17 = llvm.mlir.constant(64 : index) : i64
          %18 = llvm.mlir.constant(0 : index) : i64
          %19 = llvm.load %arg1 : !llvm.ptr -> !llvm.struct<"iree_hal_executable_dispatch_state_v0_t", (i32, i32, i16, i16, i32, i32, i16, i8, i8, ptr, ptr, ptr)>
          %20 = llvm.extractvalue %19[10] : !llvm.struct<"iree_hal_executable_dispatch_state_v0_t", (i32, i32, i16, i16, i32, i32, i16, i8, i8, ptr, ptr, ptr)> 
          %21 = llvm.load %20 : !llvm.ptr -> !llvm.ptr
          llvm.intr.assume %6 ["align"(%21, %17 : !llvm.ptr, i64)] : i1
          %22 = llvm.load %arg1 : !llvm.ptr -> !llvm.struct<"iree_hal_executable_dispatch_state_v0_t", (i32, i32, i16, i16, i32, i32, i16, i8, i8, ptr, ptr, ptr)>
          %23 = llvm.extractvalue %22[10] : !llvm.struct<"iree_hal_executable_dispatch_state_v0_t", (i32, i32, i16, i16, i32, i32, i16, i8, i8, ptr, ptr, ptr)> 
          %24 = llvm.getelementptr %23[1] : (!llvm.ptr) -> !llvm.ptr, !llvm.ptr
          %25 = llvm.load %24 : !llvm.ptr -> !llvm.ptr
          llvm.intr.assume %6 ["align"(%25, %17 : !llvm.ptr, i64)] : i1
          %26 = llvm.load %arg1 : !llvm.ptr -> !llvm.struct<"iree_hal_executable_dispatch_state_v0_t", (i32, i32, i16, i16, i32, i32, i16, i8, i8, ptr, ptr, ptr)>
          %27 = llvm.extractvalue %26[10] : !llvm.struct<"iree_hal_executable_dispatch_state_v0_t", (i32, i32, i16, i16, i32, i32, i16, i8, i8, ptr, ptr, ptr)> 
          %28 = llvm.getelementptr %27[2] : (!llvm.ptr) -> !llvm.ptr, !llvm.ptr
          %29 = llvm.load %28 : !llvm.ptr -> !llvm.ptr
          llvm.intr.assume %6 ["align"(%29, %17 : !llvm.ptr, i64)] : i1
          %30 = llvm.load %arg2 : !llvm.ptr -> !llvm.struct<"iree_hal_executable_workgroup_state_v0_t", (i32, i32, i16, i16, i32, ptr, i32)>
          %31 = llvm.extractvalue %30[0] : !llvm.struct<"iree_hal_executable_workgroup_state_v0_t", (i32, i32, i16, i16, i32, ptr, i32)> 
          %32 = llvm.zext %31 : i32 to i64
          %33 = llvm.mul %32, %15 overflow<nsw> : i64
          llvm.br ^bb1(%18 : i64)
        ^bb1(%34: i64):  // 2 preds: ^bb0, ^bb4
          %35 = llvm.icmp "slt" %34, %17 : i64
          llvm.cond_br %35, ^bb2(%18, %14 : i64, !llvm.array<8 x vector<8xf32>>), ^bb5
        ^bb2(%36: i64, %37: !llvm.array<8 x vector<8xf32>>):  // 2 preds: ^bb1, ^bb3
          %38 = llvm.icmp "slt" %36, %17 : i64
          llvm.cond_br %38, ^bb3, ^bb4
        ^bb3:  // pred: ^bb2
          %39 = llvm.mul %33, %17 : i64
          %40 = llvm.add %39, %36 : i64
          %41 = llvm.getelementptr %21[%40] : (!llvm.ptr, i64) -> !llvm.ptr, f32
          %42 = llvm.load %41 {alignment = 4 : i64} : !llvm.ptr -> vector<4xf32>
          %43 = llvm.add %33, %13 : i64
          %44 = llvm.mul %43, %17 : i64
          %45 = llvm.add %44, %36 : i64
          %46 = llvm.getelementptr %21[%45] : (!llvm.ptr, i64) -> !llvm.ptr, f32
          %47 = llvm.load %46 {alignment = 4 : i64} : !llvm.ptr -> vector<4xf32>
          %48 = llvm.add %33, %12 : i64
          %49 = llvm.mul %48, %17 : i64
          %50 = llvm.add %49, %36 : i64
          %51 = llvm.getelementptr %21[%50] : (!llvm.ptr, i64) -> !llvm.ptr, f32
          %52 = llvm.load %51 {alignment = 4 : i64} : !llvm.ptr -> vector<4xf32>
          %53 = llvm.add %33, %11 : i64
          %54 = llvm.mul %53, %17 : i64
          %55 = llvm.add %54, %36 : i64
          %56 = llvm.getelementptr %21[%55] : (!llvm.ptr, i64) -> !llvm.ptr, f32
          %57 = llvm.load %56 {alignment = 4 : i64} : !llvm.ptr -> vector<4xf32>
          %58 = llvm.add %33, %16 : i64
          %59 = llvm.mul %58, %17 : i64
          %60 = llvm.add %59, %36 : i64
          %61 = llvm.getelementptr %21[%60] : (!llvm.ptr, i64) -> !llvm.ptr, f32
          %62 = llvm.load %61 {alignment = 4 : i64} : !llvm.ptr -> vector<4xf32>
          %63 = llvm.add %33, %10 : i64
          %64 = llvm.mul %63, %17 : i64
          %65 = llvm.add %64, %36 : i64
          %66 = llvm.getelementptr %21[%65] : (!llvm.ptr, i64) -> !llvm.ptr, f32
          %67 = llvm.load %66 {alignment = 4 : i64} : !llvm.ptr -> vector<4xf32>
          %68 = llvm.add %33, %9 : i64
          %69 = llvm.mul %68, %17 : i64
          %70 = llvm.add %69, %36 : i64
          %71 = llvm.getelementptr %21[%70] : (!llvm.ptr, i64) -> !llvm.ptr, f32
          %72 = llvm.load %71 {alignment = 4 : i64} : !llvm.ptr -> vector<4xf32>
          %73 = llvm.add %33, %8 : i64
          %74 = llvm.mul %73, %17 : i64
          %75 = llvm.add %74, %36 : i64
          %76 = llvm.getelementptr %21[%75] : (!llvm.ptr, i64) -> !llvm.ptr, f32
          %77 = llvm.load %76 {alignment = 4 : i64} : !llvm.ptr -> vector<4xf32>
          %78 = llvm.mul %36, %17 : i64
          %79 = llvm.add %78, %34 : i64
          %80 = llvm.getelementptr %25[%79] : (!llvm.ptr, i64) -> !llvm.ptr, f32
          %81 = llvm.load %80 {alignment = 4 : i64} : !llvm.ptr -> vector<8xf32>
          %82 = llvm.add %36, %13 : i64
          %83 = llvm.mul %82, %17 : i64
          %84 = llvm.add %83, %34 : i64
          %85 = llvm.getelementptr %25[%84] : (!llvm.ptr, i64) -> !llvm.ptr, f32
          %86 = llvm.load %85 {alignment = 4 : i64} : !llvm.ptr -> vector<8xf32>
          %87 = llvm.add %36, %12 : i64
          %88 = llvm.mul %87, %17 : i64
          %89 = llvm.add %88, %34 : i64
          %90 = llvm.getelementptr %25[%89] : (!llvm.ptr, i64) -> !llvm.ptr, f32
          %91 = llvm.load %90 {alignment = 4 : i64} : !llvm.ptr -> vector<8xf32>
          %92 = llvm.add %36, %11 : i64
          %93 = llvm.mul %92, %17 : i64
          %94 = llvm.add %93, %34 : i64
          %95 = llvm.getelementptr %25[%94] : (!llvm.ptr, i64) -> !llvm.ptr, f32
          %96 = llvm.load %95 {alignment = 4 : i64} : !llvm.ptr -> vector<8xf32>
          %97 = llvm.extractelement %42[%5 : i64] : vector<4xf32>
          %98 = llvm.insertelement %97, %4[%3 : i32] : vector<8xf32>
          %99 = llvm.shufflevector %98, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %100 = llvm.extractvalue %37[0] : !llvm.array<8 x vector<8xf32>> 
          %101 = llvm.intr.fmuladd(%99, %81, %100) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %102 = llvm.extractelement %47[%5 : i64] : vector<4xf32>
          %103 = llvm.insertelement %102, %4[%3 : i32] : vector<8xf32>
          %104 = llvm.shufflevector %103, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %105 = llvm.extractvalue %37[1] : !llvm.array<8 x vector<8xf32>> 
          %106 = llvm.intr.fmuladd(%104, %81, %105) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %107 = llvm.extractelement %52[%5 : i64] : vector<4xf32>
          %108 = llvm.insertelement %107, %4[%3 : i32] : vector<8xf32>
          %109 = llvm.shufflevector %108, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %110 = llvm.extractvalue %37[2] : !llvm.array<8 x vector<8xf32>> 
          %111 = llvm.intr.fmuladd(%109, %81, %110) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %112 = llvm.extractelement %57[%5 : i64] : vector<4xf32>
          %113 = llvm.insertelement %112, %4[%3 : i32] : vector<8xf32>
          %114 = llvm.shufflevector %113, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %115 = llvm.extractvalue %37[3] : !llvm.array<8 x vector<8xf32>> 
          %116 = llvm.intr.fmuladd(%114, %81, %115) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %117 = llvm.extractelement %62[%5 : i64] : vector<4xf32>
          %118 = llvm.insertelement %117, %4[%3 : i32] : vector<8xf32>
          %119 = llvm.shufflevector %118, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %120 = llvm.extractvalue %37[4] : !llvm.array<8 x vector<8xf32>> 
          %121 = llvm.intr.fmuladd(%119, %81, %120) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %122 = llvm.extractelement %67[%5 : i64] : vector<4xf32>
          %123 = llvm.insertelement %122, %4[%3 : i32] : vector<8xf32>
          %124 = llvm.shufflevector %123, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %125 = llvm.extractvalue %37[5] : !llvm.array<8 x vector<8xf32>> 
          %126 = llvm.intr.fmuladd(%124, %81, %125) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %127 = llvm.extractelement %72[%5 : i64] : vector<4xf32>
          %128 = llvm.insertelement %127, %4[%3 : i32] : vector<8xf32>
          %129 = llvm.shufflevector %128, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %130 = llvm.extractvalue %37[6] : !llvm.array<8 x vector<8xf32>> 
          %131 = llvm.intr.fmuladd(%129, %81, %130) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %132 = llvm.extractelement %77[%5 : i64] : vector<4xf32>
          %133 = llvm.insertelement %132, %4[%3 : i32] : vector<8xf32>
          %134 = llvm.shufflevector %133, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %135 = llvm.extractvalue %37[7] : !llvm.array<8 x vector<8xf32>> 
          %136 = llvm.intr.fmuladd(%134, %81, %135) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %137 = llvm.extractelement %42[%2 : i64] : vector<4xf32>
          %138 = llvm.insertelement %137, %4[%3 : i32] : vector<8xf32>
          %139 = llvm.shufflevector %138, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %140 = llvm.intr.fmuladd(%139, %86, %101) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %141 = llvm.extractelement %47[%2 : i64] : vector<4xf32>
          %142 = llvm.insertelement %141, %4[%3 : i32] : vector<8xf32>
          %143 = llvm.shufflevector %142, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %144 = llvm.intr.fmuladd(%143, %86, %106) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %145 = llvm.extractelement %52[%2 : i64] : vector<4xf32>
          %146 = llvm.insertelement %145, %4[%3 : i32] : vector<8xf32>
          %147 = llvm.shufflevector %146, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %148 = llvm.intr.fmuladd(%147, %86, %111) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %149 = llvm.extractelement %57[%2 : i64] : vector<4xf32>
          %150 = llvm.insertelement %149, %4[%3 : i32] : vector<8xf32>
          %151 = llvm.shufflevector %150, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %152 = llvm.intr.fmuladd(%151, %86, %116) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %153 = llvm.extractelement %62[%2 : i64] : vector<4xf32>
          %154 = llvm.insertelement %153, %4[%3 : i32] : vector<8xf32>
          %155 = llvm.shufflevector %154, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %156 = llvm.intr.fmuladd(%155, %86, %121) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %157 = llvm.extractelement %67[%2 : i64] : vector<4xf32>
          %158 = llvm.insertelement %157, %4[%3 : i32] : vector<8xf32>
          %159 = llvm.shufflevector %158, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %160 = llvm.intr.fmuladd(%159, %86, %126) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %161 = llvm.extractelement %72[%2 : i64] : vector<4xf32>
          %162 = llvm.insertelement %161, %4[%3 : i32] : vector<8xf32>
          %163 = llvm.shufflevector %162, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %164 = llvm.intr.fmuladd(%163, %86, %131) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %165 = llvm.extractelement %77[%2 : i64] : vector<4xf32>
          %166 = llvm.insertelement %165, %4[%3 : i32] : vector<8xf32>
          %167 = llvm.shufflevector %166, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %168 = llvm.intr.fmuladd(%167, %86, %136) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %169 = llvm.extractelement %42[%1 : i64] : vector<4xf32>
          %170 = llvm.insertelement %169, %4[%3 : i32] : vector<8xf32>
          %171 = llvm.shufflevector %170, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %172 = llvm.intr.fmuladd(%171, %91, %140) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %173 = llvm.extractelement %47[%1 : i64] : vector<4xf32>
          %174 = llvm.insertelement %173, %4[%3 : i32] : vector<8xf32>
          %175 = llvm.shufflevector %174, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %176 = llvm.intr.fmuladd(%175, %91, %144) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %177 = llvm.extractelement %52[%1 : i64] : vector<4xf32>
          %178 = llvm.insertelement %177, %4[%3 : i32] : vector<8xf32>
          %179 = llvm.shufflevector %178, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %180 = llvm.intr.fmuladd(%179, %91, %148) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %181 = llvm.extractelement %57[%1 : i64] : vector<4xf32>
          %182 = llvm.insertelement %181, %4[%3 : i32] : vector<8xf32>
          %183 = llvm.shufflevector %182, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %184 = llvm.intr.fmuladd(%183, %91, %152) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %185 = llvm.extractelement %62[%1 : i64] : vector<4xf32>
          %186 = llvm.insertelement %185, %4[%3 : i32] : vector<8xf32>
          %187 = llvm.shufflevector %186, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %188 = llvm.intr.fmuladd(%187, %91, %156) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %189 = llvm.extractelement %67[%1 : i64] : vector<4xf32>
          %190 = llvm.insertelement %189, %4[%3 : i32] : vector<8xf32>
          %191 = llvm.shufflevector %190, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %192 = llvm.intr.fmuladd(%191, %91, %160) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %193 = llvm.extractelement %72[%1 : i64] : vector<4xf32>
          %194 = llvm.insertelement %193, %4[%3 : i32] : vector<8xf32>
          %195 = llvm.shufflevector %194, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %196 = llvm.intr.fmuladd(%195, %91, %164) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %197 = llvm.extractelement %77[%1 : i64] : vector<4xf32>
          %198 = llvm.insertelement %197, %4[%3 : i32] : vector<8xf32>
          %199 = llvm.shufflevector %198, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %200 = llvm.intr.fmuladd(%199, %91, %168) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %201 = llvm.extractelement %42[%0 : i64] : vector<4xf32>
          %202 = llvm.insertelement %201, %4[%3 : i32] : vector<8xf32>
          %203 = llvm.shufflevector %202, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %204 = llvm.intr.fmuladd(%203, %96, %172) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %205 = llvm.extractelement %47[%0 : i64] : vector<4xf32>
          %206 = llvm.insertelement %205, %4[%3 : i32] : vector<8xf32>
          %207 = llvm.shufflevector %206, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %208 = llvm.intr.fmuladd(%207, %96, %176) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %209 = llvm.extractelement %52[%0 : i64] : vector<4xf32>
          %210 = llvm.insertelement %209, %4[%3 : i32] : vector<8xf32>
          %211 = llvm.shufflevector %210, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %212 = llvm.intr.fmuladd(%211, %96, %180) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %213 = llvm.extractelement %57[%0 : i64] : vector<4xf32>
          %214 = llvm.insertelement %213, %4[%3 : i32] : vector<8xf32>
          %215 = llvm.shufflevector %214, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %216 = llvm.intr.fmuladd(%215, %96, %184) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %217 = llvm.extractelement %62[%0 : i64] : vector<4xf32>
          %218 = llvm.insertelement %217, %4[%3 : i32] : vector<8xf32>
          %219 = llvm.shufflevector %218, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %220 = llvm.intr.fmuladd(%219, %96, %188) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %221 = llvm.extractelement %67[%0 : i64] : vector<4xf32>
          %222 = llvm.insertelement %221, %4[%3 : i32] : vector<8xf32>
          %223 = llvm.shufflevector %222, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %224 = llvm.intr.fmuladd(%223, %96, %192) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %225 = llvm.extractelement %72[%0 : i64] : vector<4xf32>
          %226 = llvm.insertelement %225, %4[%3 : i32] : vector<8xf32>
          %227 = llvm.shufflevector %226, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %228 = llvm.intr.fmuladd(%227, %96, %196) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %229 = llvm.extractelement %77[%0 : i64] : vector<4xf32>
          %230 = llvm.insertelement %229, %4[%3 : i32] : vector<8xf32>
          %231 = llvm.shufflevector %230, %4 [0, 0, 0, 0, 0, 0, 0, 0] : vector<8xf32> 
          %232 = llvm.intr.fmuladd(%231, %96, %200) : (vector<8xf32>, vector<8xf32>, vector<8xf32>) -> vector<8xf32>
          %233 = llvm.insertvalue %204, %7[0] : !llvm.array<8 x vector<8xf32>> 
          %234 = llvm.insertvalue %208, %233[1] : !llvm.array<8 x vector<8xf32>> 
          %235 = llvm.insertvalue %212, %234[2] : !llvm.array<8 x vector<8xf32>> 
          %236 = llvm.insertvalue %216, %235[3] : !llvm.array<8 x vector<8xf32>> 
          %237 = llvm.insertvalue %220, %236[4] : !llvm.array<8 x vector<8xf32>> 
          %238 = llvm.insertvalue %224, %237[5] : !llvm.array<8 x vector<8xf32>> 
          %239 = llvm.insertvalue %228, %238[6] : !llvm.array<8 x vector<8xf32>> 
          %240 = llvm.insertvalue %232, %239[7] : !llvm.array<8 x vector<8xf32>> 
          %241 = llvm.add %36, %16 : i64
          llvm.br ^bb2(%241, %240 : i64, !llvm.array<8 x vector<8xf32>>)
        ^bb4:  // pred: ^bb2
          %242 = llvm.extractvalue %37[0] : !llvm.array<8 x vector<8xf32>> 
          %243 = llvm.mul %33, %17 : i64
          %244 = llvm.add %243, %34 : i64
          %245 = llvm.getelementptr %29[%244] : (!llvm.ptr, i64) -> !llvm.ptr, f32
          llvm.store %242, %245 {alignment = 4 : i64} : vector<8xf32>, !llvm.ptr
          %246 = llvm.extractvalue %37[1] : !llvm.array<8 x vector<8xf32>> 
          %247 = llvm.add %33, %13 : i64
          %248 = llvm.mul %247, %17 : i64
          %249 = llvm.add %248, %34 : i64
          %250 = llvm.getelementptr %29[%249] : (!llvm.ptr, i64) -> !llvm.ptr, f32
          llvm.store %246, %250 {alignment = 4 : i64} : vector<8xf32>, !llvm.ptr
          %251 = llvm.extractvalue %37[2] : !llvm.array<8 x vector<8xf32>> 
          %252 = llvm.add %33, %12 : i64
          %253 = llvm.mul %252, %17 : i64
          %254 = llvm.add %253, %34 : i64
          %255 = llvm.getelementptr %29[%254] : (!llvm.ptr, i64) -> !llvm.ptr, f32
          llvm.store %251, %255 {alignment = 4 : i64} : vector<8xf32>, !llvm.ptr
          %256 = llvm.extractvalue %37[3] : !llvm.array<8 x vector<8xf32>> 
          %257 = llvm.add %33, %11 : i64
          %258 = llvm.mul %257, %17 : i64
          %259 = llvm.add %258, %34 : i64
          %260 = llvm.getelementptr %29[%259] : (!llvm.ptr, i64) -> !llvm.ptr, f32
          llvm.store %256, %260 {alignment = 4 : i64} : vector<8xf32>, !llvm.ptr
          %261 = llvm.extractvalue %37[4] : !llvm.array<8 x vector<8xf32>> 
          %262 = llvm.add %33, %16 : i64
          %263 = llvm.mul %262, %17 : i64
          %264 = llvm.add %263, %34 : i64
          %265 = llvm.getelementptr %29[%264] : (!llvm.ptr, i64) -> !llvm.ptr, f32
          llvm.store %261, %265 {alignment = 4 : i64} : vector<8xf32>, !llvm.ptr
          %266 = llvm.extractvalue %37[5] : !llvm.array<8 x vector<8xf32>> 
          %267 = llvm.add %33, %10 : i64
          %268 = llvm.mul %267, %17 : i64
          %269 = llvm.add %268, %34 : i64
          %270 = llvm.getelementptr %29[%269] : (!llvm.ptr, i64) -> !llvm.ptr, f32
          llvm.store %266, %270 {alignment = 4 : i64} : vector<8xf32>, !llvm.ptr
          %271 = llvm.extractvalue %37[6] : !llvm.array<8 x vector<8xf32>> 
          %272 = llvm.add %33, %9 : i64
          %273 = llvm.mul %272, %17 : i64
          %274 = llvm.add %273, %34 : i64
          %275 = llvm.getelementptr %29[%274] : (!llvm.ptr, i64) -> !llvm.ptr, f32
          llvm.store %271, %275 {alignment = 4 : i64} : vector<8xf32>, !llvm.ptr
          %276 = llvm.extractvalue %37[7] : !llvm.array<8 x vector<8xf32>> 
          %277 = llvm.add %33, %8 : i64
          %278 = llvm.mul %277, %17 : i64
          %279 = llvm.add %278, %34 : i64
          %280 = llvm.getelementptr %29[%279] : (!llvm.ptr, i64) -> !llvm.ptr, f32
          llvm.store %276, %280 {alignment = 4 : i64} : vector<8xf32>, !llvm.ptr
          %281 = llvm.add %34, %15 : i64
          llvm.br ^bb1(%281 : i64)
        ^bb5:  // pred: ^bb1
          llvm.return %3 : i32
        }
      }
    }
  }
  util.func private @__matmul_memoize_apply(%arg0: !hal.device, %arg1: i64) -> !hal.command_buffer attributes {inlining_policy = #util.inline.never} {
    %c16384 = arith.constant 16384 : index
    %c2 = arith.constant 2 : index
    %c1 = arith.constant 1 : index
    %c0 = arith.constant 0 : index
    %c3 = arith.constant 3 : index
    %c8 = arith.constant 8 : index
    %__device_0_executable_0_matmul_dispatch_0 = util.global.load immutable @__device_0_executable_0_matmul_dispatch_0 : !hal.executable
    %cmd = hal.command_buffer.create device(%arg0 : !hal.device) mode("None") categories("Transfer|Dispatch") affinity(%arg1) bindings(%c3) : !hal.command_buffer
    %function_id = hal.executable.lookup.function target(%__device_0_executable_0_matmul_dispatch_0 : !hal.executable) function(@matmul_dispatch_0::@embedded_elf_arm_64::@matmul_dispatch_0_matmul_64x64x64_f32) : i64
    hal.command_buffer.dispatch<%cmd : !hal.command_buffer> target(%__device_0_executable_0_matmul_dispatch_0 : !hal.executable)[%function_id] workgroups([%c8, %c1, %c1]) bindings([
      (%c0 : index)[%c0, %c16384], 
      (%c1 : index)[%c0, %c16384], 
      (%c2 : index)[%c0, %c16384]
    ]) flags("None")
    hal.command_buffer.execution_barrier<%cmd : !hal.command_buffer> source("Dispatch|Transfer|CommandRetire") target("CommandIssue|Dispatch|Transfer") flags("None")
    hal.command_buffer.finalize<%cmd : !hal.command_buffer>
    util.return %cmd : !hal.command_buffer
  }
  util.global private @__matmul_memoize_result_0_device_0 : !hal.command_buffer
  util.initializer {
    %c-1_i64 = arith.constant -1 : i64
    %__device_0 = util.global.load immutable @__device_0 : !hal.device
    %0 = util.call @__matmul_memoize_apply(%__device_0, %c-1_i64) : (!hal.device, i64) -> !hal.command_buffer
    util.global.store %0, @__matmul_memoize_result_0_device_0 : !hal.command_buffer
    util.return
  }
  util.func private @__matmul_memoize_lookup(%arg0: !hal.device, %arg1: i64) -> !hal.command_buffer {
    %0 = util.null : !hal.command_buffer
    %__device_0 = util.global.load immutable @__device_0 : !hal.device
    %1 = util.cmp.eq %arg0, %__device_0 : !hal.device
    %2 = scf.if %1 -> (!hal.command_buffer) {
      %__matmul_memoize_result_0_device_0 = util.global.load immutable @__matmul_memoize_result_0_device_0 : !hal.command_buffer
      scf.yield %__matmul_memoize_result_0_device_0 : !hal.command_buffer
    } else {
      scf.yield %0 : !hal.command_buffer
    }
    util.return %2 : !hal.command_buffer
  }
  util.func public @matmul(%arg0: !hal.buffer_view, %arg1: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @matmul(%input0: tensor<64x64xf32>, %input1: tensor<64x64xf32>) -> (%output0: tensor<64x64xf32>)"}} {
    %c-1_i32 = arith.constant -1 : i32
    %c0_i64 = arith.constant 0 : i64
    %0 = util.null : !hal.fence
    %c-1_i64 = arith.constant -1 : i64
    %c0 = arith.constant 0 : index
    %c16384 = arith.constant 16384 : index
    %c64 = arith.constant 64 : index
    %memory_type = hal.memory_type<"DeviceVisible|DeviceLocal"> : i32
    %buffer_usage = hal.buffer_usage<"TransferSource|TransferTarget|Transfer|DispatchStorageRead|DispatchStorageWrite|DispatchStorage"> : i32
    %__device_0 = util.global.load immutable @__device_0 : !hal.device
    %element_type_f32 = hal.element_type<f32> : i32
    %dense_row_major = hal.encoding_type<dense_row_major> : i32
    hal.buffer_view.assert<%arg0 : !hal.buffer_view> message("input0") shape([%c64, %c64]) type(%element_type_f32) encoding(%dense_row_major)
    %buffer = hal.buffer_view.buffer<%arg0 : !hal.buffer_view> : !hal.buffer
    %allocator = hal.device.allocator<%__device_0 : !hal.device> : !hal.allocator
    hal.buffer.assert<%buffer : !hal.buffer> message("tensor") allocator(%allocator : !hal.allocator) minimum_length(%c16384) type(DeviceVisible) usage("TransferSource|TransferTarget|Transfer|DispatchStorageRead|DispatchStorageWrite|DispatchStorage")
    hal.buffer_view.assert<%arg1 : !hal.buffer_view> message("input1") shape([%c64, %c64]) type(%element_type_f32) encoding(%dense_row_major)
    %buffer_0 = hal.buffer_view.buffer<%arg1 : !hal.buffer_view> : !hal.buffer
    hal.buffer.assert<%buffer_0 : !hal.buffer> message("tensor") allocator(%allocator : !hal.allocator) minimum_length(%c16384) type(DeviceVisible) usage("TransferSource|TransferTarget|Transfer|DispatchStorageRead|DispatchStorageWrite|DispatchStorage")
    %fence = hal.fence.create device(%__device_0 : !hal.device) flags("None") : !hal.fence
    %transient_buffer = hal.device.queue.alloca<%__device_0 : !hal.device> affinity(%c-1_i64) wait(%0) signal(%fence) pool(%c0_i64) type(%memory_type) usage(%buffer_usage) flags("None") : !hal.buffer{%c16384}
    %1 = util.call @__matmul_memoize_lookup(%__device_0, %c-1_i64) : (!hal.device, i64) -> !hal.command_buffer
    %fence_1 = hal.fence.create device(%__device_0 : !hal.device) flags("None") : !hal.fence
    hal.device.queue.execute.indirect<%__device_0 : !hal.device> affinity(%c-1_i64) wait(%fence) signal(%fence_1) commands(%1) bindings([
      (%buffer : !hal.buffer)[%c0, %c16384], 
      (%buffer_0 : !hal.buffer)[%c0, %c16384], 
      (%transient_buffer : !hal.buffer)[%c0, %c16384]
    ]) flags("None")
    %status = hal.fence.await until([%fence_1]) timeout_millis(%c-1_i32) flags("None") : i32
    util.status.check_ok %status, "failed to wait on timepoint"
    %view = hal.buffer_view.create buffer(%transient_buffer : !hal.buffer)[%c0, %c16384] shape([%c64, %c64]) type(%element_type_f32) encoding(%dense_row_major) : !hal.buffer_view
    util.return %view : !hal.buffer_view
  }
}


