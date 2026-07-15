import type { Env, NotificationSettingsRow } from './types';
import {
  boolToInt,
  HttpError,
  json,
  logError,
  logWarn,
  nowIso,
  readJson,
  requireEmail,
  requiredBoolean,
  requiredRow,
} from './utils';
import { notificationToJson } from './serializers';
import {
  getIntegrationSettingsRow,
  isSmtpConfigured,
  requireSmtpSettings,
  type RequiredSmtpSettings,
} from './admin_settings';
import type { EmailMessage } from './smtp';
import { DEFAULT_FORM_CONTENT_LOCALE, localizedTextFor } from './localization';
import type { ProjectRow, ResponseRow, SurveyRow } from './types';
import { mustSurvey } from './admin_records';
import { buildAnswersSummary, formatCompletedFollowUpSummary } from './follow_up';
import { DEFAULT_QUOTA_LIMITS, quotaLimit, reserveQuota, utcDay } from './usage_quota';

export async function notificationSettings(
  request: Request,
  env: Env,
  surveyId: number,
  parts: string[],
): Promise<Response> {
  const method = request.method.toUpperCase();
  if (method === 'GET') {
    const row = await env.DB.prepare(`SELECT * FROM notification_settings WHERE survey_id = ?`)
      .bind(surveyId)
      .first<NotificationSettingsRow>();
    return json(row ? notificationToJson(row) : null);
  }
  if (method === 'PUT') {
    await mustSurvey(env.DB, surveyId);
    const body = await readJson(request);
    const row = await env.DB.prepare(
      `INSERT INTO notification_settings
         (survey_id, enabled, recipient_email, updated_at)
       VALUES (?, ?, ?, ?)
       ON CONFLICT(survey_id) DO UPDATE SET
         enabled = excluded.enabled,
         recipient_email = excluded.recipient_email,
         updated_at = excluded.updated_at
       RETURNING *`,
    )
      .bind(
        surveyId,
        boolToInt(requiredBoolean(body.enabled, 'enabled')),
        requireEmail(body.recipientEmail, 'recipientEmail'),
        nowIso(),
      )
      .first<NotificationSettingsRow>();
    return json(notificationToJson(requiredRow(row, 'NotificationSettings')));
  }
  if (method === 'POST' && parts[5] === 'toggle') {
    const body = await readJson(request);
    const row = await env.DB.prepare(
      `UPDATE notification_settings SET enabled = ?, updated_at = ?
       WHERE survey_id = ? RETURNING *`,
    )
      .bind(boolToInt(requiredBoolean(body.enabled, 'enabled')), nowIso(), surveyId)
      .first<NotificationSettingsRow>();
    if (!row) throw new HttpError(404, 'Notification settings not found');
    return json(notificationToJson(row));
  }
  if (method === 'POST' && parts[5] === 'test') {
    const settings = await requireSmtpSettings(await getIntegrationSettingsRow(env), env);
    const row = await env.DB.prepare(`SELECT * FROM notification_settings WHERE survey_id = ?`)
      .bind(surveyId)
      .first<NotificationSettingsRow>();
    if (!row) throw new HttpError(404, 'Notification settings not found');
    await sendEmailMessage(settings, {
      to: row.recipient_email,
      subject: 'Form Concierge test notification',
      text: [
        'This is a test notification from Form Concierge.',
        '',
        `Survey ID: ${surveyId}`,
        `Sent at: ${nowIso()}`,
      ].join('\n'),
    });
    return json(notificationToJson(row));
  }
  if (method === 'DELETE') {
    await env.DB.prepare(`DELETE FROM notification_settings WHERE survey_id = ?`).bind(surveyId).run();
    return json({ ok: true });
  }
  return json({ error: 'Not found' }, 404);
}

export type ResponseNotificationKind = 'submission' | 'follow_up';

export type ResponseNotificationContent = {
  subject: string;
  text: string;
};

/** Pure email subject/body builder (unit-tested). */
export function buildResponseNotificationContent(input: {
  kind: ResponseNotificationKind;
  projectName: string;
  surveyTitle: string;
  responseId: number;
  submittedAt: string;
  answersSummary: string;
  followUpSummary: string | null;
}): ResponseNotificationContent {
  const subjectPrefix = input.kind === 'follow_up' ? 'Follow-up completed' : 'New response';
  const intro =
    input.kind === 'follow_up' ? 'A respondent completed follow-up questions.' : 'A new response was submitted.';

  const bodyLines = [
    intro,
    '',
    `Project: ${input.projectName}`,
    `Survey: ${input.surveyTitle}`,
    `Response ID: ${input.responseId}`,
    `Submitted at: ${input.submittedAt}`,
    '',
    'Answers:',
    input.answersSummary,
  ];
  if (input.followUpSummary) {
    bodyLines.push('', 'Follow-up:', input.followUpSummary);
  }

  return {
    subject: `${subjectPrefix}: ${input.projectName} / ${input.surveyTitle}`,
    text: bodyLines.join('\n'),
  };
}

/**
 * Email admins about a new response (or completed follow-up).
 * Includes project name, survey title, main answers, and follow-up when present.
 */
export async function sendResponseNotification(
  env: Env,
  survey: SurveyRow,
  response: ResponseRow,
  options: { kind?: ResponseNotificationKind } = {},
): Promise<void> {
  const kind = options.kind ?? 'submission';
  const notification = await env.DB.prepare(`SELECT * FROM notification_settings WHERE survey_id = ? AND enabled = 1`)
    .bind(survey.id)
    .first<NotificationSettingsRow>();
  if (!notification) return;

  const integrationSettings = await getIntegrationSettingsRow(env);
  if (!isSmtpConfigured(integrationSettings)) {
    logWarn('smtp_settings_not_configured', {
      surveyId: survey.id,
      responseId: response.id,
    });
    return;
  }

  await reserveQuota(env.DB, {
    subject: `survey:${survey.id}`,
    resource: 'emails',
    period: utcDay(),
    amount: 1,
    limit: quotaLimit(env, 'QUOTA_EMAILS_PER_SURVEY_DAY', DEFAULT_QUOTA_LIMITS.emailsPerSurveyDay),
    message: 'Survey daily email limit reached.',
  });

  const settings = await requireSmtpSettings(integrationSettings, env);
  const project = await env.DB.prepare(`SELECT * FROM projects WHERE id = ?`)
    .bind(survey.project_id)
    .first<ProjectRow>();
  const locale = project?.default_locale ?? DEFAULT_FORM_CONTENT_LOCALE;
  const projectName = project?.name?.trim() || `Project #${survey.project_id}`;
  const surveyTitle = localizedTextFor(survey.title_translations, locale);

  let answersSummary = '(no answers)';
  try {
    answersSummary = await buildAnswersSummary(env, survey, response.id, locale);
  } catch (error) {
    logError('response_notification_answers_failed', error, {
      surveyId: survey.id,
      responseId: response.id,
    });
  }

  const followUpSummary = formatCompletedFollowUpSummary(response.follow_up, {
    truncateText: false,
  });

  const content = buildResponseNotificationContent({
    kind,
    projectName,
    surveyTitle,
    responseId: response.id,
    submittedAt: response.submitted_at,
    answersSummary,
    followUpSummary,
  });

  await sendEmailMessage(settings, {
    to: notification.recipient_email,
    subject: content.subject,
    text: content.text,
  });
}

async function sendEmailMessage(settings: RequiredSmtpSettings, message: EmailMessage): Promise<void> {
  const { sendEmail } = await import('./smtp');
  await sendEmail(settings, message);
}
