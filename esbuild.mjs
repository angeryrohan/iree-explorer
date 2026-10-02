import * as esbuild from 'esbuild';
import { copyFile, mkdir } from 'node:fs/promises';

const production = process.argv.includes('--production');
const watch = process.argv.includes('--watch');

const common = {
  bundle: true,
  minify: production,
  sourcemap: !production,
  logLevel: 'info',
};

const extension = {
  ...common,
  entryPoints: ['src/extension.ts'],
  outfile: 'dist/extension.js',
  platform: 'node',
  format: 'cjs',
  target: 'node18',
  external: ['vscode'],
};

const webviews = ['tiling', 'dataflow', 'opdiff'].map((name) => ({
  ...common,
  entryPoints: [`src/webview/${name}/main.ts`],
  outfile: `media/${name}/main.js`,
  platform: 'browser',
  format: 'iife',
  target: 'es2020',
}));

for (const name of ['tiling', 'dataflow', 'opdiff']) {
  await mkdir(`media/${name}`, { recursive: true });
  await copyFile(`src/webview/${name}/style.css`, `media/${name}/style.css`);
}

if (watch) {
  for (const cfg of [extension, ...webviews]) {
    const ctx = await esbuild.context(cfg);
    await ctx.watch();
  }
} else {
  await Promise.all([esbuild.build(extension), ...webviews.map((w) => esbuild.build(w))]);
}
