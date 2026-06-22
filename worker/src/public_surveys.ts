import type { AnonymousContext, AnswerInput, AnswerRow, ChoiceRow, Env, ProjectRow, QuestionRow, ResponseRow, SurveyRow, VisibilityRuleRow } from './types';
import { HttpError, isChoiceQuestionType, isTextQuestionType, json, logError, nowIso, optionalCustomDomain, readJson, requireAnswerInput, requiredInteger } from './utils';
import { normalizeDeviceInfo, normalizeMetadata } from './metadata';
import { choiceToJson, parseChoiceIds, projectToJson, questionToJson, responseToJson, surveyToJson } from './serializers';
import { getVisibilityRules, visibleQuestionIds } from './visibility_rules';
import { DEFAULT_FORM_CONTENT_LOCALE, localizedTextFor } from './localization';
import { sendResponseNotification } from './notification_settings';

export async function getPublicProject(env: Env, slug: string): Promise<Response> {
  const project = await env.DB.prepare(
    `SELECT * FROM projects WHERE slug = ?`,
  ).bind(slug).first<ProjectRow>();
  if (!project) return json(null);
  return json(await publicProjectPayload(env, project));
}

export async function getPublicProjectByDomain(env: Env, domainValue: string | null): Promise<Response> {
  let customDomain: string | null = null;
  try {
    customDomain = optionalCustomDomain(domainValue);
  } catch (error) {
    if (error instanceof HttpError) return json(null);
    throw error;
  }
  if (!customDomain) return json(null);
  const project = await env.DB.prepare(
    `SELECT * FROM projects WHERE custom_domain = ?`,
  ).bind(customDomain).first<ProjectRow>();
  if (!project) return json(null);
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
  const answers = Array.isArray(body.answers)
    ? body.answers.map(requireAnswerInput)
    : [];
  const questions = await env.DB.prepare(
    `SELECT * FROM questions WHERE survey_id = ? AND is_deleted = 0 ORDER BY order_index`,
  ).bind(surveyId).all<QuestionRow>();
  const visibilityRules = await getVisibilityRules(env.DB, surveyId);
  await validateAnswers(env, questions.results, visibilityRules, answers);

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
      requiredInteger(answer.questionId, 'questionId', { min: 1 }),
      typeof answer.textValue === 'string' ? answer.textValue : null,
      Array.isArray(answer.selectedChoiceIds)
        ? JSON.stringify(answer.selectedChoiceIds.map((choiceId) => requiredInteger(choiceId, 'selectedChoiceIds', { min: 1 })))
        : null,
    ),
  );
  if (inserts.length > 0) await env.DB.batch(inserts);

  await env.DB.prepare(
    `UPDATE anonymous_accounts SET last_seen_at = ? WHERE id = ?`,
  ).bind(now, anonymous.id).run();

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
  for (const question of questions) {
    if (!visibleQuestionIdSet.has(question.id)) continue;
    const questionText = localizedTextFor(question.text_translations, DEFAULT_FORM_CONTENT_LOCALE);
    const answer = byQuestion.get(question.id);
    if (!answer) {
      if (question.is_required) throw new HttpError(400, `Question "${questionText}" is required`);
      if (question.min_selected != null && question.min_selected > 0) {
        throw new HttpError(400, `Question "${questionText}" requires at least ${question.min_selected} choices`);
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
