// Capability detection against the iree-compile binary. The parsing functions
// here are pure; the actual process execution is injected (it always goes
// through CompilerService).

import { Capabilities } from '../model/types';

/** Used only when --compile-to values cannot be extracted from --help. */
export const FALLBACK_COMPILE_TO_PHASES = [
  'input', 'abi', 'preprocessing', 'global-optimization', 'dispatch-creation',
  'flow', 'stream', 'executable-sources', 'executable-configurations',
  'executable-targets', 'hal', 'vm', 'end',
];

/** Collects every `--flag` name that begins an option line in LLVM cl help output. */
export function parseKnownFlags(helpText: string): Set<string> {
  const flags = new Set<string>();
  const re = /^\s{1,8}--?([A-Za-z0-9][\w.-]*)(?:[=\s<]|$)/gm;
  for (let m = re.exec(helpText); m; m = re.exec(helpText)) {
    flags.add(m[1]);
  }
  return flags;
}

/**
 * Extracts enum values listed under an option, e.g.
 *   --compile-to=<value>   - ...
 *     =start               -   Entry point ...
 *     =input               -   ...
 */
export function parseEnumValues(helpText: string, flag: string): string[] | undefined {
  const lines = helpText.split(/\r?\n/);
  const header = new RegExp(`^\\s*--${escapeRe(flag)}=<`);
  const idx = lines.findIndex((l) => header.test(l));
  if (idx < 0) {
    return undefined;
  }
  const values: string[] = [];
  for (let i = idx + 1; i < lines.length; i++) {
    const m = /^\s+=([\w.-]+)\s/.exec(lines[i]) ?? /^\s+=([\w.-]+)$/.exec(lines[i]);
    if (!m) {
      break;
    }
    values.push(m[1]);
  }
  return values.length > 0 ? values : undefined;
}

export function parseVersion(versionText: string): string | undefined {
  const lines = versionText.split(/\r?\n/).map((l) => l.trim()).filter((l) => l.length > 0);
  if (lines.length === 0) {
    return undefined;
  }
  // Keep the IREE and LLVM version lines; drop the URL banner.
  const interesting = lines.filter((l) => /version/i.test(l));
  return (interesting.length > 0 ? interesting : lines).join(' | ');
}

/** Parses the output of `--iree-hal-list-target-backends`. */
export function parseTargetBackendList(text: string): string[] | undefined {
  const lines = text.split(/\r?\n/);
  const start = lines.findIndex((l) => /registered target backends/i.test(l));
  if (start < 0) {
    return undefined;
  }
  const out: string[] = [];
  for (let i = start + 1; i < lines.length; i++) {
    const m = /^\s+([\w.-]+)\s*$/.exec(lines[i]);
    if (!m) {
      if (lines[i].trim().length === 0) {
        continue;
      }
      break;
    }
    out.push(m[1]);
  }
  return out;
}

export function buildCapabilities(
  version: string,
  helpText: string,
  registeredBackends: string[] | undefined,
): Capabilities {
  const knownFlags = parseKnownFlags(helpText);
  const phases = parseEnumValues(helpText, 'compile-to');
  return {
    version,
    knownFlags,
    hasTargetDevice: knownFlags.has('iree-hal-target-device'),
    hasTargetBackends: knownFlags.has('iree-hal-target-backends'),
    compileToPhases: phases ?? FALLBACK_COMPILE_TO_PHASES,
    compileToPhasesGuessed: phases === undefined,
    hasListTargetBackends: knownFlags.has('iree-hal-list-target-backends'),
    registeredBackends: registeredBackends ?? [],
  };
}

export interface ProbeRunner {
  /** Runs iree-compile with args, resolves stdout+stderr (never rejects on non-zero exit). */
  (args: string[]): Promise<{ code: number | null; output: string }>;
}

export interface ProbeLog {
  (message: string): void;
}

/** Runs --version, --help, --help-hidden and the backend listing. */
export async function probeCapabilities(run: ProbeRunner, log: ProbeLog): Promise<Capabilities | undefined> {
  const versionRes = await run(['--version']);
  const version = parseVersion(versionRes.output);
  if (versionRes.code !== 0 || version === undefined) {
    log(`probe: 'iree-compile --version' failed (exit ${versionRes.code})`);
    return undefined;
  }
  const help = await run(['--help']);
  const hidden = await run(['--help-hidden']);
  const helpText = `${help.output}\n${hidden.output}`;
  if (helpText.trim().length === 0) {
    log('probe: --help produced no output');
  }
  let backends: string[] | undefined;
  if (parseKnownFlags(helpText).has('iree-hal-list-target-backends')) {
    const list = await run(['--iree-hal-list-target-backends']);
    backends = parseTargetBackendList(list.output);
    if (!backends) {
      log('probe: could not parse --iree-hal-list-target-backends output');
    }
  }
  const caps = buildCapabilities(version, helpText, backends);
  if (caps.compileToPhasesGuessed) {
    log(`probe: could not extract --compile-to values from help; using a GUESSED list: ${caps.compileToPhases.join(', ')}`);
  }
  return caps;
}

/** Capabilities are cached in globalState; Sets don't serialise. */
export interface SerializedCapabilities extends Omit<Capabilities, 'knownFlags'> {
  knownFlags: string[];
}

export function serializeCapabilities(c: Capabilities): SerializedCapabilities {
  return { ...c, knownFlags: [...c.knownFlags] };
}

export function deserializeCapabilities(s: SerializedCapabilities | undefined): Capabilities | undefined {
  if (!s || !Array.isArray(s.knownFlags)) {
    return undefined;
  }
  return { ...s, knownFlags: new Set(s.knownFlags) };
}

function escapeRe(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
