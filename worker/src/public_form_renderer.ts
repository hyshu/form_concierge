import type { ChoiceRow, Env, ProjectRow, QuestionRow, SurveyRow } from './types';
import { choiceToJson, projectToJson, questionToJson, surveyToJson, visibilityRuleToJson } from './serializers';
import { HttpError, optionalCustomDomain, queryInChunks } from './utils';
import {
  DEFAULT_FORM_CONTENT_LOCALE,
  preferredLocalesFromAcceptLanguage,
  resolveFormContentLocale,
} from './localization';
import { getVisibilityRules } from './visibility_rules';

type PublicFormData = {
  project: ReturnType<typeof projectToJson>;
  survey: ReturnType<typeof surveyToJson>;
  questions: ReturnType<typeof questionToJson>[];
  visibilityRules: ReturnType<typeof visibilityRuleToJson>[];
  choicesByQuestion: Record<string, ReturnType<typeof choiceToJson>[]>;
};

export function isPublicFormHtmlRequest(request: Request, path: string): boolean {
  const method = request.method.toUpperCase();
  if (method !== 'GET' && method !== 'HEAD') return false;
  if (path === '/api' || path.startsWith('/api/')) return false;
  const parts = path.split('/').filter(Boolean);
  if (parts.length > 2) return false;
  if (parts[0]?.includes('.')) return false;
  if (parts[1]?.includes('.')) return false;
  const accept = request.headers.get('accept') ?? '';
  return accept.length === 0 || accept.includes('text/html') || accept.includes('*/*');
}

export async function renderPublicForm(request: Request, env: Env): Promise<Response> {
  const url = new URL(request.url);
  const pathParts = pathPartsFromPath(url.pathname);
  const surveyKey = isApiHost(env, url) ? pathParts[1] ?? null : pathParts[0] ?? null;
  const data = isApiHost(env, url)
    ? await loadProjectBySlug(env, pathParts[0] ?? null, surveyKey)
    : await loadProjectByDomain(env, url.hostname, surveyKey);

  if (!data) {
    if (pathParts.length === 0 && isApiHost(env, url)) {
      return html(request, renderServiceRootHtml(env, url));
    }
    return html(request, renderNotFoundHtml(env, url), 404);
  }

  const locale = resolveFormContentLocale(
    preferredLocalesFromAcceptLanguage(request.headers.get('accept-language')),
    data.project.supportedLocales,
    data.project.defaultLocale,
  );
  return html(request, renderSurveyHtml(env, url, data, locale));
}

async function loadProjectBySlug(
  env: Env,
  slug: string | null,
  surveyKey: string | null,
): Promise<PublicFormData | null> {
  if (!slug) return null;
  const project = await env.DB.prepare(
    `SELECT * FROM projects WHERE slug = ?`,
  ).bind(slug).first<ProjectRow>();
  if (!project) return null;
  return loadProjectData(env, project, surveyKey);
}

async function loadProjectByDomain(
  env: Env,
  host: string,
  surveyKey: string | null,
): Promise<PublicFormData | null> {
  let customDomain: string | null = null;
  try {
    customDomain = optionalCustomDomain(host);
  } catch {
    return null;
  }
  if (!customDomain) return null;

  const project = await env.DB.prepare(
    `SELECT * FROM projects WHERE custom_domain = ?`,
  ).bind(customDomain).first<ProjectRow>();
  if (!project) return null;
  return loadProjectData(env, project, surveyKey);
}

async function loadProjectData(
  env: Env,
  project: ProjectRow,
  surveyKey: string | null,
): Promise<PublicFormData | null> {
  const rows = await env.DB.prepare(
    `SELECT * FROM surveys
     WHERE project_id = ? AND status = 'published' AND web_enabled = 1
     ORDER BY updated_at DESC`,
  ).bind(project.id).all<SurveyRow>();
  const surveys = rows.results.filter(isAccepting);
  if (surveys.length === 0) return null;

  const selectedSurvey = surveyKey == null
    ? surveys.length === 1 ? surveys[0] : null
    : selectSurveyByKey(surveys, surveyKey);
  if (!selectedSurvey) return null;

  return loadPublicFormData(env, project, selectedSurvey);
}

