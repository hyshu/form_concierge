import assert from 'node:assert/strict';
import test from 'node:test';

import { renderPublicForm } from './public_form_renderer';
import type { Env, ProjectRow, SurveyRow } from './types';
import { HttpError } from './utils';

test('renderPublicForm returns 404 for invalid API-host survey path ids before storage access', async () => {
  const response = await renderPublicForm(
    htmlRequest('https://example.com/acme/1e2'),
    envWithoutDb('https://example.com'),
  );

  assert.equal(response.status, 404);
  assert.match(await response.text(), /Page not found/);
});

test('renderPublicForm returns 404 for invalid custom-domain survey path ids before storage access', async () => {
  const response = await renderPublicForm(
    htmlRequest('https://forms.example.com/1.0'),
    envWithoutDb('https://api.example.com'),
  );

  assert.equal(response.status, 404);
  assert.match(await response.text(), /Page not found/);
});

test('renderPublicForm rejects missing localized text instead of falling back', async () => {
  await assert.rejects(
    () => renderPublicForm(
      htmlRequest('https://example.com/acme'),
      envWithPublicRows({
        survey: surveyRow({ title_translations: '{"en":"Survey"}' }),
      }),
    ),
    (error: unknown) =>
      error instanceof HttpError &&
      error.status === 500 &&
      error.message === 'Missing localized text for locale: ja',
  );
});

test('renderPublicForm returns 404 for project root when multiple surveys are available', async () => {
  const response = await renderPublicForm(
    htmlRequest('https://example.com/acme'),
    envWithPublicRows({
      surveys: [
        surveyRow({ id: 1 }),
        surveyRow({ id: 2 }),
      ],
    }),
  );

  assert.equal(response.status, 404);
  assert.match(await response.text(), /Page not found/);
});

function htmlRequest(url: string): Request {
  return new Request(url, {
    headers: {
      accept: 'text/html',
    },
  });
}

function envWithPublicRows(input: {
  project?: Partial<ProjectRow>;
  survey?: Partial<SurveyRow>;
  surveys?: Partial<SurveyRow>[];
}): Env {
  const project = projectRow(input.project);
  const surveys = input.surveys?.map((item) => surveyRow(item)) ?? [
    surveyRow(input.survey),
  ];
  return {
    DB: {
      prepare(sql: string) {
        return {
          bind() {
            return this;
          },
          async first<T>() {
            if (sql.includes('FROM projects')) return project as T;
            throw new Error(`Unexpected first query: ${sql}`);
          },
          async all<T>() {
            if (sql.includes('FROM surveys')) return d1Result<T>(surveys as T[]);
            if (sql.includes('FROM questions')) return d1Result<T>([]);
            if (sql.includes('FROM question_visibility_rules')) return d1Result<T>([]);
            throw new Error(`Unexpected all query: ${sql}`);
          },
        } as unknown as D1PreparedStatement;
      },
    } as unknown as D1Database,
    MEDIA_BUCKET: {} as R2Bucket,
    PUBLIC_BASE_URL: 'https://example.com',
    PUBLIC_FORM_ASSET_BASE_URL: 'https://assets.example.com',
  };
}

function d1Result<T>(results: T[]): D1Result<T> {
  return {
    success: true,
    meta: {
      duration: 0,
      size_after: 0,
      rows_read: 0,
      rows_written: 0,
      last_row_id: 0,
      changed_db: false,
      changes: 0,
    },
    results,
  };
}

function projectRow(overrides: Partial<ProjectRow> = {}): ProjectRow {
  return {
    id: 1,
    slug: 'acme',
    custom_domain: null,
    default_locale: 'ja',
    supported_locales: '["en","ja"]',
    name: 'Project',
    created_by_admin_id: 'admin-1',
    created_at: '2026-01-01T00:00:00.000Z',
    updated_at: '2026-01-01T00:00:00.000Z',
    ...overrides,
  };
}

function surveyRow(overrides: Partial<SurveyRow> = {}): SurveyRow {
  return {
    id: 1,
    project_id: 1,
    title_translations: '{"en":"Survey","ja":"Survey"}',
    description_translations: '{"en":"","ja":""}',
    status: 'published',
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

function envWithoutDb(publicBaseUrl: string): Env {
  return {
    DB: new Proxy({}, {
      get() {
        throw new Error('DB should not be accessed for invalid public form path ids');
      },
    }) as D1Database,
    MEDIA_BUCKET: {} as R2Bucket,
    PUBLIC_BASE_URL: publicBaseUrl,
    PUBLIC_FORM_ASSET_BASE_URL: 'https://assets.example.com',
  };
}
