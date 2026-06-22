import type { ChoiceRow, Env, QuestionRow } from './types';
import {
  HttpError,
  assertExactIds,
  boolToInt,
  countRows,
  insertChoices,
  isChoiceQuestionType,
  json,
  normalizeQuestionType,
  optionalNumber,
  optionalString,
  readJson,
  requireNumberList,
  requiredRow,
  updateOrder,
} from './utils';
import { choiceToJson, questionToJson } from './serializers';
import { mustChoice, mustQuestion, mustSurvey } from './admin_records';
import { FORM_CONTENT_LOCALES, defaultLocalizedText, requireLocalizedText } from './localization';

export async function createQuestion(request: Request, env: Env): Promise<Response> {
  const body = await readJson(request);
  const surveyId = Number(body.surveyId);
  await mustSurvey(env.DB, surveyId);
  const type = normalizeQuestionType(body.type);
  const validation = normalizeQuestionValidation(body, type);
  const max = await env.DB.prepare(
    `SELECT MAX(order_index) AS max_order FROM questions WHERE survey_id = ?`,
  ).bind(surveyId).first<{ max_order: number | null }>();
  const row = await env.DB.prepare(
    `INSERT INTO questions
       (survey_id, text_translations, type, order_index, is_required, placeholder_translations,
        min_length, max_length, min_selected, max_selected, visibility_condition_mode)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
     RETURNING *`,
  ).bind(
    surveyId,
    JSON.stringify(requireLocalizedText(body.textTranslations, 'textTranslations', FORM_CONTENT_LOCALES)),
    type,
    (max?.max_order ?? -1) + 1,
    boolToInt(body.isRequired !== false),
    JSON.stringify(requireLocalizedText(
      body.placeholderTranslations,
      'placeholderTranslations',
      FORM_CONTENT_LOCALES,
      { allowEmpty: true },
    )),
    validation.minLength,
    validation.maxLength,
    validation.minSelected,
    validation.maxSelected,
    normalizeVisibilityConditionMode(body.visibilityConditionMode),
  ).first<QuestionRow>();
  const question = requiredRow(row, 'Question');
  if (isChoiceQuestionType(question.type)) {
    await insertChoices(env.DB, question.id, [
      defaultLocalizedText('Choice 1'),
      defaultLocalizedText('Choice 2'),
    ]);
  }
  return json(questionToJson(question), 201);
}

export async function updateQuestion(request: Request, env: Env, questionId: number): Promise<Response> {
  const existing = await mustQuestion(env.DB, questionId);
  const body = await readJson(request);
  const type = normalizeQuestionType(body.type ?? existing.type);
  const validation = normalizeQuestionValidation(
    {
      minLength: body.minLength ?? existing.min_length,
      maxLength: body.maxLength ?? existing.max_length,
      minSelected: body.minSelected ?? existing.min_selected,
      maxSelected: body.maxSelected ?? existing.max_selected,
    },
    type,
  );
  const row = await env.DB.prepare(
    `UPDATE questions
     SET text_translations = ?, type = ?, order_index = ?, is_required = ?, placeholder_translations = ?,
         min_length = ?, max_length = ?, min_selected = ?, max_selected = ?,
         visibility_condition_mode = ?, is_deleted = ?
     WHERE id = ?
     RETURNING *`,
  ).bind(
    JSON.stringify(requireLocalizedText(body.textTranslations, 'textTranslations', FORM_CONTENT_LOCALES)),
    type,
    optionalNumber(body.orderIndex) ?? existing.order_index,
    boolToInt(body.isRequired ?? existing.is_required === 1),
    JSON.stringify(requireLocalizedText(
      body.placeholderTranslations,
      'placeholderTranslations',
      FORM_CONTENT_LOCALES,
      { allowEmpty: true },
    )),
    validation.minLength,
    validation.maxLength,
    validation.minSelected,
    validation.maxSelected,
    normalizeVisibilityConditionMode(body.visibilityConditionMode ?? existing.visibility_condition_mode),
    boolToInt(body.isDeleted ?? existing.is_deleted === 1),
    questionId,
  ).first<QuestionRow>();
  return json(questionToJson(requiredRow(row, 'Question')));
}

