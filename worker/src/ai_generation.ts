import type { Env } from './types';
import type { AiProvider } from './admin_settings';
import {
  apiKeyForProvider,
  getIntegrationSettingsRow,
  normalizeAiProvider,
} from './admin_settings';
import {
  HttpError,
  MEDIA_MAX_FILES,
  isChoiceQuestionType,
  isImageUploadQuestionType,
  isTextQuestionType,
  json,
  normalizeQuestionType,
  readJson,
  requireString,
} from './utils';

const DEFAULT_MODELS: Record<AiProvider, string> = {
  gemini: 'gemini-3.5-flash',
  openai: 'gpt-5.5',
  claude: 'claude-sonnet-4-6',
  groq: 'openai/gpt-oss-120b',
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
  'response',
] as const;
type TranslationFieldKind = (typeof TRANSLATION_FIELD_KINDS)[number];

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

export type FollowUpGeneratedItem = {
  id: string;
  type: string;
  text: string;
  required: boolean;
  placeholder: string | null;
  maxFiles: number | null;
  choices: { id: string; label: string }[];
};

export type FollowUpGenerationResult = {
  needed: boolean;
  items: FollowUpGeneratedItem[];
};

/** Generate optional adaptive follow-up questions from main-form answers. */
export async function generateFollowUpFromAnswers(
  env: Env,
  input: {
    surveyTitle: string;
    locale: string;
    answersSummary: string;
    deviceContext: string;
    recentResponsesSummary: string;
    /** Optional admin-authored AI follow-up guidance in the user prompt. */
    followUpPrompt?: string | null;
  },
): Promise<FollowUpGenerationResult> {
  const { provider, apiKey } = await requireAiProvider(env);
  const model = resolveModelId(env, provider);
  const adminPrompt = input.followUpPrompt?.trim() ?? '';
  const userSections = [
    `Survey title: ${input.surveyTitle}`,
    `Respondent locale: ${input.locale}`,
    '',
    'Already known device / app metadata for this submission (do NOT ask for any of this again):',
    input.deviceContext,
    '',
    'Current response answers:',
    input.answersSummary,
    '',
    "This respondent's prior responses on this survey within the last 30 days (context only; do not re-ask these):",
    input.recentResponsesSummary,
  ];
  if (adminPrompt.length > 0) {
    userSections.push(
      '',
      'Survey-specific AI follow-up instructions from the administrator (incorporate these when deciding questions):',
      adminPrompt,
    );
  }
  const text = await generateStructuredJson({
    provider,
    apiKey,
    model,
    system: followUpSystemInstruction(input.locale),
    user: userSections.join('\n'),
    schemaName: 'follow_up_interview',
    schema: followUpSchema(),
    maxTokens: 2048,
  });
  return parseFollowUpGeneration(text, provider);
}

function followUpSystemInstruction(locale: string): string {
  return [
    'You decide whether a short adaptive follow-up interview is useful after a survey.',
    'Only ask follow-up questions when answers are incomplete, ambiguous, or worth clarifying.',
    'If answers are already complete and clear, set needed to false and return an empty items array.',
    'When needed is true, return 1 to 4 concise follow-up questions.',
    `Write all question text, placeholders, and choice labels in locale "${locale}".`,
    'Use only these types: singleChoice, multipleChoice, textSingle, textMultiLine, imageUpload.',
    'For choice questions provide 2 to 6 choices. For text and imageUpload questions use an empty choices array.',
    'Use imageUpload when a photo, screenshot, or receipt would clarify the response (bugs, damage, UI issues, product condition).',
    'Do not request images for pure opinion or demographic questions.',
    'At most one imageUpload item per follow-up.',
    'Every follow-up question MUST have required=false. Respondents may skip all of them.',
    'Do not re-ask the same main survey questions.',
    // Device / app telemetry is captured automatically at submit time.
    'NEVER ask for device type, device model, manufacturer, platform, OS name, OS version, browser, browser version, app name, app version, app build, screen size, locale, timezone, user agent, or similar technical environment details. That data is already provided in the prompt.',
    'Use recent responses only as background context for better follow-ups; do not copy them verbatim as questions.',
    'Prefer product, feedback, or clarification questions over technical diagnostics.',
    'Return JSON only.',
  ].join('\n');
}

