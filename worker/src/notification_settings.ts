import type { Env, NotificationSettingsRow } from './types';
import { boolToInt, json, nowIso, optionalNumber, readJson, requireString, requiredRow } from './utils';
import { notificationToJson } from './serializers';

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
  if (method === 'DELETE') {
    await env.DB.prepare(`DELETE FROM notification_settings WHERE survey_id = ?`)
      .bind(surveyId)
      .run();
    return json({ ok: true });
  }
  return json({ error: 'Not found' }, 404);
}
