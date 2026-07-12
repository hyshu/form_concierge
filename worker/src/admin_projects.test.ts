import assert from 'node:assert/strict';
import test from 'node:test';

import { projectRow } from '../test/fixtures';
import {
  adminPostRequest,
  adminPutRequest,
  assertHttpErrorAsync,
  d1Database,
  stubRateLimiter,
  stubSecretsStoreEnv,
} from '../test/helpers';
import { createProject, updateProject } from './admin_projects';
import type { AdminContext, Env, ProjectRow } from './types';

test('createProject rejects malformed slugs and locales before storage writes', async () => {
  const cases: { body: Record<string, unknown>; message: string }[] = [
    {
      body: projectBody({ slug: 'Bad Slug!' }),
      message: 'slug must contain lowercase letters, numbers, and hyphens',
    },
    {
      body: projectBody({ supportedLocales: [] }),
      message: 'supportedLocales must not be empty',
    },
    {
      body: projectBody({ supportedLocales: ['en', 'xx'] }),
      message: 'Unsupported locale: xx',
    },
    {
      body: projectBody({ defaultLocale: 'ja' }),
      message: 'defaultLocale must be included in supportedLocales',
    },
  ];
  for (const { body, message } of cases) {
    await assertHttpErrorAsync(
      () => createProject(
        adminPostRequest('projects', body),
        projectsEnv({ slugTaken: false }),
        admin(),
      ),
      400,
      message,
    );
  }
});

test('createProject rejects duplicate slugs and custom domains', async () => {
  await assertHttpErrorAsync(
    () => createProject(
      adminPostRequest('projects', projectBody({})),
      projectsEnv({ slugTaken: true }),
      admin(),
    ),
    400,
    'A project with this slug already exists',
  );
  await assertHttpErrorAsync(
    () => createProject(
      adminPostRequest('projects', projectBody({ customDomain: 'forms.example.com' })),
      projectsEnv({ slugTaken: false, customDomainTaken: true }),
      admin(),
    ),
    400,
    'A project with this custom domain already exists',
  );
});

test('createProject persists a valid project and returns 201', async () => {
  const response = await createProject(
    adminPostRequest('projects', projectBody({})),
    projectsEnv({
      slugTaken: false,
      insertedRow: projectRow({ slug: 'new-project' }),
    }),
    admin(),
  );
  assert.equal(response.status, 201);
  const payload = await response.json() as { slug: string };
  assert.equal(payload.slug, 'new-project');
});

test('updateProject returns 404 for a missing project', async () => {
  await assertHttpErrorAsync(
    () => updateProject(
      adminPutRequest('projects/99', projectBody({})),
      projectsEnv({ existingRow: null }),
      99,
    ),
    404,
    'Project not found',
  );
});

test('updateProject rejects a slug already used by another project', async () => {
  await assertHttpErrorAsync(
    () => updateProject(
      adminPutRequest('projects/1', projectBody({ slug: 'taken' })),
      projectsEnv({ existingRow: projectRow(), slugTaken: true }),
      1,
    ),
    400,
    'A project with this slug already exists',
  );
});

function admin(): AdminContext {
  return {
    id: 'admin-1',
    email: 'ada@example.com',
    scopeNames: ['admin'],
    created: '2026-01-01T00:00:00.000Z',
  };
}

function projectBody(overrides: Record<string, unknown>): Record<string, unknown> {
  return {
    slug: 'new-project',
    customDomain: '',
    defaultLocale: 'en',
    supportedLocales: ['en'],
    name: 'New project',
    ...overrides,
  };
}

type ProjectsEnvOptions = {
  slugTaken?: boolean;
  customDomainTaken?: boolean;
  insertedRow?: ProjectRow;
  existingRow?: ProjectRow | null;
};

function projectsEnv(options: ProjectsEnvOptions): Env {
  return {
    DB: d1Database((sql: string) => ({
      bind() {
        return this;
      },
      async first<T>() {
        if (sql.includes('WHERE slug = ?')) {
          return (options.slugTaken ? { id: 2 } : null) as T | null;
        }
        if (sql.includes('WHERE custom_domain = ?')) {
          return (options.customDomainTaken ? { id: 2 } : null) as T | null;
        }
        if (sql.includes('SELECT * FROM projects WHERE id = ?')) {
          return (options.existingRow ?? null) as T | null;
        }
        if (sql.startsWith('INSERT INTO projects') || sql.startsWith('UPDATE projects')) {
          return (options.insertedRow ?? projectRow()) as T | null;
        }
        throw new Error(`Unexpected first() query in admin_projects test: ${sql}`);
      },
    }) as unknown as D1PreparedStatement),
    MEDIA_BUCKET: {} as R2Bucket,
    PUBLIC_BASE_URL: 'https://api.example.com',
    PUBLIC_FORM_ASSET_BASE_URL: 'https://assets.example.com',
    LOGIN_RATE_LIMITER: stubRateLimiter(),
    ANON_CREATE_RATE_LIMITER: stubRateLimiter(),
    ...stubSecretsStoreEnv(),
  };
}
