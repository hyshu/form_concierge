import type { AdminContext, Env, ProjectRow, QuestionInput, QuestionRow, SurveyRow } from './types';
import {
  HttpError,
  boolToInt,
  countRows,
  integerParam,
  isChoiceQuestionType,
  isTextQuestionType,
  isUniqueConstraintError,
  json,
  normalizeQuestionType,
  nowIso,
  optionalBoolean,
  optionalIsoDateTime,
  optionalLimitedString,
  readJson,
  requireObject,
  requireSlug,
  requiredBoolean,
  requiredInteger,
  requiredRow,
} from './utils';
import { surveyToJson } from './serializers';
import { mustProject, mustSurvey, projectSupportedLocales } from './admin_records';
import { insertQuestion, normalizeQuestionValidation, normalizeVisibilityConditionMode } from './admin_questions';
import { collectFileKeysForSurveys, deleteMediaKeys } from './media';
import {
  DEFAULT_FORM_CONTENT_LOCALE,
  LocalizedText,
  localizedTextFor,
  requireLocalizedText,
} from './localization';

export async function listSurveys(env: Env, projectId: number | undefined, url: URL): Promise<Response> {
  const limit = integerParam(url.searchParams.get('limit'), 'limit', 100, { min: 1, max: 500 });
  const offset = integerParam(url.searchParams.get('offset'), 'offset', 0, { min: 0 });
  const statement = projectId == null
    ? env.DB.prepare(`SELECT * FROM surveys ORDER BY updated_at DESC LIMIT ? OFFSET ?`).bind(limit, offset)
    : env.DB.prepare(
        `SELECT * FROM surveys WHERE project_id = ? ORDER BY updated_at DESC LIMIT ? OFFSET ?`,
      ).bind(projectId, limit, offset);
  const rows = await statement.all<SurveyRow>();
  return json(rows.results.map(surveyToJson));
}

export async function getAdminSurvey(env: Env, surveyId: number): Promise<Response> {
  const row = await env.DB.prepare(`SELECT * FROM surveys WHERE id = ?`)
    .bind(surveyId)
    .first<SurveyRow>();
  if (!row) throw new HttpError(404, 'Survey not found');
  return json(surveyToJson(row));
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
  project?: ProjectRow,
): Promise<SurveyRow> {
  const projectId = requireProjectId(body.projectId);
  const resolvedProject = project ?? await mustProject(db, projectId);
  const content = parseSurveyContent(body, resolvedProject);
  const explicitSlug = body.slug != null && body.slug !== '';
  let slug = await resolveSurveySlug(db, body.slug, resolvedProject, content);
  const baseAutoSlug = explicitSlug
    ? null
    : (slugFromSurveyTitle(content, resolvedProject.default_locale) ?? 'survey');
  const now = nowIso();
  const webEnabled = Object.hasOwn(body, 'webEnabled')
    ? boolToInt(requiredBoolean(body.webEnabled, 'webEnabled'))
    : 1;
  const followUpEnabled = Object.hasOwn(body, 'followUpEnabled')
    ? boolToInt(requiredBoolean(body.followUpEnabled, 'followUpEnabled'))
    : 0;
  const followUpPrompt = Object.hasOwn(body, 'followUpPrompt')
    ? optionalFollowUpPrompt(body.followUpPrompt)
    : null;
  const captchaEnabled = Object.hasOwn(body, 'captchaEnabled')
    ? boolToInt(requiredBoolean(body.captchaEnabled, 'captchaEnabled'))
    : 1;
  const startsAt = optionalIsoDateTime(body.startsAt, 'startsAt');
  const endsAt = optionalIsoDateTime(body.endsAt, 'endsAt');
  assertSurveySchedule(startsAt, endsAt);
  const titleJson = JSON.stringify(content.titleTranslations);
  const descriptionJson = JSON.stringify(content.descriptionTranslations);

  // Auto-slug path: retry INSERT on UNIQUE races instead of failing with 500.
  for (let attempt = 0; attempt < 8; attempt++) {
    try {
      const row = await db.prepare(
        `INSERT INTO surveys
           (project_id, slug, title_translations, description_translations, status, web_enabled, follow_up_enabled,
            follow_up_prompt, captcha_enabled, created_by_admin_id, created_at, updated_at, starts_at, ends_at)
         VALUES (?, ?, ?, ?, 'draft', ?, ?, ?, ?, ?, ?, ?, ?, ?)
         RETURNING *`,
      )
        .bind(
          projectId,
          slug,
          titleJson,
          descriptionJson,
          webEnabled,
          followUpEnabled,
          followUpPrompt,
          captchaEnabled,
          admin.id,
          now,
          now,
          startsAt,
          endsAt,
        )
        .first<SurveyRow>();
      return requiredRow(row, 'Survey');
    } catch (error) {
      if (!isUniqueConstraintError(error)) throw error;
      if (explicitSlug || baseAutoSlug == null) {
        throw new HttpError(400, 'A survey with this slug already exists');
      }
      slug = await nextSurveySlugCandidate(db, projectId, baseAutoSlug, slug);
    }
  }
  throw new HttpError(400, 'Unable to generate a unique survey slug');
}