function selectSurveyByKey(
  surveys: SurveyRow[],
  key: string,
): SurveyRow | null {
  if (/^\d+$/.test(key)) {
    const id = Number(key);
    return Number.isSafeInteger(id)
      ? surveys.find((survey) => survey.id === id) ?? null
      : null;
  }
  return surveys.find((survey) => survey.slug === key) ?? null;
}

async function loadPublicFormData(env: Env, project: ProjectRow, survey: SurveyRow): Promise<PublicFormData> {
  const questions = await env.DB.prepare(
    `SELECT * FROM questions
     WHERE survey_id = ? AND is_deleted = 0
     ORDER BY order_index`,
  ).bind(survey.id).all<QuestionRow>();
  const visibilityRules = await getVisibilityRules(env.DB, survey.id);
  const choicesByQuestion = await loadChoicesByQuestion(env, questions.results);

  return {
    project: projectToJson(project),
    survey: surveyToJson(survey),
    questions: questions.results.map(questionToJson),
    visibilityRules: visibilityRules.map(visibilityRuleToJson),
    choicesByQuestion,
  };
}

async function loadChoicesByQuestion(
  env: Env,
  questions: QuestionRow[],
): Promise<Record<string, ReturnType<typeof choiceToJson>[]>> {
  const choicesByQuestion: Record<string, ReturnType<typeof choiceToJson>[]> = {};
  for (const question of questions) {
    choicesByQuestion[String(question.id)] = [];
  }
  const questionIds = questions.map((question) => question.id);
  if (questionIds.length === 0) return choicesByQuestion;
  const rows = await queryInChunks<ChoiceRow>(
    env.DB,
    (ph) => `SELECT * FROM choices WHERE question_id IN (${ph}) ORDER BY order_index`,
    questionIds,
  );
  for (const row of rows) {
    const key = String(row.question_id);
    (choicesByQuestion[key] ??= []).push(choiceToJson(row));
  }
  return choicesByQuestion;
}

function renderSurveyHtml(
  env: Env,
  url: URL,
  data: PublicFormData,
  locale: string,
): string {
  const title = textFor(data.survey.titleTranslations, locale);
  const description = textFor(data.survey.descriptionTranslations, locale);
  const assetBaseUrl = publicFormAssetBaseUrl(env);
  const apiUrl = publicApiUrl(env);
  const turnstileSiteKey = data.survey.captchaEnabled ? env.TURNSTILE_SITE_KEY : null;
  const payload = { ...data, apiUrl, turnstileSiteKey };

  return documentHtml({
    lang: locale,
    title,
    description,
    apiUrl,
    assetBaseUrl,
    turnstileSiteKey,
    payload,
    body: `
      <main id="form-concierge-ssr-root" class="survey-wrapper">
        <section class="max-w-xl mx-auto bg-white rounded-xl shadow-md border border-slate-200 p-6">
          <div class="flex items-start justify-between gap-3">
            <div class="min-w-0 flex-1">
              <h1 class="text-2xl font-semibold text-slate-900">${escapeHtml(title)}</h1>
              ${description ? `<p class="mt-2 text-slate-600 leading-relaxed">${escapeHtml(description)}</p>` : ''}
            </div>
            ${renderLocaleList(data.project.supportedLocales, locale)}
          </div>
        </section>
        <section class="max-w-xl mx-auto mt-6 space-y-4">
          ${data.questions.map((question) => renderQuestion(question, data.choicesByQuestion, locale)).join('')}
          ${turnstileSiteKey ? `<div class="cf-turnstile" data-sitekey="${escapeAttribute(turnstileSiteKey)}"></div>` : ''}
          <button class="w-full px-6 py-3 bg-indigo-600 text-white font-medium rounded-lg disabled:opacity-50" disabled>
            ${locale === 'ja' ? '送信' : 'Submit'}
          </button>
        </section>
      </main>
    `,
  });
}

