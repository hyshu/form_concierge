import type { AdminContext } from './types';
import { HttpError } from './utils';

/**
 * Permission scopes granted by each administrator role.
 */
export const ROLE_SCOPES: Record<string, string[]> = {
  admin: ['admin', 'survey:read', 'survey:write', 'response:read', 'response:write', 'user:manage'],
  editor: ['survey:read', 'survey:write', 'response:read', 'response:write'],
  viewer: ['survey:read', 'response:read'],
};

/**
 * Returns the permission scopes assigned to a supported role.
 */
export function scopesForRole(role: string): string[] {
  const scopes = ROLE_SCOPES[role];
  if (!scopes) throw new HttpError(400, 'Invalid role');
  return scopes;
}

/**
 * Resolves the administrator role represented by a set of permission scopes.
 */
export function roleFromScopes(scopes: readonly string[]): string {
  if (scopes.includes('admin')) return 'admin';
  if (scopes.includes('survey:write') || scopes.includes('response:write')) return 'editor';
  return 'viewer';
}

/**
 * Returns whether the administrator has the requested permission scope.
 */
export function hasScope(admin: AdminContext, scope: string): boolean {
  return admin.scopeNames.includes('admin') || admin.scopeNames.includes(scope);
}

/**
 * Rejects the operation unless the administrator has the requested permission scope.
 */
export function requireScope(admin: AdminContext, scope: string): void {
  if (!hasScope(admin, scope)) throw new HttpError(403, 'Insufficient permissions');
}
