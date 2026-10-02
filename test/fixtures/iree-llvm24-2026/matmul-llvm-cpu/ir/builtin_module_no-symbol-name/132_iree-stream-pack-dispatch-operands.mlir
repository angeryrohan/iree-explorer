// -----// IR Dump After PackDispatchOperandsPass: iree-stream-pack-dispatch-operands //----- //
#executable_target_embedded_elf_arm_64 = #hal.executable.target<"llvm-cpu", "embedded-elf-arm_64", {cpu = "generic", cpu_features = "+reserve-x18", data_layout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-Fn32", iree.encoding.resolver = #iree_cpu.cpu_encoding_resolver<>, max_stack_allocation_size = 32768 : i64, native_vector_size = 16 : i64, target_triple = "arm64-unknown-unknown-eabi-elf"}>
#device_target_local = #hal.device.target<"local", [#executable_target_embedded_elf_arm_64]> : !hal.device
module attributes {stream.affinity.default = #hal.device.affinity<@__device_0>} {
  util.global private @__device_0 = #device_target_local
  stream.executable private @matmul_dispatch_0 {
    stream.executable.export public @matmul_dispatch_0_matmul_64x64x64_f32 workgroups() -> (index, index, index) {
      %x, %y, %z = iree_tensor_ext.dispatch.workgroup_count_from_slice()
      stream.return %x, %y, %z : index, index, index
    }
    builtin.module {
      func.func @matmul_dispatch_0_matmul_64x64x64_f32(%arg0: !stream.binding {stream.alignment = 64 : index}, %arg1: !stream.binding {stream.alignment = 64 : index}, %arg2: !stream.binding {stream.alignment = 64 : index}, %arg3: i32, %arg4: i32, %arg5: i32, %arg6: i32, %arg7: i32, %arg8: i32) {
        %0 = arith.extui %arg3 : i32 to i64
        %1 = arith.extui %arg4 : i32 to i64
        %c32_i64 = arith.constant 32 : i64
        %2 = arith.shli %1, %c32_i64 : i64
        %3 = arith.ori %0, %2 : i64
        %4 = arith.index_castui %3 {stream.values = [0 : index]} : i64 to index
        %5 = arith.extui %arg5 : i32 to i64
        %6 = arith.extui %arg6 : i32 to i64
        %c32_i64_0 = arith.constant 32 : i64
        %7 = arith.shli %6, %c32_i64_0 : i64
        %8 = arith.ori %5, %7 : i64
        %9 = arith.index_castui %8 {stream.values = [0 : index]} : i64 to index
        %10 = arith.extui %arg7 : i32 to i64
        %11 = arith.extui %arg8 : i32 to i64
        %c32_i64_1 = arith.constant 32 : i64
        %12 = arith.shli %11, %c32_i64_1 : i64
        %13 = arith.ori %10, %12 : i64
        %14 = arith.index_castui %13 {stream.values = [0 : index]} : i64 to index
        %15:3 = util.assume.int 
            %4<umin = 0, umax = 0>, 
            %9<umin = 0, umax = 0>, 
            %14<umin = 0, umax = 0>
          : index, index, index
        %cst = arith.constant 0.000000e+00 : f32
        %c0 = arith.constant 0 : index
        %16 = stream.binding.subspan %arg0[%15#0] : !stream.binding -> !iree_tensor_ext.dispatch.tensor<readonly:tensor<64x64xf32>>
        %17 = stream.binding.subspan %arg1[%15#1] : !stream.binding -> !iree_tensor_ext.dispatch.tensor<readonly:tensor<64x64xf32>>
        %18 = stream.binding.subspan %arg2[%15#2] : !stream.binding -> !iree_tensor_ext.dispatch.tensor<writeonly:tensor<64x64xf32>>
        %19 = iree_tensor_ext.dispatch.tensor.load %16, offsets = [0, 0], sizes = [64, 64], strides = [1, 1] : !iree_tensor_ext.dispatch.tensor<readonly:tensor<64x64xf32>> -> tensor<64x64xf32>
        %20 = iree_tensor_ext.dispatch.tensor.load %17, offsets = [0, 0], sizes = [64, 64], strides = [1, 1] : !iree_tensor_ext.dispatch.tensor<readonly:tensor<64x64xf32>> -> tensor<64x64xf32>
        %21 = tensor.empty() : tensor<64x64xf32>
        %22 = linalg.fill ins(%cst : f32) outs(%21 : tensor<64x64xf32>) -> tensor<64x64xf32>
        %23 = linalg.matmul ins(%19, %20 : tensor<64x64xf32>, tensor<64x64xf32>) outs(%22 : tensor<64x64xf32>) -> tensor<64x64xf32>
        iree_tensor_ext.dispatch.tensor.store %23, %18, offsets = [0, 0], sizes = [64, 64], strides = [1, 1] : tensor<64x64xf32> -> !iree_tensor_ext.dispatch.tensor<writeonly:tensor<64x64xf32>>
        return
      }
    }
  }
  util.func public @matmul(%arg0: !hal.buffer_view, %arg1: !hal.buffer_view) -> !hal.buffer_view attributes {iree.abi.stub, iree.reflection = {iree.abi.declaration = "sync func @matmul(%input0: tensor<64x64xf32>, %input1: tensor<64x64xf32>) -> (%output0: tensor<64x64xf32>)"}} {
    %c0 = arith.constant 0 : index
    %c16384 = arith.constant 16384 : index
    %c64 = arith.constant 64 : index
    %element_type_f32 = hal.element_type<f32> : i32
    %dense_row_major = hal.encoding_type<dense_row_major> : i32
    hal.buffer_view.assert<%arg0 : !hal.buffer_view> message("input0") shape([%c64, %c64]) type(%element_type_f32) encoding(%dense_row_major)
    %0 = stream.tensor.import on(#hal.device.affinity<@__device_0>) %arg0 : !hal.buffer_view -> tensor<64x64xf32> in !stream.resource<external>{%c16384}
    hal.buffer_view.assert<%arg1 : !hal.buffer_view> message("input1") shape([%c64, %c64]) type(%element_type_f32) encoding(%dense_row_major)
    %1 = stream.tensor.import on(#hal.device.affinity<@__device_0>) %arg1 : !hal.buffer_view -> tensor<64x64xf32> in !stream.resource<external>{%c16384}
    %result, %result_timepoint = stream.resource.alloca uninitialized on(#hal.device.affinity<@__device_0>) : !stream.resource<external>{%c16384} => !stream.timepoint
    %c0_0 = arith.constant 0 : index
    %c0_i64 = arith.constant 0 : i64
    %c0_i32 = arith.constant 0 : i32
    %c32_i64 = arith.constant 32 : i64
    %c0_i32_1 = arith.constant 0 : i32
    %c0_i64_2 = arith.constant 0 : i64
    %c0_i32_3 = arith.constant 0 : i32
    %c32_i64_4 = arith.constant 32 : i64
    %c0_i32_5 = arith.constant 0 : i32
    %c0_i64_6 = arith.constant 0 : i64
    %c0_i32_7 = arith.constant 0 : i32
    %c32_i64_8 = arith.constant 32 : i64
    %c0_i32_9 = arith.constant 0 : i32
    %2 = stream.cmd.execute on(#hal.device.affinity<@__device_0>) await(%result_timepoint) => with(%0 as %arg2: !stream.resource<external>{%c16384}, %1 as %arg3: !stream.resource<external>{%c16384}, %result as %arg4: !stream.resource<external>{%c16384}) {
      stream.cmd.dispatch @matmul_dispatch_0::@matmul_dispatch_0_matmul_64x64x64_f32(%c0_i32, %c0_i32_1, %c0_i32_3, %c0_i32_5, %c0_i32_7, %c0_i32_9 : i32, i32, i32, i32, i32, i32) {
        ro %arg2[%c0_0 for %c16384] : !stream.resource<external>{%c16384},
        ro %arg3[%c0_0 for %c16384] : !stream.resource<external>{%c16384},
        wo %arg4[%c0_0 for %c16384] : !stream.resource<external>{%c16384}
      }
    } => !stream.timepoint
    %3 = stream.timepoint.await %2 => %result : !stream.resource<external>{%c16384}
    %4 = stream.tensor.export on(#hal.device.affinity<@__device_0>) %3 : tensor<64x64xf32> in !stream.resource<external>{%c16384} -> !hal.buffer_view
    util.return %4 : !hal.buffer_view
  }
}


