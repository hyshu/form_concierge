import assert from 'node:assert/strict';
import test from 'node:test';

import { generateSurveyQuestions } from './ai_generation';
import { emptyD1Raw, emptyD1Result } from './test_helpers';
import type { Env, IntegrationSettingsRow } from './types';
import { HttpError } from './utils';

const locales = ['en', 'ja', 'zh-Hans', 'zh-Hant', 'ko', 'de'] as const;

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

function localizedText(value: string): Record<string, string> {
  return Object.fromEntries(locales.map((locale) => [locale, value]));
}

function promptRequest(): Request {
  return new Request('https://example.com/api/admin/ai/questions', {
    method: 'POST',
    body: JSON.stringify({ prompt: 'Build a short survey' }),
  });
}

function envWithSettings(): Env {
  return {
    DB: d1WithSettings(),
    MEDIA_BUCKET: {} as R2Bucket,
    PUBLIC_BASE_URL: 'https://api.example.com',
    PUBLIC_FORM_ASSET_BASE_URL: 'https://forms.example.com',
  };
}

function d1WithSettings(): D1Database {
  let statement: D1PreparedStatement;
  statement = {
    bind() {
      return statement;
    },
    async first<T>() {
      return integrationSettings() as T;
    },
    async run<T>() {
      return emptyD1Result<T>();
    },
    async all<T>() {
      return emptyD1Result<T>();
    },
    raw: emptyD1Raw,
  };

  return {
    prepare() {
      return statement;
    },
    async batch<T>() {
      return [emptyD1Result<T>()];
    },
    async exec() {
      return { count: 0, duration: 0 };
    },
    withSession() {
      throw new Error('D1 sessions are not used by this test');
    },
    async dump() {
      return new ArrayBuffer(0);
    },
  } satisfies D1Database;
}

function integrationSettings(): IntegrationSettingsRow {
  return {
    id: 1,
    ai_provider: 'openai',
    gemini_api_key: null,
    openai_api_key: 'openai-key',
    claude_api_key: null,
    cerebras_api_key: null,
    smtp_host: null,
    smtp_port: null,
    smtp_username: null,
    smtp_password: null,
    smtp_from_email: null,
    smtp_from_name: null,
    smtp_secure_mode: 'starttls',
    updated_at: '2026-01-01T00:00:00.000Z',
  };
}

async function assertProviderError(action: () => Promise<unknown>, message: string): Promise<void> {
  await assert.rejects(action, (error: unknown) =>
    error instanceof HttpError &&
    error.status === 502 &&
    error.message === message,
  );
}
