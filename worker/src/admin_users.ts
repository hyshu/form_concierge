import type { AdminContext, AdminRow, Env } from './types';
import { HttpError, json, nowIso, readJson, requireString } from './utils';
import { hashPassword } from './crypto';
import { adminContextToJson, adminUserToJson } from './serializers';
import { getAdminById } from './auth';

export async function listUsers(env: Env): Promise<Response> {
  const rows = await env.DB.prepare(
    `SELECT id, email, scope_names, blocked, created_at FROM admins ORDER BY created_at`,
  ).all<AdminRow>();
  return json(rows.results.map(adminUserToJson));
}

export async function createUser(request: Request, env: Env): Promise<Response> {
  const body = await readJson(request);
  const id = crypto.randomUUID();
  await env.DB.prepare(
    `INSERT INTO admins (id, email, password_hash, scope_names)
     VALUES (?, ?, ?, ?)`,
  ).bind(
    id,
    requireString(body.email, 'email').toLowerCase(),
    await hashPassword(requireString(body.password, 'password')),
    JSON.stringify(Array.isArray(body.scopes) ? body.scopes.map(String) : ['admin']),
  ).run();
  const user = await getAdminById(env.DB, id);
  return json(adminContextToJson(user!), 201);
}

export async function deleteUser(env: Env, admin: AdminContext, userId: string): Promise<Response> {
  await env.DB.prepare(`DELETE FROM admins WHERE id = ?`).bind(userId).run();
  return json({ selfDeleted: admin.id === userId });
}

export async function toggleUserBlocked(env: Env, userId: string): Promise<Response> {
  const row = await env.DB.prepare(
    `UPDATE admins SET blocked = CASE WHEN blocked = 1 THEN 0 ELSE 1 END,
     updated_at = ? WHERE id = ? RETURNING blocked`,
  ).bind(nowIso(), userId).first<{ blocked: number }>();
  if (!row) throw new HttpError(404, 'User not found');
  return json({ blocked: row.blocked === 1 });
}
