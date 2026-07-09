import type { AnswerInput } from './types';

export const CHOICE_QUESTION_TYPES = new Set(['singleChoice', 'multipleChoice']);
export const TEXT_QUESTION_TYPES = new Set(['textSingle', 'textMultiLine']);
export const QUESTION_TYPES = new Set([...CHOICE_QUESTION_TYPES, ...TEXT_QUESTION_TYPES]);
const JSON_BODY_MAX_BYTES = 1024 * 1024;

export const jsonHeaders = {
  'content-type': 'application/json; charset=utf-8',
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET,POST,PUT,DELETE,OPTIONS',
  'access-control-allow-headers': 'content-type,authorization',
};

export async function readJson(
  request: Request,
  optional = false,
): Promise<Record<string, unknown>> {
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

export function requireObject(value: unknown, field: string): Record<string, unknown> {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpError(400, `${field} must be an object`);
  }
  return value as Record<string, unknown>;
}

export function requireAnswerInput(value: unknown): AnswerInput {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpError(400, 'Invalid answer');
  }
  return value as AnswerInput;
}

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

export class HttpError extends Error {
  constructor(
    readonly status: number,
    message: string,
    readonly details?: unknown,
  ) {
    super(message);
  }
}

export function logError(event: string, error: unknown, context: Record<string, unknown> = {}): void {
  console.error(JSON.stringify({
    level: 'error',
    event,
    ...context,
    error: errorToLogObject(error),
  }));
}

export function logWarn(event: string, context: Record<string, unknown> = {}): void {
  console.warn(JSON.stringify({
    level: 'warn',
    event,
    ...context,
  }));
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

export async function countRows(db: D1Database, sql: string, ...binds: unknown[]): Promise<number> {
  const row = await db.prepare(sql).bind(...binds).first<{ count: unknown }>();
  if (!row || typeof row.count !== 'number' || !Number.isSafeInteger(row.count)) {
    throw new HttpError(500, 'Count query failed');
  }
  return row.count;
}

export function requiredRow<T>(row: T | null, name: string): T {
  if (!row) throw new HttpError(500, `${name} operation failed`);
  return row;
}

export function requireString(value: unknown, field: string): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new HttpError(400, `${field} is required`);
  }
  return value.trim();
}

