// Dispatches TreeView: one item per dispatch function, children are the
// dumped artifacts for its executable.

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

export type DispatchElement = DispatchArtifact | FileChild;

function isFile(e: DispatchElement): e is FileChild {
  return (e as FileChild).kind === 'file';
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
  sort: DispatchSort = 'name';

  setDispatches(items: DispatchArtifact[]): void {
    this.items = items;
    this.emitter.fire();
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
      return list;
    }
    if (isFile(e)) {
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
