import assert from 'node:assert/strict';
import test from 'node:test';

import type { QuestionRow, VisibilityRuleRow } from './types';
import { HttpError } from './utils';
import { normalizeRuleInput, visibleQuestionIds } from './visibility_rules';

test('visibleQuestionIds evaluates choice rules with strict selected ids', () => {
  const visible = visibleQuestionIds(
    [
      question({ id: 1, type: 'singleChoice', order_index: 0 }),
      question({ id: 2, type: 'textSingle', order_index: 1 }),
    ],
    [rule({ source_question_id: 1, target_question_id: 2, value_json: '5' })],
    [{ questionId: 1, selectedChoiceIds: [5] }],
  );

  assert.deepEqual([...visible], [1, 2]);
});

test('visibleQuestionIds rejects coerced selected choice ids', () => {
  assertHttpError(
    () => visibleQuestionIds(
      [
        question({ id: 1, type: 'singleChoice', order_index: 0 }),
        question({ id: 2, type: 'textSingle', order_index: 1 }),
      ],
      [rule({ source_question_id: 1, target_question_id: 2, value_json: '100' })],
      [{ questionId: 1, selectedChoiceIds: ['1e2'] }],
    ),
    'selectedChoiceIds must be an integer',
  );
});

test('visibleQuestionIds rejects non-string text rule values', () => {
  assertHttpError(
    () => visibleQuestionIds(
      [
        question({ id: 1, type: 'textSingle', order_index: 0 }),
        question({ id: 2, type: 'textSingle', order_index: 1 }),
      ],
      [rule({ source_question_id: 1, target_question_id: 2, value_json: '7' })],
      [{ questionId: 1, textValue: '7' }],
    ),
    500,
    'Invalid visibility rule value for rule 1',
  );
});

test('normalizeRuleInput rejects coerced operators', () => {
  assertHttpError(
    () => normalizeRuleInput({
      targetQuestionId: 2,
      sourceQuestionId: 1,
      operator: 1,
      value: null,
    }),
    'Invalid visibility operator',
  );
});

function question(overrides: Partial<QuestionRow>): QuestionRow {
  return {
    id: 0,
    survey_id: 1,
    text_translations: '{"en":"Question"}',
    type: 'textSingle',
    order_index: 0,
    is_required: 0,
    placeholder_translations: '{}',
    min_length: null,
    max_length: null,
    min_selected: null,
    max_selected: null,
    visibility_condition_mode: 'all',
    is_deleted: 0,
    ...overrides,
  };
}

function rule(overrides: Partial<VisibilityRuleRow>): VisibilityRuleRow {
  return {
    id: 1,
    survey_id: 1,
    target_question_id: 2,
    source_question_id: 1,
    operator: 'equals',
    value_json: null,
    created_at: '2026-06-22T00:00:00.000Z',
    updated_at: '2026-06-22T00:00:00.000Z',
    ...overrides,
  };
}

function assertHttpError(
  action: () => unknown,
  statusOrMessage: number | string,
  maybeMessage?: string,
): void {
  const status = typeof statusOrMessage === 'number' ? statusOrMessage : 400;
  const message = maybeMessage ?? statusOrMessage;
  assert.throws(action, (error: unknown) =>
    error instanceof HttpError &&
    error.status === status &&
    error.message === message,
  );
}
