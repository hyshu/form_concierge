import type { AdminContext, AnswerRow, ChoiceRow, Env, QuestionRow, ReplyRow, ResponseRow } from './types';
import { HttpError, countRows, isChoiceQuestionType, json, nowIso, readJson, requireString, requiredRow } from './utils';
import { answerToJson, parseChoiceIds, replyToJson, responseToJson } from './serializers';

export async function listResponses(env: Env, surveyId: number, url: URL): Promise<Response> {
  const limit = Math.min(Number(url.searchParams.get('limit') ?? '50'), 100);
  const offset = Math.max(Number(url.searchParams.get('offset') ?? '0'), 0);
  const rows = await env.DB.prepare(
    `SELECT id, survey_id, anonymous_account_id, anonymous_id, submitted_at, user_agent,
       device_id, device_label, device_platform, device_os, device_os_version,
       device_browser, device_browser_version, device_locale, device_timezone,
       screen_width, screen_height, device_pixel_ratio, device_info, metadata
     FROM survey_responses
     WHERE survey_id = ?
     ORDER BY submitted_at DESC
     LIMIT ? OFFSET ?`,
  ).bind(surveyId, limit, offset).all<ResponseRow>();
  return json(rows.results.map(responseToJson));
}

export async function responseCount(env: Env, surveyId: number): Promise<Response> {
  return json({
    count: await countRows(
      env.DB,
      `SELECT COUNT(*) AS count FROM survey_responses WHERE survey_id = ?`,
      surveyId,
    ),
  });
}

export async function responseAnswers(env: Env, responseId: number): Promise<Response> {
  const rows = await env.DB.prepare(
    `SELECT * FROM answers WHERE survey_response_id = ?`,
  ).bind(responseId).all<AnswerRow>();
  return json(rows.results.map(answerToJson));
}

export async function aggregatedResults(env: Env, surveyId: number): Promise<Response> {
  const totalResponses = await countRows(
    env.DB,
    `SELECT COUNT(*) AS count FROM survey_responses WHERE survey_id = ?`,
    surveyId,
  );
  const questions = await env.DB.prepare(
    `SELECT * FROM questions WHERE survey_id = ? ORDER BY order_index`,
  ).bind(surveyId).all<QuestionRow>();
  const questionResults = [];
  for (const question of questions.results) {
    const answers = await env.DB.prepare(
      `SELECT * FROM answers WHERE question_id = ?`,
    ).bind(question.id).all<AnswerRow>();
    if (isChoiceQuestionType(question.type)) {
      const choices = await env.DB.prepare(
        `SELECT * FROM choices WHERE question_id = ?`,
      ).bind(question.id).all<ChoiceRow>();
      const counts: Record<string, number> = {};
      for (const choice of choices.results) counts[String(choice.id)] = 0;
      for (const answer of answers.results) {
        const selected = parseChoiceIds(answer.selected_choice_ids);
        for (const choiceId of selected) counts[String(choiceId)] = (counts[String(choiceId)] ?? 0) + 1;
      }
      questionResults.push({
        questionId: question.id,
        questionText: question.text,
        questionType: question.type,
        choiceCounts: counts,
        textResponses: null,
      });
    } else {
      questionResults.push({
        questionId: question.id,
        questionText: question.text,
        questionType: question.type,
        choiceCounts: null,
        textResponses: answers.results
          .map((answer) => answer.text_value)
          .filter((value): value is string => Boolean(value)),
      });
    }
  }
  return json({ surveyId, totalResponses, questionResults });
}

export async function responseTrends(env: Env, surveyId: number, url: URL): Promise<Response> {
  const days = Math.min(Math.max(Number(url.searchParams.get('days') ?? '30'), 1), 365);
  const start = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
  const rows = await env.DB.prepare(
    `SELECT submitted_at FROM survey_responses WHERE survey_id = ? AND submitted_at >= ?`,
  ).bind(surveyId, start.toISOString()).all<{ submitted_at: string }>();
  const result: Record<string, number> = {};
  for (let i = 0; i < days; i++) {
    const date = new Date(start.getTime() + i * 24 * 60 * 60 * 1000)
      .toISOString()
      .slice(0, 10);
    result[date] = 0;
  }
  for (const row of rows.results) {
    const date = row.submitted_at.slice(0, 10);
    result[date] = (result[date] ?? 0) + 1;
  }
  return json(result);
}

export async function deleteResponse(env: Env, responseId: number): Promise<Response> {
  await env.DB.prepare(`DELETE FROM survey_responses WHERE id = ?`).bind(responseId).run();
  return json({ ok: true });
}

export async function createReply(
  request: Request,
  env: Env,
  admin: AdminContext,
  responseId: number,
): Promise<Response> {
  const body = await readJson(request);
  const response = await env.DB.prepare(
    `SELECT id, anonymous_account_id FROM survey_responses WHERE id = ?`,
  ).bind(responseId).first<{ id: number; anonymous_account_id: string }>();
  if (!response) throw new HttpError(404, 'Response not found');
  const row = await env.DB.prepare(
    `INSERT INTO admin_replies
       (survey_response_id, anonymous_account_id, admin_id, body, created_at)
     VALUES (?, ?, ?, ?, ?)
     RETURNING *`,
  ).bind(
    response.id,
    response.anonymous_account_id,
    admin.id,
    requireString(body.body, 'body'),
    nowIso(),
  ).first<ReplyRow>();
  return json(replyToJson(requiredRow(row, 'Reply')), 201);
}

export async function getReplies(env: Env, responseId: number): Promise<Response> {
  const rows = await env.DB.prepare(
    `SELECT * FROM admin_replies WHERE survey_response_id = ? ORDER BY created_at DESC`,
  ).bind(responseId).all<ReplyRow>();
  return json(rows.results.map(replyToJson));
}
