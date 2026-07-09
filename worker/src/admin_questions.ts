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
  optionalBoolean,
  optionalInteger,
  optionalString,
  readJson,
  requireNumberList,
  requiredInteger,
  requiredRow,
  updateOrder,
} from './utils';
import { choiceToJson, parseChoiceIds, questionToJson } from './serializers';
import { mustChoice, mustProject, mustQuestion, mustSurvey, projectSupportedLocales } from './admin_records';
import { defaultLocalizedText, requireLocalizedText } from './localization';
import { assertVisibilityOrderInvariant } from './visibility_rules';

type InsertQuestionInput = {
  surveyId: number;
  textTranslations: Record<string, string>;
  type: string;
  orderIndex: number;
  isRequired: boolean;
  placeholderTranslations: Record<string, string>;
  minLength: number | null;
  maxLength: number | null;
  minSelected: number | null;
  maxSelected: number | null;
  visibilityConditionMode: string;
  choiceTranslations?: readonly Record<string, string>[];
};

export async function createQuestion(request: Request, env: Env): Promise<Response> {
  const body = await readJson(request);
  const surveyId = requiredInteger(body.surveyId, 'surveyId', { min: 1 });
  const locales = await surveySupportedLocales(env.DB, surveyId);
  const type = normalizeQuestionType(body.type);
  const validation = normalizeQuestionValidation(body, type);
  const max = await env.DB.prepare(
    `SELECT MAX(order_index) AS max_order FROM questions WHERE survey_id = ?`,
  ).bind(surveyId).first<{ max_order: number | null }>();
  const question = await insertQuestion(env.DB, {
    surveyId,
    textTranslations: requireLocalizedText(body.textTranslations, 'textTranslations', locales),
    type,
    orderIndex: (max?.max_order ?? -1) + 1,
    isRequired: optionalBoolean(body.isRequired, 'isRequired') ?? true,
    placeholderTranslations: requireLocalizedText(
      body.placeholderTranslations,
      'placeholderTranslations',
      locales,
      { allowEmpty: true },
    ),
    ...validation,
    visibilityConditionMode: normalizeVisibilityConditionMode(body.visibilityConditionMode),
    choiceTranslations: [
      defaultLocalizedText('Choice 1', locales),
      defaultLocalizedText('Choice 2', locales),
    ],
  });
  return json(questionToJson(question), 201);
}

export async function insertQuestion(db: D1Database, input: InsertQuestionInput): Promise<QuestionRow> {
  const row = await db.prepare(
    `INSERT INTO questions
       (survey_id, text_translations, type, order_index, is_required, placeholder_translations,
        min_length, max_length, min_selected, max_selected, visibility_condition_mode)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
     RETURNING *`,
  ).bind(
    input.surveyId,
    JSON.stringify(input.textTranslations),
    input.type,
    input.orderIndex,
    boolToInt(input.isRequired),
    JSON.stringify(input.placeholderTranslations),
    input.minLength,
    input.maxLength,
    input.minSelected,
    input.maxSelected,
    input.visibilityConditionMode,
  ).first<QuestionRow>();
  const question = requiredRow(row, 'Question');
  if (isChoiceQuestionType(question.type) && input.choiceTranslations?.length) {
    await insertChoices(db, question.id, input.choiceTranslations);
  }
  return question;
}

