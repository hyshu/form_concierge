import type { AnonymousContext, Env } from './types';
import {
  HttpError,
  MEDIA_ALLOWED_CONTENT_TYPES,
  MEDIA_MAX_BYTES,
  json,
  jsonHeaders,
} from './utils';

const KEY_PATTERN = /^uploads\/[a-zA-Z0-9_-]+\/[a-zA-Z0-9-]+\.(jpe?g|png|webp|gif)$/i;

export type MediaObjectMeta = {
  key: string;
  contentType: string;
  size: number;
};

const IMAGE_SIGNATURES: ReadonlyArray<{ type: string; bytes: number[] }> = [
  { type: 'image/jpeg', bytes: [0xff, 0xd8, 0xff] },
  { type: 'image/png', bytes: [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a] },
  { type: 'image/webp', bytes: [0x52, 0x49, 0x46, 0x46] }, // "RIFF"; WEBP at offset 8 checked below
  { type: 'image/gif', bytes: [0x47, 0x49, 0x46, 0x38] },  // "GIF8"
];

function matchesSignature(header: Uint8Array, contentType: string): boolean {
  for (const sig of IMAGE_SIGNATURES) {
    if (sig.type !== contentType) continue;
    if (header.length < sig.bytes.length) return false;
    const prefixMatch = sig.bytes.every((b, i) => header[i] === b);
    if (!prefixMatch) return false;
    if (contentType === 'image/webp') {
      if (header.length < 12) return false;
      return header[8] === 0x57 && header[9] === 0x45 && header[10] === 0x42 && header[11] === 0x50;
    }
    return true;
  }
  return false;
}

async function readBodyWithLimit(body: ReadableStream<Uint8Array>, limit: number): Promise<Uint8Array> {
  const reader = body.getReader();
  const chunks: Uint8Array[] = [];
  let total = 0;
  try {
    for (;;) {
      const { done, value } = await reader.read();
      if (done) break;
      total += value.byteLength;
      if (total > limit) throw new HttpError(400, `Image must be ${limit} bytes or smaller`);
      chunks.push(value);
    }
  } finally {
    reader.releaseLock();
  }
  const result = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    result.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return result;
}

/** Upload a single image for an anonymous respondent. */
export async function uploadMedia(
  request: Request,
  env: Env,
  anonymous: AnonymousContext,
): Promise<Response> {
  const contentType = normalizeContentType(request.headers.get('content-type'));
  if (!MEDIA_ALLOWED_CONTENT_TYPES.has(contentType)) {
    throw new HttpError(400, 'Unsupported image type. Use JPEG, PNG, WebP, or GIF');
  }

  const claimedLength = Number(request.headers.get('content-length') ?? '');
  if (claimedLength > MEDIA_MAX_BYTES) {
    throw new HttpError(400, `Image must be ${MEDIA_MAX_BYTES} bytes or smaller`);
  }

  if (!request.body) throw new HttpError(400, 'Empty image body');
  const bytes = await readBodyWithLimit(request.body, MEDIA_MAX_BYTES);
  if (bytes.byteLength === 0) throw new HttpError(400, 'Empty image body');

  if (!matchesSignature(bytes, contentType)) {
    throw new HttpError(400, 'File content does not match declared image type');
  }

  const key = buildUploadKey(anonymous.id, contentType);
  await env.MEDIA_BUCKET.put(key, bytes, {
    httpMetadata: { contentType },
    customMetadata: {
      anonymousAccountId: anonymous.id,
      uploadedAt: new Date().toISOString(),
    },
  });

  return json({
    key,
    contentType,
    size: bytes.byteLength,
  } satisfies MediaObjectMeta, 201);
}

/** Fetch image bytes. Anonymous may only read their own uploads; admins may read any. */
export async function getMedia(
  env: Env,
  key: string,
  access: { anonymousId?: string; isAdmin?: boolean },
): Promise<Response> {
  assertValidMediaKey(key);
  if (!access.isAdmin) {
    if (!access.anonymousId) throw new HttpError(401, 'Unauthorized');
    if (!key.startsWith(`uploads/${access.anonymousId}/`)) {
      throw new HttpError(403, 'Forbidden');
    }
  }

  const object = await env.MEDIA_BUCKET.get(key);
  if (!object) throw new HttpError(404, 'Media not found');

  const contentType = object.httpMetadata?.contentType ?? 'application/octet-stream';
  const headers = new Headers({
    'content-type': contentType,
    'cache-control': 'private, max-age=3600',
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET,POST,OPTIONS',
    'access-control-allow-headers': 'content-type,authorization',
  });
  if (object.size != null) headers.set('content-length', String(object.size));

  return new Response(object.body, { status: 200, headers });
}

export function assertValidMediaKey(key: string): void {
  if (!KEY_PATTERN.test(key)) {
    throw new HttpError(400, 'Invalid media key');
  }
}

export function assertOwnedMediaKeys(
  keys: readonly string[],
  anonymousAccountId: string,
): void {
  const prefix = `uploads/${anonymousAccountId}/`;
  for (const key of keys) {
    assertValidMediaKey(key);
    if (!key.startsWith(prefix)) {
      throw new HttpError(400, 'Media key does not belong to this account');
    }
  }
}

export async function assertMediaObjectsExist(
  env: Env,
  keys: readonly string[],
): Promise<void> {
  for (const key of keys) {
    const head = await env.MEDIA_BUCKET.head(key);
    if (!head) throw new HttpError(400, `Media not found: ${key}`);
  }
}

export function encodeFileKeysForStorage(fileKeys: readonly string[]): string {
  return JSON.stringify({ fileKeys: [...fileKeys] });
}

export function parseStoredFileKeys(textValue: string | null): string[] | null {
  if (!textValue) return null;
  try {
    const decoded = JSON.parse(textValue) as unknown;
    if (!decoded || typeof decoded !== 'object' || Array.isArray(decoded)) return null;
    const fileKeys = (decoded as { fileKeys?: unknown }).fileKeys;
    if (!Array.isArray(fileKeys)) return null;
    if (!fileKeys.every((item) => typeof item === 'string')) return null;
    return fileKeys as string[];
  } catch {
    return null;
  }
}

function buildUploadKey(anonymousAccountId: string, contentType: string): string {
  const ext = extensionForContentType(contentType);
  const id = crypto.randomUUID();
  return `uploads/${anonymousAccountId}/${id}.${ext}`;
}

function extensionForContentType(contentType: string): string {
  switch (contentType) {
    case 'image/jpeg':
      return 'jpg';
    case 'image/png':
      return 'png';
    case 'image/webp':
      return 'webp';
    case 'image/gif':
      return 'gif';
    default:
      return 'bin';
  }
}

function normalizeContentType(value: string | null): string {
  if (!value) throw new HttpError(400, 'content-type is required');
  return value.split(';')[0]?.trim().toLowerCase() ?? '';
}

/** Keep media CORS aligned with JSON endpoints for browser admin previews. */
export function mediaOptionsResponse(): Response {
  return new Response(null, { status: 204, headers: jsonHeaders });
}
