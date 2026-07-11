import { HttpError } from './utils';

export async function verifyTurnstileToken(
  token: string,
  secretKey: string,
  ip: string | null,
): Promise<void> {
  const body = new URLSearchParams({
    secret: secretKey,
    response: token,
  });
  if (ip) body.set('remoteip', ip);
  const res = await fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify', {
    method: 'POST',
    body,
  });
  if (!res.ok) throw new HttpError(502, 'CAPTCHA verification service unavailable');
  const result = await res.json<{ success: boolean }>();
  if (!result.success) throw new HttpError(403, 'CAPTCHA verification failed');
}
