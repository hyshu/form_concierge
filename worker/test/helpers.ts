import assert from 'node:assert/strict';

import { HttpError } from '../src/utils';

const adminApiBaseUrl = 'https://example.com/api/admin';
const localizedTextLocales = [
  'en',
  'ja',
  'zh-Hans',
  'zh-Hant',
  'ko',
  'de',
  'es',
  'fr',
  'it',
  'th',
  'tr',
] as const;

export function assertHttpError(action: () => unknown, status: number, message: string): void {
  assert.throws(action, (error: unknown) =>
    error instanceof HttpError &&
    error.status === status &&
    error.message === message,
  );
}

export async function assertHttpErrorAsync(
  action: () => Promise<unknown>,
  status: number,
  message: string,
): Promise<void> {
  await assert.rejects(action, (error: unknown) =>
    error instanceof HttpError &&
    error.status === status &&
    error.message === message,
  );
}

export function assertBadRequest(action: () => unknown, message: string): void {
  assertHttpError(action, 400, message);
}

export async function assertBadRequestAsync(
  action: () => Promise<unknown>,
  message: string,
): Promise<void> {
  await assertHttpErrorAsync(action, 400, message);
}

export function adminPostRequest(path: string, body: unknown): Request {
  return adminJsonRequest(path, 'POST', body);
}

export function adminPutRequest(path: string, body: unknown): Request {
  return adminJsonRequest(path, 'PUT', body);
}

export function localizedText(value: string): Record<string, string> {
  return Object.fromEntries(localizedTextLocales.map((locale) => [locale, value]));
}

export function d1Meta(): D1Result<unknown>['meta'] {
  return {
    duration: 0,
    size_after: 0,
    rows_read: 0,
    rows_written: 0,
    last_row_id: 0,
    changed_db: false,
    changes: 0,
  };
}

export function d1Result<T>(results: T[]): D1Result<T> {
  return {
    success: true,
    meta: d1Meta(),
    results,
  };
}

export function emptyD1Result<T>(): D1Result<T> {
  return d1Result<T>([]);
}

export function emptyD1Raw<T = unknown[]>(options: { columnNames: true }): Promise<[string[], ...T[]]>;
export function emptyD1Raw<T = unknown[]>(options?: { columnNames?: false }): Promise<T[]>;
export async function emptyD1Raw(_options?: { columnNames?: boolean }): Promise<unknown[]> {
  return [];
}

export function d1Database(
  prepare: (sql: string) => D1PreparedStatement = () => {
    throw new Error('D1 prepare should not be used by this test');
  },
): D1Database {
  return {
    prepare,
    async batch<T>() {
      return [emptyD1Result<T>()];
    },
    async exec() {
      return { count: 0, duration: 0 };
    },
    withSession() {
      throw new Error('D1 sessions are not used by this test');
    },
    async dump() {
      return new ArrayBuffer(0);
    },
  } satisfies D1Database;
}

export function stubRateLimiter(): RateLimit {
  return { async limit() { return { success: true }; } };
}

function adminJsonRequest(path: string, method: 'POST' | 'PUT', body: unknown): Request {
  return new Request(`${adminApiBaseUrl}/${path}`, {
    method,
    body: JSON.stringify(body),
  });
}
