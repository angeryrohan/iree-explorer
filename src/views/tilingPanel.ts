// Tiling webview panel. The only webview in the extension. Strict CSP with a
// nonce; assets only from media/.

import { randomBytes } from 'crypto';
import * as vscode from 'vscode';
import { DispatchInfo } from '../model/types';

export type ToWebview =
  | { type: 'render'; dispatch: DispatchInfo }
  | { type: 'clear' }
  | { type: 'error'; message: string };

export type FromWebview =
  | { type: 'ready' }
  | { type: 'openSource'; file: string; line: number };

function isFromWebview(m: unknown): m is FromWebview {
  if (typeof m !== 'object' || m === null) {
    return false;
  }
  const t = (m as { type?: unknown }).type;
  if (t === 'ready') {
    return true;
  }
  if (t === 'openSource') {
    const o = m as { file?: unknown; line?: unknown };
    return typeof o.file === 'string' && typeof o.line === 'number';
  }
  return false;
}

export class TilingPanel implements vscode.Disposable {
  static readonly viewType = 'ireeExplorer.tiling';
  private panel: vscode.WebviewPanel | undefined;
  private ready = false;
  private pending: ToWebview | undefined;
  private current: DispatchInfo | undefined;
  private readonly subs: vscode.Disposable[] = [];

  constructor(private readonly extensionUri: vscode.Uri, private readonly log: (m: string) => void) {}

  dispose(): void {
    this.panel?.dispose();
    this.subs.forEach((s) => s.dispose());
  }

  get visibleDispatch(): DispatchInfo | undefined {
    return this.panel ? this.current : undefined;
  }

  get isOpen(): boolean {
    return this.panel !== undefined;
  }

  show(dispatch: DispatchInfo): void {
    this.current = dispatch;
    this.ensurePanel();
    this.panel!.title = `Tiling: ${dispatch.name}`;
    this.panel!.reveal(this.panel!.viewColumn ?? vscode.ViewColumn.Beside, true);
    this.post({ type: 'render', dispatch });
  }

  /** Updates the panel if it's open (e.g. after a recompile). */
  update(dispatch: DispatchInfo | undefined, message?: string): void {
    if (!this.panel) {
      return;
    }
    if (dispatch) {
      this.current = dispatch;
      this.panel.title = `Tiling: ${dispatch.name}`;
      this.post({ type: 'render', dispatch });
    } else {
      this.current = undefined;
      this.post(message ? { type: 'error', message } : { type: 'clear' });
    }
  }

  private post(msg: ToWebview): void {
    if (!this.panel) {
      return;
    }
    if (!this.ready) {
      this.pending = msg;
      return;
    }
    void this.panel.webview.postMessage(msg);
  }

  private ensurePanel(): void {
    if (this.panel) {
      return;
    }
    const media = vscode.Uri.joinPath(this.extensionUri, 'media');
    this.ready = false;
    this.panel = vscode.window.createWebviewPanel(
      TilingPanel.viewType,
      'Tiling',
      { viewColumn: vscode.ViewColumn.Beside, preserveFocus: true },
      { enableScripts: true, localResourceRoots: [media], retainContextWhenHidden: true },
    );
    this.panel.iconPath = vscode.Uri.joinPath(this.extensionUri, 'media', 'iree.svg');
    this.panel.webview.html = this.html(this.panel.webview);
    this.panel.onDidDispose(() => {
      this.panel = undefined;
      this.ready = false;
    }, null, this.subs);
    this.panel.webview.onDidReceiveMessage((m: unknown) => this.onMessage(m), null, this.subs);
  }

  private async onMessage(m: unknown): Promise<void> {
    if (!isFromWebview(m)) {
      return;
    }
    if (m.type === 'ready') {
      this.ready = true;
      const p = this.pending;
      this.pending = undefined;
      if (p) {
        this.post(p);
      }
      return;
    }
    // Only open files the panel was told about.
    if (this.current && m.file !== this.current.sourceFile) {
      this.log(`tiling: refused to open unexpected file ${m.file}`);
      return;
    }
    try {
      const doc = await vscode.workspace.openTextDocument(vscode.Uri.file(m.file));
      const line = Math.max(0, m.line - 1);
      await vscode.window.showTextDocument(doc, {
        viewColumn: vscode.ViewColumn.One,
        selection: new vscode.Range(line, 0, line, 0),
      });
    } catch (e) {
      vscode.window.showErrorMessage(`Could not open ${m.file}: ${String(e)}`);
    }
  }

  private html(webview: vscode.Webview): string {
    const nonce = randomBytes(16).toString('base64');
    const script = webview.asWebviewUri(vscode.Uri.joinPath(this.extensionUri, 'media', 'tiling', 'main.js'));
    const style = webview.asWebviewUri(vscode.Uri.joinPath(this.extensionUri, 'media', 'tiling', 'style.css'));
    const csp = [
      `default-src 'none'`,
      `img-src ${webview.cspSource} data:`,
      `style-src ${webview.cspSource}`,
      `script-src 'nonce-${nonce}'`,
    ].join('; ');
    return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta http-equiv="Content-Security-Policy" content="${csp}">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="stylesheet" href="${style}">
<title>Tiling</title>
</head>
<body>
<div id="app"><p class="muted">Select a dispatch in the IREE › Dispatches view.</p></div>
<script nonce="${nonce}" src="${script}"></script>
</body>
</html>`;
  }
}
