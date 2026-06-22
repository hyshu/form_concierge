export interface Env {
  DB: D1Database;
  PUBLIC_BASE_URL?: string;
}

type AdminContext = {
  id: string;
  email: string;
  scopeNames: string[];
  blocked: boolean;
  created: string;
};

type AnonymousContext = {
  id: string;
  displayName: string | null;
  createdAt: string;
  lastSeenAt: string;
};

type SurveyRow = {
  id: number;
  slug: string;
  title: string;
  description: string | null;
  status: string;
  auth_requirement: string;
  created_by_admin_id: string | null;
  created_at: string;
  updated_at: string;
  starts_at: string | null;
  ends_at: string | null;
};

type QuestionRow = {
  id: number;
  survey_id: number;
  text: string;
  type: string;
  order_index: number;
  is_required: number;
  placeholder: string | null;
  min_length: number | null;
  max_length: number | null;
  is_deleted: number;
};

type ChoiceRow = {
  id: number;
  question_id: number;
  text: string;
  order_index: number;
  value: string | null;
};

type ResponseRow = {
  id: number;
  survey_id: number;
  anonymous_account_id: string;
  anonymous_id: string | null;
  submitted_at: string;
  user_agent: string | null;
  device_id: string | null;
  device_label: string | null;
  device_platform: string | null;
  device_os: string | null;
  device_os_version: string | null;
  device_browser: string | null;
  device_browser_version: string | null;
  device_locale: string | null;
  device_timezone: string | null;
  screen_width: number | null;
  screen_height: number | null;
  device_pixel_ratio: number | null;
  device_info: string | null;
  metadata: string | null;
};

type AnswerRow = {
  id: number;
  survey_response_id: number;
  question_id: number;
  text_value: string | null;
  selected_choice_ids: string | null;
};

type ReplyRow = {
  id: number;
  survey_response_id: number;
  anonymous_account_id: string;
  admin_id: string | null;
  body: string;
  created_at: string;
  read_at: string | null;
};

type QuestionInput = {
  text: string;
  type: string;
  isRequired: boolean;
  placeholder: string | null;
  choices: string[];
};

type NormalizedDeviceInfo = {
  deviceId: string | null;
  label: string | null;
  platform: string | null;
  os: string | null;
  osVersion: string | null;
  browser: string | null;
  browserVersion: string | null;
  appVersion: string | null;
  appBuild: string | null;
  model: string | null;
  manufacturer: string | null;
  locale: string | null;
  timezone: string | null;
  screenWidth: number | null;
  screenHeight: number | null;
  devicePixelRatio: number | null;
  rawJson: string | null;
};

const jsonHeaders = {
  'content-type': 'application/json; charset=utf-8',
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET,POST,PUT,DELETE,OPTIONS',
  'access-control-allow-headers': 'content-type,authorization',
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: jsonHeaders });
    }

    try {
      return await route(request, env);
    } catch (error) {
      if (error instanceof HttpError) {
        return json({ error: error.message, details: error.details }, error.status);
      }
      console.error(error);
      return json({ error: 'Internal server error' }, 500);
    }
  },
};

async function route(request: Request, env: Env): Promise<Response> {
  const url = new URL(request.url);
  const path = url.pathname.replace(/\/+$/, '') || '/';
  const method = request.method.toUpperCase();
  const parts = path.split('/').filter(Boolean);

  if (method === 'GET' && path === '/api/config') {
    return json({
      passwordResetEnabled: false,
      requireEmailVerification: false,
      geminiEnabled: false,
    });
  }

  if (method === 'GET' && path === '/api/admin/bootstrap/status') {
    const count = await countRows(env.DB, 'SELECT COUNT(*) AS count FROM admins');
    return json({ isFirstUser: count === 0 });
  }

  if (method === 'POST' && path === '/api/admin/bootstrap') {
    return bootstrapAdmin(request, env);
  }

  if (method === 'POST' && path === '/api/admin/auth/login') {
    return loginAdmin(request, env);
  }

  if (method === 'POST' && path === '/api/anonymous/accounts') {
    return createAnonymousAccount(request, env);
  }

  if (path === '/api/anonymous/me' && method === 'GET') {
    const anonymous = await requireAnonymous(request, env);
    return json(anonymousAccountToJson(anonymous));
  }

  if (path === '/api/anonymous/replies' && method === 'GET') {
    const anonymous = await requireAnonymous(request, env);
    const responseId = url.searchParams.get('responseId');
    const statement = responseId
      ? env.DB.prepare(
          `SELECT * FROM admin_replies
           WHERE anonymous_account_id = ? AND survey_response_id = ?
           ORDER BY created_at DESC`,
        ).bind(anonymous.id, Number(responseId))
      : env.DB.prepare(
          `SELECT * FROM admin_replies
           WHERE anonymous_account_id = ?
           ORDER BY created_at DESC`,
        ).bind(anonymous.id);
    const rows = await statement.all<ReplyRow>();
    return json(rows.results.map(replyToJson));
  }

  if (parts[0] === 'api' && parts[1] === 'surveys' && parts[2] && method === 'GET') {
    if (parts[2] === 'id' && parts[3] && parts[4] === 'questions') {
      return getPublicQuestions(env, Number(parts[3]));
    }
    return getPublicSurvey(env, parts[2]);
  }

  if (
    parts[0] === 'api' &&
    parts[1] === 'surveys' &&
    parts[2] === 'id' &&
    parts[3] &&
    parts[4] === 'responses' &&
    method === 'POST'
  ) {
    const anonymous = await requireAnonymous(request, env);
    return submitResponse(request, env, Number(parts[3]), anonymous);
  }

  if (
    parts[0] === 'api' &&
    parts[1] === 'questions' &&
    parts[2] &&
    parts[3] === 'choices' &&
    method === 'GET'
  ) {
    return getPublicChoices(env, Number(parts[2]));
  }

  if (parts[0] === 'api' && parts[1] === 'admin') {
    const admin = await requireAdmin(request, env);
    return routeAdmin(request, env, admin, parts, url);
  }

  return json({ error: 'Not found' }, 404);
}

