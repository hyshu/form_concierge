import assert from 'node:assert/strict';
import test from 'node:test';

import { assertBadRequest, assertBadRequestAsync, assertHttpErrorAsync } from '../test/helpers';
import {
  boolToInt,
  countRows,
  integerParam,
  logError,
  logWarn,
  normalizeQuestionType,
  optionalBoolean,
  optionalInteger,
  optionalIntegerParam,
  optionalString,
  readJson,
  requireObject,
  requireNumberList,
  requiredBoolean,
  requiredInteger,
  requiredIntegerParam,
} from './utils';

test('readJson accepts object bodies only', async () => {
  assert.deepEqual(
    await readJson(new Request('https://example.com', {
      method: 'POST',
      body: '{"name":"Ada"}',
    })),
    { name: 'Ada' },
  );
  await assertBadRequestAsync(
    () => readJson(new Request('https://example.com', { method: 'POST', body: '[]' })),
    'JSON body must be an object',
  );
  await assertBadRequestAsync(
    () => readJson(new Request('https://example.com', { method: 'POST', body: '"text"' })),
    'JSON body must be an object',
  );
  await assertBadRequestAsync(
    () => readJson(new Request('https://example.com', { method: 'POST', body: '{' })),
    'Invalid JSON body',
  );
});

test('readJson handles optional empty bodies', async () => {
  assert.deepEqual(
    await readJson(new Request('https://example.com', { method: 'POST' }), true),
    {},
  );
  await assertBadRequestAsync(
    () => readJson(new Request('https://example.com', { method: 'POST' })),
    'JSON body required',
  );
});

test('readJson rejects oversized JSON bodies before parsing', async () => {
  const largeBody = JSON.stringify({ value: 'x'.repeat(1024 * 1024) });
  await assertHttpErrorAsync(
    () => readJson(new Request('https://example.com', { method: 'POST', body: largeBody })),
    413,
    'JSON body too large',
  );
  await assertHttpErrorAsync(
    () => readJson(new Request('https://example.com', {
      method: 'POST',
      headers: { 'content-length': `${1024 * 1024 + 1}` },
    })),
    413,
    'JSON body too large',
  );
  await assertBadRequestAsync(
    () => readJson(new Request('https://example.com', {
      method: 'POST',
      headers: { 'content-length': '1.5' },
    })),
    'Invalid Content-Length',
  );
});

test('requireObject rejects non-object values', () => {
  assert.deepEqual(requireObject({ name: 'Ada' }, 'profile'), { name: 'Ada' });
  assertBadRequest(() => requireObject(null, 'profile'), 'profile must be an object');
  assertBadRequest(() => requireObject([], 'profile'), 'profile must be an object');
  assertBadRequest(() => requireObject('name', 'profile'), 'profile must be an object');
});

test('countRows rejects missing or non-numeric count results', async () => {
  assert.equal(await countRows(d1CountResult({ count: 2 }), 'SELECT COUNT(*) AS count'), 2);
  await assertHttpErrorAsync(
    () => countRows(d1CountResult(null), 'SELECT COUNT(*) AS count'),
    500,
    'Count query failed',
  );
  await assertHttpErrorAsync(
    () => countRows(d1CountResult({ count: '2' }), 'SELECT COUNT(*) AS count'),
    500,
    'Count query failed',
  );
});

test('structured log helpers emit JSON entries', () => {
  const errorLogs = captureConsoleError(() => {
    logError('test_error', new Error('boom'), { surveyId: 7 });
  });
  assert.equal(errorLogs.length, 1);
  const errorEntry = JSON.parse(errorLogs[0]) as {
    level: string;
    event: string;
    surveyId: number;
    error: { name: string; message: string; stack: string };
  };
  assert.equal(errorEntry.level, 'error');
  assert.equal(errorEntry.event, 'test_error');
  assert.equal(errorEntry.surveyId, 7);
  assert.equal(errorEntry.error.name, 'Error');
  assert.equal(errorEntry.error.message, 'boom');
  assert.match(errorEntry.error.stack, /Error: boom/);

  const warnLogs = captureConsoleWarn(() => {
    logWarn('test_warn', { responseId: 11 });
  });
  assert.equal(warnLogs.length, 1);
  assert.deepEqual(JSON.parse(warnLogs[0]), {
    level: 'warn',
    event: 'test_warn',
    responseId: 11,
  });
});

test('optionalIntegerParam returns null for missing values', () => {
  assert.equal(optionalIntegerParam(null, 'limit'), null);
  assert.equal(optionalIntegerParam('', 'limit'), null);
  assert.equal(optionalIntegerParam('   ', 'limit'), null);
});

test('optionalIntegerParam accepts decimal integer syntax only', () => {
  assert.equal(optionalIntegerParam('42', 'limit'), 42);
  assert.equal(optionalIntegerParam('-2', 'offset'), -2);
  assertBadRequest(() => optionalIntegerParam(' 42 ', 'limit'), 'limit must be an integer');
  assertBadRequest(() => optionalIntegerParam('1.5', 'limit'), 'limit must be an integer');
  assertBadRequest(() => optionalIntegerParam('1e2', 'limit'), 'limit must be an integer');
  assertBadRequest(() => optionalIntegerParam('Infinity', 'limit'), 'limit must be an integer');
  assertBadRequest(() => optionalIntegerParam('9007199254740992', 'limit'), 'limit must be a safe integer');
});

