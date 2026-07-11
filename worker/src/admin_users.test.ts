import assert from 'node:assert/strict';
import test from 'node:test';

import { adminRow } from '../test/fixtures';
import {
  adminPostRequest,
  adminPutRequest,
  assertHttpErrorAsync,
  d1Database,
  stubRateLimiter,
  stubSecretsStoreEnv,
  TEST_TURNSTILE_SECRET_KEY,
  TEST_TURNSTILE_SITE_KEY,
} from '../test/helpers';
import { createUser, deleteUser, updateUserRole } from './admin_users';
import type { AdminContext, Env } from './types';

test('createUser rejects invalid email and short password before touching storage', async () => {
  await assertHttpErrorAsync(
    () => createUser(
      adminPostRequest('users', { role: 'editor', email: 'not-an-email', password: 'password123' }),
      usersEnv({}),
    ),
    400,
    'email must be a valid email address',
  );
  await assertHttpErrorAsync(
    () => createUser(
      adminPostRequest('users', { role: 'editor', email: 'new@example.com', password: 'short' }),
      usersEnv({}),
    ),
    400,
    'password must be at least 8 characters',
  );
});

test('createUser maps duplicate emails to 409', async () => {
  await assertHttpErrorAsync(
    () => createUser(
      adminPostRequest('users', { role: 'editor', email: 'dup@example.com', password: 'password123' }),
      usersEnv({
        insertError: new Error('UNIQUE constraint failed: admins.email'),
      }),
    ),
    409,
    'A user with this email already exists',
  );
});

test('updateUserRole refuses to demote the last active admin', async () => {
  await assertHttpErrorAsync(
    () => updateUserRole(
      adminPutRequest('users/admin-1', { role: 'editor' }),
      usersEnv({ targetScopeNames: '["admin"]', adminCount: 1 }),
      'admin-1',
    ),
    400,
    'Cannot remove the last active admin',
  );
});

test('updateUserRole allows demotion when another admin remains', async () => {
  const response = await updateUserRole(
    adminPutRequest('users/admin-1', { role: 'editor' }),
    usersEnv({
      targetScopeNames: '["admin"]',
      adminCount: 2,
      updatedRow: adminRow({ scope_names: '["survey:read"]' }),
    }),
    'admin-1',
  );
  const payload = await response.json() as { role: string };
  assert.equal(payload.role, 'viewer');
});

test('updateUserRole returns 404 for unknown users', async () => {
  await assertHttpErrorAsync(
    () => updateUserRole(
      adminPutRequest('users/ghost', { role: 'editor' }),
      usersEnv({ targetScopeNames: null, updatedRow: null }),
      'ghost',
    ),
    404,
    'User not found',
  );
});

test('deleteUser refuses to delete the last active admin', async () => {
  await assertHttpErrorAsync(
    () => deleteUser(
      usersEnv({ targetScopeNames: '["admin"]', adminCount: 1 }),
      adminContext('admin-2'),
      'admin-1',
    ),
    400,
    'Cannot delete the last active admin',
  );
});

test('deleteUser reports self-deletion', async () => {
  const env = usersEnv({ targetScopeNames: '["survey:read"]', adminCount: 2 });
  const self = await deleteUser(env, adminContext('editor-1'), 'editor-1');
  assert.deepEqual(await self.json(), { selfDeleted: true });
  const other = await deleteUser(env, adminContext('admin-1'), 'editor-1');
  assert.deepEqual(await other.json(), { selfDeleted: false });
});

function adminContext(id: string): AdminContext {
  return {
    id,
    email: `${id}@example.com`,
    scopeNames: ['admin'],
    created: '2026-01-01T00:00:00.000Z',
  };
}

type UsersEnvOptions = {
  insertError?: Error;
  targetScopeNames?: string | null;
  adminCount?: number;
  updatedRow?: ReturnType<typeof adminRow> | null;
};

function usersEnv(options: UsersEnvOptions): Env {
  return {
    DB: d1Database((sql: string) => ({
      bind() {
        return this;
      },
      async run() {
        if (sql.startsWith('INSERT INTO admins') && options.insertError) {
          throw options.insertError;
        }
        return { success: true } as unknown as D1Result;
      },
      async first<T>() {
        if (sql.includes('SELECT scope_names FROM admins')) {
          return (options.targetScopeNames == null
            ? null
            : { scope_names: options.targetScopeNames }) as T | null;
        }
        if (sql.includes('COUNT(*)')) {
          return { count: options.adminCount ?? 0 } as T | null;
        }
        if (sql.startsWith('UPDATE admins')) {
          return (options.updatedRow ?? null) as T | null;
        }
        throw new Error(`Unexpected first() query in admin_users test: ${sql}`);
      },
    }) as unknown as D1PreparedStatement),
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
