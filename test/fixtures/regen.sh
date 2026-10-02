#!/usr/bin/env bash
# Regenerates fixture dump dirs from a real iree-compile.
#   IREE_COMPILE=/path/to/iree-compile ./regen.sh
# Layout: <iree-version-tag>/<input>-<target>/{ir,sources,configs,stderr.log,meta.json}
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
bin="${IREE_COMPILE:-iree-compile}"
tag="${TAG:-$("$bin" --version | grep -o 'LLVM version [^ ]*' | tr ' ' '-' )}"
for input in matmul conv reduction; do
  for target in llvm-cpu vulkan-spirv; do
    out="$here/$tag/$input-$target"
    rm -rf "$out"; mkdir -p "$out/ir" "$out/sources" "$out/configs"
    case "$target" in
      llvm-cpu) tflags=(--iree-hal-target-device=local --iree-hal-local-target-device-backends=llvm-cpu --iree-llvmcpu-target-cpu=generic) ;;
      vulkan-spirv) tflags=(--iree-hal-target-device=vulkan --iree-vulkan-target=rdna3) ;;
    esac
    "$bin" "$here/inputs/$input.mlir" "${tflags[@]}" \
      --mlir-print-ir-after-all --mlir-print-ir-tree-dir="$out/ir" \
      --iree-hal-dump-executable-sources-to="$out/sources" \
      --iree-hal-dump-executable-configurations-to="$out/configs" \
      --mlir-elide-elementsattrs-if-larger=16 --mlir-pass-statistics --mlir-timing \
      -o /dev/null 2> "$out/stderr.log"
    # Absolute paths (in stderr and in dumped pass options) would leak the
    # generating machine; rewrite them.
    grep -rl "$here" "$out" | while read -r f; do
      LC_ALL=C sed -i.bak "s|$here|<fixtures>|g" "$f" && rm -f "$f.bak"
    done
    printf '{"inputPath":"%s","targetId":"%s","targetLabel":"%s","args":[],"compilerPath":"iree-compile","startedAt":0,"outputPath":"","sharedMemoryBudgetBytes":65536}\n' \
      "inputs/$input.mlir" "$target" "$target" > "$out/meta.json"
  done
done
# Keep full pass trees only for one input per target (the rest are large and
# only needed for dispatch/lowering tests). FULL=1 keeps everything.
if [ -z "${FULL:-}" ]; then
  for d in conv-llvm-cpu conv-vulkan-spirv matmul-vulkan-spirv reduction-llvm-cpu; do
    rm -rf "$here/$tag/$d/ir" && mkdir "$here/$tag/$d/ir" && touch "$here/$tag/$d/ir/.keep"
  done
fi
du -sh "$here/$tag"/*
