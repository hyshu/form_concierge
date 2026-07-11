import type { AnonymousContext, AnswerRow, ChoiceRow, Env, QuestionRow, ReplyRow, ResponseRow, SurveyRow } from './types';
import { generateFollowUpFromAnswers } from './ai_generation';
import { isAiGenerationConfigured } from './admin_settings';
import {
  HttpError,
  MEDIA_MAX_FILES,
  isChoiceQuestionType,
  isImageUploadQuestionType,
  isTextQuestionType,
  json,
  nowIso,
  readJson,
  requireString,
} from './utils';
import { followUpToJson, parseChoiceIds, responseToJson } from './serializers';
import { DEFAULT_FORM_CONTENT_LOCALE, localizedTextFor } from './localization';
import {
  assertMediaObjectsExist,
  assertOwnedMediaKeys,
  parseStoredFileKeys,
} from './media';

const MAX_FOLLOW_UP_JSON_BYTES = 64 * 1024;
const FOLLOW_UP_STATUSES = new Set(['skipped', 'pending', 'completed']);
/** How far back to load sibling responses for AI context. */
const RECENT_HISTORY_DAYS = 30;
/** Cap recent responses included in the follow-up prompt. */
const MAX_RECENT_RESPONSES = 20;
/** Truncate long free-text answers in history. */
const MAX_HISTORY_ANSWER_CHARS = 200;

export type FollowUpStatus = 'skipped' | 'pending' | 'completed';

export type FollowUpChoice = {
  id: string;
  label: string;
};

export type FollowUpAnswer = {
  textValue: string | null;
  selectedChoiceIds: string[];
  fileKeys: string[];
};

export type FollowUpItem = {
  id: string;
  type: string;
  text: string;
  required: boolean;
  placeholder: string | null;
  maxFiles: number | null;
  choices: FollowUpChoice[];
  answer: FollowUpAnswer | null;
};

export type FollowUpPayload = {
  version: 1;
  status: FollowUpStatus;
  generatedAt: string;
  completedAt: string | null;
  locale: string;
  items: FollowUpItem[];
};

/**
 * Decide whether adaptive follow-up is needed and optionally persist pending items.
 * If not needed / AI unavailable / errors: mark skipped and complete without blocking.
 */
export async function generateFollowUp(
  request: Request,
  env: Env,
  responseId: number,
  anonymous: AnonymousContext,
): Promise<Response> {
  const response = await loadOwnedResponse(env, responseId, anonymous.id);
  const existing = parseStoredFollowUp(response.follow_up);
  if (existing) {
    return json({
      needed: existing.status === 'pending' || existing.status === 'completed'
        ? existing.items.length > 0
        : false,
      followUp: existing,
    });
  }

  const survey = await env.DB.prepare(`SELECT * FROM surveys WHERE id = ?`)
    .bind(response.survey_id)
    .first<SurveyRow>();
  if (!survey) throw new HttpError(404, 'Survey not found');

  if (survey.follow_up_enabled !== 1) {
    const skipped = skippedFollowUp(DEFAULT_FORM_CONTENT_LOCALE);
    await claimFollowUp(env, responseId, skipped);
    return json({ needed: false, followUp: skipped });
  }

  if (!(await isAiGenerationConfigured(env))) {
    const skipped = skippedFollowUp(DEFAULT_FORM_CONTENT_LOCALE);
    await claimFollowUp(env, responseId, skipped);
    return json({ needed: false, followUp: skipped });
  }

  const body = await readJson(request, true);
  const locale = optionalLocale(body.locale) ?? DEFAULT_FORM_CONTENT_LOCALE;

  try {
    const [answersSummary, recentResponsesSummary] = await Promise.all([
      buildAnswersSummary(env, survey, responseId, locale),
      buildRecentResponsesSummary(env, survey, responseId, anonymous.id, locale),
    ]);
    const generated = await generateFollowUpFromAnswers(env, {
      surveyTitle: localizedTextFor(survey.title_translations, locale),
      locale,
      answersSummary,
      deviceContext: formatDeviceContext(response),
      recentResponsesSummary,
    });

    if (!generated.needed || generated.items.length === 0) {
      const skipped = skippedFollowUp(locale);
      await claimFollowUp(env, responseId, skipped);
      return json({ needed: false, followUp: skipped });
    }

    const pending: FollowUpPayload = {
      version: 1,
      status: 'pending',
      generatedAt: nowIso(),
      completedAt: null,
      locale,
      items: generated.items.map((item) => ({
        id: item.id,
        type: item.type,
        text: item.text,
        required: false,
        placeholder: item.placeholder,
        maxFiles: item.maxFiles ?? null,
        choices: item.choices,
        answer: null,
      })),
    };
    const claimed = await claimFollowUp(env, responseId, pending);
    if (!claimed) {
      const current = await loadOwnedResponse(env, responseId, anonymous.id);
      return json({ needed: false, followUp: parseStoredFollowUp(current.follow_up) });
    }
    return json({ needed: true, followUp: pending });
  } catch (error) {
    const skipped = skippedFollowUp(locale);
    await claimFollowUp(env, responseId, skipped);
    return json({
      needed: false,
      followUp: skipped,
      error: error instanceof HttpError ? error.message : 'Follow-up generation failed',
    });
  }
}

