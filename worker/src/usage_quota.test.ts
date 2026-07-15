import assert from 'node:assert/strict';
import test from 'node:test';

import { d1Database, d1Result } from '../test/helpers';
import { reserveQuota, reserveQuotas, utcDay } from './usage_quota';

test('reserveQuota accepts a reservation when D1 returns the new usage', async () => {
  const db = d1Database(
    () =>
      ({
        bind() {
          return this;
        },
        async first<T>() {
          return { used: 1 } as T;
        },
      }) as D1PreparedStatement,
  );

  await reserveQuota(db, {
    subject: 'account:1',
    resource: 'responses',
    period: utcDay(),
    amount: 1,
    limit: 10,
    message: 'Limit reached.',
  });
});

test('reserveQuota rejects atomically when D1 cannot increment usage', async () => {
  const db = d1Database(
    () =>
      ({
        bind() {
          return this;
        },
        async first() {
          return null;
        },
      }) as D1PreparedStatement,
  );

  await assert.rejects(
    reserveQuota(db, {
      subject: 'account:1',
      resource: 'responses',
      period: utcDay(),
      amount: 1,
      limit: 10,
      message: 'Limit reached.',
    }),
    (error: unknown) => error instanceof Error && error.message === 'Limit reached.',
  );
});

test('reserveQuotas refunds earlier reservations when a later limit is reached', async () => {
  let reservations = 0;
  let refunds = 0;
  const db = d1Database(
    (sql) =>
      ({
        bind() {
          return this;
        },
        async first<T>() {
          reservations += 1;
          return (reservations === 1 ? { used: 1 } : null) as T | null;
        },
        async run<T>() {
          assert.match(sql, /^UPDATE usage_quotas/);
          refunds += 1;
          return d1Result<T>([]);
        },
      }) as D1PreparedStatement,
  );

  const base = { resource: 'responses', period: utcDay(), amount: 1, limit: 10, message: 'Limit reached.' };
  await assert.rejects(
    reserveQuotas(db, [
      { ...base, subject: 'account:1' },
      { ...base, subject: 'survey:1' },
    ]),
  );
  assert.equal(refunds, 1);
});
