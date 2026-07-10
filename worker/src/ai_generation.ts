import type { Env } from './types';
import type { AiProvider } from './admin_settings';
import { apiKeyForProvider, getIntegrationSettingsRow, normalizeAiProvider } from './admin_settings';
import { HttpError, isChoiceQuestionType, isTextQuestionType, json, normalizeQuestionType, readJson, requireString } from './utils';

const DEFAULT_MODELS: Record<AiProvider, string> = {
  gemini: 'gemini-3.5-flash',
  openai: 'gpt-5.5',
  claude: 'claude-sonnet-4-6',
  cerebras: 'gpt-oss-120b',
};
const MAX_PROMPT_LENGTH = 4_000;
const LOCALES = [
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

const MAX_SOURCE_TEXT_LENGTH = 2_000;
const TRANSLATION_FIELD_KINDS = [
  'title',
  'description',
  'question',
  'placeholder',
  'choice',
] as const;
type TranslationFieldKind = typeof TRANSLATION_FIELD_KINDS[number];

export async function generateSurveyQuestions(request: Request, env: Env): Promise<Response> {
  const { provider, apiKey } = await requireAiProvider(env);

  const body = await readJson(request);
  const prompt = requireString(body.prompt, 'prompt');
  if (prompt.length > MAX_PROMPT_LENGTH) {
    throw new HttpError(400, `prompt must be ${MAX_PROMPT_LENGTH} characters or fewer`);
  }

  const model = resolveModelId(env, provider);
  const text = await generateStructuredJson({
    provider,
    apiKey,
    model,
    system: systemInstruction(),
    user: `Survey request: ${prompt}`,
    schemaName: 'survey_questions',
    schema: questionListSchema(),
    maxTokens: 4096,
  });
  const decoded = parseGeneratedQuestions(text, provider);
  return json(decoded.map((question) => normalizeGeneratedQuestion(question, provider)));
}

export async function translateLocalizedText(request: Request, env: Env): Promise<Response> {
  const { provider, apiKey } = await requireAiProvider(env);

  const body = await readJson(request);
  const sourceLocale = requireLocaleCode(body.sourceLocale, 'sourceLocale');
  const sourceText = requireString(body.sourceText, 'sourceText').trim();
  if (sourceText.length === 0) throw new HttpError(400, 'sourceText is required');
  if (sourceText.length > MAX_SOURCE_TEXT_LENGTH) {
    throw new HttpError(400, `sourceText must be ${MAX_SOURCE_TEXT_LENGTH} characters or fewer`);
  }
  const targetLocales = requireTargetLocales(body.targetLocales, sourceLocale);
  const fieldKind = optionalTranslationFieldKind(body.fieldKind);

  const model = resolveModelId(env, provider);
  const text = await generateStructuredJson({
    provider,
    apiKey,
    model,
    system: translationSystemInstruction(sourceLocale, fieldKind),
    user: [
      `Source locale: ${sourceLocale}`,
      `Target locales: ${targetLocales.join(', ')}`,
      fieldKind ? `Field kind: ${fieldKind}` : null,
      'Source text:',
      sourceText,
    ].filter(Boolean).join('\n'),
    schemaName: 'localized_translations',
    schema: translationSchema(targetLocales),
    maxTokens: 2048,
  });
  return json({
    translations: parseTranslations(text, targetLocales, provider),
  });
}

async function requireAiProvider(env: Env): Promise<{ provider: AiProvider; apiKey: string }> {
  const settings = await getIntegrationSettingsRow(env);
  if (!settings) throw new HttpError(400, 'AI generation provider is not configured');
  const provider = normalizeAiProvider(settings.ai_provider);
  const apiKey = apiKeyForProvider(settings, provider);
  if (!apiKey) throw new HttpError(400, `${providerLabel(provider)} API key is not configured`);
  return { provider, apiKey };
}

/** Prefer env override (AI_*_MODEL) so deprecations do not require a code deploy. */
function resolveModelId(env: Env, provider: AiProvider): string {
  const envKey = {
    gemini: 'AI_GEMINI_MODEL',
    openai: 'AI_OPENAI_MODEL',
    claude: 'AI_CLAUDE_MODEL',
    cerebras: 'AI_CEREBRAS_MODEL',
  }[provider];
  const override = (env as unknown as Record<string, unknown>)[envKey];
  if (typeof override === 'string' && override.trim().length > 0) return override.trim();
  return DEFAULT_MODELS[provider];
}

type StructuredJsonRequest = {
  provider: AiProvider;
  apiKey: string;
  model: string;
  system: string;
  user: string;
  schemaName: string;
  schema: Record<string, unknown>;
  maxTokens: number;
};

async function generateStructuredJson(input: StructuredJsonRequest): Promise<string> {
  switch (input.provider) {
    case 'gemini':
      return generateWithGemini(input);
    case 'openai':
      return generateWithOpenAiCompatible({
        ...input,
        endpoint: 'https://api.openai.com/v1/chat/completions',
      });
    case 'claude':
      return generateWithClaude(input);
    case 'cerebras':
      return generateWithOpenAiCompatible({
        ...input,
        endpoint: 'https://api.cerebras.ai/v1/chat/completions',
      });
  }
}

async function generateWithGemini(input: StructuredJsonRequest): Promise<string> {
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${input.model}:generateContent`,
    {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-goog-api-key': input.apiKey,
      },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              {
                text: [input.system, '', input.user].join('\n'),
              },
            ],
          },
        ],
        generationConfig: {
          temperature: 0.2,
          responseMimeType: 'application/json',
          responseSchema: toProviderSchema(input.provider, input.schema),
        },
      }),
    },
  );
  const payload = await response.json().catch(() => null);
  if (!response.ok) {
    const message = providerErrorMessage(payload) ?? 'Gemini request failed';
    // Do not forward upstream payload details to clients.
    throw new HttpError(response.status >= 500 ? 502 : 400, message);
  }

  return extractGeminiText(payload);
}

async function generateWithOpenAiCompatible(
  input: StructuredJsonRequest & { endpoint: string },
): Promise<string> {
  const response = await fetch(input.endpoint, {
    method: 'POST',
    headers: {
      'authorization': `Bearer ${input.apiKey}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: input.model,
      messages: [
        { role: 'system', content: input.system },
        { role: 'user', content: input.user },
      ],
      max_completion_tokens: input.maxTokens,
      response_format: {
        type: 'json_schema',
        json_schema: {
          name: input.schemaName,
          strict: true,
          schema: toProviderSchema(input.provider, input.schema),
        },
      },
    }),
  });
  const payload = await response.json().catch(() => null);
  if (!response.ok) {
    const message = providerErrorMessage(payload) ?? `${providerLabel(input.provider)} request failed`;
    throw new HttpError(response.status >= 500 ? 502 : 400, message);
  }
  return extractOpenAiCompatibleText(payload, input.provider);
}

