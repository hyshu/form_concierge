import type { AnonymousContext, AnswerInput, AnswerRow, ChoiceRow, Env, ProjectRow, QuestionRow, ResponseRow, SurveyRow, VisibilityRuleRow } from './types';
import {
  HttpError,
  MEDIA_MAX_FILES,
  isChoiceQuestionType,
  isImageUploadQuestionType,
  isTextQuestionType,
  isUniqueConstraintError,
  json,
  logError,
  nowIso,
  optionalCustomDomain,
  optionalLimitedString,
  readJson,
  requireAnswerInput,
  queryInChunks,
  requiredInteger,
} from './utils';
import { normalizeDeviceInfo, normalizeMetadata } from './metadata';
import { choiceToJson, parseChoiceIds, projectToJson, questionToJson, responseToJson, surveyToJson } from './serializers';
import { getVisibilityRules, visibleQuestionIds } from './visibility_rules';
import { DEFAULT_FORM_CONTENT_LOCALE, localizedTextFor } from './localization';
import { sendResponseNotification } from './notification_settings';
import {
  assertMediaObjectsExist,
  assertOwnedMediaKeys,
  encodeFileKeysForStorage,
} from './media';
import { getTurnstileSecretKey } from './admin_settings';
import { verifyTurnstileToken } from './turnstile';

export async function getPublicProject(env: Env, slug: string): Promise<Response> {
  const project = await env.DB.prepare(
    `SELECT * FROM projects WHERE slug = ?`,
  ).bind(slug).first<ProjectRow>();
  if (!project) throw new HttpError(404, 'Project not found');
  return json(await publicProjectPayload(env, project));
}

export async function getPublicProjectByDomain(env: Env, domainValue: string | null): Promise<Response> {
  let customDomain: string | null = null;
  try {
    customDomain = optionalCustomDomain(domainValue);
  } catch (error) {
    if (error instanceof HttpError) throw new HttpError(404, 'Project not found');
    throw error;
  }
  if (!customDomain) throw new HttpError(404, 'Project not found');
  const project = await env.DB.prepare(
    `SELECT * FROM projects WHERE custom_domain = ?`,
  ).bind(customDomain).first<ProjectRow>();
  if (!project) throw new HttpError(404, 'Project not found');
  return json(await publicProjectPayload(env, project));
}

async function publicProjectPayload(env: Env, project: ProjectRow) {
  const rows = await env.DB.prepare(
    `SELECT * FROM surveys
     WHERE project_id = ? AND status = 'published' AND web_enabled = 1
     ORDER BY updated_at DESC`,
  ).bind(project.id).all<SurveyRow>();
  return {
    project: projectToJson(project),
    surveys: rows.results.filter(isAccepting).map(surveyToJson),
  };
}

export async function getPublicQuestions(env: Env, surveyId: number): Promise<Response> {
  const survey = await env.DB.prepare(
    `SELECT * FROM surveys WHERE id = ? AND status = 'published' AND web_enabled = 1`,
  ).bind(surveyId).first<SurveyRow>();
  if (!survey || !isAccepting(survey)) return json([]);
  const rows = await env.DB.prepare(
    `SELECT * FROM questions
     WHERE survey_id = ? AND is_deleted = 0
     ORDER BY order_index`,
  ).bind(surveyId).all<QuestionRow>();
  return json(rows.results.map(questionToJson));
}

export async function getPublicChoices(env: Env, questionId: number): Promise<Response> {
  const question = await env.DB.prepare(
    `SELECT q.* FROM questions q
     JOIN surveys s ON s.id = q.survey_id
     WHERE q.id = ? AND q.is_deleted = 0 AND s.status = 'published' AND s.web_enabled = 1`,
  ).bind(questionId).first<QuestionRow>();
  if (!question) return json([]);
  const rows = await env.DB.prepare(
    `SELECT * FROM choices WHERE question_id = ? ORDER BY order_index`,
  ).bind(questionId).all<ChoiceRow>();
  return json(rows.results.map(choiceToJson));
}

