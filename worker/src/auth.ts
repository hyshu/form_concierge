import type { AdminContext, AdminRow, AnonymousAccountRow, AnonymousContext, Env } from './types';
import { HttpError, bearerToken, json, nowIso, optionalLimitedString, readJson, requireEmail, requireString } from './utils';
import { hashPassword, randomToken, sha256Hex, verifyPassword } from './crypto';
import { adminContextToJson, adminRowToContext, anonymousAccountToJson } from './serializers';
import { clientIp, consumeRateLimit } from './rate_limit';

const MIN_PASSWORD_LENGTH = 8;
const DISPLAY_NAME_MAX_LENGTH = 160;
/** Skip last_seen_at writes unless older than this (reply polling is high-frequency). */
const LAST_SEEN_THROTTLE_MS = 5 * 60 * 1000;
const LOGIN_RATE_LIMIT = 20;
const LOGIN_RATE_WINDOW_MS = 15 * 60 * 1000;
const ANON_CREATE_RATE_LIMIT = 30;
const ANON_CREATE_RATE_WINDOW_MS = 60 * 60 * 1000;
const BOOTSTRAP_SCOPES = JSON.stringify([
  'admin',
  'survey:read',
  'survey:write',
  'response:read',
  'response:write',
  'user:manage',
]);

export async function bootstrapAdmin(request: Request, env: Env): Promise<Response> {
  const body = await readJson(request);
  // Same validation as createUser — bootstrap must not allow weak credentials.
  const email = requireEmail(body.email, 'email');
  const password = requireString(body.password, 'password');
  if (password.length < MIN_PASSWORD_LENGTH) {
    throw new HttpError(400, `password must be at least ${MIN_PASSWORD_LENGTH} characters`);
  }
  const passwordHash = await hashPassword(password);
  const id = crypto.randomUUID();
  // Atomic "first admin only": INSERT...WHERE NOT EXISTS closes the COUNT→INSERT
  // TOCTOU window that could create two bootstrap admins under concurrency.
  const row = await env.DB.prepare(
    `INSERT INTO admins (id, email, password_hash, scope_names)
     SELECT ?, ?, ?, ?
     WHERE NOT EXISTS (SELECT 1 FROM admins LIMIT 1)
     RETURNING id, email, scope_names, created_at`,
  ).bind(id, email, passwordHash, BOOTSTRAP_SCOPES).first<AdminRow>();
  if (!row) throw new HttpError(409, 'Admin already exists');
  const user = adminRowToContext(row);
  return json(await createAdminSession(env.DB, user));
}

export async function loginAdmin(request: Request, env: Env): Promise<Response> {
  const body = await readJson(request);
  const email = requireString(body.email, 'email').toLowerCase();
  const password = requireString(body.password, 'password');
  consumeRateLimit(
    `login:${clientIp(request)}:${email}`,
    LOGIN_RATE_LIMIT,
    LOGIN_RATE_WINDOW_MS,
    'Too many login attempts. Try again later.',
  );
  const row = await env.DB.prepare(
    `SELECT id, email, password_hash, scope_names, created_at
     FROM admins WHERE email = ?`,
  ).bind(email).first<{
    id: string;
    email: string;
    password_hash: string;
    scope_names: string;
    created_at: string;
  }>();
  if (!row || !(await verifyPassword(password, row.password_hash))) {
    throw new HttpError(401, 'Invalid email or password');
  }
  const user = adminRowToContext(row);
  return json(await createAdminSession(env.DB, user));
}

export async function createAnonymousAccount(request: Request, env: Env): Promise<Response> {
  consumeRateLimit(
    `anon-create:${clientIp(request)}`,
    ANON_CREATE_RATE_LIMIT,
    ANON_CREATE_RATE_WINDOW_MS,
    'Too many anonymous accounts created. Try again later.',
  );
  const body = await readJson(request, true);
  const displayName = optionalLimitedString(body.displayName, 'displayName', DISPLAY_NAME_MAX_LENGTH);
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
  const now = nowIso();
  const row = await env.DB.prepare(
    `SELECT a.id, a.email, a.scope_names, a.created_at
     FROM admin_sessions s
     JOIN admins a ON a.id = s.admin_id
     WHERE s.token_hash = ? AND s.expires_at > ?`,
  ).bind(tokenHash, now).first<AdminRow>();
  if (!row) throw new HttpError(401, 'Admin authentication required');
  // Scope checks are done per-route via requireScope (editor/viewer lack "admin").
  return adminRowToContext(row);
}

export async function logoutAdmin(request: Request, env: Env): Promise<Response> {
  const token = bearerToken(request);
  if (!token) throw new HttpError(401, 'Admin authentication required');
  const tokenHash = await sha256Hex(token);
  const now = nowIso();
  await env.DB.batch([
    env.DB.prepare(`DELETE FROM admin_sessions WHERE token_hash = ?`).bind(tokenHash),
    env.DB.prepare(`DELETE FROM admin_sessions WHERE expires_at <= ?`).bind(now),
  ]);
  return json({ ok: true });
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
  const now = nowIso();
  const lastSeenMs = Date.parse(row.last_seen_at);
  const shouldTouch =
    !Number.isFinite(lastSeenMs) || Date.now() - lastSeenMs >= LAST_SEEN_THROTTLE_MS;
  if (shouldTouch) {
    await env.DB.prepare(
      `UPDATE anonymous_accounts SET last_seen_at = ? WHERE id = ?`,
    ).bind(now, row.id).run();
  }
  return {
    id: row.id,
    displayName: row.display_name,
    createdAt: row.created_at,
    lastSeenAt: shouldTouch ? now : row.last_seen_at,
  };
}

async function createAdminSession(db: D1Database, user: AdminContext) {
  const token = randomToken();
  const now = nowIso();
  // Opportunistically prune expired sessions so the table does not grow unbounded.
  await db.batch([
    db.prepare(`DELETE FROM admin_sessions WHERE expires_at <= ?`).bind(now),
    db.prepare(
      `INSERT INTO admin_sessions (token_hash, admin_id, expires_at)
       VALUES (?, ?, ?)`,
    ).bind(
      await sha256Hex(token),
      user.id,
      new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
    ),
  ]);
  return { token, user: adminContextToJson(user) };
}

export async function getAdminById(db: D1Database, id: string): Promise<AdminContext | null> {
  const row = await db.prepare(
    `SELECT id, email, scope_names, created_at FROM admins WHERE id = ?`,
  ).bind(id).first<AdminRow>();
  return row ? adminRowToContext(row) : null;
}
