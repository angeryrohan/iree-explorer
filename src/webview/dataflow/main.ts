// Data-flow webview: the program's kernels in execution order, with arcs for
// the tensors flowing between them. No framework; all text via textContent.

import { formatBytes } from '../../model/tiling';
import { FlowNode, FlowProgram, FlowValue } from '../../model/dataflow';

interface VsCodeApi {
  postMessage(msg: unknown): void;
}
declare function acquireVsCodeApi(): VsCodeApi;

type ToWebview =
  | { type: 'render'; program: FlowProgram }
  | { type: 'error'; message: string };

const vscode = acquireVsCodeApi();
const app = document.getElementById('app') as HTMLElement;
const SVG_NS = 'http://www.w3.org/2000/svg';
const ROW_H = 64;
const BOX_H = 52;
const LANE_W = 12;
const MAX_NODES = 400;

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

/** "tensor<4x128xf32>" -> "4×128 f32" */
export function shortType(t: string): string {
  const m = /^tensor<(.*)>$/.exec(t);
  if (!m) {
    return t;
  }
  const parts = m[1].split(',')[0].split('x');
  const elt = parts.pop() ?? '';
  return parts.length > 0 ? `${parts.join('×')} ${elt}` : elt;
}

function valueText(v: FlowValue): string {
  return `${shortType(v.type)}${v.bytes !== undefined ? ` (${formatBytes(v.bytes)})` : ''}`;
}

/** Assigns each multi-row edge a gutter lane so arcs don't overlap. */
export function assignLanes(edges: Array<{ from: number; to: number }>): number[] {
  const order = edges.map((_, i) => i).sort((a, b) => edges[a].from - edges[b].from || edges[a].to - edges[b].to);
  const laneEnd: number[] = [];
  const lanes = new Array<number>(edges.length).fill(0);
  for (const i of order) {
    const { from, to } = edges[i];
    let lane = laneEnd.findIndex((end) => end <= from);
    if (lane < 0) {
      lane = laneEnd.length;
      laneEnd.push(to);
    } else {
      laneEnd[lane] = to;
    }
    lanes[i] = lane;
  }
  return lanes;
}

let program: FlowProgram | undefined;
let selected = 0;

function render(): void {
  if (!program) {
    return;
  }
  const root = document.createDocumentFragment();
  if (program.graphs.length === 0) {
    root.appendChild(el('p', 'muted', 'No flow-level program found in this compile (no flow.dispatch ops). Compile to "flow" or later.'));
    app.replaceChildren(root);
    return;
  }
  const g = program.graphs[Math.min(selected, program.graphs.length - 1)];

  // ----- header -----
  const h = el('header');
  const title = el('h1', undefined, `@${g.func}`);
  h.appendChild(title);
  if (program.graphs.length > 1) {
    const sel = el('select');
    program.graphs.forEach((gr, i) => {
      const o = el('option', undefined, `@${gr.func}`);
      o.value = String(i);
      o.selected = i === selected;
      sel.appendChild(o);
    });
    sel.addEventListener('change', () => {
      selected = Number(sel.value);
      render();
    });
    h.appendChild(sel);
  }
  const dispatches = g.nodes.filter((n) => n.kind === 'dispatch').length;
  const inter = g.edges.filter((e) => g.nodes[e.from].kind !== 'input' && g.nodes[e.to].kind !== 'output');
  const biggest = inter.reduce<FlowValue | undefined>((m, e) => ((e.value.bytes ?? 0) > (m?.bytes ?? -1) ? e.value : m), undefined);
  const count = (n: number, word: string) => `${n} ${word}${n === 1 ? '' : 's'}`;
  const facts = [
    count(dispatches, 'kernel'),
    count(g.nodes.filter((n) => n.kind === 'input').length, 'input'),
    count(g.nodes.filter((n) => n.kind === 'output').length, 'output'),
  ];
  if (biggest?.bytes !== undefined) {
    facts.push(`largest intermediate ${formatBytes(biggest.bytes)}`);
  }
  h.appendChild(el('div', 'facts', facts.join('  ·  ')));
  const open = el('button', 'link', 'Open the flow-level IR');
  open.addEventListener('click', () => vscode.postMessage({ type: 'openLine', line: 1 }));
  h.appendChild(open);
  h.appendChild(el('p', 'muted small', 'Kernels in the order the program runs them. Arcs are tensors passed between them. Click a kernel to see its tiling.'));
  root.appendChild(h);

  // ----- graph -----
  const nodes = g.nodes.slice(0, MAX_NODES);
  const edges = g.edges.filter((e) => e.from < nodes.length && e.to < nodes.length);
  const lanes = assignLanes(edges);
  const laneCount = Math.max(0, ...lanes.map((l) => l + 1));
  const gutter = 16 + laneCount * LANE_W;

  const graph = el('div', 'graph');
  graph.style.height = `${nodes.length * ROW_H}px`;
  const arcs = svg('svg', { class: 'arcs', width: gutter + 4, height: nodes.length * ROW_H });
  const defs = svg('defs', {});
  const marker = svg('marker', { id: 'arrow', viewBox: '0 0 8 8', refX: 7, refY: 4, markerWidth: 7, markerHeight: 7, orient: 'auto' });
  marker.appendChild(svg('path', { d: 'M0,0 L8,4 L0,8 z', class: 'arrowhead' }));
  defs.appendChild(marker);
  arcs.appendChild(defs);
  const cy = (i: number) => i * ROW_H + BOX_H / 2;
  edges.forEach((e, i) => {
    const x = gutter - 8 - lanes[i] * LANE_W;
    const y1 = cy(e.from) + 6;
    const y2 = cy(e.to) - 6;
    const p = svg('path', {
      d: `M${gutter},${y1} H${x} V${y2} H${gutter}`,
      class: `arc from-${e.from} to-${e.to}`,
      'marker-end': 'url(#arrow)',
    });
    const t = svg('title', {});
    t.textContent = `${nodes[e.from].label} → ${nodes[e.to].label}: ${valueText(e.value)}`;
    p.appendChild(t);
    arcs.appendChild(p);
  });
  graph.appendChild(arcs);

  nodes.forEach((n, i) => graph.appendChild(box(n, i, gutter, edges)));
  root.appendChild(graph);
  if (g.nodes.length > MAX_NODES) {
    root.appendChild(el('p', 'muted', `Showing the first ${MAX_NODES} of ${g.nodes.length} steps.`));
  }
  app.replaceChildren(root);
}

