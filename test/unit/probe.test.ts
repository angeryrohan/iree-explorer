import { readFileSync } from 'fs';
import { describe, expect, it } from 'vitest';
import {
  buildCapabilities, deserializeCapabilities, FALLBACK_COMPILE_TO_PHASES, parseEnumValues, parseKnownFlags,
  parseTargetBackendList, parseVersion, probeCapabilities, serializeCapabilities,
} from '../../src/compiler/probe';
import { fixture } from './helpers';

const help = readFileSync(fixture('probe', 'help.txt'), 'utf8');
const hidden = readFileSync(fixture('probe', 'help-hidden.txt'), 'utf8');
const version = readFileSync(fixture('probe', 'version.txt'), 'utf8');
const backends = readFileSync(fixture('probe', 'list-target-backends.txt'), 'utf8');

describe('probe (real iree-compile help text)', () => {
  it('finds the flags the extension depends on', () => {
    const flags = parseKnownFlags(`${help}\n${hidden}`);
    for (const f of [
      'iree-hal-target-device', 'iree-hal-target-backends', 'compile-to', 'mlir-print-ir-tree-dir',
      'mlir-print-ir-after-all', 'iree-hal-dump-executable-sources-to', 'iree-hal-dump-executable-configurations-to',
      'mlir-elide-elementsattrs-if-larger', 'mlir-pass-statistics', 'mlir-timing', 'iree-hal-list-target-backends',
      'iree-llvmcpu-target-cpu', 'iree-vulkan-target', 'iree-hal-local-target-device-backends',
    ]) {
      expect(flags.has(f), f).toBe(true);
    }
    expect(flags.has('iree-definitely-not-a-flag')).toBe(false);
  });

  it('extracts --compile-to phases from help instead of hardcoding', () => {
    expect(parseEnumValues(help, 'compile-to')).toEqual([
      'start', 'input', 'abi', 'preprocessing', 'global-optimization', 'dispatch-creation', 'flow', 'stream',
      'executable-sources', 'executable-configurations', 'executable-targets', 'hal', 'vm', 'end',
    ]);
  });

  it('falls back to a guessed phase list when help has none', () => {
    const caps = buildCapabilities('v', '  --foo  - bar', undefined);
    expect(caps.compileToPhases).toEqual(FALLBACK_COMPILE_TO_PHASES);
    expect(caps.compileToPhasesGuessed).toBe(true);
    expect(caps.hasTargetDevice).toBe(false);
  });

  it('parses version and backend list', () => {
    expect(parseVersion(version)).toMatch(/IREE compiler version/);
    expect(parseTargetBackendList(backends)).toEqual(['dummy', 'llvm-cpu', 'vmvx', 'vmvx-inline', 'vulkan-spirv']);
    expect(parseTargetBackendList('garbage')).toBeUndefined();
  });

  it('probeCapabilities drives the runner and round-trips through serialization', async () => {
    const outputs: Record<string, string> = {
      '--version': version, '--help': help, '--help-hidden': hidden, '--iree-hal-list-target-backends': backends,
    };
    const caps = await probeCapabilities(async (args) => ({ code: 0, output: outputs[args[0]] ?? '' }), () => undefined);
    expect(caps?.hasTargetDevice).toBe(true);
    expect(caps?.registeredBackends).toContain('vulkan-spirv');
    const rt = deserializeCapabilities(JSON.parse(JSON.stringify(serializeCapabilities(caps!))));
    expect(rt?.knownFlags.has('mlir-timing')).toBe(true);
  });

  it('returns undefined when the binary fails', async () => {
    const logs: string[] = [];
    const caps = await probeCapabilities(async () => ({ code: null, output: 'ENOENT' }), (m) => logs.push(m));
    expect(caps).toBeUndefined();
    expect(logs.length).toBeGreaterThan(0);
  });
});
