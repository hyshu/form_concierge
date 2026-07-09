import assert from 'node:assert/strict';
import test from 'node:test';

import { hashPassword, verifyPassword } from './crypto';

test('verifyPassword accepts hashes created by hashPassword', async () => {
  const stored = await hashPassword('correct horse battery staple');

  assert.equal(await verifyPassword('correct horse battery staple', stored), true);
  assert.equal(await verifyPassword('wrong password', stored), false);
});

test('verifyPassword uses the iteration count stored with the hash', async () => {
  const current = await hashPassword('legacy password');
  const [algorithm, , salt] = current.split(':');
  const saltBytes = base64UrlDecode(salt);
  assert.ok(saltBytes);
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode('legacy password'),
    'PBKDF2',
    false,
    ['deriveBits'],
  );
  const bits = await crypto.subtle.deriveBits(
    { name: 'PBKDF2', hash: 'SHA-256', salt: saltBytes, iterations: 120000 },
    key,
    32 * 8,
  );
  const legacyStored = `${algorithm}:120000:${salt}:${base64UrlEncode(new Uint8Array(bits))}`;
  assert.equal(await verifyPassword('legacy password', legacyStored), true);
  assert.equal(await verifyPassword('wrong', legacyStored), false);
  assert.equal(await verifyPassword('legacy password', current), true);
});

function base64UrlEncode(bytes: Uint8Array): string {
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function base64UrlDecode(value: string): Uint8Array | null {
  if (!/^[A-Za-z0-9_-]+$/.test(value) || value.length % 4 === 1) return null;
  const padded = value.replace(/-/g, '+').replace(/_/g, '/').padEnd(Math.ceil(value.length / 4) * 4, '=');
  try {
    return Uint8Array.from(atob(padded), (char) => char.charCodeAt(0));
  } catch {
    return null;
  }
}

test('verifyPassword rejects malformed stored hashes without throwing', async () => {
  const stored = await hashPassword('password');
  const [algorithm, iterations, salt, hash] = stored.split(':');
  assert.ok(algorithm);
  assert.ok(iterations);
  assert.ok(salt);
  assert.ok(hash);

  const malformedHashes = [
    '',
    `${algorithm}:${iterations}:${salt}`,
    `${algorithm}:${iterations}:${salt}:${hash}:extra`,
    `bcrypt:${iterations}:${salt}:${hash}`,
    `${algorithm}:1e5:${salt}:${hash}`,
    `${algorithm}:100001:${salt}:${hash}`,
    `${algorithm}:${iterations}:!!!!:${hash}`,
    `${algorithm}:${iterations}:A:${hash}`,
    `${algorithm}:${iterations}:${salt}:!!!!`,
    `${algorithm}:${iterations}:${salt}:A`,
  ];

  for (const malformed of malformedHashes) {
    assert.equal(await verifyPassword('password', malformed), false, malformed);
  }
});
