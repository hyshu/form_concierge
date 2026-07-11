import test from 'node:test';

import { integrationSettingsRow } from '../test/fixtures';
import {
  adminPutRequest,
  assertHttpError,
  assertHttpErrorAsync,
  d1Database,
  stubRateLimiter,
  stubSecretsStoreEnv,
  TEST_TURNSTILE_SITE_KEY,
  TEST_TURNSTILE_SECRET_KEY,
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
  return {
    DB: d1Database((sql: string) => {
      if (!sql.includes('SELECT * FROM integration_settings')) {
        throw new Error('D1 write should not be used by invalid settings tests');
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
    TURNSTILE_SITE_KEY: TEST_TURNSTILE_SITE_KEY,
    TURNSTILE_SECRET_KEY: TEST_TURNSTILE_SECRET_KEY,
    ...stubSecretsStoreEnv(),
  };
}