async function generateWithClaude(input: StructuredJsonRequest): Promise<string> {
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': input.apiKey,
      'anthropic-version': '2023-06-01',
      'anthropic-beta': 'structured-outputs-2025-11-13',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: input.model,
      max_tokens: input.maxTokens,
      system: input.system,
      messages: [
        { role: 'user', content: input.user },
      ],
      output_config: {
        effort: 'low',
        format: {
          type: 'json_schema',
          schema: toProviderSchema(input.provider, input.schema),
        },
      },
    }),
  });
  const payload = await response.json().catch(() => null);
  if (!response.ok) {
    const message = providerErrorMessage(payload) ?? 'Claude request failed';
    throw new HttpError(response.status >= 500 ? 502 : 400, message);
  }
  return extractClaudeText(payload);
}

function systemInstruction(): string {
  return [
    'Generate concise survey questions for Form Concierge.',
    'Return only questions that fit the requested survey.',
    'Use every locale in the schema. Keep translations natural and short.',
    'For choice questions, provide two to six choices.',
    'For text questions, provide an empty choiceTranslations array.',
    'Return JSON only.',
  ].join('\n');
}

function translationSystemInstruction(
  sourceLocale: string,
  fieldKind: TranslationFieldKind | null,
): string {
  return [
    'You translate Form Concierge survey copy.',
    `Source language code: ${sourceLocale}.`,
    fieldKind ? `This text is a survey ${fieldKind}.` : null,
    'Translate into every requested target locale key.',
    'Keep meaning, tone, and length natural for that language.',
    'Preserve placeholders such as {count}, {title}, or {name} exactly.',
    'Do not add quotes, labels, or explanations.',
    'Return JSON only.',
  ].filter(Boolean).join('\n');
}