test('optionalInteger validates JSON body values without numeric coercion', () => {
  assert.equal(optionalInteger(9, 'questionId', { min: 1 }), 9);
  assertBadRequest(() => optionalInteger('9', 'questionId', { min: 1 }), 'questionId must be an integer');
  assertBadRequest(() => optionalInteger('', 'questionId'), 'questionId must be an integer');
  assertBadRequest(() => optionalInteger(1.5, 'questionId'), 'questionId must be an integer');
  assertBadRequest(() => optionalInteger(false, 'questionId'), 'questionId must be an integer');
  assertBadRequest(() => optionalInteger(0, 'questionId', { min: 1 }), 'questionId must be at least 1');
});

test('optionalString rejects coerced values', () => {
  assert.equal(optionalString(null, 'startsAt'), null);
  assert.equal(optionalString('', 'startsAt'), null);
  assert.equal(optionalString(' 2026-01-01 ', 'startsAt'), '2026-01-01');
  assertBadRequest(() => optionalString(7, 'startsAt'), 'startsAt must be a string');
  assertBadRequest(() => optionalString(false, 'value'), 'value must be a string');
});

test('integerParam applies defaults and inclusive bounds', () => {
  assert.equal(integerParam(null, 'limit', 50, { min: 1, max: 100 }), 50);
  assert.equal(integerParam('100', 'limit', 50, { min: 1, max: 100 }), 100);
  assertBadRequest(() => integerParam('0', 'limit', 50, { min: 1 }), 'limit must be at least 1');
  assertBadRequest(() => integerParam('101', 'limit', 50, { max: 100 }), 'limit must be at most 100');
});

test('requiredIntegerParam rejects omitted path ids', () => {
  assert.equal(requiredIntegerParam('7', 'surveyId', { min: 1 }), 7);
  assertBadRequest(() => requiredIntegerParam(undefined, 'surveyId'), 'surveyId is required');
});

test('requiredInteger rejects omitted body ids', () => {
  assert.equal(requiredInteger(7, 'surveyId', { min: 1 }), 7);
  assertBadRequest(() => requiredInteger(null, 'surveyId'), 'surveyId is required');
});

test('boolean helpers reject coerced values', () => {
  assert.equal(optionalBoolean(null, 'enabled'), null);
  assert.equal(optionalBoolean(true, 'enabled'), true);
  assert.equal(requiredBoolean(false, 'enabled'), false);
  assert.equal(boolToInt(true), 1);
  assert.equal(boolToInt(false), 0);
  assertBadRequest(() => optionalBoolean('true', 'enabled'), 'enabled must be a boolean');
  assertBadRequest(() => optionalBoolean(1, 'enabled'), 'enabled must be a boolean');
  assertBadRequest(() => requiredBoolean(undefined, 'enabled'), 'enabled is required');
});

test('requireNumberList validates arrays as strict integer lists', () => {
  assert.deepEqual(requireNumberList([1, 2], 'choiceIds', { min: 1 }), [1, 2]);
  assertBadRequest(() => requireNumberList('1,2', 'choiceIds'), 'choiceIds must be an array');
  assertBadRequest(() => requireNumberList(['1'], 'choiceIds', { min: 1 }), 'choiceIds[0] must be an integer');
  assertBadRequest(() => requireNumberList([true], 'choiceIds', { min: 1 }), 'choiceIds[0] must be an integer');
  assertBadRequest(() => requireNumberList([1.5], 'choiceIds', { min: 1 }), 'choiceIds[0] must be an integer');
  assertBadRequest(() => requireNumberList([0], 'choiceIds', { min: 1 }), 'choiceIds[0] must be at least 1');
});

test('normalizeQuestionType rejects coerced values', () => {
  assert.equal(normalizeQuestionType('textSingle'), 'textSingle');
  assertBadRequest(() => normalizeQuestionType(1), 'Invalid question type');
  assertBadRequest(
    () => normalizeQuestionType({ toString: () => 'textSingle' }),
    'Invalid question type',
  );
});

function captureConsoleError(action: () => void): string[] {
  const original = console.error;
  const messages: string[] = [];
  console.error = (...args: unknown[]) => {
    messages.push(args.map(String).join(' '));
  };
  try {
    action();
    return messages;
  } finally {
    console.error = original;
  }
}

function captureConsoleWarn(action: () => void): string[] {
  const original = console.warn;
  const messages: string[] = [];
  console.warn = (...args: unknown[]) => {
    messages.push(args.map(String).join(' '));
  };
  try {
    action();
    return messages;
  } finally {
    console.warn = original;
  }
}

function d1CountResult(row: Record<string, unknown> | null): D1Database {
  return {
    prepare() {
      return {
        bind() {
          return this;
        },
        async first<T>() {
          return row as T | null;
        },
      } as D1PreparedStatement;
    },
  } as unknown as D1Database;
}
