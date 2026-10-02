// Target profile registry: built-ins + probed backends + user settings, and
// the persisted active selection.

import * as vscode from 'vscode';
import { Capabilities, TargetProfile } from '../model/types';
import {
  BUILTIN_TARGETS, mergeTargets, probedTargets, sanitizeCustomTargets, targetAvailability, targetKind,
} from './flags';
import {
  BACKEND_OPTIONS, backendBuildBytes, canFreeSpace, diskNeededBytes, diskVerdict, findBuild, formatGB, freeDiskBytes,
  rebuildCommand,
} from './rebuild';

function cfg() {
  return vscode.workspace.getConfiguration('ireeExplorer');
}

function settingsTarget(): vscode.ConfigurationTarget {
  return vscode.workspace.workspaceFolders ? vscode.ConfigurationTarget.Workspace : vscode.ConfigurationTarget.Global;
}

export class TargetManager implements vscode.Disposable {
  private caps: Capabilities | undefined;
  private readonly emitter = new vscode.EventEmitter<TargetProfile | undefined>();
  readonly onDidChange = this.emitter.event;
  private readonly subs: vscode.Disposable[] = [];
  private reportedProblems = new Set<string>();

  constructor(private readonly log: (m: string) => void) {
    this.subs.push(vscode.workspace.onDidChangeConfiguration((e) => {
      if (e.affectsConfiguration('ireeExplorer.activeTarget') || e.affectsConfiguration('ireeExplorer.targets')) {
        this.emitter.fire(this.active());
      }
    }));
  }

  dispose(): void {
    this.emitter.dispose();
    this.subs.forEach((s) => s.dispose());
  }

  setCapabilities(caps: Capabilities | undefined): void {
    this.caps = caps;
    this.emitter.fire(this.active());
  }

  all(): TargetProfile[] {
    const { targets, problems } = sanitizeCustomTargets(cfg().get<unknown>('targets', []));
    for (const p of problems) {
      if (!this.reportedProblems.has(p)) {
        this.reportedProblems.add(p);
        this.log(`settings: ${p}`);
      }
    }
    return mergeTargets(BUILTIN_TARGETS, probedTargets(this.caps), targets);
  }

  active(): TargetProfile | undefined {
    const id = cfg().get<string>('activeTarget', '');
    const all = this.all();
    if (id) {
      const t = all.find((x) => x.id === id);
      if (t) {
        return t;
      }
    }
    // Default: first built-in the binary actually has, else llvm-cpu.
    return all.find((t) => targetAvailability(t, this.caps) === 'yes') ?? all.find((t) => t.id === 'llvm-cpu-host');
  }

  async setActive(id: string): Promise<void> {
    await cfg().update('activeTarget', id, settingsTarget());
    this.emitter.fire(this.active());
  }

  /** Targets for the menu: everything not known to be missing from the build. */
  visible(): TargetProfile[] {
    const activeId = cfg().get<string>('activeTarget', '');
    return this.all().filter((t) => t.id === activeId || targetAvailability(t, this.caps) !== 'no');
  }

  private describe(t: TargetProfile): { label: string; description: string; detail: string } {
    const k = targetKind(t);
    const flags = [t.device ? `device=${t.device}` : '', t.backend ? `backend=${t.backend}` : '', ...t.deviceFlags].filter(Boolean).join(' ');
    const avail = targetAvailability(t, this.caps);
    return {
      label: `$(${k.icon}) ${t.label}`,
      description: `${k.kind}${avail === 'no' ? ' · not in this build' : ''}`,
      detail: flags,
    };
  }

  async pick(): Promise<TargetProfile | undefined> {
    type Item = vscode.QuickPickItem & { profile?: TargetProfile; manage?: boolean };
    const activeId = this.active()?.id;
    const items: Item[] = this.visible().map((t) => {
      const d = this.describe(t);
      return { ...d, label: `${d.label}${t.id === activeId ? '  $(check)' : ''}`, profile: t };
    });
    items.push({ label: '', kind: vscode.QuickPickItemKind.Separator });
    items.push({ label: '$(settings-gear) Manage targets…', detail: 'Add or remove a backend in your iree-compile, or add a custom target', manage: true });
    const choice = await vscode.window.showQuickPick(items, {
      title: 'IREE target',
      placeHolder: this.caps?.registeredBackends.length
        ? `Backends in your iree-compile: ${this.caps.registeredBackends.join(', ')}`
        : 'Backend list not available from this iree-compile; built-ins shown',
      matchOnDetail: true,
    });
    if (!choice) {
      return undefined;
    }
    if (choice.manage) {
      await vscode.commands.executeCommand('ireeExplorer.manageTargets');
      return undefined;
    }
    if (choice.profile) {
      await this.setActive(choice.profile.id);
      return choice.profile;
    }
    return undefined;
  }

