import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import test from 'node:test';

import { projectRow, surveyRow } from '../test/fixtures';
import {
  adminPostRequest,
  assertBadRequest,
  assertBadRequestAsync,
  d1Database,
  d1Result,
  emptyD1Raw,
  stubRateLimiter,
  stubSecretsStoreEnv,
} from '../test/helpers';
import { createSurvey, createSurveyWithQuestions } from './admin_surveys';
import { getAdminProject } from './admin_projects';
import { parseSurveyNotifications, PREVIOUS_NOTIFICATION_EMAIL_SQL } from './notification_settings';
import type { AdminContext, Env } from './types';

test('previous notification email prefers project history, then latest across projects', () => {
  const db = new DatabaseSync(':memory:');
  try {
    db.exec(`CREATE TABLE surveys (id INTEGER PRIMARY KEY, project_id INTEGER);
      CREATE TABLE notification_settings (
        id INTEGER PRIMARY KEY, survey_id INTEGER, recipient_email TEXT, updated_at TEXT, enabled INTEGER
      );
      INSERT INTO surveys VALUES (1, 1), (2, 1), (3, 2);
      INSERT INTO notification_settings VALUES
        (1, 1, 'old@example.com', '2026-01-01', 1),
        (2, 2, 'project@example.com', '2026-01-02', 0),
        (3, 3, 'global@example.com', '2026-01-03', 1);`);
    const previous = db.prepare(PREVIOUS_NOTIFICATION_EMAIL_SQL);
    assert.equal(previous.get(1)?.recipient_email, 'project@example.com');
    assert.equal(previous.get(2)?.recipient_email, 'global@example.com');
    assert.equal(previous.get(99)?.recipient_email, 'global@example.com');
    db.exec('DELETE FROM notification_settings;');
    assert.equal(previous.get(1), undefined);
  } finally {
    db.close();
  }
});

test('notification creation preferences validate email even when disabled', () => {
  assert.equal(parseSurveyNotifications(undefined), null);
  assert.equal(parseSurveyNotifications({ enabled: false, recipientEmail: '' }), null);
  assert.equal(parseSurveyNotifications({ enabled: false, recipientEmail: '  ' }), null);
  assert.deepEqual(parseSurveyNotifications({ enabled: false, recipientEmail: 'ops@example.com' }), {
    enabled: false,
    recipientEmail: 'ops@example.com',
  });
  assertBadRequest(
    () => parseSurveyNotifications({ enabled: true, recipientEmail: '' }),
    'notifications.recipientEmail is required',
  );
  assertBadRequest(
    () => parseSurveyNotifications({ enabled: false, recipientEmail: 'invalid' }),
    'notifications.recipientEmail must be a valid email address',
  );
});

test('invalid creation notifications are rejected before any database access', async () => {
  const { env } = creationEnv();
  await assertBadRequestAsync(
    () =>
      createSurveyWithQuestions(
        adminPostRequest('surveys/with-questions', {
          notifications: { enabled: 'yes', recipientEmail: 'ops@example.com' },
        }),
        { ...env, DB: d1Database() },
        admin,
      ),
    'notifications.enabled must be a boolean',
  );
});

for (const withQuestions of [false, true]) {
  for (const enabled of [false, true]) {
    test(`survey creation withQuestions=${withQuestions} saves notifications enabled=${enabled}`, async () => {
      const { env, writes } = creationEnv();
      const response = await create(withQuestions, env, { enabled, recipientEmail: 'ops@example.com' });
      assert.equal(response.status, 201);
      const notification = writes.find((write) => write.sql.startsWith('INSERT INTO notification_settings'));
      assert.deepEqual(notification?.values.slice(0, 3), [1, enabled ? 1 : 0, 'ops@example.com']);
      assert.equal(
        writes.some((write) => write.sql.startsWith('DELETE FROM surveys')),
        false,
      );
    });
  }

  test(`survey creation withQuestions=${withQuestions} rolls back when notification persistence fails`, async () => {
    const { env, writes } = creationEnv(true);
    await assert.rejects(
      () => create(withQuestions, env, { enabled: true, recipientEmail: 'ops@example.com' }),
      /Notification write failed/,
    );
    const deleted = writes.find((write) => write.sql.startsWith('DELETE FROM surveys'));
    assert.deepEqual(deleted?.values, [1]);
  });
}

test('notification off without a recipient creates no notification settings', async () => {
  const { env, writes } = creationEnv();
  const response = await create(true, env, { enabled: false, recipientEmail: null });
  assert.equal(response.status, 201);
  assert.equal(
    writes.some((write) => write.sql.includes('notification_settings')),
    false,
  );
});

test('project admin view supplies the suggested notification recipient', async () => {
  const { env } = creationEnv();
  const payload = (await (await getAdminProject(env, 1)).json()) as { notificationRecipientEmail: string };
  assert.equal(payload.notificationRecipientEmail, 'previous@example.com');
});

const admin: AdminContext = {
  id: 'admin-1',
  email: 'admin@example.com',
  scopeNames: ['admin'],
  created: '2026-01-01T00:00:00.000Z',
};

function create(withQuestions: boolean, env: Env, notifications: unknown): Promise<Response> {
  const survey = {
    projectId: 1,
    slug: 'feedback',
    titleTranslations: { en: 'Feedback' },
    descriptionTranslations: { en: '' },
  };
  return withQuestions
    ? createSurveyWithQuestions(
        adminPostRequest('surveys/with-questions', { survey, questions: [], notifications }),
        env,
        admin,
      )
    : createSurvey(adminPostRequest('surveys', { ...survey, notifications }), env, admin);
}

function creationEnv(failNotifications = false) {
  const writes: { sql: string; values: unknown[] }[] = [];
  const env: Env = {
    DB: d1Database((sql) => {
      let values: unknown[] = [];
      return {
        bind(...bound: unknown[]) {
          values = bound;
          return this;
        },
        async first<T>() {
          if (sql === PREVIOUS_NOTIFICATION_EMAIL_SQL) return { recipient_email: 'previous@example.com' } as T;
          if (sql.includes('FROM projects WHERE id')) return projectRow() as T;
          if (sql.startsWith('SELECT id FROM surveys')) return null;
          if (sql.startsWith('INSERT INTO surveys')) return surveyRow() as T;
          throw new Error(`Unexpected query: ${sql}`);
        },
        async run<T>() {
          writes.push({ sql, values });
          if (failNotifications && sql.startsWith('INSERT INTO notification_settings')) {
            throw new Error('Notification write failed');
          }
          return d1Result<T>([]);
        },
        async all<T>() {
          return d1Result<T>([]);
        },
        raw: emptyD1Raw,
      } satisfies D1PreparedStatement;
    }),
    MEDIA_BUCKET: {} as R2Bucket,
    PUBLIC_BASE_URL: 'https://api.example.com',
    PUBLIC_FORM_ASSET_BASE_URL: 'https://forms.example.com',
    LOGIN_RATE_LIMITER: stubRateLimiter(),
    ANON_CREATE_RATE_LIMITER: stubRateLimiter(),
    ...stubSecretsStoreEnv(),
  };
  return { env, writes };
}