async function routeAdmin(
  request: Request,
  env: Env,
  admin: AdminContext,
  parts: string[],
  url: URL,
): Promise<Response> {
  const method = request.method.toUpperCase();

  if (parts[2] === 'users') {
    if (method === 'GET' && parts.length === 3) return listUsers(env);
    if (method === 'POST' && parts.length === 3) return createUser(request, env);
    if (method === 'DELETE' && parts[3]) return deleteUser(env, admin, parts[3]);
    if (method === 'POST' && parts[3] && parts[4] === 'toggle-blocked') {
      return toggleUserBlocked(env, parts[3]);
    }
  }

  if (parts[2] === 'surveys') {
    if (method === 'GET' && parts.length === 3) return listSurveys(env, admin);
    if (method === 'POST' && parts.length === 3) return createSurvey(request, env, admin);
    if (method === 'POST' && parts[3] === 'with-questions') {
      return createSurveyWithQuestions(request, env, admin);
    }

    const surveyId = Number(parts[3]);
    if (Number.isFinite(surveyId)) {
      if (method === 'GET' && parts.length === 4) return getAdminSurvey(env, surveyId);
      if (method === 'PUT' && parts.length === 4) return updateSurvey(request, env, surveyId);
      if (method === 'DELETE' && parts.length === 4) return deleteSurvey(env, surveyId);
      if (method === 'POST' && parts[4] === 'publish') {
        return updateSurveyStatus(env, surveyId, 'published', ['draft'], 'Only draft surveys can be published');
      }
      if (method === 'POST' && parts[4] === 'close') {
        return updateSurveyStatus(env, surveyId, 'closed', ['published'], 'Only published surveys can be closed');
      }
      if (method === 'POST' && parts[4] === 'reopen') {
        return updateSurveyStatus(env, surveyId, 'published', ['closed'], 'Only closed surveys can be reopened');
      }
      if (method === 'GET' && parts[4] === 'questions') {
        return getAdminQuestions(env, surveyId);
      }
      if (method === 'POST' && parts[4] === 'questions' && parts[5] === 'reorder') {
        return reorderQuestions(request, env, surveyId);
      }
      if (method === 'GET' && parts[4] === 'responses' && parts[5] === 'count') {
        return responseCount(env, surveyId);
      }
      if (method === 'GET' && parts[4] === 'responses') {
        return listResponses(env, surveyId, url);
      }
      if (method === 'GET' && parts[4] === 'results') {
        return aggregatedResults(env, surveyId);
      }
      if (method === 'GET' && parts[4] === 'trends') {
        return responseTrends(env, surveyId, url);
      }
      if (parts[4] === 'notification-settings') {
        return notificationSettings(request, env, surveyId, parts);
      }
    }
  }

  if (parts[2] === 'questions') {
    if (method === 'POST' && parts.length === 3) return createQuestion(request, env);
    const questionId = Number(parts[3]);
    if (Number.isFinite(questionId)) {
      if (method === 'GET' && parts.length === 4) return getQuestion(env, questionId);
      if (method === 'PUT' && parts.length === 4) return updateQuestion(request, env, questionId);
      if (method === 'DELETE' && parts.length === 4) return deleteQuestion(env, questionId);
      if (method === 'GET' && parts[4] === 'choices') return getChoices(env, questionId);
      if (method === 'POST' && parts[4] === 'choices' && parts[5] === 'reorder') {
        return reorderChoices(request, env, questionId);
      }
    }
  }

  if (parts[2] === 'choices') {
    if (method === 'POST' && parts.length === 3) return createChoice(request, env);
    const choiceId = Number(parts[3]);
    if (Number.isFinite(choiceId)) {
      if (method === 'GET' && parts.length === 4) return getChoice(env, choiceId);
      if (method === 'PUT' && parts.length === 4) return updateChoice(request, env, choiceId);
      if (method === 'DELETE' && parts.length === 4) return deleteChoice(env, choiceId);
    }
  }

  if (parts[2] === 'responses') {
    const responseId = Number(parts[3]);
    if (Number.isFinite(responseId)) {
      if (method === 'GET' && parts[4] === 'answers') return responseAnswers(env, responseId);
      if (method === 'DELETE' && parts.length === 4) return deleteResponse(env, responseId);
      if (method === 'GET' && parts[4] === 'replies') return getReplies(env, responseId);
      if (method === 'POST' && parts[4] === 'replies') {
        return createReply(request, env, admin, responseId);
      }
    }
  }

  if (parts[2] === 'ai' && parts[3] === 'survey-questions') {
    throw new HttpError(501, 'AI generation is not configured');
  }

  return json({ error: 'Not found' }, 404);
}

