// Shared interfaces. No VS Code imports in src/model/ — everything here must
// be usable from unit tests and from the webview bundle.

// ---------------------------------------------------------------------------
// Compiler capabilities / targets
// ---------------------------------------------------------------------------

export interface Capabilities {
  /** Raw first lines of `iree-compile --version`. */
  version: string;
  /** Every `--flag` name seen in --help / --help-hidden, without leading dashes. */
  knownFlags: Set<string>;
  /** `--iree-hal-target-device` exists (newer flag family). */
  hasTargetDevice: boolean;
  /** `--iree-hal-target-backends` exists (older flag family). */
  hasTargetBackends: boolean;
  /** Valid values for `--compile-to`. */
  compileToPhases: string[];
  /** True when compileToPhases came from the fallback list, not from help text. */
  compileToPhasesGuessed: boolean;
  /** `--iree-hal-list-target-backends` exists. */
  hasListTargetBackends: boolean;
  /** Backends reported by `--iree-hal-list-target-backends`, if run. */
  registeredBackends: string[];
}

export interface TargetProfile {
  id: string;
  label: string;
  /** Value for --iree-hal-target-device (newer flag family). */
  device?: string;
  /** Value for --iree-hal-target-backends (older flag family). */
  backend?: string;
  deviceFlags: string[];
  extraFlags: string[];
  /** Overrides ireeExplorer.sharedMemoryBudgetBytes for this target. */
  sharedMemoryBudgetBytes?: number;
  /** Where the profile came from; informational only. */
  source?: 'builtin' | 'probed' | 'custom';
}

export interface CompileRequest {
  inputPath: string;
  target: TargetProfile;
  /** Fresh directory under storageUri. */
  dumpDir: string;
  extraFlags: string[];
  /** Stops the pipeline early. */
  compileTo?: string;
}

export interface Diagnostic {
  file: string;
  line: number;   // 1-based
  col: number;    // 1-based
  severity: 'error' | 'warning' | 'note' | 'remark';
  message: string;
}

// ---------------------------------------------------------------------------
// Pass pipeline
// ---------------------------------------------------------------------------

export interface PassNode {
  /** Position in global execution order (0-based, after sorting). */
  ordinal: number;
  /** The numeric prefix components from the filename, e.g. [156, 0, 1, 5]. */
  ordinalPath: number[];
  passName: string;
  /** Pass class name from the dump header, e.g. "CSEPass", if present. */
  className?: string;
  /** Full pass pipeline element from the dump header, e.g. "inline{...}". */
  pipelineText?: string;
  /** Directory path segments relative to the tree root. */
  scope: string[];
  filePath: string;
  sizeBytes: number;
  /** Content differs from the previous sibling in the same scope. */
  changed: boolean;
  /**
   * The pass ran a nested pipeline (other dumps extend its ordinal path), so
   * its own dump only repeats its children's changes.
   */
  container: boolean;
  /** Content hash (hex). */
  hash: string;
  /** Wall time in ms from --mlir-timing, if it could be matched. */
  wallMs?: number;
  /** Inferred compile phase ("flow", "stream", ...). */
  phase: string;
}

export interface PassFileEntry {
  /** Path relative to the ir/ tree root, '/' separated. */
  relPath: string;
  absPath: string;
  sizeBytes: number;
  mtimeMs: number;
  hash: string;
  /** First line of the file (dump header), if read. */
  header?: string;
}

export interface TimingRow {
  depth: number;
  name: string;
  wallMs: number;
}

// ---------------------------------------------------------------------------
// Lowering config / dispatches
// ---------------------------------------------------------------------------

export interface TileLevel {
  /** "workgroup" | "thread" | "level 0" | ... */
  name: string;
  /** One entry per iteration dim, 0 = untiled. */
  sizes: number[];
}

export interface LoweringConfig {
  /**
   * codegen: #iree_codegen.lowering_config<tile_sizes = [[..], ..]>
   * gpu:     #iree_gpu.lowering_config<{workgroup = [..], ...}>
   * cpu:     #iree_cpu.lowering_config<distribution = [..], ...>
   */
  form: 'codegen' | 'gpu' | 'cpu';
  levels: TileLevel[];
  raw: string;
}

