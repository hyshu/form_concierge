import test from 'node:test';

import {
  adminPostRequest,
  assertBadRequestAsync,
  d1Database,
  localizedText,
  stubRateLimiter,
  stubSecretsStoreEnv,
  TEST_TURNSTILE_SITE_KEY,
  TEST_TURNSTILE_SECRET_KEY,
} from '../test/helpers';
import { createSurveyWithQuestions } from './admin_surveys';
import type { AdminContext, Env } from './types';

test('createSurveyWithQuestions requires a questions array', async () => {
  await assertBadRequestAsync(
    () => createSurveyWithQuestions(
      createSurveyWithQuestionsRequest({ survey: {}, questions: null }),
      envUnused(),
      admin(),
    ),
    'questions must be an array',
  );
});

test('createSurveyWithQuestions requires a survey object', async () => {
  await assertBadRequestAsync(
    () => createSurveyWithQuestions(
      createSurveyWithQuestionsRequest({ survey: null, questions: [] }),
      envUnused(),
      admin(),
    ),
    'survey must be an object',
  );
});

test('createSurveyWithQuestions rejects non-object question items', async () => {
  await assertBadRequestAsync(
    () => createSurveyWithQuestions(
      createSurveyWithQuestionsRequest({ survey: {}, questions: [null] }),
      envUnused(),
      admin(),
    ),
    'questions[0] must be an object',
  );
});

test('createSurveyWithQuestions validates choice translations shape by question type', async () => {
  await assertBadRequestAsync(
    () => createSurveyWithQuestions(
      createSurveyWithQuestionsRequest({
        survey: {},
        questions: [{ ...questionInput('singleChoice'), choiceTranslations: [] }],
      }),
      envUnused(),
      admin(),
    ),
    'questions[0].choiceTranslations must not be empty',
  );

  await assertBadRequestAsync(
    () => createSurveyWithQuestions(
      createSurveyWithQuestionsRequest({
        survey: {},
        questions: [
          { ...questionInput('textSingle'), choiceTranslations: [localizedText('Choice')] },
        ],
      }),
      envUnused(),
      admin(),
    ),
    'questions[0].choiceTranslations must be empty for text and image questions',
  );
});

function createSurveyWithQuestionsRequest(body: unknown): Request {
  return adminPostRequest('surveys/with-questions', body);
}

function questionInput(type: string): Record<string, unknown> {
  return {
    textTranslations: localizedText('Question'),
    type,
    isRequired: true,
    placeholderTranslations: localizedText(''),
    minLength: null,
    maxLength: null,
    minSelected: null,
    maxSelected: null,
    visibilityConditionMode: 'all',
    choiceTranslations: [localizedText('Choice')],
  };
}

function admin(): AdminContext {
  return {
    id: 'admin-1',
    email: 'admin@example.com',
    scopeNames: ['admin'],
    created: '2026-01-01T00:00:00.000Z',
  };
}

function envUnused(): Env {
  return {
    DB: d1Database(() => {
      throw new Error('D1 should not be used by invalid question input tests');
    }),
    MEDIA_BUCKET: {} as R2Bucket,
    PUBLIC_BASE_URL: 'https://api.example.com',
    PUBLIC_FORM_ASSET_BASE_URL: 'https://forms.example.com',
    LOGIN_RATE_LIMITER: stubRateLimiter(),
    ANON_CREATE_RATE_LIMITER: stubRateLimiter(),
    TURNSTILE_SITE_KEY: TEST_TURNSTILE_SITE_KEY,
    TURNSTILE_SECRET_KEY: TEST_TURNSTILE_SECRET_KEY,
    ...stubSecretsStoreEnv(),
  };
}
