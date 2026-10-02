// @vitest-environment jsdom
import { readFileSync } from 'fs';
import { beforeAll, describe, expect, it } from 'vitest';
import { parseFlowProgram } from '../../src/model/dataflow';
import { fixture } from './helpers';

const posted: unknown[] = [];
const send = (data: unknown) => window.dispatchEvent(new MessageEvent('message', { data }));
const app = () => document.getElementById('app')!;
let lanes: (e: Array<{ from: number; to: number }>) => number[];

beforeAll(async () => {
  document.body.innerHTML = '<div id="app"></div>';
  (globalThis as unknown as { acquireVsCodeApi: () => unknown }).acquireVsCodeApi = () => ({ postMessage: (m: unknown) => posted.push(m) });
  lanes = (await import('../../src/webview/dataflow/main')).assignLanes;
});

describe('data flow webview', () => {
  it('renders one box per step and one arc per tensor', () => {
    const program = parseFlowProgram(readFileSync(fixture('flow', 'mlp.flow.mlir'), 'utf8'), '/x.mlir');
    send({ type: 'render', program });
    expect(app().querySelectorAll('.node')).toHaveLength(6);
    expect(app().querySelectorAll('.node.dispatch')).toHaveLength(2);
    expect(app().querySelectorAll('path.arc')).toHaveLength(5);
    expect(app().querySelector('.facts')?.textContent).toBe('2 kernels  ·  3 inputs  ·  1 output  ·  largest intermediate 2 KiB');
    expect(app().querySelectorAll('.node')[3].querySelector('.node-detail')?.textContent)
      .toBe('reads 4×64 f32 (1 KiB), 64×128 f32 (32 KiB)  →  writes 4×128 f32 (2 KiB)');
  });

  it('clicking a kernel asks for its tiling', () => {
    (app().querySelector('.node.dispatch') as HTMLElement).click();
    expect(posted.at(-1)).toMatchObject({ type: 'openDispatch', entry: expect.stringMatching(/^mlp_dispatch_0_/) });
  });

  it('gives overlapping arcs different lanes', () => {
    expect(lanes([{ from: 0, to: 3 }, { from: 1, to: 3 }, { from: 3, to: 4 }, { from: 2, to: 4 }])).toEqual([0, 1, 0, 2]);
  });

  it('shows a message for an empty program', () => {
    send({ type: 'render', program: { file: 'x', graphs: [] } });
    expect(app().textContent).toMatch(/No flow-level program/);
  });
});
