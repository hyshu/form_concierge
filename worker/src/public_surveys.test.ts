import assert from 'node:assert/strict';
import test from 'node:test';

import { questionRow, responseRow, surveyRow } from '../test/fixtures';
import {
  assertHttpErrorAsync,
  d1Database,
  d1Result,
  stubRateLimiter,
  stubSecretsStoreEnv,
} from '../test/helpers';
import { submitResponse } from './public_surveys';
import type { AnonymousContext, Env, QuestionRow, ResponseRow, SurveyRow } from './types';

test('submitResponse rejects surveys that are not accepting responses', async () => {
  const closedVariants: Partial<SurveyRow>[] = [
    { status: 'draft' },
    { status: 'published', web_enabled: 0 },
    { status: 'published', starts_at: '2999-01-01T00:00:00.000Z' },
    { status: 'published', ends_at: '2000-01-01T00:00:00.000Z' },
  ];
  for (const overrides of closedVariants) {
    await assertHttpErrorAsync(
      () => submitResponse(
        submitRequest({ answers: [] }),
        submitEnv({ survey: surveyRow(overrides) }),
        1,
        anonymousContext(),
      ),
      400,
      'Survey is not accepting responses',
    );
  }
  await assertHttpErrorAsync(
    () => submitResponse(
      submitRequest({ answers: [] }),
      submitEnv({ survey: null }),
      1,
      anonymousContext(),
    ),
    400,
    'Survey is not accepting responses',
  );
});

test('submitResponse requires a CAPTCHA token when the survey enables CAPTCHA', async () => {
  await assertHttpErrorAsync(
    () => submitResponse(
      submitRequest({ answers: [] }),
      submitEnv({ survey: acceptingSurvey({ captcha_enabled: 1 }) }),
      1,
      anonymousContext(),
    ),
    400,
    'CAPTCHA token is required',
  );
  await assertHttpErrorAsync(
    () => submitResponse(
      submitRequest({ answers: [], captchaToken: 42 }),
      submitEnv({ survey: acceptingSurvey({ captcha_enabled: 1 }) }),
      1,
      anonymousContext(),
    ),
    400,
    'CAPTCHA token is required',
  );
});

test('submitResponse skips CAPTCHA when the survey disables it', async () => {
  const response = await submitResponse(
    submitRequest({ answers: [] }),
    submitEnv({ survey: acceptingSurvey(), questions: [] }),
    1,
    anonymousContext(),
    executionContext(),
  );
  assert.equal(response.status, 201);
});

test('submitResponse skips CAPTCHA when survey enables it but Turnstile is not configured', async () => {
  const response = await submitResponse(
    submitRequest({ answers: [] }),
    submitEnv({
      survey: acceptingSurvey({ captcha_enabled: 1 }),
      questions: [],
      turnstileConfigured: false,
    }),
    1,
    anonymousContext(),
    executionContext(),
  );
  assert.equal(response.status, 201);
});

test('submitResponse validates required and constrained answers', async () => {
  const cases: { questions: QuestionRow[]; body: unknown; message: string }[] = [
    {
      questions: [questionRow({ id: 1, is_required: 1 })],
      body: { answers: [] },
      message: 'Question "Question" is required',
    },
    {
      questions: [questionRow({ id: 1, is_required: 1 })],
      body: { answers: [{ questionId: 1, textValue: '   ' }] },
      message: 'Question "Question" is required',
    },
    {
      questions: [questionRow({ id: 1, min_length: 5 })],
      body: { answers: [{ questionId: 1, textValue: 'hey' }] },
      message: 'Question "Question" is too short',
    },
    {
      questions: [questionRow({ id: 1, max_length: 3 })],
      body: { answers: [{ questionId: 1, textValue: 'hello' }] },
      message: 'Question "Question" is too long',
    },
    {
      questions: [questionRow({ id: 1 })],
      body: { answers: [{ questionId: 2, textValue: 'hi' }] },
      message: 'Answer question does not belong to survey',
    },
    {
      questions: [questionRow({ id: 1 })],
      body: {
        answers: [
          { questionId: 1, textValue: 'a' },
          { questionId: 1, textValue: 'b' },
        ],
      },
      message: 'Duplicate answer',
    },
    {
      questions: [questionRow({ id: 1, type: 'singleChoice' })],
      body: { answers: [{ questionId: 1, selectedChoiceIds: [10, 11] }] },
      message: 'Question "Question" allows one choice',
    },
    {
      questions: [questionRow({ id: 1, type: 'singleChoice', is_required: 1 })],
      body: { answers: [{ questionId: 1, selectedChoiceIds: [] }] },
      message: 'Question "Question" requires a choice',
    },
    {
      questions: [questionRow({ id: 1, type: 'singleChoice' })],
      body: { answers: [{ questionId: 1, selectedChoiceIds: [99] }] },
      message: 'Choice does not belong to question',
    },
  ];
  for (const { questions, body, message } of cases) {
    await assertHttpErrorAsync(
      () => submitResponse(
        submitRequest(body),
        submitEnv({ survey: acceptingSurvey(), questions, choiceIds: [10] }),
        1,
        anonymousContext(),
      ),
      400,
      message,
    );
  }
});

