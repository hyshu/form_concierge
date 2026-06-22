import type { Env, NotificationSettingsRow } from './types';
import { boolToInt, json, nowIso, readJson, requireString, requiredRow } from './utils';
import { notificationToJson } from './serializers';
import { getIntegrationSettingsRow, isSmtpConfigured, requireSmtpSettings } from './admin_settings';
import { sendEmail } from './smtp';
import { DEFAULT_FORM_CONTENT_LOCALE, localizedTextFor } from './localization';
import type { ResponseRow, SurveyRow } from './types';

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
      boolToInt(body.enabled),
      requireString(body.recipientEmail, 'recipientEmail'),
      nowIso(),
    ).first<NotificationSettingsRow>();
    return json(notificationToJson(requiredRow(row, 'NotificationSettings')));
  }
  if (method === 'POST' && parts[5] === 'toggle') {
    const body = await readJson(request);
    const row = await env.DB.prepare(
      `UPDATE notification_settings SET enabled = ?, updated_at = ?
       WHERE survey_id = ? RETURNING *`,
    ).bind(boolToInt(body.enabled), nowIso(), surveyId).first<NotificationSettingsRow>();
    return json(notificationToJson(requiredRow(row, 'NotificationSettings')));
  }
  if (method === 'POST' && parts[5] === 'test') {
    const settings = requireSmtpSettings(await getIntegrationSettingsRow(env));
    const row = await env.DB.prepare(
      `SELECT * FROM notification_settings WHERE survey_id = ?`,
    ).bind(surveyId).first<NotificationSettingsRow>();
    const notification = requiredRow(row, 'NotificationSettings');
    await sendEmail(settings, {
      to: notification.recipient_email,
      subject: 'Form Concierge test notification',
      text: [
        'This is a test notification from Form Concierge.',
        '',
        `Survey ID: ${surveyId}`,
        `Sent at: ${nowIso()}`,
      ].join('\n'),
    });
    return json(notificationToJson(notification));
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
    console.error('SMTP settings are not configured');
    return;
  }

  const settings = requireSmtpSettings(integrationSettings);
  const surveyTitle = localizedTextFor(
    survey.title_translations,
    survey.default_locale || DEFAULT_FORM_CONTENT_LOCALE,
  );
  await sendEmail(settings, {
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