/** Save answers for a pending follow-up interview. */
export async function saveFollowUp(
  request: Request,
  env: Env,
  responseId: number,
  anonymous: AnonymousContext,
): Promise<Response> {
  const response = await loadOwnedResponse(env, responseId, anonymous.id);
  const existing = parseStoredFollowUp(response.follow_up);
  if (!existing) throw new HttpError(400, 'Follow-up has not been generated');
  if (existing.status === 'skipped') {
    return json(responseToJson(response));
  }
  if (existing.status === 'completed') {
    return json(responseToJson(response));
  }
  if (existing.status !== 'pending') {
    throw new HttpError(400, 'Follow-up is not awaiting answers');
  }

  const body = await readJson(request);
  const answersById = parseAnswerMap(body.answers);
  const allFileKeys: string[] = [];
  const items = existing.items.map((item) => {
    const answer = answersById.get(item.id) ?? null;
    validateFollowUpAnswer(item, answer);
    const normalized = answer ?? {
      textValue: null,
      selectedChoiceIds: [],
      fileKeys: [],
    };
    if (normalized.fileKeys.length > 0) {
      assertOwnedMediaKeys(normalized.fileKeys, anonymous.id);
      allFileKeys.push(...normalized.fileKeys);
    }
    return {
      ...item,
      answer: normalized,
    };
  });
  if (allFileKeys.length > 0) {
    await assertMediaObjectsExist(env, allFileKeys);
  }

  const completed: FollowUpPayload = {
    ...existing,
    status: 'completed',
    completedAt: nowIso(),
    items,
  };
  const updated = await updateFollowUp(env, responseId, completed);
  return json(responseToJson(updated));
}

async function loadOwnedResponse(
  env: Env,
  responseId: number,
  anonymousAccountId: string,
): Promise<ResponseRow> {
  const row = await env.DB.prepare(`SELECT * FROM survey_responses WHERE id = ?`)
    .bind(responseId)
    .first<ResponseRow>();
  if (!row) throw new HttpError(404, 'Response not found');
  if (row.anonymous_account_id !== anonymousAccountId) {
    throw new HttpError(403, 'Forbidden');
  }
  return row;
}

async function claimFollowUp(
  env: Env,
  responseId: number,
  followUp: FollowUpPayload,
): Promise<ResponseRow | null> {
  const encoded = JSON.stringify(followUp);
  if (encoded.length > MAX_FOLLOW_UP_JSON_BYTES) {
    throw new HttpError(400, 'followUp payload is too large');
  }
  return env.DB.prepare(
    `UPDATE survey_responses SET follow_up = ? WHERE id = ? AND follow_up IS NULL RETURNING *`,
  ).bind(encoded, responseId).first<ResponseRow>();
}

async function updateFollowUp(
  env: Env,
  responseId: number,
  followUp: FollowUpPayload,
): Promise<ResponseRow> {
  const encoded = JSON.stringify(followUp);
  if (encoded.length > MAX_FOLLOW_UP_JSON_BYTES) {
    throw new HttpError(400, 'followUp payload is too large');
  }
  const row = await env.DB.prepare(
    `UPDATE survey_responses SET follow_up = ? WHERE id = ? RETURNING *`,
  ).bind(encoded, responseId).first<ResponseRow>();
  if (!row) throw new HttpError(500, 'Failed to save follow-up');
  return row;
}

function skippedFollowUp(locale: string): FollowUpPayload {
  return {
    version: 1,
    status: 'skipped',
    generatedAt: nowIso(),
    completedAt: nowIso(),
    locale,
    items: [],
  };
}

