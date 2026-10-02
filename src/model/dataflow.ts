// Static data-flow graph of a compiled program: which kernels (dispatches)
// run in what order, and which tensors flow between them. Built from the
// flow-level IR (after dispatch creation, before stream lowering), where the
// host program is still expressed on tensors:
//   %0 = hal.tensor.import %arg0 "input0" : !hal.buffer_view -> tensor<4x64xf32>
//   %3 = flow.dispatch @exe::@entry(%0, %1) : (tensor<..>, tensor<..>) -> tensor<4x128xf32>
//   %5 = hal.tensor.export %4 "output0" : tensor<4x10xf32> -> !hal.buffer_view
// Pure; never throws.

import { elementBytes, parseShapedType, splitTopLevel } from './lowering';
import { PassNode } from './types';

export interface FlowValue {
  name: string;
  type: string;
  bytes?: number;
}

export interface FlowNode {
  id: number;
  kind: 'input' | 'output' | 'dispatch' | 'op';
  /** "input0", "matmul + tanh", "flow.tensor.reshape", ... */
  label: string;
  /** Dispatch entry symbol, for linking to the Dispatches view. */
  entry?: string;
  executable?: string;
  /** Linalg (and fused elementwise) ops inside the dispatch. */
  ops?: string[];
  results: FlowValue[];
  /** 1-based line in the source file. */
  line: number;
}

export interface FlowEdge {
  from: number;
  to: number;
  value: FlowValue;
}

export interface FlowGraph {
  func: string;
  nodes: FlowNode[];
  edges: FlowEdge[];
}

export interface FlowProgram {
  file: string;
  graphs: FlowGraph[];
}

function valueBytes(type: string): number | undefined {
  const st = parseShapedType(type);
  if (!st || st.shape.length === 0 || st.shape.some((d) => d < 0)) {
    return undefined;
  }
  const eb = elementBytes(st.elementType);
  return eb === undefined ? undefined : st.shape.reduce((a, b) => a * b, 1) * eb;
}

/** "tensor<4x128xf32>{%d}" -> "tensor<4x128xf32>" */
function cleanType(t: string): string {
  return t.trim().replace(/\{[^}]*\}\s*$/, '').trim();
}

