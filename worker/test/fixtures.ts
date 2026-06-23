import type {
  AdminRow,
  AnswerRow,
  ProjectRow,
  QuestionRow,
  ResponseRow,
  VisibilityRuleRow,
} from '../src/types';

export function adminRow(overrides: Partial<AdminRow> = {}): AdminRow {
  return {
    id: 'admin-1',
    email: 'ada@example.com',
    scope_names: '[]',
    created_at: '2026-01-01T00:00:00.000Z',
    ...overrides,
  };
}

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

export function projectRow(overrides: Partial<ProjectRow> = {}): ProjectRow {
  return {
    id: 1,
    slug: 'demo',
    custom_domain: null,
    default_locale: 'en',
    supported_locales: '["en"]',
    name: 'Demo',
    created_by_admin_id: 'admin-1',
    created_at: '2026-01-01T00:00:00.000Z',
    updated_at: '2026-01-01T00:00:00.000Z',
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

export function responseRow(overrides: Partial<ResponseRow> = {}): ResponseRow {
  return {
    id: 1,
    survey_id: 1,
    anonymous_account_id: 'anon-account-1',
    anonymous_id: null,
    submitted_at: '2026-01-01T00:00:00.000Z',
    user_agent: null,
    device_id: null,
    device_label: null,
    device_platform: null,
    device_os: null,
    device_os_version: null,
    device_browser: null,
    device_browser_version: null,
    device_locale: null,
    device_timezone: null,
    screen_width: null,
    screen_height: null,
    device_pixel_ratio: null,
    device_info: null,
    metadata: null,
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