export async function createSurveyWithQuestions(
  request: Request,
  env: Env,
  admin: AdminContext,
): Promise<Response> {
  const body = await readJson(request);
  const survey = requireObject(body.survey, 'survey');
  validateQuestionInputShape(body.questions);
  const projectId = requireProjectId(survey.projectId);
  const project = await mustProject(env.DB, projectId);
  const questions = parseQuestionInputs(body.questions, projectSupportedLocales(project));
  const created = await insertSurvey(env.DB, survey, admin, project);

  try {
    for (let i = 0; i < questions.length; i++) {
      await insertQuestion(env.DB, {
        ...questions[i],
        surveyId: created.id,
        orderIndex: i,
      });
    }
  } catch (error) {
    // Cascade deletes questions/choices so a mid-loop failure leaves no half survey.
    await env.DB.prepare(`DELETE FROM surveys WHERE id = ?`).bind(created.id).run();
    throw error;
  }
  return json(surveyToJson(created), 201);
}

export async function updateSurvey(request: Request, env: Env, surveyId: number): Promise<Response> {
  const existing = await mustSurvey(env.DB, surveyId);
  const body = await readJson(request);
  const project = await mustProject(env.DB, existing.project_id);
  const content = parseSurveyContent(body, project);
  const slug = Object.hasOwn(body, 'slug')
    ? requireSurveySlug(body.slug)
    : existing.slug;
  await ensureUniqueSurveySlug(env.DB, project.id, slug, surveyId);
  const startsAt = Object.hasOwn(body, 'startsAt')
    ? optionalIsoDateTime(body.startsAt, 'startsAt')
    : existing.starts_at;
  const endsAt = Object.hasOwn(body, 'endsAt')
    ? optionalIsoDateTime(body.endsAt, 'endsAt')
    : existing.ends_at;
  assertSurveySchedule(startsAt, endsAt);
  const row = await env.DB.prepare(
    `UPDATE surveys
     SET slug = ?, title_translations = ?, description_translations = ?,
         web_enabled = ?, follow_up_enabled = ?, follow_up_prompt = ?, captcha_enabled = ?,
         starts_at = ?, ends_at = ?, updated_at = ?
     WHERE id = ?
     RETURNING *`,
  ).bind(
    slug,
    JSON.stringify(content.titleTranslations),
    JSON.stringify(content.descriptionTranslations),
    Object.hasOwn(body, 'webEnabled') ? boolToInt(requiredBoolean(body.webEnabled, 'webEnabled')) : existing.web_enabled,
    Object.hasOwn(body, 'followUpEnabled')
      ? boolToInt(requiredBoolean(body.followUpEnabled, 'followUpEnabled'))
      : existing.follow_up_enabled,
    Object.hasOwn(body, 'followUpPrompt')
      ? optionalFollowUpPrompt(body.followUpPrompt)
      : existing.follow_up_prompt,
    Object.hasOwn(body, 'captchaEnabled')
      ? boolToInt(requiredBoolean(body.captchaEnabled, 'captchaEnabled'))
      : existing.captcha_enabled,
    startsAt,
    endsAt,
    nowIso(),
    surveyId,
  ).first<SurveyRow>();
  return json(surveyToJson(requiredRow(row, 'Survey')));
}

