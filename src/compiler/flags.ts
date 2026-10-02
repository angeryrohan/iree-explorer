// Flag construction. Pure: takes a request + capabilities, returns argv and
// warnings. Never invents flags: anything not confirmed by probing is either
// dropped (dump/diagnostic flags) or passed with a visible warning (flags the
// user explicitly asked for via a profile).

import * as path from 'path';
import { Capabilities, CompileRequest, TargetProfile } from '../model/types';

export interface CompileArgs {
  args: string[];
  /** Where the output artifact is written. */
  outputPath: string;
  /** Human-readable problems the user should see. */
  warnings: string[];
}

export interface FlagSettings {
  elideAttrsLargerThan: number;
  dumpBinaries: boolean;
  /**
   * Whether `xcrun metal` exists (it ships with Xcode, not the Command Line
   * Tools). Undefined = unknown / not checked.
   */
  metalToolchainAvailable?: boolean;
}

export const METAL_NO_METALLIB_FLAG = '--iree-metal-compile-to-metallib=false';

export const DUMP_SUBDIRS = {
  ir: 'ir',
  sources: 'sources',
  configs: 'configs',
  binaries: 'binaries',
  intermediates: 'intermediates',
} as const;

// Built-in profiles. `device` is the newer --iree-hal-target-device family,
// `backend` the older --iree-hal-target-backends family.
//
// TODO(verify): the per-device flag names below were confirmed against a
// 2026 IREE build for llvm-cpu and vulkan only (--iree-llvmcpu-target-cpu,
// --iree-vulkan-target, --iree-hal-local-target-device-backends). The cuda
// (--iree-cuda-target), hip (--iree-hip-target) and metal flags are from the
// IREE docs; check them against `iree-compile --help-hidden` on a build that
// has those backends enabled. Flags missing from the probed binary are
// reported as warnings at compile time, never passed silently.
export const BUILTIN_TARGETS: TargetProfile[] = [
  {
    id: 'llvm-cpu-host',
    label: 'llvm-cpu (host)',
    device: 'local',
    backend: 'llvm-cpu',
    deviceFlags: ['--iree-hal-local-target-device-backends=llvm-cpu', '--iree-llvmcpu-target-cpu=host'],
    extraFlags: [],
    sharedMemoryBudgetBytes: 32768,
    source: 'builtin',
  },
  {
    id: 'cuda-sm80',
    label: 'cuda (sm_80)',
    device: 'cuda',
    backend: 'cuda',
    deviceFlags: ['--iree-cuda-target=sm_80'],
    extraFlags: [],
    sharedMemoryBudgetBytes: 166912,
    source: 'builtin',
  },
  {
    id: 'gfx942-rocm',
    label: 'rocm (gfx942)',
    device: 'hip',
    backend: 'rocm',
    deviceFlags: ['--iree-hip-target=gfx942'],
    extraFlags: [],
    sharedMemoryBudgetBytes: 65536,
    source: 'builtin',
  },
  {
    id: 'vulkan-rdna3',
    label: 'vulkan-spirv (rdna3)',
    device: 'vulkan',
    backend: 'vulkan-spirv',
    deviceFlags: ['--iree-vulkan-target=rdna3'],
    extraFlags: [],
    sharedMemoryBudgetBytes: 65536,
    source: 'builtin',
  },
  {
    id: 'metal-spirv',
    label: 'metal-spirv',
    device: 'metal',
    backend: 'metal-spirv',
    deviceFlags: [],
    extraFlags: [],
    sharedMemoryBudgetBytes: 32768,
    source: 'builtin',
  },
];

/** Adds a legacy-flag profile for every probed backend not already covered. */
export function probedTargets(caps: Capabilities | undefined): TargetProfile[] {
  if (!caps) {
    return [];
  }
  const covered = new Set(BUILTIN_TARGETS.map((t) => t.backend));
  return caps.registeredBackends
    .filter((b) => !covered.has(b))
    .map((b) => ({
      id: `backend-${b}`,
      label: b,
      backend: b,
      deviceFlags: [],
      extraFlags: [],
      source: 'probed' as const,
    }));
}

