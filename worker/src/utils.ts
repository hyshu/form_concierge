import type { AnswerInput } from './types';

/**
 * Question types that accept selected choice identifiers.
 */
export const CHOICE_QUESTION_TYPES = new Set(['singleChoice', 'multipleChoice']);
/**
 * Question types that accept free text answers.
 */
export const TEXT_QUESTION_TYPES = new Set(['textSingle', 'textMultiLine']);
/**
 * The question type used for image uploads.
 */
export const IMAGE_UPLOAD_QUESTION_TYPE = 'imageUpload';
/**
 * All question types accepted by the API.
 */
export const QUESTION_TYPES = new Set([...CHOICE_QUESTION_TYPES, ...TEXT_QUESTION_TYPES, IMAGE_UPLOAD_QUESTION_TYPE]);
const JSON_BODY_MAX_BYTES = 1024 * 1024;

/** Max bytes per uploaded image (5 MiB). */
export const MEDIA_MAX_BYTES = 5 * 1024 * 1024;
/** Default / hard cap for images per imageUpload answer. */
export const MEDIA_MAX_FILES = 3;
/**
 * MIME types accepted for uploaded survey images.
 */
export const MEDIA_ALLOWED_CONTENT_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp', 'image/gif']);

/**
 * Response headers used for JSON API responses.
 */
export const jsonHeaders = {
  /**
   * Declares that the response body contains UTF-8 JSON.
   */
  'content-type': 'application/json; charset=utf-8',
  /**
   * Allows cross-origin requests from any origin.
   */
  'access-control-allow-origin': '*',
  /**
   * The HTTP methods accepted by the API's cross-origin policy.
   */
  'access-control-allow-methods': 'GET,POST,PUT,DELETE,OPTIONS',
  /**
   * The request headers permitted by the cross-origin policy.
   */
  'access-control-allow-headers': 'content-type,authorization',
  // Cache preflight so browsers do not OPTIONS on every cross-origin call.
  /**
   * The lifetime of cached preflight results in seconds.
   */
  'access-control-max-age': '86400',
};

/** True only for UNIQUE violations (not generic FK "constraint" failures). */
export function isUniqueConstraintError(error: unknown): boolean {
  const message = error instanceof Error ? error.message : String(error);
  return /unique constraint failed|SQLITE_CONSTRAINT_UNIQUE|constraint failed:.*unique/i.test(message);
}

/**
 * Reads a bounded request body and requires a JSON object.
 */
export async function readJson(request: Request, optional = false): Promise<Record<string, unknown>> {
  const text = await readTextWithLimit(request, JSON_BODY_MAX_BYTES);
  if (!text && optional) return {};
  if (!text) throw new HttpError(400, 'JSON body required');
  let decoded: unknown;
  try {
    decoded = JSON.parse(text);
  } catch {
    throw new HttpError(400, 'Invalid JSON body');
  }
  if (!decoded || typeof decoded !== 'object' || Array.isArray(decoded)) {
    throw new HttpError(400, 'JSON body must be an object');
  }
  return decoded as Record<string, unknown>;
}

async function readTextWithLimit(request: Request, maxBytes: number): Promise<string> {
  const contentLength = request.headers.get('content-length');
  if (contentLength != null) {
    if (!/^\d+$/.test(contentLength)) throw new HttpError(400, 'Invalid Content-Length');
    if (Number(contentLength) > maxBytes) throw new HttpError(413, 'JSON body too large');
  }
  if (!request.body) return '';

  const reader = request.body.getReader();
  const decoder = new TextDecoder();
  let bytesRead = 0;
  let text = '';

  try {
    for (;;) {
      const { done, value } = await reader.read();
      if (done) break;
      bytesRead += value.byteLength;
      if (bytesRead > maxBytes) {
        await reader.cancel();
        throw new HttpError(413, 'JSON body too large');
      }
      text += decoder.decode(value, { stream: true });
    }
    text += decoder.decode();
    return text;
  } finally {
    reader.releaseLock();
  }
}

/**
 * Requires a non-null object and rejects arrays and primitive values.
 */
export function requireObject(value: unknown, field: string): Record<string, unknown> {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpError(400, `${field} must be an object`);
  }
  return value as Record<string, unknown>;
}

/**
 * Validates the outer structure of an answer payload.
 */
