import type { AdminContext, Env, ProjectRow, QuestionInput, QuestionRow, SurveyRow } from './types';
import {
  HttpError,
  boolToInt,
  countRows,
  isChoiceQuestionType,
  isTextQuestionType,
  json,
  normalizeQuestionType,
  nowIso,
  optionalBoolean,
  optionalString,
  readJson,
  requireObject,
  requiredBoolean,
  requiredInteger,
  requiredRow,
} from './utils';
import { surveyToJson } from './serializers';
import { mustProject, mustSurvey } from './admin_records';
import { insertQuestion, normalizeQuestionValidation, normalizeVisibilityConditionMode } from './admin_questions';
import {
  DEFAULT_FORM_CONTENT_LOCALE,
  FORM_CONTENT_LOCALES,
  LocalizedText,
  localizedTextFor,
  requireLocalizedText,
} from './localization';

export async function listSurveys(env: Env, projectId?: number): Promise<Response> {
  const statement = projectId == null
    ? env.DB.prepare(`SELECT * FROM surveys ORDER BY updated_at DESC`)
    : env.DB.prepare(`SELECT * FROM surveys WHERE project_id = ? ORDER BY updated_at DESC`).bind(projectId);
  const rows = await statement.all<SurveyRow>();
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
  const projectId = requireProjectId(body.projectId);
  const project = await mustProject(db, projectId);
  const content = parseSurveyContent(body, project);
  const now = nowIso();
  const row = await db.prepare(
    `INSERT INTO surveys
       (project_id, title_translations, description_translations, status, web_enabled, created_by_admin_id,
        created_at, updated_at, starts_at, ends_at)
     VALUES (?, ?, ?, 'draft', ?, ?, ?, ?, ?, ?)
     RETURNING *`,
  )
    .bind(
      projectId,
      JSON.stringify(content.titleTranslations),
      JSON.stringify(content.descriptionTranslations),
      Object.hasOwn(body, 'webEnabled') ? boolToInt(requiredBoolean(body.webEnabled, 'webEnabled')) : 1,
      admin.id,
      now,
      now,
      optionalString(body.startsAt, 'startsAt'),
      optionalString(body.endsAt, 'endsAt'),
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
  const survey = requireObject(body.survey, 'survey');
  const questions = parseQuestionInputs(body.questions);
  const created = await insertSurvey(env.DB, survey, admin);

  for (let i = 0; i < questions.length; i++) {
    await insertQuestion(env.DB, {
      ...questions[i],
      surveyId: created.id,
      orderIndex: i,
    });
  }
  return json(surveyToJson(created), 201);
}

export async function updateSurvey(request: Request, env: Env, surveyId: number): Promise<Response> {
  const existing = await mustSurvey(env.DB, surveyId);
  const body = await readJson(request);
  const project = await mustProject(env.DB, existing.project_id);
  const content = parseSurveyContent(body, project);
  const row = await env.DB.prepare(
    `UPDATE surveys
     SET title_translations = ?, description_translations = ?,
         web_enabled = ?, starts_at = ?, ends_at = ?, updated_at = ?
     WHERE id = ?
     RETURNING *`,
  ).bind(
    JSON.stringify(content.titleTranslations),
    JSON.stringify(content.descriptionTranslations),
    Object.hasOwn(body, 'webEnabled') ? boolToInt(requiredBoolean(body.webEnabled, 'webEnabled')) : existing.web_enabled,
    optionalString(body.startsAt ?? existing.starts_at, 'startsAt'),
    optionalString(body.endsAt ?? existing.ends_at, 'endsAt'),
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
  if (!Array.isArray(value)) throw new HttpError(400, 'questions must be an array');
  return value.map((raw, index) => {
    if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
      throw new HttpError(400, `questions[${index}] must be an object`);
    }
    const question = raw as Record<string, unknown>;
    const type = normalizeQuestionType(question.type);
    if (!Array.isArray(question.choiceTranslations)) {
      throw new HttpError(400, `questions[${index}].choiceTranslations must be an array`);
    }
    const choiceTranslations = question.choiceTranslations.map((choice, choiceIndex) => requireLocalizedText(
      choice,
      `questions[${index}].choiceTranslations[${choiceIndex}]`,
      FORM_CONTENT_LOCALES,
    ));
    if (isChoiceQuestionType(type) && choiceTranslations.length === 0) {
      throw new HttpError(400, `questions[${index}].choiceTranslations must not be empty`);
    }
    if (isTextQuestionType(type) && choiceTranslations.length > 0) {
      throw new HttpError(400, `questions[${index}].choiceTranslations must be empty for text questions`);
    }
    return {
      textTranslations: requireLocalizedText(
        question.textTranslations,
        `questions[${index}].textTranslations`,
        FORM_CONTENT_LOCALES,
      ),
      type,
      isRequired: optionalBoolean(question.isRequired, `questions[${index}].isRequired`) ?? true,
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

function parseSurveyContent(body: Record<string, unknown>, project: ProjectRow): {
  titleTranslations: LocalizedText;
  descriptionTranslations: LocalizedText;
} {
  const supportedLocales = parseProjectLocales(project);
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

function parseProjectLocales(project: ProjectRow): string[] {
  try {
    const decoded = JSON.parse(project.supported_locales);
    if (!Array.isArray(decoded)) throw new Error('not an array');
    return decoded.map((locale, index) => {
      if (typeof locale !== 'string') throw new Error(`locale ${index} is not a string`);
      return locale;
    });
  } catch {
    throw new HttpError(500, 'Invalid project supported locales');
  }
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
