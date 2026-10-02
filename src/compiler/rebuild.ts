// Helpers for adding a compiler backend to a local IREE CMake build.
// Backends are compiled into iree-compile; they can't be installed at runtime,
// so "adding" one means reconfiguring the build with the option ON and
// rebuilding. Pure functions here; the extension runs the command in a
// visible terminal after the user confirms.

import { promises as fs } from 'fs';
import * as path from 'path';

export interface BackendOption {
  /** Backend name as iree-compile reports it. */
  backend: string;
  /** CMake cache variable that enables it. */
  cmake: string;
  label: string;
  /** Rough rebuild cost, shown before the user confirms. */
  estimate: string;
  /** Extra disk the build grows by, GB: [Release, RelWithDebInfo/Debug]. */
  diskGB: [number, number];
  note?: string;
  /** Shown when removing this backend. */
  removeWarning?: string;
  /**
   * Build folders (relative to the build dir) that belong to this backend
   * alone; used to estimate what removing it frees. Only the target plugin:
   * a test configure with VMVX=OFF still built Codegen/VMVX and Dialect/VMVX
   * (other code uses them), and SPIRV/LLVMGPU codegen is shared too.
   */
  dirs: string[];
}

// Option names checked against iree/CMakeLists.txt (cmake_dependent_option
// IREE_TARGET_BACKEND_*).
// Disk estimates are rough: measured against one RelWithDebInfo build where
// LLVM alone is ~41 GB. CUDA/ROCm add a whole LLVM code generator (NVPTX /
// AMDGPU); the SPIR-V backends share most of their code.
// TODO(verify): refine with a real before/after `du` per backend.
export const BACKEND_OPTIONS: BackendOption[] = [
  {
    backend: 'llvm-cpu', cmake: 'IREE_TARGET_BACKEND_LLVM_CPU', label: 'CPU (llvm-cpu)', estimate: '~15–40 min', diskGB: [3, 8],
    dirs: ['compiler/plugins/target/LLVMCPU'],
    removeWarning: 'IREE evaluates constants at compile time by running them on the local CPU device, which uses llvm-cpu. Without it, compiling models with constant weights can fail or slow down.',
  },
  { backend: 'vmvx', cmake: 'IREE_TARGET_BACKEND_VMVX', label: 'Portable CPU (vmvx)', estimate: '~5–15 min', diskGB: [0.5, 1], dirs: ['compiler/plugins/target/VMVX'] },
  { backend: 'vulkan-spirv', cmake: 'IREE_TARGET_BACKEND_VULKAN_SPIRV', label: 'Vulkan GPU (vulkan-spirv)', estimate: '~10–30 min', diskGB: [1, 3], dirs: ['compiler/plugins/target/VulkanSPIRV'] },
  { backend: 'metal-spirv', cmake: 'IREE_TARGET_BACKEND_METAL_SPIRV', label: 'Apple GPU (metal-spirv)', estimate: '~10–30 min', diskGB: [1, 3], dirs: ['compiler/plugins/target/MetalSPIRV'], note: 'Compiling works anywhere; running the .vmfb needs a Mac.' },
  { backend: 'cuda', cmake: 'IREE_TARGET_BACKEND_CUDA', label: 'NVIDIA GPU (cuda)', estimate: '~30–90 min', diskGB: [3, 8], dirs: ['compiler/plugins/target/CUDA'], note: 'Adds the NVPTX target to LLVM, so a large part of LLVM rebuilds.' },
  { backend: 'rocm', cmake: 'IREE_TARGET_BACKEND_ROCM', label: 'AMD GPU (rocm)', estimate: '~30–90 min', diskGB: [3, 8], dirs: ['compiler/plugins/target/ROCM'], note: 'Adds the AMDGPU target to LLVM, so a large part of LLVM rebuilds.' },
  { backend: 'webgpu-spirv', cmake: 'IREE_TARGET_BACKEND_WEBGPU_SPIRV', label: 'WebGPU (webgpu-spirv)', estimate: '~10–30 min', diskGB: [1, 3], dirs: ['compiler/plugins/target/WebGPUSPIRV'] },
];

/** Parses `NAME:TYPE=VALUE` lines of a CMakeCache.txt. */
export function parseCMakeCache(text: string): Map<string, string> {
  const out = new Map<string, string>();
  for (const line of text.split(/\r?\n/)) {
    if (line.startsWith('#') || line.startsWith('//')) {
      continue;
    }
    const m = /^([A-Za-z_][\w.+-]*):[A-Z]+=(.*)$/.exec(line);
    if (m) {
      out.set(m[1], m[2]);
    }
  }
  return out;
}

export interface BuildInfo {
  buildDir: string;
  sourceDir: string;
  /** CMAKE_BUILD_TYPE, e.g. "RelWithDebInfo". */
  buildType: string;
  /** CMAKE_GENERATOR, e.g. "Ninja". */
  generator: string;
  /** backend -> enabled in the CMake cache */
  enabled: Map<string, boolean>;
}