export function requireAnswerInput(value: unknown): AnswerInput {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpError(400, 'Invalid answer');
  }
  return value as AnswerInput;
}

/**
 * Encodes a value as a JSON response with the supplied HTTP status.
 */
export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

/**
 * An expected request failure carrying an HTTP status and public message.
 */
export class HttpError extends Error {
  /**
   * Creates an HTTP error with its status, message, and optional details.
   */
  constructor(
    /**
     * The HTTP status to return for this expected failure.
     */
    readonly status: number,
    message: string,
    /**
     * Optional structured details to include in the error response.
     */
    readonly details?: unknown,
  ) {
    super(message);
  }
}

/**
 * Writes structured error details with an event name and supplied context.
 */
export function logError(event: string, error: unknown, context: Record<string, unknown> = {}): void {
  console.error(
    JSON.stringify({
      level: 'error',
      event,
      ...context,
      error: errorToLogObject(error),
    }),
  );
}

/**
 * Writes a structured warning with an event name and supplied context.
 */
export function logWarn(event: string, context: Record<string, unknown> = {}): void {
  console.warn(
    JSON.stringify({
      level: 'warn',
      event,
      ...context,
    }),
  );
}

function errorToLogObject(error: unknown): Record<string, string> {
  if (error instanceof Error) {
    return {
      name: error.name,
      message: error.message,
      stack: error.stack ?? '',
    };
  }
  return { message: String(error) };
}

/**
 * Executes a parameterized count query and returns its numeric result.
 */
export async function countRows(db: D1Database, sql: string, ...binds: unknown[]): Promise<number> {
  const row = await db
    .prepare(sql)
    .bind(...binds)
    .first<{ count: unknown }>();
  if (!row || typeof row.count !== 'number' || !Number.isSafeInteger(row.count)) {
    throw new HttpError(500, 'Count query failed');
  }
  return row.count;
}

/**
 * Returns the database operation result or throws HTTP 500 when no row was returned.
 */
export function requiredRow<T>(row: T | null, name: string): T {
  if (!row) throw new HttpError(500, `${name} operation failed`);
  return row;
}

const D1_BIND_CHUNK = 90;

/**
 * Executes an identifier query in bounded chunks and combines the returned rows.
 */
export async function queryInChunks<T>(
  db: D1Database,
  buildSql: (placeholders: string) => string,
  ids: readonly unknown[],
): Promise<T[]> {
  if (ids.length === 0) return [];
  const results: T[] = [];
  for (let i = 0; i < ids.length; i += D1_BIND_CHUNK) {
    const chunk = ids.slice(i, i + D1_BIND_CHUNK);
    const ph = chunk.map(() => '?').join(', ');
    const rows = await db
      .prepare(buildSql(ph))
      .bind(...chunk)
      .all<T>();
    results.push(...rows.results);
  }
  return results;
}

/**
 * Requires a nonempty trimmed string and reports the field name on failure.
 */
export function requireString(value: unknown, field: string): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new HttpError(400, `${field} is required`);
  }
  return value.trim();
}

/**
 * Returns a trimmed optional string, rejecting values of the wrong type.
 */
