// Launches VS Code with the extension under development and runs the suite.
//   IREE_COMPILE=/path/to/iree-compile  enables the tests that really compile.
//   VSCODE_PATH=/path/to/Code           uses a local VS Code instead of downloading one.
import * as path from 'path';
import { runTests } from '@vscode/test-electron';

async function main(): Promise<void> {
  const root = path.resolve(__dirname, '..', '..');
  const workspace = path.join(root, 'test', 'fixtures', 'inputs');
  try {
    await runTests({
      extensionDevelopmentPath: root,
      extensionTestsPath: path.join(__dirname, 'suite', 'index'),
      vscodeExecutablePath: process.env.VSCODE_PATH || undefined,
      launchArgs: [workspace, '--disable-extensions', '--disable-workspace-trust'],
      extensionTestsEnv: { IREE_COMPILE: process.env.IREE_COMPILE ?? '' },
    });
  } catch (e) {
    console.error('Integration tests failed:', e);
    process.exit(1);
  }
}

void main();