export interface TranslationInfo {
  pipeline?: string;
  workgroupSize?: number[];
  subgroupSize?: number;
  raw: string;
}

/**
 * How an operand dim is indexed: a plain iteration dim, or a convolution
 * window `out * stride + win * dilation`.
 */
export type DimRef = number | { out: number; win: number; stride: number; dilation: number };

export interface OperandInfo {
  /** "%3" etc. */
  name: string;
  role: 'input' | 'output';
  shape: number[];          // -1 for dynamic dims
  elementType: string;      // "f32", "i8", ...
  elementBytes?: number;
  /** For each operand dim, the iteration dim(s) it is indexed by; -1 if not recoverable. */
  dimMap?: DimRef[];
}

/** Hardware limits read from the executable target attribute in the IR. */
export interface TargetHardware {
  kind: 'gpu' | 'cpu' | 'unknown';
  /** "llvm-cpu", "vulkan-spirv", "rocm", ... */
  backend?: string;
  /** GPU arch ("rdna3", "gfx942") or CPU name ("apple-m1", "generic"). */
  arch?: string;
  maxWorkgroupMemoryBytes?: number;
  maxThreadsPerWorkgroup?: number;
  subgroupSizes?: number[];
  /** Compute units (WGPs / SMs); only present for specific chips. */
  computeUnits?: number;
  /** CPU SIMD register width in bytes. */
  nativeVectorBytes?: number;
}

export interface DispatchInfo {
  /** Entry point symbol. */
  name: string;
  /** "linalg.matmul", "linalg.generic", ... */
  opName: string;
  /** From op result/operand shapes; empty if not recoverable. */
  iterationDomain: number[];
  /** "parallel" | "reduction", from the op. */
  iteratorTypes: string[];
  config?: LoweringConfig;
  translation?: TranslationInfo;
  sourceFile: string;
  /** 1-based line of the op carrying the config, if found. */
  sourceLine?: number;
  operands: OperandInfo[];
  /** Number of linalg ops in the function. */
  opCount: number;
  /** Executable symbol (hal.executable @X). */
  executable?: string;
  /** Variant symbol (hal.executable.variant @X). */
  variant?: string;
  /** Target shared-memory budget in bytes from settings (fallback when the IR has none). */
  sharedMemoryBudgetBytes?: number;
  /** Hardware limits from the IR's target attribute. */
  hardware?: TargetHardware;
  /** Conventional names for the iteration dims of named ops (M, N, K, ...). */
  dimNames?: string[];
}

export interface TilingCheck {
  status: 'ok' | 'warn' | 'info';
  title: string;
  detail: string;
}

// ---------------------------------------------------------------------------
// Tiling geometry (computed from DispatchInfo, rendered by the webview)
// ---------------------------------------------------------------------------

export interface TileRect {
  level: number;
  x: number;       // in iteration-space units
  y: number;
  w: number;
  h: number;
  ragged: boolean; // a remainder tile (smaller than the nominal tile)
}

export interface HatchRegion {
  level: number;
  x: number;
  y: number;
  w: number;
  h: number;
  count: number;   // tiles represented
}

export interface LevelStats {
  name: string;
  sizes: number[];
  /** Effective tile per dim after inheriting untiled dims from the parent level. */
  effective: number[];
  /** Tiles per dim within the parent tile (level 0: within the domain). */
  tilesPerDim: number[];
  tilesTotal: number;
  /** Dims (indices) where the parent extent is not divisible by the tile. */
  raggedDims: number[];
}

export interface OperandFootprint {
  name: string;
  role: 'input' | 'output';
  tileShape: number[];
  bytes?: number;
}

export interface TilingGeometry {
  /** Iteration dims used as drawing axes: [xDim, yDim]; yDim may be -1 (1-D). */
  axes: [number, number];
  domain: number[];
  reductionDims: number[];
  levels: LevelStats[];
  rects: TileRect[];
  hatches: HatchRegion[];
  /** Reduction strip rects, per level, along the first reduction dim. */
  reductionRects: TileRect[];
  reductionHatches: HatchRegion[];
  workgroupCount?: number;
  footprints: OperandFootprint[];
  footprintTotalBytes?: number;
  fitsSharedMemory?: boolean;
  truncated: boolean;
  warnings: string[];
}