export async function updateQuestion(request: Request, env: Env, questionId: number): Promise<Response> {
  const existing = await mustQuestion(env.DB, questionId);
  const locales = await surveySupportedLocales(env.DB, existing.survey_id);
  const body = await readJson(request);
  const type = normalizeQuestionType(body.type ?? existing.type);
  if (type !== existing.type) {
    const answerCount = await countRows(
      env.DB,
      `SELECT COUNT(*) AS count FROM answers WHERE question_id = ?`,
      questionId,
    );
    if (answerCount > 0) {
      throw new HttpError(400, 'Cannot change question type after responses exist');
    }
  }
  // Object.hasOwn: explicit null clears the constraint; omitted keys keep existing.
  // (?? would treat null as "keep", so empty Max length fields could never clear.)
  const validation = normalizeQuestionValidation(
    {
      minLength: Object.hasOwn(body, 'minLength') ? body.minLength : existing.min_length,
      maxLength: Object.hasOwn(body, 'maxLength') ? body.maxLength : existing.max_length,
      minSelected: Object.hasOwn(body, 'minSelected') ? body.minSelected : existing.min_selected,
      maxSelected: Object.hasOwn(body, 'maxSelected') ? body.maxSelected : existing.max_selected,
    },
    type,
  );
  const orderIndex = optionalInteger(body.orderIndex, 'orderIndex', { min: 0 }) ?? existing.order_index;
  if (orderIndex !== existing.order_index) {
    const siblings = await env.DB.prepare(
      `SELECT id, order_index FROM questions WHERE survey_id = ? AND is_deleted = 0`,
    ).bind(existing.survey_id).all<{ id: number; order_index: number }>();
    const proposed = new Map(
      siblings.results.map((row) => [
        row.id,
        row.id === questionId ? orderIndex : row.order_index,
      ]),
    );
    await assertVisibilityOrderInvariant(env.DB, existing.survey_id, proposed);
  }
  const row = await env.DB.prepare(
    `UPDATE questions
     SET text_translations = ?, type = ?, order_index = ?, is_required = ?, placeholder_translations = ?,
         min_length = ?, max_length = ?, min_selected = ?, max_selected = ?,
         visibility_condition_mode = ?, is_deleted = ?
     WHERE id = ?
     RETURNING *`,
  ).bind(
    JSON.stringify(requireLocalizedText(body.textTranslations, 'textTranslations', locales)),
    type,
    orderIndex,
    boolToInt(optionalBoolean(body.isRequired, 'isRequired') ?? (existing.is_required === 1)),
    JSON.stringify(requireLocalizedText(
      body.placeholderTranslations,
      'placeholderTranslations',
      locales,
      { allowEmpty: true },
    )),
    validation.minLength,
    validation.maxLength,
    validation.minSelected,
    validation.maxSelected,
    normalizeVisibilityConditionMode(body.visibilityConditionMode ?? existing.visibility_condition_mode),
    boolToInt(optionalBoolean(body.isDeleted, 'isDeleted') ?? (existing.is_deleted === 1)),
    questionId,
  ).first<QuestionRow>();
  return json(questionToJson(requiredRow(row, 'Question')));
}

