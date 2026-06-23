import test from 'node:test';

import { assertBadRequestAsync, emptyD1Result } from '../test/helpers';
import { createSurveyWithQuestions } from './admin_surveys';
import type { AdminContext, Env } from './types';

test('createSurveyWithQuestions requires a questions array', async () => {
  await assertBadRequestAsync(
    () => createSurveyWithQuestions(requestWithBody({ survey: {}, questions: null }), envUnused(), admin()),
    'questions must be an array',
  );
});

test('createSurveyWithQuestions requires a survey object', async () => {
  await assertBadRequestAsync(
    () => createSurveyWithQuestions(requestWithBody({ survey: null, questions: [] }), envUnused(), admin()),
    'survey must be an object',
  );
});

test('createSurveyWithQuestions rejects non-object question items', async () => {
  await assertBadRequestAsync(
    () => createSurveyWithQuestions(requestWithBody({ survey: {}, questions: [null] }), envUnused(), admin()),
    'questions[0] must be an object',
  );
});

test('createSurveyWithQuestions validates choice translations shape by question type', async () => {
  await assertBadRequestAsync(
    () => createSurveyWithQuestions(
      requestWithBody({
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
      requestWithBody({
        survey: {},
        questions: [{ ...questionInput('textSingle'), choiceTranslations: [localizedText('Choice')] }],
      }),
      envUnused(),
      admin(),
    ),
    'questions[0].choiceTranslations must be empty for text questions',
  );
});

function requestWithBody(body: unknown): Request {
  return new Request('https://example.com/api/admin/surveys/with-questions', {
    method: 'POST',
    body: JSON.stringify(body),
  });
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

function localizedText(value: string): Record<string, string> {
  return {
    en: value,
    ja: value,
    'zh-Hans': value,
    'zh-Hant': value,
    ko: value,
    de: value,
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
    DB: d1Unused(),
    MEDIA_BUCKET: {} as R2Bucket,
    PUBLIC_BASE_URL: 'https://api.example.com',
    PUBLIC_FORM_ASSET_BASE_URL: 'https://forms.example.com',
  };
}

function d1Unused(): D1Database {
  return {
    prepare() {
      throw new Error('D1 should not be used by invalid question input tests');
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