function box(n: FlowNode, i: number, left: number, edges: Array<{ from: number; to: number; value: FlowValue }>): HTMLElement {
  const b = el('div', `node ${n.kind}`);
  b.style.top = `${i * ROW_H}px`;
  b.style.left = `${left + 4}px`;
  const top = el('div', 'node-title');
  const kindLabel = n.kind === 'dispatch' ? 'kernel' : n.kind;
  top.appendChild(el('span', 'badge', kindLabel));
  top.appendChild(el('span', 'name', n.label));
  b.appendChild(top);

  const ins = edges.filter((e) => e.to === i);
  const parts: string[] = [];
  if (n.kind === 'input' || n.kind === 'output') {
    const v = n.results[0];
    if (v) {
      parts.push(valueText(v));
    }
  } else {
    if (ins.length > 0) {
      parts.push(`reads ${ins.map((e) => valueText(e.value)).join(', ')}`);
    }
    if (n.results.length > 0) {
      parts.push(`writes ${n.results.map(valueText).join(', ')}`);
    }
  }
  b.appendChild(el('div', 'node-detail', parts.join('  →  ')));
  b.title = n.kind === 'dispatch' ? `${n.entry ?? ''}\nClick: show tiling · line ${n.line}` : `line ${n.line}`;

  b.addEventListener('mouseenter', () => {
    app.querySelectorAll(`.arc.from-${i}, .arc.to-${i}`).forEach((a) => a.classList.add('active'));
  });
  b.addEventListener('mouseleave', () => {
    app.querySelectorAll('.arc.active').forEach((a) => a.classList.remove('active'));
  });
  b.addEventListener('click', () => {
    if (n.kind === 'dispatch' && n.entry) {
      vscode.postMessage({ type: 'openDispatch', entry: n.entry });
    } else {
      vscode.postMessage({ type: 'openLine', line: n.line });
    }
  });
  return b;
}

window.addEventListener('message', (ev: MessageEvent) => {
  const msg = ev.data as ToWebview;
  try {
    if (msg?.type === 'render') {
      program = msg.program;
      selected = 0;
      render();
    } else if (msg?.type === 'error') {
      app.replaceChildren(el('p', 'error', msg.message));
    }
  } catch (e) {
    app.replaceChildren(el('p', 'error', `Rendering failed: ${String(e)}`));
  }
});

vscode.postMessage({ type: 'ready' });
