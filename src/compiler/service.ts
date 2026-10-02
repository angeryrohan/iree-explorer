// CompilerService: the only place that spawns processes. Owns binary
// discovery, capability probing (cached per version), dump directory
// management, stderr streaming, cancellation and diagnostics.

import { spawn, ChildProcess } from 'child_process';
import { createWriteStream, promises as fs, constants as fsConstants } from 'fs';
import * as path from 'path';
import * as vscode from 'vscode';
import { DumpMeta, gcDumpDirs, META_FILE, newDumpDirName, STDERR_FILE } from '../model/artifacts';
import { Capabilities, CompileRequest, Diagnostic } from '../model/types';
import { parseDiagnostics } from './diagnostics';
import { buildCompileArgs, DUMP_SUBDIRS, targetKind } from './flags';
import {
  deserializeCapabilities, probeCapabilities, SerializedCapabilities, serializeCapabilities,
} from './probe';

export interface CompileResult {
  exitCode: number | null;
  cancelled: boolean;
  durationMs: number;
  outputPath: string;
  dumpDir: string;
  diagnostics: Diagnostic[];
  warnings: string[];
}

const CAPS_KEY_PREFIX = 'ireeExplorer.caps:';

function cfg() {
  return vscode.workspace.getConfiguration('ireeExplorer');
}

async function isExecutable(p: string): Promise<boolean> {
  try {
    await fs.access(p, fsConstants.X_OK);
    const st = await fs.stat(p);
    return st.isFile();
  } catch {
    return false;
  }
}

async function findOnPath(name: string): Promise<string | undefined> {
  const exts = process.platform === 'win32' ? ['.exe', '.cmd', ''] : [''];
  for (const dir of (process.env.PATH ?? '').split(path.delimiter)) {
    if (!dir) {
      continue;
    }
    for (const ext of exts) {
      const p = path.join(dir, name + ext);
      if (await isExecutable(p)) {
        return p;
      }
    }
  }
  return undefined;
}

export class CompilerService implements vscode.Disposable {
  private inflight: { abort: AbortController; done: Promise<unknown> } | undefined;
  private capsPromise: Promise<Capabilities | undefined> | undefined;
  private promptedForBinary = false;
  private versionString: string | undefined;
  private readonly onDidChangeCapsEmitter = new vscode.EventEmitter<Capabilities | undefined>();
  readonly onDidChangeCapabilities = this.onDidChangeCapsEmitter.event;
  private readonly onDidChangeBusyEmitter = new vscode.EventEmitter<boolean>();
  readonly onDidChangeBusy = this.onDidChangeBusyEmitter.event;

  constructor(
    private readonly context: vscode.ExtensionContext,
    readonly output: vscode.OutputChannel,
    private readonly diagnostics: vscode.DiagnosticCollection,
  ) {}

  dispose(): void {
    this.inflight?.abort.abort();
    this.onDidChangeCapsEmitter.dispose();
    this.onDidChangeBusyEmitter.dispose();
  }

  get busy(): boolean {
    return this.inflight !== undefined;
  }

  get version(): string | undefined {
    return this.versionString;
  }

  log(msg: string): void {
    this.output.appendLine(`[${new Date().toLocaleTimeString()}] ${msg}`);
  }

  // -------------------------------------------------------------------------
  // Binary discovery
  // -------------------------------------------------------------------------

  /** Setting → PATH → one-time "Locate iree-compile" prompt. */
  async resolveCompiler(interactive: boolean): Promise<string | undefined> {
    const configured = expandHome(cfg().get<string>('compilerPath', '').trim());
    if (configured) {
      if (await isExecutable(configured)) {
        return configured;
      }
      this.log(`ireeExplorer.compilerPath "${configured}" is not an executable file.`);
    }
    const onPath = await findOnPath('iree-compile');
    if (onPath) {
      return onPath;
    }
    if (!interactive || this.promptedForBinary) {
      return undefined;
    }
    this.promptedForBinary = true;
    const pick = await vscode.window.showWarningMessage(
      'IREE Explorer could not find iree-compile (checked ireeExplorer.compilerPath and PATH).',
      'Locate iree-compile',
    );
    if (pick !== 'Locate iree-compile') {
      return undefined;
    }
    const uris = await vscode.window.showOpenDialog({ canSelectMany: false, openLabel: 'Use this iree-compile' });
    const chosen = uris?.[0]?.fsPath;
    if (!chosen || !(await isExecutable(chosen))) {
      if (chosen) {
        vscode.window.showErrorMessage(`${chosen} is not executable.`);
      }
      return undefined;
    }
    const target = vscode.workspace.workspaceFolders ? vscode.ConfigurationTarget.Workspace : vscode.ConfigurationTarget.Global;
    await cfg().update('compilerPath', chosen, target);
    return chosen;
  }

