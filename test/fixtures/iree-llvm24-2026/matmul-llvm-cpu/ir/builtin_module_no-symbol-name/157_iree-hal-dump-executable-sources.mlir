// -----// IR Dump After DumpExecutableSourcesPass: iree-hal-dump-executable-sources{path=<fixtures>/iree-llvm24-2026/matmul-llvm-cpu/configs prefix=configured} //----- //
#config = #iree_cpu.lowering_config<cache_parallel = [8, 64], vector_common_parallel = [8, 8]>
#config1 = #iree_cpu.lowering_config<cache_parallel = [8, 64, 0], distribution = [8, 64, 0], vector_common_parallel = [8, 8, 0], vector_reduction = [0, 0, 4]>
#executable_target_embedded_elf_arm_64 = #hal.executable.target<"llvm-cpu", "embedded-elf-arm_64", {cpu = "generic", cpu_features = "+reserve-x18", data_layout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-Fn32", iree.encoding.resolver = #iree_cpu.cpu_encoding_resolver<>, max_stack_allocation_size = 32768 : i64, native_vector_size = 16 : i64, target_triple = "arm64-unknown-unknown-eabi-elf"}>
#pipeline_layout = #hal.pipeline.layout<bindings = [#hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, "ReadOnly|Indirect">, #hal.pipeline.binding<storage_buffer, Indirect>], flags = Indirect>
#translation = #iree_codegen.translation_info<pipeline = #iree_cpu.pipeline<DoubleTilingExpert>, {enable_loop_peeling}>
#device_target_local = #hal.device.target<"local", [#executable_target_embedded_elf_arm_64]> : !hal.device
module attributes {stream.affinity.default = #hal.device.affinity<@__device_0>} {
  util.global private @__device_0 = #device_target_local
  hal.executable private @matmul_dispatch_0 {
    hal.executable.variant public @embedded_elf_arm_64 target(#executable_target_embedded_elf_arm_64) {
      hal.executable.export public @matmul_dispatch_0_matmul_64x64x64_f32 ordinal(0) layout(#pipeline_layout) count(%arg0: !hal.device) -> (index, index, index) {
        %x, %y, %z = iree_tensor_ext.dispatch.workgroup_count_from_slice()
        hal.return %x, %y, %z : index, index, index
      }
      builtin.module {
        func.func @matmul_dispatch_0_matmul_64x64x64_f32() attributes {translation_info = #translation} {
          %cst = arith.constant 0.000000e+00 : f32
          %c0 = arith.constant 0 : index
          %0 = hal.interface.binding.subspan layout(#pipeline_layout) binding(0) alignment(64) offset(%c0) flags("ReadOnly|Indirect") : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
          %1 = hal.interface.binding.subspan layout(#pipeline_layout) binding(1) alignment(64) offset(%c0) flags("ReadOnly|Indirect") : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
          %2 = hal.interface.binding.subspan layout(#pipeline_layout) binding(2) alignment(64) offset(%c0) flags(Indirect) : memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
          %3 = iree_codegen.load_from_buffer %0 : memref<64x64xf32, #hal.descriptor_type<storage_buffer>> -> tensor<64x64xf32>
          %4 = iree_codegen.load_from_buffer %1 : memref<64x64xf32, #hal.descriptor_type<storage_buffer>> -> tensor<64x64xf32>
          %5 = tensor.empty() : tensor<64x64xf32>
          %6 = linalg.fill {lowering_config = #config} ins(%cst : f32) outs(%5 : tensor<64x64xf32>) -> tensor<64x64xf32>
          %7 = linalg.matmul {lowering_config = #config1} ins(%3, %4 : tensor<64x64xf32>, tensor<64x64xf32>) outs(%6 : tensor<64x64xf32>) -> tensor<64x64xf32>
          iree_codegen.store_to_buffer %7, %2 : tensor<64x64xf32> into memref<64x64xf32, #hal.descriptor_type<storage_buffer>>
          return
        }
        iree_codegen.dispatch_config @matmul_dispatch_0_matmul_64x64x64_f32 {
        ^bb0(%arg0: !hal.device):
          %x, %y, %z = iree_tensor_ext.dispatch.workgroup_count_from_slice()
          iree_codegen.yield %x, %y, %z : index, index, index
        }
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
    %2 = stream.cmd.execute on(#hal.device.affinity<@__device_0>) await(%result_timepoint) => with(%0 as %arg2: !stream.resource<external>{%c16384}, %1 as %arg3: !stream.resource<external>{%c16384}, %result as %arg4: !stream.resource<external>{%c16384}) {
      stream.cmd.dispatch @matmul_dispatch_0::@embedded_elf_arm_64::@matmul_dispatch_0_matmul_64x64x64_f32 {
        ro %arg2[%c0 for %c16384] : !stream.resource<external>{%c16384},
        ro %arg3[%c0 for %c16384] : !stream.resource<external>{%c16384},
        wo %arg4[%c0 for %c16384] : !stream.resource<external>{%c16384}
      }
    } => !stream.timepoint
    %3 = stream.timepoint.await %2 => %result : !stream.resource<external>{%c16384}
    %4 = stream.tensor.export on(#hal.device.affinity<@__device_0>) %3 : tensor<64x64xf32> in !stream.resource<external>{%c16384} -> !hal.buffer_view
    util.return %4 : !hal.buffer_view
  }
}


