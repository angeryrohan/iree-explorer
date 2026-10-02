// Parses MLIR diagnostics from iree-compile stderr. Pure.

import { Diagnostic } from '../model/types';

const DIAG_RE = /^(.+?):(\d+):(\d+): (error|warning|note|remark): (.*)$/;

export function parseDiagnostics(stderr: string): Diagnostic[] {
  const out: Diagnostic[] = [];
  for (const line of stderr.split(/\r?\n/)) {
    const m = DIAG_RE.exec(line);
    if (!m) {
      continue;
    }
    const file = m[1];
    // `<unknown>` / `loc(...)`-style pseudo files cannot be mapped to the editor.
    if (file.startsWith('<') || file.startsWith('loc(')) {
      continue;
    }
    out.push({
      file,
      line: Number(m[2]),
      col: Number(m[3]),
      severity: m[4] as Diagnostic['severity'],
      message: m[5],
    });
  }
  return out;
}
