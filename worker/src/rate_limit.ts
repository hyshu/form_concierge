import { HttpError } from './utils';

type Bucket = {
  count: number;
  resetAt: number;
};

/** Best-effort in-isolate limiter; swept periodically to prevent unbounded growth. */
const buckets = new Map<string, Bucket>();
const SWEEP_INTERVAL = 128;
let callsSinceSweep = 0;

function sweepExpired(): void {
  const now = Date.now();
  for (const [key, entry] of buckets) {
    if (entry.resetAt <= now) buckets.delete(key);
  }
}

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

export async function checkRateLimit(
  limiter: RateLimit,
  key: string,
  message = 'Too many requests. Try again later.',
): Promise<void> {
  const { success } = await limiter.limit({ key });
  if (!success) throw new HttpError(429, message);
}

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

/** Test helper: clear buckets between unit tests. */
export function resetRateLimitsForTests(): void {
  buckets.clear();
  callsSinceSweep = 0;
}
