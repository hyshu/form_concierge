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
} from '../test/helpers';
import { changeOwnPassword, createUser, deleteUser, updateUserRole } from './admin_users';
import { hashPassword, verifyPassword } from './crypto';
import type { AdminContext, Env } from './types';

test('createUser rejects invalid email and short password before touching storage', async () => {
  await assertHttpErrorAsync(
    () =>
      createUser(
        adminPostRequest('users', {
          role: 'editor',
          email: 'not-an-email',
          password: 'password123',
        }),
        usersEnv({}),
      ),
    400,
    'email must be a valid email address',
  );
  await assertHttpErrorAsync(
    () =>
      createUser(
        adminPostRequest('users', { role: 'editor', email: 'new@example.com', password: 'short' }),
        usersEnv({}),
      ),
    400,
    'password must be at least 8 characters',
  );
});

test('createUser maps duplicate emails to 409', async () => {
  await assertHttpErrorAsync(
    () =>
      createUser(
        adminPostRequest('users', {
          role: 'editor',
          email: 'dup@example.com',
          password: 'password123',
        }),
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
    () =>
      updateUserRole(
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
  const payload = (await response.json()) as { role: string };
  assert.equal(payload.role, 'viewer');
});

test('updateUserRole returns 404 for unknown users', async () => {
  await assertHttpErrorAsync(
    () =>
      updateUserRole(
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
    () => deleteUser(usersEnv({ targetScopeNames: '["admin"]', adminCount: 1 }), adminContext('admin-2'), 'admin-1'),
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

test('changeOwnPassword rejects an incorrect current password', async () => {
  const passwordHash = await hashPassword('current-password');
  await assertHttpErrorAsync(
    () =>
      changeOwnPassword(
        adminPutRequest('account/password', {
          currentPassword: 'wrong-password',
          newPassword: 'new-password-123',
        }),
        usersEnv({ passwordHash }),
        adminContext('admin-1'),
      ),
    401,
    'Current password is incorrect',
  );
});

test('changeOwnPassword updates password and revokes other sessions', async () => {
  const executed: { sql: string; values: unknown[] }[] = [];
  const response = await changeOwnPassword(
    new Request('https://example.com/api/admin/account/password', {
      method: 'PUT',
      headers: { authorization: 'Bearer current-session-token' },
      body: JSON.stringify({
        currentPassword: 'current-password',
        newPassword: 'new-password-123',
      }),
    }),
    usersEnv({
      passwordHash: await hashPassword('current-password'),
      executed,
    }),
    adminContext('admin-1'),
  );
  assert.deepEqual(await response.json(), { ok: true });
  assert.equal(executed.length, 2);
  assert.equal(executed[0].sql.startsWith('UPDATE admins SET password_hash'), true);
  assert.equal(await verifyPassword('new-password-123', executed[0].values[0] as string), true);
  assert.equal(executed[1].sql.startsWith('DELETE FROM admin_sessions'), true);
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
  passwordHash?: string;
  executed?: { sql: string; values: unknown[] }[];
};

function usersEnv(options: UsersEnvOptions): Env {
  return {
    DB: d1Database((sql: string) => {
      const captured: { sql: string; values: unknown[] } = { sql, values: [] };
      if (sql.startsWith('UPDATE admins SET password_hash') || sql.startsWith('DELETE FROM admin_sessions')) {
        options.executed?.push(captured);
      }
      return {
        bind(...values: unknown[]) {
          captured.values = values;
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
            return (options.targetScopeNames == null ? null : { scope_names: options.targetScopeNames }) as T | null;
          }
          if (sql.includes('COUNT(*)')) {
            return { count: options.adminCount ?? 0 } as T | null;
          }
          if (sql.startsWith('UPDATE admins')) {
            return (options.updatedRow ?? null) as T | null;
          }
          if (sql.includes('SELECT password_hash FROM admins')) {
            return (options.passwordHash == null ? null : { password_hash: options.passwordHash }) as T | null;
          }
          throw new Error(`Unexpected first() query in admin_users test: ${sql}`);
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