function translationSchema(targetLocales: readonly string[]) {
  return {
    type: 'object',
    additionalProperties: false,
    properties: Object.fromEntries(targetLocales.map((locale) => [locale, { type: 'string' }])),
    required: [...targetLocales],
  };
}

function requireLocaleCode(value: unknown, field: string): string {
  const locale = requireString(value, field);
  if (!LOCALES.includes(locale as typeof LOCALES[number])) {
    throw new HttpError(400, `${field} is not a supported locale`);
  }
  return locale;
}

function requireTargetLocales(value: unknown, sourceLocale: string): string[] {
  if (!Array.isArray(value)) throw new HttpError(400, 'targetLocales must be an array');
  if (value.length === 0) throw new HttpError(400, 'targetLocales must not be empty');
  if (value.length > LOCALES.length) {
    throw new HttpError(400, 'targetLocales has too many items');
  }
  const locales: string[] = [];
  for (const [index, item] of value.entries()) {
    if (typeof item !== 'string') {
      throw new HttpError(400, `targetLocales[${index}] must be a string`);
    }
    if (!LOCALES.includes(item as typeof LOCALES[number])) {
      throw new HttpError(400, `targetLocales[${index}] is not a supported locale`);
    }
    if (item === sourceLocale) {
      throw new HttpError(400, 'targetLocales must not include sourceLocale');
    }
    if (locales.includes(item)) {
      throw new HttpError(400, `targetLocales contains duplicate locale: ${item}`);
    }
    locales.push(item);
  }
  return locales;
}

function optionalTranslationFieldKind(value: unknown): TranslationFieldKind | null {
  if (value == null || value === '') return null;
  if (typeof value !== 'string') throw new HttpError(400, 'fieldKind must be a string');
  if (!(TRANSLATION_FIELD_KINDS as readonly string[]).includes(value)) {
    throw new HttpError(400, 'fieldKind is not supported');
  }
  return value as TranslationFieldKind;
}

function parseTranslations(
  text: string,
  targetLocales: readonly string[],
  provider: AiProvider,
): Record<string, string> {
  let decoded: unknown;
  try {
    decoded = JSON.parse(text);
  } catch {
    throw new HttpError(502, `${providerLabel(provider)} returned invalid translation JSON`);
  }
  if (!decoded || typeof decoded !== 'object' || Array.isArray(decoded)) {
    throw new HttpError(502, `${providerLabel(provider)} returned invalid translation JSON`);
  }
  const raw = decoded as Record<string, unknown>;
  const translations: Record<string, string> = {};
  for (const locale of targetLocales) {
    const value = raw[locale];
    if (typeof value !== 'string' || value.trim().length === 0) {
      throw new HttpError(
        502,
        `${providerLabel(provider)} returned missing translation for ${locale}`,
      );
    }
    translations[locale] = value.trim();
  }
  return translations;
}

function questionListSchema() {
  return {
    type: 'object',
    additionalProperties: false,
    properties: {
      questions: {
        type: 'array',
        items: questionSchema(),
      },
    },
    required: ['questions'],
  };
}

function questionSchema() {
  const localizedTextSchema = {
    type: 'object',
    additionalProperties: false,
    properties: Object.fromEntries(LOCALES.map((locale) => [locale, { type: 'string' }])),
    required: [...LOCALES],
  };
  return {
    type: 'object',
    additionalProperties: false,
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
      'minLength',
      'maxLength',
      'minSelected',
      'maxSelected',
      'visibilityConditionMode',
      'choiceTranslations',
    ],
  };
}

