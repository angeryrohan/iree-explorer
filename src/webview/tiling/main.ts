// Tiling webview. Renders a DispatchInfo as nested SVG rectangles plus the
// derived numbers. No framework; all text goes through textContent.

import {
  computeChecks, computeLevelStats, computeTilingGeometry, DEFAULT_GEOMETRY_OPTIONS, dimLabel, formatBytes,
} from '../../model/tiling';
import { DispatchInfo, TilingCheck, TilingGeometry } from '../../model/types';

interface VsCodeApi {
  postMessage(msg: unknown): void;
}
declare function acquireVsCodeApi(): VsCodeApi;

type ToWebview =
  | { type: 'render'; dispatch: DispatchInfo }
  | { type: 'clear' }
  | { type: 'error'; message: string };

const vscode = acquireVsCodeApi();
const app = document.getElementById('app') as HTMLElement;
const SVG_NS = 'http://www.w3.org/2000/svg';
const LEVEL_COLORS = ['blue', 'orange', 'green', 'purple', 'red', 'yellow'];

function levelColor(i: number): string {
  return `var(--vscode-charts-${LEVEL_COLORS[i % LEVEL_COLORS.length]})`;
}

/** CSS class carrying the level colour (SVG attributes can't use var()). */
function colorClass(i: number): string {
  return `c-${i % LEVEL_COLORS.length}`;
}

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

function svg<K extends keyof SVGElementTagNameMap>(tag: K, attrs: Record<string, string | number>): SVGElementTagNameMap[K] {
  const e = document.createElementNS(SVG_NS, tag);
  for (const [k, v] of Object.entries(attrs)) {
    e.setAttribute(k, String(v));
  }
  return e;
}

function fmtList(xs: number[]): string {
  return `[${xs.join(', ')}]`;
}

function clear(): void {
  app.replaceChildren(el('p', 'muted', 'Select a dispatch in the IREE › Dispatches view.'));
}

function showError(message: string): void {
  app.replaceChildren(el('p', 'error', message));
}

/** Names for iteration dims of the dispatch being rendered (M/N/K, OH/OW, or d0…). */
let dimName: (i: number) => string = (i) => `d${i}`;

const CHECK_ICON: Record<TilingCheck['status'], string> = { ok: '✓', warn: '!', info: 'i' };

function render(d: DispatchInfo): void {
  const root = document.createDocumentFragment();
  dimName = (i) => dimLabel(d, i);

  // ----- header: what is this kernel, in one line -----
  const h = el('header');
  h.appendChild(el('h1', undefined, d.name));
  const facts: string[] = [];
  if (d.opName) {
    facts.push(d.opName);
  }
  if (d.iterationDomain.length > 0) {
    facts.push(`${d.iterationDomain.map((_, i) => dimName(i)).join('×')} = ${d.iterationDomain.join('×')}`);
  }
  if (d.translation?.pipeline) {
    facts.push(d.translation.pipeline);
  }
  const hw = d.hardware;
  if (hw) {
    facts.push([hw.kind === 'gpu' ? 'GPU' : hw.kind === 'cpu' ? 'CPU' : hw.backend, hw.arch].filter(Boolean).join(' '));
  }
  const line = el('div', 'facts', facts.join('  ·  '));
  h.appendChild(line);
  if (d.sourceLine !== undefined) {
    const b = el('button', 'link', `Open in IR (${d.sourceFile.split(/[\\/]/).pop() ?? 'source'}:${d.sourceLine})`);
    b.addEventListener('click', () => vscode.postMessage({ type: 'openSource', file: d.sourceFile, line: d.sourceLine }));
    h.appendChild(b);
  }
  root.appendChild(h);

  let geo: TilingGeometry | undefined;
  try {
    geo = d.config ? computeTilingGeometry(d, DEFAULT_GEOMETRY_OPTIONS) : undefined;
  } catch (e) {
    root.appendChild(el('p', 'error', `Geometry failed: ${String(e)}`));
  }

  // ----- verdict: the checklist -----
  root.appendChild(checklist(computeChecks(d, geo)));

  if (!d.config) {
    app.replaceChildren(root);
    return;
  }
  if (!geo) {
    root.appendChild(fallbackTable(d));
    root.appendChild(details(d));
    app.replaceChildren(root);
    return;
  }

  // ----- picture -----
  const body = el('div', 'body');
  const drawing = el('div', 'drawing');
  const main = drawMain(geo);
  drawing.appendChild(main);
  if (geo.reductionDims.length > 0) {
    drawing.appendChild(drawReduction(geo));
  }
  body.appendChild(drawing);
  body.appendChild(legend(geo, main.parentElement ?? drawing));
  root.appendChild(body);

  // Non-ragged notes (clamping, truncation); ragged tiles are in the checklist.
  const notes = geo.warnings.filter((w) => !/not divisible/.test(w));
  if (notes.length > 0) {
    const n = el('ul', 'notes');
    notes.forEach((m) => n.appendChild(el('li', undefined, m)));
    root.appendChild(n);
  }

  // ----- numbers, collapsed -----
  root.appendChild(details(d, geo));
  app.replaceChildren(root);
}

