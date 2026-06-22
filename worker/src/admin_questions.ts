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
  requireString,
  requiredRow,
  updateOrder,
} from './utils';
import { choiceToJson, questionToJson } from './serializers';
import { mustChoice, mustQuestion, mustSurvey } from './admin_records';

export async function createQuestion(request: Request, env: Env): Promise<Response> {
  const body = await readJson(request);
  const surveyId = Number(body.surveyId);
  await mustSurvey(env.DB, surveyId);
  const max = await env.DB.prepare(
    `SELECT MAX(order_index) AS max_order FROM questions WHERE survey_id = ?`,
  ).bind(surveyId).first<{ max_order: number | null }>();
  const row = await env.DB.prepare(
    `INSERT INTO questions
       (survey_id, text, type, order_index, is_required, placeholder, min_length, max_length)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)
     RETURNING *`,
  ).bind(
    surveyId,
    requireString(body.text, 'text'),
    normalizeQuestionType(body.type),
    (max?.max_order ?? -1) + 1,
    boolToInt(body.isRequired !== false),
    optionalString(body.placeholder),
    optionalNumber(body.minLength),
    optionalNumber(body.maxLength),
  ).first<QuestionRow>();
  const question = requiredRow(row, 'Question');
  if (isChoiceQuestionType(question.type)) {
    await insertChoices(env.DB, question.id, ['Choice 1', 'Choice 2']);
  }
  return json(questionToJson(question), 201);
}

export async function updateQuestion(request: Request, env: Env, questionId: number): Promise<Response> {
  const existing = await mustQuestion(env.DB, questionId);
  const body = await readJson(request);
  const row = await env.DB.prepare(
    `UPDATE questions
     SET text = ?, type = ?, order_index = ?, is_required = ?, placeholder = ?,
         min_length = ?, max_length = ?, is_deleted = ?
     WHERE id = ?
     RETURNING *`,
  ).bind(
    requireString(body.text ?? existing.text, 'text'),
    normalizeQuestionType(body.type ?? existing.type),
    optionalNumber(body.orderIndex) ?? existing.order_index,
    boolToInt(body.isRequired ?? existing.is_required === 1),
    optionalString(body.placeholder ?? existing.placeholder),
    optionalNumber(body.minLength ?? existing.min_length),
    optionalNumber(body.maxLength ?? existing.max_length),
    boolToInt(body.isDeleted ?? existing.is_deleted === 1),
    questionId,
  ).first<QuestionRow>();
  return json(questionToJson(requiredRow(row, 'Question')));
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
    `INSERT INTO choices (question_id, text, order_index, value)
     VALUES (?, ?, ?, ?)
     RETURNING *`,
  ).bind(
    question.id,
    requireString(body.text, 'text'),
    (max?.max_order ?? -1) + 1,
    optionalString(body.value),
  ).first<ChoiceRow>();
  return json(choiceToJson(requiredRow(row, 'Choice')), 201);
}

export async function updateChoice(request: Request, env: Env, choiceId: number): Promise<Response> {
  const existing = await mustChoice(env.DB, choiceId);
  const body = await readJson(request);
  const row = await env.DB.prepare(
    `UPDATE choices SET text = ?, order_index = ?, value = ? WHERE id = ? RETURNING *`,
  ).bind(
    requireString(body.text ?? existing.text, 'text'),
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
