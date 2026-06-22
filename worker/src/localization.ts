import { HttpError, objectBody, requireString } from './utils';

export const FORM_CONTENT_LOCALES = ['en', 'ja', 'zh-Hans', 'zh-Hant', 'ko', 'de'] as const;
export const DEFAULT_FORM_CONTENT_LOCALE = 'en';

export type LocalizedText = Record<string, string>;

export function requireSupportedLocales(value: unknown): string[] {
  if (!Array.isArray(value)) throw new HttpError(400, 'supportedLocales must be an array');
  const locales = value.map(String);
  if (locales.length === 0) throw new HttpError(400, 'supportedLocales must not be empty');
  for (const locale of locales) {
    if (!FORM_CONTENT_LOCALES.includes(locale as typeof FORM_CONTENT_LOCALES[number])) {
      throw new HttpError(400, `Unsupported locale: ${locale}`);
    }
  }
  return locales;
}

export function requireDefaultLocale(value: unknown, supportedLocales: string[]): string {
  const locale = requireString(value, 'defaultLocale');
  if (!supportedLocales.includes(locale)) {
    throw new HttpError(400, 'defaultLocale must be included in supportedLocales');
  }
  return locale;
}

export function requireLocalizedText(
  value: unknown,
  field: string,
  locales: readonly string[],
  options: { allowEmpty?: boolean } = {},
): LocalizedText {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpError(400, `${field} must be an object`);
  }
  const raw = objectBody(value);
  const localized: LocalizedText = {};
  for (const locale of locales) {
    const rawValue = raw[locale];
    if (typeof rawValue !== 'string') {
      throw new HttpError(400, `${field}.${locale} is required`);
    }
    const text = rawValue.trim();
    if (!options.allowEmpty && text.length === 0) {
      throw new HttpError(400, `${field}.${locale} is required`);
    }
    localized[locale] = text;
  }
  return localized;
}

export function defaultLocalizedText(value: string): LocalizedText {
  return Object.fromEntries(FORM_CONTENT_LOCALES.map((locale) => [locale, value]));
}

export function defaultLocalizedTextJson(value: string): string {
  return JSON.stringify(defaultLocalizedText(value));
}

export function parseLocalizedText(value: string): LocalizedText {
  const decoded = JSON.parse(value);
  if (!decoded || typeof decoded !== 'object' || Array.isArray(decoded)) {
    throw new HttpError(500, 'Invalid localized text');
  }
  return Object.fromEntries(
    Object.entries(decoded).map(([locale, text]) => [locale, String(text)]),
  );
}

export function localizedTextFor(value: string, locale = DEFAULT_FORM_CONTENT_LOCALE): string {
  const text = parseLocalizedText(value)[locale];
  if (text == null) throw new HttpError(500, `Missing localized text for locale: ${locale}`);
  return text;
}
