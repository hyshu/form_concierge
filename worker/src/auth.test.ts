import assert from 'node:assert/strict';
import test from 'node:test';

import { ROLE_SCOPES } from './permissions';
import { hasScope, requireScope } from './permissions';
import type { AdminContext } from './types';
import { assertHttpError } from '../test/helpers';

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
