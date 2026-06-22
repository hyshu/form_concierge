import type { Env } from './types';
import type { AiProvider } from './admin_settings';
import { apiKeyForProvider, getIntegrationSettingsRow, normalizeAiProvider } from './admin_settings';
import { HttpError, isChoiceQuestionType, isTextQuestionType, json, normalizeQuestionType, readJson, requireString } from './utils';

const GEMINI_MODEL = 'gemini-3.5-flash';
const OPENAI_MODEL = 'gpt-5.5';
const CLAUDE_MODEL = 'claude-sonnet-4-6';
const CEREBRAS_MODEL = 'gpt-oss-120b';
const LOCALES = ['en', 'ja', 'zh-Hans', 'zh-Hant', 'ko', 'de'] as const;

export async function generateSurveyQuestions(request: Request, env: Env): Promise<Response> {
  const settings = await getIntegrationSettingsRow(env);
  if (!settings) throw new HttpError(400, 'AI generation provider is not configured');
  const provider = normalizeAiProvider(settings.ai_provider);
  const apiKey = apiKeyForProvider(settings, provider);
  if (!apiKey) throw new HttpError(400, `${providerLabel(provider)} API key is not configured`);

  const body = await readJson(request);
  const prompt = requireString(body.prompt, 'prompt');

  const text = await generateQuestionsJson({ provider, apiKey, prompt });
  const decoded = parseGeneratedQuestions(text, provider);
  return json(decoded.map((question) => normalizeGeneratedQuestion(question, provider)));
}

async function generateQuestionsJson(input: {
  provider: AiProvider;
  apiKey: string;
  prompt: string;
}): Promise<string> {
  switch (input.provider) {
    case 'gemini':
      return generateWithGemini(input.apiKey, input.prompt);
    case 'openai':
      return generateWithOpenAiCompatible({
        apiKey: input.apiKey,
        model: OPENAI_MODEL,
        endpoint: 'https://api.openai.com/v1/chat/completions',
        provider: input.provider,
      }, input.prompt);
    case 'claude':
      return generateWithClaude(input.apiKey, input.prompt);
    case 'cerebras':
      return generateWithOpenAiCompatible({
        apiKey: input.apiKey,
        model: CEREBRAS_MODEL,
        endpoint: 'https://api.cerebras.ai/v1/chat/completions',
        provider: input.provider,
      }, input.prompt);
  }
}

async function generateWithGemini(apiKey: string, prompt: string): Promise<string> {
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
    const message = providerErrorMessage(payload) ?? 'Gemini request failed';
    throw new HttpError(response.status, message, payload);
  }

  return extractGeminiText(payload);
}

async function generateWithOpenAiCompatible(
  config: {
    apiKey: string;
    model: string;
    endpoint: string;
    provider: AiProvider;
  },
  prompt: string,
): Promise<string> {
  const response = await fetch(config.endpoint, {
    method: 'POST',
    headers: {
      'authorization': `Bearer ${config.apiKey}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: config.model,
      messages: [
        { role: 'system', content: systemInstruction() },
        { role: 'user', content: `Survey request: ${prompt}` },
      ],
      max_completion_tokens: 4096,
      response_format: {
        type: 'json_schema',
        json_schema: {
          name: 'survey_questions',
          strict: true,
          schema: questionListSchema(),
        },
      },
    }),
  });
  const payload = await response.json().catch(() => null);
  if (!response.ok) {
    const message = providerErrorMessage(payload) ?? `${providerLabel(config.provider)} request failed`;
    throw new HttpError(response.status, message, payload);
  }
  return extractOpenAiCompatibleText(payload, config.provider);
}

async function generateWithClaude(apiKey: string, prompt: string): Promise<string> {
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'anthropic-beta': 'structured-outputs-2025-11-13',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: CLAUDE_MODEL,
      max_tokens: 4096,
      system: systemInstruction(),
      messages: [
        { role: 'user', content: `Survey request: ${prompt}` },
      ],
      output_config: {
        effort: 'low',
        format: {
          type: 'json_schema',
          schema: questionListSchema(),
        },
      },
    }),
  });
  const payload = await response.json().catch(() => null);
  if (!response.ok) {
    const message = providerErrorMessage(payload) ?? 'Claude request failed';
    throw new HttpError(response.status, message, payload);
  }
  return extractClaudeText(payload);
}

function geminiRequestBody(prompt: string) {
  return {
    contents: [
      {
        parts: [
          {
            text: [
              systemInstruction(),
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
          schema: questionListSchema(),
        },
      },
    },
  };
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
    if (Array.isArray(decoded)) return decoded;
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
    textTranslations: normalizeLocalizedText(input.textTranslations, 'Question', provider),
    type,
    isRequired: input.isRequired !== false,
    placeholderTranslations: normalizeLocalizedText(input.placeholderTranslations, '', provider),
    minLength: nullableInteger(input.minLength),
    maxLength: nullableInteger(input.maxLength),
    minSelected: nullableInteger(input.minSelected),
    maxSelected: nullableInteger(input.maxSelected),
    visibilityConditionMode: input.visibilityConditionMode === 'any' ? 'any' : 'all',
    choiceTranslations: choices,
  };
}

function normalizeChoiceTranslations(value: unknown, provider: AiProvider): Record<string, string>[] {
  if (!Array.isArray(value)) return [];
  return value.map((item) => normalizeLocalizedText(item, 'Choice', provider));
}

function normalizeLocalizedText(value: unknown, fallback: string, provider: AiProvider): Record<string, string> {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpError(502, `${providerLabel(provider)} returned invalid localized text`);
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
