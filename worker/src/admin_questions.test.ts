import assert from 'node:assert/strict';
import test from 'node:test';

import { normalizeQuestionValidation, normalizeVisibilityConditionMode } from './admin_questions';
import { HttpError } from './utils';

test('normalizeQuestionValidation rejects coerced numeric strings', () => {
  assertHttpError(
    () => normalizeQuestionValidation({ minLength: '1e2' }, 'textSingle'),
    'minLength must be an integer',
  );
});

test('normalizeQuestionValidation keeps integer bounds strict', () => {
  assert.deepEqual(
    normalizeQuestionValidation({ minLength: 1, maxLength: 3 }, 'textSingle'),
    {
      minLength: 1,
      maxLength: 3,
      minSelected: null,
      maxSelected: null,
    },
  );
  assertHttpError(
    () => normalizeQuestionValidation({ minSelected: 2, maxSelected: 1 }, 'multipleChoice'),
    'minSelected cannot be greater than maxSelected',
  );
});

test('normalizeVisibilityConditionMode rejects coerced values', () => {
  assert.equal(normalizeVisibilityConditionMode(undefined), 'all');
  assert.equal(normalizeVisibilityConditionMode('any'), 'any');
  assertHttpError(
    () => normalizeVisibilityConditionMode({ toString: () => 'any' }),
    'Invalid visibility condition mode',
  );
});

function assertHttpError(action: () => unknown, message: string): void {
  assert.throws(action, (error: unknown) =>
    error instanceof HttpError &&
    error.status === 400 &&
    error.message === message,
  );
}
