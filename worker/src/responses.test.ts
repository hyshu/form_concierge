import assert from 'node:assert/strict';
import test from 'node:test';

import type { AnswerRow, QuestionRow } from './types';
import { HttpError } from './utils';
import { formatAnswerForCsv, incrementChoiceCount } from './responses';

test('incrementChoiceCount rejects unknown choice ids', () => {
  const counts = { '1': 0 };
  incrementChoiceCount(counts, 1);
  assert.deepEqual(counts, { '1': 1 });

  assertHttpError(
    () => incrementChoiceCount(counts, 2),
    500,
    'Unknown choice id 2',
  );
});

test('formatAnswerForCsv rejects missing choice text', () => {
  assert.equal(
    formatAnswerForCsv(
      question({ id: 10, type: 'multipleChoice' }),
      answer({ question_id: 10, selected_choice_ids: '[1]' }),
      new Map([[1, 'Yes']]),
    ),
    'Yes',
  );

  assertHttpError(
    () => formatAnswerForCsv(
      question({ id: 10, type: 'multipleChoice' }),
      answer({ question_id: 10, selected_choice_ids: '[2]' }),
      new Map([[1, 'Yes']]),
    ),
    500,
    'Unknown choice id 2',
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

function answer(overrides: Partial<AnswerRow>): AnswerRow {
  return {
    id: 1,
    survey_response_id: 1,
    question_id: 1,
    text_value: null,
    selected_choice_ids: null,
    ...overrides,
  };
}

function assertHttpError(
  action: () => unknown,
  status: number,
  message: string,
): void {
  assert.throws(action, (error: unknown) =>
    error instanceof HttpError &&
    error.status === status &&
    error.message === message,
  );
}
