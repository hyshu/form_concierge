import type { ChoiceRow, QuestionInput, QuestionRow } from './types';
import { HttpError, isChoiceQuestionType, isTextQuestionType, nowIso, requireObject, requiredInteger } from './utils';

/** A validated creation condition referencing question and choice positions. */
export type SurveyCreationRule = {
  /** The target position in the new survey. */
  targetQuestionIndex: number;
  /** The earlier source position in the new survey. */
  sourceQuestionIndex: number;
  /** The comparison applied to the source answer. */
  operator: string;
  /** The expected text for text questions. */
  textValue: string | null;
  /** The source choice position for choice questions. */
  choiceIndex: number | null;
};

const VALUELESS_OPERATORS = new Set(['isAnswered', 'isNotAnswered']);
const COMPARISONS = new Set(['equals', 'notEquals', 'contains', 'notContains']);

/** Validates all creation conditions before any survey data is inserted. */
export function parseSurveyCreationRules(value: unknown, questions: QuestionInput[]): SurveyCreationRule[] {
  if (value == null) return [];
  if (!Array.isArray(value)) throw new HttpError(400, 'visibilityRules must be an array');
  return value.map((item) => {
    const rule = requireObject(item, 'visibilityRules item');
    const targetQuestionIndex = requiredInteger(rule.targetQuestionIndex, 'targetQuestionIndex', { min: 0 });
    const sourceQuestionIndex = requiredInteger(rule.sourceQuestionIndex, 'sourceQuestionIndex', { min: 0 });
    const source = questions[sourceQuestionIndex];
    if (!source || !questions[targetQuestionIndex] || sourceQuestionIndex >= targetQuestionIndex) {
      throw new HttpError(400, 'A rule can only depend on an earlier question in this survey');
    }
    const operator = rule.operator;
    if (typeof operator !== 'string' || (!VALUELESS_OPERATORS.has(operator) && !COMPARISONS.has(operator))) {
      throw new HttpError(400, 'Invalid visibility operator');
    }
    const normalized: SurveyCreationRule = {
      targetQuestionIndex,
      sourceQuestionIndex,
      operator,
      textValue: null,
      choiceIndex: null,
    };
    if (VALUELESS_OPERATORS.has(operator)) return normalized;
    if (isTextQuestionType(source.type)) {
      if (typeof rule.textValue !== 'string' || rule.textValue.trim() === '') {
        throw new HttpError(400, 'Text visibility rules require a value');
      }
      return { ...normalized, textValue: rule.textValue.trim() };
    }
    if (isChoiceQuestionType(source.type) && (operator === 'equals' || operator === 'notEquals')) {
      const choiceIndex = requiredInteger(rule.choiceIndex, 'choiceIndex', { min: 0 });
      if (!source.choiceTranslations?.[choiceIndex]) {
        throw new HttpError(400, 'Visibility rule choice must belong to its source question');
      }
      return { ...normalized, choiceIndex };
    }
    throw new HttpError(400, 'Unsupported comparison for source question type');
  });
}

/** Resolves positional conditions to stored identifiers in the creation request. */
export async function saveSurveyCreationRules(
  db: D1Database,
  surveyId: number,
  questions: QuestionRow[],
  rules: SurveyCreationRule[],
): Promise<void> {
  if (rules.length === 0) return;
  const choicesBySource = new Map<number, ChoiceRow[]>();
  for (const rule of rules) {
    if (rule.choiceIndex == null || choicesBySource.has(rule.sourceQuestionIndex)) continue;
    const choices = await db
      .prepare('SELECT * FROM choices WHERE question_id = ? ORDER BY order_index, id')
      .bind(questions[rule.sourceQuestionIndex].id)
      .all<ChoiceRow>();
    choicesBySource.set(rule.sourceQuestionIndex, choices.results);
  }
  const now = nowIso();
  const statements = rules.map((rule) => {
    const choice = rule.choiceIndex == null ? null : choicesBySource.get(rule.sourceQuestionIndex)?.[rule.choiceIndex];
    if (rule.choiceIndex != null && !choice) throw new HttpError(500, 'Created visibility rule choice was not found');
    const value = choice?.id ?? rule.textValue;
    return db
      .prepare(
        `INSERT INTO question_visibility_rules
       (survey_id, target_question_id, source_question_id, operator, value_json, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      )
      .bind(
        surveyId,
        questions[rule.targetQuestionIndex].id,
        questions[rule.sourceQuestionIndex].id,
        rule.operator,
        value == null ? null : JSON.stringify(value),
        now,
        now,
      );
  });
  await db.batch(statements);
}
