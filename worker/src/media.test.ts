import assert from 'node:assert/strict';
import test from 'node:test';

import {
  assertOwnedMediaKeys,
  assertValidMediaKey,
  encodeFileKeysForStorage,
  parseStoredFileKeys,
  uploadMedia,
} from './media';
import { assertHttpErrorAsync } from '../test/helpers';
import type { Env } from './types';

const anonymous = {
  id: 'anon-1',
  displayName: null,
  createdAt: '2026-01-01T00:00:00.000Z',
  lastSeenAt: '2026-01-01T00:00:00.000Z',
};

test('assertValidMediaKey accepts owned upload keys', () => {
  assertValidMediaKey('uploads/anon-1/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee.jpg');
});

test('assertValidMediaKey rejects path traversal keys', () => {
  assert.throws(
    () => assertValidMediaKey('uploads/anon-1/../secret.jpg'),
    (error: unknown) => error instanceof Error && error.message === 'Invalid media key',
  );
});

test('assertOwnedMediaKeys rejects foreign prefixes', () => {
  assert.throws(
    () => assertOwnedMediaKeys(
      ['uploads/other/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee.jpg'],
      'anon-1',
    ),
    (error: unknown) =>
      error instanceof Error && error.message === 'Media key does not belong to this account',
  );
});

test('encode/parse file keys round-trips', () => {
  const encoded = encodeFileKeysForStorage([
    'uploads/anon-1/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee.jpg',
  ]);
  assert.deepEqual(parseStoredFileKeys(encoded), [
    'uploads/anon-1/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee.jpg',
  ]);
  assert.equal(parseStoredFileKeys('plain text'), null);
});

test('uploadMedia stores bytes in R2 and returns metadata', async () => {
  const putCalls: Array<{ key: string; type: string; size: number }> = [];
  const env = {
    MEDIA_BUCKET: {
      put: async (key: string, value: ArrayBuffer, options: { httpMetadata?: { contentType?: string } }) => {
        putCalls.push({
          key,
          type: options.httpMetadata?.contentType ?? '',
          size: value.byteLength,
        });
      },
    },
  } as unknown as Env;

  const body = new Uint8Array([0xff, 0xd8, 0xff, 0xd9]).buffer;
  const response = await uploadMedia(
    new Request('http://localhost/api/media', {
      method: 'POST',
      headers: { 'content-type': 'image/jpeg' },
      body,
    }),
    env,
    anonymous,
  );
  assert.equal(response.status, 201);
  const json = await response.json() as { key: string; contentType: string; size: number };
  assert.equal(json.contentType, 'image/jpeg');
  assert.equal(json.size, 4);
  assert.match(json.key, /^uploads\/anon-1\/[a-z0-9-]+\.jpg$/i);
  assert.equal(putCalls.length, 1);
  assert.equal(putCalls[0]?.type, 'image/jpeg');
});

test('uploadMedia rejects unsupported content types', async () => {
  const env = {
    MEDIA_BUCKET: { put: async () => {} },
  } as unknown as Env;

  await assertHttpErrorAsync(
    () => uploadMedia(
      new Request('http://localhost/api/media', {
        method: 'POST',
        headers: { 'content-type': 'application/pdf' },
        body: new Uint8Array([1, 2, 3]),
      }),
      env,
      anonymous,
    ),
    400,
    'Unsupported image type. Use JPEG, PNG, WebP, or GIF',
  );
});
