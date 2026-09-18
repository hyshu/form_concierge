import { HttpError } from './utils';

type Bucket = {
  count: number;
  resetAt: number;
};

/** Best-effort isolate-local limiter, swept periodically to bound memory use. */
const buckets = new Map<string, Bucket>();
const SWEEP_INTERVAL = 128;
let callsSinceSweep = 0;

function sweepExpired(): void {
  const now = Date.now();
  for (const [key, entry] of buckets) {
    if (entry.resetAt <= now) buckets.delete(key);
  }
}

/**
 * Consumes one request from an isolate-local time window and throws HTTP 429 when exceeded.
 */
export function consumeRateLimit(
  key: string,
  limit: number,
  windowMs: number,
  message = 'Too many requests. Try again later.',
): void {
  if (++callsSinceSweep >= SWEEP_INTERVAL) {
    callsSinceSweep = 0;
    sweepExpired();
  }
  const now = Date.now();
  let entry = buckets.get(key);
  if (!entry || entry.resetAt <= now) {
    entry = { count: 0, resetAt: now + windowMs };
    buckets.set(key, entry);
  }
  entry.count += 1;
  if (entry.count > limit) {
    throw new HttpError(429, message);
  }
}

/**
 * Checks a Cloudflare rate limit binding and throws HTTP 429 when the request is denied.
 */
export async function checkRateLimit(
  limiter: RateLimit,
  key: string,
  message = 'Too many requests. Try again later.',
): Promise<void> {
  const { success } = await limiter.limit({ key });
  if (!success) throw new HttpError(429, message);
}

/**
 * Reads the connecting IP from request headers, falling back to an unknown marker.
 */
export function clientIp(request: Request): string {
  const cf = request.headers.get('cf-connecting-ip');
  if (cf && cf.trim().length > 0) return cf.trim();
  const forwarded = request.headers.get('x-forwarded-for');
  if (forwarded) {
    const first = forwarded.split(',')[0]?.trim();
    if (first) return first;
  }
  return 'unknown';
}

/** Clears rate limit buckets between unit tests. */
export function resetRateLimitsForTests(): void {
  buckets.clear();
  callsSinceSweep = 0;
}