  /** "Manage targets" entry point. */
  async manage(compilerPath: string | undefined): Promise<void> {
    const pick = await vscode.window.showQuickPick([
      { label: '$(add) Add a backend to your iree-compile…', detail: 'Rebuilds your local IREE build with an extra backend (e.g. metal, cuda); checks disk space first', v: 'add' },
      { label: '$(remove) Remove a backend from your iree-compile…', detail: 'Rebuilds without it and deletes its build files: smaller iree-compile, faster rebuilds, some disk freed', v: 'remove' },
      { label: '$(plug) Add a custom target…', detail: 'A plugin backend (e.g. LLForge dummy) plus extra flags', v: 'custom' },
    ], { title: 'Manage IREE targets' });
    if (pick?.v === 'add') {
      await this.changeBackend(compilerPath, true);
    } else if (pick?.v === 'remove') {
      await this.changeBackend(compilerPath, false);
    } else if (pick?.v === 'custom') {
      await this.addCustom();
    }
  }

  /** Adds (enable) or removes a built-in backend by reconfiguring + rebuilding the local build. */
  private async changeBackend(compilerPath: string | undefined, enable: boolean): Promise<void> {
    if (!compilerPath) {
      vscode.window.showErrorMessage('IREE: set ireeExplorer.compilerPath first.');
      return;
    }
    const build = await findBuild(compilerPath);
    if (!build) {
      vscode.window.showWarningMessage(
        `IREE: ${compilerPath} is not part of a local CMake build (no CMakeCache.txt found above it), so it can't be rebuilt from here. ` +
        'If it came from pip (iree-base-compiler), install a build with the backends you want instead.',
      );
      return;
    }
    const have = new Set(this.caps?.registeredBackends ?? []);
    const inBuild = (b: (typeof BACKEND_OPTIONS)[number]) => have.has(b.backend) || build.enabled.get(b.backend) === true;
    const candidates = BACKEND_OPTIONS.filter((b) => (enable ? !inBuild(b) : inBuild(b)));
    if (candidates.length === 0) {
      vscode.window.showInformationMessage(enable
        ? 'IREE: every backend IREE can build is already in your iree-compile.'
        : 'IREE: no built-in backends to remove. (Plugin backends such as LLForge come from IREE_CMAKE_PLUGIN_PATHS, not these switches.)');
      return;
    }
    if (!enable && candidates.length === 1) {
      vscode.window.showWarningMessage(`IREE: ${candidates[0].label} is the only backend in your build; removing it would leave nothing to compile for.`);
      return;
    }

    const free = await freeDiskBytes(build.buildDir);
    const activeBackend = this.active()?.backend;
    // What removal frees: the backend's own build folders (measured now).
    const frees = new Map<string, number>();
    if (!enable) {
      for (const b of candidates) {
        frees.set(b.backend, await backendBuildBytes(build, b));
      }
    }
    const pick = await vscode.window.showQuickPick(
      candidates.map((b) => {
        const need = diskNeededBytes(build, b, enable);
        const v = free !== undefined ? diskVerdict(free, need) : undefined;
        const icon = v?.status === 'insufficient' ? '$(error) ' : v?.status === 'tight' ? '$(warning) ' : '';
        const warn = !enable && (b.removeWarning || b.backend === activeBackend) ? '$(warning) ' : '';
        return {
          label: `${enable ? icon : warn}${b.label}`,
          description: enable
            ? `rebuild ${b.estimate} · needs ~${formatGB(need)} disk`
            : `rebuild ~2–10 min · frees up to ~${formatGB(frees.get(b.backend) ?? 0)}`,
          detail: enable ? b.note : b.removeWarning,
          b,
        };
      }),
      {
        title: `${enable ? 'Add a backend to' : 'Remove a backend from'} ${build.buildDir}`,
        placeHolder: `${free !== undefined ? `${formatGB(free)} free on this disk. ` : ''}In your iree-compile now: ${[...have].join(', ') || 'unknown'}`,
      },
    );
    if (!pick) {
      return;
    }
    const b = pick.b;
    const need = diskNeededBytes(build, b, enable);
    const verdict = free !== undefined ? diskVerdict(free, need) : undefined;
    if (verdict?.status === 'insufficient') {
      // A build that runs out of disk half-way leaves the tree broken; don't start it.
      vscode.window.showErrorMessage(`IREE: can't ${enable ? 'add' : 'remove'} ${b.backend}. ${verdict.message}`, { modal: true });
      return;
    }

    const cmd = rebuildCommand(build, b, enable);
    const lines: string[] = [];
    if (enable) {
      lines.push(`This reconfigures ${build.buildDir} with ${b.cmake}=ON and rebuilds iree-compile and iree-opt (${b.estimate} on a typical laptop).`);
      if (b.note) {
        lines.push(b.note);
      }
    } else {
      lines.push(`This reconfigures ${build.buildDir} with ${b.cmake}=OFF and relinks iree-compile and iree-opt (~2–10 min).`);
      if (b.removeWarning) {
        lines.push(`Warning: ${b.removeWarning}`);
      }
      if (b.backend === activeBackend) {
        lines.push('Warning: this is the backend of your current target. Pick another target afterwards.');
      }
      const freed = frees.get(b.backend) ?? 0;
      if (canFreeSpace(build)) {
        lines.push(`Afterwards "ninja -t cleandead" deletes the build files the new configuration no longer produces: up to ~${formatGB(freed)} for ${b.backend} (code shared with other backends stays). Adding it back later means recompiling those files.`);
      } else {
        lines.push(`This build uses ${build.generator || 'a non-Ninja generator'}, so the old ${b.backend} build files (~${formatGB(freed)}) can't be cleaned automatically and stay on disk.`);
      }
    }
    lines.push('Your other build options, including plugins, are kept.');
    lines.push(verdict ? verdict.message : 'Free disk space could not be checked.');
    lines.push(`It runs in a terminal you can watch or stop:\n${cmd}`);
    const action = enable ? 'Rebuild' : 'Remove and Rebuild';
    const ok = await vscode.window.showWarningMessage(
      `${enable ? 'Add' : 'Remove'} ${b.label} ${enable ? 'to' : 'from'} iree-compile?`,
      { modal: true, detail: lines.join('\n\n') },
      action,
    );
    if (ok !== action) {
      return;
    }
    const term = vscode.window.createTerminal({ name: `IREE rebuild (${enable ? '+' : '-'}${b.backend})`, cwd: build.buildDir });
    term.show();
    term.sendText(cmd);
    this.log(`Rebuild started: ${cmd}`);
    vscode.window.showInformationMessage(`IREE: rebuilding ${enable ? 'with' : 'without'} ${b.backend}. The target menu updates by itself when iree-compile changes.`);
  }

