import assert from 'node:assert/strict';
import test from 'node:test';

import { normalizeDeviceInfo } from './metadata';
import { HttpError } from './utils';

test('normalizeDeviceInfo keeps numeric telemetry strict', () => {
  assert.deepEqual(
    {
      screenWidth: normalizeDeviceInfo({ screenWidth: 390 }).screenWidth,
      devicePixelRatio: normalizeDeviceInfo({ devicePixelRatio: 2 }).devicePixelRatio,
    },
    {
      screenWidth: 390,
      devicePixelRatio: 2,
    },
  );
  assertHttpError(
    () => normalizeDeviceInfo({ screenWidth: '390' }),
    'deviceInfo.screenWidth must be an integer',
  );
  assertHttpError(
    () => normalizeDeviceInfo({ devicePixelRatio: '2' }),
    'deviceInfo.devicePixelRatio must be a positive number',
  );
});

function assertHttpError(action: () => unknown, message: string): void {
  assert.throws(action, (error: unknown) =>
    error instanceof HttpError &&
    error.status === 400 &&
    error.message === message,
  );
}
