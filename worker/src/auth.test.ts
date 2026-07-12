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
} from '../test/helpers';
import { bootstrapAdmin, loginAdmin } from './auth';

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
    () =>
      bootstrapAdmin(
        bootstrapRequest({
          email: 'admin@example.com',
          password: 'password123',
        }),
        env,
      ),
    409,
    'Admin already exists',
  );
});

test('login requires CAPTCHA after three failed attempts when Turnstile is configured', async () => {
  const { env, failures } = loginEnv({ turnstileConfigured: true });
  const request = () =>
    loginRequest({
      email: 'admin@example.com',
      password: 'wrong-password',
    });

  for (let attempt = 1; attempt <= 2; attempt++) {
    await assert.rejects(
      () => loginAdmin(request(), env),
      (error: unknown) =>
        error instanceof Error &&
        'details' in error &&
        (error as { details?: { captchaRequired?: boolean } }).details?.captchaRequired === false,
    );
  }
  await assert.rejects(
    () => loginAdmin(request(), env),
    (error: unknown) =>
      error instanceof Error &&
      'details' in error &&
      (error as { details?: { captchaRequired?: boolean } }).details?.captchaRequired === true,
  );
  assert.equal([...failures.values()][0], 3);

  await assertHttpErrorAsync(() => loginAdmin(request(), env), 403, 'CAPTCHA is required');
});

test('login never requires CAPTCHA when Turnstile keys are not configured', async () => {
  const { env, failures } = loginEnv({ turnstileConfigured: false });
  for (let attempt = 0; attempt < 4; attempt++) {
    await assertHttpErrorAsync(
      () =>
        loginAdmin(
          loginRequest({
            email: 'admin@example.com',
            password: 'wrong-password',
          }),
          env,
        ),
      401,
      'Invalid email or password',
    );
  }
  assert.equal(failures.size, 0);
});

function bootstrapRequest(body: { email: string; password: string }): Request {
  return new Request('https://example.com/api/admin/bootstrap', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}

function loginRequest(body: { email: string; password: string; captchaToken?: string }): Request {
  return new Request('https://example.com/api/admin/auth/login', {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'cf-connecting-ip': '203.0.113.10',
    },
    body: JSON.stringify(body),
  });
}

function loginEnv(options: { turnstileConfigured: boolean }): {
  env: Env;
  failures: Map<string, number>;
} {
  const failures = new Map<string, number>();
  const db = d1Database(
    (sql: string) =>
      ({
        bind(...values: unknown[]) {
          return {
            async first<T>() {
              const key = String(values[0]);
              if (sql.includes('FROM admin_login_failures')) {
                const count = failures.get(key);
                return (count == null ? null : { failed_attempts: count }) as T;
              }
              if (sql.includes('INSERT INTO admin_login_failures')) {
                const count = (failures.get(key) ?? 0) + 1;
                failures.set(key, count);
                return { failed_attempts: count } as T;
              }
              if (sql.includes('FROM admins WHERE email')) return null;
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
      }) as unknown as D1PreparedStatement,
  );
  return {
    failures,
    env: {
      DB: db,
      MEDIA_BUCKET: {} as R2Bucket,
      PUBLIC_BASE_URL: 'https://api.example.com',
      PUBLIC_FORM_ASSET_BASE_URL: 'https://forms.example.com',
      LOGIN_RATE_LIMITER: stubRateLimiter(),
      ANON_CREATE_RATE_LIMITER: stubRateLimiter(),
      ...stubSecretsStoreEnv({
        turnstileSiteKey: options.turnstileConfigured ? undefined : null,
        turnstileSecretKey: options.turnstileConfigured ? undefined : null,
      }),
    },
  };
}

function bootstrapEnv(options: { inserted: boolean }): Env {
  return {
    DB: d1Database(
      (sql: string) =>
        ({
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
        }) as unknown as D1PreparedStatement,
    ),
    MEDIA_BUCKET: {} as R2Bucket,
    PUBLIC_BASE_URL: 'https://api.example.com',
    PUBLIC_FORM_ASSET_BASE_URL: 'https://forms.example.com',
    LOGIN_RATE_LIMITER: stubRateLimiter(),
    ANON_CREATE_RATE_LIMITER: stubRateLimiter(),
    ...stubSecretsStoreEnv(),
  };
}