export function normalizeVisibilityConditionMode(value: unknown): string {
  if (value == null) return 'all';
  if (typeof value !== 'string') throw new HttpError(400, 'Invalid visibility condition mode');
  const mode = value;
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
  const minLength = optionalInteger(body.minLength, 'minLength', { min: 0 });
  const maxLength = optionalInteger(body.maxLength, 'maxLength', { min: 0 });
  const minSelected = optionalInteger(body.minSelected, 'minSelected', { min: 0 });
  const maxSelected = optionalInteger(body.maxSelected, 'maxSelected', { min: 0 });
  if (minLength != null && maxLength != null && minLength > maxLength) {
    throw new HttpError(400, 'minLength cannot be greater than maxLength');
  }
  if (minSelected != null && maxSelected != null && minSelected > maxSelected) {
    throw new HttpError(400, 'minSelected cannot be greater than maxSelected');
  }
  if (type === 'singleChoice') {
    // singleChoice can select at most one option; min/max > 1 makes the form
    // unanswerable (every submit fails validation).
    if (minSelected != null && minSelected > 1) {
      throw new HttpError(400, 'singleChoice minSelected cannot be greater than 1');
    }
    if (maxSelected != null && maxSelected > 1) {
      throw new HttpError(400, 'singleChoice maxSelected cannot be greater than 1');
    }
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
  // Soft-delete does not cascade FK rules; drop visibility rules that reference
  // this question so public forms do not hide targets forever.
  const deleteVisibilityRules = env.DB.prepare(
    `DELETE FROM question_visibility_rules
     WHERE target_question_id = ? OR source_question_id = ?`,
  ).bind(questionId, questionId);
  if (answerCount > 0) {
    await env.DB.batch([
      deleteVisibilityRules,
      env.DB.prepare(`UPDATE questions SET is_deleted = 1 WHERE id = ?`).bind(questionId),
    ]);
    return json({ hardDeleted: false });
  }
  await env.DB.batch([
    deleteVisibilityRules,
    env.DB.prepare(`DELETE FROM choices WHERE question_id = ?`).bind(questionId),
    env.DB.prepare(`DELETE FROM questions WHERE id = ?`).bind(questionId),
  ]);
  await compactQuestionOrder(env.DB, question.survey_id);
  return json({ hardDeleted: true });
}

export async function reorderQuestions(request: Request, env: Env, surveyId: number): Promise<Response> {
  const body = await readJson(request);
  const questionIds = requireNumberList(body.questionIds, 'questionIds', { min: 1 });
  const rows = await env.DB.prepare(
    `SELECT * FROM questions WHERE survey_id = ? AND is_deleted = 0 ORDER BY order_index`,
  ).bind(surveyId).all<QuestionRow>();
  assertExactIds(rows.results.map((row) => row.id), questionIds, 'questionIds');
  // Reject reorder that would put a visibility source after its target.
  await assertVisibilityOrderInvariant(
    env.DB,
    surveyId,
    new Map(questionIds.map((id, index) => [id, index])),
  );
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
  if (!row) throw new HttpError(404, 'Question not found');
  return json(questionToJson(row));
}

export async function createChoice(request: Request, env: Env): Promise<Response> {
  const body = await readJson(request);
  const question = await mustQuestion(env.DB, requiredInteger(body.questionId, 'questionId', { min: 1 }));
  const locales = await surveySupportedLocales(env.DB, question.survey_id);
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
    JSON.stringify(requireLocalizedText(body.textTranslations, 'textTranslations', locales)),
    (max?.max_order ?? -1) + 1,
    optionalString(body.value, 'value'),
  ).first<ChoiceRow>();
  return json(choiceToJson(requiredRow(row, 'Choice')), 201);
}

export async function updateChoice(request: Request, env: Env, choiceId: number): Promise<Response> {
  const existing = await mustChoice(env.DB, choiceId);
  const question = await mustQuestion(env.DB, existing.question_id);
  const locales = await surveySupportedLocales(env.DB, question.survey_id);
  const body = await readJson(request);
  const row = await env.DB.prepare(
    `UPDATE choices SET text_translations = ?, order_index = ?, value = ? WHERE id = ? RETURNING *`,
  ).bind(
    JSON.stringify(requireLocalizedText(body.textTranslations, 'textTranslations', locales)),
    optionalInteger(body.orderIndex, 'orderIndex', { min: 0 }) ?? existing.order_index,
    optionalString(body.value ?? existing.value, 'value'),
    choiceId,
  ).first<ChoiceRow>();
  return json(choiceToJson(requiredRow(row, 'Choice')));
}

async function surveySupportedLocales(db: D1Database, surveyId: number): Promise<string[]> {
  const survey = await mustSurvey(db, surveyId);
  const project = await mustProject(db, survey.project_id);
  return projectSupportedLocales(project);
}

export async function deleteChoice(env: Env, choiceId: number): Promise<Response> {
  const choice = await mustChoice(env.DB, choiceId);
  const answers = await env.DB.prepare(
    `SELECT selected_choice_ids FROM answers
     WHERE question_id = ? AND selected_choice_ids IS NOT NULL`,
  ).bind(choice.question_id).all<{ selected_choice_ids: string }>();
  for (const answer of answers.results) {
    if (parseChoiceIds(answer.selected_choice_ids).includes(choiceId)) {
      throw new HttpError(
        400,
        'Cannot delete a choice that has been selected in responses',
      );
    }
  }
  await env.DB.prepare(`DELETE FROM choices WHERE id = ?`).bind(choiceId).run();
  return json({ ok: true });
}

export async function reorderChoices(request: Request, env: Env, questionId: number): Promise<Response> {
  const body = await readJson(request);
  const choiceIds = requireNumberList(body.choiceIds, 'choiceIds', { min: 1 });
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
  if (!row) throw new HttpError(404, 'Choice not found');
  return json(choiceToJson(row));
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
