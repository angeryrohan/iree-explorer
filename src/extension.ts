// Activation and wiring only. Logic lives in compiler/, model/ and views/.

import { promises as fs } from 'fs';
import * as path from 'path';
import * as vscode from 'vscode';
import { CompilerService } from './compiler/service';
import { TargetManager } from './compiler/targets';
import {
  DispatchArtifact, EXTENSION_STORAGE, gcDumpDirs, indexDump, IndexedDump, listDumpDirs, resolveOutputRoot, watchDir,
} from './model/artifacts';
import { findFlowDump, FlowProgram, parseFlowProgram } from './model/dataflow';
import { diffOps, OpDiffView } from './model/opdiff';
import { prepareRepro, previousInScope } from './model/pipeline';
import { PassNode } from './model/types';
import { DispatchSort, DispatchTreeProvider } from './views/dispatchTree';
import { DumpFile, DumpFilesTreeProvider } from './views/dumpFilesTree';
import { PassSort, PipelineElement, PipelineTreeProvider } from './views/pipelineTree';
import { IreeStatusBar } from './views/statusBar';
import { DataFlowPanel } from './views/dataFlowPanel';
import { OpDiffPanel } from './views/opDiffPanel';
import { TilingPanel } from './views/tilingPanel';

const LAST_DUMP_KEY = 'ireeExplorer.lastDumpDir';

function settingsTarget(): vscode.ConfigurationTarget {
  return vscode.workspace.workspaceFolders ? vscode.ConfigurationTarget.Workspace : vscode.ConfigurationTarget.Global;
}

const MLIR_EXTENSION_IDS = ['llvm-vs-code-extensions.vscode-mlir', 'llvm-vs-code-extensions.mlir'];

function cfg() {
  return vscode.workspace.getConfiguration('ireeExplorer');
}

function isPass(e: unknown): e is PassNode {
  return typeof e === 'object' && e !== null && typeof (e as PassNode).filePath === 'string' && Array.isArray((e as PassNode).ordinalPath);
}

function isDispatch(e: unknown): e is DispatchArtifact {
  return typeof e === 'object' && e !== null && typeof (e as DispatchArtifact).info === 'object';
}

/** Returned from activate(); used by integration tests. */
export interface IreeExplorerApi {
  loadDump(dir: string): Promise<void>;
  passes(): PassNode[];
  dispatches(): DispatchArtifact[];
  tilingOpen(): boolean;
  dataFlowOpen(): boolean;
  opDiffOpen(): boolean;
  dataFlowRow(): boolean;
  currentDump(): { dir: string; outputPath?: string; exitCode?: number | null; cancelled?: boolean } | undefined;
}