const FOLLOW_UP_PROMPT_MAX_LENGTH = 4000;

function optionalFollowUpPrompt(value: unknown): string | null {
  return optionalLimitedString(value, 'followUpPrompt', FOLLOW_UP_PROMPT_MAX_LENGTH);
}

function assertSurveySchedule(startsAt: string | null, endsAt: string | null): void {
  if (startsAt != null && endsAt != null && Date.parse(startsAt) >= Date.parse(endsAt)) {
    throw new HttpError(400, 'startsAt must be before endsAt');
  }
}

export async function deleteSurvey(env: Env, surveyId: number): Promise<Response> {
  const fileKeys = await collectFileKeysForSurveys(env.DB, [surveyId]);
  await env.DB.prepare(`DELETE FROM surveys WHERE id = ?`).bind(surveyId).run();
  await deleteMediaKeys(env.MEDIA_BUCKET, fileKeys);
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

function validateQuestionInputShape(value: unknown): void {
  if (!Array.isArray(value)) throw new HttpError(400, 'questions must be an array');
  value.forEach((raw, index) => {
    if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
      throw new HttpError(400, `questions[${index}] must be an object`);
    }
    const question = raw as Record<string, unknown>;
    const type = normalizeQuestionType(question.type);
    if (!Array.isArray(question.choiceTranslations)) {
      throw new HttpError(400, `questions[${index}].choiceTranslations must be an array`);
    }
    if (isChoiceQuestionType(type) && question.choiceTranslations.length === 0) {
      throw new HttpError(400, `questions[${index}].choiceTranslations must not be empty`);
    }
    if ((isTextQuestionType(type) || type === 'imageUpload') && question.choiceTranslations.length > 0) {
      throw new HttpError(
        400,
        `questions[${index}].choiceTranslations must be empty for text and image questions`,
      );
    }
  });
}

function parseQuestionInputs(value: unknown, locales: readonly string[]): QuestionInput[] {
  validateQuestionInputShape(value);
  return (value as Record<string, unknown>[]).map((question, index) => {
    const type = normalizeQuestionType(question.type);
    const choiceTranslations = (question.choiceTranslations as unknown[]).map((choice, choiceIndex) => requireLocalizedText(
      choice,
      `questions[${index}].choiceTranslations[${choiceIndex}]`,
      locales,
    ));
    return {
      textTranslations: requireLocalizedText(
        question.textTranslations,
        `questions[${index}].textTranslations`,
        locales,
      ),
      type,
      isRequired: optionalBoolean(question.isRequired, `questions[${index}].isRequired`) ?? true,
      placeholderTranslations: requireLocalizedText(
        question.placeholderTranslations,
        `questions[${index}].placeholderTranslations`,
        locales,
        { allowEmpty: true },
      ),
      ...normalizeQuestionValidation(question, type),
      visibilityConditionMode: normalizeVisibilityConditionMode(question.visibilityConditionMode),
      choiceTranslations,
    };
  });
}

function parseSurveyContent(body: Record<string, unknown>, project: ProjectRow): {
  titleTranslations: LocalizedText;
  descriptionTranslations: LocalizedText;
} {
  const supportedLocales = projectSupportedLocales(project);
  return {
    titleTranslations: requireLocalizedText(body.titleTranslations, 'titleTranslations', supportedLocales),
    descriptionTranslations: requireLocalizedText(
      body.descriptionTranslations,
      'descriptionTranslations',
      supportedLocales,
      { allowEmpty: true },
    ),
  };
}

