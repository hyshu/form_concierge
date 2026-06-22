import assert from 'node:assert/strict';
import test from 'node:test';

import { hashPassword, verifyPassword } from './crypto';

test('verifyPassword accepts hashes created by hashPassword', async () => {
  const stored = await hashPassword('correct horse battery staple');

  assert.equal(await verifyPassword('correct horse battery staple', stored), true);
  assert.equal(await verifyPassword('wrong password', stored), false);
});

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
