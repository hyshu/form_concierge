import { HttpError, requireObject, requireString } from './utils';

export const FORM_CONTENT_LOCALES = [
  'en',
  'ja',
  'zh-Hans',
  'zh-Hant',
  'ko',
  'de',
  'es',
  'fr',
  'it',
  'th',
  'tr',
] as const;
export const DEFAULT_FORM_CONTENT_LOCALE = 'en';

export type LocalizedText = Record<string, string>;

export function requireSupportedLocales(value: unknown): string[] {
  if (!Array.isArray(value)) throw new HttpError(400, 'supportedLocales must be an array');
  const locales = value.map((locale, index) => {
    if (typeof locale !== 'string') {
      throw new HttpError(400, `supportedLocales[${index}] must be a string`);
    }
    return locale;
  });
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
  const raw = requireObject(value, field);
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

export function defaultLocalizedText(
  value: string,
  locales: readonly string[] = FORM_CONTENT_LOCALES,
): LocalizedText {
  return Object.fromEntries(locales.map((locale) => [locale, value]));
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
    Object.entries(decoded).map(([locale, text]) => {
      if (typeof text !== 'string') throw new HttpError(500, `Invalid localized text for locale: ${locale}`);
      return [locale, text];
    }),
  );
}

export function localizedTextFor(value: string, locale = DEFAULT_FORM_CONTENT_LOCALE): string {
  const map = parseLocalizedText(value);
  // Prefer the requested locale, then the global default, then any available
  // translation. Projects may publish with a single locale (e.g. ja-only) while
  // callers still pass DEFAULT_FORM_CONTENT_LOCALE (en) for error messages.
  const text =
    map[locale] ??
    map[DEFAULT_FORM_CONTENT_LOCALE] ??
    Object.values(map).find((item): item is string => typeof item === 'string');
  if (text == null) {
    throw new HttpError(500, `Missing localized text for locale: ${locale}`);
  }
  return text;
}
