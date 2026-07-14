import type { AdminContext, AnswerRow, ChoiceRow, Env, ProjectRow, QuestionRow, ReplyRow, ResponseRow } from './types';
import { mustProject, mustSurvey } from './admin_records';
import {
  HttpError,
  countRows,
  integerParam,
  isChoiceQuestionType,
  isImageUploadQuestionType,
  json,
  nowIso,
  readJson,
  requireString,
  queryInChunks,
  requiredRow,
} from './utils';
import { answerToJson, choiceToJson, parseChoiceIds, projectToJson, questionToJson, replyToJson, responseToJson, surveyToJson } from './serializers';
import {
  DEFAULT_FORM_CONTENT_LOCALE,
  localizedTextFor,
} from './localization';
import { collectFileKeysFromResponse, deleteMediaKeys, parseStoredFileKeys } from './media';

export async function listResponses(env: Env, surveyId: number, url: URL): Promise<Response> {
  const limit = integerParam(url.searchParams.get('limit'), 'limit', 50, { min: 1, max: 100 });
  const offset = integerParam(url.searchParams.get('offset'), 'offset', 0, { min: 0 });
  const rows = await env.DB.prepare(
    `SELECT r.id, r.survey_id, r.anonymous_account_id, r.anonymous_id,
       r.submitted_at, r.user_agent, r.device_id, r.device_label,
       r.device_platform, r.device_os, r.device_os_version, r.device_browser,
       r.device_browser_version, r.device_locale, r.device_timezone,
       r.screen_width, r.screen_height, r.device_pixel_ratio, r.device_info,
       r.metadata, r.follow_up,
       (SELECT COUNT(*) FROM admin_replies ar
        WHERE ar.survey_response_id = r.id) AS reply_count
     FROM survey_responses r
     WHERE r.survey_id = ?
     ORDER BY r.submitted_at DESC
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

export async function responseAnswers(env: Env, responseId: number, url: URL): Promise<Response> {
  const limit = integerParam(url.searchParams.get('limit'), 'limit', 500, { min: 1, max: 2000 });
  const offset = integerParam(url.searchParams.get('offset'), 'offset', 0, { min: 0 });
  const rows = await env.DB.prepare(
    `SELECT * FROM answers WHERE survey_response_id = ?
     ORDER BY id LIMIT ? OFFSET ?`,
  ).bind(responseId, limit, offset).all<AnswerRow>();
  return json(rows.results.map(answerToJson));
}

type AnswerWithResponseMeta = AnswerRow & {
  submitted_at: string;
  anonymous_id: string | null;
  device_locale: string | null;
  metadata: string | null;
};

export async function aggregatedResults(env: Env, surveyId: number): Promise<Response> {
  const totalResponses = await countRows(
    env.DB,
    `SELECT COUNT(*) AS count FROM survey_responses WHERE survey_id = ?`,
    surveyId,
  );
  const questions = await env.DB.prepare(
    `SELECT * FROM questions WHERE survey_id = ? ORDER BY order_index`,
  ).bind(surveyId).all<QuestionRow>();
  const questionIds = questions.results.map((question) => question.id);
  const [allAnswers, allChoices] = await Promise.all([
    loadAnswersForQuestions(env.DB, questionIds),
    loadChoicesForQuestions(env.DB, questionIds),
  ]);
  const answersByQuestion = groupBy(allAnswers, (answer) => answer.question_id);
  const choicesByQuestion = groupBy(allChoices, (choice) => choice.question_id);

  const questionResults = questions.results.map((question) => {
    const answers = answersByQuestion.get(question.id) ?? [];
    const individualAnswers = answers.map((answer) => {
      const fileKeys = isImageUploadQuestionType(question.type)
        ? (parseStoredFileKeys(answer.text_value) ?? [])
        : null;
      return {
        responseId: answer.survey_response_id,
        submittedAt: answer.submitted_at,
        anonymousId: answer.anonymous_id,
        responseLocale: responseLocaleFrom(
          answer.metadata,
          answer.device_locale,
        ),
        textValue: fileKeys ? null : answer.text_value,
        selectedChoiceIds: parseChoiceIds(answer.selected_choice_ids),
        fileKeys,
      };
    });
    if (isChoiceQuestionType(question.type)) {
      const choices = choicesByQuestion.get(question.id) ?? [];
      const counts: Record<string, number> = {};
      for (const choice of choices) counts[String(choice.id)] = 0;
      for (const answer of answers) {
        for (const choiceId of parseChoiceIds(answer.selected_choice_ids)) {
          incrementChoiceCount(counts, choiceId);
        }
      }
      return {
        questionId: question.id,
        questionText: localizedTextFor(question.text_translations, DEFAULT_FORM_CONTENT_LOCALE),
        questionType: question.type,
        choiceCounts: counts,
        textResponses: null,
        imageResponseCount: null,
        individualAnswers,
      };
    }
    if (isImageUploadQuestionType(question.type)) {
      const withImages = individualAnswers.filter(
        (answer) => (answer.fileKeys?.length ?? 0) > 0,
      );
      return {
        questionId: question.id,
        questionText: localizedTextFor(question.text_translations, DEFAULT_FORM_CONTENT_LOCALE),
        questionType: question.type,
        choiceCounts: null,
        textResponses: null,
        imageResponseCount: withImages.length,
        individualAnswers,
      };
    }
    return {
      questionId: question.id,
      questionText: localizedTextFor(question.text_translations, DEFAULT_FORM_CONTENT_LOCALE),
      questionType: question.type,
      choiceCounts: null,
      textResponses: answers
        .map((answer) => answer.text_value)
        .filter((value): value is string => Boolean(value)),
      imageResponseCount: null,
      individualAnswers,
    };
  });
  return json({ surveyId, totalResponses, questionResults });
}

async function loadAnswersForQuestions(
  db: D1Database,
  questionIds: number[],
): Promise<AnswerWithResponseMeta[]> {
  if (questionIds.length === 0) return [];
  return queryInChunks<AnswerWithResponseMeta>(
    db,
    (ph) => `SELECT a.*, r.submitted_at, r.anonymous_id,
       r.device_locale, r.metadata
     FROM answers a
     JOIN survey_responses r ON r.id = a.survey_response_id
     WHERE a.question_id IN (${ph})
     ORDER BY r.submitted_at DESC, a.id`,
    questionIds,
  );
}

export function responseLocaleFrom(
  metadataJson: string | null,
  deviceLocale: string | null,
): string | null {
  let metadataLocale: unknown;
  if (metadataJson) {
    try {
      const metadata: unknown = JSON.parse(metadataJson);
      if (metadata && typeof metadata === 'object' && !Array.isArray(metadata)) {
        metadataLocale = (metadata as Record<string, unknown>).locale;
      }
    } catch {
      // Response serialization reports malformed metadata separately. Locale
      // detection should still fall back to device info instead of hiding data.
    }
  }

  for (const candidate of [metadataLocale, deviceLocale]) {
    if (typeof candidate !== 'string' || candidate.trim().length === 0) {
      continue;
    }
    const value = candidate.trim();
    if (/^[A-Za-z]{2,3}(?:[-_][A-Za-z0-9]{2,8})*$/.test(value)) {
      return value;
    }
  }
  return null;
}

async function loadChoicesForQuestions(db: D1Database, questionIds: number[]): Promise<ChoiceRow[]> {
  if (questionIds.length === 0) return [];
  return queryInChunks<ChoiceRow>(
    db,
    (ph) => `SELECT * FROM choices WHERE question_id IN (${ph}) ORDER BY order_index`,
    questionIds,
  );
}

export async function responseTrends(env: Env, surveyId: number, url: URL): Promise<Response> {
  const days = integerParam(url.searchParams.get('days'), 'days', 30, { min: 1, max: 365 });
  // UTC midnight buckets so "today" is always present and days are full calendar days.
  // Previous logic used now-days (partial first day) and only initialized `days`
  // keys from that offset, which dropped today's key when it had zero responses.
  const todayUtc = utcMidnight(new Date());
  const start = new Date(todayUtc.getTime() - (days - 1) * 24 * 60 * 60 * 1000);
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
    if (Object.hasOwn(result, date)) {
      result[date] += 1;
    }
  }
  return json(result);
}

/** Floor a Date to UTC midnight (00:00:00.000Z). */
export function utcMidnight(date: Date): Date {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
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

  // UTF-8 BOM so Excel opens Japanese (and other non-ASCII) correctly.
  return new Response(`\uFEFF${toExportCsv(data)}`, {
    headers: exportHeaders('text/csv; charset=utf-8', filename),
  });
}

export async function deleteResponse(env: Env, responseId: number): Promise<Response> {
  const response = await env.DB.prepare(
    `SELECT follow_up FROM survey_responses WHERE id = ?`,
  ).bind(responseId).first<{ follow_up: string | null }>();

  const answers = response
    ? (await env.DB.prepare(
        `SELECT text_value FROM answers WHERE survey_response_id = ?`,
      ).bind(responseId).all<{ text_value: string | null }>()).results
    : [];

  const fileKeys = response
    ? collectFileKeysFromResponse(answers, response.follow_up)
    : [];

  await env.DB.prepare(`DELETE FROM survey_responses WHERE id = ?`).bind(responseId).run();
  await deleteMediaKeys(env.MEDIA_BUCKET, fileKeys);
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
       r.screen_width, r.screen_height, r.device_pixel_ratio, r.device_info, r.metadata, r.follow_up
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
  if (isChoiceQuestionType(question.type)) {
    return parseChoiceIds(answer.selected_choice_ids)
      .map((choiceId) => choiceTextForCsv(choiceTextById, choiceId))
      .join('; ');
  }
  if (question.type === 'imageUpload') {
    const fileKeys = parseStoredFileKeys(answer.text_value) ?? [];
    return fileKeys.join('; ');
  }
  return answer.text_value ?? '';
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
