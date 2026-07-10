import assert from 'node:assert/strict';
import test from 'node:test';

import { responseRow, surveyRow } from '../test/fixtures';
import { assertHttpErrorAsync, emptyD1Result } from '../test/helpers';
import { generateFollowUp, saveFollowUp } from './follow_up';
import type { Env } from './types';

const anonymous = {
  id: 'anon-account-1',
  displayName: null,
  createdAt: '2026-01-01T00:00:00.000Z',
  lastSeenAt: '2026-01-01T00:00:00.000Z',
};

function jsonRequest(method: string, path: string, body: unknown): Request {
  return new Request(`http://localhost${path}`, {
    method,
    headers: {
      'content-type': 'application/json',
      authorization: 'Bearer token',
    },
    body: JSON.stringify(body),
  });
}

function envWithLookup(handlers: {
  selectResponse?: () => unknown;
  selectSurvey?: () => unknown;
  updateResponse?: () => unknown;
}): Env {
  return {
    DB: {
      prepare(sql: string) {
        return {
          bind: (..._args: unknown[]) => ({
            first: async () => {
              if (sql.includes('UPDATE survey_responses')) {
                return handlers.updateResponse?.() ?? null;
              }
              if (sql.includes('FROM survey_responses')) {
                return handlers.selectResponse?.() ?? null;
              }
              if (sql.includes('FROM surveys')) {
                return handlers.selectSurvey?.() ?? null;
              }
              return null;
            },
            run: async () => emptyD1Result(),
            all: async () => ({ results: [] }),
          }),
        };
      },
    },
  } as unknown as Env;
}

test('generateFollowUp skips when survey follow-up is disabled', async () => {
  const skippedPayload = {
    version: 1,
    status: 'skipped',
    generatedAt: '2026-01-01T00:00:00.000Z',
    completedAt: '2026-01-01T00:00:00.000Z',
    locale: 'en',
    items: [],
  };
  const env = envWithLookup({
    selectResponse: () => responseRow({ id: 10, survey_id: 1, follow_up: null }),
    selectSurvey: () => surveyRow({ id: 1, follow_up_enabled: 0 }),
    updateResponse: () => responseRow({
      id: 10,
      survey_id: 1,
      follow_up: JSON.stringify(skippedPayload),
    }),
  });

  const response = await generateFollowUp(
    jsonRequest('POST', '/api/responses/10/follow-up/generate', {}),
    env,
    10,
    anonymous,
  );
  assert.equal(response.status, 200);
  const body = await response.json() as {
    needed: boolean;
    followUp: { status: string; items: unknown[] };
  };
  assert.equal(body.needed, false);
  assert.equal(body.followUp.status, 'skipped');
  assert.deepEqual(body.followUp.items, []);
});

test('saveFollowUp rejects answers when follow-up was never generated', async () => {
  const env = envWithLookup({
    selectResponse: () => responseRow({ id: 10, follow_up: null }),
  });

  await assertHttpErrorAsync(
    () => saveFollowUp(
      jsonRequest('PUT', '/api/responses/10/follow-up', { answers: [] }),
      env,
      10,
      anonymous,
    ),
    400,
    'Follow-up has not been generated',
  );
});
