import assert from 'node:assert/strict';
import test from 'node:test';

import { integrationSettingsRow } from '../test/fixtures';
import {
  adminPutRequest,
  assertHttpError,
  assertHttpErrorAsync,
  d1Database,
  stubRateLimiter,
  stubSecretsStoreEnv,
} from '../test/helpers';
import {
  getAdminIntegrationSettings,
  requireSmtpSettings,
  updateAdminIntegrationSettings,
} from './admin_settings';
import type { Env, IntegrationSettingsRow } from './types';

test('updateAdminIntegrationSettings requires settings objects', async () => {
  await assertHttpErrorAsync(
    () => updateAdminIntegrationSettings(
      settingsRequest({ ai: null, smtp: {} }),
      envWithSettings(null),
    ),
    400,
    'ai must be an object',
  );
  await assertHttpErrorAsync(
    () => updateAdminIntegrationSettings(
      settingsRequest({ ai: { provider: 'gemini' }, smtp: null }),
      envWithSettings(null),
    ),
    400,
    'smtp must be an object',
  );
});

test('updateAdminIntegrationSettings rejects coerced settings values', async () => {
  await assertHttpErrorAsync(
    () => updateAdminIntegrationSettings(settingsRequest({
      ai: { provider: 7 },
      smtp: { secureMode: 'starttls' },
    }), envWithSettings(null)),
    400,
    'ai.provider must be a string',
  );
  await assertHttpErrorAsync(
    () => updateAdminIntegrationSettings(settingsRequest({
      ai: { provider: 'gemini', geminiApiKey: 7 },
      smtp: { secureMode: 'starttls' },
    }), envWithSettings(null)),
    400,
    'ai.geminiApiKey must be a string',
  );
  await assertHttpErrorAsync(
    () => updateAdminIntegrationSettings(settingsRequest({
      ai: { provider: 'gemini' },
      smtp: { host: 7, secureMode: 'starttls' },
    }), envWithSettings(null)),
    400,
    'smtp.host must be a string',
  );
  await assertHttpErrorAsync(
    () => updateAdminIntegrationSettings(settingsRequest({
      ai: { provider: 'gemini' },
      smtp: { secureMode: 7 },
    }), envWithSettings(null)),
    400,
    'smtp.secureMode must be a string',
  );
});

test('updateAdminIntegrationSettings rejects a stale expectedUpdatedAt with 409', async () => {
  await assertHttpErrorAsync(
    () => updateAdminIntegrationSettings(
      settingsRequest({
        ai: { provider: 'gemini' },
        smtp: { secureMode: 'starttls' },
        expectedUpdatedAt: '2026-01-01T00:00:00.000Z',
      }),
      envWithSettings(integrationSettingsRow({ updated_at: '2026-02-01T00:00:00.000Z' })),
    ),
    409,
    'Settings were changed by someone else. Reload and try again.',
  );
});

test('updateAdminIntegrationSettings rejects non-string expectedUpdatedAt', async () => {
  await assertHttpErrorAsync(
    () => updateAdminIntegrationSettings(
      settingsRequest({
        ai: { provider: 'gemini' },
        smtp: { secureMode: 'starttls' },
        expectedUpdatedAt: 1234567890,
      }),
      envWithSettings(null),
    ),
    400,
    'expectedUpdatedAt must be a string',
  );
});

test('updateAdminIntegrationSettings saves when expectedUpdatedAt matches the stored row', async () => {
  const stored = integrationSettingsRow({ updated_at: '2026-02-01T00:00:00.000Z' });
  const response = await updateAdminIntegrationSettings(
    settingsRequest({
      ai: { provider: 'gemini' },
      smtp: { secureMode: 'starttls' },
      expectedUpdatedAt: '2026-02-01T00:00:00.000Z',
    }),
    envAllowingWrite(stored),
  );
  const payload = await response.json() as { ai: { provider: string } };
  assert.equal(payload.ai.provider, 'gemini');
});

test('updateAdminIntegrationSettings rejects port 465 without TLS', async () => {
  await assertHttpErrorAsync(
    () => updateAdminIntegrationSettings(
      settingsRequest({
        ai: { provider: 'gemini' },
        smtp: {
          host: 'smtp.resend.com',
          port: 465,
          fromEmail: 'forms@example.com',
          username: 'resend',
          password: 're_test',
          secureMode: 'starttls',
        },
      }),
      envAllowingWrite(integrationSettingsRow()),
    ),
    400,
    'Port 465 requires Security = TLS (implicit SSL/TLS). STARTTLS is for ports 587/2587.',
  );
});

test('updateAdminIntegrationSettings rejects port 587 with implicit TLS', async () => {
  await assertHttpErrorAsync(
    () => updateAdminIntegrationSettings(
      settingsRequest({
        ai: { provider: 'gemini' },
        smtp: {
          host: 'smtp.resend.com',
          port: 587,
          fromEmail: 'forms@example.com',
          username: 'resend',
          password: 're_test',
          secureMode: 'tls',
        },
      }),
      envAllowingWrite(integrationSettingsRow()),
    ),
    400,
    'Port 587 requires Security = STARTTLS. Use port 465 or 2465 for implicit TLS.',
  );
});

test('stored integration setting enums fail closed', async () => {
  await assertHttpErrorAsync(
    () => getAdminIntegrationSettings(envWithSettings(
      integrationSettingsRow({ ai_provider: 'bedrock' }),
    )),
    500,
    'Invalid stored AI provider',
  );
  await assertHttpErrorAsync(
    () => requireSmtpSettings(integrationSettingsRow({ smtp_secure_mode: 'ssl' }), envWithSettings(null)),
    500,
    'Invalid stored SMTP secure mode',
  );
});

function settingsRequest(body: unknown): Request {
  return adminPutRequest('settings', body);
}

function envWithSettings(row: IntegrationSettingsRow | null): Env {
  return settingsEnv(row, { allowWrite: false });
}

function envAllowingWrite(row: IntegrationSettingsRow): Env {
  return settingsEnv(row, { allowWrite: true });
}

function settingsEnv(
  row: IntegrationSettingsRow | null,
  { allowWrite }: { allowWrite: boolean },
): Env {
  return {
    DB: d1Database((sql: string) => {
      const isRead = sql.includes('SELECT * FROM integration_settings');
      if (!isRead && !allowWrite) {
        throw new Error('D1 write should not be used by invalid settings tests');
      }
      if (!isRead && !sql.includes('INSERT INTO integration_settings')) {
        throw new Error(`Unexpected settings query: ${sql}`);
      }
      return {
        bind() {
          return this;
        },
        async first<T>() {
          return row as T | null;
        },
      } as unknown as D1PreparedStatement;
    }),
    MEDIA_BUCKET: {} as R2Bucket,
    PUBLIC_BASE_URL: 'https://api.example.com',
    PUBLIC_FORM_ASSET_BASE_URL: 'https://assets.example.com',
    LOGIN_RATE_LIMITER: stubRateLimiter(),
    ANON_CREATE_RATE_LIMITER: stubRateLimiter(),
    ...stubSecretsStoreEnv(),
  };
}
