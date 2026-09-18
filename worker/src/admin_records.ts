import type { ChoiceRow, ProjectRow, QuestionRow, SurveyRow } from './types';
import { HttpError } from './utils';

/**
 * Rejects content changes that are not allowed while a survey is published.
 */
export function guardPublishedSurvey(survey: SurveyRow, action: string): void {
  if (survey.status === 'published') {
    throw new HttpError(400, `Cannot ${action} while the survey is published`);
  }
}

/**
 * Loads a project row or throws an HTTP not-found error.
 */
export async function mustProject(db: D1Database, id: number): Promise<ProjectRow> {
  const row = await db.prepare(`SELECT * FROM projects WHERE id = ?`).bind(id).first<ProjectRow>();
  if (!row) throw new HttpError(404, 'Project not found');
  return row;
}

/**
 * Loads a survey row or throws an HTTP not-found error.
 */
export async function mustSurvey(db: D1Database, id: number): Promise<SurveyRow> {
  const row = await db.prepare(`SELECT * FROM surveys WHERE id = ?`).bind(id).first<SurveyRow>();
  if (!row) throw new HttpError(404, 'Survey not found');
  return row;
}

/**
 * Loads a question row or throws an HTTP not-found error.
 */
export async function mustQuestion(db: D1Database, id: number): Promise<QuestionRow> {
  const row = await db.prepare(`SELECT * FROM questions WHERE id = ?`).bind(id).first<QuestionRow>();
  if (!row) throw new HttpError(404, 'Question not found');
  return row;
}

/**
 * Loads a choice row or throws an HTTP not-found error.
 */
export async function mustChoice(db: D1Database, id: number): Promise<ChoiceRow> {
  const row = await db.prepare(`SELECT * FROM choices WHERE id = ?`).bind(id).first<ChoiceRow>();
  if (!row) throw new HttpError(404, 'Choice not found');
  return row;
}

/**
 * Parses the locale codes stored in a project's database row.
 */
export function projectSupportedLocales(project: ProjectRow): string[] {
  try {
    const decoded = JSON.parse(project.supported_locales);
    if (!Array.isArray(decoded)) throw new Error('not an array');
    return decoded.map((locale, index) => {
      if (typeof locale !== 'string') throw new Error(`locale ${index} is not a string`);
      return locale;
    });
  } catch {
    throw new HttpError(500, 'Invalid project supported locales');
  }
}