export function optionalString(value: unknown, field: string): string | null {
  if (value == null || value === '') return null;
  if (typeof value !== 'string') throw new HttpError(400, `${field} must be a string`);
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

/** Reject empty / invalid emails and SMTP header/command injection characters. */
export function requireEmail(value: unknown, field: string): string {
  const email = requireString(value, field).toLowerCase();
  if (!isValidEmail(email)) {
    throw new HttpError(400, `${field} must be a valid email address`);
  }
  return email;
}

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

/** Optional ISO-8601 datetime; invalid values are 400 (not silently "always open"). */
export function optionalIsoDateTime(value: unknown, field: string): string | null {
  const text = optionalString(value, field);
  if (text == null) return null;
  const ms = Date.parse(text);
  if (Number.isNaN(ms)) {
    throw new HttpError(400, `${field} must be a valid ISO 8601 date`);
  }
  return new Date(ms).toISOString();
}

export function optionalBoolean(value: unknown, field: string): boolean | null {
  if (value == null) return null;
  if (typeof value !== 'boolean') throw new HttpError(400, `${field} must be a boolean`);
  return value;
}

export function requiredBoolean(value: unknown, field: string): boolean {
  const boolean = optionalBoolean(value, field);
  if (boolean == null) throw new HttpError(400, `${field} is required`);
  return boolean;
}

export function optionalCustomDomain(value: unknown): string | null {
  if (value == null) return null;
  if (typeof value !== 'string') throw new HttpError(400, 'customDomain must be a hostname');
  const domain = value.trim().toLowerCase().replace(/\.$/, '');
  if (domain.length === 0) return null;
  if (domain.length > 253) throw new HttpError(400, 'customDomain must be 253 characters or fewer');
  if (domain.includes('://') || domain.includes('/') || domain.includes('?') || domain.includes('#') || domain.includes('@') || domain.includes(':')) {
    throw new HttpError(400, 'customDomain must be a hostname');
  }
  const labels = domain.split('.');
  if (labels.length < 2) throw new HttpError(400, 'customDomain must include a registrable domain');
  const validLabels = labels.every((label) =>
    /^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$/.test(label),
  );
  if (!validLabels) throw new HttpError(400, 'customDomain must be a valid hostname');
  return domain;
}

type IntegerParamOptions = {
  min?: number;
  max?: number;
};

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

export function optionalInteger(
  value: unknown,
  field: string,
  options: IntegerParamOptions = {},
): number | null {
  if (value == null) return null;
  if (typeof value !== 'number') throw new HttpError(400, `${field} must be an integer`);
  return validateInteger(value, field, options);
}

function validateInteger(
  number: number,
  field: string,
  options: IntegerParamOptions,
): number {
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

export function integerParam(
  value: string | null,
  field: string,
  defaultValue: number,
  options: IntegerParamOptions = {},
): number {
  return optionalIntegerParam(value, field, options) ?? defaultValue;
}

export function requiredInteger(
  value: unknown,
  field: string,
  options: IntegerParamOptions = {},
): number {
  const number = optionalInteger(value, field, options);
  if (number == null) throw new HttpError(400, `${field} is required`);
  return number;
}

export function requiredIntegerParam(
  value: string | null | undefined,
  field: string,
  options: IntegerParamOptions = {},
): number {
  const number = optionalIntegerParam(value ?? null, field, options);
  if (number == null) throw new HttpError(400, `${field} is required`);
  return number;
}

export function requireSlug(value: unknown): string {
  const slug = requireString(value, 'slug');
  if (!/^[a-z0-9-]+$/.test(slug)) throw new HttpError(400, 'slug must contain lowercase letters, numbers, and hyphens');
  return slug;
}

export function requireNumberList(
  value: unknown,
  field: string,
  options: IntegerParamOptions = {},
): number[] {
  if (!Array.isArray(value)) throw new HttpError(400, `${field} must be an array`);
  return value.map((item, index) => requiredInteger(item, `${field}[${index}]`, options));
}

export function assertExactIds(expected: number[], actual: number[], field: string): void {
  const expectedSorted = [...expected].sort((a, b) => a - b);
  const actualSorted = [...actual].sort((a, b) => a - b);
  if (
    expectedSorted.length !== actualSorted.length ||
    expectedSorted.some((id, index) => id !== actualSorted[index])
  ) {
    throw new HttpError(400, `${field} must include every current id exactly once`);
  }
}

export function isChoiceQuestionType(type: string): boolean {
  return CHOICE_QUESTION_TYPES.has(type);
}

export function isTextQuestionType(type: string): boolean {
  return TEXT_QUESTION_TYPES.has(type);
}

export async function insertChoices(
  db: D1Database,
  questionId: number,
  choiceTranslations: readonly Record<string, string>[],
): Promise<void> {
  const inserts = choiceTranslations.map((translations, index) =>
    db.prepare(`INSERT INTO choices (question_id, text_translations, order_index) VALUES (?, ?, ?)`)
      .bind(questionId, JSON.stringify(translations), index),
  );
  if (inserts.length > 0) await db.batch(inserts);
}

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

export function boolToInt(value: boolean): number {
  return value ? 1 : 0;
}

export function compactObject(source: Record<string, unknown>): Record<string, unknown> {
  return Object.fromEntries(
    Object.entries(source).filter(([, value]) => {
      if (value == null) return false;
      return typeof value !== 'string' || value.trim().length > 0;
    }),
  );
}

export function bearerToken(request: Request): string | null {
  const authorization = request.headers.get('authorization');
  if (!authorization?.startsWith('Bearer ')) return null;
  return authorization.slice('Bearer '.length).trim();
}

export function nowIso(): string {
  return new Date().toISOString();
}
