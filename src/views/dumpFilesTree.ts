// "Dump Files" view: the current compile's output folder as a file tree, so
// dumps can be browsed without leaving VS Code.

import { promises as fs } from 'fs';
import * as path from 'path';
import * as vscode from 'vscode';

export interface DumpFile {
  path: string;
  isDir: boolean;
}

// Files VS Code can't usefully show as text.
const BINARY = /\.(vmfb|o|so|dylib|bc|spv|hsaco|ptx|metallib|elf|bin)$/i;

// Short explanations for the well-known entries of a dump folder.
const DESCRIPTIONS: Record<string, string> = {
  ir: 'IR after every pass',
  sources: 'dispatch sources',
  configs: 'dispatches with tile sizes',
  binaries: 'compiled kernels',
  intermediates: 'codegen intermediates',
  'stderr.log': 'compiler output',
  'meta.json': 'compile command + result',
};

export class DumpFilesTreeProvider implements vscode.TreeDataProvider<DumpFile> {
  private readonly emitter = new vscode.EventEmitter<DumpFile | undefined | void>();
  readonly onDidChangeTreeData = this.emitter.event;
  private root: string | undefined;

  setRoot(dir: string | undefined): void {
    this.root = dir;
    this.emitter.fire();
  }

  get rootDir(): string | undefined {
    return this.root;
  }

  getParent(e: DumpFile): DumpFile | undefined {
    const parent = path.dirname(e.path);
    return this.root && parent !== this.root && parent.startsWith(this.root) ? { path: parent, isDir: true } : undefined;
  }

  async getChildren(e?: DumpFile): Promise<DumpFile[]> {
    const dir = e?.path ?? this.root;
    if (!dir) {
      return [];
    }
    try {
      const entries = await fs.readdir(dir, { withFileTypes: true });
      return entries
        .filter((d) => !d.name.startsWith('.'))
        .map((d) => ({ path: path.join(dir, d.name), isDir: d.isDirectory() }))
        // Folders first, then numeric-aware name order (pass dumps are "12_cse.mlir").
        .sort((a, b) => Number(b.isDir) - Number(a.isDir) || path.basename(a.path).localeCompare(path.basename(b.path), undefined, { numeric: true }));
    } catch {
      return [];
    }
  }

  getTreeItem(e: DumpFile): vscode.TreeItem {
    const uri = vscode.Uri.file(e.path);
    const item = new vscode.TreeItem(uri, e.isDir ? vscode.TreeItemCollapsibleState.Collapsed : vscode.TreeItemCollapsibleState.None);
    const name = path.basename(e.path);
    if (path.dirname(e.path) === this.root && DESCRIPTIONS[name]) {
      item.description = DESCRIPTIONS[name];
    } else if (name.startsWith('output.')) {
      item.description = 'compiled output';
    }
    item.tooltip = e.path;
    item.contextValue = e.isDir ? 'dumpDir' : 'dumpFile';
    if (!e.isDir && !BINARY.test(name)) {
      item.command = { command: 'vscode.open', title: 'Open', arguments: [uri, { preview: true }] };
    }
    return item;
  }
}
