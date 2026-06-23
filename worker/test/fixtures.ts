import type { QuestionRow } from '../src/types';

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