/** Result types after the last top-level `->`. */
function resultTypes(line: string): string[] {
  const idx = line.lastIndexOf('->');
  if (idx < 0) {
    return [];
  }
  let rest = line.slice(idx + 2).trim();
  // Strip trailing attribute dicts / comments.
  rest = rest.replace(/\s+attributes\s*\{.*$/, '').replace(/\s*\/\/.*$/, '');
  if (rest.startsWith('(')) {
    rest = rest.slice(1, rest.lastIndexOf(')'));
  }
  return splitTopLevel(rest, ',').map(cleanType);
}

/** Maps entry symbol -> short op summary, from the flow.executable bodies. */
export function dispatchOpSummaries(text: string): Map<string, string[]> {
  const out = new Map<string, string[]>();
  const fnRe = /^\s*func\.func\s+(?:(?:public|private)\s+)?@([\w$.-]+)/gm;
  const starts: Array<{ name: string; index: number }> = [];
  for (let m = fnRe.exec(text); m; m = fnRe.exec(text)) {
    starts.push({ name: m[1], index: m.index });
  }
  for (let i = 0; i < starts.length; i++) {
    const end = i + 1 < starts.length ? starts[i + 1].index : text.length;
    const lines = text.slice(starts[i].index, end).split('\n');
    const ops: string[] = [];
    for (let j = 0; j < lines.length; j++) {
      const m = /=\s*linalg\.([a-z_0-9]+)\b/.exec(lines[j]) ?? /^\s*linalg\.([a-z_0-9]+)\b/.exec(lines[j]);
      if (!m || m[1] === 'yield' || m[1] === 'index') {
        continue;
      }
      if (m[1] === 'generic') {
        // Name a generic by the first real op in its body (e.g. math.tanh -> tanh).
        let body = 'generic';
        for (let k = j + 1; k < Math.min(lines.length, j + 30); k++) {
          if (/linalg\.yield/.test(lines[k])) {
            break;
          }
          const b = /=\s*(?:math|arith)\.([a-z_0-9]+)/.exec(lines[k]);
          if (b) {
            body = b[1];
            break;
          }
        }
        ops.push(body);
      } else if (m[1] !== 'fill') {
        ops.push(m[1]);
      }
    }
    if (ops.length > 0) {
      out.set(starts[i].name, ops);
    }
  }
  return out;
}

function shortName(entry: string, executable: string | undefined): string {
  // "mlp_dispatch_0_matmul_4x128x64_f32" -> "dispatch_0"
  const m = /(dispatch_\d+)/.exec(executable ?? entry);
  return m ? m[1] : entry;
}

/** Parses every public util.func / func.func in a flow-level module. */
export function parseFlowProgram(text: string, file: string): FlowProgram {
  try {
    return { file, graphs: parseGraphs(text) };
  } catch {
    return { file, graphs: [] };
  }
}

function parseGraphs(text: string): FlowGraph[] {
  const summaries = dispatchOpSummaries(text);
  const lines = text.split('\n');
  const graphs: FlowGraph[] = [];
  for (let i = 0; i < lines.length; i++) {
    const fm = /^ {2}(?:util|func)\.func public @([\w$.-]+)\(/.exec(lines[i]);
    if (!fm) {
      continue;
    }
    const g: FlowGraph = { func: fm[1], nodes: [], edges: [] };
    const producer = new Map<string, { node: number; value: FlowValue }>();
    for (let j = i + 1; j < lines.length && lines[j] !== '  }'; j++) {
      const line = lines[j];
      // Top-level ops of the function body only (nested regions are deeper).
      if (!/^ {4}\S/.test(line)) {
        continue;
      }
      const rm = /^ {4}(%[\w]+)(?::(\d+))?\s*=\s*([\w.]+)/.exec(line);
      const om = rm ? undefined : /^ {4}([\w.]+)/.exec(line);
      const opName = rm ? rm[3] : om?.[1] ?? '';
      if (!opName || /^(util|func)\.return$/.test(opName)) {
        continue;
      }
      const rhs = rm ? line.slice(line.indexOf('=') + 1) : line;
      const types = resultTypes(line);
      const count = rm?.[2] ? Number(rm[2]) : rm ? 1 : 0;
      const results: FlowValue[] = [];
      for (let k = 0; k < count; k++) {
        const name = count > 1 ? `${rm![1]}#${k}` : rm![1];
        const type = types[k] ?? types[0] ?? '';
        results.push({ name, type, bytes: valueBytes(type) });
      }

      let node: FlowNode | undefined;
      const id = g.nodes.length;
      if (opName === 'hal.tensor.import') {
        const label = /"([^"]+)"/.exec(rhs)?.[1] ?? 'input';
        node = { id, kind: 'input', label, results, line: j + 1 };
      } else if (opName === 'hal.tensor.export') {
        const label = /"([^"]+)"/.exec(rhs)?.[1] ?? 'output';
        const t = cleanType(/:\s*(tensor<[^>]*>)/.exec(rhs)?.[1] ?? '');
        node = { id, kind: 'output', label, results: [], line: j + 1 };
        // Show the exported tensor as the output's value.
        if (t) {
          node.results = [{ name: label, type: t, bytes: valueBytes(t) }];
        }
      } else if (opName === 'flow.dispatch') {
        const dm = /flow\.dispatch\s+@([\w$.-]+)::@([\w$.-]+)/.exec(rhs);
        const entry = dm?.[2] ?? '?';
        const ops = summaries.get(entry);
        node = {
          id, kind: 'dispatch', entry, executable: dm?.[1], ops,
          label: `${shortName(entry, dm?.[1])}${ops ? `: ${ops.join(' + ')}` : ''}`,
          results, line: j + 1,
        };
      } else if (results.some((r) => r.type.startsWith('tensor<'))) {
        node = { id, kind: 'op', label: opName, results, line: j + 1 };
      }
      if (!node) {
        continue;
      }
      // Operands: SSA uses after the op name that some earlier node produced.
      const used = new Set<string>();
      for (const u of rhs.matchAll(/%[\w]+(?:#\d+)?/g)) {
        const p = producer.get(u[0]);
        if (p && !used.has(u[0])) {
          used.add(u[0]);
          g.edges.push({ from: p.node, to: id, value: p.value });
        }
      }
      g.nodes.push(node);
      if (node.kind !== 'output') {
        for (const r of results) {
          producer.set(r.name, { node: id, value: r });
        }
      }
    }
    if (g.nodes.some((n) => n.kind === 'dispatch')) {
      graphs.push(g);
    }
  }
  return graphs;
}

/**
 * Finds the pass dump holding the last flow-level program: the latest
 * root-scope dump (up to the stream phase) that still contains flow.dispatch.
 */
export async function findFlowDump(
  passes: PassNode[],
  readText: (file: string) => Promise<string | undefined>,
): Promise<{ file: string; text: string } | undefined> {
  const phases = new Set(['dispatch-creation', 'flow', 'stream']);
  const roots = passes.filter((p) => p.scope.length === 1 && phases.has(p.phase) && !p.container);
  for (let i = roots.length - 1; i >= 0; i--) {
    const text = await readText(roots[i].filePath);
    if (text && /flow\.dispatch @/.test(text)) {
      return { file: roots[i].filePath, text };
    }
  }
  return undefined;
}
