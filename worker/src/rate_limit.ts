import { HttpError } from './utils';

type Bucket = {
  count: number;
  resetAt: number;
};

/** Best-effort in-isolate limiter. Prefer Cloudflare WAF rate rules in production. */
const buckets = new Map<string, Bucket>();

export function consumeRateLimit(
  key: string,
  limit: number,
  windowMs: number,
  message = 'Too many requests. Try again later.',
): void {
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
}