function checklist(checks: TilingCheck[]): HTMLElement {
  const ul = el('ul', 'checks');
  for (const c of checks) {
    const li = el('li', `check ${c.status}`);
    li.appendChild(el('span', 'check-icon', CHECK_ICON[c.status]));
    const text = el('div', 'check-text');
    text.appendChild(el('div', 'check-title', c.title));
    text.appendChild(el('div', 'check-detail', c.detail));
    li.appendChild(text);
    ul.appendChild(li);
  }
  return ul;
}

function details(d: DispatchInfo, geo?: TilingGeometry): HTMLElement {
  const det = el('details', 'numbers');
  det.appendChild(el('summary', undefined, 'Numbers and raw attributes'));
  if (geo) {
    det.appendChild(levelTable(geo));
    det.appendChild(footprintTable(geo, d));
  }
  det.appendChild(rawConfig(d));
  return det;
}

// ---------------------------------------------------------------------------

const PAD_L = 44;
const PAD_T = 28;

function hatchPattern(defs: SVGDefsElement, level: number): string {
  const id = `hatch-${level}`;
  const p = svg('pattern', { id, width: 6, height: 6, patternUnits: 'userSpaceOnUse', patternTransform: 'rotate(45)' });
  p.appendChild(svg('line', { x1: 0, y1: 0, x2: 0, y2: 6, class: `hatch-line ${colorClass(level)}` }));
  defs.appendChild(p);
  return id;
}

