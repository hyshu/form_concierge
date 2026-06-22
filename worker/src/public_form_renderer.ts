import type { ChoiceRow, Env, QuestionRow, SurveyRow } from './types';
import { choiceToJson, questionToJson, surveyToJson, visibilityRuleToJson } from './serializers';
import { optionalCustomDomain } from './utils';
import { getVisibilityRules } from './visibility_rules';

const DEFAULT_FORM_ASSET_BASE_URL = 'http://localhost:8081';

type PublicFormData = {
  survey: ReturnType<typeof surveyToJson>;
  questions: ReturnType<typeof questionToJson>[];
  visibilityRules: ReturnType<typeof visibilityRuleToJson>[];
  choicesByQuestion: Record<string, ReturnType<typeof choiceToJson>[]>;
};

export function isPublicFormHtmlRequest(request: Request, path: string): boolean {
  const method = request.method.toUpperCase();
  if (method !== 'GET' && method !== 'HEAD') return false;
  if (path.startsWith('/api')) return false;
  const parts = path.split('/').filter(Boolean);
  if (parts.length > 1) return false;
  if (parts[0]?.includes('.')) return false;
  const accept = request.headers.get('accept') ?? '';
  return accept.length === 0 || accept.includes('text/html') || accept.includes('*/*');
}

export async function renderPublicForm(request: Request, env: Env): Promise<Response> {
  const url = new URL(request.url);
  const slug = slugFromPath(url.pathname);
  const data = slug
    ? await loadPublicFormBySlug(env, slug)
    : await loadPublicFormByDomain(env, url.hostname);

  if (!data) {
    if (!slug && isApiHost(env, url)) {
      return html(request, renderServiceRootHtml(env, url));
    }
    return html(request, renderNotFoundHtml(env, url), 404);
  }

  return html(request, renderSurveyHtml(env, url, data));
}

async function loadPublicFormBySlug(env: Env, slug: string): Promise<PublicFormData | null> {
  const survey = await env.DB.prepare(
    `SELECT * FROM surveys WHERE slug = ? AND status = 'published'`,
  ).bind(slug).first<SurveyRow>();
  if (!survey || !isAccepting(survey)) return null;
  return loadPublicFormData(env, survey);
}

async function loadPublicFormByDomain(env: Env, host: string): Promise<PublicFormData | null> {
  let customDomain: string | null = null;
  try {
    customDomain = optionalCustomDomain(host);
  } catch {
    return null;
  }
  if (!customDomain) return null;

  const survey = await env.DB.prepare(
    `SELECT * FROM surveys WHERE custom_domain = ? AND status = 'published'`,
  ).bind(customDomain).first<SurveyRow>();
  if (!survey || !isAccepting(survey)) return null;
  return loadPublicFormData(env, survey);
}

async function loadPublicFormData(env: Env, survey: SurveyRow): Promise<PublicFormData> {
  const questions = await env.DB.prepare(
    `SELECT * FROM questions
     WHERE survey_id = ? AND is_deleted = 0
     ORDER BY order_index`,
  ).bind(survey.id).all<QuestionRow>();
  const visibilityRules = await getVisibilityRules(env.DB, survey.id);
  const choicesByQuestion = await loadChoicesByQuestion(env, questions.results);

  return {
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
    const rows = await env.DB.prepare(
      `SELECT * FROM choices WHERE question_id = ? ORDER BY order_index`,
    ).bind(question.id).all<ChoiceRow>();
    if (rows.results.length > 0) {
      choicesByQuestion[String(question.id)] = rows.results.map(choiceToJson);
    }
  }
  return choicesByQuestion;
}

function renderSurveyHtml(env: Env, url: URL, data: PublicFormData): string {
  const locale = data.survey.defaultLocale;
  const title = textFor(data.survey.titleTranslations, locale);
  const description = textFor(data.survey.descriptionTranslations, locale);
  const assetBaseUrl = publicFormAssetBaseUrl(env);
  const apiUrl = publicApiUrl(env, url);
  const payload = { ...data, apiUrl };

  return documentHtml({
    lang: locale,
    title,
    description,
    apiUrl,
    assetBaseUrl,
    payload,
    body: `
      <main id="form-concierge-ssr-root" class="survey-wrapper">
        <section class="max-w-xl mx-auto bg-white rounded-xl shadow-md border border-slate-200 p-6">
          <h1 class="text-2xl font-semibold text-slate-900">${escapeHtml(title)}</h1>
          ${description ? `<p class="mt-4 text-slate-600 leading-relaxed">${escapeHtml(description)}</p>` : ''}
          ${renderLocaleList(data.survey.supportedLocales)}
        </section>
        <section class="max-w-xl mx-auto mt-6 space-y-4">
          ${data.questions.map((question) => renderQuestion(question, data.choicesByQuestion, locale)).join('')}
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
    apiUrl: publicApiUrl(env, url),
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
  const apiUrl = publicApiUrl(env, url);
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

function renderLocaleList(locales: string[]): string {
  if (locales.length <= 1) return '';
  return `
    <div class="mt-4 flex gap-2">
      ${locales.map((locale) => `<span class="px-4 py-2 bg-indigo-50 text-slate-700 rounded-full text-sm">${escapeHtml(localeLabel(locale))}</span>`).join('')}
    </div>
  `;
}

function renderQuestion(
  question: PublicFormData['questions'][number],
  choicesByQuestion: PublicFormData['choicesByQuestion'],
  locale: string,
): string {
  const label = textFor(question.textTranslations, locale);
  const required = question.isRequired ? '<span class="ml-1 text-red-500">*</span>' : '';
  const choices = choicesByQuestion[String(question.id)] ?? [];
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
  return translations[locale] ?? translations.en ?? Object.values(translations)[0] ?? '';
}

function slugFromPath(pathname: string): string | null {
  const parts = pathname.split('/').filter(Boolean);
  return parts.length === 1 ? decodeURIComponent(parts[0]) : null;
}

function isAccepting(survey: SurveyRow): boolean {
  const now = Date.now();
  if (survey.starts_at && Date.parse(survey.starts_at) > now) return false;
  if (survey.ends_at && Date.parse(survey.ends_at) < now) return false;
  return true;
}

function publicApiUrl(env: Env, url: URL): string {
  return removeTrailingSlash(env.PUBLIC_BASE_URL ?? url.origin);
}

function isApiHost(env: Env, url: URL): boolean {
  try {
    return new URL(publicApiUrl(env, url)).hostname === url.hostname;
  } catch {
    return false;
  }
}

function publicFormAssetBaseUrl(env: Env): string {
  return removeTrailingSlash(env.PUBLIC_FORM_ASSET_BASE_URL ?? DEFAULT_FORM_ASSET_BASE_URL);
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
  } as Record<string, string>)[locale] ?? locale;
}