export function buildInfoFromCache(buildDir: string, cache: Map<string, string>): BuildInfo | undefined {
  const sourceDir = cache.get('CMAKE_HOME_DIRECTORY');
  if (!sourceDir) {
    return undefined;
  }
  const enabled = new Map<string, boolean>();
  for (const b of BACKEND_OPTIONS) {
    const v = cache.get(b.cmake);
    if (v !== undefined) {
      enabled.set(b.backend, /^(ON|TRUE|1|YES)$/i.test(v));
    }
  }
  return { buildDir, sourceDir, buildType: cache.get('CMAKE_BUILD_TYPE') ?? '', generator: cache.get('CMAKE_GENERATOR') ?? '', enabled };
}

/** Walks up from iree-compile (usually <build>/tools/) to find its CMake build. */
export async function findBuild(compilerPath: string): Promise<BuildInfo | undefined> {
  let dir = path.dirname(await fs.realpath(compilerPath).catch(() => compilerPath));
  for (let i = 0; i < 4; i++) {
    const cachePath = path.join(dir, 'CMakeCache.txt');
    try {
      const text = await fs.readFile(cachePath, 'utf8');
      return buildInfoFromCache(dir, parseCMakeCache(text));
    } catch {
      // keep walking up
    }
    const parent = path.dirname(dir);
    if (parent === dir) {
      break;
    }
    dir = parent;
  }
  return undefined;
}

function shq(s: string): string {
  return /^[\w@%+=:,./-]+$/.test(s) ? s : `'${s.replace(/'/g, `'\\''`)}'`;
}

/** Whether removal can delete the backend's stale build files (Ninja only). */
export function canFreeSpace(info: BuildInfo): boolean {
  return /ninja/i.test(info.generator);
}

/**
 * Reconfigures the existing build with the backend ON or OFF (every other
 * cached option, e.g. IREE_CMAKE_PLUGIN_PATHS, is kept) and rebuilds the tools.
 * When removing with Ninja, `ninja -t cleandead` then deletes every build file
 * the new configuration no longer produces (the backend's objects), and
 * nothing that's still in use.
 */
export function rebuildCommand(info: BuildInfo, option: BackendOption, enable = true): string {
  const steps = [
    `cmake -S ${shq(info.sourceDir)} -B ${shq(info.buildDir)} -D${option.cmake}=${enable ? 'ON' : 'OFF'}`,
    `cmake --build ${shq(info.buildDir)} --target iree-compile iree-opt`,
  ];
  if (!enable && canFreeSpace(info)) {
    steps.push(`ninja -C ${shq(info.buildDir)} -t cleandead`);
  }
  return steps.join(' && ');
}

/** Total size of a directory tree in bytes (0 if missing). */
export async function dirBytes(dir: string): Promise<number> {
  let total = 0;
  let entries: import('fs').Dirent[];
  try {
    entries = await fs.readdir(dir, { withFileTypes: true });
  } catch {
    return 0;
  }
  for (const e of entries) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) {
      total += await dirBytes(p);
    } else if (e.isFile()) {
      total += await fs.stat(p).then((st) => st.size, () => 0);
    }
  }
  return total;
}

/** Upper bound on what removing a backend frees: its own build folders. */
export async function backendBuildBytes(info: BuildInfo, option: BackendOption): Promise<number> {
  let total = 0;
  for (const d of option.dirs) {
    total += await dirBytes(path.join(info.buildDir, d));
  }
  return total;
}

const GB = 1024 ** 3;
/** Relinking libIREECompiler (~0.6 GB) and temporaries need room even when removing. */
const RELINK_HEADROOM_GB = 2;

/** Disk the build needs free, in bytes. Removing a backend only needs relink room. */
export function diskNeededBytes(info: BuildInfo, option: BackendOption, enable: boolean): number {
  const lean = /^(Release|MinSizeRel)$/i.test(info.buildType);
  const grow = enable ? option.diskGB[lean ? 0 : 1] : 0;
  return (grow + RELINK_HEADROOM_GB) * GB;
}

export interface DiskVerdict {
  status: 'ok' | 'tight' | 'insufficient';
  freeBytes: number;
  neededBytes: number;
  message: string;
}

export function formatGB(bytes: number): string {
  if (bytes < 0.1 * GB) {
    return `${Math.max(1, Math.round(bytes / 1024 ** 2))} MB`;
  }
  return `${(bytes / GB).toFixed(bytes < 10 * GB ? 1 : 0)} GB`;
}

/** "tight" = fits, but less than 5 GB would be left afterwards. */
export function diskVerdict(freeBytes: number, neededBytes: number): DiskVerdict {
  const after = freeBytes - neededBytes;
  const base = `${formatGB(freeBytes)} free; this needs about ${formatGB(neededBytes)}`;
  if (after < 0) {
    return { status: 'insufficient', freeBytes, neededBytes, message: `Not enough disk space: ${base}. Free up ${formatGB(-after)} or more first.` };
  }
  if (after < 5 * GB) {
    return { status: 'tight', freeBytes, neededBytes, message: `Disk space is tight: ${base}, leaving ~${formatGB(after)}.` };
  }
  return { status: 'ok', freeBytes, neededBytes, message: `Disk space OK: ${base}.` };
}

/** Free bytes available to this user on the volume holding `dir`. */
export async function freeDiskBytes(dir: string): Promise<number | undefined> {
  try {
    const st = await fs.statfs(dir);
    return Number(st.bavail) * Number(st.bsize);
  } catch {
    return undefined;
  }
}