function renderNotFoundHtml(env: Env, url: URL): string {
  return documentHtml({
    lang: 'en',
    title: 'Survey Not Found',
    description: 'The survey you are looking for does not exist or is not available.',
    apiUrl: publicApiUrl(env),
    assetBaseUrl: publicFormAssetBaseUrl(env),
    payload: null,
    body: `
      <main id="form-concierge-ssr-root" class="max-w-xl mx-auto bg-white rounded-xl shadow-md border border-slate-200 text-center py-16 px-6">
        <h1 class="text-7xl font-light text-slate-300">404</h1>
        <p class="mt-4 text-lg font-medium text-slate-700">Page not found</p>
        <p class="mt-2 text-sm text-slate-500">The page you are looking for does not exist.</p>
      </main>
    `,
  });
}

function renderServiceRootHtml(env: Env, url: URL): string {
  const apiUrl = publicApiUrl(env);
  return documentHtml({
    lang: 'en',
    title: 'Form Concierge API',
    description: 'Form Concierge API is running.',
    apiUrl,
    assetBaseUrl: publicFormAssetBaseUrl(env),
    includeClient: false,
    payload: null,
    body: `
      <main id="form-concierge-ssr-root" class="max-w-xl mx-auto bg-white rounded-xl shadow-md border border-slate-200 text-center py-16 px-6">
        <h1 class="text-2xl font-semibold text-slate-900">Form Concierge API</h1>
        <p class="mt-4 text-slate-600">API is running.</p>
        <p class="mt-2 text-sm text-slate-500">${escapeHtml(apiUrl)}</p>
      </main>
    `,
  });
}

function documentHtml(input: {
  lang: string;
  title: string;
  description: string;
  apiUrl: string;
  assetBaseUrl: string;
  includeClient?: boolean;
  turnstileSiteKey?: string | null;
  payload: unknown;
  body: string;
}): string {
  return `<!DOCTYPE html>
<html lang="${escapeAttribute(input.lang)}">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="form-concierge-api-url" content="${escapeAttribute(input.apiUrl)}">
  <title>${escapeHtml(input.title)}</title>
  <meta name="description" content="${escapeAttribute(input.description)}">
  <link rel="icon" href="data:,">
  <link rel="stylesheet" href="${escapeAttribute(`${input.assetBaseUrl}/styles.css`)}">
  ${input.turnstileSiteKey ? '<script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>' : ''}
  ${
    input.includeClient === false
      ? ''
      : `<script id="form-concierge-ssr" type="application/json">${safeJson(input.payload)}</script>
  <script defer src="${escapeAttribute(`${input.assetBaseUrl}/main.client.dart.js`)}"></script>`
  }
</head>
<body class="bg-slate-50 min-h-screen py-8 px-4 md:py-12">
${input.body}
</body>
</html>`;
}

function renderLocaleList(locales: string[], selectedLocale: string): string {
  if (locales.length <= 1) return '';
  return `
    <select name="locale" class="shrink-0 px-3 py-1.5 border border-slate-200 rounded-lg text-sm bg-white text-slate-700" disabled>
      ${locales
        .map(
          (locale) =>
            `<option value="${escapeAttribute(locale)}"${locale === selectedLocale ? ' selected' : ''}>${escapeHtml(localeLabel(locale))}</option>`,
        )
        .join('')}
    </select>
  `;
}

function renderQuestion(
  question: PublicFormData['questions'][number],
  choicesByQuestion: PublicFormData['choicesByQuestion'],
  locale: string,
): string {
  const label = textFor(question.textTranslations, locale);
  const required = question.isRequired ? '<span class="ml-1 text-red-500">*</span>' : '';
  const choices = choicesByQuestion[String(question.id)];
  if (!choices) throw new HttpError(500, `Missing choices for question ${question.id}`);
  return `
    <article class="bg-white rounded-xl shadow-md border border-slate-200 p-5">
      <h2 class="font-medium text-slate-900">${escapeHtml(label)}${required}</h2>
      <div class="mt-4">
        ${renderQuestionInput(question, choices, locale)}
      </div>
    </article>
  `;
}

