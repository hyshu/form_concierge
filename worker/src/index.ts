import type { AdminContext, Env, ReplyRow } from './types';
import {
  bootstrapAdmin,
  createAnonymousAccount,
  loginAdmin,
  logoutAdmin,
  requireAdmin,
  requireAnonymous,
} from './auth';
import { changeOwnPassword, createUser, deleteUser, listUsers, updateUserRole } from './admin_users';
import {
  createSurvey,
  createSurveyWithQuestions,
  deleteSurvey,
  getAdminSurvey,
  listSurveys,
  updateSurvey,
  updateSurveyStatus,
} from './admin_surveys';
import { createProject, deleteProject, getAdminProject, listProjects, updateProject } from './admin_projects';
import {
  createChoice,
  createQuestion,
  deleteChoice,
  deleteQuestion,
  getAdminQuestions,
  getChoice,
  getChoices,
  getQuestion,
  reorderChoices,
  reorderQuestions,
  updateChoice,
  updateQuestion,
} from './admin_questions';
import { notificationSettings } from './notification_settings';
import { generateSurveyQuestions, translateLocalizedText } from './ai_generation';
import {
  getAdminIntegrationSettings,
  getTurnstileSiteKey,
  isAiGenerationConfigured,
  isEmailConfiguredResponse,
  isTurnstileConfigured,
  updateAdminIntegrationSettings,
} from './admin_settings';
import {
  getPublicChoices,
  getPublicProject,
  getPublicProjectByDomain,
  getPublicQuestions,
  submitResponse,
} from './public_surveys';
import { generateFollowUp, saveFollowUp } from './follow_up';
import { cleanupExpiredMedia, getMedia, uploadMedia } from './media';
import { listAdminVisibilityRules, listPublicVisibilityRules, replaceAdminVisibilityRules } from './visibility_rules';
import {
  aggregatedResults,
  createReply,
  deleteResponse,
  exportResponses,
  getReplies,
  listResponses,
  responseAnswers,
  responseCount,
  responseTrends,
} from './responses';
import { HttpError, countRows, json, jsonHeaders, logError, optionalIntegerParam, requiredIntegerParam } from './utils';
import { anonymousAccountToJson, replyToJson } from './serializers';
import { requireScope } from './permissions';
import { isPublicFormHtmlRequest, renderPublicForm } from './public_form_renderer';
import { scheduleRuntimeMigrations } from './runtime_migrations';
import { cleanupOldQuotaPeriods } from './usage_quota';
import { checkRateLimit, clientIp } from './rate_limit';

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    scheduleRuntimeMigrations(env, ctx);
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: jsonHeaders });
    }

    try {
      return await route(request, env, ctx);
    } catch (error) {
      if (error instanceof HttpError) {
        return json({ error: error.message, details: error.details }, error.status);
      }
      logError('unhandled_request_error', error, {
        method: request.method,
        path: new URL(request.url).pathname,
      });
      return json({ error: 'Internal server error' }, 500);
    }
  },
  async scheduled(_controller: ScheduledController, env: Env, ctx: ExecutionContext): Promise<void> {
    ctx.waitUntil(
      Promise.all([cleanupExpiredMedia(env), cleanupOldQuotaPeriods(env.DB)])
        .then(() => undefined)
        .catch((error) => {
          logError('scheduled_cleanup_failed', error);
        }),
    );
  },
} satisfies ExportedHandler<Env>;