function followUpSchema() {
  return {
    type: 'object',
    additionalProperties: false,
    properties: {
      needed: { type: 'boolean' },
      items: {
        type: 'array',
        items: {
          type: 'object',
          additionalProperties: false,
          properties: {
            type: {
              type: 'string',
              enum: [
                'singleChoice',
                'multipleChoice',
                'textSingle',
                'textMultiLine',
                'imageUpload',
              ],
            },
            text: { type: 'string' },
            required: { type: 'boolean' },
            placeholder: { type: ['string', 'null'] },
            maxFiles: { type: ['integer', 'null'] },
            choices: {
              type: 'array',
              items: {
                type: 'object',
                additionalProperties: false,
                properties: {
                  label: { type: 'string' },
                },
                required: ['label'],
              },
            },
          },
          required: ['type', 'text', 'required', 'placeholder', 'maxFiles', 'choices'],
        },
      },
    },
    required: ['needed', 'items'],
  };
}

function parseFollowUpGeneration(text: string, provider: AiProvider): FollowUpGenerationResult {
  let decoded: unknown;
  try {
    decoded = JSON.parse(text);
  } catch {
    throw new HttpError(502, `${providerLabel(provider)} returned invalid follow-up JSON`);
  }
  if (!decoded || typeof decoded !== 'object' || Array.isArray(decoded)) {
    throw new HttpError(502, `${providerLabel(provider)} returned invalid follow-up JSON`);
  }
  const raw = decoded as Record<string, unknown>;
  if (typeof raw.needed !== 'boolean') {
    throw new HttpError(502, `${providerLabel(provider)} returned invalid needed flag`);
  }
  if (!Array.isArray(raw.items)) {
    throw new HttpError(502, `${providerLabel(provider)} returned invalid follow-up items`);
  }
  if (!raw.needed) {
    return { needed: false, items: [] };
  }
  if (raw.items.length === 0) {
    return { needed: false, items: [] };
  }
  if (raw.items.length > 4) {
    throw new HttpError(502, `${providerLabel(provider)} returned too many follow-up items`);
  }

  const items: FollowUpGeneratedItem[] = raw.items.map((item, index) => {
    if (!item || typeof item !== 'object' || Array.isArray(item)) {
      throw new HttpError(502, `${providerLabel(provider)} returned an invalid follow-up item`);
    }
    const row = item as Record<string, unknown>;
    const type = normalizeQuestionType(row.type);
    const textValue = typeof row.text === 'string' ? row.text.trim() : '';
    if (!textValue) {
      throw new HttpError(502, `${providerLabel(provider)} returned empty follow-up text`);
    }
    // Accept required from the model for schema compatibility, but always store false.
    if (row.required != null && typeof row.required !== 'boolean') {
      throw new HttpError(502, `${providerLabel(provider)} returned invalid required flag`);
    }
    const placeholder =
      row.placeholder == null
        ? null
        : typeof row.placeholder === 'string'
          ? row.placeholder.trim() || null
          : null;
    if (!Array.isArray(row.choices)) {
      throw new HttpError(502, `${providerLabel(provider)} returned invalid follow-up choices`);
    }
    const choices = row.choices.map((choice, choiceIndex) => {
      if (!choice || typeof choice !== 'object' || Array.isArray(choice)) {
        throw new HttpError(502, `${providerLabel(provider)} returned invalid follow-up choice`);
      }
      const label = (choice as { label?: unknown }).label;
      if (typeof label !== 'string' || label.trim().length === 0) {
        throw new HttpError(
          502,
          `${providerLabel(provider)} returned empty follow-up choice label`,
        );
      }
      return {
        id: `c${choiceIndex + 1}`,
        label: label.trim(),
      };
    });
    if (isChoiceQuestionType(type) && (choices.length < 2 || choices.length > 6)) {
      throw new HttpError(502, `${providerLabel(provider)} returned invalid choice count`);
    }
    if ((isTextQuestionType(type) || isImageUploadQuestionType(type)) && choices.length > 0) {
      throw new HttpError(
        502,
        `${providerLabel(provider)} returned non-choice follow-up with choices`,
      );
    }
    let maxFiles: number | null = null;
    if (isImageUploadQuestionType(type)) {
      if (row.maxFiles == null) {
        maxFiles = 1;
      } else if (
        typeof row.maxFiles === 'number' &&
        Number.isSafeInteger(row.maxFiles) &&
        row.maxFiles >= 1 &&
        row.maxFiles <= MEDIA_MAX_FILES
      ) {
        maxFiles = row.maxFiles;
      } else {
        throw new HttpError(502, `${providerLabel(provider)} returned invalid maxFiles`);
      }
    }
    return {
      id: `fu_${index + 1}`,
      type,
      text: textValue,
      // Follow-up is always optional; respondents may skip every item.
      required: false,
      placeholder: isTextQuestionType(type) ? placeholder : null,
      maxFiles,
      choices: isChoiceQuestionType(type) ? choices : [],
    };
  });

  const imageCount = items.filter((item) => isImageUploadQuestionType(item.type)).length;
  if (imageCount > 1) {
    throw new HttpError(502, `${providerLabel(provider)} returned multiple imageUpload items`);
  }

  return { needed: true, items };
}

