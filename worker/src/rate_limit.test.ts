import assert from 'node:assert/strict';
import test from 'node:test';

import { assertHttpErrorAsync } from '../test/helpers';
import {
  checkRateLimit,
  clientIp,
  consumeRateLimit,
  resetRateLimitsForTests,
} from './rate_limit';
import { HttpError } from './utils';

test('consumeRateLimit throws 429 once the limit is exceeded', () => {
  resetRateLimitsForTests();
  const windowMs = 60_000;
  consumeRateLimit('key-a', 2, windowMs);
  consumeRateLimit('key-a', 2, windowMs);
  assert.throws(
    () => consumeRateLimit('key-a', 2, windowMs),
    (error: unknown) =>
      error instanceof HttpError &&
      error.status === 429 &&
      error.message === 'Too many requests. Try again later.',
  );
});

test('consumeRateLimit tracks keys independently', () => {
  resetRateLimitsForTests();
  consumeRateLimit('key-a', 1, 60_000);
  assert.doesNotThrow(() => consumeRateLimit('key-b', 1, 60_000));
});

test('consumeRateLimit resets after the window expires', (t) => {
  resetRateLimitsForTests();
  const realNow = Date.now;
  t.after(() => {
    Date.now = realNow;
    resetRateLimitsForTests();
  });
  let now = 1_000_000;
  Date.now = () => now;
  consumeRateLimit('key-a', 1, 1_000);
  now += 1_001;
  assert.doesNotThrow(() => consumeRateLimit('key-a', 1, 1_000));
});

test('consumeRateLimit uses a custom message when provided', () => {
  resetRateLimitsForTests();
  consumeRateLimit('key-a', 1, 60_000);
  assert.throws(
    () => consumeRateLimit('key-a', 1, 60_000, 'Too many login attempts.'),
    (error: unknown) =>
      error instanceof HttpError &&
      error.status === 429 &&
      error.message === 'Too many login attempts.',
  );
});

test('checkRateLimit throws 429 when the Workers limiter denies', async () => {
  await assertHttpErrorAsync(
    () => checkRateLimit({ async limit() { return { success: false }; } }, 'key'),
    429,
    'Too many requests. Try again later.',
  );
  await assert.doesNotReject(
    () => checkRateLimit({ async limit() { return { success: true }; } }, 'key'),
  );
});

test('clientIp prefers cf-connecting-ip, then x-forwarded-for, then unknown', () => {
  assert.equal(
    clientIp(requestWithHeaders({ 'cf-connecting-ip': ' 203.0.113.9 ' })),
    '203.0.113.9',
  );
  assert.equal(
    clientIp(requestWithHeaders({ 'x-forwarded-for': '198.51.100.7, 10.0.0.1' })),
    '198.51.100.7',
  );
  assert.equal(clientIp(requestWithHeaders({})), 'unknown');
});

function requestWithHeaders(headers: Record<string, string>): Request {
  return new Request('https://example.com/', { headers });
}
