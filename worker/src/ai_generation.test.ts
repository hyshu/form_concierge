import test from 'node:test';

import { integrationSettingsRow } from '../test/fixtures';
import {
  adminPostRequest,
  assertHttpErrorAsync,
  d1Database,
  emptyD1Raw,
  emptyD1Result,
  localizedText,
  stubRateLimiter,
} from '../test/helpers';
import { generateSurveyQuestions, toProviderSchema } from './ai_generation';
import type { Env } from './types';
import assert from 'node:assert/strict';

test('generateSurveyQuestions rejects coercible integer fields from providers', async () => {
  await withOpenAiQuestion({ minLength: '3' }, async () => {
    await assertProviderError(
      () => generateSurveyQuestions(promptRequest(), envWithSettings()),
      'OpenAI returned invalid integer for minLength',
    );
  });
});

test('generateSurveyQuestions rejects invalid boolean and enum fields from providers', async () => {
  await withOpenAiQuestion({ isRequired: 'false' }, async () => {
    await assertProviderError(
      () => generateSurveyQuestions(promptRequest(), envWithSettings()),
      'OpenAI returned invalid boolean for isRequired',
    );
  });

  await withOpenAiQuestion({ visibilityConditionMode: 'sometimes' }, async () => {
    await assertProviderError(
      () => generateSurveyQuestions(promptRequest(), envWithSettings()),
      'OpenAI returned invalid visibility condition mode',
    );
  });
});

test('generateSurveyQuestions rejects missing localized output from providers', async () => {
  const textTranslations = localizedText('Question');
  delete textTranslations.ja;
  await withOpenAiQuestion({ textTranslations }, async () => {
    await assertProviderError(
      () => generateSurveyQuestions(promptRequest(), envWithSettings()),
      'OpenAI returned missing localized text for ja',
    );
  });
});

test('generateSurveyQuestions rejects schema-shape fallback responses', async () => {
  await withOpenAiQuestion({ choiceTranslations: null }, async () => {
    await assertProviderError(
      () => generateSurveyQuestions(promptRequest(), envWithSettings()),
      'OpenAI returned invalid choice translations',
    );
  });

  await withOpenAiContent([generatedQuestion({})], async () => {
    await assertProviderError(
      () => generateSurveyQuestions(promptRequest(), envWithSettings()),
      'OpenAI returned invalid question JSON',
    );
  });
});

async function withOpenAiQuestion(
  overrides: Record<string, unknown>,
  action: () => Promise<void>,
): Promise<void> {
  await withOpenAiContent({ questions: [generatedQuestion(overrides)] }, action);
}

async function withOpenAiContent(
  content: unknown,
  action: () => Promise<void>,
): Promise<void> {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = (async () => new Response(JSON.stringify({
    choices: [
      {
        message: {
          content: JSON.stringify(content),
        },
      },
    ],
  }))) as typeof fetch;
  try {
    await action();
  } finally {
    globalThis.fetch = originalFetch;
  }
}

function generatedQuestion(overrides: Record<string, unknown>) {
  return {
    textTranslations: localizedText('Question'),
    type: 'textSingle',
    isRequired: true,
    placeholderTranslations: localizedText('Placeholder'),
    minLength: null,
    maxLength: null,
    minSelected: null,
    maxSelected: null,
    visibilityConditionMode: 'all',
    choiceTranslations: [],
    ...overrides,
  };
}

function promptRequest(): Request {
  return adminPostRequest('ai/questions', { prompt: 'Build a short survey' });
}

function envWithSettings(): Env {
  return {
    DB: d1WithSettings(),
    MEDIA_BUCKET: {} as R2Bucket,
    PUBLIC_BASE_URL: 'https://api.example.com',
    PUBLIC_FORM_ASSET_BASE_URL: 'https://forms.example.com',
    LOGIN_RATE_LIMITER: stubRateLimiter(),
    ANON_CREATE_RATE_LIMITER: stubRateLimiter(),
  };
}

function d1WithSettings(): D1Database {
  let statement: D1PreparedStatement;
  statement = {
    bind() {
      return statement;
    },
    async first<T>() {
      return integrationSettingsRow({
        ai_provider: 'openai',
        openai_api_key: 'openai-key',
        smtp_host: null,
        smtp_port: null,
        smtp_from_email: null,
      }) as T;
    },
    async run<T>() {
      return emptyD1Result<T>();
    },
    async all<T>() {
      return emptyD1Result<T>();
    },
    raw: emptyD1Raw,
  };

  return d1Database(() => statement);
}

async function assertProviderError(action: () => Promise<unknown>, message: string): Promise<void> {
  await assertHttpErrorAsync(action, 502, message);
}

test('toProviderSchema strips Gemini-unsupported fields and keeps OpenAI/Cerebras strict rules', () => {
  const source = {
    type: 'object',
    additionalProperties: false,
    properties: {
      ja: { type: 'string' },
      ko: { type: 'string' },
      nested: {
        type: 'object',
        properties: {
          minLength: { type: ['integer', 'null'] },
        },
        required: ['minLength'],
        additionalProperties: false,
      },
    },
    // Intentionally incomplete vs properties — strict transform should fill this in.
    required: ['ja'],
  };

  const gemini = toProviderSchema('gemini', source) as Record<string, unknown>;
  assert.equal(Object.hasOwn(gemini, 'additionalProperties'), false);
  const geminiNested = (gemini.properties as Record<string, Record<string, unknown>>).nested;
  assert.equal(Object.hasOwn(geminiNested, 'additionalProperties'), false);
  assert.deepEqual(geminiNested.properties, {
    minLength: { type: 'integer', nullable: true },
  });

  for (const provider of ['openai', 'cerebras', 'claude'] as const) {
    const strict = toProviderSchema(provider, source) as Record<string, unknown>;
    assert.equal(strict.additionalProperties, false);
    assert.deepEqual(strict.required, ['ja', 'ko', 'nested']);
    const nested = (strict.properties as Record<string, Record<string, unknown>>).nested;
    assert.equal(nested.additionalProperties, false);
    assert.deepEqual(nested.required, ['minLength']);
    // Union types are left alone for strict JSON Schema providers.
    assert.deepEqual(
      (nested.properties as Record<string, unknown>).minLength,
      { type: ['integer', 'null'] },
    );
  }
});

test('translateLocalizedText rejects missing API key and invalid locales', async () => {
  const { translateLocalizedText } = await import('./ai_generation');
  const env = {
    DB: {
      prepare: () => ({
        first: async () => null,
        bind: () => ({ first: async () => null }),
      }),
    },
  } as unknown as Env;

  await assertHttpErrorAsync(
    () => translateLocalizedText(
      adminPostRequest('/api/admin/ai/translate-localized-text', {
        sourceLocale: 'en',
        sourceText: 'Hello',
        targetLocales: ['ja'],
      }),
      env,
    ),
    400,
    'AI generation provider is not configured',
  );
});
