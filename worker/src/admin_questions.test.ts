import assert from 'node:assert/strict';
import test from 'node:test';

import { createQuestion, normalizeQuestionValidation, normalizeVisibilityConditionMode } from './admin_questions';
import type { Env, ProjectRow, QuestionRow, SurveyRow } from './types';
import { HttpError } from './utils';

test('normalizeQuestionValidation rejects coerced numeric strings', () => {
  assertHttpError(
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
  assertHttpError(
    () => normalizeQuestionValidation({ minSelected: 2, maxSelected: 1 }, 'multipleChoice'),
    'minSelected cannot be greater than maxSelected',
  );
});

test('normalizeVisibilityConditionMode rejects coerced values', () => {
  assert.equal(normalizeVisibilityConditionMode(undefined), 'all');
  assert.equal(normalizeVisibilityConditionMode('any'), 'any');
  assertHttpError(
    () => normalizeVisibilityConditionMode({ toString: () => 'any' }),
    'Invalid visibility condition mode',
  );
});

test('createQuestion validates localized text against project supported locales', async () => {
  const env = envWithRows({
    project: projectRow({ supported_locales: '["ja"]' }),
    survey: surveyRow(),
    insertedQuestion: questionRow({
      text_translations: '{"ja":"質問"}',
      placeholder_translations: '{"ja":""}',
      type: 'textSingle',
    }),
  });
  const response = await createQuestion(
    requestWithBody({
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

function assertHttpError(action: () => unknown, message: string): void {
  assert.throws(action, (error: unknown) =>
    error instanceof HttpError &&
    error.status === 400 &&
    error.message === message,
  );
}

function requestWithBody(body: unknown): Request {
  return new Request('https://example.com/api/admin/questions', {
    method: 'POST',
    body: JSON.stringify(body),
  });
}

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
  return {
    prepare(sql: string) {
      return {
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
      };
    },
    async batch<T>() {
      return [d1Result<T>([])];
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
  } as unknown as D1Database;
}

function d1Result<T>(results: T[]): D1Result<T> {
  return {
    success: true,
    meta: d1Meta(),
    results,
  };
}

function d1Meta() {
  return {
    duration: 0,
    size_after: 0,
    rows_read: 0,
    rows_written: 0,
    last_row_id: 0,
    changed_db: false,
    changes: 0,
  };
}

function projectRow(overrides: Partial<ProjectRow> = {}): ProjectRow {
  return {
    id: 10,
    slug: 'demo',
    custom_domain: null,
    default_locale: 'ja',
    supported_locales: '["ja"]',
    name_translations: '{"ja":"Demo"}',
    description_translations: '{"ja":""}',
    created_by_admin_id: 'admin-1',
    created_at: '2026-01-01T00:00:00.000Z',
    updated_at: '2026-01-01T00:00:00.000Z',
    ...overrides,
  };
}

function surveyRow(overrides: Partial<SurveyRow> = {}): SurveyRow {
  return {
    id: 1,
    project_id: 10,
    title_translations: '{"ja":"調査"}',
    description_translations: '{"ja":""}',
    status: 'draft',
    web_enabled: 1,
    auth_requirement: 'anonymous',
    created_by_admin_id: 'admin-1',
    created_at: '2026-01-01T00:00:00.000Z',
    updated_at: '2026-01-01T00:00:00.000Z',
    starts_at: null,
    ends_at: null,
    ...overrides,
  };
}

function questionRow(overrides: Partial<QuestionRow> = {}): QuestionRow {
  return {
    id: 5,
    survey_id: 1,
    text_translations: '{"ja":"質問"}',
    type: 'textSingle',
    order_index: 0,
    is_required: 1,
    placeholder_translations: '{"ja":""}',
    min_length: null,
    max_length: null,
    min_selected: null,
    max_selected: null,
    visibility_condition_mode: 'all',
    is_deleted: 0,
    ...overrides,
  };
}
