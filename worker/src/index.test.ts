import assert from 'node:assert/strict';
import test from 'node:test';

import worker from './index';
import type { Env } from './types';

test('public survey id routes reject non-integer path ids before storage access', async () => {
  const response = await worker.fetch(
    new Request('https://example.com/api/surveys/id/1.5/questions'),
    envWithoutDb(),
    executionContext(),
  );

  assert.equal(response.status, 400);
  assert.deepEqual(await response.json(), {
    error: 'surveyId must be an integer',
  });
});

test('public question routes reject non-positive path ids before storage access', async () => {
  const response = await worker.fetch(
    new Request('https://example.com/api/questions/0/choices'),
    envWithoutDb(),
    executionContext(),
  );

  assert.equal(response.status, 400);
  assert.deepEqual(await response.json(), {
    error: 'questionId must be at least 1',
  });
});

function envWithoutDb(): Env {
  return {
    DB: new Proxy({}, {
      get() {
        throw new Error('DB should not be accessed for invalid route ids');
      },
    }) as D1Database,
    MEDIA_BUCKET: {} as R2Bucket,
    PUBLIC_BASE_URL: 'https://example.com',
    PUBLIC_FORM_ASSET_BASE_URL: 'https://forms.example.com',
  };
}

function executionContext(): ExecutionContext {
  return {
    waitUntil(_promise: Promise<unknown>) {},
    passThroughOnException() {},
    props: undefined,
    tracing: tracing(),
  };
}

function tracing(): Tracing {
  return {
    enterSpan(_name, callback, ...args) {
      return callback(new TestSpan(), ...args);
    },
    startActiveSpan(_name, callback, ...args) {
      return callback(new TestSpan(), ...args);
    },
    Span: TestSpan as typeof Span,
  };
}

class TestSpan implements Span {
  get isTraced(): boolean {
    return false;
  }

  setAttribute(_key: string, _value?: boolean | number | string): void {}

  end(): void {}
}