  async resolveOpt(): Promise<string> {
    const configured = expandHome(cfg().get<string>('optPath', '').trim());
    if (configured) {
      return configured;
    }
    const compiler = await this.resolveCompiler(false);
    if (compiler) {
      const sibling = path.join(path.dirname(compiler), process.platform === 'win32' ? 'iree-opt.exe' : 'iree-opt');
      if (await isExecutable(sibling)) {
        return sibling;
      }
    }
    return (await findOnPath('iree-opt')) ?? 'iree-opt';
  }

  // -------------------------------------------------------------------------
  // Capabilities
  // -------------------------------------------------------------------------

  /** Probes (or returns cached) capabilities. Undefined if probing failed. */
  getCapabilities(force = false): Promise<Capabilities | undefined> {
    if (!this.capsPromise || force) {
      this.capsPromise = this.loadCapabilities(force).then((c) => {
        this.onDidChangeCapsEmitter.fire(c);
        return c;
      });
    }
    return this.capsPromise;
  }

  invalidateCapabilities(): void {
    this.capsPromise = undefined;
    this.versionString = undefined;
  }

  private async loadCapabilities(force: boolean): Promise<Capabilities | undefined> {
    const bin = await this.resolveCompiler(false);
    if (!bin) {
      this.versionString = undefined;
      return undefined;
    }
    const run = (args: string[]) => this.runCapture(bin, args);
    const v = await run(['--version']);
    const version = v.output.split(/\r?\n/).filter((l) => /version/i.test(l)).join(' | ') || v.output.trim();
    this.versionString = version || undefined;
    const key = `${CAPS_KEY_PREFIX}${bin}::${version}`;
    // "(unknown)" versions (local dev builds) change without the string
    // changing, so also key on the binary's mtime.
    let mtime = 0;
    try {
      mtime = (await fs.stat(bin)).mtimeMs;
    } catch {
      // ignore
    }
    const fullKey = `${key}::${mtime}`;
    if (!force) {
      const cached = deserializeCapabilities(this.context.globalState.get<SerializedCapabilities>(fullKey));
      if (cached) {
        return cached;
      }
    }
    this.log(`Probing ${bin} (${version || 'unknown version'})…`);
    const caps = await probeCapabilities(run, (m) => this.log(m));
    if (caps) {
      await this.context.globalState.update(fullKey, serializeCapabilities(caps));
      this.log(
        `Probe: target-device=${caps.hasTargetDevice} target-backends=${caps.hasTargetBackends} ` +
        `backends=[${caps.registeredBackends.join(', ')}] compile-to=[${caps.compileToPhases.join(', ')}]` +
        (caps.compileToPhasesGuessed ? ' (GUESSED)' : ''),
      );
    }
    return caps;
  }

  async clearCapabilityCache(): Promise<void> {
    for (const k of this.context.globalState.keys()) {
      if (k.startsWith(CAPS_KEY_PREFIX)) {
        await this.context.globalState.update(k, undefined);
      }
    }
    this.invalidateCapabilities();
  }

  /** Runs a short-lived command, capturing stdout+stderr. Never rejects. */
  runCapture(bin: string, args: string[], timeoutMs = 30000): Promise<{ code: number | null; output: string }> {
    return new Promise((resolve) => {
      let out = '';
      let child: ChildProcess;
      try {
        child = spawn(bin, args, { stdio: ['ignore', 'pipe', 'pipe'] });
      } catch (e) {
        resolve({ code: null, output: String(e) });
        return;
      }
      const timer = setTimeout(() => child.kill('SIGKILL'), timeoutMs);
      child.stdout?.on('data', (d: Buffer) => { out += d.toString('utf8'); });
      child.stderr?.on('data', (d: Buffer) => { out += d.toString('utf8'); });
      child.on('error', (e) => {
        clearTimeout(timer);
        resolve({ code: null, output: `${out}\n${e.message}` });
      });
      child.on('close', (code) => {
        clearTimeout(timer);
        resolve({ code, output: out });
      });
    });
  }

  private metalToolchain: Promise<boolean | undefined> | undefined;

