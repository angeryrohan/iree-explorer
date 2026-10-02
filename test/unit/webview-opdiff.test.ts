// @vitest-environment jsdom
import { beforeAll, describe, expect, it } from 'vitest';
import { diffOps, OpDiffView } from '../../src/model/opdiff';

const posted: unknown[] = [];
const send = (data: unknown) => window.dispatchEvent(new MessageEvent('message', { data }));
const app = () => document.getElementById('app')!;

const before = [
  '%0 = arith.addf %a, %a : f32',
  '%1 = arith.mulf %0, %0 : f32',
  '%2 = arith.mulf %1, %1 : f32',
].join('\n');
const after = [
  '%0 = arith.addf %a, %a fastmath<fast> : f32',
  '%1 = math.sqrt %0 : f32',
].join('\n');
const view = (b: string, a: string): OpDiffView => ({
  before: { label: '#3 canonicalize', file: '/a.mlir' },
  after: { label: '#4 cse', file: '/b.mlir' },
  diff: diffOps(b, a),
});

beforeAll(async () => {
  document.body.innerHTML = '<div id="app"></div>';
  (globalThis as unknown as { acquireVsCodeApi: () => unknown }).acquireVsCodeApi = () => ({ postMessage: (m: unknown) => posted.push(m) });
  await import('../../src/webview/opdiff/main');
});

describe('op changes webview', () => {
  it('says it is ready', () => {
    expect(posted[0]).toEqual({ type: 'ready' });
  });

  it('renders the summary, count table and changed ops', () => {
    send({ type: 'render', view: view(before, after) });
    expect(app().querySelector('.facts')?.textContent).toBe('3 → 2 ops  ·  1 added  ·  2 removed  ·  1 modified');
    const rows = [...app().querySelectorAll('tr.count-row')].map((r) => [...r.querySelectorAll('td')].map((td) => td.textContent));
    expect(rows).toEqual([
      ['arith.mulf', '2', '0', '−2', '–'],
      ['math.sqrt', '0', '1', '+1', '–'],
      ['arith.addf', '1', '1', '0', '1'],
    ]);
    expect([...app().querySelectorAll('.change')].map((c) => c.className)).toEqual([
      'change modified', 'change removed', 'change removed', 'change added',
    ]);
  });

  it('filters by op name when an op is clicked', () => {
    (app().querySelector('tr.count-row button.op') as HTMLElement).click();
    expect(app().querySelectorAll('tr.count-row')).toHaveLength(1);
    expect([...app().querySelectorAll('.change .op')].map((e) => e.textContent)).toEqual(['arith.mulf', 'arith.mulf']);
  });

  it('hides a change kind when its box is unticked', () => {
    send({ type: 'render', view: view(before, after) });
    const box = app().querySelector('label.toggle.removed input') as HTMLInputElement;
    box.click();
    expect(app().querySelectorAll('.change.removed')).toHaveLength(0);
    expect(app().querySelectorAll('.change')).toHaveLength(2);
  });

  it('opens the dump at a line and the text diff', () => {
    send({ type: 'render', view: view(before, after) });
    (app().querySelector('.change.added button.line') as HTMLElement).click();
    expect(posted.at(-1)).toEqual({ type: 'openLine', side: 'after', line: 2 });
    (app().querySelector('header button.link') as HTMLElement).click();
    expect(posted.at(-1)).toEqual({ type: 'openTextDiff' });
  });

  it('explains when no ops changed', () => {
    send({ type: 'render', view: view(before, before.replace(/%0/g, '%v')) });
    expect(app().textContent).toMatch(/No op-level changes/);
    expect(app().querySelector('table')).toBeNull();
  });
});
