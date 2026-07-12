import assert from 'node:assert/strict';
import test from 'node:test';

import {
  d1Database,
  stubRateLimiter,
  stubSecretsStoreEnv,
  stubSecretsStoreSecret,
} from '../test/helpers';
import { deleteSecret, tryGetSecret, upsertSecret } from './secrets_store';
import type { Env } from './types';

test('tryGetSecret returns the value or null when the binding fails', async () => {
  assert.equal(await tryGetSecret(stubSecretsStoreSecret('s3cret')), 's3cret');
  assert.equal(await tryGetSecret(stubSecretsStoreSecret()), null);
});

test('upsertSecret PATCHes an existing secret by id', async (t) => {
  const calls = mockFetch(t, [
    listResponse([{ id: 'sec-1', name: 'smtp_password' }]),
    okResponse(),
  ]);
  await upsertSecret(secretsEnv(), 'smtp_password', 'new-value');
  assert.equal(calls.length, 2);
  assert.equal(calls[1].method, 'PATCH');
  assert.ok(calls[1].url.endsWith('/secrets/sec-1'));
  assert.deepEqual(JSON.parse(calls[1].body!), { value: 'new-value' });
});

test('upsertSecret POSTs a new secret with workers scope', async (t) => {
  const calls = mockFetch(t, [listResponse([]), okResponse()]);
  await upsertSecret(secretsEnv(), 'gemini_api_key', 'abc');
  assert.equal(calls[1].method, 'POST');
  assert.deepEqual(JSON.parse(calls[1].body!), {
    name: 'gemini_api_key',
    value: 'abc',
    scopes: ['workers'],
  });
});

test('upsertSecret surfaces Cloudflare API failures', async (t) => {
  mockFetch(t, [listResponse([]), errorResponse(403)]);
  await assert.rejects(
    () => upsertSecret(secretsEnv(), 'gemini_api_key', 'abc'),
    /Secrets Store create failed: 403/,
  );
  mockFetch(t, [errorResponse(500)]);
  await assert.rejects(
    () => upsertSecret(secretsEnv(), 'gemini_api_key', 'abc'),
    /Secrets Store list failed: 500/,
  );
});

test('deleteSecret is a no-op when the secret does not exist', async (t) => {
  const calls = mockFetch(t, [listResponse([])]);
  await deleteSecret(secretsEnv(), 'smtp_password');
  assert.equal(calls.length, 1);
});

test('deleteSecret DELETEs the matching secret and reports failures', async (t) => {
  const calls = mockFetch(t, [
    listResponse([{ id: 'sec-9', name: 'smtp_password' }]),
    okResponse(),
  ]);
  await deleteSecret(secretsEnv(), 'smtp_password');
  assert.equal(calls[1].method, 'DELETE');
  assert.ok(calls[1].url.endsWith('/secrets/sec-9'));

  mockFetch(t, [
    listResponse([{ id: 'sec-9', name: 'smtp_password' }]),
    errorResponse(404),
  ]);
  await assert.rejects(
    () => deleteSecret(secretsEnv(), 'smtp_password'),
    /Secrets Store delete failed: 404/,
  );
});

type RecordedCall = { url: string; method: string; body: string | null };

function mockFetch(
  t: { after: (fn: () => void) => void },
  responses: Response[],
): RecordedCall[] {
  const realFetch = globalThis.fetch;
  t.after(() => {
    globalThis.fetch = realFetch;
  });
  const calls: RecordedCall[] = [];
  const queue = [...responses];
  globalThis.fetch = (async (input: RequestInfo | URL, init?: RequestInit) => {
    calls.push({
      url: String(input),
      method: init?.method ?? 'GET',
      body: typeof init?.body === 'string' ? init.body : null,
    });
    const next = queue.shift();
    if (!next) throw new Error('Unexpected extra fetch call in secrets_store test');
    return next;
  }) as typeof fetch;
  return calls;
}

function listResponse(secrets: { id: string; name: string }[]): Response {
  return new Response(JSON.stringify({ success: true, result: secrets, errors: [] }), {
    headers: { 'content-type': 'application/json' },
  });
}

function okResponse(): Response {
  return new Response(JSON.stringify({ success: true, result: {}, errors: [] }));
}

function errorResponse(status: number): Response {
  return new Response('{}', { status });
}

function secretsEnv(): Env {
  return {
    DB: d1Database(),
    MEDIA_BUCKET: {} as R2Bucket,
    PUBLIC_BASE_URL: 'https://api.example.com',
    PUBLIC_FORM_ASSET_BASE_URL: 'https://assets.example.com',
    LOGIN_RATE_LIMITER: stubRateLimiter(),
    ANON_CREATE_RATE_LIMITER: stubRateLimiter(),
    ...stubSecretsStoreEnv(),
  };
}
