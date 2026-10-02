import * as path from 'path';

export const FIXTURES = path.join(__dirname, '..', 'fixtures');
export const VERSION_DIR = path.join(FIXTURES, 'iree-llvm24-2026');
export const fixture = (...p: string[]) => path.join(FIXTURES, ...p);
export const dump = (name: string) => path.join(VERSION_DIR, name);
