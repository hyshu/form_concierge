import type { ChoiceRow, ProjectRow, QuestionRow, SurveyRow } from './types';
import { HttpError } from './utils';

export async function mustProject(db: D1Database, id: number): Promise<ProjectRow> {
  const row = await db.prepare(`SELECT * FROM projects WHERE id = ?`).bind(id).first<ProjectRow>();
  if (!row) throw new HttpError(404, 'Project not found');
  return row;
}

export async function mustSurvey(db: D1Database, id: number): Promise<SurveyRow> {
  const row = await db.prepare(`SELECT * FROM surveys WHERE id = ?`).bind(id).first<SurveyRow>();
  if (!row) throw new HttpError(404, 'Survey not found');
  return row;
}

export async function mustQuestion(db: D1Database, id: number): Promise<QuestionRow> {
  const row = await db.prepare(`SELECT * FROM questions WHERE id = ?`).bind(id).first<QuestionRow>();
  if (!row) throw new HttpError(404, 'Question not found');
  return row;
}

export async function mustChoice(db: D1Database, id: number): Promise<ChoiceRow> {
  const row = await db.prepare(`SELECT * FROM choices WHERE id = ?`).bind(id).first<ChoiceRow>();
  if (!row) throw new HttpError(404, 'Choice not found');
  return row;
}