function parseStoredFollowUp(value: string | null): FollowUpPayload | null {
  const jsonValue = followUpToJson(value);
  if (!jsonValue) return null;
  return normalizeFollowUpPayload(jsonValue);
}

function normalizeFollowUpPayload(value: Record<string, unknown>): FollowUpPayload {
  if (value.version !== 1) throw new HttpError(500, 'Unsupported followUp version');
  if (typeof value.status !== 'string' || !FOLLOW_UP_STATUSES.has(value.status)) {
    throw new HttpError(500, 'Invalid followUp status');
  }
  if (typeof value.generatedAt !== 'string') throw new HttpError(500, 'Invalid followUp generatedAt');
  if (value.completedAt != null && typeof value.completedAt !== 'string') {
    throw new HttpError(500, 'Invalid followUp completedAt');
  }
  if (typeof value.locale !== 'string') throw new HttpError(500, 'Invalid followUp locale');
  if (!Array.isArray(value.items)) throw new HttpError(500, 'Invalid followUp items');

  return {
    version: 1,
    status: value.status as FollowUpStatus,
    generatedAt: value.generatedAt,
    completedAt: value.completedAt ?? null,
    locale: value.locale,
    items: value.items.map((item, index) => normalizeStoredItem(item, index)),
  };
}

function normalizeStoredItem(value: unknown, index: number): FollowUpItem {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpError(500, `Invalid followUp item at ${index}`);
  }
  const item = value as Record<string, unknown>;
  if (typeof item.id !== 'string' || typeof item.type !== 'string' || typeof item.text !== 'string') {
    throw new HttpError(500, `Invalid followUp item at ${index}`);
  }
  if (typeof item.required !== 'boolean') throw new HttpError(500, `Invalid followUp required at ${index}`);
  const placeholder =
    item.placeholder == null
      ? null
      : typeof item.placeholder === 'string'
        ? item.placeholder
        : null;
  if (!Array.isArray(item.choices)) throw new HttpError(500, `Invalid followUp choices at ${index}`);
  const choices = item.choices.map((choice, choiceIndex) => {
    if (!choice || typeof choice !== 'object' || Array.isArray(choice)) {
      throw new HttpError(500, `Invalid followUp choice at ${index}.${choiceIndex}`);
    }
    const row = choice as Record<string, unknown>;
    if (typeof row.id !== 'string' || typeof row.label !== 'string') {
      throw new HttpError(500, `Invalid followUp choice at ${index}.${choiceIndex}`);
    }
    return { id: row.id, label: row.label };
  });
  const maxFiles =
    item.maxFiles == null
      ? null
      : typeof item.maxFiles === 'number' && Number.isSafeInteger(item.maxFiles)
        ? item.maxFiles
        : null;
  return {
    id: item.id,
    type: item.type,
    text: item.text,
    // Historical payloads may have required=true; treat all follow-up as optional.
    required: false,
    placeholder,
    maxFiles,
    choices,
    answer: normalizeStoredAnswer(item.answer),
  };
}

function normalizeStoredAnswer(value: unknown): FollowUpAnswer | null {
  if (value == null) return null;
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpError(500, 'Invalid followUp answer');
  }
  const answer = value as Record<string, unknown>;
  const textValue =
    answer.textValue == null
      ? null
      : typeof answer.textValue === 'string'
        ? answer.textValue
        : null;
  const selectedChoiceIds = Array.isArray(answer.selectedChoiceIds)
    ? answer.selectedChoiceIds.filter((id): id is string => typeof id === 'string')
    : [];
  const fileKeys = Array.isArray(answer.fileKeys)
    ? answer.fileKeys.filter((id): id is string => typeof id === 'string')
    : [];
  return { textValue, selectedChoiceIds, fileKeys };
}

