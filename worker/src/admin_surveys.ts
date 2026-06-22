import type { AdminContext, ChoiceRow, Env, NotificationSettingsRow, QuestionInput, QuestionRow, SurveyRow } from './types';
import {
  HttpError,
  assertExactIds,
  boolToInt,
  countRows,
  insertChoices,
  isChoiceQuestionType,
  json,
  normalizeQuestionType,
  nowIso,
  objectBody,
  optionalNumber,
  optionalString,
  readJson,
  requireNumberList,
  requireSlug,
  requireString,
  requiredRow,
  updateOrder,
} from './utils';
import { choiceToJson, notificationToJson, questionToJson, surveyToJson } from './serializers';

export async function listSurveys(env: Env, admin: AdminContext): Promise<Response> {
  const rows = await env.DB.prepare(
    `SELECT * FROM surveys
     WHERE created_by_admin_id = ?
     ORDER BY updated_at DESC`,
  ).bind(admin.id).all<SurveyRow>();
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
  const now = nowIso();
  const row = await db.prepare(
    `INSERT INTO surveys
       (slug, title, description, status, auth_requirement, created_by_admin_id,
        created_at, updated_at, starts_at, ends_at)
     VALUES (?, ?, ?, 'draft', ?, ?, ?, ?, ?, ?)
     RETURNING *`,
  )
    .bind(
      slug,
      requireString(body.title, 'title'),
      optionalString(body.description),
      body.authRequirement === 'authenticated' ? 'authenticated' : 'anonymous',
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
         (survey_id, text, type, order_index, is_required, placeholder)
       VALUES (?, ?, ?, ?, ?, ?)
       RETURNING *`,
    ).bind(
      created.id,
      q.text,
      q.type,
      i,
      boolToInt(q.isRequired),
      q.placeholder,
    ).first<QuestionRow>();
    if (!question) throw new HttpError(500, 'Failed to create question');
    if (isChoiceQuestionType(question.type)) {
      await insertChoices(env.DB, question.id, q.choices.map(String));
    }
  }
  return json(surveyToJson(created), 201);
}

export async function updateSurvey(request: Request, env: Env, surveyId: number): Promise<Response> {
  const existing = await mustSurvey(env.DB, surveyId);
  const body = await readJson(request);
  const slug = requireSlug(body.slug ?? existing.slug);
  await ensureUniqueSlug(env.DB, slug, surveyId);
  const row = await env.DB.prepare(
    `UPDATE surveys
     SET slug = ?, title = ?, description = ?, auth_requirement = ?,
         starts_at = ?, ends_at = ?, updated_at = ?
     WHERE id = ?
     RETURNING *`,
  ).bind(
    slug,
    requireString(body.title ?? existing.title, 'title'),
    optionalString(body.description ?? existing.description),
    body.authRequirement === 'authenticated' ? 'authenticated' : 'anonymous',
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

export async function notificationSettings(
  request: Request,
  env: Env,
  surveyId: number,
  parts: string[],
): Promise<Response> {
  const method = request.method.toUpperCase();
  if (method === 'GET') {
    const row = await env.DB.prepare(
      `SELECT * FROM notification_settings WHERE survey_id = ?`,
    ).bind(surveyId).first<NotificationSettingsRow>();
    return json(row ? notificationToJson(row) : null);
  }
  if (method === 'PUT') {
    const body = await readJson(request);
    const row = await env.DB.prepare(
      `INSERT INTO notification_settings
         (survey_id, enabled, recipient_email, send_hour, updated_at)
       VALUES (?, ?, ?, ?, ?)
       ON CONFLICT(survey_id) DO UPDATE SET
         enabled = excluded.enabled,
         recipient_email = excluded.recipient_email,
         send_hour = excluded.send_hour,
         updated_at = excluded.updated_at
       RETURNING *`,
    ).bind(
      surveyId,
      boolToInt(body.enabled),
      requireString(body.recipientEmail, 'recipientEmail'),
      optionalNumber(body.sendHour) ?? 9,
      nowIso(),
    ).first<NotificationSettingsRow>();
    return json(notificationToJson(requiredRow(row, 'NotificationSettings')));
  }
  if (method === 'POST' && parts[5] === 'toggle') {
    const body = await readJson(request);
    const row = await env.DB.prepare(
      `UPDATE notification_settings SET enabled = ?, updated_at = ?
       WHERE survey_id = ? RETURNING *`,
    ).bind(boolToInt(body.enabled), nowIso(), surveyId).first<NotificationSettingsRow>();
    return json(notificationToJson(requiredRow(row, 'NotificationSettings')));
  }
  if (method === 'DELETE') {
    await env.DB.prepare(`DELETE FROM notification_settings WHERE survey_id = ?`)
      .bind(surveyId)
      .run();
    return json({ ok: true });
  }
  return json({ error: 'Not found' }, 404);
}

async function mustSurvey(db: D1Database, id: number): Promise<SurveyRow> {
  const row = await db.prepare(`SELECT * FROM surveys WHERE id = ?`).bind(id).first<SurveyRow>();
  if (!row) throw new HttpError(404, 'Survey not found');
  return row;
}

async function mustQuestion(db: D1Database, id: number): Promise<QuestionRow> {
  const row = await db.prepare(`SELECT * FROM questions WHERE id = ?`).bind(id).first<QuestionRow>();
  if (!row) throw new HttpError(404, 'Question not found');
  return row;
}

async function mustChoice(db: D1Database, id: number): Promise<ChoiceRow> {
  const row = await db.prepare(`SELECT * FROM choices WHERE id = ?`).bind(id).first<ChoiceRow>();
  if (!row) throw new HttpError(404, 'Choice not found');
  return row;
}

function parseQuestionInputs(value: unknown): QuestionInput[] {
  if (!Array.isArray(value)) return [];
  return value.map((raw, index) => {
    const question = typeof raw === 'object' && raw !== null ? raw as Record<string, unknown> : {};
    const type = normalizeQuestionType(question.type);
    const choices = Array.isArray(question.choices)
      ? question.choices.map((choice) => requireString(choice, `questions[${index}].choices`))
      : [];
    return {
      text: requireString(question.text, `questions[${index}].text`),
      type,
      isRequired: question.isRequired !== false,
      placeholder: optionalString(question.placeholder),
      choices,
    };
  });
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
      throw new HttpError(400, `Question "${question.text}" must have at least one choice`);
    }
  }
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
