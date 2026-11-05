import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { DatabaseSync, type SQLInputValue } from 'node:sqlite';
import { URL } from 'node:url';
import test from 'node:test';

import {
  adminPostRequest,
  d1Database,
  d1Result,
  emptyD1Raw,
  stubRateLimiter,
  stubSecretsStoreEnv,
} from '../test/helpers';
import { createSurveyWithQuestions } from './admin_surveys';
import type { AdminContext, Env, QuestionRow, VisibilityRuleRow } from './types';
import { visibleQuestionIds } from './visibility_rules';

test('survey creation stores conditions and resolves draft choice positions to real IDs', async () => {
  const { db, env } = databaseEnv();
  try {
    const response = await createSurveyWithQuestions(
      request([
        {
          targetQuestionIndex: 1,
          sourceQuestionIndex: 0,
          operator: 'equals',
          choiceIndex: 1,
        },
      ]),
      env,
      admin,
    );
    assert.equal(response.status, 201);
    const questions = db.prepare('SELECT * FROM questions ORDER BY order_index').all() as QuestionRow[];
    const choices = db.prepare('SELECT id FROM choices ORDER BY order_index').all();
    const rules = db.prepare('SELECT * FROM question_visibility_rules').all() as VisibilityRuleRow[];
    assert.equal(rules.length, 1);
    assert.equal(rules[0].source_question_id, questions[0].id);
    assert.equal(rules[0].target_question_id, questions[1].id);
    assert.equal(rules[0].value_json, JSON.stringify(choices[1].id));
    assert.equal(questions[1].visibility_condition_mode, 'any');
    const shown = visibleQuestionIds(questions, rules, [
      { questionId: questions[0].id, selectedChoiceIds: [choices[1].id] },
    ]);
    const hidden = visibleQuestionIds(questions, rules, [
      { questionId: questions[0].id, selectedChoiceIds: [choices[0].id] },
    ]);
    assert.ok(shown.has(questions[1].id));
    assert.ok(!hidden.has(questions[1].id));
  } finally {
    db.close();
  }
});

test('text and answer-presence conditions can be created together', async () => {
  const { db, env } = databaseEnv();
  try {
    const body = payload([
      { targetQuestionIndex: 1, sourceQuestionIndex: 0, operator: 'contains', textValue: 'detail' },
      { targetQuestionIndex: 1, sourceQuestionIndex: 0, operator: 'isAnswered' },
    ]);
    body.questions[0] = { ...body.questions[1], textTranslations: { en: 'Source text' } };
    const response = await createSurveyWithQuestions(adminPostRequest('surveys/with-questions', body), env, admin);
    assert.equal(response.status, 201);
    const rules = db.prepare('SELECT operator, value_json FROM question_visibility_rules ORDER BY id').all();
    assert.deepEqual(
      rules.map((rule) => [rule.operator, rule.value_json]),
      [
        ['contains', '"detail"'],
        ['isAnswered', null],
      ],
    );
  } finally {
    db.close();
  }
});

for (const rule of [
  { targetQuestionIndex: 0, sourceQuestionIndex: 0, operator: 'isAnswered' },
  { targetQuestionIndex: 0, sourceQuestionIndex: 1, operator: 'isAnswered' },
  { targetQuestionIndex: 2, sourceQuestionIndex: 0, operator: 'isAnswered' },
  { targetQuestionIndex: 1, sourceQuestionIndex: '0', operator: 'isAnswered' },
  { targetQuestionIndex: 1, sourceQuestionIndex: 0, operator: 'equals', choiceIndex: 99 },
  { targetQuestionIndex: 1, sourceQuestionIndex: 0, operator: 'contains', textValue: 'bad choice comparison' },
  { targetQuestionIndex: 1, sourceQuestionIndex: 0, operator: 'unknown' },
]) {
  test(`invalid creation rule leaves no partial survey ${JSON.stringify(rule)}`, async () => {
    const { db, env } = databaseEnv();
    try {
      await assert.rejects(() => createSurveyWithQuestions(request([rule]), env, admin), { status: 400 });
      assert.equal(db.prepare('SELECT COUNT(*) AS count FROM surveys').get()?.count, 0);
      assert.equal(db.prepare('SELECT COUNT(*) AS count FROM questions').get()?.count, 0);
    } finally {
      db.close();
    }
  });
}

