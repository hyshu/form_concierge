import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const apiUrl = process.env.API_URL ?? 'http://127.0.0.1:8787';
const adminEmail = process.env.ADMIN_EMAIL ?? 'e2e-admin@example.com';
const adminPassword = process.env.ADMIN_PASSWORD ?? 'password12345';
const rootDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const artifactDir = path.join(rootDir, 'e2e/.artifacts');

const allLocales = ['en', 'ja', 'zh-Hans', 'zh-Hant', 'ko', 'de'];

const translations = (en, ja = en) => ({
  en,
  ja,
  'zh-Hans': en,
  'zh-Hant': en,
  ko: en,
  de: en,
});

async function request(method, route, { body, token } = {}) {
  const response = await fetch(`${apiUrl}${route}`, {
    method,
    headers: {
      accept: 'application/json',
      ...(body == null ? {} : { 'content-type': 'application/json' }),
      ...(token == null ? {} : { authorization: `Bearer ${token}` }),
    },
    body: body == null ? undefined : JSON.stringify(body),
  });
  const text = await response.text();
  const json = text.length === 0 ? null : JSON.parse(text);
  if (!response.ok) {
    throw new Error(`${method} ${route} failed: ${response.status} ${text}`);
  }
  return json;
}

async function adminToken() {
  const status = await request('GET', '/api/admin/bootstrap/status');
  if (status.isFirstUser === true) {
    const auth = await request('POST', '/api/admin/bootstrap', {
      body: { email: adminEmail, password: adminPassword },
    });
    return auth.token;
  }

  const auth = await request('POST', '/api/admin/auth/login', {
    body: { email: adminEmail, password: adminPassword },
  });
  return auth.token;
}

async function seed() {
  const token = await adminToken();
  const project = await request('POST', '/api/admin/projects', {
    token,
    body: {
      slug: 'demo-project',
      customDomain: '',
      defaultLocale: 'en',
      supportedLocales: ['en', 'ja'],
      nameTranslations: {
        en: 'Customer feedback',
        ja: '顧客フィードバック',
      },
      descriptionTranslations: {
        en: 'Seeded E2E project',
        ja: 'E2E用プロジェクト',
      },
    },
  });

  const survey = await request('POST', '/api/admin/surveys/with-questions', {
    token,
    body: {
      survey: {
        projectId: project.id,
        titleTranslations: {
          en: 'Customer feedback',
          ja: '顧客フィードバック',
        },
        descriptionTranslations: {
          en: 'Tell us what you think',
          ja: 'ご意見をお聞かせください',
        },
        webEnabled: true,
      },
      questions: [
        {
          textTranslations: translations('Your name', 'お名前'),
          type: 'textSingle',
          isRequired: true,
          placeholderTranslations: translations('Type your name', 'お名前を入力'),
          minLength: 1,
          maxLength: 80,
          minSelected: null,
          maxSelected: null,
          visibilityConditionMode: 'all',
          choiceTranslations: [],
        },
      ],
    },
  });

  const published = await request('POST', `/api/admin/surveys/${survey.id}/publish`, {
    token,
  });

  const artifact = {
    apiUrl,
    adminEmail,
    adminPassword,
    projectId: project.id,
    projectSlug: project.slug,
    surveyId: published.id,
    locales: allLocales,
  };
  await mkdir(artifactDir, { recursive: true });
  await writeFile(
    path.join(artifactDir, 'seed.json'),
    `${JSON.stringify(artifact, null, 2)}\n`,
  );
  console.log(JSON.stringify(artifact));
}

seed().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
