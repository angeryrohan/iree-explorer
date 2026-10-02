// ArtifactIndex: walks a compile dump directory and builds the in-memory model
// (pass nodes, dispatches). Node fs only, no VS Code imports; all IO async.

import { createHash } from 'crypto';
import { promises as fs, watch, FSWatcher } from 'fs';
import * as path from 'path';
import { parseDispatchFile } from './lowering';
import { buildPassNodes } from './pipeline';
import { attachTimings, parseTiming } from './timing';
import { DispatchInfo, PassFileEntry, PassNode } from './types';

export interface DumpMeta {
  inputPath: string;
  targetId: string;
  targetLabel: string;
  args: string[];
  compilerPath: string;
  startedAt: number;
  durationMs?: number;
  exitCode?: number | null;
  cancelled?: boolean;
  outputPath: string;
  sharedMemoryBudgetBytes?: number;
}

export interface DispatchArtifact {
  info: DispatchInfo;
  /** Source listing (--iree-hal-dump-executable-sources-to), if dumped. */
  sourceFile?: string;
  /** Configured listing (--iree-hal-dump-executable-configurations-to), if dumped. */
  configFile?: string;
  /** Binaries / intermediates whose name mentions the executable. */
  binaryFiles: string[];
  intermediateFiles: string[];
}

export interface IndexedDump {
  dir: string;
  meta?: DumpMeta;
  passes: PassNode[];
  dispatches: DispatchArtifact[];
  timingsMatched: number;
  problems: string[];
}

export const META_FILE = 'meta.json';
export const STDERR_FILE = 'stderr.log';

async function exists(p: string): Promise<boolean> {
  try {
    await fs.access(p);
    return true;
  } catch {
    return false;
  }
}

async function walk(root: string, rel = ''): Promise<string[]> {
  let entries: import('fs').Dirent[];
  try {
    entries = await fs.readdir(path.join(root, rel), { withFileTypes: true });
  } catch {
    return [];
  }
  const out: string[] = [];
  for (const e of entries) {
    const r = rel ? `${rel}/${e.name}` : e.name;
    if (e.isDirectory()) {
      out.push(...(await walk(root, r)));
    } else if (e.isFile()) {
      out.push(r);
    }
  }
  return out;
}

async function mapLimit<T, R>(items: T[], limit: number, fn: (t: T) => Promise<R>): Promise<R[]> {
  const out: R[] = new Array(items.length);
  let next = 0;
  const workers = Array.from({ length: Math.min(limit, items.length) }, async () => {
    while (next < items.length) {
      const i = next++;
      out[i] = await fn(items[i]);
    }
  });
  await Promise.all(workers);
  return out;
}

async function readPassEntry(root: string, rel: string): Promise<PassFileEntry | undefined> {
  const abs = path.join(root, rel);
  try {
    const [stat, buf] = await Promise.all([fs.stat(abs), fs.readFile(abs)]);
    // Hash the IR body only: the header names the pass, which always differs.
    const nl = buf.indexOf(0x0a);
    const header = nl >= 0 ? buf.subarray(0, nl).toString('utf8') : buf.toString('utf8');
    const body = header.startsWith('// -----//') && nl >= 0 ? buf.subarray(nl + 1) : buf;
    return {
      relPath: rel,
      absPath: abs,
      sizeBytes: stat.size,
      mtimeMs: stat.mtimeMs,
      hash: createHash('sha1').update(body).digest('hex'),
      header,
    };
  } catch {
    return undefined;
  }
}

export async function indexDump(dir: string, sharedMemoryBudgetBytes?: number): Promise<IndexedDump> {
  const problems: string[] = [];
  let meta: DumpMeta | undefined;
  try {
    meta = JSON.parse(await fs.readFile(path.join(dir, META_FILE), 'utf8')) as DumpMeta;
  } catch {
    problems.push('meta.json missing or unreadable');
  }

  // --- passes ---
  const irRoot = path.join(dir, 'ir');
  const irFiles = (await walk(irRoot)).filter((f) => f.endsWith('.mlir'));
  const entries = (await mapLimit(irFiles, 16, (f) => readPassEntry(irRoot, f))).filter(
    (e): e is PassFileEntry => e !== undefined,
  );
  if (irFiles.length === 0) {
    problems.push('No pass dumps found (ir/ is empty or missing).');
  }
  const passes = buildPassNodes(entries);

  let timingsMatched = 0;
  try {
    const stderr = await fs.readFile(path.join(dir, STDERR_FILE), 'utf8');
    const rows = parseTiming(stderr);
    if (rows) {
      timingsMatched = attachTimings(passes, rows);
    }
  } catch {
    // no stderr log: no timings
  }

  // --- dispatches ---
  const budget = sharedMemoryBudgetBytes ?? meta?.sharedMemoryBudgetBytes;
  const dispatches = await indexDispatches(dir, budget, problems);
  return { dir, meta, passes, dispatches, timingsMatched, problems };
}

async function listFiles(d: string): Promise<string[]> {
  if (!(await exists(d))) {
    return [];
  }
  return (await walk(d)).map((f) => path.join(d, f)).sort();
}

