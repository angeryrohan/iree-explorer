import { readFileSync } from 'fs';
import { describe, expect, it } from 'vitest';
import {
  BUILTIN_TARGETS, buildCompileArgs, mergeTargets, probedTargets, sanitizeCustomTargets, targetFlags,
} from '../../src/compiler/flags';
import { buildCapabilities } from '../../src/compiler/probe';
import { parseDiagnostics } from '../../src/compiler/diagnostics';
import { fixture } from './helpers';

const helpText = readFileSync(fixture('probe', 'help.txt'), 'utf8') + readFileSync(fixture('probe', 'help-hidden.txt'), 'utf8');
const caps = buildCapabilities('v', helpText, ['dummy', 'llvm-cpu', 'vmvx', 'vmvx-inline', 'vulkan-spirv']);
const cpu = BUILTIN_TARGETS.find((t) => t.id === 'llvm-cpu-host')!;
const settings = { elideAttrsLargerThan: 16, dumpBinaries: false };

describe('flags', () => {
  it('prefers --iree-hal-target-device when the binary has it', () => {
    const { args, warnings } = targetFlags(cpu, caps);
    expect(args).toEqual([
      '--iree-hal-target-device=local', '--iree-hal-local-target-device-backends=llvm-cpu', '--iree-llvmcpu-target-cpu=host',
    ]);
    expect(warnings).toEqual([]);
  });

  it('falls back to --iree-hal-target-backends on older binaries', () => {
    const old = { ...caps, hasTargetDevice: false };
    expect(targetFlags(cpu, old).args).toEqual(['--iree-hal-target-backends=llvm-cpu', '--iree-llvmcpu-target-cpu=host']);
  });

  it('warns (does not silently pass) flags the binary does not list', () => {
    const hip = BUILTIN_TARGETS.find((t) => t.id === 'gfx942-rocm')!;
    const { warnings } = targetFlags(hip, caps);
    expect(warnings.some((w) => w.includes('--iree-hip-target'))).toBe(true);
  });

  it('always includes dump flags, the elide threshold and print-ir-after-all', () => {
    const r = buildCompileArgs({ inputPath: '/in.mlir', target: cpu, dumpDir: '/d', extraFlags: ['--x'] }, caps, settings);
    expect(r.args).toContain('--mlir-print-ir-tree-dir=/d/ir');
    expect(r.args).toContain('--mlir-print-ir-after-all');
    expect(r.args).toContain('--iree-hal-dump-executable-sources-to=/d/sources');
    expect(r.args).toContain('--iree-hal-dump-executable-configurations-to=/d/configs');
    expect(r.args).toContain('--mlir-elide-elementsattrs-if-larger=16');
    expect(r.args).toContain('--mlir-pass-statistics');
    expect(r.args).toContain('--mlir-timing');
    expect(r.args.slice(-3)).toEqual(['--x', '-o', '/d/output.vmfb']);
    expect(r.warnings).toEqual([]);
  });

  it('drops dump flags a binary lacks, with a warning', () => {
    const noTree = { ...caps, knownFlags: new Set([...caps.knownFlags].filter((f) => f !== 'mlir-print-ir-tree-dir')) };
    const r = buildCompileArgs({ inputPath: '/in.mlir', target: cpu, dumpDir: '/d', extraFlags: [] }, noTree, settings);
    expect(r.args.some((a) => a.startsWith('--mlir-print-ir-tree-dir'))).toBe(false);
    expect(r.warnings.join()).toMatch(/mlir-print-ir-tree-dir/);
  });

  it('writes textual output when stopping early', () => {
    const r = buildCompileArgs({ inputPath: '/in.mlir', target: cpu, dumpDir: '/d', extraFlags: [], compileTo: 'flow' }, caps, settings);
    expect(r.args).toContain('--compile-to=flow');
    expect(r.outputPath).toBe('/d/output.flow.mlir');
  });

  it('merges custom targets over built-ins and probed backends', () => {
    const { targets, problems } = sanitizeCustomTargets([
      { id: 'llvm-cpu-host', label: 'my cpu', backend: 'llvm-cpu', deviceFlags: ['--iree-llvmcpu-target-cpu=znver4'] },
      { id: 'dummy-accel', label: 'LLForge dummy', backend: 'dummy' },
      { id: 'broken' },
      42,
    ]);
    expect(problems).toHaveLength(2);
    const merged = mergeTargets(BUILTIN_TARGETS, probedTargets(caps), targets);
    expect(merged.find((t) => t.id === 'llvm-cpu-host')?.label).toBe('my cpu');
    expect(merged.find((t) => t.id === 'backend-dummy')).toBeDefined();
    expect(merged.find((t) => t.id === 'dummy-accel')?.source).toBe('custom');
  });
});

describe('metal without Xcode', () => {
  const metal = BUILTIN_TARGETS.find((t) => t.id === 'metal-spirv')!;
  const withMetal = { ...caps, knownFlags: new Set([...caps.knownFlags, 'iree-metal-compile-to-metallib']) };
  const req = { inputPath: '/in.mlir', target: metal, dumpDir: '/d', extraFlags: [] as string[] };

  it('embeds shader source when xcrun metal is missing', () => {
    const r = buildCompileArgs(req, withMetal, { ...settings, metalToolchainAvailable: false });
    expect(r.args).toContain('--iree-metal-compile-to-metallib=false');
    expect(r.warnings.join()).toMatch(/Xcode/);
  });

  it('leaves the default alone with Xcode, for other targets, or when the user set it', () => {
    expect(buildCompileArgs(req, withMetal, { ...settings, metalToolchainAvailable: true }).args.join(' ')).not.toContain('compile-to-metallib');
    expect(buildCompileArgs({ ...req, target: cpu }, withMetal, { ...settings, metalToolchainAvailable: false }).args.join(' ')).not.toContain('compile-to-metallib');
    const own = buildCompileArgs({ ...req, extraFlags: ['--iree-metal-compile-to-metallib=true'] }, withMetal, { ...settings, metalToolchainAvailable: false });
    expect(own.args.filter((a) => a.startsWith('--iree-metal-compile-to-metallib'))).toEqual(['--iree-metal-compile-to-metallib=true']);
  });

  it('does not invent the flag for a binary without the Metal backend', () => {
    expect(buildCompileArgs(req, caps, { ...settings, metalToolchainAvailable: false }).args.join(' ')).not.toContain('compile-to-metallib');
  });
});

describe('diagnostics', () => {
  it('parses a real iree-compile error', () => {
    const d = parseDiagnostics(readFileSync(fixture('probe', 'compile-error.txt'), 'utf8'));
    expect(d).toEqual([{ file: 'bad.mlir', line: 2, col: 23, severity: 'error', message: 'use of undeclared SSA value name' }]);
  });
  it('ignores unknown locations', () => {
    expect(parseDiagnostics('<unknown>:0: error: nope\nloc("x"):1:2: error: y')).toEqual([]);
  });
});
