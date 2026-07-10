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

/** Normalize browser/Accept-Language tags to form content locale codes. */
export function normalizeFormContentLocale(locale: string): string {
  const normalized = locale.replaceAll('_', '-');
  if ((FORM_CONTENT_LOCALES as readonly string[]).includes(normalized)) {
    return normalized;
  }
  const lower = normalized.toLowerCase();
  if (lower === 'zh-hans' || lower === 'zh-cn' || lower === 'zh-sg') {
    return 'zh-Hans';
  }
  if (
    lower === 'zh-hant'
    || lower === 'zh-tw'
    || lower === 'zh-hk'
    || lower === 'zh-mo'
  ) {
    return 'zh-Hant';
  }
  const language = lower.split('-')[0] ?? lower;
  if ((FORM_CONTENT_LOCALES as readonly string[]).includes(language)) {
    return language;
  }
  return normalized;
}

/**
 * First preferred locale that is in [supportedLocales], else [defaultLocale].
 * Preferred tags are normalized (e.g. `ja-JP` → `ja`).
 */
export function resolveFormContentLocale(
  preferredLocales: readonly string[],
  supportedLocales: readonly string[],
  defaultLocale: string = DEFAULT_FORM_CONTENT_LOCALE,
): string {
  const orderedSupported: string[] = [];
  for (const locale of supportedLocales) {
    const normalized = normalizeFormContentLocale(locale);
    if (!orderedSupported.includes(normalized)) {
      orderedSupported.push(normalized);
    }
  }
  if (orderedSupported.length === 0) {
    return normalizeFormContentLocale(defaultLocale);
  }

  const normalizedDefault = normalizeFormContentLocale(defaultLocale);
  const fallback = orderedSupported.includes(normalizedDefault)
    ? normalizedDefault
    : orderedSupported[0]!;

  for (const preferred of preferredLocales) {
    const candidate = normalizeFormContentLocale(preferred);
    if (orderedSupported.includes(candidate)) return candidate;
  }
  return fallback;
}

/** Parse an Accept-Language header into tags ordered by quality (highest first). */
export function preferredLocalesFromAcceptLanguage(
  header: string | null | undefined,
): string[] {
  if (!header?.trim()) return [];
  return header
    .split(',')
    .map((part) => {
      const [tagPart, ...params] = part.trim().split(';');
      const tag = tagPart?.trim() ?? '';
      let quality = 1;
      for (const param of params) {
        const match = param.trim().match(/^q=([0-9.]+)$/i);
        if (match) {
          const parsed = Number(match[1]);
          if (!Number.isNaN(parsed)) quality = parsed;
        }
      }
      return { tag, quality };
    })
    .filter((item) => item.tag.length > 0 && item.tag !== '*')
    .sort((a, b) => b.quality - a.quality)
    .map((item) => item.tag);
}

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