/**
 * Normalize a shared JSON Schema into the dialect expected by each provider.
 *
 * - Gemini (`generateContent.responseSchema`): OpenAPI-like subset. Rejects
 *   `additionalProperties` and prefers `nullable` over `type: [T, "null"]`.
 * - OpenAI / Cerebras (`strict: true`): every object must set
 *   `additionalProperties: false`, and every property key must be listed in
 *   `required` (Cerebras documents the same rule; OpenAI structured outputs too).
 * - Claude: accepts JSON Schema; we still emit a strict-friendly object shape
 *   for consistency with examples that use `additionalProperties: false`.
 */
export function toProviderSchema(provider: AiProvider, schema: unknown): unknown {
  switch (provider) {
    case 'gemini':
      return toGeminiSchema(schema);
    case 'openai':
    case 'cerebras':
    case 'claude':
      return toStrictJsonSchema(schema);
  }
}

/**
 * Gemini Schema is a subset of OpenAPI/JSON Schema and rejects unknown keys
 * such as `additionalProperties`. Union types like `type: ['string', 'null']`
 * should become `type` + `nullable: true`.
 */
function toGeminiSchema(schema: unknown): unknown {
  if (Array.isArray(schema)) {
    return schema.map(toGeminiSchema);
  }
  if (!schema || typeof schema !== 'object') return schema;

  const source = schema as Record<string, unknown>;
  const result: Record<string, unknown> = {};

  for (const [key, value] of Object.entries(source)) {
    if (key === 'additionalProperties') continue;

    if (key === 'type' && Array.isArray(value)) {
      const types = value.filter((item): item is string => typeof item === 'string');
      const nonNull = types.filter((item) => item !== 'null');
      if (types.includes('null') && nonNull.length === 1) {
        result.type = nonNull[0];
        result.nullable = true;
        continue;
      }
      // Fallback: keep the first concrete type if we cannot map cleanly.
      if (nonNull.length > 0) result.type = nonNull[0];
      continue;
    }

    result[key] = toGeminiSchema(value);
  }

  return result;
}

/**
 * Make a schema safe for OpenAI/Cerebras strict structured outputs (and Claude).
 * Ensures every object has `additionalProperties: false` and that `required`
 * lists every key under `properties`.
 */
function toStrictJsonSchema(schema: unknown): unknown {
  if (Array.isArray(schema)) {
    return schema.map(toStrictJsonSchema);
  }
  if (!schema || typeof schema !== 'object') return schema;

  const source = schema as Record<string, unknown>;
  const result: Record<string, unknown> = {};

  for (const [key, value] of Object.entries(source)) {
    result[key] = toStrictJsonSchema(value);
  }

  const properties = result.properties;
  const isObjectSchema =
    result.type === 'object'
    || (properties != null && typeof properties === 'object' && !Array.isArray(properties));

  if (isObjectSchema) {
    result.additionalProperties = false;
    if (properties != null && typeof properties === 'object' && !Array.isArray(properties)) {
      result.required = Object.keys(properties as Record<string, unknown>);
    } else if (!Array.isArray(result.required)) {
      result.required = [];
    }
  }

  return result;
}

