import type { Env, NotificationSettingsRow } from './types';
import { boolToInt, HttpError, json, logWarn, nowIso, readJson, requireEmail, requiredBoolean, requiredRow } from './utils';
import { notificationToJson } from './serializers';
import { getIntegrationSettingsRow, isSmtpConfigured, requireSmtpSettings, type RequiredSmtpSettings } from './admin_settings';
import type { EmailMessage } from './smtp';
import { DEFAULT_FORM_CONTENT_LOCALE, localizedTextFor } from './localization';
import type { ProjectRow, ResponseRow, SurveyRow } from './types';
import { mustSurvey } from './admin_records';

export async function notificationSettings(
  request: Request,
  env: Env,
  surveyId: number,
  parts: string[],
): Promise<Response> {
  const method = request.method.toUpperCase();
  if (method === 'GET') {
    const row = await env.DB.prepare(
      `SELECT * FROM notification_settings WHERE survey_id = ?`,
    ).bind(surveyId).first<NotificationSettingsRow>();
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
    ).bind(
      surveyId,
      boolToInt(requiredBoolean(body.enabled, 'enabled')),
      requireEmail(body.recipientEmail, 'recipientEmail'),
      nowIso(),
    ).first<NotificationSettingsRow>();
    return json(notificationToJson(requiredRow(row, 'NotificationSettings')));
  }
  if (method === 'POST' && parts[5] === 'toggle') {
    const body = await readJson(request);
    const row = await env.DB.prepare(
      `UPDATE notification_settings SET enabled = ?, updated_at = ?
       WHERE survey_id = ? RETURNING *`,
    ).bind(boolToInt(requiredBoolean(body.enabled, 'enabled')), nowIso(), surveyId).first<NotificationSettingsRow>();
    if (!row) throw new HttpError(404, 'Notification settings not found');
    return json(notificationToJson(row));
  }
  if (method === 'POST' && parts[5] === 'test') {
    const settings = await requireSmtpSettings(await getIntegrationSettingsRow(env), env);
    const row = await env.DB.prepare(
      `SELECT * FROM notification_settings WHERE survey_id = ?`,
    ).bind(surveyId).first<NotificationSettingsRow>();
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
    await env.DB.prepare(`DELETE FROM notification_settings WHERE survey_id = ?`)
      .bind(surveyId)
      .run();
    return json({ ok: true });
  }
  return json({ error: 'Not found' }, 404);
}

export async function sendResponseNotification(
  env: Env,
  survey: SurveyRow,
  response: ResponseRow,
): Promise<void> {
  const notification = await env.DB.prepare(
    `SELECT * FROM notification_settings WHERE survey_id = ? AND enabled = 1`,
  ).bind(survey.id).first<NotificationSettingsRow>();
  if (!notification) return;

  const integrationSettings = await getIntegrationSettingsRow(env);
  if (!isSmtpConfigured(integrationSettings)) {
    logWarn('smtp_settings_not_configured', {
      surveyId: survey.id,
      responseId: response.id,
    });
    return;
  }

  const settings = await requireSmtpSettings(integrationSettings, env);
  const project = await env.DB.prepare(
    `SELECT * FROM projects WHERE id = ?`,
  ).bind(survey.project_id).first<ProjectRow>();
  const surveyTitle = localizedTextFor(
    survey.title_translations,
    project?.default_locale ?? DEFAULT_FORM_CONTENT_LOCALE,
  );
  await sendEmailMessage(settings, {
    to: notification.recipient_email,
    subject: `New response: ${surveyTitle}`,
    text: [
      'A new response was submitted.',
      '',
      `Survey: ${surveyTitle}`,
      `Response ID: ${response.id}`,
      `Submitted at: ${response.submitted_at}`,
    ].join('\n'),
  });
}

async function sendEmailMessage(settings: RequiredSmtpSettings, message: EmailMessage): Promise<void> {
  const { sendEmail } = await import('./smtp');
  await sendEmail(settings, message);
}