function parseAnswerMap(value: unknown): Map<string, FollowUpAnswer> {
  if (!Array.isArray(value)) throw new HttpError(400, 'answers must be an array');
  const map = new Map<string, FollowUpAnswer>();
  for (const [index, raw] of value.entries()) {
    if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
      throw new HttpError(400, `answers[${index}] must be an object`);
    }
    const row = raw as Record<string, unknown>;
    const id = requireString(row.id, `answers[${index}].id`);
    if (map.has(id)) throw new HttpError(400, `Duplicate answer for ${id}`);
    const textValue =
      row.textValue == null
        ? null
        : typeof row.textValue === 'string'
          ? row.textValue.trim()
          : (() => {
              throw new HttpError(400, `answers[${index}].textValue must be a string`);
            })();
    const selectedChoiceIds = Array.isArray(row.selectedChoiceIds)
      ? row.selectedChoiceIds.map((choiceId, choiceIndex) => {
          if (typeof choiceId !== 'string' || choiceId.trim().length === 0) {
            throw new HttpError(
              400,
              `answers[${index}].selectedChoiceIds[${choiceIndex}] must be a non-empty string`,
            );
          }
          return choiceId.trim();
        })
      : [];
    const fileKeys = Array.isArray(row.fileKeys)
      ? row.fileKeys.map((fileKey, fileIndex) => {
          if (typeof fileKey !== 'string' || fileKey.trim().length === 0) {
            throw new HttpError(
              400,
              `answers[${index}].fileKeys[${fileIndex}] must be a non-empty string`,
            );
          }
          return fileKey.trim();
        })
      : [];
    if (fileKeys.length > MEDIA_MAX_FILES) {
      throw new HttpError(400, `answers[${index}].fileKeys allows at most ${MEDIA_MAX_FILES} items`);
    }
    map.set(id, {
      textValue: textValue && textValue.length > 0 ? textValue : null,
      selectedChoiceIds,
      fileKeys,
    });
  }
  return map;
}

function validateFollowUpAnswer(item: FollowUpItem, answer: FollowUpAnswer | null): void {
  // All follow-up items are optional; empty answers are always allowed.
  if (isTextQuestionType(item.type)) {
    return;
  }
  if (isChoiceQuestionType(item.type)) {
    const selected = answer?.selectedChoiceIds ?? [];
    if (item.type === 'singleChoice' && selected.length > 1) {
      throw new HttpError(400, `Follow-up "${item.text}" allows one choice`);
    }
    const valid = new Set(item.choices.map((choice) => choice.id));
    for (const choiceId of selected) {
      if (!valid.has(choiceId)) {
        throw new HttpError(400, `Follow-up "${item.text}" has an invalid choice`);
      }
    }
    return;
  }
  if (isImageUploadQuestionType(item.type)) {
    const fileKeys = answer?.fileKeys ?? [];
    const maxFiles = item.maxFiles ?? 1;
    if (fileKeys.length > maxFiles) {
      throw new HttpError(400, `Follow-up "${item.text}" allows at most ${maxFiles} images`);
    }
    return;
  }
  throw new HttpError(400, `Unsupported follow-up type: ${item.type}`);
}

async function buildAnswersSummary(
  env: Env,
  survey: SurveyRow,
  responseId: number,
  locale: string,
): Promise<string> {
  const questions = await env.DB.prepare(
    `SELECT * FROM questions WHERE survey_id = ? AND is_deleted = 0 ORDER BY order_index`,
  ).bind(survey.id).all<QuestionRow>();
  const answers = await env.DB.prepare(
    `SELECT * FROM answers WHERE survey_response_id = ?`,
  ).bind(responseId).all<AnswerRow>();
  const answerByQuestion = new Map(answers.results.map((answer) => [answer.question_id, answer]));
  const questionIds = questions.results.map((question) => question.id);
  const choicesByQuestion = await loadChoicesByQuestion(env, questionIds);
  return formatQaLines(questions.results, answerByQuestion, choicesByQuestion, locale);
}