type SurveyContent = ReturnType<typeof parseSurveyContent>;

async function resolveSurveySlug(
  db: D1Database,
  value: unknown,
  project: ProjectRow,
  content: SurveyContent,
): Promise<string> {
  if (value != null && value !== '') {
    const slug = requireSurveySlug(value);
    await ensureUniqueSurveySlug(db, project.id, slug);
    return slug;
  }
  const base = slugFromSurveyTitle(content, project.default_locale) ?? 'survey';
  return uniqueSurveySlug(db, project.id, base);
}

function requireSurveySlug(value: unknown): string {
  const slug = requireSlug(value);
  if (/^\d+$/.test(slug)) {
    throw new HttpError(400, 'slug must include at least one lowercase letter');
  }
  return slug;
}

function slugFromSurveyTitle(
  content: SurveyContent,
  defaultLocale: string,
): string | null {
  const candidates = [
    content.titleTranslations[defaultLocale],
    content.titleTranslations[DEFAULT_FORM_CONTENT_LOCALE],
    ...Object.values(content.titleTranslations),
  ];
  for (const candidate of candidates) {
    if (typeof candidate !== 'string') continue;
    const slug = candidate
      .trim()
      .toLowerCase()
      .normalize('NFKD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '')
      .replace(/-{2,}/g, '-');
    if (slug && /[a-z]/.test(slug)) return slug;
  }
  return null;
}

async function uniqueSurveySlug(
  db: D1Database,
  projectId: number,
  base: string,
): Promise<string> {
  // Prefer SELECT for the common path; insert still retries on UNIQUE races.
  for (let index = 0; index < 100; index++) {
    const slug = index === 0 ? base : `${base}-${index + 1}`;
    const row = await db.prepare(
      `SELECT id FROM surveys WHERE project_id = ? AND slug = ?`,
    ).bind(projectId, slug).first<{ id: number }>();
    if (!row) return slug;
  }
  throw new HttpError(400, 'Unable to generate a unique survey slug');
}

/** Allocate the next free auto-slug after a UNIQUE race on the current candidate. */
export async function nextSurveySlugCandidate(
  db: D1Database,
  projectId: number,
  base: string,
  failedSlug: string,
): Promise<string> {
  const prefix = `${base}-`;
  let start = 1;
  if (failedSlug === base) start = 2;
  else if (failedSlug.startsWith(prefix)) {
    const n = Number(failedSlug.slice(prefix.length));
    if (Number.isFinite(n) && n >= 1) start = n + 1;
  }
  for (let index = start; index < start + 100; index++) {
    const slug = index === 1 ? base : `${base}-${index}`;
    if (slug === failedSlug) continue;
    const row = await db.prepare(
      `SELECT id FROM surveys WHERE project_id = ? AND slug = ?`,
    ).bind(projectId, slug).first<{ id: number }>();
    if (!row) return slug;
  }
  throw new HttpError(400, 'Unable to generate a unique survey slug');
}

async function ensureUniqueSurveySlug(
  db: D1Database,
  projectId: number,
  slug: string,
  exceptSurveyId?: number,
): Promise<void> {
  const row = exceptSurveyId == null
    ? await db.prepare(
        `SELECT id FROM surveys WHERE project_id = ? AND slug = ?`,
      ).bind(projectId, slug).first<{ id: number }>()
    : await db.prepare(
        `SELECT id FROM surveys WHERE project_id = ? AND slug = ? AND id != ?`,
      ).bind(projectId, slug, exceptSurveyId).first<{ id: number }>();
  if (row) throw new HttpError(400, 'A survey with this slug already exists');
}

function requireProjectId(value: unknown): number {
  return requiredInteger(value, 'projectId', { min: 1 });
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