test('rule persistence failure removes the survey and its inserted questions and choices', async () => {
  const { db, env } = databaseEnv(true);
  try {
    await assert.rejects(
      () =>
        createSurveyWithQuestions(
          request([
            {
              targetQuestionIndex: 1,
              sourceQuestionIndex: 0,
              operator: 'equals',
              choiceIndex: 0,
            },
          ]),
          env,
          admin,
        ),
      /Simulated rule persistence failure/,
    );
    for (const table of ['surveys', 'questions', 'choices', 'question_visibility_rules']) {
      assert.equal(db.prepare(`SELECT COUNT(*) AS count FROM ${table}`).get()?.count, 0);
    }
  } finally {
    db.close();
  }
});

const admin: AdminContext = {
  id: 'admin-1',
  email: 'admin@example.com',
  scopeNames: ['admin'],
  created: '2026-01-01T00:00:00.000Z',
};

function request(rules: unknown[]): Request {
  return adminPostRequest('surveys/with-questions', payload(rules));
}

function payload(visibilityRules: unknown[]) {
  return {
    survey: {
      projectId: 1,
      slug: 'conditional',
      titleTranslations: { en: 'Conditional' },
      descriptionTranslations: { en: '' },
    },
    questions: [
      {
        textTranslations: { en: 'Source' },
        type: 'singleChoice',
        isRequired: false,
        placeholderTranslations: { en: '' },
        visibilityConditionMode: 'all',
        choiceTranslations: [{ en: 'One' }, { en: 'Two' }],
      },
      {
        textTranslations: { en: 'Target' },
        type: 'textSingle',
        isRequired: false,
        placeholderTranslations: { en: '' },
        visibilityConditionMode: 'any',
        choiceTranslations: [],
      },
    ],
    visibilityRules,
  };
}

function databaseEnv(failRules = false) {
  const db = new DatabaseSync(':memory:');
  db.exec(readFileSync(new URL('../migrations/0001_initial.sql', import.meta.url), 'utf8'));
  db.exec(`INSERT INTO admins (id, email, password_hash) VALUES ('admin-1', 'admin@example.com', 'unused');
    INSERT INTO projects (id, slug, supported_locales, name) VALUES (1, 'test', '["en"]', 'Test');`);
  const database = d1Database((sql) => {
    const statement = db.prepare(sql);
    let values: SQLInputValue[] = [];
    return {
      bind(...bound: unknown[]) {
        values = bound as SQLInputValue[];
        return this;
      },
      async first<T>() {
        return (statement.get(...values) ?? null) as T | null;
      },
      async all<T>() {
        if (failRules && sql.startsWith('INSERT INTO question_visibility_rules'))
          throw new Error('Simulated rule persistence failure');
        return d1Result(statement.all(...values) as T[]);
      },
      async run<T>() {
        statement.run(...values);
        return d1Result<T>([]);
      },
      raw: emptyD1Raw,
    } satisfies D1PreparedStatement;
  });
  database.batch = async <T>(statements: D1PreparedStatement[]) => {
    db.exec('BEGIN');
    try {
      const results: D1Result<T>[] = [];
      for (const statement of statements) results.push(await statement.all<T>());
      db.exec('COMMIT');
      return results;
    } catch (error) {
      db.exec('ROLLBACK');
      throw error;
    }
  };
  const env: Env = {
    DB: database,
    MEDIA_BUCKET: {} as R2Bucket,
    PUBLIC_BASE_URL: 'https://api.example.com',
    PUBLIC_FORM_ASSET_BASE_URL: 'https://forms.example.com',
    LOGIN_RATE_LIMITER: stubRateLimiter(),
    ANON_CREATE_RATE_LIMITER: stubRateLimiter(),
    ...stubSecretsStoreEnv(),
  };
  return { db, env };
}