  /** `xcrun --find metal` succeeds (Xcode installed). Undefined off macOS. Cached per session. */
  hasMetalToolchain(): Promise<boolean | undefined> {
    if (process.platform !== 'darwin') {
      return Promise.resolve(undefined);
    }
    this.metalToolchain ??= this.runCapture('xcrun', ['--find', 'metal'], 10000).then((r) => r.code === 0);
    return this.metalToolchain;
  }

  // -------------------------------------------------------------------------
  // Dump dirs
  // -------------------------------------------------------------------------

  storageRoot(): string {
    const base = this.context.storageUri ?? this.context.globalStorageUri;
    return path.join(base.fsPath, 'dumps');
  }

  /** Creates `<root>/<timestamp>/` (root defaults to extension storage). */
  async createDumpDir(dumpBinaries: boolean, root = this.storageRoot()): Promise<string> {
    const dir = path.join(root, newDumpDirName());
    // iree-compile does not create parent dirs for the tree/dump flags.
    const subs: string[] = [DUMP_SUBDIRS.ir, DUMP_SUBDIRS.sources, DUMP_SUBDIRS.configs];
    if (dumpBinaries) {
      subs.push(DUMP_SUBDIRS.binaries, DUMP_SUBDIRS.intermediates);
    }
    for (const s of subs) {
      await fs.mkdir(path.join(dir, s), { recursive: true });
    }
    return dir;
  }

  // -------------------------------------------------------------------------
  // Compile
  // -------------------------------------------------------------------------

  cancel(): boolean {
    if (!this.inflight) {
      return false;
    }
    this.inflight.abort.abort();
    return true;
  }

  /**
   * Runs one compile. A new request cancels any in-flight one. `token` is a
   * withProgress cancellation token.
   */
  async compile(req: CompileRequest, token?: vscode.CancellationToken, onSpawn?: () => void): Promise<CompileResult> {
    if (this.inflight) {
      this.log('Cancelling the previous compile (a new one was requested).');
      this.inflight.abort.abort();
      await this.inflight.done.catch(() => undefined);
    }
    const abort = new AbortController();
    const sub = token?.onCancellationRequested(() => abort.abort());
    const p = this.compileImpl(req, abort.signal, onSpawn);
    this.inflight = { abort, done: p };
    this.onDidChangeBusyEmitter.fire(true);
    try {
      return await p;
    } finally {
      sub?.dispose();
      if (this.inflight?.abort === abort) {
        this.inflight = undefined;
        this.onDidChangeBusyEmitter.fire(false);
      }
    }
  }

