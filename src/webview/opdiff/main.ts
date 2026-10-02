// Op Changes webview: per-op-kind count deltas and the individual ops a pass
// added, removed or modified. No framework; all text via textContent.

import { OpChange, OpChangeKind, OpCount, OpDiffView } from '../../model/opdiff';

interface VsCodeApi {
  postMessage(msg: unknown): void;
}
declare function acquireVsCodeApi(): VsCodeApi;

type ToWebview = { type: 'render'; view: OpDiffView };

const vscode = acquireVsCodeApi();
const app = document.getElementById('app') as HTMLElement;
const MAX_ROWS = 500;
const KINDS: OpChangeKind[] = ['modified', 'added', 'removed'];

let current: OpDiffView | undefined;
let filter = '';
const shownKinds = new Set<OpChangeKind>(KINDS);

function el<K extends keyof HTMLElementTagNameMap>(tag: K, cls?: string, text?: string): HTMLElementTagNameMap[K] {
  const e = document.createElement(tag);
  if (cls) {
    e.className = cls;
  }
  if (text !== undefined) {
    e.textContent = text;
  }
  return e;
}

/** "+3", "−2", "0" */
export function signed(n: number): string {
  return n > 0 ? `+${n}` : n < 0 ? `−${-n}` : '0';
}

function matches(name: string): boolean {
  return filter === '' || name.toLowerCase().includes(filter.toLowerCase());
}

function lineButton(side: 'before' | 'after', line: number): HTMLButtonElement {
  const b = el('button', 'link line', `L${line}`);
  b.title = `Open the ${side === 'before' ? 'earlier' : 'later'} dump at line ${line}`;
  b.addEventListener('click', () => vscode.postMessage({ type: 'openLine', side, line }));
  return b;
}

function countsTable(counts: OpCount[]): HTMLElement {
  const rows = counts.filter((c) => matches(c.name));
  const wrap = el('section');
  wrap.append(el('h2', undefined, 'By op kind'));
  if (rows.length === 0) {
    wrap.append(el('p', 'muted', 'No op kinds match.'));
    return wrap;
  }
  const table = el('table', 'counts');
  const head = el('tr');
  for (const h of ['Op', 'Before', 'After', 'Change', 'Modified']) {
    head.append(el('th', h === 'Op' ? undefined : 'num', h));
  }
  table.append(el('thead'));
  table.tHead!.append(head);
  const body = el('tbody');
  for (const c of rows) {
    const tr = el('tr', 'count-row');
    const name = el('button', 'link op', c.name);
    name.title = `Show only ${c.name}`;
    name.addEventListener('click', () => setFilter(c.name));
    const nameCell = el('td');
    nameCell.append(name);
    const delta = c.after - c.before;
    tr.append(
      nameCell,
      el('td', 'num', String(c.before)),
      el('td', 'num', String(c.after)),
      el('td', `num ${delta > 0 ? 'pos' : delta < 0 ? 'neg' : 'muted'}`, signed(delta)),
      el('td', `num ${c.modified > 0 ? 'mod' : 'muted'}`, c.modified > 0 ? String(c.modified) : '–'),
    );
    body.append(tr);
  }
  table.append(body);
  wrap.append(table);
  return wrap;
}

function changeRow(c: OpChange): HTMLElement {
  const row = el('div', `change ${c.kind}`);
  const title = el('div', 'change-title');
  title.append(el('span', 'badge', c.kind), el('span', 'op', c.name));
  const lines = el('span', 'lines');
  if (c.before) {
    lines.append(lineButton('before', c.before.line));
  }
  if (c.before && c.after) {
    lines.append(el('span', 'muted', ' → '));
  }
  if (c.after) {
    lines.append(lineButton('after', c.after.line));
  }
  title.append(lines);
  row.append(title);
  if (c.before) {
    row.append(el('div', 'code del', c.before.text));
  }
  if (c.after) {
    row.append(el('div', 'code ins', c.after.text));
  }
  return row;
}

function changeList(changes: OpChange[], truncated: boolean): HTMLElement {
  const wrap = el('section');
  const header = el('div', 'list-header');
  header.append(el('h2', undefined, 'Changed ops'));
  for (const k of KINDS) {
    const label = el('label', `toggle ${k}`);
    const box = el('input');
    box.type = 'checkbox';
    box.checked = shownKinds.has(k);
    box.addEventListener('change', () => {
      if (box.checked) {
        shownKinds.add(k);
      } else {
        shownKinds.delete(k);
      }
      render();
    });
    label.append(box, document.createTextNode(` ${k}`));
    header.append(label);
  }
  wrap.append(header);
  const rows = changes.filter((c) => shownKinds.has(c.kind) && matches(c.name));
  if (rows.length === 0) {
    wrap.append(el('p', 'muted', 'No changed ops match.'));
  }
  const list = el('div', 'changes');
  for (const c of rows.slice(0, MAX_ROWS)) {
    list.append(changeRow(c));
  }
  wrap.append(list);
  if (rows.length > MAX_ROWS || truncated) {
    wrap.append(el('p', 'muted small', `Showing the first ${Math.min(rows.length, MAX_ROWS)} changed ops. Filter by op name to narrow the list, or open the text diff.`));
  }
  return wrap;
}

function setFilter(value: string): void {
  filter = value;
  render();
  const input = app.querySelector<HTMLInputElement>('input.filter');
  input?.focus();
}

function render(): void {
  if (!current) {
    return;
  }
  const { before, after, diff } = current;
  app.replaceChildren();

  const top = el('header');
  top.append(el('h1', undefined, 'Op Changes'));
  const textDiff = el('button', 'link', 'Open text diff');
  textDiff.addEventListener('click', () => vscode.postMessage({ type: 'openTextDiff' }));
  top.append(textDiff);
  app.append(top);
  app.append(el('div', 'range', `${before.label}  →  ${after.label}`));
  app.append(el('div', 'facts',
    `${diff.totalBefore} → ${diff.totalAfter} ops  ·  ${diff.added} added  ·  ${diff.removed} removed  ·  ${diff.modified} modified`));

  if (diff.added + diff.removed + diff.modified === 0) {
    app.append(el('p', 'muted', 'No op-level changes. Any text differences are in value names, locations or the dump header.'));
    return;
  }

  const input = el('input', 'filter');
  input.type = 'search';
  input.placeholder = 'Filter by op name, e.g. linalg or arith.constant';
  input.value = filter;
  input.addEventListener('input', () => {
    filter = input.value.trim();
    const pos = input.selectionStart;
    render();
    const again = app.querySelector<HTMLInputElement>('input.filter');
    again?.focus();
    again?.setSelectionRange(pos, pos);
  });
  app.append(input);

  app.append(countsTable(diff.counts), changeList(diff.changes, diff.truncated));
}

window.addEventListener('message', (e: MessageEvent<ToWebview>) => {
  if (e.data?.type === 'render') {
    current = e.data.view;
    filter = '';
    KINDS.forEach((k) => shownKinds.add(k));
    render();
  }
});

vscode.postMessage({ type: 'ready' });
