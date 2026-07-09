import type { AdminContext, AnswerRow, ChoiceRow, Env, ProjectRow, QuestionRow, ReplyRow, ResponseRow } from './types';
import { mustProject, mustSurvey } from './admin_records';
import { HttpError, countRows, integerParam, isChoiceQuestionType, json, nowIso, readJson, requireString, requiredRow } from './utils';
import { answerToJson, choiceToJson, parseChoiceIds, projectToJson, questionToJson, replyToJson, responseToJson, surveyToJson } from './serializers';
import { DEFAULT_FORM_CONTENT_LOCALE, localizedTextFor } from './localization';

export async function listResponses(env: Env, surveyId: number, url: URL): Promise<Response> {
  const limit = integerParam(url.searchParams.get('limit'), 'limit', 50, { min: 1, max: 100 });
  const offset = integerParam(url.searchParams.get('offset'), 'offset', 0, { min: 0 });
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
        for (const choiceId of selected) incrementChoiceCount(counts, choiceId);
      }
      questionResults.push({
        questionId: question.id,
        questionText: localizedTextFor(question.text_translations, DEFAULT_FORM_CONTENT_LOCALE),
        questionType: question.type,
        choiceCounts: counts,
        textResponses: null,
      });
    } else {
      questionResults.push({
        questionId: question.id,
        questionText: localizedTextFor(question.text_translations, DEFAULT_FORM_CONTENT_LOCALE),
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
  const days = integerParam(url.searchParams.get('days'), 'days', 30, { min: 1, max: 365 });
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

export async function exportResponses(env: Env, surveyId: number, url: URL): Promise<Response> {
  const format = (url.searchParams.get('format') ?? 'csv').toLowerCase();
  if (format !== 'csv' && format !== 'json') {
    throw new HttpError(400, 'format must be csv or json');
  }

  const data = await loadExportData(env, surveyId, url);
  const timestamp = nowIso().replace(/[:.]/g, '-');
  const filename = `${safeFilename(data.project.slug)}-survey-${data.survey.id}-responses-${timestamp}.${format}`;

  if (format === 'json') {
    return new Response(JSON.stringify(toExportJson(data), null, 2), {
      headers: exportHeaders('application/json; charset=utf-8', filename),
    });
  }

  return new Response(toExportCsv(data), {
    headers: exportHeaders('text/csv; charset=utf-8', filename),
  });
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

type ExportData = {
  survey: Awaited<ReturnType<typeof mustSurvey>>;
  project: ProjectRow;
  questions: QuestionRow[];
  choicesByQuestion: Map<number, ChoiceRow[]>;
  responses: ResponseRow[];
  answersByResponse: Map<number, AnswerRow[]>;
  repliesByResponse: Map<number, ReplyRow[]>;
};

async function loadExportData(env: Env, surveyId: number, url: URL): Promise<ExportData> {
  const survey = await mustSurvey(env.DB, surveyId);
  const project = await mustProject(env.DB, survey.project_id);
  const questions = await env.DB.prepare(
    `SELECT * FROM questions WHERE survey_id = ? ORDER BY order_index`,
  ).bind(surveyId).all<QuestionRow>();
  const choices = await env.DB.prepare(
    `SELECT c.* FROM choices c
     JOIN questions q ON q.id = c.question_id
     WHERE q.survey_id = ?
     ORDER BY q.order_index, c.order_index`,
  ).bind(surveyId).all<ChoiceRow>();
  const dateFilter = exportDateFilter(url);
  const responses = await selectExportResponses(env, surveyId, dateFilter);
  const responseIds = responses.map((response) => response.id);
  const answers = responseIds.length === 0
    ? []
    : (await env.DB.prepare(
        `SELECT a.* FROM answers a
         JOIN survey_responses r ON r.id = a.survey_response_id
         WHERE r.survey_id = ?${dateFilter.sql}
         ORDER BY r.submitted_at DESC, a.id`,
      ).bind(surveyId, ...dateFilter.binds).all<AnswerRow>()).results;
  const replies = responseIds.length === 0
    ? []
    : (await env.DB.prepare(
        `SELECT ar.* FROM admin_replies ar
         JOIN survey_responses r ON r.id = ar.survey_response_id
         WHERE r.survey_id = ?${dateFilter.sql}
         ORDER BY ar.created_at`,
      ).bind(surveyId, ...dateFilter.binds).all<ReplyRow>()).results;

  return {
    survey,
    project,
    questions: questions.results,
    choicesByQuestion: groupBy(choices.results, (choice) => choice.question_id),
    responses,
    answersByResponse: groupBy(answers, (answer) => answer.survey_response_id),
    repliesByResponse: groupBy(replies, (reply) => reply.survey_response_id),
  };
}

type ExportDateFilter = { sql: string; binds: unknown[] };

function exportDateFilter(url: URL): ExportDateFilter {
  const from = url.searchParams.get('from');
  const to = url.searchParams.get('to');
  const conditions: string[] = [];
  const binds: unknown[] = [];
  if (from) {
    conditions.push('r.submitted_at >= ?');
    binds.push(parseDateParam(from, 'from', 'start'));
  }
  if (to) {
    conditions.push('r.submitted_at <= ?');
    binds.push(parseDateParam(to, 'to', 'end'));
  }
  return {
    sql: conditions.length > 0 ? ` AND ${conditions.join(' AND ')}` : '',
    binds,
  };
}

async function selectExportResponses(
  env: Env,
  surveyId: number,
  dateFilter: ExportDateFilter,
): Promise<ResponseRow[]> {
  const rows = await env.DB.prepare(
    `SELECT r.id, r.survey_id, r.anonymous_account_id, r.anonymous_id, r.submitted_at, r.user_agent,
       r.device_id, r.device_label, r.device_platform, r.device_os, r.device_os_version,
       r.device_browser, r.device_browser_version, r.device_locale, r.device_timezone,
       r.screen_width, r.screen_height, r.device_pixel_ratio, r.device_info, r.metadata
     FROM survey_responses r
     WHERE r.survey_id = ?${dateFilter.sql}
     ORDER BY r.submitted_at DESC`,
  ).bind(surveyId, ...dateFilter.binds).all<ResponseRow>();
  return rows.results;
}

function toExportJson(data: ExportData) {
  return {
    exportedAt: nowIso(),
    project: projectToJson(data.project),
    survey: surveyToJson(data.survey),
    responseCount: data.responses.length,
    questions: data.questions.map((question) => ({
      ...questionToJson(question),
      choices: (data.choicesByQuestion.get(question.id) ?? []).map(choiceToJson),
    })),
    responses: data.responses.map((response) => ({
      ...responseToJson(response),
      answers: (data.answersByResponse.get(response.id) ?? []).map(answerToJson),
      replies: (data.repliesByResponse.get(response.id) ?? []).map(replyToJson),
    })),
  };
}

function toExportCsv(data: ExportData): string {
  const questions = data.questions;
  const headers = [
    'responseId',
    'submittedAt',
    'anonymousId',
    'anonymousAccountId',
    'deviceId',
    'deviceLabel',
    'devicePlatform',
    'deviceOs',
    'deviceOsVersion',
    'deviceBrowser',
    'deviceBrowserVersion',
    'deviceLocale',
    'deviceTimezone',
    'screenWidth',
    'screenHeight',
    'devicePixelRatio',
    'userAgent',
    'metadataJson',
    'adminReplies',
    ...questions.map((question) => questionColumnName(question)),
  ];
  const choiceTextByQuestion = new Map<number, Map<number, string>>();
  for (const question of questions) {
    choiceTextByQuestion.set(
      question.id,
      new Map((data.choicesByQuestion.get(question.id) ?? []).map((choice) => [
        choice.id,
        localizedTextFor(choice.text_translations, DEFAULT_FORM_CONTENT_LOCALE),
      ])),
    );
  }
  const lines = [headers.map(csvCell).join(',')];
  for (const response of data.responses) {
    const answers = new Map(
      (data.answersByResponse.get(response.id) ?? []).map((answer) => [answer.question_id, answer]),
    );
    const replies = (data.repliesByResponse.get(response.id) ?? [])
      .map((reply) => `${reply.created_at}: ${reply.body}`)
      .join('\n');
    const row = [
      response.id,
      response.submitted_at,
      response.anonymous_id,
      response.anonymous_account_id,
      response.device_id,
      response.device_label,
      response.device_platform,
      response.device_os,
      response.device_os_version,
      response.device_browser,
      response.device_browser_version,
      response.device_locale,
      response.device_timezone,
      response.screen_width,
      response.screen_height,
      response.device_pixel_ratio,
      response.user_agent,
      response.metadata,
      replies,
      ...questions.map((question) =>
        formatAnswerForCsv(
          question,
          answers.get(question.id),
          choiceTextByQuestion.get(question.id) ?? new Map(),
        ),
      ),
    ];
    lines.push(row.map(csvCell).join(','));
  }
  return `${lines.join('\n')}\n`;
}

export function formatAnswerForCsv(
  question: QuestionRow,
  answer: AnswerRow | undefined,
  choiceTextById: Map<number, string>,
): string {
  if (!answer) return '';
  if (!isChoiceQuestionType(question.type)) return answer.text_value ?? '';
  return parseChoiceIds(answer.selected_choice_ids)
    .map((choiceId) => choiceTextForCsv(choiceTextById, choiceId))
    .join('; ');
}

export function incrementChoiceCount(counts: Record<string, number>, choiceId: number): void {
  const key = String(choiceId);
  // Skip orphaned choice ids (deleted after answers were stored) so aggregates
  // and exports never 500 on historical data.
  if (!Object.hasOwn(counts, key)) return;
  counts[key] += 1;
}

function choiceTextForCsv(choiceTextById: Map<number, string>, choiceId: number): string {
  return choiceTextById.get(choiceId) ?? `[deleted choice ${choiceId}]`;
}

function questionColumnName(question: QuestionRow): string {
  const prefix = `Q${question.order_index + 1}`;
  return `${prefix}: ${localizedTextFor(question.text_translations, DEFAULT_FORM_CONTENT_LOCALE)}`;
}

/** Escape CSV formula injection (=, +, -, @, tab, CR) and quote special cells. */
export function csvCell(value: unknown): string {
  if (value == null) return '';
  let text = String(value);
  if (/^[=+\-@\t\r]/.test(text)) {
    text = `'${text}`;
  }
  if (!/[",\n\r]/.test(text)) return text;
  return `"${text.replaceAll('"', '""')}"`;
}

function exportHeaders(contentType: string, filename: string): HeadersInit {
  return {
    'content-type': contentType,
    'content-disposition': `attachment; filename="${filename}"`,
    'access-control-allow-origin': '*',
    'access-control-expose-headers': 'content-disposition',
  };
}

function safeFilename(value: string): string {
  return value.replace(/[^a-z0-9-]+/gi, '-').replace(/-+/g, '-').replace(/^-|-$/g, '') || 'survey';
}

function parseDateParam(value: string, field: string, bound: 'start' | 'end' = 'start'): string {
  // Date-only values (YYYY-MM-DD) normalize to start/end of that UTC day so
  // `to=2026-07-10` includes responses submitted on that day.
  const normalized = /^\d{4}-\d{2}-\d{2}$/.test(value)
    ? bound === 'end'
      ? `${value}T23:59:59.999Z`
      : `${value}T00:00:00.000Z`
    : value;
  const date = new Date(normalized);
  if (Number.isNaN(date.getTime())) throw new HttpError(400, `${field} must be a valid date`);
  return date.toISOString();
}

function groupBy<T>(values: T[], keyOf: (value: T) => number): Map<number, T[]> {
  const result = new Map<number, T[]>();
  for (const value of values) {
    const key = keyOf(value);
    const group = result.get(key) ?? [];
    group.push(value);
    result.set(key, group);
  }
  return result;
}
