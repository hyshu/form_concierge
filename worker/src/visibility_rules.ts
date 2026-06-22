import type { AnswerInput, Env, QuestionRow, VisibilityRuleInput, VisibilityRuleRow } from './types';
import { HttpError, isChoiceQuestionType, isTextQuestionType, json, nowIso, optionalInteger, readJson, requiredInteger } from './utils';
import { mustSurvey } from './admin_records';
import { visibilityRuleToJson } from './serializers';

const VISIBILITY_OPERATORS = new Set([
  'equals',
  'notEquals',
  'contains',
  'notContains',
  'isAnswered',
  'isNotAnswered',
]);

const VALUELESS_OPERATORS = new Set(['isAnswered', 'isNotAnswered']);

export type NormalizedVisibilityRule = {
  targetQuestionId: number;
  sourceQuestionId: number;
  operator: string;
  value: unknown;
};

export async function listPublicVisibilityRules(env: Env, surveyId: number): Promise<Response> {
  const rows = await env.DB.prepare(
     `SELECT r.* FROM question_visibility_rules r
     JOIN surveys s ON s.id = r.survey_id
     WHERE r.survey_id = ? AND s.status = 'published' AND s.web_enabled = 1
     ORDER BY r.target_question_id, r.id`,
  ).bind(surveyId).all<VisibilityRuleRow>();
  return json(rows.results.map(visibilityRuleToJson));
}

export async function listAdminVisibilityRules(env: Env, surveyId: number): Promise<Response> {
  await mustSurvey(env.DB, surveyId);
  const rows = await getVisibilityRules(env.DB, surveyId);
  return json(rows.map(visibilityRuleToJson));
}

