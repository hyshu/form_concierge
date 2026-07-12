import assert from 'node:assert/strict';
import test from 'node:test';

import { responseRow, surveyRow } from '../test/fixtures';
import {
  adminPutRequest,
  assertHttpErrorAsync,
  d1Database,
  stubRateLimiter,
  stubSecretsStoreEnv,
} from '../test/helpers';
import { notificationSettings, sendResponseNotification } from './notification_settings';
import type { Env, NotificationSettingsRow } from './types';

test('notificationSettings GET returns null when nothing is configured', async () => {
  const response = await notificationSettings(
    new Request('https://example.com/api/admin/surveys/1/notifications'),
    notificationEnv({}),
    1,
    [],
  );
  assert.equal(await response.json(), null);
});

test('notificationSettings PUT validates the survey and payload', async () => {
  await assertHttpErrorAsync(
    () => notificationSettings(
      adminPutRequest('surveys/99/notifications', { enabled: true, recipientEmail: 'a@b.co' }),
      notificationEnv({ survey: null }),
      99,
      [],
    ),
    404,
    'Survey not found',
  );
  await assertHttpErrorAsync(
    () => notificationSettings(
      adminPutRequest('surveys/1/notifications', { enabled: 'yes', recipientEmail: 'a@b.co' }),
      notificationEnv({ survey: surveyRow() }),
      1,
      [],
    ),
    400,
    'enabled must be a boolean',
  );
  await assertHttpErrorAsync(
    () => notificationSettings(
      adminPutRequest('surveys/1/notifications', { enabled: true, recipientEmail: 'nope' }),
      notificationEnv({ survey: surveyRow() }),
      1,
      [],
    ),
    400,
    'recipientEmail must be a valid email address',
  );
});

test('notificationSettings PUT upserts and returns the stored row', async () => {
  const stored = notificationRow({ enabled: 1, recipient_email: 'ops@example.com' });
  const response = await notificationSettings(
    adminPutRequest('surveys/1/notifications', { enabled: true, recipientEmail: 'ops@example.com' }),
    notificationEnv({ survey: surveyRow(), upsertedRow: stored }),
    1,
    [],
  );
  assert.deepEqual(await response.json(), {
    id: 1,
    surveyId: 1,
    enabled: true,
    recipientEmail: 'ops@example.com',
    updatedAt: '2026-01-01T00:00:00.000Z',
  });
});

test('notificationSettings toggle returns 404 when no settings exist', async () => {
  await assertHttpErrorAsync(
    () => notificationSettings(
      toggleRequest({ enabled: true }),
      notificationEnv({ toggledRow: null }),
      1,
      ['api', 'admin', 'surveys', '1', 'notifications', 'toggle'],
    ),
    404,
    'Notification settings not found',
  );
});

test('notificationSettings test-send fails fast when SMTP is not configured', async () => {
  await assertHttpErrorAsync(
    () => notificationSettings(
      new Request('https://example.com/api/admin/surveys/1/notifications/test', { method: 'POST' }),
      notificationEnv({ integrationSettings: null }),
      1,
      ['api', 'admin', 'surveys', '1', 'notifications', 'test'],
    ),
    400,
    'SMTP settings are not configured',
  );
});

test('notificationSettings rejects unknown methods with 404', async () => {
  const response = await notificationSettings(
    new Request('https://example.com/api/admin/surveys/1/notifications', { method: 'PATCH' }),
    notificationEnv({}),
    1,
    [],
  );
  assert.equal(response.status, 404);
});

test('sendResponseNotification is a no-op when notifications are disabled', async () => {
  await assert.doesNotReject(
    () => sendResponseNotification(
      notificationEnv({ notificationRow: null, strictAfterNotification: true }),
      surveyRow({ status: 'published' }),
      responseRow(),
    ),
  );
});

test('sendResponseNotification skips sending when SMTP is unconfigured', async () => {
  await assert.doesNotReject(
    () => sendResponseNotification(
      notificationEnv({
        notificationRow: notificationRow({ enabled: 1 }),
        integrationSettings: null,
      }),
      surveyRow({ status: 'published' }),
      responseRow(),
    ),
  );
});

function notificationRow(
  overrides: Partial<NotificationSettingsRow> = {},
): NotificationSettingsRow {
  return {
    id: 1,
    survey_id: 1,
    enabled: 1,
    recipient_email: 'ops@example.com',
    updated_at: '2026-01-01T00:00:00.000Z',
    ...overrides,
  };
}

function toggleRequest(body: unknown): Request {
  return new Request('https://example.com/api/admin/surveys/1/notifications/toggle', {
    method: 'POST',
    body: JSON.stringify(body),
  });
}

type NotificationEnvOptions = {
  survey?: ReturnType<typeof surveyRow> | null;
  notificationRow?: NotificationSettingsRow | null;
  upsertedRow?: NotificationSettingsRow;
  toggledRow?: NotificationSettingsRow | null;
  integrationSettings?: null;
  strictAfterNotification?: boolean;
};

function notificationEnv(options: NotificationEnvOptions): Env {
  return {
    DB: d1Database((sql: string) => ({
      bind() {
        return this;
      },
      async first<T>() {
        if (sql.includes('FROM notification_settings')) {
          return (options.notificationRow ?? null) as T | null;
        }
        if (sql.includes('SELECT * FROM surveys')) {
          return (options.survey ?? null) as T | null;
        }
        if (sql.startsWith('INSERT INTO notification_settings')) {
          return (options.upsertedRow ?? null) as T | null;
        }
        if (sql.startsWith('UPDATE notification_settings')) {
          return (options.toggledRow ?? null) as T | null;
        }
        if (sql.includes('FROM integration_settings')) {
          if (options.strictAfterNotification) {
            throw new Error('Integration settings should not be read when notifications are off');
          }
          return (options.integrationSettings ?? null) as T | null;
        }
        throw new Error(`Unexpected first() query in notification test: ${sql}`);
      },
    }) as unknown as D1PreparedStatement),
    MEDIA_BUCKET: {} as R2Bucket,
    PUBLIC_BASE_URL: 'https://api.example.com',
    PUBLIC_FORM_ASSET_BASE_URL: 'https://assets.example.com',
    LOGIN_RATE_LIMITER: stubRateLimiter(),
    ANON_CREATE_RATE_LIMITER: stubRateLimiter(),
    ...stubSecretsStoreEnv(),
  };
}
