import assert from 'node:assert/strict';
import test from 'node:test';

import {
  normalizeFormContentLocale,
  preferredLocalesFromAcceptLanguage,
  resolveFormContentLocale,
} from './localization';

test('normalizeFormContentLocale maps regional tags', () => {
  assert.equal(normalizeFormContentLocale('ja-JP'), 'ja');
  assert.equal(normalizeFormContentLocale('zh-CN'), 'zh-Hans');
  assert.equal(normalizeFormContentLocale('zh_TW'), 'zh-Hant');
  assert.equal(normalizeFormContentLocale('en'), 'en');
});

test('preferredLocalesFromAcceptLanguage orders by quality', () => {
  assert.deepEqual(
    preferredLocalesFromAcceptLanguage('fr-FR,fr;q=0.9,en;q=0.8,ja;q=0.7'),
    ['fr-FR', 'fr', 'en', 'ja'],
  );
  assert.deepEqual(preferredLocalesFromAcceptLanguage(null), []);
  assert.deepEqual(preferredLocalesFromAcceptLanguage('*'), []);
});

test('resolveFormContentLocale picks supported preferred locales', () => {
  assert.equal(
    resolveFormContentLocale(['ja-JP', 'en'], ['en', 'ja'], 'en'),
    'ja',
  );
  assert.equal(
    resolveFormContentLocale(['de'], ['en', 'ja'], 'ja'),
    'ja',
  );
});
