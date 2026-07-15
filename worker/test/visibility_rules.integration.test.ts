import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';

import { UPDATE_QUESTION_CONDITION_MODE_SQL } from '../src/visibility_rules';

test('visibility condition mode update runs against migrated local D1', () => {
  const persistTo = mkdtempSync(join(tmpdir(), 'form-concierge-d1-'));

  try {
    runWrangler(['d1', 'migrations', 'apply', 'form_concierge', '--local', '--persist-to', persistTo]);
    runWrangler([
      'd1',
      'execute',
      'form_concierge',
      '--local',
      '--persist-to',
      persistTo,
      '--command',
      `INSERT INTO projects (id, slug, supported_locales, name)
       VALUES (1, 'integration', '["en"]', 'Integration');
       INSERT INTO surveys
         (id, project_id, slug, title_translations, description_translations)
       VALUES (1, 1, 'visibility', '{"en":"Visibility"}', '{"en":""}');
       INSERT INTO questions
         (id, survey_id, text_translations, type, order_index, placeholder_translations)
       VALUES (1, 1, '{"en":"Question"}', 'textSingle', 0, '{"en":""}');`,
    ]);

    runWrangler([
      'd1',
      'execute',
      'form_concierge',
      '--local',
      '--persist-to',
      persistTo,
      '--command',
      bindSql(UPDATE_QUESTION_CONDITION_MODE_SQL, ["'any'", '1']),
    ]);

    const output = runWrangler([
      'd1',
      'execute',
      'form_concierge',
      '--local',
      '--persist-to',
      persistTo,
      '--command',
      'SELECT visibility_condition_mode FROM questions WHERE id = 1;',
      '--json',
    ]);
    assert.match(output, /"visibility_condition_mode": "any"/);
  } finally {
    rmSync(persistTo, { recursive: true, force: true });
  }
});

function bindSql(sql: string, values: string[]): string {
  let index = 0;
  const bound = sql.replaceAll('?', () => values[index++] ?? '?');
  assert.equal(index, values.length);
  return bound;
}

function runWrangler(args: string[]): string {
  const result = spawnSync(join('node_modules', '.bin', 'wrangler'), args, {
    cwd: process.cwd(),
    encoding: 'utf8',
    env: { ...process.env, CI: '1' },
  });
  assert.equal(result.status, 0, `${result.stdout}\n${result.stderr}`);
  return result.stdout;
}