function drawMain(geo: TilingGeometry): SVGSVGElement {
  const [xd, yd] = geo.axes;
  const X = geo.domain[xd];
  const Y = yd >= 0 ? geo.domain[yd] : 1;
  const px = DEFAULT_GEOMETRY_OPTIONS.canvasPx;
  const scale = px / Math.max(X, yd >= 0 ? Y : 1);
  const W = X * scale;
  const H = yd >= 0 ? Y * scale : 48;
  const sy = yd >= 0 ? scale : H;
  const s = svg('svg', { width: W + PAD_L + 8, height: H + PAD_T + 8, class: 'tiles', role: 'img' });
  const defs = svg('defs', {});
  s.appendChild(defs);
  const g = svg('g', { transform: `translate(${PAD_L},${PAD_T})` });
  s.appendChild(g);

  const title = svg('text', { x: W / 2, y: -10, 'text-anchor': 'middle', class: 'axis' });
  title.textContent = `${dimName(xd)} = ${X}`;
  g.appendChild(title);
  if (yd >= 0) {
    const t = svg('text', { x: -10, y: H / 2, 'text-anchor': 'middle', class: 'axis', transform: `rotate(-90 -10 ${H / 2})` });
    t.textContent = `${dimName(yd)} = ${Y}`;
    g.appendChild(t);
  }

  g.appendChild(svg('rect', { x: 0, y: 0, width: W, height: H, class: 'domain' }));
  const patterns = new Map<number, string>();
  for (const h of geo.hatches) {
    if (!patterns.has(h.level)) {
      patterns.set(h.level, hatchPattern(defs, h.level));
    }
  }
  const nLevels = Math.max(1, geo.levels.length);
  const labels: SVGTextElement[] = [];
  for (const hz of geo.hatches) {
    const x = hz.x * scale;
    const y = hz.y * sy;
    const w = hz.w * scale;
    const hh = hz.h * sy;
    const grp = svg('g', { class: `lvl lvl-${hz.level}`, 'data-level': hz.level });
    grp.appendChild(svg('rect', { x, y, width: w, height: hh, fill: `url(#${patterns.get(hz.level)})`, class: 'hatch' }));
    if (w > 28 && hh > 14) {
      const t = svg('text', { x: x + w / 2, y: y + hh / 2 + 4, 'text-anchor': 'middle', class: 'count' });
      t.textContent = `×${hz.count}`;
      labels.push(t);
    }
    const tt = svg('title', {});
    tt.textContent = `${geo.levels[hz.level]?.name}: ${hz.count} tiles (too small to draw individually)`;
    grp.appendChild(tt);
    g.appendChild(grp);
  }
  // Outer levels are drawn last so their boundaries stay visible where they
  // coincide with inner tile edges; hatches go underneath everything.
  const ordered = geo.rects.slice().sort((a, b) => b.level - a.level);
  for (const r of ordered) {
    const rect = svg('rect', {
      x: r.x * scale, y: r.y * sy, width: r.w * scale, height: r.h * sy,
      class: `tile lvl lvl-${r.level} ${colorClass(r.level)}${r.ragged ? ' ragged' : ''}`,
      'stroke-width': Math.max(0.5, 2.5 - (2 * r.level) / nLevels),
      'data-level': r.level,
    });
    const tt = svg('title', {});
    tt.textContent = `${geo.levels[r.level]?.name ?? `level ${r.level}`}: ${r.w}×${r.h} at (${r.x}, ${r.y})${r.ragged ? ' — remainder tile' : ''}`;
    rect.appendChild(tt);
    g.appendChild(rect);
  }
  labels.forEach((l) => g.appendChild(l));
  return s;
}

function drawReduction(geo: TilingGeometry): HTMLElement {
  const rd = geo.reductionDims[0];
  const K = geo.domain[rd];
  const W = DEFAULT_GEOMETRY_OPTIONS.stripPx;
  const rows = Math.max(1, geo.levels.length);
  const rowH = 14;
  const wrap = el('div', 'strip');
  wrap.appendChild(el('div', 'caption', `reduction ${dimName(rd)} = ${K} (the loop inside each tile)${geo.reductionDims.length > 1 ? `, +${geo.reductionDims.length - 1} more reduction dims` : ''}`));
  const s = svg('svg', { width: W + PAD_L + 8, height: rows * (rowH + 4) + 4, class: 'tiles' });
  const defs = svg('defs', {});
  s.appendChild(defs);
  const g = svg('g', { transform: `translate(${PAD_L},2)` });
  s.appendChild(g);
  const scale = W / K;
  geo.levels.forEach((l, i) => {
    const lbl = svg('text', { x: -6, y: i * (rowH + 4) + rowH - 3, 'text-anchor': 'end', class: 'axis small' });
    lbl.textContent = l.sizes[rd] ? String(l.sizes[rd]) : '—';
    g.appendChild(lbl);
    g.appendChild(svg('rect', { x: 0, y: i * (rowH + 4), width: W, height: rowH, class: 'domain' }));
  });
  for (const r of geo.reductionRects) {
    const rect = svg('rect', {
      x: r.x * scale, y: r.level * (rowH + 4), width: r.w * scale, height: rowH,
      class: `tile lvl lvl-${r.level} ${colorClass(r.level)}${r.ragged ? ' ragged' : ''}`, 'data-level': r.level,
    });
    const tt = svg('title', {});
    tt.textContent = `${geo.levels[r.level]?.name}: k ${r.x}..${r.x + r.w}${r.ragged ? ' — remainder' : ''}`;
    rect.appendChild(tt);
    g.appendChild(rect);
  }
  for (const hz of geo.reductionHatches) {
    const id = hatchPattern(defs, hz.level);
    const grp = svg('g', { class: `lvl lvl-${hz.level}`, 'data-level': hz.level });
    grp.appendChild(svg('rect', { x: 0, y: hz.level * (rowH + 4), width: W, height: rowH, fill: `url(#${id})` }));
    const t = svg('text', { x: W / 2, y: hz.level * (rowH + 4) + rowH - 3, 'text-anchor': 'middle', class: 'count' });
    t.textContent = `×${hz.count}`;
    grp.appendChild(t);
    g.appendChild(grp);
  }
  wrap.appendChild(s);
  return wrap;
}