async function bootstrapAdmin(request: Request, env: Env): Promise<Response> {
  const count = await countRows(env.DB, 'SELECT COUNT(*) AS count FROM admins');
  if (count > 0) throw new HttpError(409, 'Admin already exists');
  const body = await readJson(request);
  const email = requireString(body.email, 'email').toLowerCase();
  const password = requireString(body.password, 'password');
  const passwordHash = await hashPassword(password);
  const id = crypto.randomUUID();
  await env.DB.prepare(
    `INSERT INTO admins (id, email, password_hash, scope_names)
     VALUES (?, ?, ?, ?)`,
  ).bind(id, email, passwordHash, JSON.stringify(['admin', 'user'])).run();
  const user = await getAdminById(env.DB, id);
  return json(await createAdminSession(env.DB, user!));
}

async function loginAdmin(request: Request, env: Env): Promise<Response> {
  const body = await readJson(request);
  const email = requireString(body.email, 'email').toLowerCase();
  const password = requireString(body.password, 'password');
  const row = await env.DB.prepare(
    `SELECT id, email, password_hash, scope_names, blocked, created_at
     FROM admins WHERE email = ?`,
  ).bind(email).first<{
    id: string;
    email: string;
    password_hash: string;
    scope_names: string;
    blocked: number;
    created_at: string;
  }>();
  if (!row || row.blocked || !(await verifyPassword(password, row.password_hash))) {
    throw new HttpError(401, 'Invalid email or password');
  }
  const user = adminRowToContext(row);
  return json(await createAdminSession(env.DB, user));
}

async function createAnonymousAccount(request: Request, env: Env): Promise<Response> {
  const body = await readJson(request, true);
  const displayName =
    typeof body.displayName === 'string' && body.displayName.trim().length > 0
      ? body.displayName.trim()
      : null;
  const token = randomToken();
  const tokenHash = await sha256Hex(token);
  const id = crypto.randomUUID();
  const now = nowIso();
  await env.DB.prepare(
    `INSERT INTO anonymous_accounts (id, token_hash, display_name, created_at, last_seen_at)
     VALUES (?, ?, ?, ?, ?)`,
  ).bind(id, tokenHash, displayName, now, now).run();
  return json({
    account: anonymousAccountToJson({ id, displayName, createdAt: now, lastSeenAt: now }),
    token,
  }, 201);
}

async function getPublicSurvey(env: Env, slug: string): Promise<Response> {
  const row = await env.DB.prepare(
    `SELECT * FROM surveys WHERE slug = ? AND status = 'published'`,
  ).bind(slug).first<SurveyRow>();
  if (!row || !isAccepting(row)) return json(null);
  return json(surveyToJson(row));
}

