import { describe, expect, it } from 'vitest';
import { targetKind, BUILTIN_TARGETS } from '../../src/compiler/flags';
import {
  BACKEND_OPTIONS, buildInfoFromCache, diskNeededBytes, diskVerdict, freeDiskBytes, parseCMakeCache, rebuildCommand,
} from '../../src/compiler/rebuild';

const CACHE = `# This is the CMakeCache file.
//Enables the 'cuda' compiler target backend
IREE_TARGET_BACKEND_CUDA:BOOL=OFF
IREE_TARGET_BACKEND_LLVM_CPU:BOOL=ON
IREE_TARGET_BACKEND_METAL_SPIRV:BOOL=OFF
IREE_TARGET_BACKEND_VULKAN_SPIRV:BOOL=ON
IREE_CMAKE_PLUGIN_PATHS:STRING=/src/LLForge
CMAKE_HOME_DIRECTORY:INTERNAL=/src/iree
CMAKE_BUILD_TYPE:STRING=RelWithDebInfo
`;
const GB = 1024 ** 3;
const opt = (b: string) => BACKEND_OPTIONS.find((o) => o.backend === b)!;

describe('rebuild helper', () => {
  it('reads the backend switches from CMakeCache.txt', () => {
    const info = buildInfoFromCache('/build', parseCMakeCache(CACHE))!;
    expect(info.sourceDir).toBe('/src/iree');
    expect(info.enabled.get('llvm-cpu')).toBe(true);
    expect(info.enabled.get('metal-spirv')).toBe(false);
    expect(info.enabled.has('rocm')).toBe(false);
  });

  it('reconfigures the same build (keeping plugins) and rebuilds the tools', () => {
    const info = buildInfoFromCache('/build dir', parseCMakeCache(CACHE))!;
    const metal = BACKEND_OPTIONS.find((b) => b.backend === 'metal-spirv')!;
    expect(rebuildCommand(info, metal)).toBe(
      "cmake -S /src/iree -B '/build dir' -DIREE_TARGET_BACKEND_METAL_SPIRV=ON && cmake --build '/build dir' --target iree-compile iree-opt",
    );
  });

  it('removing turns the switch OFF and cleans dead build files (Ninja only)', () => {
    const info = buildInfoFromCache('/b', parseCMakeCache(CACHE + 'CMAKE_GENERATOR:INTERNAL=Ninja\n'))!;
    expect(rebuildCommand(info, opt('vmvx'), false)).toBe(
      'cmake -S /src/iree -B /b -DIREE_TARGET_BACKEND_VMVX=OFF && cmake --build /b --target iree-compile iree-opt && ninja -C /b -t cleandead',
    );
    expect(rebuildCommand({ ...info, generator: 'Unix Makefiles' }, opt('vmvx'), false)).not.toContain('cleandead');
    expect(rebuildCommand(info, opt('metal-spirv'), true)).not.toContain('cleandead');
    expect(opt('llvm-cpu').removeWarning).toMatch(/constants at compile time/);
  });

  it('estimates disk by build type; removal only needs relink room', () => {
    const debug = buildInfoFromCache('/b', parseCMakeCache(CACHE))!;
    const release = { ...debug, buildType: 'Release' };
    expect(diskNeededBytes(debug, opt('cuda'), true)).toBe(10 * GB);
    expect(diskNeededBytes(release, opt('cuda'), true)).toBe(5 * GB);
    expect(diskNeededBytes(debug, opt('cuda'), false)).toBe(2 * GB);
  });

  it('judges free space', () => {
    expect(diskVerdict(26 * GB, 10 * GB)).toMatchObject({ status: 'ok', message: 'Disk space OK: 26 GB free; this needs about 10 GB.' });
    expect(diskVerdict(12 * GB, 10 * GB).status).toBe('tight');
    expect(diskVerdict(4 * GB, 10 * GB)).toMatchObject({ status: 'insufficient', message: 'Not enough disk space: 4.0 GB free; this needs about 10 GB. Free up 6.0 GB or more first.' });
  });

  it('reads real free space', async () => {
    expect(await freeDiskBytes('/')).toBeGreaterThan(0);
    expect(await freeDiskBytes('/definitely/not/here')).toBeUndefined();
  });

  it('needs a source dir', () => {
    expect(buildInfoFromCache('/b', parseCMakeCache('FOO:BOOL=ON'))).toBeUndefined();
  });
});

describe('target icons', () => {
  it('uses one processor icon for every target, with a hardware label', () => {
    expect(BUILTIN_TARGETS.map((t) => targetKind(t).kind)).toEqual(['CPU', 'NVIDIA GPU', 'AMD GPU', 'GPU (Vulkan)', 'Apple GPU (Metal)']);
    expect(new Set(BUILTIN_TARGETS.map((t) => targetKind(t).icon))).toEqual(new Set(['chip']));
    expect(targetKind({ id: 'x', label: 'dummy', backend: 'dummy', deviceFlags: [], extraFlags: [] })).toEqual({ icon: 'chip', kind: 'Plugin / custom' });
  });
});
