import type { AnswerInput } from './types';

export const CHOICE_QUESTION_TYPES = new Set(['singleChoice', 'multipleChoice']);
export const TEXT_QUESTION_TYPES = new Set(['textSingle', 'textMultiLine']);
export const QUESTION_TYPES = new Set([...CHOICE_QUESTION_TYPES, ...TEXT_QUESTION_TYPES]);

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
  const text = await request.text();
  if (!text && optional) return {};
  if (!text) throw new HttpError(400, 'JSON body required');
  try {
    return objectBody(JSON.parse(text));
  } catch {
    throw new HttpError(400, 'Invalid JSON body');
  }
}

export function objectBody(value: unknown): Record<string, unknown> {
  return value && typeof value === 'object' && !Array.isArray(value)
    ? value as Record<string, unknown>
    : {};
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

export async function countRows(db: D1Database, sql: string, ...binds: unknown[]): Promise<number> {
  const row = await db.prepare(sql).bind(...binds).first<{ count: number }>();
  return Number(row?.count ?? 0);
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

export function optionalString(value: unknown): string | null {
  return typeof value === 'string' && value.trim().length > 0 ? value.trim() : null;
}

export function optionalNumber(value: unknown): number | null {
  if (value == null || value === '') return null;
  const number = Number(value);
  return Number.isFinite(number) ? number : null;
}

export function requireSlug(value: unknown): string {
  const slug = requireString(value, 'slug');
  if (!/^[a-z0-9-]+$/.test(slug)) throw new HttpError(400, 'slug must contain lowercase letters, numbers, and hyphens');
  return slug;
}

export function requireNumberList(value: unknown, field: string): number[] {
  if (!Array.isArray(value)) throw new HttpError(400, `${field} must be an array`);
  const numbers = value.map(Number);
  if (!numbers.every(Number.isInteger)) throw new HttpError(400, `${field} must contain integers`);
  return numbers;
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
  choices: readonly string[],
): Promise<void> {
  const inserts = choices.map((choice, index) =>
    db.prepare(`INSERT INTO choices (question_id, text, order_index) VALUES (?, ?, ?)`)
      .bind(questionId, choice, index),
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
  const type = String(value);
  if (QUESTION_TYPES.has(type)) {
    return type;
  }
  throw new HttpError(400, 'Invalid question type');
}

export function boolToInt(value: unknown): number {
  return value === true || value === 1 || value === 'true' ? 1 : 0;
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
