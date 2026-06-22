import type { AnonymousContext, AnswerInput, AnswerRow, ChoiceRow, Env, QuestionRow, ResponseRow, SurveyRow } from './types';
import { HttpError, isChoiceQuestionType, isTextQuestionType, json, nowIso, readJson, requireAnswerInput } from './utils';
import { normalizeDeviceInfo, normalizeMetadata } from './metadata';
import { choiceToJson, parseChoiceIds, questionToJson, responseToJson, surveyToJson } from './serializers';

export async function getPublicSurvey(env: Env, slug: string): Promise<Response> {
  const row = await env.DB.prepare(
    `SELECT * FROM surveys WHERE slug = ? AND status = 'published'`,
  ).bind(slug).first<SurveyRow>();
  if (!row || !isAccepting(row)) return json(null);
  return json(surveyToJson(row));
}

export async function getPublicQuestions(env: Env, surveyId: number): Promise<Response> {
  const survey = await env.DB.prepare(
    `SELECT * FROM surveys WHERE id = ? AND status = 'published'`,
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
     WHERE q.id = ? AND q.is_deleted = 0 AND s.status = 'published'`,
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
): Promise<Response> {
  const survey = await env.DB.prepare(`SELECT * FROM surveys WHERE id = ?`)
    .bind(surveyId)
    .first<SurveyRow>();
  if (!survey || survey.status !== 'published' || !isAccepting(survey)) {
    throw new HttpError(400, 'Survey is not accepting responses');
  }

  const body = await readJson(request);
  const answers = Array.isArray(body.answers)
    ? body.answers.map(requireAnswerInput)
    : [];
  const questions = await env.DB.prepare(
    `SELECT * FROM questions WHERE survey_id = ? AND is_deleted = 0 ORDER BY order_index`,
  ).bind(surveyId).all<QuestionRow>();
  await validateAnswers(env, questions.results, answers);

  const now = nowIso();
  const userAgent = request.headers.get('user-agent');
  const deviceInfo = normalizeDeviceInfo(body.deviceInfo);
  const metadata = normalizeMetadata(body.metadata);
  const response = await env.DB.prepare(
    `INSERT INTO survey_responses
       (survey_id, anonymous_account_id, anonymous_id, submitted_at, ip_address, user_agent,
        device_id, device_label, device_platform, device_os, device_os_version,
        device_browser, device_browser_version, device_locale, device_timezone,
        screen_width, screen_height, device_pixel_ratio, device_info, metadata)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
     RETURNING id, survey_id, anonymous_account_id, anonymous_id, submitted_at, user_agent,
       device_id, device_label, device_platform, device_os, device_os_version,
       device_browser, device_browser_version, device_locale, device_timezone,
       screen_width, screen_height, device_pixel_ratio, device_info, metadata`,
  )
    .bind(
      surveyId,
      anonymous.id,
      typeof body.anonymousId === 'string' ? body.anonymousId : anonymous.id,
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
    )
    .first<ResponseRow>();

  if (!response) throw new HttpError(500, 'Failed to save response');

  const inserts = answers.map((answer) =>
    env.DB.prepare(
      `INSERT INTO answers
         (survey_response_id, question_id, text_value, selected_choice_ids)
       VALUES (?, ?, ?, ?)`,
    ).bind(
      response.id,
      Number(answer.questionId),
      typeof answer.textValue === 'string' ? answer.textValue : null,
      Array.isArray(answer.selectedChoiceIds)
        ? JSON.stringify(answer.selectedChoiceIds.map(Number))
        : null,
    ),
  );
  if (inserts.length > 0) await env.DB.batch(inserts);

  await env.DB.prepare(
    `UPDATE anonymous_accounts SET last_seen_at = ? WHERE id = ?`,
  ).bind(now, anonymous.id).run();

  return json(responseToJson(response), 201);
}

async function validateAnswers(
  env: Env,
  questions: QuestionRow[],
  answers: AnswerInput[],
): Promise<void> {
  const byQuestion = new Map<number, AnswerInput>();
  for (const answer of answers) {
    const questionId = Number(answer?.questionId);
    if (!Number.isInteger(questionId)) throw new HttpError(400, 'Invalid questionId');
    if (byQuestion.has(questionId)) throw new HttpError(400, 'Duplicate answer');
    byQuestion.set(questionId, answer);
  }
  const questionIds = new Set(questions.map((question) => question.id));
  for (const questionId of byQuestion.keys()) {
    if (!questionIds.has(questionId)) throw new HttpError(400, 'Answer question does not belong to survey');
  }
  for (const question of questions) {
    const answer = byQuestion.get(question.id);
    if (!answer) {
      if (question.is_required) throw new HttpError(400, `Question "${question.text}" is required`);
      continue;
    }
    if (isTextQuestionType(question.type)) {
      const value = typeof answer.textValue === 'string' ? answer.textValue.trim() : '';
      if (question.is_required && value.length === 0) {
        throw new HttpError(400, `Question "${question.text}" is required`);
      }
      if (question.min_length != null && value.length < question.min_length) {
        throw new HttpError(400, `Question "${question.text}" is too short`);
      }
      if (question.max_length != null && value.length > question.max_length) {
        throw new HttpError(400, `Question "${question.text}" is too long`);
      }
      answer.textValue = value.length === 0 ? null : value;
      answer.selectedChoiceIds = null;
      continue;
    }

    const selected = Array.isArray(answer.selectedChoiceIds)
      ? answer.selectedChoiceIds.map(Number)
      : [];
    if (question.is_required && selected.length === 0) {
      throw new HttpError(400, `Question "${question.text}" requires a choice`);
    }
    if (question.type === 'singleChoice' && selected.length > 1) {
      throw new HttpError(400, `Question "${question.text}" allows one choice`);
    }
    const choices = await env.DB.prepare(
      `SELECT id FROM choices WHERE question_id = ?`,
    ).bind(question.id).all<{ id: number }>();
    const validChoices = new Set(choices.results.map((choice) => choice.id));
    for (const choiceId of selected) {
      if (!validChoices.has(choiceId)) throw new HttpError(400, 'Choice does not belong to question');
    }
    answer.textValue = null;
    answer.selectedChoiceIds = selected;
  }
}

function isAccepting(survey: SurveyRow): boolean {
  const now = Date.now();
  if (survey.starts_at && Date.parse(survey.starts_at) > now) return false;
  if (survey.ends_at && Date.parse(survey.ends_at) < now) return false;
  return true;
}
