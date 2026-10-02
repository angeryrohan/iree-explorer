// Dispatches TreeView: a "Data Flow" row for the whole program, then one item
// per dispatch function whose children are the dumped artifacts for its
// executable.

import * as path from 'path';
import * as vscode from 'vscode';
import { DispatchArtifact } from '../model/artifacts';

export type DispatchSort = 'name' | 'ops';

interface FileChild {
  kind: 'file';
  label: string;
  file: string;
  icon: string;
  parent: DispatchArtifact;
}

interface DataFlowRow {
  kind: 'dataFlow';
}

export type DispatchElement = DispatchArtifact | FileChild | DataFlowRow;

const DATA_FLOW_ROW: DataFlowRow = { kind: 'dataFlow' };

function isFile(e: DispatchElement): e is FileChild {
  return (e as FileChild).kind === 'file';
}

function isDataFlowRow(e: DispatchElement): e is DataFlowRow {
  return (e as DataFlowRow).kind === 'dataFlow';
}

export function dispatchDescription(d: DispatchArtifact): string {
  const parts: string[] = [];
  const t = d.info.translation;
  if (t?.pipeline) {
    parts.push(t.pipeline);
  }
  if (t?.workgroupSize) {
    parts.push(`wg [${t.workgroupSize.join(',')}]`);
  }
  if (d.info.opName) {
    parts.push(d.info.opName);
  }
  return parts.join(' · ');
}

export class DispatchTreeProvider implements vscode.TreeDataProvider<DispatchElement> {
  private readonly emitter = new vscode.EventEmitter<DispatchElement | undefined | void>();
  readonly onDidChangeTreeData = this.emitter.event;
  private items: DispatchArtifact[] = [];
  private dataFlow = false;
  sort: DispatchSort = 'name';

  /** `hasDataFlow`: the compile has a flow-level program, so show the Data Flow row. */
  setDispatches(items: DispatchArtifact[], hasDataFlow = false): void {
    this.items = items;
    this.dataFlow = hasDataFlow;
    this.emitter.fire();
  }

  get hasDataFlowRow(): boolean {
    return this.dataFlow;
  }

  get dispatches(): DispatchArtifact[] {
    return this.items;
  }

  refresh(): void {
    this.emitter.fire();
  }

  getParent(e: DispatchElement): DispatchElement | undefined {
    return isFile(e) ? e.parent : undefined;
  }

  getChildren(e?: DispatchElement): DispatchElement[] {
    if (!e) {
      const list = this.items.slice();
      if (this.sort === 'ops') {
        list.sort((a, b) => b.info.opCount - a.info.opCount || a.info.name.localeCompare(b.info.name));
      } else {
        list.sort((a, b) => a.info.name.localeCompare(b.info.name, undefined, { numeric: true }));
      }
      return this.dataFlow ? [DATA_FLOW_ROW, ...list] : list;
    }
    if (isFile(e) || isDataFlowRow(e)) {
      return [];
    }
    const kids: FileChild[] = [];
    if (e.sourceFile) {
      kids.push({ kind: 'file', label: 'Source IR', file: e.sourceFile, icon: 'file-code', parent: e });
    }
    if (e.configFile) {
      kids.push({ kind: 'file', label: 'Configuration IR', file: e.configFile, icon: 'settings-gear', parent: e });
    }
    for (const f of e.intermediateFiles) {
      kids.push({ kind: 'file', label: `Intermediate: ${path.basename(f)}`, file: f, icon: 'file-binary', parent: e });
    }
    for (const f of e.binaryFiles) {
      kids.push({ kind: 'file', label: `Binary: ${path.basename(f)}`, file: f, icon: 'file-binary', parent: e });
    }
    return kids;
  }

  getTreeItem(e: DispatchElement): vscode.TreeItem {
    if (isDataFlowRow(e)) {
      const item = new vscode.TreeItem('Data Flow', vscode.TreeItemCollapsibleState.None);
      item.description = 'whole program';
      item.iconPath = new vscode.ThemeIcon('type-hierarchy');
      item.tooltip = 'The kernels in the order the program runs them, the ops fused into each, and the tensors passed between them. Click to open.';
      item.contextValue = 'dataFlow';
      item.id = 'dataFlow';
      item.command = { command: 'ireeExplorer.showDataFlow', title: 'Show Data Flow' };
      return item;
    }
    if (isFile(e)) {
      const item = new vscode.TreeItem(e.label, vscode.TreeItemCollapsibleState.None);
      item.iconPath = new vscode.ThemeIcon(e.icon);
      item.resourceUri = vscode.Uri.file(e.file);
      item.tooltip = e.file;
      item.contextValue = 'dispatchFile';
      item.command = { command: 'vscode.open', title: 'Open', arguments: [vscode.Uri.file(e.file), { preview: true }] };
      return item;
    }
    const item = new vscode.TreeItem(e.info.name, vscode.TreeItemCollapsibleState.Collapsed);
    item.description = dispatchDescription(e);
    item.iconPath = new vscode.ThemeIcon(e.info.config ? 'layout' : 'symbol-function');
    const md = new vscode.MarkdownString();
    md.appendMarkdown(`**${e.info.name}**\n\n`);
    if (e.info.executable) {
      md.appendMarkdown(`executable \`@${e.info.executable}\`${e.info.variant ? ` · variant \`@${e.info.variant}\`` : ''}\n\n`);
    }
    md.appendMarkdown(`root op: \`${e.info.opName || 'unknown'}\` · ${e.info.opCount} linalg op(s)\n\n`);
    if (e.info.iterationDomain.length > 0) {
      md.appendMarkdown(`iteration domain: \`[${e.info.iterationDomain.join(', ')}]\` (${e.info.iteratorTypes.map((t) => t[0]).join('')})\n\n`);
    }
    if (e.info.config) {
      md.appendMarkdown(`lowering_config: ${e.info.config.levels.map((l) => `${l.name}=[${l.sizes.join(',')}]`).join(' ')}\n\n`);
    }
    md.appendMarkdown('Click to show tiling.');
    item.tooltip = md;
    item.contextValue = 'dispatch';
    item.id = `dispatch:${e.info.sourceFile}:${e.info.name}`;
    item.command = { command: 'ireeExplorer.showTiling', title: 'Show Tiling', arguments: [e] };
    return item;
  }
}
