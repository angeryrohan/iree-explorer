import * as assert from 'assert';
import { execFileSync } from 'child_process';
import { createHash } from 'crypto';
import { promises as fs, readFileSync } from 'fs';
import * as os from 'os';
import * as path from 'path';
import * as vscode from 'vscode';

interface Api {
  loadDump(dir: string): Promise<void>;
  passes(): Array<{ passName: string; changed: boolean; filePath: string; scope: string[]; ordinalPath: number[] }>;
  dispatches(): Array<{ info: { name: string } }>;
  tilingOpen(): boolean;
  dataFlowOpen(): boolean;
  opDiffOpen(): boolean;
  dataFlowRow(): boolean;
  currentDump(): { dir: string; outputPath?: string; exitCode?: number | null; cancelled?: boolean } | undefined;
}

function pgrep(pattern: string): string[] {
  try {
    return execFileSync('pgrep', ['-f', pattern], { encoding: 'utf8' }).split('\n').filter((l) => l.trim().length > 0);
  } catch {
    return []; // pgrep exits 1 when nothing matches
  }
}

const sha = (f: string) => createHash('sha256').update(readFileSync(f)).digest('hex');

const ROOT = path.resolve(__dirname, '..', '..', '..');
const FIXTURES = path.join(ROOT, 'test', 'fixtures');
const IREE_COMPILE = process.env.IREE_COMPILE;

async function api(): Promise<Api> {
  const ext = vscode.extensions.all.find((e) => e.packageJSON.name === 'iree-explorer');
  assert.ok(ext, 'extension not found');
  return (await ext.activate()) as Api;
}

async function waitFor(pred: () => boolean, ms = 60000): Promise<void> {
  const start = Date.now();
  while (!pred()) {
    if (Date.now() - start > ms) {
      throw new Error('timed out');
    }
    await new Promise((r) => setTimeout(r, 200));
  }
}

