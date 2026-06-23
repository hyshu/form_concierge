import type { AnswerRow, QuestionRow, VisibilityRuleRow } from '../src/types';

export function answerRow(overrides: Partial<AnswerRow> = {}): AnswerRow {
  return {
    id: 1,
    survey_response_id: 1,
    question_id: 1,
    text_value: null,
    selected_choice_ids: null,
    ...overrides,
  };
}

export function questionRow(overrides: Partial<QuestionRow>): QuestionRow {
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

export function visibilityRuleRow(
  overrides: Partial<VisibilityRuleRow> = {},
): VisibilityRuleRow {
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