async function buildRecentResponsesSummary(
  env: Env,
  survey: SurveyRow,
  currentResponseId: number,
  anonymousAccountId: string,
  locale: string,
): Promise<string> {
  const cutoff = new Date(Date.now() - RECENT_HISTORY_DAYS * 24 * 60 * 60 * 1000).toISOString();
  const recent = await env.DB.prepare(
    `SELECT id, submitted_at, follow_up
     FROM survey_responses
     WHERE survey_id = ?
       AND id != ?
       AND anonymous_account_id = ?
       AND submitted_at >= ?
     ORDER BY submitted_at DESC
     LIMIT ?`,
  ).bind(survey.id, currentResponseId, anonymousAccountId, cutoff, MAX_RECENT_RESPONSES).all<{
    id: number;
    submitted_at: string;
    follow_up: string | null;
  }>();

  if (recent.results.length === 0) {
    return '(no prior responses from this respondent in the last 30 days)';
  }

  const questions = await env.DB.prepare(
    `SELECT * FROM questions WHERE survey_id = ? AND is_deleted = 0 ORDER BY order_index`,
  ).bind(survey.id).all<QuestionRow>();
  const questionIds = questions.results.map((question) => question.id);
  const choicesByQuestion = await loadChoicesByQuestion(env, questionIds);

  const responseIds = recent.results.map((row) => row.id);
  const placeholders = responseIds.map(() => '?').join(', ');
  const [allAnswers, allReplies] = await Promise.all([
    env.DB.prepare(
      `SELECT * FROM answers WHERE survey_response_id IN (${placeholders})`,
    ).bind(...responseIds).all<AnswerRow>(),
    env.DB.prepare(
      `SELECT * FROM admin_replies WHERE survey_response_id IN (${placeholders}) ORDER BY created_at ASC`,
    ).bind(...responseIds).all<ReplyRow>(),
  ]);
  const answersByResponse = new Map<number, Map<number, AnswerRow>>();
  for (const answer of allAnswers.results) {
    const byQuestion = answersByResponse.get(answer.survey_response_id) ?? new Map();
    byQuestion.set(answer.question_id, answer);
    answersByResponse.set(answer.survey_response_id, byQuestion);
  }
  const repliesByResponse = new Map<number, ReplyRow[]>();
  for (const reply of allReplies.results) {
    const list = repliesByResponse.get(reply.survey_response_id) ?? [];
    list.push(reply);
    repliesByResponse.set(reply.survey_response_id, list);
  }

  const blocks: string[] = [];
  for (const row of recent.results) {
    const answerByQuestion = answersByResponse.get(row.id) ?? new Map();
    const qa = formatQaLines(
      questions.results,
      answerByQuestion,
      choicesByQuestion,
      locale,
      { truncateText: true },
    );
    const followUpNote = formatCompletedFollowUpSummary(row.follow_up);
    const replies = repliesByResponse.get(row.id) ?? [];
    const replyLines = replies.map((r) =>
      `- [${r.created_at}] ${truncateText(r.body.trim(), MAX_HISTORY_ANSWER_CHARS)}`,
    );
    blocks.push(
      [
        `### Response ${row.id} at ${row.submitted_at}`,
        qa,
        followUpNote ? `Follow-up answers:\n${followUpNote}` : null,
        replyLines.length > 0 ? `Admin replies:\n${replyLines.join('\n')}` : null,
      ].filter(Boolean).join('\n'),
    );
  }
  return blocks.join('\n\n');
}

function formatQaLines(
  questions: QuestionRow[],
  answerByQuestion: Map<number, AnswerRow>,
  choicesByQuestion: Map<number, ChoiceRow[]>,
  locale: string,
  options: { truncateText?: boolean } = {},
): string {
  const lines: string[] = [];

  for (const question of questions) {
    const answer = answerByQuestion.get(question.id);
    const questionText = localizedTextFor(question.text_translations, locale);
    if (!answer) {
      lines.push(`- ${questionText}: (no answer)`);
      continue;
    }
    if (isTextQuestionType(question.type)) {
      const raw = answer.text_value ?? '(empty)';
      const text = options.truncateText ? truncateText(raw, MAX_HISTORY_ANSWER_CHARS) : raw;
      lines.push(`- ${questionText}: ${text}`);
      continue;
    }
    if (isImageUploadQuestionType(question.type)) {
      const fileKeys = parseStoredFileKeys(answer.text_value) ?? [];
      lines.push(
        `- ${questionText}: ${
          fileKeys.length > 0 ? `${fileKeys.length} image(s) attached` : '(no images)'
        }`,
      );
      continue;
    }
    const choiceIds = parseChoiceIds(answer.selected_choice_ids);
    if (choiceIds.length === 0) {
      lines.push(`- ${questionText}: (no selection)`);
      continue;
    }
    const choices = choicesByQuestion.get(question.id) ?? [];
    const labels = choices
      .filter((choice) => choiceIds.includes(choice.id))
      .map((choice) => localizedTextFor(choice.text_translations, locale));
    lines.push(`- ${questionText}: ${labels.join(', ') || choiceIds.join(', ')}`);
  }

  return lines.length > 0 ? lines.join('\n') : '(no answers)';
}

