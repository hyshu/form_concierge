import type { AdminContext, Env, ReplyRow } from './types';
import { bootstrapAdmin, createAnonymousAccount, loginAdmin, requireAdmin, requireAnonymous } from './auth';
import { createUser, deleteUser, listUsers, toggleUserBlocked } from './admin_users';
import {
  createChoice,
  createQuestion,
  createSurvey,
  createSurveyWithQuestions,
  deleteChoice,
  deleteQuestion,
  deleteSurvey,
  getAdminQuestions,
  getAdminSurvey,
  getChoice,
  getChoices,
  getQuestion,
  listSurveys,
  notificationSettings,
  reorderChoices,
  reorderQuestions,
  updateChoice,
  updateQuestion,
  updateSurvey,
  updateSurveyStatus,
} from './admin_surveys';
import { getPublicChoices, getPublicQuestions, getPublicSurvey, submitResponse } from './public_surveys';
import {
  aggregatedResults,
  createReply,
  deleteResponse,
  getReplies,
  listResponses,
  responseAnswers,
  responseCount,
  responseTrends,
} from './responses';
import { HttpError, countRows, json, jsonHeaders } from './utils';
import { anonymousAccountToJson, replyToJson } from './serializers';

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