export async function submitResponse(
  request: Request,
  env: Env,
  surveyId: number,
  anonymous: AnonymousContext,
  ctx?: ExecutionContext,
): Promise<Response> {
  const survey = await env.DB.prepare(`SELECT * FROM surveys WHERE id = ?`)
    .bind(surveyId)
    .first<SurveyRow>();
  if (!survey || survey.status !== 'published' || survey.web_enabled !== 1 || !isAccepting(survey)) {
    throw new HttpError(400, 'Survey is not accepting responses');
  }

  const body = await readJson(request);

  if (survey.captcha_enabled === 1) {
    const turnstileSecret = await getTurnstileSecretKey(env);
    if (turnstileSecret) {
      const captchaToken = typeof body.captchaToken === 'string' ? body.captchaToken : '';
      if (!captchaToken) throw new HttpError(400, 'CAPTCHA token is required');
      await verifyTurnstileToken(
        captchaToken,
        turnstileSecret,
        request.headers.get('cf-connecting-ip'),
      );
    }
  }
  const answers = Array.isArray(body.answers)
    ? body.answers.map(requireAnswerInput)
    : [];
  const questions = await env.DB.prepare(
    `SELECT * FROM questions WHERE survey_id = ? AND is_deleted = 0 ORDER BY order_index`,
  ).bind(surveyId).all<QuestionRow>();
  const visibilityRules = await getVisibilityRules(env.DB, surveyId);
  await validateAnswers(env, questions.results, visibilityRules, answers, anonymous.id);

  const idempotencyKey = optionalLimitedString(body.idempotencyKey, 'idempotencyKey', 64);

  if (idempotencyKey) {
    const existing = await env.DB.prepare(
      `SELECT * FROM survey_responses WHERE idempotency_key = ?`,
    ).bind(idempotencyKey).first<ResponseRow>();
    if (existing) return json(responseToJson(existing), 200);
  }

  const now = nowIso();
  const userAgent = request.headers.get('user-agent');
  const deviceInfo = normalizeDeviceInfo(body.deviceInfo);
  const metadata = normalizeMetadata(body.metadata);
  const returningCols = `id, survey_id, anonymous_account_id, anonymous_id, submitted_at, user_agent,
         device_id, device_label, device_platform, device_os, device_os_version,
         device_browser, device_browser_version, device_locale, device_timezone,
         screen_width, screen_height, device_pixel_ratio, device_info, metadata, follow_up`;
  const statements: D1PreparedStatement[] = [
    env.DB.prepare(
      `INSERT INTO survey_responses
         (survey_id, anonymous_account_id, anonymous_id, submitted_at, ip_address, user_agent,
          device_id, device_label, device_platform, device_os, device_os_version,
          device_browser, device_browser_version, device_locale, device_timezone,
          screen_width, screen_height, device_pixel_ratio, device_info, metadata, follow_up, idempotency_key)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, ?)
       RETURNING ${returningCols}`,
    ).bind(
      surveyId,
      anonymous.id,
      optionalLimitedString(body.anonymousId, 'anonymousId', 128) ?? anonymous.id,
      now,
      request.headers.get('cf-connecting-ip'),
      userAgent,
      deviceInfo.deviceId,
      deviceInfo.label,
      deviceInfo.platform,
      deviceInfo.os,
      deviceInfo.osVersion,
      deviceInfo.browser,
      deviceInfo.browserVersion,
      deviceInfo.locale,
      deviceInfo.timezone,
      deviceInfo.screenWidth,
      deviceInfo.screenHeight,
      deviceInfo.devicePixelRatio,
      deviceInfo.rawJson,
      metadata,
      idempotencyKey,
    ),
  ];

  if (answers.length > 0) {
    const answerPayload = answers.map((answer) => {
      const fileKeys = Array.isArray(answer.fileKeys)
        ? (answer.fileKeys as string[])
        : null;
      return {
        questionId: requiredInteger(answer.questionId, 'questionId', { min: 1 }),
        textValue: fileKeys
          ? encodeFileKeysForStorage(fileKeys)
          : typeof answer.textValue === 'string'
            ? answer.textValue
            : null,
        selectedChoiceIds: Array.isArray(answer.selectedChoiceIds)
          ? JSON.stringify(
              answer.selectedChoiceIds.map((choiceId) =>
                requiredInteger(choiceId, 'selectedChoiceIds', { min: 1 }),
              ),
            )
          : null,
      };
    });
    statements.push(
      env.DB.prepare(
        `INSERT INTO answers
           (survey_response_id, question_id, text_value, selected_choice_ids)
         SELECT r.id,
                json_extract(j.value, '$.questionId'),
                json_extract(j.value, '$.textValue'),
                json_extract(j.value, '$.selectedChoiceIds')
         FROM (SELECT last_insert_rowid() AS id) AS r
         CROSS JOIN json_each(?) AS j`,
      ).bind(JSON.stringify(answerPayload)),
    );
  }

  let response: ResponseRow;
  try {
    const batchResults = await env.DB.batch(statements);
    const row = batchResults[0]?.results?.[0] as ResponseRow | undefined;
    if (!row) throw new HttpError(500, 'Failed to save response');
    response = row;
  } catch (error) {
    if (idempotencyKey && isUniqueConstraintError(error)) {
      const existing = await env.DB.prepare(
        `SELECT ${returningCols} FROM survey_responses WHERE idempotency_key = ?`,
      ).bind(idempotencyKey).first<ResponseRow>();
      if (existing) return json(responseToJson(existing), 200);
    }
    throw error;
  }

  const notificationTask = sendResponseNotification(env, survey, response).catch((error) => {
    logError('response_notification_failed', error, {
      surveyId: survey.id,
      responseId: response.id,
    });
  });
  if (ctx) {
    ctx.waitUntil(notificationTask);
  } else {
    await notificationTask;
  }

  return json(responseToJson(response), 201);
}

