import assert from 'node:assert/strict';
import test from 'node:test';

import { questionRow } from '../test/fixtures';
import { assertHttpError } from '../test/helpers';
import { formatAnswerForCsv, incrementChoiceCount } from './responses';
import type { AnswerRow } from './types';

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
      questionRow({ id: 10, type: 'multipleChoice' }),
      answer({ question_id: 10, selected_choice_ids: '[1]' }),
      new Map([[1, 'Yes']]),
    ),
    'Yes',
  );

  assertHttpError(
    () => formatAnswerForCsv(
      questionRow({ id: 10, type: 'multipleChoice' }),
      answer({ question_id: 10, selected_choice_ids: '[2]' }),
      new Map([[1, 'Yes']]),
    ),
    500,
    'Unknown choice id 2',
  );
});

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