/** Validates user-provided profile objects from settings. Invalid entries are skipped. */
export function sanitizeCustomTargets(raw: unknown): { targets: TargetProfile[]; problems: string[] } {
  const targets: TargetProfile[] = [];
  const problems: string[] = [];
  if (!Array.isArray(raw)) {
    return { targets, problems };
  }
  raw.forEach((entry: unknown, i) => {
    if (typeof entry !== 'object' || entry === null) {
      problems.push(`ireeExplorer.targets[${i}] is not an object`);
      return;
    }
    const e = entry as Record<string, unknown>;
    if (typeof e.id !== 'string' || e.id.length === 0) {
      problems.push(`ireeExplorer.targets[${i}] has no id`);
      return;
    }
    const strArr = (v: unknown): string[] => (Array.isArray(v) ? v.filter((x): x is string => typeof x === 'string') : []);
    const device = typeof e.device === 'string' && e.device ? e.device : undefined;
    const backend = typeof e.backend === 'string' && e.backend ? e.backend : undefined;
    if (!device && !backend) {
      problems.push(`ireeExplorer.targets[${i}] (${e.id}) needs "device" or "backend"`);
      return;
    }
    targets.push({
      id: e.id,
      label: typeof e.label === 'string' && e.label ? e.label : e.id,
      device,
      backend,
      deviceFlags: strArr(e.deviceFlags),
      extraFlags: strArr(e.extraFlags),
      sharedMemoryBudgetBytes: typeof e.sharedMemoryBudgetBytes === 'number' ? e.sharedMemoryBudgetBytes : undefined,
      source: 'custom',
    });
  });
  return { targets, problems };
}

/** Merges built-in, probed and custom profiles; custom wins on id collision. */
export function mergeTargets(builtin: TargetProfile[], probed: TargetProfile[], custom: TargetProfile[]): TargetProfile[] {
  const byId = new Map<string, TargetProfile>();
  for (const t of [...builtin, ...probed, ...custom]) {
    byId.set(t.id, t);
  }
  return [...byId.values()];
}

export interface TargetKind {
  /** Codicon name: the same processor icon for every target. */
  icon: string;
  /** Short hardware description shown next to the label. */
  kind: string;
}

/** Hardware description for a profile, from its device/backend. */
export function targetKind(t: TargetProfile): TargetKind {
  const k = `${t.device ?? ''} ${t.backend ?? ''}`;
  const kind = /\bcuda\b/.test(k) ? 'NVIDIA GPU'
    : /\b(hip|rocm)\b/.test(k) ? 'AMD GPU'
      : /\bmetal/.test(k) ? 'Apple GPU (Metal)'
        : /\bvulkan/.test(k) ? 'GPU (Vulkan)'
          : /\bwebgpu/.test(k) ? 'GPU (WebGPU)'
            : /\bllvm-cpu\b/.test(k) ? 'CPU'
              : /\bvmvx/.test(k) ? 'CPU (portable VMVX)'
                : 'Plugin / custom';
  return { icon: 'chip', kind };
}

/** Whether a profile's backend is known to be compiled into the binary. */
export function targetAvailability(t: TargetProfile, caps: Capabilities | undefined): 'yes' | 'no' | 'unknown' {
  if (!caps || caps.registeredBackends.length === 0 || !t.backend) {
    return 'unknown';
  }
  return caps.registeredBackends.includes(t.backend) ? 'yes' : 'no';
}

/** Extracts the flag name from "--foo=bar" / "-foo" / "--foo". */
export function flagName(arg: string): string | undefined {
  const m = /^--?([A-Za-z0-9][\w.-]*)/.exec(arg);
  return m ? m[1] : undefined;
}

export function targetFlags(t: TargetProfile, caps: Capabilities | undefined): { args: string[]; warnings: string[] } {
  const warnings: string[] = [];
  const args: string[] = [];
  const preferDevice = t.device !== undefined && (caps === undefined || caps.hasTargetDevice);
  if (preferDevice) {
    args.push(`--iree-hal-target-device=${t.device}`);
    args.push(...t.deviceFlags);
  } else if (t.backend !== undefined && (caps === undefined || caps.hasTargetBackends)) {
    args.push(`--iree-hal-target-backends=${t.backend}`);
    // Device-family-only flags make no sense with the legacy form.
    args.push(...t.deviceFlags.filter((f) => !/^--iree-hal-local-target-device-backends=/.test(f)));
  } else {
    warnings.push(
      `Target "${t.label}" has no usable selection flag: binary supports ` +
      `${caps?.hasTargetDevice ? '--iree-hal-target-device' : ''}${caps?.hasTargetBackends ? ' --iree-hal-target-backends' : ''}` +
      ` but the profile sets ${t.device ? 'device' : ''}${t.backend ? ' backend' : ''}.`,
    );
  }
  args.push(...t.extraFlags);
  if (caps) {
    for (const a of args) {
      const name = flagName(a);
      if (name && !caps.knownFlags.has(name)) {
        warnings.push(`Flag --${name} (from target "${t.label}") is not listed by this iree-compile's --help-hidden; it may be rejected.`);
      }
    }
  }
  return { args, warnings };
}

