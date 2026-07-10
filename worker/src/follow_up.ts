import type { AnonymousContext, AnswerRow, ChoiceRow, Env, QuestionRow, ResponseRow, SurveyRow } from './types';
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
    await writeFollowUp(env, responseId, skipped);
    return json({ needed: false, followUp: skipped });
  }

  if (!(await isAiGenerationConfigured(env))) {
    const skipped = skippedFollowUp(DEFAULT_FORM_CONTENT_LOCALE);
    await writeFollowUp(env, responseId, skipped);
    return json({ needed: false, followUp: skipped });
  }

  const body = await readJson(request, true);
  const locale = optionalLocale(body.locale) ?? DEFAULT_FORM_CONTENT_LOCALE;

  try {
    const context = await buildAnswersSummary(env, survey, responseId, locale);
    const generated = await generateFollowUpFromAnswers(env, {
      surveyTitle: localizedTextFor(survey.title_translations, locale),
      locale,
      answersSummary: context,
    });

    if (!generated.needed || generated.items.length === 0) {
      const skipped = skippedFollowUp(locale);
      await writeFollowUp(env, responseId, skipped);
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
        required: item.required,
        placeholder: item.placeholder,
        maxFiles: item.maxFiles ?? null,
        choices: item.choices,
        answer: null,
      })),
    };
    await writeFollowUp(env, responseId, pending);
    return json({ needed: true, followUp: pending });
  } catch (error) {
    // Never block main-form completion on follow-up failures.
    const skipped = skippedFollowUp(locale);
    await writeFollowUp(env, responseId, skipped);
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
  const updated = await writeFollowUp(env, responseId, completed);
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

async function writeFollowUp(
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
    required: item.required,
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
  if (isTextQuestionType(item.type)) {
    const value = answer?.textValue?.trim() ?? '';
    if (item.required && value.length === 0) {
      throw new HttpError(400, `Follow-up "${item.text}" is required`);
    }
    return;
  }
  if (isChoiceQuestionType(item.type)) {
    const selected = answer?.selectedChoiceIds ?? [];
    if (item.required && selected.length === 0) {
      throw new HttpError(400, `Follow-up "${item.text}" requires a choice`);
    }
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
    if (item.required && fileKeys.length === 0) {
      throw new HttpError(400, `Follow-up "${item.text}" requires an image`);
    }
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
  const lines: string[] = [];

  for (const question of questions.results) {
    const answer = answerByQuestion.get(question.id);
    const questionText = localizedTextFor(question.text_translations, locale);
    if (!answer) {
      lines.push(`- ${questionText}: (no answer)`);
      continue;
    }
    if (isTextQuestionType(question.type)) {
      lines.push(`- ${questionText}: ${answer.text_value ?? '(empty)'}`);
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