async function route(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
  const url = new URL(request.url);
  const path = url.pathname.replace(/\/+$/, '') || '/';
  const method = request.method.toUpperCase();
  const parts = path.split('/').filter(Boolean);

  if (env.PUBLIC_WRITE_RATE_LIMITER && isCostlyPublicWrite(parts, method)) {
    await checkRateLimit(env.PUBLIC_WRITE_RATE_LIMITER, `public-write:${clientIp(request)}`);
  }

  if (method === 'GET' && path === '/api/config') {
    return json({
      passwordResetEnabled: false,
      requireEmailVerification: false,
      aiGenerationEnabled: await isAiGenerationConfigured(env),
      turnstileSiteKey: (await isTurnstileConfigured(env)) ? await getTurnstileSiteKey(env) : null,
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

  if (path === '/api/anonymous/replies/latest' && method === 'GET') {
    const anonymous = await requireAnonymous(request, env);
    const responseId = optionalIntegerParam(url.searchParams.get('responseId'), 'responseId', {
      min: 1,
    });
    const statement =
      responseId == null
        ? env.DB.prepare(
            `SELECT MAX(created_at) AS latest_reply_at
           FROM admin_replies
           WHERE anonymous_account_id = ?`,
          ).bind(anonymous.id)
        : env.DB.prepare(
            `SELECT MAX(created_at) AS latest_reply_at
           FROM admin_replies
           WHERE anonymous_account_id = ? AND survey_response_id = ?`,
          ).bind(anonymous.id, responseId);
    const row = await statement.first<{ latest_reply_at: string | null }>();
    return json({ latestReplyAt: row?.latest_reply_at ?? null });
  }

  if (path === '/api/anonymous/replies' && method === 'GET') {
    const anonymous = await requireAnonymous(request, env);
    const responseId = optionalIntegerParam(url.searchParams.get('responseId'), 'responseId', {
      min: 1,
    });
    const statement =
      responseId != null
        ? env.DB.prepare(
            `SELECT * FROM admin_replies
           WHERE anonymous_account_id = ? AND survey_response_id = ?
           ORDER BY created_at DESC`,
          ).bind(anonymous.id, responseId)
        : env.DB.prepare(
            `SELECT * FROM admin_replies
           WHERE anonymous_account_id = ?
           ORDER BY created_at DESC`,
          ).bind(anonymous.id);
    const rows = await statement.all<ReplyRow>();
    return json(rows.results.map(replyToJson));
  }

  if (parts[0] === 'api' && parts[1] === 'projects' && parts[2] && method === 'GET') {
    if (parts[2] === 'domain' && parts.length === 3) {
      return getPublicProjectByDomain(env, url.searchParams.get('host'));
    }
    if (parts.length === 3) {
      return getPublicProject(env, parts[2]);
    }
  }

  if (parts[0] === 'api' && parts[1] === 'surveys' && parts[2] && method === 'GET') {
    if (parts[2] !== 'id') {
      return json({ error: 'Not found' }, 404);
    }
    if (!parts[3]) {
      return json({ error: 'Not found' }, 404);
    }
    if (parts[2] === 'id' && parts[3] && parts[4] === 'questions') {
      return getPublicQuestions(env, requiredIntegerParam(parts[3], 'surveyId', { min: 1 }));
    }
    if (parts[2] === 'id' && parts[3] && parts[4] === 'visibility-rules') {
      return listPublicVisibilityRules(env, requiredIntegerParam(parts[3], 'surveyId', { min: 1 }));
    }
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
    return submitResponse(request, env, requiredIntegerParam(parts[3], 'surveyId', { min: 1 }), anonymous, ctx);
  }

  if (parts[0] === 'api' && parts[1] === 'responses' && parts[2] && parts[3] === 'follow-up') {
    const anonymous = await requireAnonymous(request, env);
    const responseId = requiredIntegerParam(parts[2], 'responseId', { min: 1 });
    if (method === 'POST' && parts[4] === 'generate' && parts.length === 5) {
      return generateFollowUp(request, env, responseId, anonymous);
    }
    if (method === 'PUT' && parts.length === 4) {
      return saveFollowUp(request, env, responseId, anonymous, ctx);
    }
  }

  if (parts[0] === 'api' && parts[1] === 'media' && parts.length === 2) {
    if (method === 'POST') {
      const anonymous = await requireAnonymous(request, env);
      return uploadMedia(request, env, anonymous);
    }
    if (method === 'GET') {
      const key = url.searchParams.get('key');
      if (!key) throw new HttpError(400, 'key is required');
      // Admin session preferred; otherwise allow the owning anonymous token.
      try {
        const admin = await requireAdmin(request, env);
        requireScope(admin, 'response:read');
        return getMedia(env, key, { isAdmin: true });
      } catch (error) {
        if (!(error instanceof HttpError) || (error.status !== 401 && error.status !== 403)) {
          throw error;
        }
        const anonymous = await requireAnonymous(request, env);
        return getMedia(env, key, { anonymousId: anonymous.id });
      }
    }
  }

  if (parts[0] === 'api' && parts[1] === 'questions' && parts[2] && parts[3] === 'choices' && method === 'GET') {
    return getPublicChoices(env, requiredIntegerParam(parts[2], 'questionId', { min: 1 }));
  }

  if (parts[0] === 'api' && parts[1] === 'admin') {
    // Logout only needs a valid session token; do not require fine-grained scopes.
    if (parts[2] === 'auth' && parts[3] === 'session' && method === 'DELETE') {
      return logoutAdmin(request, env);
    }
    const admin = await requireAdmin(request, env);
    return routeAdmin(request, env, admin, parts, url);
  }

  if (isPublicFormHtmlRequest(request, path)) {
    return renderPublicForm(request, env);
  }

  return json({ error: 'Not found' }, 404);
}

function isCostlyPublicWrite(parts: string[], method: string): boolean {
  if (parts[0] !== 'api') return false;
  if (parts[1] === 'media') return method === 'POST';
  if (parts[1] === 'surveys' && parts[2] === 'id' && parts[4] === 'responses') return method === 'POST';
  return parts[1] === 'responses' && parts[3] === 'follow-up' && (method === 'POST' || method === 'PUT');
}

async function routeAdmin(
  request: Request,
  env: Env,
  admin: AdminContext,
  parts: string[],
  url: URL,
): Promise<Response> {
  const method = request.method.toUpperCase();

  if (parts[2] === 'account' && parts[3] === 'password' && parts.length === 4 && method === 'PUT') {
    return changeOwnPassword(request, env, admin);
  }

  if (parts[2] === 'users') {
    requireScope(admin, 'user:manage');
    if (method === 'GET' && parts.length === 3) return listUsers(env);
    if (method === 'POST' && parts.length === 3) return createUser(request, env);
    if (method === 'PUT' && parts[3] && parts[4] === 'role') return updateUserRole(request, env, parts[3]);
    if (method === 'DELETE' && parts[3]) return deleteUser(env, admin, parts[3]);
  }

  if (parts[2] === 'settings') {
    if (method === 'GET' && parts[3] === 'email-configured') {
      return isEmailConfiguredResponse(env);
    }
    requireScope(admin, 'admin');
    if (method === 'GET' && parts.length === 3) return getAdminIntegrationSettings(env);
    if (method === 'PUT' && parts.length === 3) return updateAdminIntegrationSettings(request, env);
  }

  if (parts[2] === 'projects') {
    if (method === 'GET') requireScope(admin, 'survey:read');
    if (method !== 'GET') requireScope(admin, 'survey:write');
    if (method === 'GET' && parts.length === 3) return listProjects(env, url);
    if (method === 'POST' && parts.length === 3) return createProject(request, env, admin);
    const projectId = optionalIntegerParam(parts[3] ?? null, 'projectId', {
      min: 1,
    });
    if (projectId != null) {
      if (method === 'GET' && parts.length === 4) return getAdminProject(env, projectId);
      if (method === 'PUT' && parts.length === 4) return updateProject(request, env, projectId);
      if (method === 'DELETE' && parts.length === 4) return deleteProject(env, projectId);
      if (method === 'GET' && parts[4] === 'surveys') return listSurveys(env, projectId, url);
    }
  }

  if (parts[2] === 'surveys') {
    if (method === 'GET') requireScope(admin, 'survey:read');
    if (method !== 'GET') requireScope(admin, 'survey:write');
    if (method === 'GET' && parts.length === 3) {
      return listSurveys(
        env,
        optionalIntegerParam(url.searchParams.get('projectId'), 'projectId', {
          min: 1,
        }) ?? undefined,
        url,
      );
    }
    if (method === 'POST' && parts.length === 3) return createSurvey(request, env, admin);
    if (method === 'POST' && parts[3] === 'with-questions') {
      return createSurveyWithQuestions(request, env, admin);
    }

    const surveyId = optionalIntegerParam(parts[3] ?? null, 'surveyId', {
      min: 1,
    });
    if (surveyId != null) {
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
        requireScope(admin, 'response:read');
        return responseCount(env, surveyId);
      }
      if (method === 'GET' && parts[4] === 'responses' && parts[5] === 'export') {
        requireScope(admin, 'response:read');
        return exportResponses(env, surveyId, url);
      }
      if (method === 'GET' && parts[4] === 'responses') {
        requireScope(admin, 'response:read');
        return listResponses(env, surveyId, url);
      }
      if (method === 'GET' && parts[4] === 'results') {
        requireScope(admin, 'response:read');
        return aggregatedResults(env, surveyId);
      }
      if (method === 'GET' && parts[4] === 'trends') {
        requireScope(admin, 'response:read');
        return responseTrends(env, surveyId, url);
      }
      if (parts[4] === 'visibility-rules') {
        if (method === 'GET') return listAdminVisibilityRules(env, surveyId);
        if (method === 'PUT') return replaceAdminVisibilityRules(request, env, surveyId);
      }
      if (parts[4] === 'notification-settings') {
        return notificationSettings(request, env, surveyId, parts);
      }
    }
  }

  if (parts[2] === 'questions') {
    if (method === 'GET') requireScope(admin, 'survey:read');
    if (method !== 'GET') requireScope(admin, 'survey:write');
    if (method === 'POST' && parts.length === 3) return createQuestion(request, env);
    const questionId = optionalIntegerParam(parts[3] ?? null, 'questionId', {
      min: 1,
    });
    if (questionId != null) {
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
    if (method === 'GET') requireScope(admin, 'survey:read');
    if (method !== 'GET') requireScope(admin, 'survey:write');
    if (method === 'POST' && parts.length === 3) return createChoice(request, env);
    const choiceId = optionalIntegerParam(parts[3] ?? null, 'choiceId', {
      min: 1,
    });
    if (choiceId != null) {
      if (method === 'GET' && parts.length === 4) return getChoice(env, choiceId);
      if (method === 'PUT' && parts.length === 4) return updateChoice(request, env, choiceId);
      if (method === 'DELETE' && parts.length === 4) return deleteChoice(env, choiceId);
    }
  }

  if (parts[2] === 'responses') {
    const responseId = optionalIntegerParam(parts[3] ?? null, 'responseId', {
      min: 1,
    });
    if (responseId != null) {
      if (method === 'GET') requireScope(admin, 'response:read');
      if (method !== 'GET') requireScope(admin, 'response:write');
      if (method === 'GET' && parts[4] === 'answers') return responseAnswers(env, responseId, url);
      if (method === 'DELETE' && parts.length === 4) return deleteResponse(env, responseId);
      if (method === 'GET' && parts[4] === 'replies') return getReplies(env, responseId);
      if (method === 'POST' && parts[4] === 'replies') {
        return createReply(request, env, admin, responseId);
      }
    }
  }

  if (parts[2] === 'ai' && parts[3] === 'survey-questions') {
    requireScope(admin, 'survey:write');
    return generateSurveyQuestions(request, env);
  }

  if (parts[2] === 'ai' && parts[3] === 'translate-localized-text') {
    requireScope(admin, 'survey:write');
    return translateLocalizedText(request, env);
  }

  return json({ error: 'Not found' }, 404);
}
