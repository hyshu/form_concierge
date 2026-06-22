import type { AdminContext, AdminRow, AnonymousContext, AnswerRow, ChoiceRow, NotificationSettingsRow, QuestionRow, ReplyRow, ResponseRow, SurveyRow, VisibilityRuleRow } from './types';
import { roleFromScopes } from './permissions';
import { compactObject } from './utils';
import { parseLocalizedText } from './localization';

export function surveyToJson(row: SurveyRow) {
  return {
    id: row.id,
    slug: row.slug,
    customDomain: row.custom_domain,
    defaultLocale: row.default_locale,
    supportedLocales: parseJsonArray(row.supported_locales),
    titleTranslations: parseLocalizedText(row.title_translations),
    descriptionTranslations: parseLocalizedText(row.description_translations),
    status: row.status,
    authRequirement: row.auth_requirement,
    createdByUserId: row.created_by_admin_id,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    startsAt: row.starts_at,
    endsAt: row.ends_at,
  };
}

export function questionToJson(row: QuestionRow) {
  return {
    id: row.id,
    surveyId: row.survey_id,
    textTranslations: parseLocalizedText(row.text_translations),
    type: row.type,
    orderIndex: row.order_index,
    isRequired: row.is_required === 1,
    placeholderTranslations: parseLocalizedText(row.placeholder_translations),
    minLength: row.min_length,
    maxLength: row.max_length,
    minSelected: row.min_selected,
    maxSelected: row.max_selected,
    visibilityConditionMode: row.visibility_condition_mode,
    isDeleted: row.is_deleted === 1,
  };
}

export function visibilityRuleToJson(row: VisibilityRuleRow) {
  return {
    id: row.id,
    surveyId: row.survey_id,
    targetQuestionId: row.target_question_id,
    sourceQuestionId: row.source_question_id,
    operator: row.operator,
    value: parseJsonValue(row.value_json),
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export function choiceToJson(row: ChoiceRow) {
  return {
    id: row.id,
    questionId: row.question_id,
    textTranslations: parseLocalizedText(row.text_translations),
    orderIndex: row.order_index,
    value: row.value,
  };
}

export function responseToJson(row: ResponseRow) {
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

export function metadataToJson(value: string | null) {
  if (!value) return null;
  const metadata = parseJsonObject(value);
  return Object.keys(metadata).length === 0 ? null : metadata;
}

export function deviceInfoToJson(row: ResponseRow) {
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

export function answerToJson(row: AnswerRow) {
  return {
    id: row.id,
    surveyResponseId: row.survey_response_id,
    questionId: row.question_id,
    textValue: row.text_value,
    selectedChoiceIds: parseChoiceIds(row.selected_choice_ids),
  };
}

export function replyToJson(row: ReplyRow) {
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

export function notificationToJson(row: NotificationSettingsRow) {
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

export function adminUserToJson(row: AdminRow) {
  return adminContextToJson(adminRowToContext(row));
}

export function adminContextToJson(user: AdminContext) {
  return {
    id: user.id,
    email: user.email,
    scopeNames: user.scopeNames,
    role: roleFromScopes(user.scopeNames),
    blocked: user.blocked,
    created: user.created,
  };
}

export function adminRowToContext(row: AdminRow): AdminContext {
  return {
    id: row.id,
    email: row.email,
    scopeNames: parseJsonArray(row.scope_names),
    blocked: row.blocked === 1,
    created: row.created_at,
  };
}

export function anonymousAccountToJson(account: AnonymousContext) {
  return {
    id: account.id,
    displayName: account.displayName,
    createdAt: account.createdAt,
    lastSeenAt: account.lastSeenAt,
  };
}

export function parseChoiceIds(value: string | null): number[] {
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

function parseJsonValue(value: string | null): unknown {
  if (!value) return null;
  try {
    return JSON.parse(value);
  } catch {
    return null;
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
