import type { Env } from './types';
import { getIntegrationSettingsRow } from './admin_settings';
import { HttpError, isChoiceQuestionType, isTextQuestionType, json, normalizeQuestionType, readJson, requireString } from './utils';

const GEMINI_MODEL = 'gemini-3.5-flash';
const LOCALES = ['en', 'ja', 'zh-Hans', 'zh-Hant', 'ko', 'de'] as const;

export async function generateSurveyQuestions(request: Request, env: Env): Promise<Response> {
  const settings = await getIntegrationSettingsRow(env);
  const apiKey = settings?.gemini_api_key;
  if (!apiKey) throw new HttpError(400, 'Gemini API key is not configured');

  const body = await readJson(request);
  const prompt = requireString(body.prompt, 'prompt');

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`,
    {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-goog-api-key': apiKey,
      },
      body: JSON.stringify(geminiRequestBody(prompt)),
    },
  );
  const payload = await response.json().catch(() => null);
  if (!response.ok) {
    const message = geminiErrorMessage(payload) ?? 'Gemini request failed';
    throw new HttpError(response.status, message, payload);
  }

  const text = extractGeminiText(payload);
  const decoded = parseGeneratedQuestions(text);
  return json(decoded.map(normalizeGeneratedQuestion));
}

function geminiRequestBody(prompt: string) {
  return {
    contents: [
      {
        parts: [
          {
            text: [
              'Generate concise survey questions for Form Concierge.',
              'Return only questions that fit the requested survey.',
              'Use every locale in the schema. Keep translations natural and short.',
              'For choice questions, provide two to six choices.',
              'For text questions, provide an empty choiceTranslations array.',
              '',
              `Survey request: ${prompt}`,
            ].join('\n'),
          },
        ],
      },
    ],
    generationConfig: {
      temperature: 0.4,
      responseFormat: {
        text: {
          mimeType: 'application/json',
          schema: questionSchema(),
        },
      },
    },
  };
}

function questionSchema() {
  const localizedTextSchema = {
    type: 'object',
    properties: Object.fromEntries(LOCALES.map((locale) => [locale, { type: 'string' }])),
    required: [...LOCALES],
  };
  return {
    type: 'array',
    items: {
      type: 'object',
      properties: {
        textTranslations: localizedTextSchema,
        type: {
          type: 'string',
          enum: ['singleChoice', 'multipleChoice', 'textSingle', 'textMultiLine'],
        },
        isRequired: { type: 'boolean' },
        placeholderTranslations: localizedTextSchema,
        minLength: { type: ['integer', 'null'] },
        maxLength: { type: ['integer', 'null'] },
        minSelected: { type: ['integer', 'null'] },
        maxSelected: { type: ['integer', 'null'] },
        visibilityConditionMode: { type: 'string', enum: ['all', 'any'] },
        choiceTranslations: {
          type: 'array',
          items: localizedTextSchema,
        },
      },
      required: [
        'textTranslations',
        'type',
        'isRequired',
        'placeholderTranslations',
        'visibilityConditionMode',
        'choiceTranslations',
      ],
    },
  };
}

function geminiErrorMessage(payload: unknown): string | null {
  if (!payload || typeof payload !== 'object') return null;
  const error = (payload as { error?: unknown }).error;
  if (!error || typeof error !== 'object') return null;
  const message = (error as { message?: unknown }).message;
  return typeof message === 'string' ? message : null;
}

function extractGeminiText(payload: unknown): string {
  const candidates = (payload as { candidates?: unknown })?.candidates;
  if (!Array.isArray(candidates)) throw new HttpError(502, 'Gemini returned no candidates');
  const parts = (candidates[0] as { content?: { parts?: unknown } })?.content?.parts;
  if (!Array.isArray(parts)) throw new HttpError(502, 'Gemini returned no content');
  const text = parts
    .map((part) => (part as { text?: unknown }).text)
    .filter((value): value is string => typeof value === 'string')
    .join('');
  if (!text.trim()) throw new HttpError(502, 'Gemini returned empty content');
  return text;
}

function parseGeneratedQuestions(text: string): unknown[] {
  try {
    const decoded = JSON.parse(text);
    if (!Array.isArray(decoded)) throw new Error('not array');
    return decoded;
  } catch {
    throw new HttpError(502, 'Gemini returned invalid question JSON');
  }
}

function normalizeGeneratedQuestion(value: unknown) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpError(502, 'Gemini returned an invalid question');
  }
  const input = value as Record<string, unknown>;
  const type = normalizeQuestionType(input.type);
  const choices = normalizeChoiceTranslations(input.choiceTranslations);
  if (isChoiceQuestionType(type) && choices.length === 0) {
    throw new HttpError(502, 'Gemini returned a choice question without choices');
  }
  if (isTextQuestionType(type) && choices.length > 0) {
    throw new HttpError(502, 'Gemini returned a text question with choices');
  }
  return {
    textTranslations: normalizeLocalizedText(input.textTranslations, 'Question'),
    type,
    isRequired: input.isRequired !== false,
    placeholderTranslations: normalizeLocalizedText(input.placeholderTranslations, ''),
    minLength: nullableInteger(input.minLength),
    maxLength: nullableInteger(input.maxLength),
    minSelected: nullableInteger(input.minSelected),
    maxSelected: nullableInteger(input.maxSelected),
    visibilityConditionMode: input.visibilityConditionMode === 'any' ? 'any' : 'all',
    choiceTranslations: choices,
  };
}

function normalizeChoiceTranslations(value: unknown): Record<string, string>[] {
  if (!Array.isArray(value)) return [];
  return value.map((item) => normalizeLocalizedText(item, 'Choice'));
}

function normalizeLocalizedText(value: unknown, fallback: string): Record<string, string> {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpError(502, 'Gemini returned invalid localized text');
  }
  const raw = value as Record<string, unknown>;
  const primary = stringValue(raw.en) || fallback;
  return Object.fromEntries(
    LOCALES.map((locale) => [locale, stringValue(raw[locale]) || primary]),
  );
}

function nullableInteger(value: unknown): number | null {
  if (value == null || value === '') return null;
  const number = Number(value);
  return Number.isInteger(number) ? number : null;
}

function stringValue(value: unknown): string {
  return typeof value === 'string' ? value.trim() : '';
}