export function activate(context: vscode.ExtensionContext): IreeExplorerApi {
  const output = vscode.window.createOutputChannel('IREE Explorer');
  const diagnostics = vscode.languages.createDiagnosticCollection('iree');
  const service = new CompilerService(context, output, diagnostics);
  const log = (m: string) => service.log(m);
  const targets = new TargetManager(log);
  const status = new IreeStatusBar();
  const pipeline = new PipelineTreeProvider();
  const dispatchTree = new DispatchTreeProvider();
  const tiling = new TilingPanel(context.extensionUri, log);
  const dataFlow = new DataFlowPanel(context.extensionUri, (entry) => {
    const d = dispatchTree.dispatches.find((x) => x.info.name === entry);
    if (d) {
      void vscode.commands.executeCommand('ireeExplorer.showTiling', d);
    } else {
      vscode.window.showInformationMessage(`IREE: ${entry} has no dumped configuration (compile past executable-configurations to see its tiling).`);
    }
  });
  const opDiff = new OpDiffPanel(context.extensionUri, (v) => {
    void vscode.commands.executeCommand(
      'vscode.diff', vscode.Uri.file(v.before.file), vscode.Uri.file(v.after.file),
      `${v.before.label} ↔ ${v.after.label}`, { preview: true },
    );
  });

  const pipelineView = vscode.window.createTreeView<PipelineElement>('ireeExplorer.pipeline', {
    treeDataProvider: pipeline, canSelectMany: true, showCollapseAll: true,
  });
  const dispatchView = vscode.window.createTreeView('ireeExplorer.dispatches', {
    treeDataProvider: dispatchTree, showCollapseAll: true,
  });
  const dumpFiles = new DumpFilesTreeProvider();
  const dumpFilesView = vscode.window.createTreeView<DumpFile>('ireeExplorer.dumpFiles', {
    treeDataProvider: dumpFiles, showCollapseAll: true,
  });

  context.subscriptions.push(output, diagnostics, service, targets, status, tiling, dataFlow, opDiff, pipelineView, dispatchView, dumpFilesView);

  let current: IndexedDump | undefined;
  let indexing: Promise<void> | undefined;

  // -------------------------------------------------------------------------
  // Model refresh
  // -------------------------------------------------------------------------

  async function loadDump(dir: string, quiet = false): Promise<void> {
    const run = async () => {
      const idx = await indexDump(dir);
      current = idx;
      pipeline.setPasses(idx.passes);
      // Dispatches imply the compile got past flow; otherwise look for a flow dump.
      dispatchTree.setDispatches(idx.dispatches, idx.dispatches.length > 0 || ((await loadFlowProgram())?.graphs.length ?? 0) > 0);
      const changed = idx.passes.filter((p) => p.changed && !p.container).length;
      pipelineView.description = idx.meta
        ? `${idx.meta.targetLabel} · ${path.basename(idx.meta.inputPath)}`
        : path.basename(dir);
      pipelineView.message = idx.passes.length > 0
        ? `${idx.passes.length} pass invocations, ${changed} changed the IR${idx.timingsMatched > 0 ? '' : ' · no timing matched'}`
        : undefined;
      dispatchView.description = idx.dispatches.length > 0 ? `${idx.dispatches.length}` : undefined;
      dumpFiles.setRoot(dir);
      dumpFilesView.description = path.basename(dir);
      void context.workspaceState.update(LAST_DUMP_KEY, dir);
      void vscode.commands.executeCommand('setContext', 'ireeExplorer.hasDump', true);
      if (!quiet) {
        for (const p of idx.problems) {
          log(`index: ${p}`);
        }
      }
      if (dataFlow.isOpen && !quiet) {
        dataFlow.update(await loadFlowProgram());
      }
      if (!quiet) {
        // The dumps it compared were overwritten.
        opDiff.close();
      }
      // Keep the tiling panel on the same dispatch across recompiles.
      const shown = tiling.visibleDispatch;
      if (shown) {
        const same = idx.dispatches.find((d) => d.info.name === shown.name);
        tiling.update(same?.info, same ? undefined : `Dispatch ${shown.name} is not in the latest compile.`);
      }
    };
    // Serialise indexing runs.
    const prev = indexing ?? Promise.resolve();
    const next = prev.then(run, run).catch((e) => log(`index failed: ${String(e)}`));
    indexing = next;
    await next;
  }

  /** The flow-level program of the current compile (for the Data Flow panel). */
  async function loadFlowProgram(): Promise<FlowProgram | undefined> {
    if (!current) {
      return undefined;
    }
    const readText = (f: string) => fs.readFile(f, 'utf8').then((t) => t, () => undefined);
    // A "stop after flow/stream" compile writes the flow module as its output.
    const out = current.meta?.outputPath;
    if (out && /\.(flow|dispatch-creation)\.mlir$/.test(out)) {
      const text = await readText(out);
      if (text && /flow\.dispatch @/.test(text)) {
        return parseFlowProgram(text, out);
      }
    }
    const found = await findFlowDump(current.passes, readText);
    return found ? parseFlowProgram(found.text, found.file) : undefined;
  }

  async function refreshCompilerInfo(force = false): Promise<void> {
    const bin = await service.resolveCompiler(false);
    const caps = await service.getCapabilities(force);
    targets.setCapabilities(caps);
    status.setCompiler(bin, service.version);
    if (bin && !caps) {
      log('Capability probing failed; the extension will pass flags unverified.');
    }
  }

  // -------------------------------------------------------------------------
  // Compile
  // -------------------------------------------------------------------------

  async function resolveInput(): Promise<string | undefined> {
    const entry = cfg().get<string>('entryFile', '').trim();
    if (entry) {
      const ws = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
      return path.isAbsolute(entry) ? entry : ws ? path.join(ws, entry) : entry;
    }
    const doc = vscode.window.activeTextEditor?.document;
    const storage = service.storageRoot();
    if (doc && doc.uri.scheme === 'file' && !doc.uri.fsPath.startsWith(storage)) {
      if (doc.isDirty) {
        await doc.save();
      }
      return doc.uri.fsPath;
    }
    // Active editor is a dump / panel: reuse the last input.
    if (current?.meta?.inputPath) {
      return current.meta.inputPath;
    }
    return undefined;
  }

  /**
   * Where dump folders go. Asks once (first compile) and saves the answer to
   * ireeExplorer.outputDir. Returns undefined if the user dismissed the prompt.
   */
  async function outputRootFor(input: string, forcePrompt = false): Promise<string | undefined> {
    const ws = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    let setting = cfg().get<string>('outputDir', '');
    if (!setting || forcePrompt) {
      type Item = vscode.QuickPickItem & { value?: string; choose?: boolean };
      const items: Item[] = [
        { label: '$(folder) Next to the input file', description: 'recommended', detail: path.join(path.dirname(input), 'iree-out'), value: '${inputDir}/iree-out' },
      ];
      if (ws) {
        items.push({ label: '$(root-folder) Workspace root', detail: path.join(ws, '.iree-explorer'), value: '${workspaceFolder}/.iree-explorer' });
      }
      items.push(
        { label: '$(folder-opened) Choose a folder…', choose: true },
        { label: '$(eye-closed) Hidden (VS Code extension storage)', detail: service.storageRoot(), value: EXTENSION_STORAGE },
      );
      const pick = await vscode.window.showQuickPick(items, {
        title: 'Where should IREE Explorer put compile output (dumps + .vmfb)?',
        placeHolder: `Each compile gets its own timestamped folder here; only the last ${cfg().get<number>('keepDumpDirs', 3)} are kept.`,
        ignoreFocusOut: true,
      });
      if (!pick) {
        return undefined;
      }
      if (pick.choose) {
        const uris = await vscode.window.showOpenDialog({ canSelectFolders: true, canSelectFiles: false, openLabel: 'Use this folder' });
        if (!uris?.[0]) {
          return undefined;
        }
        setting = uris[0].fsPath;
      } else {
        setting = pick.value ?? EXTENSION_STORAGE;
      }
      await cfg().update('outputDir', setting, settingsTarget());
    }
    return resolveOutputRoot(setting, input, ws) ?? service.storageRoot();
  }

  async function compile(opts?: { compileTo?: string }): Promise<void> {
    const input = await resolveInput();
    if (!input) {
      vscode.window.showErrorMessage('IREE: open an .mlir file or set ireeExplorer.entryFile.');
      return;
    }
    const bin = await service.resolveCompiler(true);
    if (!bin) {
      return;
    }
    let target = targets.active();
    if (!target) {
      target = await targets.pick();
      if (!target) {
        return;
      }
    }
    const root = await outputRootFor(input);
    if (!root) {
      return;
    }
    const stopAfter = opts?.compileTo ?? cfg().get<string>('compileTo', 'end');
    const compileTo = stopAfter && stopAfter !== 'end' ? stopAfter : undefined;
    const dumpDir = await service.createDumpDir(cfg().get<boolean>('dumpBinaries', false), root);
    const extraFlags = cfg().get<string[]>('extraFlags', []);
    const name = path.basename(input);

    let stopWatch: (() => void) | undefined;
    const result = await vscode.window.withProgress(
      {
        location: vscode.ProgressLocation.Notification,
        title: `IREE: compiling ${name} for ${target.label}${compileTo ? ` (stop after ${compileTo})` : ''}`,
        cancellable: true,
      },
      (_progress, token) => service.compile(
        { inputPath: input, target: target!, dumpDir, extraFlags, compileTo },
        token,
        () => {
          // Live-fill the pipeline tree while the compile runs.
          stopWatch = watchDir(path.join(dumpDir, 'ir'), () => { void loadDump(dumpDir, true); }, 1500);
        },
      ),
    );
    stopWatch?.();
    await loadDump(dumpDir);

    for (const w of result.warnings) {
      if (/not supported|no usable|not listed/.test(w)) {
        vscode.window.showWarningMessage(`IREE: ${w}`);
      }
    }

    const secs = (result.durationMs / 1000).toFixed(2);
    if (result.cancelled) {
      vscode.window.showInformationMessage(`IREE: compile of ${name} cancelled after ${secs}s.`);
      return;
    }
    if (result.exitCode !== 0) {
      const first = result.diagnostics.find((d) => d.severity === 'error');
      // Notifications are not awaited: the command resolves when the compile does.
      void vscode.window.showErrorMessage(
        `IREE: compile failed (exit ${result.exitCode ?? 'signal'})${first ? `: ${first.message}` : ''}`,
        'Show Output', 'Show Problems',
      ).then((choice) => {
        if (choice === 'Show Output') {
          output.show(true);
        } else if (choice === 'Show Problems') {
          void vscode.commands.executeCommand('workbench.actions.view.problems');
        }
      });
      return;
    }
    log(`Output: ${result.outputPath}`);
    void vscode.window.showInformationMessage(
      `IREE: ${name} → ${path.basename(result.outputPath)} in ${secs}s (${target.label})`,
      'Reveal Output', 'Copy Path',
    ).then((choice) => {
      if (choice === 'Reveal Output') {
        void vscode.commands.executeCommand('revealFileInOS', vscode.Uri.file(result.outputPath));
      } else if (choice === 'Copy Path') {
        void vscode.env.clipboard.writeText(result.outputPath);
      }
    });
  }

  // -------------------------------------------------------------------------
  // Pipeline commands
  // -------------------------------------------------------------------------

  async function openPass(n: PassNode): Promise<void> {
    try {
      const doc = await vscode.workspace.openTextDocument(vscode.Uri.file(n.filePath));
      if (doc.languageId !== 'mlir') {
        await vscode.languages.setTextDocumentLanguage(doc, 'mlir').then(undefined, () => undefined);
      }
      await vscode.window.showTextDocument(doc, { preview: true, preserveFocus: true });
      await vscode.commands.executeCommand('workbench.action.files.setActiveEditorReadonlyInSession').then(undefined, () => undefined);
    } catch (e) {
      vscode.window.showErrorMessage(`IREE: could not open ${n.filePath}: ${String(e)}`);
    }
  }

  function selectedPasses(arg?: unknown, all?: unknown): PassNode[] {
    if (Array.isArray(all) && all.every(isPass)) {
      return all;
    }
    if (isPass(arg)) {
      return [arg];
    }
    return pipelineView.selection.filter(isPass);
  }

  async function diff(left: PassNode, right: PassNode): Promise<void> {
    const [a, b] = left.ordinal <= right.ordinal ? [left, right] : [right, left];
    await vscode.commands.executeCommand(
      'vscode.diff',
      vscode.Uri.file(a.filePath),
      vscode.Uri.file(b.filePath),
      `${PipelineTreeProvider.label(a)} ↔ ${PipelineTreeProvider.label(b)}`,
      { preview: true },
    );
  }

  async function diffWithPrevious(arg?: unknown): Promise<void> {
    const n = selectedPasses(arg)[0];
    if (!n) {
      vscode.window.showInformationMessage('IREE: select a pass first.');
      return;
    }
    const prev = previousInScope(pipeline.passes, n);
    if (!prev) {
      vscode.window.showInformationMessage(`IREE: ${n.passName} is the first pass dumped in its scope; nothing to diff against.`);
      return;
    }
    await diff(prev, n);
  }

  async function diffSelected(arg?: unknown, all?: unknown): Promise<void> {
    const sel = selectedPasses(arg, all);
    if (sel.length !== 2) {
      vscode.window.showInformationMessage('IREE: select exactly two passes (Cmd/Ctrl+click) to diff.');
      return;
    }
    await diff(sel[0], sel[1]);
  }

  /** Op Changes for two selected passes, or for one pass against the previous in its scope. */
  async function showOpChanges(arg?: unknown, all?: unknown): Promise<void> {
    const sel = selectedPasses(arg, all);
    let pair: [PassNode, PassNode] | undefined;
    if (sel.length === 2) {
      pair = sel[0].ordinal <= sel[1].ordinal ? [sel[0], sel[1]] : [sel[1], sel[0]];
    } else if (sel.length === 1) {
      const prev = previousInScope(pipeline.passes, sel[0]);
      if (!prev) {
        vscode.window.showInformationMessage(`IREE: ${sel[0].passName} is the first pass dumped in its scope; nothing to compare against.`);
        return;
      }
      pair = [prev, sel[0]];
    }
    if (!pair) {
      vscode.window.showInformationMessage('IREE: select one pass (compares with the previous pass) or two passes (Cmd/Ctrl+click).');
      return;
    }
    const [a, b] = pair;
    const [beforeText, afterText] = await Promise.all([fs.readFile(a.filePath, 'utf8'), fs.readFile(b.filePath, 'utf8')]);
    const view: OpDiffView = {
      before: { label: PipelineTreeProvider.label(a), file: a.filePath },
      after: { label: PipelineTreeProvider.label(b), file: b.filePath },
      diff: diffOps(beforeText, afterText),
    };
    opDiff.show(view);
  }

  async function copyRepro(arg?: unknown): Promise<void> {
    const n = selectedPasses(arg)[0];
    if (!n) {
      return;
    }
    // Outside the dump dirs so loading a read-only/checked-in dump never writes into it.
    const reproDir = path.join(path.dirname(service.storageRoot()), 'repro');
    const plan = await prepareRepro(
      pipeline.passes,
      n,
      await service.resolveOpt(),
      (f) => fs.readFile(f, 'utf8').then((t) => t, () => undefined),
      (name) => path.join(reproDir, name),
      current?.meta?.inputPath,
    );
    if (plan.problem) {
      vscode.window.showInformationMessage(`IREE: ${plan.problem}`);
      return;
    }
    if (plan.wrappedInput) {
      await fs.mkdir(reproDir, { recursive: true });
      await fs.writeFile(path.join(reproDir, plan.wrappedInput.fileName), plan.wrappedInput.text);
    }
    const cmd = plan.command;
    await vscode.env.clipboard.writeText(cmd);
    void vscode.window.showInformationMessage(`IREE: copied repro for ${n.passName}.`, 'Run in Terminal').then((choice) => {
      if (choice === 'Run in Terminal') {
        const term = vscode.window.createTerminal('IREE repro');
        term.show();
        term.sendText(cmd.split('\n').filter((l) => !l.startsWith('#')).join('\n'));
      }
    });
  }

  // -------------------------------------------------------------------------
  // Dispatch / tiling commands
  // -------------------------------------------------------------------------

  async function showTiling(arg?: unknown): Promise<void> {
    let d = isDispatch(arg) ? arg : undefined;
    if (!d) {
      const all = dispatchTree.dispatches;
      if (all.length === 0) {
        vscode.window.showInformationMessage('IREE: no dispatches yet. Compile to executable-configurations or later.');
        return;
      }
      const pick = await vscode.window.showQuickPick(
        all.map((x) => ({ label: x.info.name, description: x.info.opName, x })),
        { title: 'Show tiling for dispatch' },
      );
      d = pick?.x;
    }
    if (!d) {
      return;
    }
    tiling.show(d.info);
    void dispatchView.reveal(d, { select: true, focus: false }).then(undefined, () => undefined);
  }

  // -------------------------------------------------------------------------
  // Registration
  // -------------------------------------------------------------------------

  const reg = (id: string, fn: (...args: unknown[]) => unknown) =>
    context.subscriptions.push(vscode.commands.registerCommand(id, async (...args: unknown[]) => {
      try {
        await fn(...args);
      } catch (e) {
        log(`${id} failed: ${e instanceof Error ? e.stack ?? e.message : String(e)}`);
        vscode.window.showErrorMessage(`IREE: ${id.replace('ireeExplorer.', '')} failed: ${e instanceof Error ? e.message : String(e)}`);
      }
    }));

  reg('ireeExplorer.compile', (arg) => compile(typeof arg === 'object' && arg !== null && 'compileTo' in arg ? arg as { compileTo?: string } : undefined));
  reg('ireeExplorer.compileTo', async () => {
    const caps = await service.getCapabilities();
    const phases = (caps?.compileToPhases ?? []).filter((p) => p !== 'start' && p !== 'end');
    if (phases.length === 0) {
      vscode.window.showWarningMessage('IREE: --compile-to phases unknown (probing failed).');
      return;
    }
    const current = cfg().get<string>('compileTo', 'end');
    const items = [
      { label: '$(debug-step-over) Full compile → .vmfb', description: current === 'end' ? 'current' : '', value: 'end' },
      ...phases.map((p) => ({ label: `$(debug-stop) Stop after: ${p}`, description: p === current ? 'current' : '', value: p })),
    ];
    const pick = await vscode.window.showQuickPick(items, {
      title: `How far should IREE compile?${caps?.compileToPhasesGuessed ? ' (phase list GUESSED: help text could not be parsed)' : ''}`,
      placeHolder: 'Stopping early writes the IR at that phase as .mlir instead of a .vmfb',
    });
    if (!pick) {
      return;
    }
    await cfg().update('compileTo', pick.value, settingsTarget());
    void vscode.window.showInformationMessage(
      pick.value === 'end' ? 'IREE: next compile runs to a .vmfb.' : `IREE: next compile stops after "${pick.value}".`,
      'Compile Now',
    ).then((c) => (c ? vscode.commands.executeCommand('ireeExplorer.compile') : undefined));
  });
  reg('ireeExplorer.manageTargets', async () => {
    await refreshCompilerInfo();
    await targets.manage(await service.resolveCompiler(false));
  });
  reg('ireeExplorer.showDataFlow', async () => {
    const program = await loadFlowProgram();
    if (!program || program.graphs.length === 0) {
      vscode.window.showInformationMessage('IREE: no flow-level program in the current compile. Compile to "flow" or later first.');
      return;
    }
    dataFlow.show(program);
  });
  reg('ireeExplorer.setOutputDir', async () => {
    const doc = vscode.window.activeTextEditor?.document;
    const input = current?.meta?.inputPath ?? doc?.uri.fsPath ?? path.join(vscode.workspace.workspaceFolders?.[0]?.uri.fsPath ?? '.', 'input.mlir');
    const root = await outputRootFor(input, true);
    if (root) {
      vscode.window.showInformationMessage(`IREE: compile output goes to ${root}`);
    }
  });
  reg('ireeExplorer.cancel', () => {
    if (!service.cancel()) {
      vscode.window.showInformationMessage('IREE: nothing is compiling.');
    }
  });
  reg('ireeExplorer.selectTarget', async () => {
    await refreshCompilerInfo();
    await targets.pick();
  });
  reg('ireeExplorer.openPipeline', (arg) => {
    const n = selectedPasses(arg)[0];
    return n ? openPass(n) : undefined;
  });
  reg('ireeExplorer.diffWithPrevious', diffWithPrevious);
  reg('ireeExplorer.diffSelected', diffSelected);
  reg('ireeExplorer.showOpChanges', showOpChanges);
  reg('ireeExplorer.copyRepro', copyRepro);
  reg('ireeExplorer.showTiling', showTiling);
  reg('ireeExplorer.revealDumpDir', async () => {
    if (!dumpFiles.rootDir) {
      vscode.window.showInformationMessage('IREE: no dump folder yet. Compile something first.');
      return;
    }
    await vscode.commands.executeCommand('ireeExplorer.dumpFiles.focus');
  });
  reg('ireeExplorer.revealInOS', (arg) => {
    const p = (arg as DumpFile | undefined)?.path ?? dumpFiles.rootDir;
    return p ? vscode.commands.executeCommand('revealFileInOS', vscode.Uri.file(p)) : undefined;
  });
  reg('ireeExplorer.copyPath', async (arg) => {
    const p = (arg as DumpFile | undefined)?.path ?? dumpFiles.rootDir;
    if (p) {
      await vscode.env.clipboard.writeText(p);
    }
  });
  reg('ireeExplorer.clearCache', async () => {
    const ok = await vscode.window.showWarningMessage(
      'Delete all IREE Explorer dump directories and the compiler probe cache?', { modal: true }, 'Delete',
    );
    if (ok !== 'Delete') {
      return;
    }
    service.cancel();
    await fs.rm(service.storageRoot(), { recursive: true, force: true });
    // Only this extension's timestamped dump folders (with meta.json) are removed.
    if (current?.dir) {
      await gcDumpDirs(path.dirname(current.dir), 0);
    }
    dumpFiles.setRoot(undefined);
    dumpFilesView.description = undefined;
    await context.workspaceState.update(LAST_DUMP_KEY, undefined);
    await service.clearCapabilityCache();
    current = undefined;
    pipeline.setPasses([]);
    dispatchTree.setDispatches([]);
    pipelineView.message = undefined;
    pipelineView.description = undefined;
    tiling.update(undefined);
    opDiff.close();
    diagnostics.clear();
    await refreshCompilerInfo(true);
  });
  reg('ireeExplorer.toggleUnchanged', async () => {
    const c = cfg();
    const t = vscode.workspace.workspaceFolders ? vscode.ConfigurationTarget.Workspace : vscode.ConfigurationTarget.Global;
    await c.update('showUnchangedPasses', !c.get<boolean>('showUnchangedPasses', false), t);
  });
  reg('ireeExplorer.sortPasses', async () => {
    const pick = await vscode.window.showQuickPick(
      [{ label: 'By ordinal', v: 'ordinal' as PassSort }, { label: 'By wall time (descending)', v: 'time' as PassSort }],
      { title: 'Sort passes' },
    );
    if (pick) {
      pipeline.sort = pick.v;
      pipeline.refresh();
    }
  });
  reg('ireeExplorer.sortDispatches', async () => {
    const pick = await vscode.window.showQuickPick(
      [{ label: 'By name', v: 'name' as DispatchSort }, { label: 'By number of ops', v: 'ops' as DispatchSort }],
      { title: 'Sort dispatches' },
    );
    if (pick) {
      dispatchTree.sort = pick.v;
      dispatchTree.refresh();
    }
  });

  // -------------------------------------------------------------------------
  // Events
  // -------------------------------------------------------------------------

  context.subscriptions.push(
    service.onDidChangeBusy((b) => status.setBusy(b)),
    targets.onDidChange((t) => status.setTarget(t)),
    vscode.workspace.onDidChangeConfiguration((e) => {
      if (e.affectsConfiguration('ireeExplorer.compilerPath')) {
        service.invalidateCapabilities();
        void refreshCompilerInfo();
        void watchCompiler();
      }
      if (e.affectsConfiguration('ireeExplorer.showUnchangedPasses')) {
        pipeline.refresh();
      }
      if (e.affectsConfiguration('ireeExplorer.compileTo')) {
        status.setStopAfter(cfg().get<string>('compileTo', 'end'));
      }
    }),
  );

  // Re-probe when iree-compile is rebuilt (e.g. after "Add a backend").
  let binWatcher: vscode.FileSystemWatcher | undefined;
  const watchCompiler = async () => {
    binWatcher?.dispose();
    const bin = await service.resolveCompiler(false);
    if (!bin) {
      return;
    }
    binWatcher = vscode.workspace.createFileSystemWatcher(new vscode.RelativePattern(vscode.Uri.file(path.dirname(bin)), path.basename(bin)));
    let timer: NodeJS.Timeout | undefined;
    const changed = () => {
      clearTimeout(timer);
      timer = setTimeout(async () => {
        service.invalidateCapabilities();
        await refreshCompilerInfo();
        const caps = await service.getCapabilities();
        log(`iree-compile changed; backends now: ${caps?.registeredBackends.join(', ') ?? 'unknown'}`);
        void vscode.window.showInformationMessage(`IREE: iree-compile was rebuilt. Backends: ${caps?.registeredBackends.join(', ') ?? 'unknown'}`);
      }, 3000);
    };
    binWatcher.onDidChange(changed);
    binWatcher.onDidCreate(changed);
  };
  context.subscriptions.push({ dispose: () => binWatcher?.dispose() });
  void watchCompiler();

  status.setTarget(targets.active());
  status.setStopAfter(cfg().get<string>('compileTo', 'end'));
  void refreshCompilerInfo();
  // Reopen the last compile's results (wherever its output folder was).
  void (async () => {
    const last = context.workspaceState.get<string>(LAST_DUMP_KEY);
    const dir = last && (await fs.stat(last).then(() => true, () => false)) ? last : (await listDumpDirs(service.storageRoot()))[0];
    if (dir) {
      await loadDump(dir, true);
    }
  })();
  void recommendMlirExtension(context);

  return {
    loadDump: (dir) => loadDump(dir),
    passes: () => pipeline.passes,
    dispatches: () => dispatchTree.dispatches,
    tilingOpen: () => tiling.isOpen,
    dataFlowOpen: () => dataFlow.isOpen,
    opDiffOpen: () => opDiff.isOpen,
    dataFlowRow: () => dispatchTree.hasDataFlowRow,
    currentDump: () => (current
      ? { dir: current.dir, outputPath: current.meta?.outputPath, exitCode: current.meta?.exitCode, cancelled: current.meta?.cancelled }
      : undefined),
  };
}

async function recommendMlirExtension(context: vscode.ExtensionContext): Promise<void> {
  // TODO(verify): the marketplace id is llvm-vs-code-extensions.vscode-mlir;
  // the design spec names llvm-vs-code-extensions.mlir. Both are checked.
  if (MLIR_EXTENSION_IDS.some((id) => vscode.extensions.getExtension(id))) {
    return;
  }
  const key = 'ireeExplorer.recommendedMlir';
  if (context.globalState.get<boolean>(key)) {
    return;
  }
  await context.globalState.update(key, true);
  const choice = await vscode.window.showInformationMessage(
    'IREE Explorer works best with the MLIR extension (syntax highlighting and LSP for dumped IR).',
    'Show MLIR Extension',
  );
  if (choice) {
    await vscode.commands.executeCommand('workbench.extensions.search', MLIR_EXTENSION_IDS[0]);
  }
}

export function deactivate(): void {
  // Disposables handle cleanup (in-flight compiles are aborted by CompilerService.dispose).
}
