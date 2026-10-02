// -----// IR Dump After CanonicalizerPass: canonicalize{cse-between-iterations=false    max-iterations=10 max-num-rewrites=-1 region-simplify=normal test-convergence=false top-down=true} //----- //
util.initializer {
  %0 = util.call @__matmul_memoize_apply() : () -> !hal.command_buffer
  util.global.store %0, @__matmul_memoize_result_0_device_0 : !hal.command_buffer
  util.return
}