export function optionalString(value: unknown, field: string): string | null {
  if (value == null || value === '') return null;
  if (typeof value !== 'string') throw new HttpError(400, `${field} must be a string`);
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

/** Optional string with a maximum length (after trim). Empty → null. */
export function optionalLimitedString(value: unknown, field: string, maxLength: number): string | null {
  const text = optionalString(value, field);
  if (text == null) return null;
  if (text.length > maxLength) {
    throw new HttpError(400, `${field} must be ${maxLength} characters or fewer`);
  }
  return text;
}

/** Reject empty / invalid emails and SMTP header/command injection characters. */
export function requireEmail(value: unknown, field: string): string {
  const email = requireString(value, field).toLowerCase();
  if (!isValidEmail(email)) {
    throw new HttpError(400, `${field} must be a valid email address`);
  }
  return email;
}

/**
 * Validates an optional email address and returns its normalized text.
 */
export function optionalEmail(value: unknown, field: string): string | null {
  const email = optionalString(value, field);
  if (email == null) return null;
  const normalized = email.toLowerCase();
  if (!isValidEmail(normalized)) {
    throw new HttpError(400, `${field} must be a valid email address`);
  }
  return normalized;
}

function isValidEmail(email: string): boolean {
  // No whitespace/CRLF/angle brackets (SMTP command & header injection).
  if (/[\s<>]/.test(email)) return false;
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

/** Parses an optional date and returns ISO 8601 text, rejecting invalid input with HTTP 400. */
export function optionalIsoDateTime(value: unknown, field: string): string | null {
  const text = optionalString(value, field);
  if (text == null) return null;
  const ms = Date.parse(text);
  if (Number.isNaN(ms)) {
    throw new HttpError(400, `${field} must be a valid ISO 8601 date`);
  }
  return new Date(ms).toISOString();
}

/**
 * Validates an optional Boolean and returns null when it is absent.
 */
export function optionalBoolean(value: unknown, field: string): boolean | null {
  if (value == null) return null;
  if (typeof value !== 'boolean') throw new HttpError(400, `${field} must be a boolean`);
  return value;
}

/**
 * Requires a Boolean value and rejects missing or invalid input.
 */
export function requiredBoolean(value: unknown, field: string): boolean {
  const boolean = optionalBoolean(value, field);
  if (boolean == null) throw new HttpError(400, `${field} is required`);
  return boolean;
}

/**
 * Validates and normalizes an optional custom domain host name.
 */
export function optionalCustomDomain(value: unknown): string | null {
  if (value == null) return null;
  if (typeof value !== 'string') throw new HttpError(400, 'customDomain must be a hostname');
  const domain = value.trim().toLowerCase().replace(/\.$/, '');
  if (domain.length === 0) return null;
  if (domain.length > 253) throw new HttpError(400, 'customDomain must be 253 characters or fewer');
  if (
    domain.includes('://') ||
    domain.includes('/') ||
    domain.includes('?') ||
    domain.includes('#') ||
    domain.includes('@') ||
    domain.includes(':')
  ) {
    throw new HttpError(400, 'customDomain must be a hostname');
  }
  const labels = domain.split('.');
  if (labels.length < 2) throw new HttpError(400, 'customDomain must include a registrable domain');
  const validLabels = labels.every((label) => /^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$/.test(label));
  if (!validLabels) throw new HttpError(400, 'customDomain must be a valid hostname');
  return domain;
}

/**
 * Optional inclusive bounds used when validating integer inputs.
 */
type IntegerParamOptions = {
  /**
   * The smallest accepted integer, when a lower bound is required.
   */
  min?: number;
  /**
   * The largest accepted integer, when an upper bound is required.
   */
  max?: number;
};

/**
 * Parses an optional integer query parameter within the supplied bounds.
 */
export function optionalIntegerParam(
  value: string | null,
  field: string,
  options: IntegerParamOptions = {},
): number | null {
  if (value == null) return null;
  if (value.trim().length === 0) return null;
  if (!/^-?\d+$/.test(value)) throw new HttpError(400, `${field} must be an integer`);
  return validateInteger(Number(value), field, options);
}

/**
 * Validates an optional integer field within the supplied bounds.
 */
export function optionalInteger(value: unknown, field: string, options: IntegerParamOptions = {}): number | null {
  if (value == null) return null;
  if (typeof value !== 'number') throw new HttpError(400, `${field} must be an integer`);
  return validateInteger(value, field, options);
}

function validateInteger(number: number, field: string, options: IntegerParamOptions): number {
  if (!Number.isInteger(number)) throw new HttpError(400, `${field} must be an integer`);
  if (!Number.isSafeInteger(number)) throw new HttpError(400, `${field} must be a safe integer`);
  if (options.min != null && number < options.min) {
    throw new HttpError(400, `${field} must be at least ${options.min}`);
  }
  if (options.max != null && number > options.max) {
    throw new HttpError(400, `${field} must be at most ${options.max}`);
  }
  return number;
}

/**
 * Parses an integer query parameter, using the fallback when absent.
 */
export function integerParam(
  value: string | null,
  field: string,
  defaultValue: number,
  options: IntegerParamOptions = {},
): number {
  return optionalIntegerParam(value, field, options) ?? defaultValue;
}

/**
 * Requires an integer field within the supplied bounds.
 */
export function requiredInteger(value: unknown, field: string, options: IntegerParamOptions = {}): number {
  const number = optionalInteger(value, field, options);
  if (number == null) throw new HttpError(400, `${field} is required`);
  return number;
}

/**
 * Requires an integer query parameter within the supplied bounds.
 */
export function requiredIntegerParam(
  value: string | null | undefined,
  field: string,
  options: IntegerParamOptions = {},
): number {
  const number = optionalIntegerParam(value ?? null, field, options);
  if (number == null) throw new HttpError(400, `${field} is required`);
  return number;
}

/**
 * Validates and normalizes a URL-friendly resource slug.
 */
export function requireSlug(value: unknown): string {
  const slug = requireString(value, 'slug');
  if (!/^[a-z0-9-]+$/.test(slug)) throw new HttpError(400, 'slug must contain lowercase letters, numbers, and hyphens');
  return slug;
}

/**
 * Validates an array of integer identifiers with the requested constraints.
 */
export function requireNumberList(value: unknown, field: string, options: IntegerParamOptions = {}): number[] {
  if (!Array.isArray(value)) throw new HttpError(400, `${field} must be an array`);
  return value.map((item, index) => requiredInteger(item, `${field}[${index}]`, options));
}

/**
 * Requires the supplied identifiers to match the expected set without duplicates.
 */
export function assertExactIds(expected: number[], actual: number[], field: string): void {
  const expectedSorted = [...expected].sort((a, b) => a - b);
  const actualSorted = [...actual].sort((a, b) => a - b);
  if (expectedSorted.length !== actualSorted.length || expectedSorted.some((id, index) => id !== actualSorted[index])) {
    throw new HttpError(400, `${field} must include every current id exactly once`);
  }
}

/**
 * Returns whether a question type accepts selectable choices.
 */
export function isChoiceQuestionType(type: string): boolean {
  return CHOICE_QUESTION_TYPES.has(type);
}

/**
 * Returns whether a question type accepts text answers.
 */
export function isTextQuestionType(type: string): boolean {
  return TEXT_QUESTION_TYPES.has(type);
}

/**
 * Returns whether a question type accepts uploaded images.
 */
export function isImageUploadQuestionType(type: string): boolean {
  return type === IMAGE_UPLOAD_QUESTION_TYPE;
}

/**
 * Inserts localized choices for a question in their supplied order.
 */
export async function insertChoices(
  db: D1Database,
  questionId: number,
  choiceTranslations: readonly Record<string, string>[],
): Promise<void> {
  const inserts = choiceTranslations.map((translations, index) =>
    db
      .prepare(`INSERT INTO choices (question_id, text_translations, order_index) VALUES (?, ?, ?)`)
      .bind(questionId, JSON.stringify(translations), index),
  );
  if (inserts.length > 0) await db.batch(inserts);
}

/**
 * Saves sequential order indexes for the supplied record identifiers.
 */
export async function updateOrder(
  db: D1Database,
  table: 'questions' | 'choices',
  ids: readonly number[],
): Promise<void> {
  const updates = ids.map((id, index) =>
    db.prepare(`UPDATE ${table} SET order_index = ? WHERE id = ?`).bind(index, id),
  );
  if (updates.length > 0) await db.batch(updates);
}

/**
 * Requires a supported question type and rejects unknown values.
 */
export function normalizeQuestionType(value: unknown): string {
  if (typeof value !== 'string') {
    throw new HttpError(400, 'Invalid question type');
  }
  const type = value;
  if (QUESTION_TYPES.has(type)) {
    return type;
  }
  throw new HttpError(400, 'Invalid question type');
}

/**
 * Converts a Boolean into the zero or one representation stored in D1.
 */
export function boolToInt(value: boolean): number {
  return value ? 1 : 0;
}

/**
 * Returns an object with absent values removed.
 */
export function compactObject(source: Record<string, unknown>): Record<string, unknown> {
  return Object.fromEntries(
    Object.entries(source).filter(([, value]) => {
      if (value == null) return false;
      return typeof value !== 'string' || value.trim().length > 0;
    }),
  );
}

/**
 * Extracts the bearer token from the authorization header, or null when unavailable.
 */
export function bearerToken(request: Request): string | null {
  const authorization = request.headers.get('authorization');
  if (!authorization?.startsWith('Bearer ')) return null;
  return authorization.slice('Bearer '.length).trim();
}

/**
 * Returns the current time as an ISO 8601 string.
 */
export function nowIso(): string {
  return new Date().toISOString();
}