export function normalizeVisibilityConditionMode(value: unknown): string {
  const mode = String(value ?? 'all');
  if (mode === 'all' || mode === 'any') return mode;
  throw new HttpError(400, 'Invalid visibility condition mode');
}

export function normalizeQuestionValidation(
  body: Record<string, unknown>,
  type: string,
): {
  minLength: number | null;
  maxLength: number | null;
  minSelected: number | null;
  maxSelected: number | null;
} {
  const minLength = optionalNumber(body.minLength);
  const maxLength = optionalNumber(body.maxLength);
  const minSelected = optionalNumber(body.minSelected);
  const maxSelected = optionalNumber(body.maxSelected);
  for (const [field, value] of Object.entries({ minLength, maxLength, minSelected, maxSelected })) {
    if (value != null && (!Number.isInteger(value) || value < 0)) {
      throw new HttpError(400, `${field} must be a non-negative integer`);
    }
  }
  if (minLength != null && maxLength != null && minLength > maxLength) {
    throw new HttpError(400, 'minLength cannot be greater than maxLength');
  }
  if (minSelected != null && maxSelected != null && minSelected > maxSelected) {
    throw new HttpError(400, 'minSelected cannot be greater than maxSelected');
  }
  if (type === 'singleChoice' && maxSelected != null && maxSelected > 1) {
    throw new HttpError(400, 'singleChoice maxSelected cannot be greater than 1');
  }
  return {
    minLength: isTextQuestionTypeName(type) ? minLength : null,
    maxLength: isTextQuestionTypeName(type) ? maxLength : null,
    minSelected: isChoiceQuestionType(type) ? minSelected : null,
    maxSelected: isChoiceQuestionType(type) ? maxSelected : null,
  };
}

function isTextQuestionTypeName(type: string): boolean {
  return type === 'textSingle' || type === 'textMultiLine';
}

export async function deleteQuestion(env: Env, questionId: number): Promise<Response> {
  const question = await mustQuestion(env.DB, questionId);
  const answerCount = await countRows(
    env.DB,
    `SELECT COUNT(*) AS count FROM answers WHERE question_id = ?`,
    questionId,
  );
  if (answerCount > 0) {
    await env.DB.prepare(`UPDATE questions SET is_deleted = 1 WHERE id = ?`)
      .bind(questionId)
      .run();
    return json({ hardDeleted: false });
  }
  await env.DB.batch([
    env.DB.prepare(`DELETE FROM choices WHERE question_id = ?`).bind(questionId),
    env.DB.prepare(`DELETE FROM questions WHERE id = ?`).bind(questionId),
  ]);
  await compactQuestionOrder(env.DB, question.survey_id);
  return json({ hardDeleted: true });
}

export async function reorderQuestions(request: Request, env: Env, surveyId: number): Promise<Response> {
  const body = await readJson(request);
  const questionIds = requireNumberList(body.questionIds, 'questionIds');
  const rows = await env.DB.prepare(
    `SELECT * FROM questions WHERE survey_id = ? AND is_deleted = 0 ORDER BY order_index`,
  ).bind(surveyId).all<QuestionRow>();
  assertExactIds(rows.results.map((row) => row.id), questionIds, 'questionIds');
  await updateOrder(env.DB, 'questions', questionIds);
  return getAdminQuestions(env, surveyId);
}

export async function getAdminQuestions(env: Env, surveyId: number): Promise<Response> {
  const rows = await env.DB.prepare(
    `SELECT * FROM questions WHERE survey_id = ? AND is_deleted = 0 ORDER BY order_index`,
  ).bind(surveyId).all<QuestionRow>();
  return json(rows.results.map(questionToJson));
}

