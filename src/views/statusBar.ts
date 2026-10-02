// Status bar: active target (click to change) and a cancel button while a
// compile is running.

import * as vscode from 'vscode';
import { targetKind } from '../compiler/flags';
import { TargetProfile } from '../model/types';

export class IreeStatusBar implements vscode.Disposable {
  private readonly target: vscode.StatusBarItem;
  private readonly cancel: vscode.StatusBarItem;
  private readonly phase: vscode.StatusBarItem;
  private stopAfter = 'end';
  private profile: TargetProfile | undefined;
  private compilerPath: string | undefined;
  private version: string | undefined;
  private busy = false;

  constructor() {
    this.target = vscode.window.createStatusBarItem('ireeExplorer.target', vscode.StatusBarAlignment.Left, 100);
    this.target.name = 'IREE Target';
    this.target.command = 'ireeExplorer.selectTarget';
    this.cancel = vscode.window.createStatusBarItem('ireeExplorer.cancel', vscode.StatusBarAlignment.Left, 99);
    this.cancel.name = 'IREE Cancel';
    this.cancel.text = '$(debug-stop) Cancel';
    this.cancel.tooltip = 'Cancel the running iree-compile';
    this.cancel.command = 'ireeExplorer.cancel';
    this.phase = vscode.window.createStatusBarItem('ireeExplorer.phase', vscode.StatusBarAlignment.Left, 99.5);
    this.phase.name = 'IREE Stop After';
    this.phase.command = 'ireeExplorer.compileTo';
    this.render();
    this.target.show();
    this.phase.show();
  }

  /** The --compile-to phase ("end" = full compile to .vmfb). */
  setStopAfter(phase: string): void {
    this.stopAfter = phase || 'end';
    this.render();
  }

  dispose(): void {
    this.target.dispose();
    this.cancel.dispose();
    this.phase.dispose();
  }

  setTarget(p: TargetProfile | undefined): void {
    this.profile = p;
    this.render();
  }

  setCompiler(path: string | undefined, version: string | undefined): void {
    this.compilerPath = path;
    this.version = version;
    this.render();
  }

  setBusy(b: boolean): void {
    this.busy = b;
    this.render();
  }

  private render(): void {
    const icon = this.busy ? '$(sync~spin)' : `$(${this.profile ? targetKind(this.profile).icon : 'cpu'})`;
    this.target.text = `${icon} ${this.profile?.label ?? 'IREE: no target'}`;
    const md = new vscode.MarkdownString(undefined, true);
    md.appendMarkdown(`**IREE target:** ${this.profile ? `${this.profile.label} (\`${this.profile.id}\`)` : 'none'}\n\n`);
    md.appendMarkdown(`**iree-compile:** ${this.compilerPath ? `\`${this.compilerPath}\`` : '_not found_'}\n\n`);
    if (this.version) {
      md.appendMarkdown(`**version:** ${this.version}\n\n`);
    }
    md.appendMarkdown('Click to change target.');
    this.target.tooltip = md;
    const full = this.stopAfter === 'end';
    this.phase.text = full ? '$(debug-step-over) full → .vmfb' : `$(debug-stop) stop after: ${this.stopAfter}`;
    this.phase.tooltip = full
      ? 'IREE: compiles all the way to a .vmfb. Click to stop after an earlier phase (flow, stream, …).'
      : `IREE: compiles only up to "${this.stopAfter}" and writes the IR as .mlir. Click to change.`;
    if (this.busy) {
      this.cancel.show();
    } else {
      this.cancel.hide();
    }
  }
}