  private async compileImpl(req: CompileRequest, signal: AbortSignal, onSpawn?: () => void): Promise<CompileResult> {
    const bin = await this.resolveCompiler(true);
    const started = Date.now();
    const base: Omit<CompileResult, 'exitCode' | 'cancelled' | 'durationMs'> = {
      outputPath: '', dumpDir: req.dumpDir, diagnostics: [], warnings: [],
    };
    if (!bin) {
      return { ...base, exitCode: null, cancelled: false, durationMs: 0, warnings: ['iree-compile not found.'] };
    }
    const caps = await this.getCapabilities();
    const c = cfg();
    const built = buildCompileArgs(req, caps, {
      elideAttrsLargerThan: c.get<number>('elideAttrsLargerThan', 16),
      dumpBinaries: c.get<boolean>('dumpBinaries', false),
      metalToolchainAvailable: targetKind(req.target).kind === 'Apple GPU (Metal)' ? await this.hasMetalToolchain() : undefined,
    });
    for (const w of built.warnings) {
      this.log(`warning: ${w}`);
    }

    const meta: DumpMeta = {
      inputPath: req.inputPath,
      targetId: req.target.id,
      targetLabel: req.target.label,
      args: built.args,
      compilerPath: bin,
      startedAt: started,
      outputPath: built.outputPath,
      sharedMemoryBudgetBytes: req.target.sharedMemoryBudgetBytes ?? c.get<number>('sharedMemoryBudgetBytes', 65536),
    };
    await fs.writeFile(path.join(req.dumpDir, META_FILE), JSON.stringify(meta, null, 2));

    this.output.appendLine('');
    this.log(`$ ${[bin, ...built.args].map(shq).join(' ')}`);

    const cwd = path.dirname(req.inputPath);
    const stderrLog = createWriteStream(path.join(req.dumpDir, STDERR_FILE));
    const diags: Diagnostic[] = [];
    const pendingLines: string[] = [];
    const flush = () => {
      if (pendingLines.length > 0) {
        this.output.append(pendingLines.join('\n') + '\n');
        pendingLines.length = 0;
      }
    };
    const flushTimer = setInterval(flush, 100);

    const exit = await new Promise<{ code: number | null; cancelled: boolean }>((resolve) => {
      if (signal.aborted) {
        resolve({ code: null, cancelled: true });
        return;
      }
      let child: ChildProcess;
      try {
        child = spawn(bin, built.args, { cwd, stdio: ['ignore', 'pipe', 'pipe'] });
      } catch (e) {
        this.log(`spawn failed: ${String(e)}`);
        resolve({ code: null, cancelled: false });
        return;
      }
      onSpawn?.();
      let cancelled = false;
      let killTimer: NodeJS.Timeout | undefined;
      const onAbort = () => {
        cancelled = true;
        this.log(`Cancelling iree-compile (pid ${child.pid})…`);
        child.kill('SIGTERM');
        killTimer = setTimeout(() => child.kill('SIGKILL'), 3000);
      };
      signal.addEventListener('abort', onAbort, { once: true });

      let partial = '';
      const onData = (d: Buffer) => {
        stderrLog.write(d);
        const text = partial + d.toString('utf8');
        const lines = text.split(/\r?\n/);
        partial = lines.pop() ?? '';
        for (const l of lines) {
          pendingLines.push(l);
          const parsed = parseDiagnostics(l);
          if (parsed.length > 0) {
            diags.push(...parsed);
          }
        }
      };
      child.stderr?.on('data', onData);
      child.stdout?.on('data', onData);
      child.on('error', (e) => {
        this.log(`iree-compile error: ${e.message}`);
      });
      child.on('close', (code) => {
        if (partial) {
          pendingLines.push(partial);
          diags.push(...parseDiagnostics(partial));
        }
        if (killTimer) {
          clearTimeout(killTimer);
        }
        signal.removeEventListener('abort', onAbort);
        resolve({ code, cancelled });
      });
    });

    clearInterval(flushTimer);
    flush();
    await new Promise<void>((r) => stderrLog.end(r));

    const durationMs = Date.now() - started;
    meta.durationMs = durationMs;
    meta.exitCode = exit.code;
    meta.cancelled = exit.cancelled;
    await fs.writeFile(path.join(req.dumpDir, META_FILE), JSON.stringify(meta, null, 2)).catch(() => undefined);

    this.publishDiagnostics(diags, cwd);
    this.log(
      exit.cancelled ? `Cancelled after ${durationMs} ms.`
        : `iree-compile exited with ${exit.code} after ${durationMs} ms.`,
    );

    const keep = c.get<number>('keepDumpDirs', 3);
    const removed = await gcDumpDirs(path.dirname(req.dumpDir), keep, req.dumpDir);
    if (removed.length > 0) {
      this.log(`Removed ${removed.length} old dump dir(s).`);
    }

    return {
      ...base,
      outputPath: built.outputPath,
      exitCode: exit.code,
      cancelled: exit.cancelled,
      durationMs,
      diagnostics: diags,
      warnings: built.warnings,
    };
  }

  private publishDiagnostics(diags: Diagnostic[], cwd: string): void {
    this.diagnostics.clear();
    const byFile = new Map<string, vscode.Diagnostic[]>();
    for (const d of diags) {
      const file = path.isAbsolute(d.file) ? d.file : path.resolve(cwd, d.file);
      const line = Math.max(0, d.line - 1);
      const col = Math.max(0, d.col - 1);
      const sev = d.severity === 'error' ? vscode.DiagnosticSeverity.Error
        : d.severity === 'warning' ? vscode.DiagnosticSeverity.Warning
          : vscode.DiagnosticSeverity.Information;
      const diag = new vscode.Diagnostic(new vscode.Range(line, col, line, col + 1), d.message, sev);
      diag.source = 'iree-compile';
      const list = byFile.get(file) ?? [];
      list.push(diag);
      byFile.set(file, list);
    }
    for (const [file, list] of byFile) {
      this.diagnostics.set(vscode.Uri.file(file), list);
    }
  }
}

function expandHome(p: string): string {
  if (p.startsWith('~/')) {
    return path.join(process.env.HOME ?? '', p.slice(2));
  }
  return p;
}

function shq(s: string): string {
  return /^[\w@%+=:,./-]+$/.test(s) ? s : `'${s.replace(/'/g, `'\\''`)}'`;
}