async function validateAnswers(
  env: Env,
  questions: QuestionRow[],
  visibilityRules: VisibilityRuleRow[],
  answers: AnswerInput[],
  anonymousAccountId: string,
): Promise<void> {
  const byQuestion = new Map<number, AnswerInput>();
  for (const answer of answers) {
    const questionId = requiredInteger(answer?.questionId, 'questionId', { min: 1 });
    if (byQuestion.has(questionId)) throw new HttpError(400, 'Duplicate answer');
    answer.questionId = questionId;
    byQuestion.set(questionId, answer);
  }
  const questionIds = new Set(questions.map((question) => question.id));
  const visibleQuestionIdSet = visibleQuestionIds(questions, visibilityRules, answers);
  for (const questionId of byQuestion.keys()) {
    if (!questionIds.has(questionId)) throw new HttpError(400, 'Answer question does not belong to survey');
    if (!visibleQuestionIdSet.has(questionId)) throw new HttpError(400, 'Answer question is not visible');
  }

  // One query for all choice ids in the survey (avoids N+1 per choice question).
  const choiceQuestionIds = questions
    .filter((question) => isChoiceQuestionType(question.type) && visibleQuestionIdSet.has(question.id))
    .map((question) => question.id);
  const validChoicesByQuestion = await loadValidChoiceIdsByQuestion(env.DB, choiceQuestionIds);

  const allFileKeys: string[] = [];

  for (const question of questions) {
    if (!visibleQuestionIdSet.has(question.id)) continue;
    const questionText = localizedTextFor(question.text_translations, DEFAULT_FORM_CONTENT_LOCALE);
    const answer = byQuestion.get(question.id);
    if (!answer) {
      if (question.is_required) throw new HttpError(400, `Question "${questionText}" is required`);
      if (question.min_selected != null && question.min_selected > 0) {
        throw new HttpError(
          400,
          `Question "${questionText}" requires at least ${question.min_selected} ${
            isImageUploadQuestionType(question.type) ? 'images' : 'choices'
          }`,
        );
      }
      continue;
    }
    if (isTextQuestionType(question.type)) {
      const value = typeof answer.textValue === 'string' ? answer.textValue.trim() : '';
      if (question.is_required && value.length === 0) {
        throw new HttpError(400, `Question "${questionText}" is required`);
      }
      if (question.min_length != null && value.length < question.min_length) {
        throw new HttpError(400, `Question "${questionText}" is too short`);
      }
      if (question.max_length != null && value.length > question.max_length) {
        throw new HttpError(400, `Question "${questionText}" is too long`);
      }
      answer.textValue = value.length === 0 ? null : value;
      answer.selectedChoiceIds = null;
      answer.fileKeys = null;
      continue;
    }

    if (isImageUploadQuestionType(question.type)) {
      const fileKeys = normalizeFileKeys(answer.fileKeys);
      const maxFiles = question.max_selected ?? MEDIA_MAX_FILES;
      const minFiles = question.min_selected ?? (question.is_required ? 1 : 0);
      if (question.is_required && fileKeys.length === 0) {
        throw new HttpError(400, `Question "${questionText}" requires an image`);
      }
      if (fileKeys.length < minFiles) {
        throw new HttpError(400, `Question "${questionText}" requires at least ${minFiles} images`);
      }
      if (fileKeys.length > maxFiles) {
        throw new HttpError(400, `Question "${questionText}" allows at most ${maxFiles} images`);
      }
      assertOwnedMediaKeys(fileKeys, anonymousAccountId);
      allFileKeys.push(...fileKeys);
      answer.fileKeys = fileKeys;
      answer.textValue = null;
      answer.selectedChoiceIds = null;
      continue;
    }

    const selected = Array.isArray(answer.selectedChoiceIds)
      ? answer.selectedChoiceIds.map((choiceId) => requiredInteger(choiceId, 'selectedChoiceIds', { min: 1 }))
      : [];
    if (question.is_required && selected.length === 0) {
      throw new HttpError(400, `Question "${questionText}" requires a choice`);
    }
    if (question.type === 'singleChoice' && selected.length > 1) {
      throw new HttpError(400, `Question "${questionText}" allows one choice`);
    }
    if (question.min_selected != null && selected.length < question.min_selected) {
      throw new HttpError(400, `Question "${questionText}" requires at least ${question.min_selected} choices`);
    }
    if (question.max_selected != null && selected.length > question.max_selected) {
      throw new HttpError(400, `Question "${questionText}" allows at most ${question.max_selected} choices`);
    }
    const validChoices = validChoicesByQuestion.get(question.id) ?? new Set<number>();
    for (const choiceId of selected) {
      if (!validChoices.has(choiceId)) throw new HttpError(400, 'Choice does not belong to question');
    }
    answer.textValue = null;
    answer.selectedChoiceIds = selected;
    answer.fileKeys = null;
  }

  if (allFileKeys.length > 0) {
    await assertMediaObjectsExist(env, allFileKeys);
  }
}