test('submitResponse returns the existing response for a known idempotency key', async () => {
  const existing = responseRow({ id: 42 });
  const env = submitEnv({
    survey: acceptingSurvey(),
    questions: [],
    existingResponseByIdempotencyKey: existing,
  });
  const response = await submitResponse(
    submitRequest({ answers: [], idempotencyKey: 'retry-key' }),
    env,
    1,
    anonymousContext(),
  );
  assert.equal(response.status, 200);
  const payload = await response.json() as { id: number };
  assert.equal(payload.id, 42);
});

test('submitResponse rejects oversized idempotency keys', async () => {
  await assertHttpErrorAsync(
    () => submitResponse(
      submitRequest({ answers: [], idempotencyKey: 'x'.repeat(65) }),
      submitEnv({ survey: acceptingSurvey(), questions: [] }),
      1,
      anonymousContext(),
    ),
    400,
    'idempotencyKey must be 64 characters or fewer',
  );
});

test('submitResponse persists a valid submission and returns 201', async () => {
  const env = submitEnv({
    survey: acceptingSurvey(),
    questions: [questionRow({ id: 1, is_required: 1 })],
  });
  const response = await submitResponse(
    submitRequest({ answers: [{ questionId: 1, textValue: 'hello' }] }),
    env,
    1,
    anonymousContext(),
    executionContext(),
  );
  assert.equal(response.status, 201);
  const payload = await response.json() as { id: number; surveyId: number };
  assert.equal(payload.surveyId, 1);
});

function acceptingSurvey(overrides: Partial<SurveyRow> = {}): SurveyRow {
  return surveyRow({ status: 'published', captcha_enabled: 0, ...overrides });
}

function anonymousContext(): AnonymousContext {
  return {
    id: 'anon-account-1',
    displayName: null,
    createdAt: '2026-01-01T00:00:00.000Z',
    lastSeenAt: '2026-01-01T00:00:00.000Z',
  };
}

function submitRequest(body: unknown): Request {
  return new Request('https://example.com/api/surveys/id/1/responses', {
    method: 'POST',
    body: JSON.stringify(body),
  });
}

type SubmitEnvOptions = {
  survey: SurveyRow | null;
  questions?: QuestionRow[];
  choiceIds?: number[];
  existingResponseByIdempotencyKey?: ResponseRow | null;
  turnstileConfigured?: boolean;
};

function submitEnv(options: SubmitEnvOptions): Env {
  const db = d1Database((sql: string) => statementFor(sql, options));
  db.batch = async <T>(statements: D1PreparedStatement[]) => {
    const inserted = responseRow({ id: 7 });
    return statements.map((_, index) =>
      d1Result<T>(index === 0 ? [inserted as T] : []),
    );
  };
  return {
    DB: db,
    MEDIA_BUCKET: {} as R2Bucket,
    PUBLIC_BASE_URL: 'https://api.example.com',
    PUBLIC_FORM_ASSET_BASE_URL: 'https://assets.example.com',
    LOGIN_RATE_LIMITER: stubRateLimiter(),
    ANON_CREATE_RATE_LIMITER: stubRateLimiter(),
    ...stubSecretsStoreEnv(
      options.turnstileConfigured === false
        ? { turnstileSiteKey: null, turnstileSecretKey: null }
        : undefined,
    ),
  };
}

function statementFor(sql: string, options: SubmitEnvOptions): D1PreparedStatement {
  return {
    bind() {
      return this;
    },
    async first<T>() {
      if (sql.includes('FROM surveys')) return options.survey as T | null;
      if (sql.includes('idempotency_key')) {
        return (options.existingResponseByIdempotencyKey ?? null) as T | null;
      }
      if (sql.includes('FROM notification_settings')) return null;
      throw new Error(`Unexpected first() query in submitResponse test: ${sql}`);
    },
    async all<T>() {
      if (sql.includes('FROM questions')) {
        return d1Result((options.questions ?? []) as T[]);
      }
      if (sql.includes('FROM question_visibility_rules')) return d1Result<T>([]);
      if (sql.includes('FROM choices')) {
        return d1Result(
          (options.choiceIds ?? []).map((id) => ({ id, question_id: 1 })) as T[],
        );
      }
      throw new Error(`Unexpected all() query in submitResponse test: ${sql}`);
    },
  } as unknown as D1PreparedStatement;
}

function executionContext(): ExecutionContext {
  return {
    waitUntil(_promise: Promise<unknown>) {},
    passThroughOnException() {},
    props: undefined,
  } as unknown as ExecutionContext;
}
