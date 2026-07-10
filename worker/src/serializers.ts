import type { AdminContext, AdminRow, AnonymousContext, AnswerRow, ChoiceRow, NotificationSettingsRow, ProjectRow, QuestionRow, ReplyRow, ResponseRow, SurveyRow, VisibilityRuleRow } from './types';
import { roleFromScopes } from './permissions';
import { HttpError, compactObject } from './utils';
import { parseLocalizedText } from './localization';
import { parseStoredFileKeys } from './media';

export function projectToJson(row: ProjectRow) {
  return {
    id: row.id,
    slug: row.slug,
    customDomain: row.custom_domain,
    defaultLocale: row.default_locale,
    supportedLocales: parseJsonArray(row.supported_locales, 'supportedLocales'),
    name: row.name,
    createdByUserId: row.created_by_admin_id,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export function surveyToJson(row: SurveyRow) {
  return {
    id: row.id,
    projectId: row.project_id,
    slug: row.slug,
    titleTranslations: parseLocalizedText(row.title_translations),
    descriptionTranslations: parseLocalizedText(row.description_translations),
    status: row.status,
    webEnabled: row.web_enabled === 1,
    followUpEnabled: row.follow_up_enabled === 1,
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
    followUp: followUpToJson(row.follow_up),
  };
}

export function followUpToJson(value: string | null): Record<string, unknown> | null {
  if (!value) return null;
  const decoded = parseJsonObject(value, 'followUp');
  return Object.keys(decoded).length === 0 ? null : decoded;
}

export function metadataToJson(value: string | null) {
  if (!value) return null;
  const metadata = parseJsonObject(value, 'metadata');
  return Object.keys(metadata).length === 0 ? null : metadata;
}

export function deviceInfoToJson(row: ResponseRow) {
  const raw = parseJsonObject(row.device_info, 'deviceInfo');
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
  const fileKeys = parseStoredFileKeys(row.text_value);
  return {
    id: row.id,
    surveyResponseId: row.survey_response_id,
    questionId: row.question_id,
    textValue: fileKeys ? null : row.text_value,
    selectedChoiceIds: parseChoiceIds(row.selected_choice_ids),
    fileKeys,
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
    updatedAt: row.updated_at,
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
    created: user.created,
  };
}

export function adminRowToContext(row: AdminRow): AdminContext {
  return {
    id: row.id,
    email: row.email,
    scopeNames: parseJsonArray(row.scope_names, 'scopeNames'),
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
  return parseJsonIntegerArray(value, 'selectedChoiceIds');
}

function parseJsonObject(value: string | null, field: string): Record<string, unknown> {
  if (!value) return {};
  const decoded = parseStoredJson(value, field);
  if (!decoded || typeof decoded !== 'object' || Array.isArray(decoded)) {
    throw new HttpError(500, `${field} must be an object`);
  }
  return decoded as Record<string, unknown>;
}

function parseJsonValue(value: string | null): unknown {
  if (!value) return null;
  return parseStoredJson(value, 'visibilityRule.value');
}

function parseJsonArray(value: string, field: string): string[] {
  const decoded = parseStoredJson(value, field);
  if (!Array.isArray(decoded)) throw new HttpError(500, `${field} must be an array`);
  return decoded.map((item, index) => {
    if (typeof item !== 'string') {
      throw new HttpError(500, `${field}[${index}] must be a string`);
    }
    return item;
  });
}

function parseJsonIntegerArray(value: string, field: string): number[] {
  const decoded = parseStoredJson(value, field);
  if (!Array.isArray(decoded)) throw new HttpError(500, `${field} must be an array`);
  return decoded.map((item, index) => {
    if (!Number.isInteger(item) || !Number.isSafeInteger(item)) {
      throw new HttpError(500, `${field}[${index}] must be a safe integer`);
    }
    return item;
  });
}

function parseStoredJson(value: string, field: string): unknown {
  try {
    return JSON.parse(value);
  } catch {
    throw new HttpError(500, `Invalid stored JSON: ${field}`);
  }
}
