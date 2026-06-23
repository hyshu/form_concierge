import assert from 'node:assert/strict';
import test from 'node:test';

import { requireSupportedLocales, parseLocalizedText } from './localization';
import {
  adminRowToContext,
  answerToJson,
  metadataToJson,
  projectToJson,
  responseToJson,
  visibilityRuleToJson,
} from './serializers';
import type { AdminRow, AnswerRow, ProjectRow, ResponseRow, VisibilityRuleRow } from './types';
import { HttpError } from './utils';

test('serializers keep stored JSON arrays strict', () => {
  assert.deepEqual(answerToJson(answerRow('[1,2]')).selectedChoiceIds, [1, 2]);
  assert.deepEqual(adminRowToContext(adminRow('["admin","surveys.read"]')).scopeNames, [
    'admin',
    'surveys.read',
  ]);
  assert.deepEqual(projectToJson(projectRow('["en","ja"]')).supportedLocales, ['en', 'ja']);

  assertHttpError(
    () => answerToJson(answerRow('[1,"2"]')),
    500,
    'selectedChoiceIds[1] must be a safe integer',
  );
  assertHttpError(
    () => adminRowToContext(adminRow('["admin",7]')),
    500,
    'scopeNames[1] must be a string',
  );
  assertHttpError(
    () => projectToJson(projectRow('["en",7]')),
    500,
    'supportedLocales[1] must be a string',
  );
});

test('serializers reject invalid stored JSON instead of defaulting', () => {
  assertHttpError(
    () => answerToJson(answerRow('{')),
    500,
    'Invalid stored JSON: selectedChoiceIds',
  );
  assertHttpError(
    () => metadataToJson('{'),
    500,
    'Invalid stored JSON: metadata',
  );
  assertHttpError(
    () => responseToJson(responseRow({ device_info: '[' })),
    500,
    'Invalid stored JSON: deviceInfo',
  );
  assertHttpError(
    () => visibilityRuleToJson(visibilityRuleRow('{')),
    500,
    'Invalid stored JSON: visibilityRule.value',
  );
  assertHttpError(
    () => projectToJson(projectRow('{')),
    500,
    'Invalid stored JSON: supportedLocales',
  );
});

test('serializers reject stored JSON shape mismatches', () => {
  assert.equal(metadataToJson('{}'), null);
  assert.deepEqual(metadataToJson('{"source":"web"}'), { source: 'web' });
  assertHttpError(
    () => metadataToJson('[]'),
    500,
    'metadata must be an object',
  );
  assertHttpError(
    () => responseToJson(responseRow({ device_info: '[]' })),
    500,
    'deviceInfo must be an object',
  );
  assertHttpError(
    () => answerToJson(answerRow('{"id":1}')),
    500,
    'selectedChoiceIds must be an array',
  );
  assertHttpError(
    () => projectToJson(projectRow('{"en":true}')),
    500,
    'supportedLocales must be an array',
  );
});

test('localized text parsing keeps stored strings strict', () => {
  assert.deepEqual(parseLocalizedText('{"en":"Name"}'), { en: 'Name' });
  assertHttpError(
    () => parseLocalizedText('{"en":7}'),
    500,
    'Invalid localized text for locale: en',
  );
});

test('supported locale request parsing rejects coerced values', () => {
  assert.deepEqual(requireSupportedLocales(['en', 'ja']), ['en', 'ja']);
  assertHttpError(
    () => requireSupportedLocales(['en', 7]),
    400,
    'supportedLocales[1] must be a string',
  );
});

function assertHttpError(action: () => unknown, status: number, message: string): void {
  assert.throws(action, (error: unknown) =>
    error instanceof HttpError &&
    error.status === status &&
    error.message === message,
  );
}

function answerRow(selectedChoiceIds: string | null): AnswerRow {
  return {
    id: 1,
    survey_response_id: 2,
    question_id: 3,
    text_value: null,
    selected_choice_ids: selectedChoiceIds,
  };
}

function adminRow(scopeNames: string): AdminRow {
  return {
    id: 'admin-1',
    email: 'ada@example.com',
    scope_names: scopeNames,
    created_at: '2026-01-01T00:00:00.000Z',
  };
}

function projectRow(
  supportedLocales: string,
  overrides: Partial<ProjectRow> = {},
): ProjectRow {
  return {
    id: 1,
    slug: 'demo',
    custom_domain: null,
    default_locale: 'en',
    supported_locales: supportedLocales,
    name: 'Demo',
    created_by_admin_id: 'admin-1',
    created_at: '2026-01-01T00:00:00.000Z',
    updated_at: '2026-01-01T00:00:00.000Z',
    ...overrides,
  };
}

function responseRow(overrides: Partial<ResponseRow> = {}): ResponseRow {
  return {
    id: 1,
    survey_id: 2,
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

function visibilityRuleRow(valueJson: string | null): VisibilityRuleRow {
  return {
    id: 1,
    survey_id: 2,
    target_question_id: 3,
    source_question_id: 4,
    operator: 'equals',
    value_json: valueJson,
    created_at: '2026-01-01T00:00:00.000Z',
    updated_at: '2026-01-01T00:00:00.000Z',
  };
}
