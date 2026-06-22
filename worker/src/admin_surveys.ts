import type { AdminContext, Env, QuestionInput, QuestionRow, SurveyRow } from './types';
import {
  HttpError,
  boolToInt,
  countRows,
  insertChoices,
  isChoiceQuestionType,
  json,
  normalizeQuestionType,
  nowIso,
  objectBody,
  optionalCustomDomain,
  optionalString,
  readJson,
  requireSlug,
  requiredRow,
} from './utils';
import { surveyToJson } from './serializers';
import { mustSurvey } from './admin_records';
import { normalizeQuestionValidation, normalizeVisibilityConditionMode } from './admin_questions';
import {
  DEFAULT_FORM_CONTENT_LOCALE,
  FORM_CONTENT_LOCALES,
  LocalizedText,
  localizedTextFor,
  requireDefaultLocale,
  requireLocalizedText,
  requireSupportedLocales,
} from './localization';

export async function listSurveys(env: Env, admin: AdminContext): Promise<Response> {
  const rows = await env.DB.prepare(
    `SELECT * FROM surveys
     ORDER BY updated_at DESC`,
  ).all<SurveyRow>();
  return json(rows.results.map(surveyToJson));
}

export async function getAdminSurvey(env: Env, surveyId: number): Promise<Response> {
  const row = await env.DB.prepare(`SELECT * FROM surveys WHERE id = ?`)
    .bind(surveyId)
    .first<SurveyRow>();
  return json(row ? surveyToJson(row) : null);
}

export async function createSurvey(request: Request, env: Env, admin: AdminContext): Promise<Response> {
  const body = await readJson(request);
  const row = await insertSurvey(env.DB, body, admin);
  return json(surveyToJson(row), 201);
}

async function insertSurvey(
  db: D1Database,
  body: Record<string, unknown>,
  admin: AdminContext,
): Promise<SurveyRow> {
  const slug = requireSlug(body.slug);
  await ensureUniqueSlug(db, slug);
  const customDomain = optionalCustomDomain(body.customDomain);
  await ensureUniqueCustomDomain(db, customDomain);
  const content = parseSurveyContent(body);
  const now = nowIso();
  const row = await db.prepare(
    `INSERT INTO surveys
       (slug, custom_domain, default_locale, supported_locales, title_translations,
        description_translations, status, created_by_admin_id,
        created_at, updated_at, starts_at, ends_at)
     VALUES (?, ?, ?, ?, ?, ?, 'draft', ?, ?, ?, ?, ?)
     RETURNING *`,
  )
    .bind(
      slug,
      customDomain,
      content.defaultLocale,
      JSON.stringify(content.supportedLocales),
      JSON.stringify(content.titleTranslations),
      JSON.stringify(content.descriptionTranslations),
      admin.id,
      now,
      now,
      optionalString(body.startsAt),
      optionalString(body.endsAt),
    )
    .first<SurveyRow>();
  return requiredRow(row, 'Survey');
}

export async function createSurveyWithQuestions(
  request: Request,
  env: Env,
  admin: AdminContext,
): Promise<Response> {
  const body = await readJson(request);
  const survey = objectBody(body.survey);
  const questions = parseQuestionInputs(body.questions);
  const created = await insertSurvey(env.DB, survey, admin);

  for (let i = 0; i < questions.length; i++) {
    const q = questions[i];
    const question = await env.DB.prepare(
      `INSERT INTO questions
         (survey_id, text_translations, type, order_index, is_required, placeholder_translations,
          min_length, max_length, min_selected, max_selected, visibility_condition_mode)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
       RETURNING *`,
    ).bind(
      created.id,
      JSON.stringify(q.textTranslations),
      q.type,
      i,
      boolToInt(q.isRequired),
      JSON.stringify(q.placeholderTranslations),
      q.minLength,
      q.maxLength,
      q.minSelected,
      q.maxSelected,
      q.visibilityConditionMode,
    ).first<QuestionRow>();
    if (!question) throw new HttpError(500, 'Failed to create question');
    if (isChoiceQuestionType(question.type)) {
      await insertChoices(env.DB, question.id, q.choiceTranslations);
    }
  }
  return json(surveyToJson(created), 201);
}

export async function updateSurvey(request: Request, env: Env, surveyId: number): Promise<Response> {
  const existing = await mustSurvey(env.DB, surveyId);
  const body = await readJson(request);
  const slug = requireSlug(body.slug ?? existing.slug);
  await ensureUniqueSlug(env.DB, slug, surveyId);
  const customDomain = optionalCustomDomain(
    Object.hasOwn(body, 'customDomain') ? body.customDomain : existing.custom_domain,
  );
  await ensureUniqueCustomDomain(env.DB, customDomain, surveyId);
  const content = parseSurveyContent(body);
  const row = await env.DB.prepare(
    `UPDATE surveys
     SET slug = ?, custom_domain = ?, default_locale = ?, supported_locales = ?,
         title_translations = ?, description_translations = ?,
         starts_at = ?, ends_at = ?, updated_at = ?
     WHERE id = ?
     RETURNING *`,
  ).bind(
    slug,
    customDomain,
    content.defaultLocale,
    JSON.stringify(content.supportedLocales),
    JSON.stringify(content.titleTranslations),
    JSON.stringify(content.descriptionTranslations),
    optionalString(body.startsAt ?? existing.starts_at),
    optionalString(body.endsAt ?? existing.ends_at),
    nowIso(),
    surveyId,
  ).first<SurveyRow>();
  return json(surveyToJson(requiredRow(row, 'Survey')));
}

