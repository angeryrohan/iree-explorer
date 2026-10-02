// @vitest-environment jsdom
// Smoke tests for the tiling webview: it renders every fixture dispatch plus
// degenerate inputs without throwing, and speaks the postMessage protocol.

import { readdirSync, readFileSync } from 'fs';
import * as path from 'path';
import { beforeAll, describe, expect, it } from 'vitest';
import { parseDispatchFile } from '../../src/model/lowering';
import { DispatchInfo } from '../../src/model/types';
import { VERSION_DIR } from './helpers';

const posted: unknown[] = [];

function send(data: unknown): void {
  window.dispatchEvent(new MessageEvent('message', { data }));
}

const app = () => document.getElementById('app')!;

beforeAll(async () => {
  document.body.innerHTML = '<div id="app"></div>';
  (globalThis as unknown as { acquireVsCodeApi: () => unknown }).acquireVsCodeApi = () => ({
    postMessage: (m: unknown) => posted.push(m),
  });
  await import('../../src/webview/tiling/main');
});

function fixtureDispatches(): DispatchInfo[] {
  const out: DispatchInfo[] = [];
  for (const d of readdirSync(VERSION_DIR)) {
    const dir = path.join(VERSION_DIR, d, 'configs');
    for (const f of readdirSync(dir).filter((x) => x.endsWith('.mlir'))) {
      const file = path.join(dir, f);
      for (const info of parseDispatchFile(readFileSync(file, 'utf8'), file)) {
        out.push({ ...info, sharedMemoryBudgetBytes: 65536 });
      }
    }
  }
  return out;
}

describe('tiling webview', () => {
  it('announces readiness', () => {
    expect(posted[0]).toEqual({ type: 'ready' });
  });

  it('renders every fixture dispatch as SVG', () => {
    const all = fixtureDispatches();
    expect(all.length).toBe(6);
    for (const d of all) {
      send({ type: 'render', dispatch: d });
      expect(app().querySelector('h1')?.textContent).toBe(d.name);
      expect(app().querySelectorAll('svg.tiles rect.tile').length, d.name).toBeGreaterThan(0);
      expect(app().querySelector('.error')).toBeNull();
    }
  });

  it('flags ragged tiles in the drawing and the table', () => {
    send({
      type: 'render',
      dispatch: {
        name: 'ragged', opName: 'linalg.matmul', iterationDomain: [100, 64, 16], iteratorTypes: ['parallel', 'parallel', 'reduction'],
        config: { form: 'gpu', levels: [{ name: 'workgroup', sizes: [32, 64, 0] }], raw: '#iree_gpu.lowering_config<{workgroup = [32, 64, 0]}>' },
        sourceFile: '/x.mlir', sourceLine: 3, operands: [], opCount: 1,
      } satisfies DispatchInfo,
    });
    expect(app().querySelectorAll('rect.ragged')).toHaveLength(1);
    const warn = app().querySelector('.check.warn');
    expect(warn?.querySelector('.check-title')?.textContent).toBe('Some tiles are partial (remainder)');
    expect(warn?.querySelector('.check-detail')?.textContent).toMatch(/d0 = 100 split by 32 leaves a last tile of 4/);
    // Detailed numbers are still there, collapsed.
    expect(app().querySelector('details.numbers td.warn')?.textContent).toBe('d0');
  });

  it('falls back to a table when the iteration domain is unknown', () => {
    send({
      type: 'render',
      dispatch: {
        name: 'dyn', opName: 'linalg.generic', iterationDomain: [], iteratorTypes: [],
        config: { form: 'codegen', levels: [{ name: 'level 0', sizes: [8, 16] }], raw: 'x' },
        sourceFile: '/x.mlir', operands: [], opCount: 1,
      } satisfies DispatchInfo,
    });
    expect(app().querySelector('svg')).toBeNull();
    expect(app().querySelector('.check-title')?.textContent).toBe('Problem size unknown');
    expect(app().querySelectorAll('table td.mono')).toHaveLength(2);
  });

  it('opens the source via postMessage and shows errors / clears', () => {
    send({ type: 'render', dispatch: fixtureDispatches()[0] });
    (app().querySelector('button.link') as HTMLButtonElement).click();
    expect(posted[posted.length - 1]).toMatchObject({ type: 'openSource', line: expect.any(Number) });
    send({ type: 'error', message: 'boom' });
    expect(app().querySelector('.error')?.textContent).toBe('boom');
    send({ type: 'clear' });
    expect(app().textContent).toMatch(/Select a dispatch/);
  });

  it('does not interpret IR text as HTML', () => {
    send({
      type: 'render',
      dispatch: {
        name: '<img src=x onerror=alert(1)>', opName: 'linalg.matmul', iterationDomain: [], iteratorTypes: [],
        sourceFile: '/x', operands: [], opCount: 0,
      } satisfies DispatchInfo,
    });
    expect(app().querySelector('img')).toBeNull();
    expect(app().querySelector('h1')?.textContent).toBe('<img src=x onerror=alert(1)>');
  });

  it('survives malformed messages', () => {
    send(null);
    send({ type: 'render', dispatch: { name: 'x' } });
    send({ type: 'nonsense' });
    expect(app().querySelector('.error')?.textContent ?? '').toMatch(/Rendering failed|^$/);
  });
});