export async function getQuestion(env: Env, questionId: number): Promise<Response> {
  const row = await env.DB.prepare(`SELECT * FROM questions WHERE id = ?`)
    .bind(questionId)
    .first<QuestionRow>();
  return json(row ? questionToJson(row) : null);
}

export async function createChoice(request: Request, env: Env): Promise<Response> {
  const body = await readJson(request);
  const question = await mustQuestion(env.DB, Number(body.questionId));
  if (!isChoiceQuestionType(question.type)) {
    throw new HttpError(400, 'Only choice questions can have choices');
  }
  const max = await env.DB.prepare(
    `SELECT MAX(order_index) AS max_order FROM choices WHERE question_id = ?`,
  ).bind(question.id).first<{ max_order: number | null }>();
  const row = await env.DB.prepare(
    `INSERT INTO choices (question_id, text_translations, order_index, value)
     VALUES (?, ?, ?, ?)
     RETURNING *`,
  ).bind(
    question.id,
    JSON.stringify(requireLocalizedText(body.textTranslations, 'textTranslations', FORM_CONTENT_LOCALES)),
    (max?.max_order ?? -1) + 1,
    optionalString(body.value),
  ).first<ChoiceRow>();
  return json(choiceToJson(requiredRow(row, 'Choice')), 201);
}

export async function updateChoice(request: Request, env: Env, choiceId: number): Promise<Response> {
  const existing = await mustChoice(env.DB, choiceId);
  const body = await readJson(request);
  const row = await env.DB.prepare(
    `UPDATE choices SET text_translations = ?, order_index = ?, value = ? WHERE id = ? RETURNING *`,
  ).bind(
    JSON.stringify(requireLocalizedText(body.textTranslations, 'textTranslations', FORM_CONTENT_LOCALES)),
    optionalNumber(body.orderIndex) ?? existing.order_index,
    optionalString(body.value ?? existing.value),
    choiceId,
  ).first<ChoiceRow>();
  return json(choiceToJson(requiredRow(row, 'Choice')));
}

export async function deleteChoice(env: Env, choiceId: number): Promise<Response> {
  await mustChoice(env.DB, choiceId);
  await env.DB.prepare(`DELETE FROM choices WHERE id = ?`).bind(choiceId).run();
  return json({ ok: true });
}

export async function reorderChoices(request: Request, env: Env, questionId: number): Promise<Response> {
  const body = await readJson(request);
  const choiceIds = requireNumberList(body.choiceIds, 'choiceIds');
  const rows = await env.DB.prepare(
    `SELECT * FROM choices WHERE question_id = ? ORDER BY order_index`,
  ).bind(questionId).all<ChoiceRow>();
  assertExactIds(rows.results.map((row) => row.id), choiceIds, 'choiceIds');
  await updateOrder(env.DB, 'choices', choiceIds);
  return getChoices(env, questionId);
}

export async function getChoices(env: Env, questionId: number): Promise<Response> {
  const rows = await env.DB.prepare(
    `SELECT * FROM choices WHERE question_id = ? ORDER BY order_index`,
  ).bind(questionId).all<ChoiceRow>();
  return json(rows.results.map(choiceToJson));
}

export async function getChoice(env: Env, choiceId: number): Promise<Response> {
  const row = await env.DB.prepare(`SELECT * FROM choices WHERE id = ?`)
    .bind(choiceId)
    .first<ChoiceRow>();
  return json(row ? choiceToJson(row) : null);
}

async function compactQuestionOrder(db: D1Database, surveyId: number): Promise<void> {
  const rows = await db.prepare(
    `SELECT id, order_index FROM questions
     WHERE survey_id = ? AND is_deleted = 0
     ORDER BY order_index`,
  ).bind(surveyId).all<{ id: number; order_index: number }>();
  const updates = rows.results
    .map((row, index) => row.order_index === index
      ? null
      : db.prepare(`UPDATE questions SET order_index = ? WHERE id = ?`).bind(index, row.id))
    .filter((statement): statement is D1PreparedStatement => statement !== null);
  if (updates.length > 0) await db.batch(updates);
}
