// Op Changes webview panel: which ops a pass (or range of passes) added,
// removed or modified. Same hardening as the other panels (nonce CSP, media/ only).

import { randomBytes } from 'crypto';
import * as vscode from 'vscode';
import { OpDiffView } from '../model/opdiff';

type FromWebview =
  | { type: 'ready' }
  | { type: 'openLine'; side: 'before' | 'after'; line: number }
  | { type: 'openTextDiff' };

function isFromWebview(m: unknown): m is FromWebview {
  if (typeof m !== 'object' || m === null) {
    return false;
  }
  const o = m as { type?: unknown; side?: unknown; line?: unknown };
  return o.type === 'ready'
    || o.type === 'openTextDiff'
    || (o.type === 'openLine' && (o.side === 'before' || o.side === 'after') && typeof o.line === 'number');
}

export class OpDiffPanel implements vscode.Disposable {
  private panel: vscode.WebviewPanel | undefined;
  private ready = false;
  private view: OpDiffView | undefined;
  private readonly subs: vscode.Disposable[] = [];

  constructor(
    private readonly extensionUri: vscode.Uri,
    private readonly onOpenTextDiff: (view: OpDiffView) => void,
  ) {}

  dispose(): void {
    this.panel?.dispose();
    this.subs.forEach((s) => s.dispose());
  }

  get isOpen(): boolean {
    return this.panel !== undefined;
  }

  show(view: OpDiffView): void {
    this.view = view;
    if (!this.panel) {
      const media = vscode.Uri.joinPath(this.extensionUri, 'media');
      this.ready = false;
      this.panel = vscode.window.createWebviewPanel(
        'ireeExplorer.opDiff', 'Op Changes', vscode.ViewColumn.Active,
        { enableScripts: true, localResourceRoots: [media], retainContextWhenHidden: true },
      );
      this.panel.iconPath = vscode.Uri.joinPath(this.extensionUri, 'media', 'iree.svg');
      this.panel.webview.html = this.html(this.panel.webview);
      this.panel.onDidDispose(() => { this.panel = undefined; this.ready = false; }, null, this.subs);
      this.panel.webview.onDidReceiveMessage((m: unknown) => this.onMessage(m), null, this.subs);
    } else {
      this.panel.reveal();
    }
    this.panel.title = `Op Changes: ${view.after.label}`;
    this.post();
  }

  /** Closes the panel; its dumps are gone after a recompile. */
  close(): void {
    this.panel?.dispose();
  }

  private post(): void {
    if (this.panel && this.ready && this.view) {
      void this.panel.webview.postMessage({ type: 'render', view: this.view });
    }
  }

  private async onMessage(m: unknown): Promise<void> {
    if (!isFromWebview(m)) {
      return;
    }
    if (m.type === 'ready') {
      this.ready = true;
      this.post();
    } else if (!this.view) {
      return;
    } else if (m.type === 'openTextDiff') {
      this.onOpenTextDiff(this.view);
    } else {
      const doc = await vscode.workspace.openTextDocument(vscode.Uri.file(this.view[m.side].file));
      if (doc.languageId !== 'mlir') {
        await vscode.languages.setTextDocumentLanguage(doc, 'mlir').then(undefined, () => undefined);
      }
      const line = Math.max(0, m.line - 1);
      await vscode.window.showTextDocument(doc, {
        viewColumn: vscode.ViewColumn.Beside,
        preview: true,
        selection: new vscode.Range(line, 0, line, 0),
      });
    }
  }

  private html(webview: vscode.Webview): string {
    const nonce = randomBytes(16).toString('base64');
    const script = webview.asWebviewUri(vscode.Uri.joinPath(this.extensionUri, 'media', 'opdiff', 'main.js'));
    const style = webview.asWebviewUri(vscode.Uri.joinPath(this.extensionUri, 'media', 'opdiff', 'style.css'));
    const csp = [`default-src 'none'`, `style-src ${webview.cspSource}`, `script-src 'nonce-${nonce}'`].join('; ');
    return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta http-equiv="Content-Security-Policy" content="${csp}">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="stylesheet" href="${style}">
<title>Op Changes</title>
</head>
<body>
<div id="app"><p>Loading…</p></div>
<script nonce="${nonce}" src="${script}"></script>
</body>
</html>`;
  }
}
