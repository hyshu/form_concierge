import assert from 'node:assert/strict';
import test from 'node:test';

import { assertBadRequest } from '../test/helpers';
import { normalizeDeviceInfo } from './metadata';

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
  assertBadRequest(
    () => normalizeDeviceInfo({ screenWidth: '390' }),
    'deviceInfo.screenWidth must be an integer',
  );
  assertBadRequest(
    () => normalizeDeviceInfo({ devicePixelRatio: '2' }),
    'deviceInfo.devicePixelRatio must be a positive number',
  );
});