export function buildCompileArgs(
  req: CompileRequest,
  caps: Capabilities | undefined,
  settings: FlagSettings,
): CompileArgs {
  const warnings: string[] = [];
  const d = (sub: string) => path.join(req.dumpDir, sub);
  const textOutput = req.compileTo !== undefined && req.compileTo !== 'end';
  const outputPath = path.join(req.dumpDir, textOutput ? `output.${req.compileTo}.mlir` : 'output.vmfb');

  const args: string[] = [req.inputPath];

  const target = targetFlags(req.target, caps);
  args.push(...target.args);
  warnings.push(...target.warnings);

  // Dump flags. --mlir-print-ir-tree-dir only writes anything when combined
  // with an --mlir-print-ir-* selector, so print-ir-after-all is required;
  // after-change would hide the unchanged passes the tree is meant to dim.
  const dumpFlags: string[] = [
    `--mlir-print-ir-after-all`,
    `--mlir-print-ir-tree-dir=${d(DUMP_SUBDIRS.ir)}`,
    `--iree-hal-dump-executable-sources-to=${d(DUMP_SUBDIRS.sources)}`,
    `--iree-hal-dump-executable-configurations-to=${d(DUMP_SUBDIRS.configs)}`,
    `--mlir-elide-elementsattrs-if-larger=${Math.max(0, Math.floor(settings.elideAttrsLargerThan))}`,
    `--mlir-pass-statistics`,
    `--mlir-timing`,
  ];
  if (settings.dumpBinaries) {
    dumpFlags.push(`--iree-hal-dump-executable-binaries-to=${d(DUMP_SUBDIRS.binaries)}`);
    dumpFlags.push(`--iree-hal-dump-executable-intermediates-to=${d(DUMP_SUBDIRS.intermediates)}`);
  }
  for (const f of dumpFlags) {
    const name = flagName(f);
    if (caps && name && !caps.knownFlags.has(name)) {
      warnings.push(`Skipping --${name}: not supported by this iree-compile (not in --help-hidden). Related views will be empty.`);
      continue;
    }
    args.push(f);
  }
  if (!caps) {
    warnings.push('Compiler capabilities were not probed; dump flags are passed unverified.');
  }

  if (req.compileTo !== undefined) {
    if (caps && !caps.knownFlags.has('compile-to')) {
      warnings.push('Skipping --compile-to: not supported by this iree-compile.');
    } else {
      if (caps && !caps.compileToPhases.includes(req.compileTo)) {
        warnings.push(`--compile-to=${req.compileTo} is not in the probed phase list (${caps.compileToPhases.join(', ')}).`);
      }
      args.push(`--compile-to=${req.compileTo}`);
    }
  }

  // Without Xcode, the Metal backend can't pre-compile shaders to .metallib
  // (it shells out to `xcrun metal`). Embedding the shader source instead
  // gives the same kernel speed; macOS compiles it when the model loads.
  const isMetal = targetKind(req.target).kind === 'Apple GPU (Metal)';
  const userSetMetallib = [...req.extraFlags, ...req.target.extraFlags].some((f) => f.startsWith('--iree-metal-compile-to-metallib'));
  if (isMetal && settings.metalToolchainAvailable === false && !userSetMetallib) {
    if (!caps || caps.knownFlags.has('iree-metal-compile-to-metallib')) {
      args.push(METAL_NO_METALLIB_FLAG);
      warnings.push(`Added ${METAL_NO_METALLIB_FLAG}: Xcode's \`metal\` tool isn't installed, so shaders are embedded as source and compiled by macOS when the model loads (same kernel speed).`);
    }
  }

  args.push(...req.extraFlags);
  args.push('-o', outputPath);
  return { args, outputPath, warnings };
}
