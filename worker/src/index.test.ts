import assert from 'node:assert/strict';
import test from 'node:test';

import { stubSecretsStoreEnv } from '../test/helpers';
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
    DB: new Proxy(
      {},
      {
        get() {
          throw new Error('DB should not be accessed for invalid route ids');
        },
      },
    ) as D1Database,
    MEDIA_BUCKET: {} as R2Bucket,
    PUBLIC_BASE_URL: 'https://example.com',
    PUBLIC_FORM_ASSET_BASE_URL: 'https://forms.example.com',
    LOGIN_RATE_LIMITER: {
      async limit() {
        return { success: true };
      },
    },
    ANON_CREATE_RATE_LIMITER: {
      async limit() {
        return { success: true };
      },
    },
    ...stubSecretsStoreEnv(),
  };
}

function executionContext(): ExecutionContext {
  return {
    waitUntil(_promise: Promise<unknown>) {},
    passThroughOnException() {},
    get exports(): Cloudflare.Exports {
      throw new Error(
        'Worker exports should not be accessed for invalid route ids',
      );
    },
    props: undefined,
    tracing: tracing(),
    mapVirtualHost() {
      throw new Error(
        'Virtual hosts should not be mapped for invalid route ids',
      );
    },
    abort(reason: unknown) {
      throw reason ?? new Error('Unexpected execution context abort');
    },
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
    startSpan() {
      return new TestSpan();
    },
    getActiveSpan() {
      return undefined;
    },
    Span: TestSpan,
  };
}

class TestSpan implements Span {
  get isTraced(): boolean {
    return false;
  }

  spanContext(): TracingSpanContext {
    return { traceId: '0'.repeat(32), spanId: '0'.repeat(16), traceFlags: 0 };
  }

  setAttribute(_key: string, _value: boolean | number | string): this {
    return this;
  }

  setAttributes(_attributes: Parameters<Span['setAttributes']>[0]): this {
    return this;
  }

  recordException(_exception: Parameters<Span['recordException']>[0]): void {}

  updateName(_name: string): this {
    return this;
  }

  setStatus(_status: TracingSpanStatus): this {
    return this;
  }

  end(): void {}
}
