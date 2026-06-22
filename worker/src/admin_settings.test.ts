import assert from 'node:assert/strict';
import test from 'node:test';

import {
  getAdminIntegrationSettings,
  requireSmtpSettings,
  updateAdminIntegrationSettings,
} from './admin_settings';
import type { Env, IntegrationSettingsRow } from './types';
import { HttpError } from './utils';

test('updateAdminIntegrationSettings requires settings objects', async () => {
  await assertHttpErrorAsync(
    () => updateAdminIntegrationSettings(settingsRequest({ ai: null, smtp: {} }), envWithSettings(null)),
    400,
    'ai must be an object',
  );
  await assertHttpErrorAsync(
    () => updateAdminIntegrationSettings(settingsRequest({ ai: { provider: 'gemini' }, smtp: null }), envWithSettings(null)),
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
    () => getAdminIntegrationSettings(envWithSettings(settingsRow({ ai_provider: 'bedrock' }))),
    500,
    'Invalid stored AI provider',
  );
  assertHttpError(
    () => requireSmtpSettings(settingsRow({ smtp_secure_mode: 'ssl' })),
    500,
    'Invalid stored SMTP secure mode',
  );
});

function settingsRequest(body: unknown): Request {
  return new Request('https://example.com/api/admin/settings', {
    method: 'PUT',
    body: JSON.stringify(body),
  });
}

function envWithSettings(row: IntegrationSettingsRow | null): Env {
  return {
    DB: {
      prepare(sql: string) {
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
      },
    } as unknown as D1Database,
    PUBLIC_BASE_URL: 'https://api.example.com',
    PUBLIC_FORM_ASSET_BASE_URL: 'https://assets.example.com',
  };
}

function settingsRow(overrides: Partial<IntegrationSettingsRow> = {}): IntegrationSettingsRow {
  return {
    id: 1,
    ai_provider: 'gemini',
    gemini_api_key: null,
    openai_api_key: null,
    claude_api_key: null,
    cerebras_api_key: null,
    smtp_host: 'smtp.example.com',
    smtp_port: 587,
    smtp_username: null,
    smtp_password: null,
    smtp_from_email: 'forms@example.com',
    smtp_from_name: null,
    smtp_secure_mode: 'starttls',
    updated_at: '2026-01-01T00:00:00.000Z',
    ...overrides,
  };
}

function assertHttpError(action: () => unknown, status: number, message: string): void {
  assert.throws(action, (error: unknown) =>
    error instanceof HttpError &&
    error.status === status &&
    error.message === message,
  );
}

async function assertHttpErrorAsync(
  action: () => Promise<unknown>,
  status: number,
  message: string,
): Promise<void> {
  await assert.rejects(action, (error: unknown) =>
    error instanceof HttpError &&
    error.status === status &&
    error.message === message,
  );
}
