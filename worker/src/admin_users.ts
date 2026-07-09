import type { AdminContext, AdminRow, Env } from './types';
import { HttpError, countRows, isUniqueConstraintError, json, nowIso, readJson, requireEmail, requireString } from './utils';
import { hashPassword } from './crypto';
import { adminContextToJson, adminUserToJson } from './serializers';
import { getAdminById } from './auth';
import { scopesForRole } from './permissions';

const MIN_PASSWORD_LENGTH = 8;

export async function listUsers(env: Env): Promise<Response> {
  const rows = await env.DB.prepare(
    `SELECT id, email, scope_names, created_at FROM admins ORDER BY created_at`,
  ).all<AdminRow>();
  return json(rows.results.map(adminUserToJson));
}

export async function createUser(request: Request, env: Env): Promise<Response> {
  const body = await readJson(request);
  const id = crypto.randomUUID();
  const role = requireString(body.role, 'role');
  const email = requireEmail(body.email, 'email');
  const password = requireString(body.password, 'password');
  if (password.length < MIN_PASSWORD_LENGTH) {
    throw new HttpError(400, `password must be at least ${MIN_PASSWORD_LENGTH} characters`);
  }
  try {
    await env.DB.prepare(
      `INSERT INTO admins (id, email, password_hash, scope_names)
       VALUES (?, ?, ?, ?)`,
    ).bind(
      id,
      email,
      await hashPassword(password),
      JSON.stringify(scopesForRole(role)),
    ).run();
  } catch (error) {
    if (isUniqueConstraintError(error)) {
      throw new HttpError(409, 'A user with this email already exists');
    }
    throw error;
  }
  const user = await getAdminById(env.DB, id);
  return json(adminContextToJson(user!), 201);
}

export async function updateUserRole(request: Request, env: Env, userId: string): Promise<Response> {
  const body = await readJson(request);
  const role = requireString(body.role, 'role');
  if (role !== 'admin' && await isLastActiveAdmin(env.DB, userId)) {
    throw new HttpError(400, 'Cannot remove the last active admin');
  }
  const row = await env.DB.prepare(
    `UPDATE admins SET scope_names = ?, updated_at = ? WHERE id = ?
     RETURNING id, email, scope_names, created_at`,
  ).bind(JSON.stringify(scopesForRole(role)), nowIso(), userId).first<AdminRow>();
  if (!row) throw new HttpError(404, 'User not found');
  return json(adminUserToJson(row));
}

export async function deleteUser(env: Env, admin: AdminContext, userId: string): Promise<Response> {
  if (await isLastActiveAdmin(env.DB, userId)) {
    throw new HttpError(400, 'Cannot delete the last active admin');
  }
  await env.DB.prepare(`DELETE FROM admins WHERE id = ?`).bind(userId).run();
  return json({ selfDeleted: admin.id === userId });
}

async function isLastActiveAdmin(db: D1Database, userId: string): Promise<boolean> {
  const target = await db.prepare(
    `SELECT scope_names FROM admins WHERE id = ?`,
  ).bind(userId).first<{ scope_names: string }>();
  if (!target || !target.scope_names.includes('"admin"')) return false;
  const count = await countRows(
    db,
    `SELECT COUNT(*) AS count FROM admins
     WHERE scope_names LIKE '%"admin"%'`,
  );
  return count <= 1;
}
