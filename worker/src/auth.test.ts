import assert from 'node:assert/strict';
import test from 'node:test';

import { ROLE_SCOPES } from './permissions';
import { hasScope, requireScope } from './permissions';
import type { AdminContext, Env } from './types';
import {
  assertBadRequestAsync,
  assertHttpError,
  assertHttpErrorAsync,
  d1Database,
  d1Meta,
  d1Result,
  stubRateLimiter,
  stubSecretsStoreEnv,
  TEST_TURNSTILE_SITE_KEY,
  TEST_TURNSTILE_SECRET_KEY,
} from '../test/helpers';
import { bootstrapAdmin } from './auth';

function adminWithScopes(scopes: string[]): AdminContext {
  return {
    id: 'admin-1',
    email: 'a@example.com',
    scopeNames: scopes,
    created: '2026-01-01T00:00:00.000Z',
  };
}

test('editor and viewer roles do not include the admin scope', () => {
  assert.equal(ROLE_SCOPES.editor.includes('admin'), false);
  assert.equal(ROLE_SCOPES.viewer.includes('admin'), false);
  assert.equal(ROLE_SCOPES.admin.includes('admin'), true);
});

test('requireScope allows editor survey:read without admin scope', () => {
  const editor = adminWithScopes(ROLE_SCOPES.editor);
  assert.equal(hasScope(editor, 'survey:read'), true);
  assert.equal(hasScope(editor, 'user:manage'), false);
  requireScope(editor, 'survey:read');
  assertHttpError(() => requireScope(editor, 'user:manage'), 403, 'Insufficient permissions');
});

test('requireScope allows viewer response:read and denies writes', () => {
  const viewer = adminWithScopes(ROLE_SCOPES.viewer);
  requireScope(viewer, 'response:read');
  assertHttpError(() => requireScope(viewer, 'survey:write'), 403, 'Insufficient permissions');
});

test('bootstrapAdmin rejects invalid email and short password', async () => {
  const env = bootstrapEnv({ inserted: false });
  await assertBadRequestAsync(
    () => bootstrapAdmin(bootstrapRequest({ email: 'x', password: 'password123' }), env),
    'email must be a valid email address',
  );
  await assertBadRequestAsync(
    () => bootstrapAdmin(bootstrapRequest({ email: 'admin@example.com', password: '1' }), env),
    'password must be at least 8 characters',
  );
});

test('bootstrapAdmin returns 409 when an admin already exists', async () => {
  const env = bootstrapEnv({ inserted: false });
  await assertHttpErrorAsync(
    () => bootstrapAdmin(
      bootstrapRequest({ email: 'admin@example.com', password: 'password123' }),
      env,
    ),
    409,
    'Admin already exists',
  );
});

function bootstrapRequest(body: { email: string; password: string }): Request {
  return new Request('https://example.com/api/admin/bootstrap', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}

function bootstrapEnv(options: { inserted: boolean }): Env {
  return {
    DB: d1Database((sql: string) => ({
      bind() {
        return {
          async first<T>() {
            if (sql.includes('INSERT INTO admins')) {
              return options.inserted
                ? ({
                    id: 'admin-1',
                    email: 'admin@example.com',
                    scope_names: '["admin"]',
                    created_at: '2026-01-01T00:00:00.000Z',
                  } as T)
                : null;
            }
            if (sql.includes('INSERT INTO admin_sessions')) return null;
            throw new Error(`Unexpected first SQL: ${sql}`);
          },
          async all<T>() {
            return d1Result<T>([]);
          },
          async run() {
            return d1Meta();
          },
        };
      },
    } as unknown as D1PreparedStatement)),
    MEDIA_BUCKET: {} as R2Bucket,
    PUBLIC_BASE_URL: 'https://api.example.com',
    PUBLIC_FORM_ASSET_BASE_URL: 'https://forms.example.com',
    LOGIN_RATE_LIMITER: stubRateLimiter(),
    ANON_CREATE_RATE_LIMITER: stubRateLimiter(),
    TURNSTILE_SITE_KEY: TEST_TURNSTILE_SITE_KEY,
    TURNSTILE_SECRET_KEY: TEST_TURNSTILE_SECRET_KEY,
    ...stubSecretsStoreEnv(),
  };
}