export async function translateLocalizedText(request: Request, env: Env): Promise<Response> {
  const { provider, apiKey } = await requireAiProvider(env);

  const body = await readJson(request);
  const fieldKind = optionalTranslationFieldKind(body.fieldKind);
  const sourceLocale = fieldKind === 'response'
    ? requireResponseSourceLocale(body.sourceLocale)
    : requireLocaleCode(body.sourceLocale, 'sourceLocale');
  const sourceText = requireString(body.sourceText, 'sourceText').trim();
  if (sourceText.length === 0) throw new HttpError(400, 'sourceText is required');
  if (sourceText.length > MAX_SOURCE_TEXT_LENGTH) {
    throw new HttpError(400, `sourceText must be ${MAX_SOURCE_TEXT_LENGTH} characters or fewer`);
  }
  const targetLocales = requireTargetLocales(
    body.targetLocales,
    sourceLocale,
    fieldKind === 'response',
  );

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
    ]
      .filter(Boolean)
      .join('\n'),
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
  const apiKey = await apiKeyForProvider(env, provider);
  if (!apiKey) throw new HttpError(400, `${providerLabel(provider)} API key is not configured`);
  return { provider, apiKey };
}

/** Prefer env override (AI_*_MODEL) so deprecations do not require a code deploy. */
function resolveModelId(env: Env, provider: AiProvider): string {
  const envKey = {
    gemini: 'AI_GEMINI_MODEL',
    openai: 'AI_OPENAI_MODEL',
    claude: 'AI_CLAUDE_MODEL',
    groq: 'AI_GROQ_MODEL',
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
    case 'groq':
      return generateWithOpenAiCompatible({
        ...input,
        endpoint: 'https://api.groq.com/openai/v1/chat/completions',
      });
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
      authorization: `Bearer ${input.apiKey}`,
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
    const message =
      providerErrorMessage(payload) ?? `${providerLabel(input.provider)} request failed`;
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
      messages: [{ role: 'user', content: input.user }],
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
    'Use only these types: singleChoice, multipleChoice, textSingle, textMultiLine, imageUpload.',
    'For choice questions, provide two to six choices.',
    'For text and imageUpload questions, provide an empty choiceTranslations array.',
    'Use imageUpload when respondents should attach a photo, screenshot, or receipt.',
    'For imageUpload set minSelected/maxSelected to the allowed image count (1-3); otherwise null.',
    'Return JSON only.',
  ].join('\n');
}

