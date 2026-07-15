import assert from 'node:assert/strict';
import { readFile, rm, writeFile } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import path from 'node:path';
import test from 'node:test';

const workerDirectory = path.resolve(import.meta.dirname, '..');
const customConfigPath = path.join(
  workerDirectory,
  '.wrangler.custom-r2.test.jsonc',
);

test('deployment typecheck validates generated R2 bindings', async (t) => {
  t.after(async () => {
    await rm(customConfigPath, { force: true });
  });
  const example = await readFile(
    path.join(workerDirectory, 'wrangler.jsonc.example'),
    'utf8',
  );
  assert.match(example, /"binding": "MEDIA_BUCKET"/);
  await writeFile(customConfigPath, example);

  const validResult = await runDeploymentTypecheck([
    '--config',
    customConfigPath,
  ]);
  assert.equal(validResult.code, 0, validResult.output);

  await writeFile(
    customConfigPath,
    example.replace('"binding": "MEDIA_BUCKET"', '"binding": "CUSTOM_BUCKET"'),
  );

  const result = await runDeploymentTypecheck([
    '--config',
    customConfigPath,
  ]);

  assert.notEqual(result.code, 0);
  assert.match(result.output, /MEDIA_BUCKET/);
});

function runDeploymentTypecheck(arguments_: string[]): Promise<{
  code: number;
  output: string;
}> {
  return new Promise((resolve, reject) => {
    const child = spawn(
      process.execPath,
      ['scripts/check-deployment-types.mjs', ...arguments_],
      {
        cwd: workerDirectory,
        stdio: ['ignore', 'pipe', 'pipe'],
      },
    );
    let output = '';
    child.stdout.setEncoding('utf8');
    child.stderr.setEncoding('utf8');
    child.stdout.on('data', (chunk: string) => {
      output += chunk;
    });
    child.stderr.on('data', (chunk: string) => {
      output += chunk;
    });
    child.once('error', reject);
    child.once('exit', (code, signal) => {
      if (signal) {
        reject(new Error(`deployment typecheck terminated by ${signal}`));
        return;
      }
      resolve({ code: code ?? 1, output });
    });
  });
}