  private async addCustom(): Promise<TargetProfile | undefined> {
    const name = await vscode.window.showInputBox({
      title: 'Custom IREE backend',
      prompt: 'Backend name for --iree-hal-target-backends (e.g. an out-of-tree plugin backend)',
      validateInput: (v) => (/^[\w.-]+$/.test(v.trim()) ? undefined : 'Letters, digits, ".", "_" and "-" only'),
    });
    if (!name) {
      return undefined;
    }
    const flags = await vscode.window.showInputBox({
      title: 'Extra flags for this target (optional)',
      prompt: 'Space-separated, e.g. --iree-dummy-enable-debug',
    });
    const profile: TargetProfile = {
      id: `custom-${name.trim()}`,
      label: name.trim(),
      backend: name.trim(),
      deviceFlags: [],
      extraFlags: (flags ?? '').split(/\s+/).filter((f) => f.length > 0),
    };
    const existing = cfg().get<unknown[]>('targets', []);
    const next = [...(Array.isArray(existing) ? existing : []).filter((e) => (e as { id?: string })?.id !== profile.id), {
      id: profile.id, label: profile.label, backend: profile.backend, deviceFlags: [], extraFlags: profile.extraFlags,
    }];
    await cfg().update('targets', next, settingsTarget());
    await this.setActive(profile.id);
    return { ...profile, source: 'custom' };
  }
}
