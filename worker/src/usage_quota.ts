import type { Env } from './types';
import { HttpError } from './utils';

/**
 * Fallback usage limits applied when deployment overrides are absent or invalid.
 */
export const DEFAULT_QUOTA_LIMITS = {
  /**
   * The fallback maximum submissions per anonymous account per day.
   */
  responsesPerAccountDay: 100,
  /**
   * The fallback maximum submissions per client IP address per day.
   */
  responsesPerIpDay: 500,
  /**
   * The fallback maximum submissions per survey per day.
   */
  responsesPerSurveyDay: 10_000,
  /**
   * The fallback maximum uploaded bytes per anonymous account per day.
   */
  uploadBytesPerAccountDay: 100 * 1024 * 1024,
  /**
   * The fallback maximum retained media bytes per anonymous account.
   */
  storedBytesPerAccount: 250 * 1024 * 1024,
  /**
   * The fallback maximum AI generations per anonymous account per day.
   */
  aiGenerationsPerAccountDay: 20,
  /**
   * The fallback maximum AI generations per survey per day.
   */
  aiGenerationsPerSurveyDay: 500,
  /**
   * The fallback maximum notification emails per survey per day.
   */
  emailsPerSurveyDay: 1_000,
} as const;

/**
 * An amount of one resource reserved against a subject's usage limit.
 */
type QuotaReservation = {
  /**
   * The account, IP, or survey identifier whose usage is counted.
   */
  subject: string;
  /**
   * The resource counter to update.
   */
  resource: string;
  /**
   * The calendar day or lifetime period used to group usage.
   */
  period: string;
  /**
   * The positive number of resource units to reserve or refund.
   */
  amount: number;
  /**
   * The maximum allowed usage for the subject and period.
   */
  limit: number;
  /**
   * The public error message returned when the usage limit is exceeded.
   */
  message: string;
};

/**
 * Atomically reserves usage and throws HTTP 429 if the reservation would exceed its limit.
 */
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

/**
 * Reserves several usage amounts and refunds completed reservations if a later reservation fails.
 */
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

/**
 * Returns reserved usage without reducing the stored counter below zero.
 */
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

/**
 * Returns the UTC calendar date as a year, month, and day string.
 */
export function utcDay(date = new Date()): string {
  return date.toISOString().slice(0, 10);
}

/**
 * Reads a positive integer quota override or returns the supplied fallback.
 */
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

/**
 * Hashes an IP address into the identifier used for quota accounting.
 */
export async function ipQuotaSubject(ip: string): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(ip));
  return `ip:${Array.from(new Uint8Array(digest), (byte) => byte.toString(16).padStart(2, '0')).join('')}`;
}

/**
 * Removes dated quota periods older than the retention window while retaining lifetime counters.
 */
export async function cleanupOldQuotaPeriods(db: D1Database): Promise<void> {
  const cutoff = new Date(Date.now() - 8 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
  await db.prepare(`DELETE FROM usage_quotas WHERE period != 'all' AND period < ?`).bind(cutoff).run();
}
