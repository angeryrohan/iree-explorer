// Pass pipeline TreeView: phases -> scopes -> passes. Native UI only.

import * as path from 'path';
import * as vscode from 'vscode';
import { groupPasses, PhaseGroup, ScopeGroup } from '../model/pipeline';
import { PassNode } from '../model/types';

export type PipelineElement = PhaseGroup | ScopeGroup | PassNode;
export type PassSort = 'ordinal' | 'time';

function isPass(e: PipelineElement): e is PassNode {
  return (e as PassNode).filePath !== undefined;
}

export function formatMs(ms: number | undefined): string {
  if (ms === undefined) {
    return '';
  }
  if (ms >= 1000) {
    return `${(ms / 1000).toFixed(2)}s`;
  }
  if (ms >= 10) {
    return `${ms.toFixed(0)}ms`;
  }
  return `${ms.toFixed(1)}ms`;
}

export class PipelineTreeProvider implements vscode.TreeDataProvider<PipelineElement> {
  private readonly emitter = new vscode.EventEmitter<PipelineElement | undefined | void>();
  readonly onDidChangeTreeData = this.emitter.event;
  private nodes: PassNode[] = [];
  private groups: PhaseGroup[] = [];
  private parents = new Map<PipelineElement, PipelineElement>();
  sort: PassSort = 'ordinal';

  setPasses(nodes: PassNode[]): void {
    this.nodes = nodes;
    this.rebuild();
  }

  get passes(): PassNode[] {
    return this.nodes;
  }

  refresh(): void {
    this.rebuild();
  }

  private showUnchanged(): boolean {
    return vscode.workspace.getConfiguration('ireeExplorer').get<boolean>('showUnchangedPasses', false);
  }

  private rebuild(): void {
    this.groups = groupPasses(this.nodes, this.showUnchanged());
    this.parents.clear();
    for (const g of this.groups) {
      for (const i of g.items) {
        this.parents.set(i, g);
        if (!isPass(i)) {
          for (const p of i.passes) {
            this.parents.set(p, i);
          }
        }
      }
    }
    this.emitter.fire();
  }

  getParent(e: PipelineElement): PipelineElement | undefined {
    return this.sort === 'time' ? undefined : this.parents.get(e);
  }

  getChildren(e?: PipelineElement): PipelineElement[] {
    if (this.sort === 'time') {
      if (e) {
        return [];
      }
      const show = this.showUnchanged();
      return this.nodes
        .filter((n) => n.wallMs !== undefined && (show || (n.changed && !n.container)))
        .sort((a, b) => (b.wallMs ?? 0) - (a.wallMs ?? 0));
    }
    if (!e) {
      return this.groups;
    }
    if (isPass(e)) {
      return [];
    }
    return e.kind === 'phase' ? e.items : e.passes;
  }

  getTreeItem(e: PipelineElement): vscode.TreeItem {
    if (isPass(e)) {
      return this.passItem(e);
    }
    if (e.kind === 'phase') {
      const item = new vscode.TreeItem(e.phase, vscode.TreeItemCollapsibleState.Collapsed);
      item.description = `${e.changedPasses}/${e.totalPasses} changed${e.wallMs > 0 ? ` · ${formatMs(e.wallMs)}` : ''}`;
      item.iconPath = new vscode.ThemeIcon('symbol-namespace');
      item.tooltip = `Phase "${e.phase}" (inferred from pass names).\n${e.totalPasses} pass invocations, ${e.changedPasses} changed the IR.`;
      item.contextValue = 'phase';
      item.id = `phase:${e.phase}`;
      return item;
    }
    const item = new vscode.TreeItem(e.label, vscode.TreeItemCollapsibleState.Collapsed);
    item.description = `${e.changedPasses}/${e.totalPasses}${e.parent ? ` · ${e.parent}` : ''}`;
    item.iconPath = new vscode.ThemeIcon('symbol-method');
    item.tooltip = e.key.split('|')[1];
    item.contextValue = 'scope';
    item.id = `scope:${e.key}`;
    return item;
  }

  private passItem(n: PassNode): vscode.TreeItem {
    const item = new vscode.TreeItem(n.passName, vscode.TreeItemCollapsibleState.None);
    const parts: string[] = [];
    if (n.container) {
      parts.push('nested pipeline');
    } else if (!n.changed) {
      parts.push('no change');
    }
    if (n.wallMs !== undefined) {
      parts.push(formatMs(n.wallMs));
    }
    if (this.sort === 'time') {
      parts.push(n.phase);
    }
    item.description = parts.join(' · ');
    item.iconPath = n.container
      ? new vscode.ThemeIcon('layers', new vscode.ThemeColor('disabledForeground'))
      : n.changed
        ? new vscode.ThemeIcon('circle-filled', new vscode.ThemeColor('charts.blue'))
        : new vscode.ThemeIcon('circle-outline', new vscode.ThemeColor('disabledForeground'));
    const md = new vscode.MarkdownString();
    md.appendMarkdown(`**${n.passName}**${n.className ? ` — \`${n.className}\`` : ''}\n\n`);
    if (n.pipelineText && n.pipelineText !== n.passName) {
      md.appendMarkdown(`\`${n.pipelineText}\`\n\n`);
    }
    md.appendMarkdown(`ordinal \`${n.ordinalPath.join('_')}\` · ${(n.sizeBytes / 1024).toFixed(1)} KiB · ${n.changed ? 'changed IR' : 'no change'}\n\n`);
    md.appendMarkdown(`scope: \`${n.scope.join(' / ')}\``);
    item.tooltip = md;
    item.contextValue = 'pass';
    item.id = `pass:${n.filePath}`;
    item.resourceUri = vscode.Uri.file(n.filePath);
    item.command = { command: 'ireeExplorer.openPipeline', title: 'Open', arguments: [n] };
    return item;
  }

  /** Short label for diff titles. */
  static label(n: PassNode): string {
    const scope = n.scope.length > 1 ? ` (${path.basename(n.scope[n.scope.length - 1])})` : '';
    return `${n.ordinalPath.join('_')} ${n.passName}${scope}`;
  }
}
