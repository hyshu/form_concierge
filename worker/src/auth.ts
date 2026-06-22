import type { AdminContext, AdminRow, AnonymousAccountRow, AnonymousContext, Env } from './types';
import { HttpError, bearerToken, countRows, json, nowIso, readJson, requireString } from './utils';
import { hashPassword, randomToken, sha256Hex, verifyPassword } from './crypto';
import { adminContextToJson, adminRowToContext, anonymousAccountToJson } from './serializers';

export async function bootstrapAdmin(request: Request, env: Env): Promise<Response> {
  const count = await countRows(env.DB, 'SELECT COUNT(*) AS count FROM admins');
  if (count > 0) throw new HttpError(409, 'Admin already exists');
  const body = await readJson(request);
  const email = requireString(body.email, 'email').toLowerCase();
  const password = requireString(body.password, 'password');
  const passwordHash = await hashPassword(password);
  const id = crypto.randomUUID();
  await env.DB.prepare(
    `INSERT INTO admins (id, email, password_hash, scope_names)
     VALUES (?, ?, ?, ?)`,
  ).bind(id, email, passwordHash, JSON.stringify(['admin', 'user'])).run();
  const user = await getAdminById(env.DB, id);
  return json(await createAdminSession(env.DB, user!));
}

export async function loginAdmin(request: Request, env: Env): Promise<Response> {
  const body = await readJson(request);
  const email = requireString(body.email, 'email').toLowerCase();
  const password = requireString(body.password, 'password');
  const row = await env.DB.prepare(
    `SELECT id, email, password_hash, scope_names, blocked, created_at
     FROM admins WHERE email = ?`,
  ).bind(email).first<{
    id: string;
    email: string;
    password_hash: string;
    scope_names: string;
    blocked: number;
    created_at: string;
  }>();
  if (!row || row.blocked || !(await verifyPassword(password, row.password_hash))) {
    throw new HttpError(401, 'Invalid email or password');
  }
  const user = adminRowToContext(row);
  return json(await createAdminSession(env.DB, user));
}

export async function createAnonymousAccount(request: Request, env: Env): Promise<Response> {
  const body = await readJson(request, true);
  const displayName =
    typeof body.displayName === 'string' && body.displayName.trim().length > 0
      ? body.displayName.trim()
      : null;
  const token = randomToken();
  const tokenHash = await sha256Hex(token);
  const id = crypto.randomUUID();
  const now = nowIso();
  await env.DB.prepare(
    `INSERT INTO anonymous_accounts (id, token_hash, display_name, created_at, last_seen_at)
     VALUES (?, ?, ?, ?, ?)`,
  ).bind(id, tokenHash, displayName, now, now).run();
  return json({
    account: anonymousAccountToJson({ id, displayName, createdAt: now, lastSeenAt: now }),
    token,
  }, 201);
}

export async function requireAdmin(request: Request, env: Env): Promise<AdminContext> {
  const token = bearerToken(request);
  if (!token) throw new HttpError(401, 'Admin authentication required');
  const tokenHash = await sha256Hex(token);
  const row = await env.DB.prepare(
    `SELECT a.id, a.email, a.scope_names, a.blocked, a.created_at
     FROM admin_sessions s
     JOIN admins a ON a.id = s.admin_id
     WHERE s.token_hash = ? AND s.expires_at > ?`,
  ).bind(tokenHash, nowIso()).first<AdminRow>();
  if (!row || row.blocked) throw new HttpError(401, 'Admin authentication required');
  const admin = adminRowToContext(row);
  if (!admin.scopeNames.includes('admin')) throw new HttpError(403, 'Admin scope required');
  return admin;
}

export async function requireAnonymous(request: Request, env: Env): Promise<AnonymousContext> {
  const token = bearerToken(request);
  if (!token) throw new HttpError(401, 'Anonymous account required');
  const tokenHash = await sha256Hex(token);
  const row = await env.DB.prepare(
    `SELECT id, display_name, created_at, last_seen_at
     FROM anonymous_accounts
     WHERE token_hash = ?`,
  ).bind(tokenHash).first<AnonymousAccountRow>();
  if (!row) throw new HttpError(401, 'Anonymous account required');
  return {
    id: row.id,
    displayName: row.display_name,
    createdAt: row.created_at,
    lastSeenAt: row.last_seen_at,
  };
}

async function createAdminSession(db: D1Database, user: AdminContext) {
  const token = randomToken();
  await db.prepare(
    `INSERT INTO admin_sessions (token_hash, admin_id, expires_at)
     VALUES (?, ?, ?)`,
  ).bind(
    await sha256Hex(token),
    user.id,
    new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
  ).run();
  return { token, user: adminContextToJson(user) };
}

export async function getAdminById(db: D1Database, id: string): Promise<AdminContext | null> {
  const row = await db.prepare(
    `SELECT id, email, scope_names, blocked, created_at FROM admins WHERE id = ?`,
  ).bind(id).first<AdminRow>();
  return row ? adminRowToContext(row) : null;
}
