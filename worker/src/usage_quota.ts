import type { Env } from './types';
import { HttpError } from './utils';

export const DEFAULT_QUOTA_LIMITS = {
  responsesPerAccountDay: 100,
  responsesPerIpDay: 500,
  responsesPerSurveyDay: 10_000,
  uploadBytesPerAccountDay: 100 * 1024 * 1024,
  storedBytesPerAccount: 250 * 1024 * 1024,
  aiGenerationsPerAccountDay: 20,
  aiGenerationsPerSurveyDay: 500,
  emailsPerSurveyDay: 1_000,
} as const;

type QuotaReservation = {
  subject: string;
  resource: string;
  period: string;
  amount: number;
  limit: number;
  message: string;
};

export async function reserveQuota(db: D1Database, reservation: QuotaReservation): Promise<void> {
  if (!Number.isSafeInteger(reservation.amount) || reservation.amount <= 0) {
    throw new Error('Quota amount must be a positive safe integer');
  }
  if (reservation.amount > reservation.limit) {
    throw new HttpError(429, reservation.message);
  }
  const row = await db
    .prepare(
      `INSERT INTO usage_quotas (subject, resource, period, used, updated_at)
     VALUES (?, ?, ?, ?, strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
     ON CONFLICT(subject, resource, period) DO UPDATE SET
       used = used + excluded.used,
       updated_at = excluded.updated_at
     WHERE used + excluded.used <= ?
     RETURNING used`,
    )
    .bind(reservation.subject, reservation.resource, reservation.period, reservation.amount, reservation.limit)
    .first<{ used: number }>();
  if (!row) throw new HttpError(429, reservation.message);
}

export async function reserveQuotas(db: D1Database, reservations: readonly QuotaReservation[]): Promise<void> {
  const reserved: QuotaReservation[] = [];
  try {
    for (const reservation of reservations) {
      await reserveQuota(db, reservation);
      reserved.push(reservation);
    }
  } catch (error) {
    await Promise.all(reserved.map((reservation) => refundQuota(db, reservation)));
    throw error;
  }
}

export async function refundQuota(
  db: D1Database,
  reservation: Pick<QuotaReservation, 'subject' | 'resource' | 'period' | 'amount'>,
): Promise<void> {
  await db
    .prepare(
      `UPDATE usage_quotas
     SET used = MAX(0, used - ?), updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
     WHERE subject = ? AND resource = ? AND period = ?`,
    )
    .bind(reservation.amount, reservation.subject, reservation.resource, reservation.period)
    .run();
}

export function utcDay(date = new Date()): string {
  return date.toISOString().slice(0, 10);
}

export function quotaLimit(
  env: Env,
  key: keyof Pick<
    Env,
    | 'QUOTA_RESPONSES_PER_ACCOUNT_DAY'
    | 'QUOTA_RESPONSES_PER_IP_DAY'
    | 'QUOTA_RESPONSES_PER_SURVEY_DAY'
    | 'QUOTA_UPLOAD_BYTES_PER_ACCOUNT_DAY'
    | 'QUOTA_STORED_BYTES_PER_ACCOUNT'
    | 'QUOTA_AI_GENERATIONS_PER_ACCOUNT_DAY'
    | 'QUOTA_AI_GENERATIONS_PER_SURVEY_DAY'
    | 'QUOTA_EMAILS_PER_SURVEY_DAY'
  >,
  fallback: number,
): number {
  const raw = env[key];
  if (raw == null || raw.trim() === '') return fallback;
  const parsed = Number(raw);
  return Number.isSafeInteger(parsed) && parsed > 0 ? parsed : fallback;
}

export async function ipQuotaSubject(ip: string): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(ip));
  return `ip:${Array.from(new Uint8Array(digest), (byte) => byte.toString(16).padStart(2, '0')).join('')}`;
}

export async function cleanupOldQuotaPeriods(db: D1Database): Promise<void> {
  const cutoff = new Date(Date.now() - 8 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
  await db.prepare(`DELETE FROM usage_quotas WHERE period != 'all' AND period < ?`).bind(cutoff).run();
}
