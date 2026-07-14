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
import {
  adminRow,
  answerRow,
  projectRow,
  responseRow,
  visibilityRuleRow,
} from '../test/fixtures';
import { assertHttpError } from '../test/helpers';

test('serializers keep stored JSON arrays strict', () => {
  assert.deepEqual(
    answerToJson(answerRow({ selected_choice_ids: '[1,2]' })).selectedChoiceIds,
    [1, 2],
  );
  assert.deepEqual(
    adminRowToContext(adminRow({ scope_names: '["admin","surveys.read"]' })).scopeNames,
    ['admin', 'surveys.read'],
  );
  assert.deepEqual(
    projectToJson(projectRow({ supported_locales: '["en","ja"]' })).supportedLocales,
    ['en', 'ja'],
  );

  assertHttpError(
    () => answerToJson(answerRow({ selected_choice_ids: '[1,"2"]' })),
    500,
    'selectedChoiceIds[1] must be a safe integer',
  );
  assertHttpError(
    () => adminRowToContext(adminRow({ scope_names: '["admin",7]' })),
    500,
    'scopeNames[1] must be a string',
  );
  assertHttpError(
    () => projectToJson(projectRow({ supported_locales: '["en",7]' })),
    500,
    'supportedLocales[1] must be a string',
  );
});

test('serializers reject invalid stored JSON instead of defaulting', () => {
  assertHttpError(
    () => answerToJson(answerRow({ selected_choice_ids: '{' })),
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
    () => visibilityRuleToJson(visibilityRuleRow({ value_json: '{' })),
    500,
    'Invalid stored JSON: visibilityRule.value',
  );
  assertHttpError(
    () => projectToJson(projectRow({ supported_locales: '{' })),
    500,
    'Invalid stored JSON: supportedLocales',
  );
});

test('response serializer exposes admin reply count', () => {
  assert.equal(responseToJson(responseRow()).replyCount, 0);
  assert.equal(responseToJson(responseRow({ reply_count: 3 })).replyCount, 3);
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
    () => answerToJson(answerRow({ selected_choice_ids: '{"id":1}' })),
    500,
    'selectedChoiceIds must be an array',
  );
  assertHttpError(
    () => projectToJson(projectRow({ supported_locales: '{"en":true}' })),
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
