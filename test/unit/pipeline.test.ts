import { mkdtempSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { tmpdir } from 'os';
import * as path from 'path';
import { describe, expect, it } from 'vitest';
import { gcDumpDirs, indexDump, resolveOutputRoot } from '../../src/model/artifacts';
import {
  buildPassNodes, buildReproCommand, classifyPass, compareOrdinalPaths, formatScopeSegment, groupPasses,
  parseDumpHeader, parsePassFileName, prepareRepro, previousInScope, sanitizePipelineText, spliceIntoModule,
  wrapInExecutable,
} from '../../src/model/pipeline';
import { parseTiming } from '../../src/model/timing';
import { dump } from './helpers';

describe('file name / header parsing', () => {
  it('parses hierarchical ordinals', () => {
    expect(parsePassFileName('157_1_2_6_14_iree-codegen-tile-and-distribute-to-workgroups-using-forall-op.mlir')).toEqual({
      ordinalPath: [157, 1, 2, 6, 14], passName: 'iree-codegen-tile-and-distribute-to-workgroups-using-forall-op',
    });
    expect(parsePassFileName('0003_Canonicalizer.mlir')).toEqual({ ordinalPath: [3], passName: 'Canonicalizer' });
    expect(parsePassFileName('notes.mlir')).toBeUndefined();
    expect(parsePassFileName('7_inline.txt')).toBeUndefined();
  });

  it('parses dump headers, old and new style', () => {
    expect(parseDumpHeader('// -----// IR Dump After CSEPass: cse //----- //')).toMatchObject({ className: 'CSEPass', pipelineText: 'cse' });
    expect(parseDumpHeader('// -----// IR Dump After InlinerPass: inline{default-pipeline=canonicalize max-iterations=4 } //----- //'))
      .toMatchObject({ className: 'InlinerPass', pipelineText: 'inline{default-pipeline=canonicalize max-iterations=4 }' });
    expect(parseDumpHeader('// -----// IR Dump After mlir::iree_compiler::detail::OpPipelineAdaptorPass: iree-op-pipeline-adaptor //----- //'))
      .toMatchObject({ className: 'mlir::iree_compiler::detail::OpPipelineAdaptorPass' });
    expect(parseDumpHeader('// -----// IR Dump After Canonicalizer (canonicalize) //----- //'))
      .toMatchObject({ className: 'Canonicalizer', pipelineText: 'canonicalize' });
    expect(parseDumpHeader('module {')).toBeUndefined();
  });

  it('orders nested passes before the parent that ran them', () => {
    expect(compareOrdinalPaths([7, 2], [7])).toBeLessThan(0);
    expect(compareOrdinalPaths([6, 1], [7, 2])).toBeLessThan(0);
    expect(compareOrdinalPaths([157, 1, 2, 6, 14], [157, 1, 2, 11, 66])).toBeLessThan(0);
  });

  it('classifies passes into phases', () => {
    expect(classifyPass('iree-global-opt-raise-special-ops')).toBe('global-optimization');
    expect(classifyPass('iree-llvmcpu-select-lowering-strategy')).toBe('executable-configurations');
    expect(classifyPass('iree-codegen-tile-and-distribute-to-workgroups-using-forall-op')).toBe('executable-targets');
    expect(classifyPass('iree-flow-canonicalize')).toBeUndefined();
    expect(classifyPass('cse')).toBeUndefined();
  });

  it('formats scope segments', () => {
    expect(formatScopeSegment('hal_executable_variant_embedded_elf_arm_64')).toBe('hal.executable.variant @embedded_elf_arm_64');
    expect(formatScopeSegment('func_func_matmul_dispatch_0_matmul_64x64x64_f32')).toBe('func.func @matmul_dispatch_0_matmul_64x64x64_f32');
    expect(formatScopeSegment('builtin_module_no-symbol-name')).toBe('builtin.module');
  });
});

describe('real dump: matmul on llvm-cpu', async () => {
  const idx = await indexDump(dump('matmul-llvm-cpu'));

  it('indexes every pass file', () => {
    expect(idx.passes.length).toBeGreaterThan(500);
    expect(idx.problems).toEqual([]);
    expect(idx.passes.every((p, i) => p.ordinal === i)).toBe(true);
    expect(idx.passes[0].passName).toBe('iree-auto-input-conversion');
  });

  it('groups into phases in pipeline order', () => {
    const phases = [...new Set(idx.passes.map((p) => p.phase))];
    expect(phases).toEqual([
      'input', 'abi', 'global-optimization', 'dispatch-creation', 'flow', 'stream',
      'executable-sources', 'executable-configurations', 'executable-targets', 'hal', 'vm',
    ]);
    const cfg = idx.passes.find((p) => p.passName === 'iree-llvmcpu-select-lowering-strategy');
    expect(cfg?.phase).toBe('executable-configurations');
    const tile = idx.passes.find((p) => p.passName.startsWith('iree-codegen-tile-and-distribute-to-workgroups'));
    expect(tile?.phase).toBe('executable-targets');
  });

  it('hiding unchanged passes cuts the node count by a large factor', () => {
    const count = (gs: ReturnType<typeof groupPasses>) =>
      gs.reduce((a, g) => a + g.items.reduce((b, i) => b + ('kind' in i ? i.passes.length : 1), 0), 0);
    const all = count(groupPasses(idx.passes, true));
    const changed = count(groupPasses(idx.passes, false));
    expect(all).toBe(idx.passes.length);
    // Measured on this dump: 743 -> 258 (2.9x). Pipeline-adaptor dumps are
    // hidden with the unchanged passes since they only repeat nested changes.
    expect(changed * 2.5).toBeLessThan(all);
    expect(idx.passes.filter((p) => p.container).every((p) => p.ordinalPath.length < 5)).toBe(true);
  });

  it('diff-with-previous stays in scope and shows tiling appear', () => {
    const tile = idx.passes.find((p) => p.passName.startsWith('iree-codegen-tile-and-distribute-to-workgroups'))!;
    expect(tile.changed).toBe(true);
    const prev = previousInScope(idx.passes, tile)!;
    expect(prev.scope).toEqual(tile.scope);
    expect(readFileSync(prev.filePath, 'utf8')).not.toMatch(/scf\.forall/);
    expect(readFileSync(tile.filePath, 'utf8')).toMatch(/scf\.forall/);
  });

  it('attaches wall times from --mlir-timing', () => {
    const instances = new Set(idx.passes.map((p) => p.ordinalPath.join('_'))).size;
    expect(idx.timingsMatched).toBeGreaterThan(instances * 0.6);
    const top = idx.passes.filter((p) => p.ordinalPath.length === 1);
    expect(top.filter((p) => p.wallMs !== undefined).length).toBeGreaterThan(top.length * 0.75);
    expect(idx.passes.find((p) => p.passName === 'iree-auto-input-conversion')?.wallMs).toBeGreaterThanOrEqual(0);
  });

  const readText = (f: string) => Promise.resolve(readFileSync(f, 'utf8'));
  const plan = (name: string, pred: (p: (typeof idx.passes)[0]) => boolean = () => true) =>
    prepareRepro(idx.passes, idx.passes.find((p) => p.passName === name && pred(p))!, 'iree-opt', readText, (f) => `/r/${f}`, '/in.mlir');

  it('repro for a function-scope pass outside executables nests under the op', async () => {
    const cse = idx.passes.find((p) => p.passName === 'cse' && p.scope.length === 2 && p.scope[1].startsWith('util_func_'))!;
    const r = await prepareRepro(idx.passes, cse, 'iree-opt', readText, (f) => `/r/${f}`);
    expect(r.command).toMatch(/^iree-opt \/r\/\S+\.input\.mlir '--pass-pipeline=builtin\.module\(util\.func\(cse\)\)'$/);
    // Spliced back into the module so module-level symbols (globals, callees) resolve.
    const text = r.wrappedInput!.text;
    expect(text).toMatch(/^module\b/m);
    expect(text).toMatch(/^ {2}util\.func public @matmul\(/m);
    expect(text.match(/^ {2}util\.func\b/gm)!.length).toBeGreaterThan(1);
  });

  it('repro for a pass inside a variant rebuilds the executable around it', async () => {
    const r = await plan('iree-llvmcpu-select-lowering-strategy');
    expect(r.command).toContain(`'--pass-pipeline=builtin.module(hal.executable(hal.executable.variant(builtin.module(iree-llvmcpu-select-lowering-strategy))))'`);
    const text = r.wrappedInput!.text;
    expect(text.split('\n')[0]).toBe('hal.executable private @matmul_dispatch_0 {');
    expect(text).toMatch(/^ {2}hal\.executable\.variant public @embedded_elf_arm_64 target\(/m);
    expect(text).toMatch(/^ {4}builtin\.module \{$/m); // bare `module` spelled out when nested
  });

  it('repro for the first pass in a function scope uses the enclosing dump', async () => {
    const r = await plan('iree-codegen-type-propagation');
    expect(r.problem).toBeUndefined();
    expect(r.command).toContain('builtin.module(hal.executable(hal.executable.variant(builtin.module(func.func(iree-codegen-type-propagation)))))');
  });

  it('repro for the very first pass uses the original input', async () => {
    expect((await plan('iree-auto-input-conversion')).command).toBe(`iree-opt /in.mlir '--pass-pipeline=builtin.module(iree-auto-input-conversion)'`);
  });

  it('refuses to repro pipeline adaptors and strips pointer options', async () => {
    expect((await plan('iree-op-pipeline-adaptor')).problem).toMatch(/internal wrapper/);
    expect((await plan('iree-hal-configure-executables')).command).toContain('hal.executable(iree-hal-configure-executables)');
    expect(sanitizePipelineText('iree-hal-serialize-target-executables{debug-level=2 target=llvm-cpu target-registry=1}'))
      .toBe('iree-hal-serialize-target-executables{debug-level=2 target=llvm-cpu}');
    expect(sanitizePipelineText('iree-hal-translate-all-executables{target-registry=1}')).toBe('iree-hal-translate-all-executables');
  });

  it('finds the dispatch and its config', () => {
    expect(idx.dispatches).toHaveLength(1);
    const d = idx.dispatches[0];
    expect(d.info.name).toBe('matmul_dispatch_0_matmul_64x64x64_f32');
    expect(d.sourceFile).toMatch(/sources\/module_matmul_dispatch_0\.mlir$/);
    expect(d.configFile).toMatch(/configs\/configured_module_matmul_dispatch_0\.mlir$/);
    expect(d.info.config?.form).toBe('cpu');
    expect(d.info.sharedMemoryBudgetBytes).toBe(65536);
  });
});

describe('degrades gracefully', () => {
  it('handles a truncated / empty dump dir', async () => {
    const dir = mkdtempSync(path.join(tmpdir(), 'iree-explorer-'));
    const idx = await indexDump(dir);
    expect(idx.passes).toEqual([]);
    expect(idx.dispatches).toEqual([]);
    expect(idx.problems.length).toBeGreaterThan(0);
  });

  it('handles unparseable file names and garbage content', async () => {
    const dir = mkdtempSync(path.join(tmpdir(), 'iree-explorer-'));
    mkdirSync(path.join(dir, 'ir', 'x'), { recursive: true });
    mkdirSync(path.join(dir, 'configs'), { recursive: true });
    writeFileSync(path.join(dir, 'ir', 'x', 'weird.mlir'), 'not mlir');
    writeFileSync(path.join(dir, 'ir', 'x', '1_cse.mlir'), Buffer.from([0, 1, 2, 255]));
    writeFileSync(
      path.join(dir, 'configs', 'configured_module_x.mlir'),
      'func.func @f() { linalg.matmul {lowering_config = #iree_codegen.lowering_config<tile_sizes = [[1, 2>} ins(',
    );
    writeFileSync(path.join(dir, 'stderr.log'), '... Execution time report ...\ngarbage');
    const idx = await indexDump(dir);
    expect(idx.passes.map((p) => p.passName)).toEqual(['cse', 'weird']);
    expect(idx.dispatches).toHaveLength(1);
    expect(idx.dispatches[0].info.config).toBeUndefined();
  });

  it('repro helpers return undefined on shapes they do not understand', () => {
    expect(wrapInExecutable('garbage', 'module {\n}', 'builtin.module', 'x')).toBeUndefined();
    expect(wrapInExecutable(undefined, '', 'hal.executable.variant', 'x')).toBeUndefined();
    expect(spliceIntoModule('func.func @f() {\n}', 'util.func @g() {\n}', 'util_func_g')).toBeUndefined();
    expect(spliceIntoModule('module {\n}', 'util.func @g() {\n}', 'util_func_g')).toBeUndefined();
    expect(buildReproCommand({ optPath: 'o', prevFile: 'p', node: buildPassNodes([])[0] ?? {
      ordinal: 0, ordinalPath: [0], passName: 'x', scope: [], filePath: '', sizeBytes: 0, changed: true, container: false, hash: '', phase: '',
    }, anchorOp: 'hal.executable.variant' })).toMatch(/^# NOTE/);
  });

  it('resolves the output folder setting', () => {
    expect(resolveOutputRoot('${inputDir}/iree-out', '/p/models/a.mlir', '/ws')).toBe('/p/models/iree-out');
    expect(resolveOutputRoot('${workspaceFolder}/.iree-explorer', '/p/a.mlir', '/ws')).toBe('/ws/.iree-explorer');
    expect(resolveOutputRoot('out', '/p/a.mlir', '/ws')).toBe('/ws/out');
    expect(resolveOutputRoot('out', '/p/a.mlir')).toBe('/p/out');
    expect(resolveOutputRoot('/abs/dir', '/p/a.mlir', '/ws')).toBe('/abs/dir');
    expect(resolveOutputRoot('', '/p/a.mlir', '/ws')).toBeUndefined();
    expect(resolveOutputRoot('extension-storage', '/p/a.mlir', '/ws')).toBeUndefined();
    expect(resolveOutputRoot('${workspaceFolder}/x', '/p/a.mlir')).toBeUndefined();
  });

  it('cleanup only deletes this extension\'s dump folders', async () => {
    const root = mkdtempSync(path.join(tmpdir(), 'iree-explorer-gc-'));
    const mk = (name: string, meta: boolean) => {
      mkdirSync(path.join(root, name));
      if (meta) {
        writeFileSync(path.join(root, name, 'meta.json'), '{}');
      }
    };
    mk('20260101-000000-000', true);
    mk('20260102-000000-000', true);
    mk('20260103-000000-000', true);
    mk('20260104-000000-000', false); // timestamp-named but not ours
    mk('my-notes', false);
    const removed = await gcDumpDirs(root, 1);
    expect(removed.map((d) => path.basename(d)).sort()).toEqual(['20260101-000000-000', '20260102-000000-000']);
    const { readdirSync } = await import('fs');
    expect(readdirSync(root).sort()).toEqual(['20260103-000000-000', '20260104-000000-000', 'my-notes']);
  });

  it('buildPassNodes on empty input', () => {
    expect(buildPassNodes([])).toEqual([]);
    expect(parseTiming('')).toBeUndefined();
  });
});