async function indexDispatches(dir: string, budget: number | undefined, problems: string[]): Promise<DispatchArtifact[]> {
  const sources = (await listFiles(path.join(dir, 'sources'))).filter((f) => f.endsWith('.mlir'));
  const configs = (await listFiles(path.join(dir, 'configs'))).filter((f) => f.endsWith('.mlir'));
  const binaries = await listFiles(path.join(dir, 'binaries'));
  const intermediates = await listFiles(path.join(dir, 'intermediates'));

  // Sources: module_<exe>.mlir; configs: configured_module_<exe>.mlir.
  const keyOf = (f: string) => path.basename(f, '.mlir').replace(/^configured_/, '').replace(/^module_/, '');
  const byKey = new Map<string, { source?: string; config?: string }>();
  for (const f of sources) {
    byKey.set(keyOf(f), { ...byKey.get(keyOf(f)), source: f });
  }
  for (const f of configs) {
    byKey.set(keyOf(f), { ...byKey.get(keyOf(f)), config: f });
  }

  const out: DispatchArtifact[] = [];
  for (const [key, files] of [...byKey.entries()].sort((a, b) => a[0].localeCompare(b[0]))) {
    const primary = files.config ?? files.source;
    if (!primary) {
      continue;
    }
    let text: string;
    try {
      text = await fs.readFile(primary, 'utf8');
    } catch {
      problems.push(`Could not read ${primary}`);
      continue;
    }
    const infos = parseDispatchFile(text, primary);
    if (infos.length === 0) {
      problems.push(`No func.func found in ${path.basename(primary)}`);
    }
    const matchKey = (f: string) => path.basename(f).includes(key);
    for (const info of infos) {
      info.sharedMemoryBudgetBytes = budget;
      out.push({
        info,
        sourceFile: files.source,
        configFile: files.config,
        binaryFiles: binaries.filter(matchKey),
        intermediateFiles: intermediates.filter(matchKey),
      });
    }
  }
  return out;
}

/** Lists dump dirs under `root` newest first (by name: they're timestamps). */
export async function listDumpDirs(root: string): Promise<string[]> {
  try {
    const entries = await fs.readdir(root, { withFileTypes: true });
    return entries
      .filter((e) => e.isDirectory() && /^\d{8}-\d{6}/.test(e.name))
      .map((e) => path.join(root, e.name))
      .sort()
      .reverse();
  } catch {
    return [];
  }
}

/**
 * Removes all but the newest `keep` dump dirs (never `protect`). Only
 * directories this extension created are touched: timestamp-named AND
 * containing meta.json, so a user-chosen output folder is safe.
 */
export async function gcDumpDirs(root: string, keep: number, protect?: string): Promise<string[]> {
  const dirs = [];
  for (const d of await listDumpDirs(root)) {
    if (await exists(path.join(d, META_FILE))) {
      dirs.push(d);
    }
  }
  const doomed = dirs.slice(Math.max(0, keep)).filter((d) => d !== protect);
  for (const d of doomed) {
    try {
      await fs.rm(d, { recursive: true, force: true });
    } catch {
      // best effort
    }
  }
  return doomed;
}

export const EXTENSION_STORAGE = 'extension-storage';

/**
 * Resolves the ireeExplorer.outputDir setting to an absolute directory.
 * Supports ${inputDir} and ${workspaceFolder}; relative paths resolve against
 * the workspace folder (else the input's folder). Returns undefined for
 * "unset" and for the extension-storage sentinel (callers use their default).
 */
export function resolveOutputRoot(setting: string, inputPath: string, workspaceFolder?: string): string | undefined {
  const s = setting.trim();
  if (s.length === 0 || s === EXTENSION_STORAGE) {
    return undefined;
  }
  const inputDir = path.dirname(inputPath);
  if (s.includes('${workspaceFolder}') && !workspaceFolder) {
    return undefined;
  }
  const expanded = s
    .replace(/\$\{inputDir\}/g, inputDir)
    .replace(/\$\{workspaceFolder\}/g, workspaceFolder ?? '')
    .replace(/^~(?=\/|$)/, process.env.HOME ?? '~');
  return path.isAbsolute(expanded) ? path.normalize(expanded) : path.resolve(workspaceFolder ?? inputDir, expanded);
}

export function newDumpDirName(now = new Date()): string {
  const p = (n: number, w = 2) => String(n).padStart(w, '0');
  return `${now.getFullYear()}${p(now.getMonth() + 1)}${p(now.getDate())}-${p(now.getHours())}${p(now.getMinutes())}${p(now.getSeconds())}-${p(now.getMilliseconds(), 3)}`;
}

/**
 * Recursive, debounced directory watch. Used while a compile is running so
 * the pipeline tree fills in live. Returns a disposer.
 */
export function watchDir(dir: string, onChange: () => void, debounceMs = 750): () => void {
  let timer: NodeJS.Timeout | undefined;
  let w: FSWatcher | undefined;
  try {
    w = watch(dir, { recursive: true }, () => {
      if (timer) {
        clearTimeout(timer);
      }
      timer = setTimeout(onChange, debounceMs);
    });
    w.on('error', () => undefined);
  } catch {
    // recursive watch unsupported on this platform: callers index at the end.
  }
  return () => {
    if (timer) {
      clearTimeout(timer);
    }
    w?.close();
  };
}