/** Compact device/app fields already stored on the response for the model. */
function formatDeviceContext(response: ResponseRow): string {
  const fromJson = parseDeviceInfoJson(response.device_info);
  const pairs: Array<[string, string | null | undefined]> = [
    ['deviceLabel', response.device_label ?? fromJson.label],
    ['platform', response.device_platform ?? fromJson.platform],
    ['os', response.device_os ?? fromJson.os],
    ['osVersion', response.device_os_version ?? fromJson.osVersion],
    ['browser', response.device_browser ?? fromJson.browser],
    ['browserVersion', response.device_browser_version ?? fromJson.browserVersion],
    ['appVersion', fromJson.appVersion],
    ['appBuild', fromJson.appBuild],
    ['model', fromJson.model],
    ['manufacturer', fromJson.manufacturer],
    ['deviceLocale', response.device_locale ?? fromJson.locale],
    ['timezone', response.device_timezone ?? fromJson.timezone],
    [
      'screen',
      response.screen_width != null && response.screen_height != null
        ? `${response.screen_width}x${response.screen_height}`
        : null,
    ],
    ['userAgent', response.user_agent],
  ];
  const lines = pairs
    .filter(([, value]) => typeof value === 'string' && value.trim().length > 0)
    .map(([key, value]) => `- ${key}: ${(value as string).trim()}`);
  return lines.length > 0
    ? lines.join('\n')
    : '(no device metadata recorded for this submission)';
}

function parseDeviceInfoJson(value: string | null): Record<string, string | null> {
  if (!value) return {};
  try {
    const decoded = JSON.parse(value) as unknown;
    if (!decoded || typeof decoded !== 'object' || Array.isArray(decoded)) return {};
    const raw = decoded as Record<string, unknown>;
    const out: Record<string, string | null> = {};
    for (const key of [
      'label',
      'platform',
      'os',
      'osVersion',
      'browser',
      'browserVersion',
      'appVersion',
      'appBuild',
      'model',
      'manufacturer',
      'locale',
      'timezone',
    ]) {
      const item = raw[key];
      out[key] = typeof item === 'string' && item.trim().length > 0 ? item.trim() : null;
    }
    return out;
  } catch {
    return {};
  }
}

function formatCompletedFollowUpSummary(followUpJson: string | null): string | null {
  if (!followUpJson) return null;
  try {
    const decoded = JSON.parse(followUpJson) as {
      status?: string;
      items?: Array<{
        text?: string;
        answer?: { textValue?: string | null; selectedChoiceIds?: string[]; fileKeys?: string[] };
        choices?: Array<{ id: string; label: string }>;
      }>;
    };
    if (decoded.status !== 'completed' || !Array.isArray(decoded.items) || decoded.items.length === 0) {
      return null;
    }
    const lines: string[] = [];
    for (const item of decoded.items) {
      if (typeof item.text !== 'string') continue;
      const answer = item.answer;
      if (!answer) {
        lines.push(`- ${item.text}: (no answer)`);
        continue;
      }
      if (answer.textValue && answer.textValue.trim()) {
        lines.push(`- ${item.text}: ${truncateText(answer.textValue.trim(), MAX_HISTORY_ANSWER_CHARS)}`);
        continue;
      }
      if (Array.isArray(answer.fileKeys) && answer.fileKeys.length > 0) {
        lines.push(`- ${item.text}: ${answer.fileKeys.length} image(s)`);
        continue;
      }
      if (Array.isArray(answer.selectedChoiceIds) && answer.selectedChoiceIds.length > 0) {
        const labelsById = new Map((item.choices ?? []).map((choice) => [choice.id, choice.label]));
        const labels = answer.selectedChoiceIds.map((id) => labelsById.get(id) ?? id);
        lines.push(`- ${item.text}: ${labels.join(', ')}`);
        continue;
      }
      lines.push(`- ${item.text}: (no answer)`);
    }
    return lines.length > 0 ? lines.join('\n') : null;
  } catch {
    return null;
  }
}

function truncateText(value: string, maxChars: number): string {
  if (value.length <= maxChars) return value;
  return `${value.slice(0, maxChars - 1)}…`;
}

async function loadChoicesByQuestion(
  env: Env,
  questionIds: number[],
): Promise<Map<number, ChoiceRow[]>> {
  const map = new Map<number, ChoiceRow[]>();
  if (questionIds.length === 0) return map;
  const placeholders = questionIds.map(() => '?').join(', ');
  const rows = await env.DB.prepare(
    `SELECT * FROM choices WHERE question_id IN (${placeholders}) ORDER BY order_index`,
  ).bind(...questionIds).all<ChoiceRow>();
  for (const choice of rows.results) {
    const list = map.get(choice.question_id) ?? [];
    list.push(choice);
    map.set(choice.question_id, list);
  }
  return map;
}

function optionalLocale(value: unknown): string | null {
  if (value == null || value === '') return null;
  if (typeof value !== 'string') throw new HttpError(400, 'locale must be a string');
  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed;
}