function renderQuestionInput(
  question: PublicFormData['questions'][number],
  choices: ReturnType<typeof choiceToJson>[],
  locale: string,
): string {
  const placeholder = textFor(question.placeholderTranslations, locale);
  if (question.type === 'imageUpload') {
    return `<div class="rounded-lg border border-dashed border-slate-300 px-4 py-6 text-sm text-slate-600">Image upload is available in the Flutter app.</div>`;
  }
  if (question.type === 'textMultiLine') {
    return `<textarea class="w-full min-h-[120px] rounded-lg border border-slate-300 px-4 py-3 resize-y" placeholder="${escapeAttribute(placeholder)}" disabled></textarea>`;
  }
  if (question.type === 'singleChoice' || question.type === 'multipleChoice') {
    const inputType = question.type === 'singleChoice' ? 'radio' : 'checkbox';
    return `
      <div class="space-y-2">
        ${choices.map((choice) => `
          <label class="flex items-center gap-3 rounded-lg border border-slate-200 p-3">
            <input type="${inputType}" disabled>
            <span>${escapeHtml(textFor(choice.textTranslations, locale))}</span>
          </label>
        `).join('')}
      </div>
    `;
  }
  return `<input class="w-full rounded-lg border border-slate-300 px-4 py-3" placeholder="${escapeAttribute(placeholder)}" disabled>`;
}

function textFor(translations: Record<string, string>, locale: string): string {
  // Match localizedTextFor: prefer requested locale, then default, then any.
  const text =
    translations[locale] ??
    translations[DEFAULT_FORM_CONTENT_LOCALE] ??
    Object.values(translations).find((item): item is string => typeof item === 'string');
  if (typeof text !== 'string') {
    throw new HttpError(500, `Missing localized text for locale: ${locale}`);
  }
  return text;
}

function pathPartsFromPath(pathname: string): string[] {
  try {
    return pathname.split('/').filter(Boolean).map(decodeURIComponent);
  } catch {
    throw new HttpError(400, 'Malformed URL path');
  }
}

function isAccepting(survey: SurveyRow): boolean {
  const now = Date.now();
  if (survey.starts_at && Date.parse(survey.starts_at) > now) return false;
  if (survey.ends_at && Date.parse(survey.ends_at) < now) return false;
  return true;
}

function publicApiUrl(env: Env): string {
  return removeTrailingSlash(env.PUBLIC_BASE_URL);
}

function isApiHost(env: Env, url: URL): boolean {
  return new URL(publicApiUrl(env)).hostname === url.hostname;
}

function publicFormAssetBaseUrl(env: Env): string {
  return removeTrailingSlash(env.PUBLIC_FORM_ASSET_BASE_URL);
}

function removeTrailingSlash(value: string): string {
  return value.replace(/\/+$/, '');
}

function html(request: Request, body: string, status = 200): Response {
  return new Response(request.method.toUpperCase() === 'HEAD' ? null : body, {
    status,
    headers: {
      'content-type': 'text/html; charset=utf-8',
      'cache-control': 'no-store',
    },
  });
}

function safeJson(value: unknown): string {
  return JSON.stringify(value)
    .replace(/</g, '\\u003c')
    .replace(/>/g, '\\u003e')
    .replace(/&/g, '\\u0026')
    .replace(/\u2028/g, '\\u2028')
    .replace(/\u2029/g, '\\u2029');
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function escapeAttribute(value: string): string {
  return escapeHtml(value);
}

function localeLabel(locale: string): string {
  return ({
    en: 'English',
    ja: '日本語',
    'zh-Hans': '简体中文',
    'zh-Hant': '繁體中文',
    ko: '한국어',
    de: 'Deutsch',
    es: 'Español',
    fr: 'Français',
    it: 'Italiano',
    th: 'ไทย',
    tr: 'Türkçe',
  } as Record<string, string>)[locale] ?? locale;
}
