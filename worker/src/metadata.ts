import type { NormalizedDeviceInfo } from './types';
import { compactObject, HttpError } from './utils';

export function normalizeDeviceInfo(value: unknown): NormalizedDeviceInfo {
  const empty: NormalizedDeviceInfo = {
    deviceId: null,
    label: null,
    platform: null,
    os: null,
    osVersion: null,
    browser: null,
    browserVersion: null,
    appVersion: null,
    appBuild: null,
    model: null,
    manufacturer: null,
    locale: null,
    timezone: null,
    screenWidth: null,
    screenHeight: null,
    devicePixelRatio: null,
    rawJson: null,
  };

  if (value == null) return empty;
  if (typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpError(400, 'deviceInfo must be an object');
  }

  const source = value as Record<string, unknown>;
  const normalized: NormalizedDeviceInfo = {
    deviceId: optionalLimitedString(source.deviceId, 'deviceInfo.deviceId'),
    label: optionalLimitedString(source.label, 'deviceInfo.label'),
    platform: optionalLimitedString(source.platform, 'deviceInfo.platform'),
    os: optionalLimitedString(source.os, 'deviceInfo.os'),
    osVersion: optionalLimitedString(source.osVersion, 'deviceInfo.osVersion'),
    browser: optionalLimitedString(source.browser, 'deviceInfo.browser'),
    browserVersion: optionalLimitedString(source.browserVersion, 'deviceInfo.browserVersion'),
    appVersion: optionalLimitedString(source.appVersion, 'deviceInfo.appVersion'),
    appBuild: optionalLimitedString(source.appBuild, 'deviceInfo.appBuild'),
    model: optionalLimitedString(source.model, 'deviceInfo.model'),
    manufacturer: optionalLimitedString(source.manufacturer, 'deviceInfo.manufacturer'),
    locale: optionalLimitedString(source.locale, 'deviceInfo.locale'),
    timezone: optionalLimitedString(source.timezone, 'deviceInfo.timezone'),
    screenWidth: optionalPositiveInteger(source.screenWidth, 'deviceInfo.screenWidth'),
    screenHeight: optionalPositiveInteger(source.screenHeight, 'deviceInfo.screenHeight'),
    devicePixelRatio: optionalPositiveNumber(source.devicePixelRatio, 'deviceInfo.devicePixelRatio'),
    rawJson: null,
  };

  const raw = compactObject({
    deviceId: normalized.deviceId,
    label: normalized.label,
    platform: normalized.platform,
    os: normalized.os,
    osVersion: normalized.osVersion,
    browser: normalized.browser,
    browserVersion: normalized.browserVersion,
    appVersion: normalized.appVersion,
    appBuild: normalized.appBuild,
    model: normalized.model,
    manufacturer: normalized.manufacturer,
    locale: normalized.locale,
    timezone: normalized.timezone,
    screenWidth: normalized.screenWidth,
    screenHeight: normalized.screenHeight,
    devicePixelRatio: normalized.devicePixelRatio,
  });

  const rawJson = Object.keys(raw).length === 0 ? null : JSON.stringify(raw);
  if (rawJson != null && rawJson.length > 2048) {
    throw new HttpError(400, 'deviceInfo is too large');
  }

  return { ...normalized, rawJson };
}

export function normalizeMetadata(value: unknown): string | null {
  if (value == null) return null;
  if (typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpError(400, 'metadata must be an object');
  }
  const normalized = normalizeMetadataValue(value, 'metadata', 0);
  const json = JSON.stringify(normalized);
  if (json === '{}') return null;
  if (json.length > 4096) throw new HttpError(400, 'metadata is too large');
  return json;
}

export function normalizeMetadataValue(value: unknown, field: string, depth: number): unknown {
  if (depth > 5) throw new HttpError(400, `${field} is too deep`);
  if (value == null) return null;
  if (typeof value === 'string') {
    if (value.length > 512) throw new HttpError(400, `${field} string is too long`);
    return value;
  }
  if (typeof value === 'number') {
    if (!Number.isFinite(value)) throw new HttpError(400, `${field} must be finite`);
    return value;
  }
  if (typeof value === 'boolean') return value;
  if (Array.isArray(value)) {
    if (value.length > 50) throw new HttpError(400, `${field} has too many items`);
    return value.map((item, index) => normalizeMetadataValue(item, `${field}[${index}]`, depth + 1));
  }
  if (typeof value === 'object') {
    const entries = Object.entries(value as Record<string, unknown>);
    if (entries.length > 50) throw new HttpError(400, `${field} has too many keys`);
    return Object.fromEntries(
      entries.map(([key, child]) => {
        if (key.length === 0 || key.length > 80) {
          throw new HttpError(400, `${field} has invalid key`);
        }
        return [key, normalizeMetadataValue(child, `${field}.${key}`, depth + 1)];
      }),
    );
  }
  throw new HttpError(400, `${field} has unsupported value`);
}

function optionalLimitedString(value: unknown, field: string, maxLength = 160): string | null {
  if (value == null || value === '') return null;
  if (typeof value !== 'string') throw new HttpError(400, `${field} must be a string`);
  const trimmed = value.trim();
  if (trimmed.length === 0) return null;
  if (trimmed.length > maxLength) throw new HttpError(400, `${field} is too long`);
  return trimmed;
}

function optionalPositiveInteger(value: unknown, field: string): number | null {
  if (value == null || value === '') return null;
  const number = Number(value);
  if (!Number.isInteger(number) || number < 0 || number > 100000) {
    throw new HttpError(400, `${field} must be a positive integer`);
  }
  return number;
}

function optionalPositiveNumber(value: unknown, field: string): number | null {
  if (value == null || value === '') return null;
  const number = Number(value);
  if (!Number.isFinite(number) || number < 0 || number > 1000) {
    throw new HttpError(400, `${field} must be a positive number`);
  }
  return number;
}