function providerErrorMessage(payload: unknown): string | null {
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

function extractOpenAiCompatibleText(payload: unknown, provider: AiProvider): string {
  const choices = (payload as { choices?: unknown })?.choices;
  if (!Array.isArray(choices)) throw new HttpError(502, `${providerLabel(provider)} returned no choices`);
  const content = (choices[0] as { message?: { content?: unknown } })?.message?.content;
  if (typeof content !== 'string' || content.trim().length === 0) {
    throw new HttpError(502, `${providerLabel(provider)} returned empty content`);
  }
  return content;
}

function extractClaudeText(payload: unknown): string {
  const content = (payload as { content?: unknown })?.content;
  if (!Array.isArray(content)) throw new HttpError(502, 'Claude returned no content');
  const text = content
    .map((part) => (part as { text?: unknown }).text)
    .filter((value): value is string => typeof value === 'string')
    .join('');
  if (!text.trim()) throw new HttpError(502, 'Claude returned empty content');
  return text;
}

function parseGeneratedQuestions(text: string, provider: AiProvider): unknown[] {
  try {
    const decoded = JSON.parse(text);
    const questions = (decoded as { questions?: unknown })?.questions;
    if (Array.isArray(questions)) return questions;
    throw new Error('not questions');
  } catch {
    throw new HttpError(502, `${providerLabel(provider)} returned invalid question JSON`);
  }
}

function normalizeGeneratedQuestion(value: unknown, provider: AiProvider) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpError(502, `${providerLabel(provider)} returned an invalid question`);
  }
  const input = value as Record<string, unknown>;
  const type = normalizeQuestionType(input.type);
  const choices = normalizeChoiceTranslations(input.choiceTranslations, provider);
  if (isChoiceQuestionType(type) && choices.length === 0) {
    throw new HttpError(502, `${providerLabel(provider)} returned a choice question without choices`);
  }
  if (isTextQuestionType(type) && choices.length > 0) {
    throw new HttpError(502, `${providerLabel(provider)} returned a text question with choices`);
  }
  return {
    textTranslations: normalizeLocalizedText(input.textTranslations, provider),
    type,
    isRequired: normalizeRequiredBoolean(input.isRequired, 'isRequired', provider),
    placeholderTranslations: normalizeLocalizedText(input.placeholderTranslations, provider),
    minLength: nullableInteger(input.minLength, 'minLength', provider),
    maxLength: nullableInteger(input.maxLength, 'maxLength', provider),
    minSelected: nullableInteger(input.minSelected, 'minSelected', provider),
    maxSelected: nullableInteger(input.maxSelected, 'maxSelected', provider),
    visibilityConditionMode: normalizeVisibilityConditionMode(input.visibilityConditionMode, provider),
    choiceTranslations: choices,
  };
}

function normalizeChoiceTranslations(value: unknown, provider: AiProvider): Record<string, string>[] {
  if (!Array.isArray(value)) {
    throw new HttpError(502, `${providerLabel(provider)} returned invalid choice translations`);
  }
  return value.map((item) => normalizeLocalizedText(item, provider));
}

function normalizeLocalizedText(value: unknown, provider: AiProvider): Record<string, string> {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpError(502, `${providerLabel(provider)} returned invalid localized text`);
  }
  const raw = value as Record<string, unknown>;
  return Object.fromEntries(
    LOCALES.map((locale) => {
      const text = localizedStringValue(raw[locale], locale, provider);
      return [locale, text];
    }),
  );
}

function normalizeRequiredBoolean(value: unknown, field: string, provider: AiProvider): boolean {
  if (typeof value !== 'boolean') {
    throw new HttpError(502, `${providerLabel(provider)} returned invalid boolean for ${field}`);
  }
  return value;
}

function normalizeVisibilityConditionMode(value: unknown, provider: AiProvider): 'all' | 'any' {
  if (value === 'all' || value === 'any') return value;
  throw new HttpError(502, `${providerLabel(provider)} returned invalid visibility condition mode`);
}

function nullableInteger(value: unknown, field: string, provider: AiProvider): number | null {
  if (value == null) return null;
  if (typeof value !== 'number' || !Number.isSafeInteger(value)) {
    throw new HttpError(502, `${providerLabel(provider)} returned invalid integer for ${field}`);
  }
  return value;
}

function localizedStringValue(value: unknown, locale: string, provider: AiProvider): string {
  if (typeof value !== 'string') {
    throw new HttpError(502, `${providerLabel(provider)} returned missing localized text for ${locale}`);
  }
  return value.trim();
}

function providerLabel(provider: AiProvider): string {
  switch (provider) {
    case 'gemini':
      return 'Gemini';
    case 'openai':
      return 'OpenAI';
    case 'claude':
      return 'Claude';
    case 'cerebras':
      return 'Cerebras';
  }
}