function legend(geo: TilingGeometry, scopeEl: HTMLElement): HTMLElement {
  const box = el('div', 'legend');
  box.appendChild(el('h2', undefined, 'Tile per level'));
  const [xd, yd] = geo.axes;
  const host = scopeEl.closest('.body') ?? document.body;
  geo.levels.forEach((l, i) => {
    const row = el('div', 'legend-row');
    const sw = el('span', 'swatch');
    sw.style.background = levelColor(i);
    row.appendChild(sw);
    row.appendChild(el('span', 'lname', l.name));
    const onAxes = yd >= 0 ? `${l.effective[xd]}×${l.effective[yd]}` : `${l.effective[xd]}`;
    row.appendChild(el('span', 'lsizes', onAxes));
    row.title = `tile_sizes ${fmtList(l.sizes)}`;
    row.addEventListener('mouseenter', () => {
      host.classList.add('focus');
      host.setAttribute('data-focus', String(i));
      host.querySelectorAll('.lvl').forEach((n) => n.classList.toggle('active', n.getAttribute('data-level') === String(i)));
    });
    row.addEventListener('mouseleave', () => {
      host.classList.remove('focus');
      host.querySelectorAll('.lvl.active').forEach((n) => n.classList.remove('active'));
    });
    box.appendChild(row);
  });
  if (geo.rects.some((r) => r.ragged)) {
    const rag = el('div', 'legend-row');
    rag.appendChild(el('span', 'swatch ragged-swatch'));
    rag.appendChild(el('span', 'lname', 'partial tile'));
    box.appendChild(rag);
  }
  if (geo.truncated) {
    box.appendChild(el('p', 'muted small', 'Hatched = too many tiles to draw; the number is the count.'));
  }
  return box;
}

function levelTable(geo: TilingGeometry): HTMLElement {
  const wrap = el('div', 'table-wrap');
  wrap.appendChild(el('h2', undefined, 'Tiles per level'));
  const t = el('table');
  const head = el('tr');
  for (const c of ['level', 'tile sizes', 'effective tile', 'tiles per dim (in parent)', 'tiles', 'remainder']) {
    head.appendChild(el('th', undefined, c));
  }
  t.appendChild(head);
  geo.levels.forEach((l, i) => {
    const tr = el('tr', `lvl lvl-${i}`);
    tr.setAttribute('data-level', String(i));
    const name = el('td');
    const sw = el('span', 'swatch');
    sw.style.background = levelColor(i);
    name.appendChild(sw);
    name.appendChild(document.createTextNode(l.name));
    tr.appendChild(name);
    tr.appendChild(el('td', 'mono', fmtList(l.sizes)));
    tr.appendChild(el('td', 'mono', fmtList(l.effective)));
    const per = l.tilesPerDim.map((n, dd) => ((l.sizes[dd] ?? 0) > 0 ? `${dimName(dd)}:${n}` : '')).filter(Boolean).join(' ');
    tr.appendChild(el('td', 'mono', per || '—'));
    tr.appendChild(el('td', 'mono', l.tilesTotal.toLocaleString()));
    const rag = el('td', l.raggedDims.length > 0 ? 'warn mono' : 'mono', l.raggedDims.length > 0 ? l.raggedDims.map((dd) => dimName(dd)).join(', ') : 'even');
    tr.appendChild(rag);
    t.appendChild(tr);
  });
  const scroll = el('div', 'scroll');
  scroll.appendChild(t);
  wrap.appendChild(scroll);
  return wrap;
}