describe('IREE Explorer', () => {
  it('activates and registers all commands', async () => {
    await api();
    const cmds = await vscode.commands.getCommands(true);
    for (const c of ['compile', 'cancel', 'selectTarget', 'openPipeline', 'diffWithPrevious', 'diffSelected',
      'showOpChanges', 'copyRepro', 'showTiling', 'revealDumpDir', 'clearCache']) {
      assert.ok(cmds.includes(`ireeExplorer.${c}`), c);
    }
  });

  it('populates the trees from a checked-in dump dir', async () => {
    const a = await api();
    await a.loadDump(path.join(FIXTURES, 'iree-llvm24-2026', 'matmul-llvm-cpu'));
    assert.ok(a.passes().length > 500);
    assert.strictEqual(a.dispatches().length, 1);
    assert.ok(a.dataFlowRow());
  });

  it('diff with previous opens a diff editor', async () => {
    const a = await api();
    const tile = a.passes().find((p) => p.passName.startsWith('iree-codegen-tile-and-distribute-to-workgroups'));
    assert.ok(tile);
    await vscode.commands.executeCommand('ireeExplorer.diffWithPrevious', tile);
    await waitFor(() => vscode.window.tabGroups.activeTabGroup.activeTab?.input instanceof vscode.TabInputTextDiff, 10000);
    const input = vscode.window.tabGroups.activeTabGroup.activeTab!.input as vscode.TabInputTextDiff;
    assert.strictEqual(input.modified.fsPath, tile.filePath);
    await vscode.commands.executeCommand('workbench.action.closeAllEditors');
  });

  it('show op changes opens the op changes panel', async () => {
    const a = await api();
    const tile = a.passes().find((p) => p.passName.startsWith('iree-codegen-tile-and-distribute-to-workgroups'));
    assert.ok(tile);
    await vscode.commands.executeCommand('ireeExplorer.showOpChanges', tile);
    await waitFor(() => a.opDiffOpen(), 10000);
    await vscode.commands.executeCommand('workbench.action.closeAllEditors');
    await waitFor(() => !a.opDiffOpen(), 10000);
  });

  it('copy repro writes an iree-opt command to the clipboard', async () => {
    const a = await api();
    const cse = a.passes().find((p) => p.passName === 'cse' && p.scope.some((s) => s.startsWith('func_func_')));
    assert.ok(cse);
    await vscode.commands.executeCommand('ireeExplorer.copyRepro', cse);
    const clip = await vscode.env.clipboard.readText();
    // A pass inside an executable variant: the input is rebuilt around the variant.
    assert.match(clip, /--pass-pipeline=builtin\.module\(hal\.executable\(hal\.executable\.variant\(builtin\.module\(func\.func\(cse\)\)\)\)\)/);
    const input = /^\S+ (\S+) /.exec(clip)![1];
    assert.ok(readFileSync(input, 'utf8').startsWith('hal.executable private @matmul_dispatch_0 {'));
    assert.ok(!input.startsWith(FIXTURES), 'repro inputs must not be written into the dump dir');
  });

  it('show tiling opens the webview panel', async () => {
    const a = await api();
    await vscode.commands.executeCommand('ireeExplorer.showTiling', a.dispatches()[0]);
    await waitFor(() => a.tilingOpen(), 10000);
    await vscode.commands.executeCommand('workbench.action.closeAllEditors');
  });

  it('show data flow opens the graph panel', async () => {
    const a = await api();
    await a.loadDump(path.join(FIXTURES, 'iree-llvm24-2026', 'matmul-llvm-cpu'));
    await vscode.commands.executeCommand('ireeExplorer.showDataFlow');
    await waitFor(() => a.dataFlowOpen(), 10000);
    await vscode.commands.executeCommand('workbench.action.closeAllEditors');
  });

  it('show dump files focuses the Dump Files view (no Finder)', async () => {
    await vscode.commands.executeCommand('ireeExplorer.revealDumpDir');
  });

  (IREE_COMPILE ? describe : describe.skip)('with a real iree-compile', () => {
    before(async () => {
      await vscode.workspace.getConfiguration('ireeExplorer').update('compilerPath', IREE_COMPILE, vscode.ConfigurationTarget.Global);
      await vscode.workspace.getConfiguration('ireeExplorer').update('activeTarget', 'llvm-cpu-host', vscode.ConfigurationTarget.Global);
      // Skip the first-compile location prompt: output next to each input.
      await vscode.workspace.getConfiguration('ireeExplorer').update('outputDir', '${inputDir}/iree-out', vscode.ConfigurationTarget.Global);
    });

    it('compiles a matmul and fills the trees', async () => {
      const a = await api();
      const tmp = await fs.mkdtemp(path.join(os.tmpdir(), 'iree-explorer-'));
      const input = path.join(tmp, 'matmul.mlir');
      await fs.copyFile(path.join(FIXTURES, 'inputs', 'matmul.mlir'), input);
      await vscode.window.showTextDocument(vscode.Uri.file(input));
      await vscode.commands.executeCommand('ireeExplorer.compile');
      assert.ok(a.passes().length > 500);
      assert.ok(a.passes().every((p) => !p.filePath.startsWith(FIXTURES)), 'trees should show the new dump, not the fixture');
      assert.ok(a.dispatches().some((d) => d.info.name.startsWith('matmul_dispatch_0')));
      assert.strictEqual(path.dirname(a.currentDump()!.dir), path.join(tmp, 'iree-out'), 'output goes next to the input');
    });

    it('switching target produces a different .vmfb', async () => {
      const a = await api();
      const tmp = await fs.mkdtemp(path.join(os.tmpdir(), 'iree-explorer-'));
      const input = path.join(tmp, 'matmul.mlir');
      await fs.copyFile(path.join(FIXTURES, 'inputs', 'matmul.mlir'), input);
      await vscode.window.showTextDocument(vscode.Uri.file(input));
      const cfg = vscode.workspace.getConfiguration('ireeExplorer');

      await cfg.update('activeTarget', 'llvm-cpu-host', vscode.ConfigurationTarget.Global);
      await vscode.commands.executeCommand('ireeExplorer.compile');
      const cpu = a.currentDump()!;
      assert.strictEqual(cpu.exitCode, 0);

      await cfg.update('activeTarget', 'vulkan-rdna3', vscode.ConfigurationTarget.Global);
      await vscode.commands.executeCommand('ireeExplorer.compile');
      const vk = a.currentDump()!;
      assert.strictEqual(vk.exitCode, 0);

      assert.notStrictEqual(cpu.dir, vk.dir);
      assert.notStrictEqual(sha(cpu.outputPath!), sha(vk.outputPath!));
      await cfg.update('activeTarget', 'llvm-cpu-host', vscode.ConfigurationTarget.Global);
    });

    it('cancel kills the iree-compile process', async () => {
      const a = await api();
      const tmp = await fs.mkdtemp(path.join(os.tmpdir(), 'iree-explorer-cancel-'));
      const input = path.join(tmp, 'slow.mlir');
      await fs.copyFile(path.join(FIXTURES, 'inputs', 'slow.mlir'), input);
      await vscode.window.showTextDocument(vscode.Uri.file(input));
      const compiling = vscode.commands.executeCommand('ireeExplorer.compile');
      await waitFor(() => pgrep(input).length > 0, 20000);
      await new Promise((r) => setTimeout(r, 1500));
      assert.ok(pgrep(input).length > 0, 'iree-compile should still be running');
      await vscode.commands.executeCommand('ireeExplorer.cancel');
      await compiling;
      await waitFor(() => pgrep(input).length === 0, 5000);
      assert.strictEqual(a.currentDump()?.cancelled, true);
    });

    it('stop-after phase writes IR instead of a .vmfb', async () => {
      const a = await api();
      const tmp = await fs.mkdtemp(path.join(os.tmpdir(), 'iree-explorer-'));
      const input = path.join(tmp, 'matmul.mlir');
      await fs.copyFile(path.join(FIXTURES, 'inputs', 'matmul.mlir'), input);
      await vscode.window.showTextDocument(vscode.Uri.file(input));
      const cfg = vscode.workspace.getConfiguration('ireeExplorer');
      await cfg.update('compileTo', 'flow', vscode.ConfigurationTarget.Global);
      try {
        await vscode.commands.executeCommand('ireeExplorer.compile');
      } finally {
        await cfg.update('compileTo', 'end', vscode.ConfigurationTarget.Global);
      }
      const out = a.currentDump()!.outputPath!;
      assert.ok(out.endsWith('output.flow.mlir'), out);
      assert.match(readFileSync(out, 'utf8'), /flow\.dispatch/);
    });

    it('compiles for Metal without Xcode (auto flag)', async function () {
      const backends = execFileSync(IREE_COMPILE!, ['--iree-hal-list-target-backends'], { encoding: 'utf8' });
      if (process.platform !== 'darwin' || !/metal-spirv/.test(backends)) {
        this.skip();
      }
      const a = await api();
      const tmp = await fs.mkdtemp(path.join(os.tmpdir(), 'iree-explorer-'));
      const input = path.join(tmp, 'matmul.mlir');
      await fs.copyFile(path.join(FIXTURES, 'inputs', 'matmul.mlir'), input);
      await vscode.window.showTextDocument(vscode.Uri.file(input));
      const cfg = vscode.workspace.getConfiguration('ireeExplorer');
      await cfg.update('activeTarget', 'metal-spirv', vscode.ConfigurationTarget.Global);
      try {
        await vscode.commands.executeCommand('ireeExplorer.compile');
      } finally {
        await cfg.update('activeTarget', 'llvm-cpu-host', vscode.ConfigurationTarget.Global);
      }
      assert.strictEqual(a.currentDump()!.exitCode, 0);
    });

    it('reports compile errors in the Problems panel', async () => {
      const tmp = await fs.mkdtemp(path.join(os.tmpdir(), 'iree-explorer-'));
      const input = path.join(tmp, 'bad.mlir');
      await fs.copyFile(path.join(FIXTURES, 'inputs', 'bad.mlir'), input);
      await vscode.window.showTextDocument(vscode.Uri.file(input));
      await vscode.commands.executeCommand('ireeExplorer.compile');
      const diags = vscode.languages.getDiagnostics(vscode.Uri.file(input));
      assert.strictEqual(diags.length, 1);
      assert.strictEqual(diags[0].range.start.line, 1);
      assert.strictEqual(diags[0].severity, vscode.DiagnosticSeverity.Error);
    });
  });
});