export async function replaceAdminVisibilityRules(
  request: Request,
  env: Env,
  surveyId: number,
): Promise<Response> {
  await mustSurvey(env.DB, surveyId);
  const body = await readJson(request);
  if (!Array.isArray(body.rules)) throw new HttpError(400, 'rules must be an array');
  const inputs = body.rules.map((rule) => normalizeRuleInput(rule));
  const questions = await getCurrentQuestions(env.DB, surveyId);
  const byId = new Map(questions.map((question) => [question.id, question]));
  const now = nowIso();

  for (const rule of inputs) {
    const target = byId.get(rule.targetQuestionId);
    const source = byId.get(rule.sourceQuestionId);
    if (!target || !source) throw new HttpError(400, 'Rule questions must belong to this survey');
    if (source.id === target.id) throw new HttpError(400, 'A question cannot depend on itself');
    if (source.order_index >= target.order_index) {
      throw new HttpError(400, 'A rule can only depend on an earlier question');
    }
    validateRuleValue(source, rule.operator, rule.value);
  }

  const statements = [
    env.DB.prepare(`DELETE FROM question_visibility_rules WHERE survey_id = ?`).bind(surveyId),
    ...inputs.map((rule) =>
      env.DB.prepare(
        `INSERT INTO question_visibility_rules
           (survey_id, target_question_id, source_question_id, operator, value_json, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
      ).bind(
        surveyId,
        rule.targetQuestionId,
        rule.sourceQuestionId,
        rule.operator,
        VALUELESS_OPERATORS.has(rule.operator) ? null : JSON.stringify(rule.value),
        now,
        now,
      ),
    ),
  ];
  await env.DB.batch(statements);
  return listAdminVisibilityRules(env, surveyId);
}

export async function getVisibilityRules(db: D1Database, surveyId: number): Promise<VisibilityRuleRow[]> {
  const rows = await db.prepare(
    `SELECT * FROM question_visibility_rules
     WHERE survey_id = ?
     ORDER BY target_question_id, id`,
  ).bind(surveyId).all<VisibilityRuleRow>();
  return rows.results;
}

export function visibleQuestionIds(
  questions: QuestionRow[],
  rules: VisibilityRuleRow[],
  answers: AnswerInput[],
): Set<number> {
  const answerByQuestion = new Map<number, AnswerInput>();
  for (const answer of answers) {
    const questionId = optionalInteger(answer.questionId, 'questionId', { min: 1 });
    if (questionId != null) answerByQuestion.set(questionId, answer);
  }
  const questionById = new Map(questions.map((question) => [question.id, question]));
  const rulesByTarget = new Map<number, VisibilityRuleRow[]>();
  for (const rule of rules) {
    const existing = rulesByTarget.get(rule.target_question_id) ?? [];
    existing.push(rule);
    rulesByTarget.set(rule.target_question_id, existing);
  }

  const visible = new Set<number>();
  for (const question of questions) {
    const questionRules = rulesByTarget.get(question.id) ?? [];
    if (questionRules.length === 0) {
      visible.add(question.id);
      continue;
    }
    const outcomes = questionRules.map((rule) => {
      const source = questionById.get(rule.source_question_id);
      if (!source || !visible.has(source.id)) return false;
      return evaluateRule(source, rule, answerByQuestion.get(source.id));
    });
    const mode = question.visibility_condition_mode === 'any' ? 'any' : 'all';
    if (mode === 'any' ? outcomes.some(Boolean) : outcomes.every(Boolean)) {
      visible.add(question.id);
    }
  }
  return visible;
}

export function normalizeRuleInput(value: unknown): NormalizedVisibilityRule {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpError(400, 'Invalid visibility rule');
  }
  const raw = value as VisibilityRuleInput;
  const targetQuestionId = requiredInteger(raw.targetQuestionId, 'targetQuestionId', { min: 1 });
  const sourceQuestionId = requiredInteger(raw.sourceQuestionId, 'sourceQuestionId', { min: 1 });
  const operator = raw.operator;
  if (typeof operator !== 'string') throw new HttpError(400, 'Invalid visibility operator');
  if (!VISIBILITY_OPERATORS.has(operator)) throw new HttpError(400, 'Invalid visibility operator');
  return {
    targetQuestionId,
    sourceQuestionId,
    operator,
    value: VALUELESS_OPERATORS.has(operator) ? null : raw.value,
  };
}

function validateRuleValue(source: QuestionRow, operator: string, value: unknown): void {
  if (VALUELESS_OPERATORS.has(operator)) return;
  if (isTextQuestionType(source.type)) {
    if (typeof value !== 'string' || value.trim().length === 0) {
      throw new HttpError(400, 'Text visibility rules require a value');
    }
    return;
  }
  if (isChoiceQuestionType(source.type)) {
    requiredInteger(value, 'Choice visibility rule value', { min: 1 });
    return;
  }
  throw new HttpError(400, 'Unsupported source question type');
}

function evaluateRule(
  source: QuestionRow,
  rule: VisibilityRuleRow,
  answer: AnswerInput | undefined,
): boolean {
  const hasAnswer = answerHasValue(source, answer);
  if (rule.operator === 'isAnswered') return hasAnswer;
  if (rule.operator === 'isNotAnswered') return !hasAnswer;
  if (!hasAnswer) return false;

  const expected = parseRuleValue(rule);
  if (isTextQuestionType(source.type)) {
    const actual = typeof answer?.textValue === 'string' ? answer.textValue.trim() : '';
    const expectedText = requireTextRuleValue(rule, expected);
    if (rule.operator === 'equals') return actual === expectedText;
    if (rule.operator === 'notEquals') return actual !== expectedText;
    if (rule.operator === 'contains') return actual.includes(expectedText);
    if (rule.operator === 'notContains') return !actual.includes(expectedText);
  }

  const selected = Array.isArray(answer?.selectedChoiceIds)
    ? answer.selectedChoiceIds.map((choiceId) => requiredInteger(choiceId, 'selectedChoiceIds', { min: 1 }))
    : [];
  const expectedChoiceId = requiredInteger(expected, 'Visibility rule choice id', { min: 1 });
  if (rule.operator === 'equals' || rule.operator === 'contains') {
    return selected.includes(expectedChoiceId);
  }
  if (rule.operator === 'notEquals' || rule.operator === 'notContains') {
    return !selected.includes(expectedChoiceId);
  }
  return false;
}

function answerHasValue(source: QuestionRow, answer: AnswerInput | undefined): boolean {
  if (!answer) return false;
  if (isTextQuestionType(source.type)) {
    return typeof answer.textValue === 'string' && answer.textValue.trim().length > 0;
  }
  return Array.isArray(answer.selectedChoiceIds) && answer.selectedChoiceIds.length > 0;
}

function parseRuleValue(rule: VisibilityRuleRow): unknown {
  if (!rule.value_json) return null;
  try {
    return JSON.parse(rule.value_json);
  } catch {
    throw new HttpError(500, `Invalid visibility rule value for rule ${rule.id}`);
  }
}

function requireTextRuleValue(rule: VisibilityRuleRow, value: unknown): string {
  if (typeof value !== 'string') {
    throw new HttpError(500, `Invalid visibility rule value for rule ${rule.id}`);
  }
  return value;
}

async function getCurrentQuestions(db: D1Database, surveyId: number): Promise<QuestionRow[]> {
  const rows = await db.prepare(
    `SELECT * FROM questions WHERE survey_id = ? AND is_deleted = 0 ORDER BY order_index`,
  ).bind(surveyId).all<QuestionRow>();
  return rows.results;
}
