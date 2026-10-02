// Data Flow webview panel: kernels in execution order and the tensors passed
// between them. Same hardening as the tiling panel (nonce CSP, media/ only).

import { randomBytes } from 'crypto';
import * as vscode from 'vscode';
import { FlowProgram } from '../model/dataflow';

type FromWebview =
  | { type: 'ready' }
  | { type: 'openDispatch'; entry: string }
  | { type: 'openLine'; line: number };

function isFromWebview(m: unknown): m is FromWebview {
  if (typeof m !== 'object' || m === null) {
    return false;
  }
  const o = m as { type?: unknown; entry?: unknown; line?: unknown };
  return o.type === 'ready'
    || (o.type === 'openDispatch' && typeof o.entry === 'string')
    || (o.type === 'openLine' && typeof o.line === 'number');
}

export class DataFlowPanel implements vscode.Disposable {
  private panel: vscode.WebviewPanel | undefined;
  private ready = false;
  private program: FlowProgram | undefined;
  private readonly subs: vscode.Disposable[] = [];

  constructor(
    private readonly extensionUri: vscode.Uri,
    private readonly onOpenDispatch: (entry: string) => void,
  ) {}

  dispose(): void {
    this.panel?.dispose();
    this.subs.forEach((s) => s.dispose());
  }

  get isOpen(): boolean {
    return this.panel !== undefined;
  }

  show(program: FlowProgram): void {
    this.program = program;
    if (!this.panel) {
      const media = vscode.Uri.joinPath(this.extensionUri, 'media');
      this.ready = false;
      this.panel = vscode.window.createWebviewPanel(
        'ireeExplorer.dataFlow', 'Data Flow', vscode.ViewColumn.Active,
        { enableScripts: true, localResourceRoots: [media], retainContextWhenHidden: true },
      );
      this.panel.iconPath = vscode.Uri.joinPath(this.extensionUri, 'media', 'iree.svg');
      this.panel.webview.html = this.html(this.panel.webview);
      this.panel.onDidDispose(() => { this.panel = undefined; this.ready = false; }, null, this.subs);
      this.panel.webview.onDidReceiveMessage((m: unknown) => this.onMessage(m), null, this.subs);
    } else {
      this.panel.reveal();
    }
    this.post();
  }

  /** Refreshes an open panel after a recompile. */
  update(program: FlowProgram | undefined): void {
    if (this.panel && program) {
      this.program = program;
      this.post();
    }
  }

  private post(): void {
    if (this.panel && this.ready && this.program) {
      void this.panel.webview.postMessage({ type: 'render', program: this.program });
    }
  }

  private async onMessage(m: unknown): Promise<void> {
    if (!isFromWebview(m)) {
      return;
    }
    if (m.type === 'ready') {
      this.ready = true;
      this.post();
    } else if (m.type === 'openDispatch') {
      this.onOpenDispatch(m.entry);
    } else if (this.program) {
      const doc = await vscode.workspace.openTextDocument(vscode.Uri.file(this.program.file));
      const line = Math.max(0, m.line - 1);
      await vscode.window.showTextDocument(doc, { viewColumn: vscode.ViewColumn.Beside, selection: new vscode.Range(line, 0, line, 0) });
    }
  }

  private html(webview: vscode.Webview): string {
    const nonce = randomBytes(16).toString('base64');
    const script = webview.asWebviewUri(vscode.Uri.joinPath(this.extensionUri, 'media', 'dataflow', 'main.js'));
    const style = webview.asWebviewUri(vscode.Uri.joinPath(this.extensionUri, 'media', 'dataflow', 'style.css'));
    const csp = [`default-src 'none'`, `style-src ${webview.cspSource}`, `script-src 'nonce-${nonce}'`].join('; ');
    return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta http-equiv="Content-Security-Policy" content="${csp}">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="stylesheet" href="${style}">
<title>Data Flow</title>
</head>
<body>
<div id="app"><p>Loading…</p></div>
<script nonce="${nonce}" src="${script}"></script>
</body>
</html>`;
  }
}