function translationSystemInstruction(
  sourceLocale: string,
  fieldKind: TranslationFieldKind | null,
): string {
  const isResponse = fieldKind === 'response';
  return [
    isResponse
      ? 'You translate a Form Concierge survey respondent answer.'
      : 'You translate Form Concierge survey copy.',
    sourceLocale === 'auto'
      ? 'Detect the source language from the answer before translating.'
      : `Source language code: ${sourceLocale}.`,
    fieldKind && !isResponse ? `This text is a survey ${fieldKind}.` : null,
    'Translate into every requested target locale key.',
    'Keep meaning, tone, and length natural for that language.',
    'Preserve placeholders such as {count}, {title}, or {name} exactly.',
    'Do not add quotes, labels, or explanations.',
    'Return JSON only.',
  ]
    .filter(Boolean)
    .join('\n');
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
  if (!LOCALES.includes(locale as (typeof LOCALES)[number])) {
    throw new HttpError(400, `${field} is not a supported locale`);
  }
  return locale;
}

function requireResponseSourceLocale(value: unknown): string {
  const locale = requireString(value, 'sourceLocale').trim();
  if (locale === 'auto') return locale;
  if (!/^[A-Za-z]{2,3}(?:[-_][A-Za-z0-9]{2,8})*$/.test(locale)) {
    throw new HttpError(400, 'sourceLocale is not a valid locale');
  }
  return locale;
}

function requireTargetLocales(
  value: unknown,
  sourceLocale: string,
  allowAnyLocale = false,
): string[] {
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
    const isSupported = LOCALES.includes(item as (typeof LOCALES)[number]);
    const isValidResponseLocale =
      allowAnyLocale && /^[A-Za-z]{2,3}(?:[-_][A-Za-z0-9]{2,8})*$/.test(item);
    if (!isSupported && !isValidResponseLocale) {
      throw new HttpError(
        400,
        `targetLocales[${index}] is not a valid locale`,
      );
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
        enum: ['singleChoice', 'multipleChoice', 'textSingle', 'textMultiLine', 'imageUpload'],
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
    case 'groq':
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
    result.type === 'object' ||
    (properties != null && typeof properties === 'object' && !Array.isArray(properties));

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
  if (!Array.isArray(choices))
    throw new HttpError(502, `${providerLabel(provider)} returned no choices`);
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
    throw new HttpError(
      502,
      `${providerLabel(provider)} returned a choice question without choices`,
    );
  }
  if ((isTextQuestionType(type) || isImageUploadQuestionType(type)) && choices.length > 0) {
    throw new HttpError(
      502,
      `${providerLabel(provider)} returned a non-choice question with choices`,
    );
  }
  let minSelected = nullableInteger(input.minSelected, 'minSelected', provider);
  let maxSelected = nullableInteger(input.maxSelected, 'maxSelected', provider);
  if (isImageUploadQuestionType(type)) {
    if (maxSelected == null) maxSelected = 1;
    if (maxSelected < 1 || maxSelected > MEDIA_MAX_FILES) {
      throw new HttpError(502, `${providerLabel(provider)} returned invalid image maxSelected`);
    }
    if (minSelected != null && (minSelected < 0 || minSelected > maxSelected)) {
      throw new HttpError(502, `${providerLabel(provider)} returned invalid image minSelected`);
    }
  }
  return {
    textTranslations: normalizeLocalizedText(input.textTranslations, provider),
    type,
    isRequired: normalizeRequiredBoolean(input.isRequired, 'isRequired', provider),
    placeholderTranslations: normalizeLocalizedText(input.placeholderTranslations, provider),
    minLength: isTextQuestionType(type)
      ? nullableInteger(input.minLength, 'minLength', provider)
      : null,
    maxLength: isTextQuestionType(type)
      ? nullableInteger(input.maxLength, 'maxLength', provider)
      : null,
    minSelected: isChoiceQuestionType(type) || isImageUploadQuestionType(type) ? minSelected : null,
    maxSelected: isChoiceQuestionType(type) || isImageUploadQuestionType(type) ? maxSelected : null,
    visibilityConditionMode: normalizeVisibilityConditionMode(
      input.visibilityConditionMode,
      provider,
    ),
    choiceTranslations: choices,
  };
}

function normalizeChoiceTranslations(
  value: unknown,
  provider: AiProvider,
): Record<string, string>[] {
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
    throw new HttpError(
      502,
      `${providerLabel(provider)} returned missing localized text for ${locale}`,
    );
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
    case 'groq':
      return 'Groq';
  }
}