export async function deleteSurvey(env: Env, surveyId: number): Promise<Response> {
  await env.DB.prepare(`DELETE FROM surveys WHERE id = ?`).bind(surveyId).run();
  return json({ ok: true });
}

export async function updateSurveyStatus(
  env: Env,
  surveyId: number,
  status: string,
  allowedFrom: string[],
  transitionErrorMessage: string,
): Promise<Response> {
  const survey = await mustSurvey(env.DB, surveyId);
  if (!allowedFrom.includes(survey.status)) {
    throw new HttpError(400, transitionErrorMessage);
  }
  if (status === 'published') {
    await assertSurveyCanPublish(env.DB, surveyId);
  }
  const row = await env.DB.prepare(
    `UPDATE surveys SET status = ?, updated_at = ? WHERE id = ? RETURNING *`,
  ).bind(status, nowIso(), survey.id).first<SurveyRow>();
  return json(surveyToJson(requiredRow(row, 'Survey')));
}

function parseQuestionInputs(value: unknown): QuestionInput[] {
  if (!Array.isArray(value)) return [];
  return value.map((raw, index) => {
    const question = typeof raw === 'object' && raw !== null ? raw as Record<string, unknown> : {};
    const type = normalizeQuestionType(question.type);
    const choiceTranslations = Array.isArray(question.choiceTranslations)
      ? question.choiceTranslations.map((choice, choiceIndex) => requireLocalizedText(
          choice,
          `questions[${index}].choiceTranslations[${choiceIndex}]`,
          FORM_CONTENT_LOCALES,
        ))
      : [];
    return {
      textTranslations: requireLocalizedText(
        question.textTranslations,
        `questions[${index}].textTranslations`,
        FORM_CONTENT_LOCALES,
      ),
      type,
      isRequired: question.isRequired !== false,
      placeholderTranslations: requireLocalizedText(
        question.placeholderTranslations,
        `questions[${index}].placeholderTranslations`,
        FORM_CONTENT_LOCALES,
        { allowEmpty: true },
      ),
      ...normalizeQuestionValidation(question, type),
      visibilityConditionMode: normalizeVisibilityConditionMode(question.visibilityConditionMode),
      choiceTranslations,
    };
  });
}

function parseSurveyContent(body: Record<string, unknown>): {
  supportedLocales: string[];
  defaultLocale: string;
  titleTranslations: LocalizedText;
  descriptionTranslations: LocalizedText;
} {
  const supportedLocales = requireSupportedLocales(body.supportedLocales);
  const defaultLocale = requireDefaultLocale(body.defaultLocale, supportedLocales);
  return {
    supportedLocales,
    defaultLocale,
    titleTranslations: requireLocalizedText(body.titleTranslations, 'titleTranslations', supportedLocales),
    descriptionTranslations: requireLocalizedText(
      body.descriptionTranslations,
      'descriptionTranslations',
      supportedLocales,
      { allowEmpty: true },
    ),
  };
}

async function ensureUniqueSlug(
  db: D1Database,
  slug: string,
  exceptSurveyId?: number,
): Promise<void> {
  const row = exceptSurveyId == null
    ? await db.prepare(`SELECT id FROM surveys WHERE slug = ?`).bind(slug).first<{ id: number }>()
    : await db.prepare(`SELECT id FROM surveys WHERE slug = ? AND id != ?`)
      .bind(slug, exceptSurveyId)
      .first<{ id: number }>();
  if (row) throw new HttpError(400, 'A survey with this slug already exists');
}

async function ensureUniqueCustomDomain(
  db: D1Database,
  customDomain: string | null,
  exceptSurveyId?: number,
): Promise<void> {
  if (customDomain == null) return;
  const row = exceptSurveyId == null
    ? await db.prepare(`SELECT id FROM surveys WHERE custom_domain = ?`).bind(customDomain).first<{ id: number }>()
    : await db.prepare(`SELECT id FROM surveys WHERE custom_domain = ? AND id != ?`)
      .bind(customDomain, exceptSurveyId)
      .first<{ id: number }>();
  if (row) throw new HttpError(400, 'A survey with this custom domain already exists');
}

async function assertSurveyCanPublish(db: D1Database, surveyId: number): Promise<void> {
  const questions = await db.prepare(
    `SELECT * FROM questions WHERE survey_id = ? AND is_deleted = 0`,
  ).bind(surveyId).all<QuestionRow>();
  if (questions.results.length === 0) {
    throw new HttpError(400, 'Survey must have at least one question');
  }
  for (const question of questions.results) {
    if (!isChoiceQuestionType(question.type)) continue;
    const choiceCount = await countRows(
      db,
      `SELECT COUNT(*) AS count FROM choices WHERE question_id = ?`,
      question.id,
    );
    if (choiceCount === 0) {
      throw new HttpError(
        400,
        `Question "${localizedTextFor(question.text_translations, DEFAULT_FORM_CONTENT_LOCALE)}" must have at least one choice`,
      );
    }
  }
}
