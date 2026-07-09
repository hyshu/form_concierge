import assert from 'node:assert/strict';
import test from 'node:test';

import { projectRow, surveyRow } from '../test/fixtures';
import { assertHttpErrorAsync, d1Database, d1Result } from '../test/helpers';
import { renderPublicForm } from './public_form_renderer';
import type { Env, ProjectRow, SurveyRow } from './types';

test('renderPublicForm returns 404 for missing API-host survey slug', async () => {
  const response = await renderPublicForm(
    htmlRequest('https://example.com/acme/1e2'),
    envWithPublicRows({}),
  );

  assert.equal(response.status, 404);
  assert.match(await response.text(), /Page not found/);
});

test('renderPublicForm returns 404 for missing custom-domain survey slug', async () => {
  const response = await renderPublicForm(
    htmlRequest('https://forms.example.com/1.0'),
    envWithPublicRows({
      project: { custom_domain: 'forms.example.com' },
    }, 'https://api.example.com'),
  );

  assert.equal(response.status, 404);
  assert.match(await response.text(), /Page not found/);
});

test('renderPublicForm falls back when preferred locale text is missing', async () => {
  const response = await renderPublicForm(
    htmlRequest('https://example.com/acme'),
    envWithPublicRows({
      // Project default is ja, but survey only has en — should not 500.
      survey: surveyRow({ title_translations: '{"en":"Survey"}' }),
    }),
  );

  assert.equal(response.status, 200);
  assert.match(await response.text(), /Survey/);
});

test('renderPublicForm rejects surveys with no localized text at all', async () => {
  await assertHttpErrorAsync(
    () => renderPublicForm(
      htmlRequest('https://example.com/acme'),
      envWithPublicRows({
        survey: surveyRow({ title_translations: '{}' }),
      }),
    ),
    500,
    'Missing localized text for locale: ja',
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
}, publicBaseUrl = 'https://example.com'): Env {
  const project = projectRow({
    slug: 'acme',
    default_locale: 'ja',
    supported_locales: '["en","ja"]',
    name: 'Project',
    ...input.project,
  });
  const surveys = input.surveys?.map((item) => surveyRow(item)) ?? [
    surveyRow({
      title_translations: '{"en":"Survey","ja":"Survey"}',
      description_translations: '{"en":"","ja":""}',
      status: 'published',
      ...input.survey,
    }),
  ];
  return {
    DB: d1Database((sql: string) => ({
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
    } as unknown as D1PreparedStatement)),
    MEDIA_BUCKET: {} as R2Bucket,
    PUBLIC_BASE_URL: publicBaseUrl,
    PUBLIC_FORM_ASSET_BASE_URL: 'https://assets.example.com',
  };
}