function normalizeFileKeys(value: unknown): string[] {
  if (value == null) return [];
  if (!Array.isArray(value)) throw new HttpError(400, 'fileKeys must be an array');
  if (value.length > MEDIA_MAX_FILES) {
    throw new HttpError(400, `fileKeys allows at most ${MEDIA_MAX_FILES} items`);
  }
  const keys: string[] = [];
  for (const [index, item] of value.entries()) {
    if (typeof item !== 'string' || item.trim().length === 0) {
      throw new HttpError(400, `fileKeys[${index}] must be a non-empty string`);
    }
    const key = item.trim();
    if (keys.includes(key)) throw new HttpError(400, 'fileKeys contains duplicates');
    keys.push(key);
  }
  return keys;
}

async function loadValidChoiceIdsByQuestion(
  db: D1Database,
  questionIds: number[],
): Promise<Map<number, Set<number>>> {
  const map = new Map<number, Set<number>>();
  if (questionIds.length === 0) return map;
  const rows = await queryInChunks<{ id: number; question_id: number }>(
    db,
    (ph) => `SELECT id, question_id FROM choices WHERE question_id IN (${ph})`,
    questionIds,
  );
  for (const row of rows) {
    const set = map.get(row.question_id) ?? new Set<number>();
    set.add(row.id);
    map.set(row.question_id, set);
  }
  return map;
}

function isAccepting(survey: SurveyRow): boolean {
  const now = Date.now();
  if (survey.starts_at && Date.parse(survey.starts_at) > now) return false;
  if (survey.ends_at && Date.parse(survey.ends_at) < now) return false;
  return true;
}
