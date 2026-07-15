import { mkdir, rm } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import path from 'node:path';
import process from 'node:process';

const workerDirectory = process.cwd();
const generatedTypes = path.resolve(
  workerDirectory,
  '../.tmp/worker-env.deployment.d.ts',
);
const configArguments = process.argv.slice(2);
const npx = process.platform === 'win32' ? 'npx.cmd' : 'npx';

await mkdir(path.dirname(generatedTypes), { recursive: true });

let exitCode = 0;
try {
  exitCode = await run(npx, [
    'wrangler',
    'types',
    generatedTypes,
    '--env-interface',
    'WorkerEnv',
    '--include-runtime',
    'false',
    '--strict-vars',
    'false',
    ...configArguments,
  ]);
  if (exitCode === 0) {
    exitCode = await run(npx, [
      'tsc',
      '--noEmit',
      '-p',
      'tsconfig.deployment.json',
    ]);
  }
} finally {
  await rm(generatedTypes, { force: true });
}

process.exitCode = exitCode;

function run(command, arguments_) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, arguments_, {
      cwd: workerDirectory,
      stdio: 'inherit',
    });
    child.once('error', reject);
    child.once('exit', (code, signal) => {
      if (signal) {
        reject(new Error(`${command} terminated by ${signal}`));
        return;
      }
      resolve(code ?? 1);
    });
  });
}