function footprintTable(geo: TilingGeometry, d: DispatchInfo): HTMLElement {
  const wrap = el('div', 'table-wrap');
  wrap.appendChild(el('h2', undefined, 'Per-workgroup operand tiles'));
  if (geo.footprints.length === 0) {
    wrap.appendChild(el('p', 'muted', 'Operand shapes not available.'));
    return wrap;
  }
  wrap.appendChild(el('p', 'muted small',
    'Parallel dims use the workgroup tile; each reduction dim uses the first level that tiles it (else its full extent). Convolution inputs include the window halo.'));
  const t = el('table');
  const head = el('tr');
  for (const c of ['operand', 'role', 'full shape', 'tile shape', 'bytes']) {
    head.appendChild(el('th', undefined, c));
  }
  t.appendChild(head);
  geo.footprints.forEach((f) => {
    const op = d.operands.find((o) => o.name === f.name && o.role === f.role);
    const tr = el('tr');
    tr.appendChild(el('td', 'mono', f.name));
    tr.appendChild(el('td', undefined, f.role));
    tr.appendChild(el('td', 'mono', op ? `${op.shape.join('×')}×${op.elementType}` : ''));
    tr.appendChild(el('td', 'mono', f.tileShape.join('×')));
    tr.appendChild(el('td', 'mono', f.bytes !== undefined ? formatBytes(f.bytes) : '?'));
    t.appendChild(tr);
  });
  const scroll = el('div', 'scroll');
  scroll.appendChild(t);
  wrap.appendChild(scroll);
  return wrap;
}

function fallbackTable(d: DispatchInfo): HTMLElement {
  const wrap = el('div', 'table-wrap');
  const t = el('table');
  const head = el('tr');
  head.appendChild(el('th', undefined, 'level'));
  const width = Math.max(0, ...(d.config?.levels.map((l) => l.sizes.length) ?? [0]));
  for (let i = 0; i < width; i++) {
    head.appendChild(el('th', undefined, `d${i}${d.iteratorTypes[i] ? ` (${d.iteratorTypes[i][0]})` : ''}`));
  }
  t.appendChild(head);
  const { levels } = computeLevelStats(d);
  levels.forEach((l, i) => {
    const tr = el('tr');
    const name = el('td');
    const sw = el('span', 'swatch');
    sw.style.background = levelColor(i);
    name.appendChild(sw);
    name.appendChild(document.createTextNode(l.name));
    tr.appendChild(name);
    for (let k = 0; k < width; k++) {
      tr.appendChild(el('td', 'mono', l.sizes[k] !== undefined ? String(l.sizes[k]) : ''));
    }
    t.appendChild(tr);
  });
  const scroll = el('div', 'scroll');
  scroll.appendChild(t);
  wrap.appendChild(scroll);
  return wrap;
}

function rawConfig(d: DispatchInfo): HTMLElement {
  const det = el('details');
  det.appendChild(el('summary', undefined, 'Raw attributes'));
  if (d.config) {
    det.appendChild(el('pre', undefined, d.config.raw));
  }
  if (d.translation) {
    det.appendChild(el('pre', undefined, d.translation.raw));
  }
  return det;
}

window.addEventListener('message', (ev: MessageEvent) => {
  const msg = ev.data as ToWebview;
  try {
    switch (msg?.type) {
      case 'render':
        render(msg.dispatch);
        break;
      case 'clear':
        clear();
        break;
      case 'error':
        showError(msg.message);
        break;
    }
  } catch (e) {
    showError(`Rendering failed: ${String(e)}`);
  }
});

vscode.postMessage({ type: 'ready' });
