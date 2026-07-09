import assert from 'node:assert/strict';
import test from 'node:test';

import { projectRow, questionRow, surveyRow } from '../test/fixtures';
import {
  adminPostRequest,
  assertBadRequest,
  d1Database,
  d1Meta,
  d1Result,
} from '../test/helpers';
import {
  createQuestion,
  normalizeQuestionValidation,
  normalizeVisibilityConditionMode,
} from './admin_questions';
import type { Env, ProjectRow, QuestionRow, SurveyRow } from './types';

test('normalizeQuestionValidation rejects coerced numeric strings', () => {
  assertBadRequest(
    () => normalizeQuestionValidation({ minLength: '1e2' }, 'textSingle'),
    'minLength must be an integer',
  );
});

test('normalizeQuestionValidation keeps integer bounds strict', () => {
  assert.deepEqual(
    normalizeQuestionValidation({ minLength: 1, maxLength: 3 }, 'textSingle'),
    {
      minLength: 1,
      maxLength: 3,
      minSelected: null,
      maxSelected: null,
    },
  );
  assertBadRequest(
    () => normalizeQuestionValidation({ minSelected: 2, maxSelected: 1 }, 'multipleChoice'),
    'minSelected cannot be greater than maxSelected',
  );
});

test('normalizeQuestionValidation accepts explicit null to clear bounds', () => {
  assert.deepEqual(
    normalizeQuestionValidation(
      { minLength: null, maxLength: null, minSelected: null, maxSelected: null },
      'textSingle',
    ),
    {
      minLength: null,
      maxLength: null,
      minSelected: null,
      maxSelected: null,
    },
  );
});

test('normalizeVisibilityConditionMode rejects coerced values', () => {
  assert.equal(normalizeVisibilityConditionMode(undefined), 'all');
  assert.equal(normalizeVisibilityConditionMode('any'), 'any');
  assertBadRequest(
    () => normalizeVisibilityConditionMode({ toString: () => 'any' }),
    'Invalid visibility condition mode',
  );
});

test('createQuestion validates localized text against project supported locales', async () => {
  const env = envWithRows({
    project: projectRow({
      id: 10,
      default_locale: 'ja',
      supported_locales: '["ja"]',
    }),
    survey: surveyRow({ project_id: 10 }),
    insertedQuestion: questionRow({
      id: 5,
      text_translations: '{"ja":"質問"}',
      placeholder_translations: '{"ja":""}',
      type: 'textSingle',
      is_required: 1,
    }),
  });
  const response = await createQuestion(
    adminPostRequest('questions', {
      surveyId: 1,
      textTranslations: { ja: '質問' },
      type: 'textSingle',
      isRequired: true,
      placeholderTranslations: { ja: '' },
      visibilityConditionMode: 'all',
    }),
    env,
  );
  const body = await response.json() as { textTranslations: Record<string, string> };

  assert.equal(response.status, 201);
  assert.deepEqual(body.textTranslations, { ja: '質問' });
});

function envWithRows(rows: {
  project: ProjectRow;
  survey: SurveyRow;
  insertedQuestion: QuestionRow;
}): Env {
  return {
    DB: d1WithRows(rows),
    MEDIA_BUCKET: {} as R2Bucket,
    PUBLIC_BASE_URL: 'https://api.example.com',
    PUBLIC_FORM_ASSET_BASE_URL: 'https://forms.example.com',
  };
}

function d1WithRows(rows: {
  project: ProjectRow;
  survey: SurveyRow;
  insertedQuestion: QuestionRow;
}): D1Database {
  return d1Database((sql: string) => ({
    bind() {
      return {
        async first<T>() {
          if (sql.includes('FROM surveys')) return rows.survey as T;
          if (sql.includes('FROM projects')) return rows.project as T;
          if (sql.includes('MAX(order_index)')) {
            return { max_order: null } as T;
          }
          if (sql.includes('INSERT INTO questions')) {
            return rows.insertedQuestion as T;
          }
          throw new Error(`Unexpected first SQL: ${sql}`);
        },
        async all<T>() {
          return d1Result<T>([]);
        },
        async run() {
          return d1Meta();
        },
      };
    },
  } as unknown as D1PreparedStatement));
}