async function getPublicQuestions(env: Env, surveyId: number): Promise<Response> {
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

async function getPublicChoices(env: Env, questionId: number): Promise<Response> {
  const question = await env.DB.prepare(
    `SELECT q.* FROM questions q
     JOIN surveys s ON s.id = q.survey_id
     WHERE q.id = ? AND q.is_deleted = 0 AND s.status = 'published'`,
  ).bind(questionId).first<QuestionRow>();
  if (!question) return json([]);
  return getChoices(env, questionId);
}

async function submitResponse(
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
  const answers = Array.isArray(body.answers) ? body.answers : [];
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

  const inserts = answers
    .filter((answer: unknown) => typeof answer === 'object' && answer !== null)
    .map((answer: any) =>
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

async function listSurveys(env: Env, admin: AdminContext): Promise<Response> {
  const rows = await env.DB.prepare(
    `SELECT * FROM surveys
     WHERE created_by_admin_id = ?
     ORDER BY updated_at DESC`,
  ).bind(admin.id).all<SurveyRow>();
  return json(rows.results.map(surveyToJson));
}

async function getAdminSurvey(env: Env, surveyId: number): Promise<Response> {
  const row = await env.DB.prepare(`SELECT * FROM surveys WHERE id = ?`)
    .bind(surveyId)
    .first<SurveyRow>();
  return json(row ? surveyToJson(row) : null);
}

async function createSurvey(request: Request, env: Env, admin: AdminContext): Promise<Response> {
  const body = await readJson(request);
  const slug = requireSlug(body.slug);
  await ensureUniqueSlug(env.DB, slug);
  const now = nowIso();
  const row = await env.DB.prepare(
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
  return json(surveyToJson(requiredRow(row, 'Survey')), 201);
}

async function createSurveyWithQuestions(
  request: Request,
  env: Env,
  admin: AdminContext,
): Promise<Response> {
  const body = await readJson(request);
  const survey = body.survey ?? {};
  const questions = parseQuestionInputs(body.questions);
  const response = await createSurvey(new Request(request.url, {
    method: 'POST',
    body: JSON.stringify(survey),
  }), env, admin);
  const created = (await response.json()) as any;

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
    if (question.type === 'singleChoice' || question.type === 'multipleChoice') {
      const choices = Array.isArray(q.choices) ? q.choices : [];
      for (let j = 0; j < choices.length; j++) {
        await env.DB.prepare(
          `INSERT INTO choices (question_id, text, order_index) VALUES (?, ?, ?)`,
        ).bind(question.id, String(choices[j]), j).run();
      }
    }
  }
  return json(created, 201);
}

async function updateSurvey(request: Request, env: Env, surveyId: number): Promise<Response> {
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

async function deleteSurvey(env: Env, surveyId: number): Promise<Response> {
  await env.DB.prepare(`DELETE FROM surveys WHERE id = ?`).bind(surveyId).run();
  return json({ ok: true });
}

async function updateSurveyStatus(
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

async function createQuestion(request: Request, env: Env): Promise<Response> {
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
  if (question.type === 'singleChoice' || question.type === 'multipleChoice') {
    await env.DB.batch([
      env.DB.prepare(`INSERT INTO choices (question_id, text, order_index) VALUES (?, ?, ?)`)
        .bind(question.id, 'Choice 1', 0),
      env.DB.prepare(`INSERT INTO choices (question_id, text, order_index) VALUES (?, ?, ?)`)
        .bind(question.id, 'Choice 2', 1),
    ]);
  }
  return json(questionToJson(question), 201);
}

async function updateQuestion(request: Request, env: Env, questionId: number): Promise<Response> {
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

async function deleteQuestion(env: Env, questionId: number): Promise<Response> {
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

async function reorderQuestions(request: Request, env: Env, surveyId: number): Promise<Response> {
  const body = await readJson(request);
  const questionIds = requireNumberList(body.questionIds, 'questionIds');
  const rows = await env.DB.prepare(
    `SELECT * FROM questions WHERE survey_id = ? AND is_deleted = 0 ORDER BY order_index`,
  ).bind(surveyId).all<QuestionRow>();
  assertExactIds(rows.results.map((row) => row.id), questionIds, 'questionIds');
  for (let i = 0; i < questionIds.length; i++) {
    await env.DB.prepare(`UPDATE questions SET order_index = ? WHERE id = ?`)
      .bind(i, questionIds[i])
      .run();
  }
  return getAdminQuestions(env, surveyId);
}

async function getAdminQuestions(env: Env, surveyId: number): Promise<Response> {
  const rows = await env.DB.prepare(
    `SELECT * FROM questions WHERE survey_id = ? AND is_deleted = 0 ORDER BY order_index`,
  ).bind(surveyId).all<QuestionRow>();
  return json(rows.results.map(questionToJson));
}

async function getQuestion(env: Env, questionId: number): Promise<Response> {
  const row = await env.DB.prepare(`SELECT * FROM questions WHERE id = ?`)
    .bind(questionId)
    .first<QuestionRow>();
  return json(row ? questionToJson(row) : null);
}

async function createChoice(request: Request, env: Env): Promise<Response> {
  const body = await readJson(request);
  const question = await mustQuestion(env.DB, Number(body.questionId));
  if (question.type !== 'singleChoice' && question.type !== 'multipleChoice') {
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

async function updateChoice(request: Request, env: Env, choiceId: number): Promise<Response> {
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

async function deleteChoice(env: Env, choiceId: number): Promise<Response> {
  await mustChoice(env.DB, choiceId);
  await env.DB.prepare(`DELETE FROM choices WHERE id = ?`).bind(choiceId).run();
  return json({ ok: true });
}

async function reorderChoices(request: Request, env: Env, questionId: number): Promise<Response> {
  const body = await readJson(request);
  const choiceIds = requireNumberList(body.choiceIds, 'choiceIds');
  const rows = await env.DB.prepare(
    `SELECT * FROM choices WHERE question_id = ? ORDER BY order_index`,
  ).bind(questionId).all<ChoiceRow>();
  assertExactIds(rows.results.map((row) => row.id), choiceIds, 'choiceIds');
  for (let i = 0; i < choiceIds.length; i++) {
    await env.DB.prepare(`UPDATE choices SET order_index = ? WHERE id = ?`)
      .bind(i, choiceIds[i])
      .run();
  }
  return getChoices(env, questionId);
}

async function getChoices(env: Env, questionId: number): Promise<Response> {
  const rows = await env.DB.prepare(
    `SELECT * FROM choices WHERE question_id = ? ORDER BY order_index`,
  ).bind(questionId).all<ChoiceRow>();
  return json(rows.results.map(choiceToJson));
}

async function getChoice(env: Env, choiceId: number): Promise<Response> {
  const row = await env.DB.prepare(`SELECT * FROM choices WHERE id = ?`)
    .bind(choiceId)
    .first<ChoiceRow>();
  return json(row ? choiceToJson(row) : null);
}

async function listResponses(env: Env, surveyId: number, url: URL): Promise<Response> {
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

async function responseCount(env: Env, surveyId: number): Promise<Response> {
  return json({
    count: await countRows(
      env.DB,
      `SELECT COUNT(*) AS count FROM survey_responses WHERE survey_id = ?`,
      surveyId,
    ),
  });
}

async function responseAnswers(env: Env, responseId: number): Promise<Response> {
  const rows = await env.DB.prepare(
    `SELECT * FROM answers WHERE survey_response_id = ?`,
  ).bind(responseId).all<AnswerRow>();
  return json(rows.results.map(answerToJson));
}

async function aggregatedResults(env: Env, surveyId: number): Promise<Response> {
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
    if (question.type === 'singleChoice' || question.type === 'multipleChoice') {
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

async function responseTrends(env: Env, surveyId: number, url: URL): Promise<Response> {
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

async function deleteResponse(env: Env, responseId: number): Promise<Response> {
  await env.DB.prepare(`DELETE FROM survey_responses WHERE id = ?`).bind(responseId).run();
  return json({ ok: true });
}

async function createReply(
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

async function getReplies(env: Env, responseId: number): Promise<Response> {
  const rows = await env.DB.prepare(
    `SELECT * FROM admin_replies WHERE survey_response_id = ? ORDER BY created_at DESC`,
  ).bind(responseId).all<ReplyRow>();
  return json(rows.results.map(replyToJson));
}

async function notificationSettings(
  request: Request,
  env: Env,
  surveyId: number,
  parts: string[],
): Promise<Response> {
  const method = request.method.toUpperCase();
  if (method === 'GET') {
    const row = await env.DB.prepare(
      `SELECT * FROM notification_settings WHERE survey_id = ?`,
    ).bind(surveyId).first<any>();
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
    ).first<any>();
    return json(notificationToJson(requiredRow(row, 'NotificationSettings')));
  }
  if (method === 'POST' && parts[5] === 'toggle') {
    const body = await readJson(request);
    const row = await env.DB.prepare(
      `UPDATE notification_settings SET enabled = ?, updated_at = ?
       WHERE survey_id = ? RETURNING *`,
    ).bind(boolToInt(body.enabled), nowIso(), surveyId).first<any>();
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

async function listUsers(env: Env): Promise<Response> {
  const rows = await env.DB.prepare(
    `SELECT id, email, scope_names, blocked, created_at FROM admins ORDER BY created_at`,
  ).all<any>();
  return json(rows.results.map(adminUserToJson));
}

async function createUser(request: Request, env: Env): Promise<Response> {
  const body = await readJson(request);
  const id = crypto.randomUUID();
  await env.DB.prepare(
    `INSERT INTO admins (id, email, password_hash, scope_names)
     VALUES (?, ?, ?, ?)`,
  ).bind(
    id,
    requireString(body.email, 'email').toLowerCase(),
    await hashPassword(requireString(body.password, 'password')),
    JSON.stringify(Array.isArray(body.scopes) ? body.scopes.map(String) : ['admin']),
  ).run();
  const user = await getAdminById(env.DB, id);
  return json(adminContextToJson(user!), 201);
}

async function deleteUser(env: Env, admin: AdminContext, userId: string): Promise<Response> {
  await env.DB.prepare(`DELETE FROM admins WHERE id = ?`).bind(userId).run();
  return json({ selfDeleted: admin.id === userId });
}

async function toggleUserBlocked(env: Env, userId: string): Promise<Response> {
  const row = await env.DB.prepare(
    `UPDATE admins SET blocked = CASE WHEN blocked = 1 THEN 0 ELSE 1 END,
     updated_at = ? WHERE id = ? RETURNING blocked`,
  ).bind(nowIso(), userId).first<{ blocked: number }>();
  if (!row) throw new HttpError(404, 'User not found');
  return json({ blocked: row.blocked === 1 });
}

async function validateAnswers(
  env: Env,
  questions: QuestionRow[],
  answers: any[],
): Promise<void> {
  const byQuestion = new Map<number, any>();
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
    if (question.type === 'textSingle' || question.type === 'textMultiLine') {
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

async function requireAdmin(request: Request, env: Env): Promise<AdminContext> {
  const token = bearerToken(request);
  if (!token) throw new HttpError(401, 'Admin authentication required');
  const tokenHash = await sha256Hex(token);
  const row = await env.DB.prepare(
    `SELECT a.id, a.email, a.scope_names, a.blocked, a.created_at
     FROM admin_sessions s
     JOIN admins a ON a.id = s.admin_id
     WHERE s.token_hash = ? AND s.expires_at > ?`,
  ).bind(tokenHash, nowIso()).first<any>();
  if (!row || row.blocked) throw new HttpError(401, 'Admin authentication required');
  const admin = adminRowToContext(row);
  if (!admin.scopeNames.includes('admin')) throw new HttpError(403, 'Admin scope required');
  return admin;
}

async function requireAnonymous(request: Request, env: Env): Promise<AnonymousContext> {
  const token = bearerToken(request);
  if (!token) throw new HttpError(401, 'Anonymous account required');
  const tokenHash = await sha256Hex(token);
  const row = await env.DB.prepare(
    `SELECT id, display_name, created_at, last_seen_at
     FROM anonymous_accounts
     WHERE token_hash = ?`,
  ).bind(tokenHash).first<any>();
  if (!row) throw new HttpError(401, 'Anonymous account required');
  return {
    id: row.id,
    displayName: row.display_name,
    createdAt: row.created_at,
    lastSeenAt: row.last_seen_at,
  };
}

async function createAdminSession(db: D1Database, user: AdminContext) {
  const token = randomToken();
  await db.prepare(
    `INSERT INTO admin_sessions (token_hash, admin_id, expires_at)
     VALUES (?, ?, ?)`,
  ).bind(
    await sha256Hex(token),
    user.id,
    new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
  ).run();
  return { token, user: adminContextToJson(user) };
}

async function getAdminById(db: D1Database, id: string): Promise<AdminContext | null> {
  const row = await db.prepare(
    `SELECT id, email, scope_names, blocked, created_at FROM admins WHERE id = ?`,
  ).bind(id).first<any>();
  return row ? adminRowToContext(row) : null;
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

function surveyToJson(row: SurveyRow) {
  return {
    id: row.id,
    slug: row.slug,
    title: row.title,
    description: row.description,
    status: row.status,
    authRequirement: row.auth_requirement,
    createdByUserId: row.created_by_admin_id,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    startsAt: row.starts_at,
    endsAt: row.ends_at,
  };
}

function questionToJson(row: QuestionRow) {
  return {
    id: row.id,
    surveyId: row.survey_id,
    text: row.text,
    type: row.type,
    orderIndex: row.order_index,
    isRequired: row.is_required === 1,
    placeholder: row.placeholder,
    minLength: row.min_length,
    maxLength: row.max_length,
    isDeleted: row.is_deleted === 1,
  };
}

function choiceToJson(row: ChoiceRow) {
  return {
    id: row.id,
    questionId: row.question_id,
    text: row.text,
    orderIndex: row.order_index,
    value: row.value,
  };
}

function responseToJson(row: ResponseRow) {
  return {
    id: row.id,
    surveyId: row.survey_id,
    anonymousAccountId: row.anonymous_account_id,
    anonymousId: row.anonymous_id,
    userId: null,
    submittedAt: row.submitted_at,
    deviceInfo: deviceInfoToJson(row),
    metadata: metadataToJson(row.metadata),
  };
}

function metadataToJson(value: string | null) {
  if (!value) return null;
  const metadata = parseJsonObject(value);
  return Object.keys(metadata).length === 0 ? null : metadata;
}

function deviceInfoToJson(row: ResponseRow) {
  const raw = parseJsonObject(row.device_info);
  const compacted = compactObject({
    ...raw,
    deviceId: row.device_id,
    label: row.device_label,
    platform: row.device_platform,
    os: row.device_os,
    osVersion: row.device_os_version,
    browser: row.device_browser,
    browserVersion: row.device_browser_version,
    locale: row.device_locale,
    timezone: row.device_timezone,
    screenWidth: row.screen_width,
    screenHeight: row.screen_height,
    devicePixelRatio: row.device_pixel_ratio,
    userAgent: row.user_agent,
  });
  return Object.keys(compacted).length === 0 ? null : compacted;
}

function answerToJson(row: AnswerRow) {
  return {
    id: row.id,
    surveyResponseId: row.survey_response_id,
    questionId: row.question_id,
    textValue: row.text_value,
    selectedChoiceIds: parseChoiceIds(row.selected_choice_ids),
  };
}

function replyToJson(row: ReplyRow) {
  return {
    id: row.id,
    surveyResponseId: row.survey_response_id,
    anonymousAccountId: row.anonymous_account_id,
    adminId: row.admin_id,
    body: row.body,
    createdAt: row.created_at,
    readAt: row.read_at,
  };
}

function notificationToJson(row: any) {
  return {
    id: row.id,
    surveyId: row.survey_id,
    enabled: row.enabled === 1,
    recipientEmail: row.recipient_email,
    sendHour: row.send_hour,
    updatedAt: row.updated_at,
    lastSentAt: row.last_sent_at,
  };
}

function adminUserToJson(row: any) {
  return adminContextToJson(adminRowToContext(row));
}

function adminContextToJson(user: AdminContext) {
  return {
    id: user.id,
    email: user.email,
    scopeNames: user.scopeNames,
    blocked: user.blocked,
    created: user.created,
  };
}

function adminRowToContext(row: any): AdminContext {
  return {
    id: row.id,
    email: row.email,
    scopeNames: parseJsonArray(row.scope_names),
    blocked: row.blocked === 1,
    created: row.created_at,
  };
}

function anonymousAccountToJson(account: AnonymousContext) {
  return {
    id: account.id,
    displayName: account.displayName,
    createdAt: account.createdAt,
    lastSeenAt: account.lastSeenAt,
  };
}

function isAccepting(survey: SurveyRow): boolean {
  const now = Date.now();
  if (survey.starts_at && Date.parse(survey.starts_at) > now) return false;
  if (survey.ends_at && Date.parse(survey.ends_at) < now) return false;
  return true;
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
    if (question.type !== 'singleChoice' && question.type !== 'multipleChoice') continue;
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

async function readJson(request: Request, optional = false): Promise<any> {
  const text = await request.text();
  if (!text && optional) return {};
  if (!text) throw new HttpError(400, 'JSON body required');
  try {
    return JSON.parse(text);
  } catch {
    throw new HttpError(400, 'Invalid JSON body');
  }
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

class HttpError extends Error {
  constructor(
    readonly status: number,
    message: string,
    readonly details?: unknown,
  ) {
    super(message);
  }
}

async function countRows(db: D1Database, sql: string, ...binds: unknown[]): Promise<number> {
  const row = await db.prepare(sql).bind(...binds).first<{ count: number }>();
  return Number(row?.count ?? 0);
}

function requiredRow<T>(row: T | null, name: string): T {
  if (!row) throw new HttpError(500, `${name} operation failed`);
  return row;
}

function requireString(value: unknown, field: string): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new HttpError(400, `${field} is required`);
  }
  return value.trim();
}

function optionalString(value: unknown): string | null {
  return typeof value === 'string' && value.trim().length > 0 ? value.trim() : null;
}

function optionalNumber(value: unknown): number | null {
  if (value == null || value === '') return null;
  const number = Number(value);
  return Number.isFinite(number) ? number : null;
}

function requireSlug(value: unknown): string {
  const slug = requireString(value, 'slug');
  if (!/^[a-z0-9-]+$/.test(slug)) throw new HttpError(400, 'slug must contain lowercase letters, numbers, and hyphens');
  return slug;
}

function requireNumberList(value: unknown, field: string): number[] {
  if (!Array.isArray(value)) throw new HttpError(400, `${field} must be an array`);
  const numbers = value.map(Number);
  if (!numbers.every(Number.isInteger)) throw new HttpError(400, `${field} must contain integers`);
  return numbers;
}

function assertExactIds(expected: number[], actual: number[], field: string): void {
  const expectedSorted = [...expected].sort((a, b) => a - b);
  const actualSorted = [...actual].sort((a, b) => a - b);
  if (
    expectedSorted.length !== actualSorted.length ||
    expectedSorted.some((id, index) => id !== actualSorted[index])
  ) {
    throw new HttpError(400, `${field} must include every current id exactly once`);
  }
}

function normalizeQuestionType(value: unknown): string {
  const type = String(value);
  if (['singleChoice', 'multipleChoice', 'textSingle', 'textMultiLine'].includes(type)) {
    return type;
  }
  throw new HttpError(400, 'Invalid question type');
}

function boolToInt(value: unknown): number {
  return value === true || value === 1 || value === 'true' ? 1 : 0;
}

function normalizeDeviceInfo(value: unknown): NormalizedDeviceInfo {
  const empty: NormalizedDeviceInfo = {
    deviceId: null,
    label: null,
    platform: null,
    os: null,
    osVersion: null,
    browser: null,
    browserVersion: null,
    appVersion: null,
    appBuild: null,
    model: null,
    manufacturer: null,
    locale: null,
    timezone: null,
    screenWidth: null,
    screenHeight: null,
    devicePixelRatio: null,
    rawJson: null,
  };

  if (value == null) return empty;
  if (typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpError(400, 'deviceInfo must be an object');
  }

  const source = value as Record<string, unknown>;
  const normalized: NormalizedDeviceInfo = {
    deviceId: optionalLimitedString(source.deviceId, 'deviceInfo.deviceId'),
    label: optionalLimitedString(source.label, 'deviceInfo.label'),
    platform: optionalLimitedString(source.platform, 'deviceInfo.platform'),
    os: optionalLimitedString(source.os, 'deviceInfo.os'),
    osVersion: optionalLimitedString(source.osVersion, 'deviceInfo.osVersion'),
    browser: optionalLimitedString(source.browser, 'deviceInfo.browser'),
    browserVersion: optionalLimitedString(source.browserVersion, 'deviceInfo.browserVersion'),
    appVersion: optionalLimitedString(source.appVersion, 'deviceInfo.appVersion'),
    appBuild: optionalLimitedString(source.appBuild, 'deviceInfo.appBuild'),
    model: optionalLimitedString(source.model, 'deviceInfo.model'),
    manufacturer: optionalLimitedString(source.manufacturer, 'deviceInfo.manufacturer'),
    locale: optionalLimitedString(source.locale, 'deviceInfo.locale'),
    timezone: optionalLimitedString(source.timezone, 'deviceInfo.timezone'),
    screenWidth: optionalPositiveInteger(source.screenWidth, 'deviceInfo.screenWidth'),
    screenHeight: optionalPositiveInteger(source.screenHeight, 'deviceInfo.screenHeight'),
    devicePixelRatio: optionalPositiveNumber(source.devicePixelRatio, 'deviceInfo.devicePixelRatio'),
    rawJson: null,
  };

  const raw = compactObject({
    deviceId: normalized.deviceId,
    label: normalized.label,
    platform: normalized.platform,
    os: normalized.os,
    osVersion: normalized.osVersion,
    browser: normalized.browser,
    browserVersion: normalized.browserVersion,
    appVersion: normalized.appVersion,
    appBuild: normalized.appBuild,
    model: normalized.model,
    manufacturer: normalized.manufacturer,
    locale: normalized.locale,
    timezone: normalized.timezone,
    screenWidth: normalized.screenWidth,
    screenHeight: normalized.screenHeight,
    devicePixelRatio: normalized.devicePixelRatio,
  });

  const rawJson = Object.keys(raw).length === 0 ? null : JSON.stringify(raw);
  if (rawJson != null && rawJson.length > 2048) {
    throw new HttpError(400, 'deviceInfo is too large');
  }

  return { ...normalized, rawJson };
}

function normalizeMetadata(value: unknown): string | null {
  if (value == null) return null;
  if (typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpError(400, 'metadata must be an object');
  }
  const normalized = normalizeMetadataValue(value, 'metadata', 0);
  const json = JSON.stringify(normalized);
  if (json === '{}') return null;
  if (json.length > 4096) throw new HttpError(400, 'metadata is too large');
  return json;
}

function normalizeMetadataValue(value: unknown, field: string, depth: number): unknown {
  if (depth > 5) throw new HttpError(400, `${field} is too deep`);
  if (value == null) return null;
  if (typeof value === 'string') {
    if (value.length > 512) throw new HttpError(400, `${field} string is too long`);
    return value;
  }
  if (typeof value === 'number') {
    if (!Number.isFinite(value)) throw new HttpError(400, `${field} must be finite`);
    return value;
  }
  if (typeof value === 'boolean') return value;
  if (Array.isArray(value)) {
    if (value.length > 50) throw new HttpError(400, `${field} has too many items`);
    return value.map((item, index) => normalizeMetadataValue(item, `${field}[${index}]`, depth + 1));
  }
  if (typeof value === 'object') {
    const entries = Object.entries(value as Record<string, unknown>);
    if (entries.length > 50) throw new HttpError(400, `${field} has too many keys`);
    return Object.fromEntries(
      entries.map(([key, child]) => {
        if (key.length === 0 || key.length > 80) {
          throw new HttpError(400, `${field} has invalid key`);
        }
        return [key, normalizeMetadataValue(child, `${field}.${key}`, depth + 1)];
      }),
    );
  }
  throw new HttpError(400, `${field} has unsupported value`);
}

function optionalLimitedString(value: unknown, field: string, maxLength = 160): string | null {
  if (value == null || value === '') return null;
  if (typeof value !== 'string') throw new HttpError(400, `${field} must be a string`);
  const trimmed = value.trim();
  if (trimmed.length === 0) return null;
  if (trimmed.length > maxLength) throw new HttpError(400, `${field} is too long`);
  return trimmed;
}

function optionalPositiveInteger(value: unknown, field: string): number | null {
  if (value == null || value === '') return null;
  const number = Number(value);
  if (!Number.isInteger(number) || number < 0 || number > 100000) {
    throw new HttpError(400, `${field} must be a positive integer`);
  }
  return number;
}

function optionalPositiveNumber(value: unknown, field: string): number | null {
  if (value == null || value === '') return null;
  const number = Number(value);
  if (!Number.isFinite(number) || number < 0 || number > 1000) {
    throw new HttpError(400, `${field} must be a positive number`);
  }
  return number;
}

function compactObject(source: Record<string, unknown>): Record<string, unknown> {
  return Object.fromEntries(
    Object.entries(source).filter(([, value]) => {
      if (value == null) return false;
      return typeof value !== 'string' || value.trim().length > 0;
    }),
  );
}

function parseChoiceIds(value: string | null): number[] {
  if (!value) return [];
  try {
    const decoded = JSON.parse(value);
    return Array.isArray(decoded) ? decoded.map(Number) : [];
  } catch {
    return [];
  }
}

function parseJsonObject(value: string | null): Record<string, unknown> {
  if (!value) return {};
  try {
    const decoded = JSON.parse(value);
    return decoded && typeof decoded === 'object' && !Array.isArray(decoded)
      ? decoded as Record<string, unknown>
      : {};
  } catch {
    return {};
  }
}

function parseJsonArray(value: string): string[] {
  try {
    const decoded = JSON.parse(value);
    return Array.isArray(decoded) ? decoded.map(String) : [];
  } catch {
    return [];
  }
}

function bearerToken(request: Request): string | null {
  const authorization = request.headers.get('authorization');
  if (!authorization?.startsWith('Bearer ')) return null;
  return authorization.slice('Bearer '.length).trim();
}

function randomToken(): string {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  return base64Url(bytes);
}

async function sha256Hex(input: string): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(input));
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, '0')).join('');
}

async function hashPassword(password: string): Promise<string> {
  const salt = new Uint8Array(16);
  crypto.getRandomValues(salt);
  const iterations = 210000;
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(password),
    'PBKDF2',
    false,
    ['deriveBits'],
  );
  const bits = await crypto.subtle.deriveBits(
    { name: 'PBKDF2', hash: 'SHA-256', salt, iterations },
    key,
    256,
  );
  return `pbkdf2-sha256:${iterations}:${base64Url(salt)}:${base64Url(new Uint8Array(bits))}`;
}

async function verifyPassword(password: string, stored: string): Promise<boolean> {
  const [algorithm, iterationsRaw, saltRaw, hashRaw] = stored.split(':');
  if (algorithm !== 'pbkdf2-sha256') return false;
  const iterations = Number(iterationsRaw);
  const salt = base64UrlDecode(saltRaw);
  const expected = base64UrlDecode(hashRaw);
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(password),
    'PBKDF2',
    false,
    ['deriveBits'],
  );
  const bits = await crypto.subtle.deriveBits(
    { name: 'PBKDF2', hash: 'SHA-256', salt, iterations },
    key,
    expected.byteLength * 8,
  );
  return timingSafeEqual(new Uint8Array(bits), expected);
}

function base64Url(bytes: Uint8Array): string {
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function base64UrlDecode(value: string): Uint8Array {
  const padded = value.replace(/-/g, '+').replace(/_/g, '/').padEnd(Math.ceil(value.length / 4) * 4, '=');
  const binary = atob(padded);
  return Uint8Array.from(binary, (char) => char.charCodeAt(0));
}

function timingSafeEqual(a: Uint8Array, b: Uint8Array): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a[i] ^ b[i];
  return diff === 0;
}

function nowIso(): string {
  return new Date().toISOString();
}
