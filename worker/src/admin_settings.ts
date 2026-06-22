import type { Env, IntegrationSettingsRow } from './types';
import { boolToInt, HttpError, json, nowIso, optionalNumber, optionalString, readJson } from './utils';

export type SmtpSecureMode = 'none' | 'starttls' | 'tls';
export type AiProvider = 'gemini' | 'openai' | 'claude' | 'cerebras';

const SETTINGS_ID = 1;
const SMTP_SECURE_MODES = new Set<SmtpSecureMode>(['none', 'starttls', 'tls']);
const AI_PROVIDERS = new Set<AiProvider>(['gemini', 'openai', 'claude', 'cerebras']);

export async function getIntegrationSettingsRow(env: Env): Promise<IntegrationSettingsRow | null> {
  return env.DB.prepare(`SELECT * FROM integration_settings WHERE id = ?`)
    .bind(SETTINGS_ID)
    .first<IntegrationSettingsRow>();
}

export async function getAdminIntegrationSettings(env: Env): Promise<Response> {
  const row = await getIntegrationSettingsRow(env);
  return json(integrationSettingsToJson(row));
}

export async function updateAdminIntegrationSettings(request: Request, env: Env): Promise<Response> {
  const body = await readJson(request);
  const existing = await getIntegrationSettingsRow(env);
  const ai = objectValue(body.ai);
  const smtp = objectValue(body.smtp);
  const aiProvider = optionalAiProvider(ai.provider) ?? normalizeAiProvider(existing?.ai_provider ?? 'gemini');

  const geminiApiKey = secretValue({
    next: ai.geminiApiKey,
    existing: existing?.gemini_api_key ?? null,
    clear: boolToInt(ai.clearGeminiApiKey) === 1,
  });
  const openaiApiKey = secretValue({
    next: ai.openaiApiKey,
    existing: existing?.openai_api_key ?? null,
    clear: boolToInt(ai.clearOpenaiApiKey) === 1,
  });
  const claudeApiKey = secretValue({
    next: ai.claudeApiKey,
    existing: existing?.claude_api_key ?? null,
    clear: boolToInt(ai.clearClaudeApiKey) === 1,
  });
  const cerebrasApiKey = secretValue({
    next: ai.cerebrasApiKey,
    existing: existing?.cerebras_api_key ?? null,
    clear: boolToInt(ai.clearCerebrasApiKey) === 1,
  });

  const smtpHost = optionalHost(smtp.host);
  const smtpPort = optionalPort(smtp.port);
  const smtpUsername = optionalString(smtp.username);
  const smtpPassword = secretValue({
    next: smtp.password,
    existing: existing?.smtp_password ?? null,
    clear: boolToInt(smtp.clearPassword) === 1,
  });
  const smtpFromEmail = optionalEmail(smtp.fromEmail, 'fromEmail');
  const smtpFromName = optionalString(smtp.fromName);
  const smtpSecureMode = optionalSecureMode(smtp.secureMode) ?? existing?.smtp_secure_mode ?? 'starttls';

  assertSmtpSettingsAreCoherent({
    host: smtpHost,
    port: smtpPort,
    fromEmail: smtpFromEmail,
    username: smtpUsername,
    password: smtpPassword,
  });

  const row = await env.DB.prepare(
    `INSERT INTO integration_settings
       (id, ai_provider, gemini_api_key, openai_api_key, claude_api_key, cerebras_api_key,
        smtp_host, smtp_port, smtp_username, smtp_password, smtp_from_email, smtp_from_name,
        smtp_secure_mode, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
     ON CONFLICT(id) DO UPDATE SET
       ai_provider = excluded.ai_provider,
       gemini_api_key = excluded.gemini_api_key,
       openai_api_key = excluded.openai_api_key,
       claude_api_key = excluded.claude_api_key,
       cerebras_api_key = excluded.cerebras_api_key,
       smtp_host = excluded.smtp_host,
       smtp_port = excluded.smtp_port,
       smtp_username = excluded.smtp_username,
       smtp_password = excluded.smtp_password,
       smtp_from_email = excluded.smtp_from_email,
       smtp_from_name = excluded.smtp_from_name,
       smtp_secure_mode = excluded.smtp_secure_mode,
       updated_at = excluded.updated_at
     RETURNING *`,
  ).bind(
    SETTINGS_ID,
    aiProvider,
    geminiApiKey,
    openaiApiKey,
    claudeApiKey,
    cerebrasApiKey,
    smtpHost,
    smtpPort,
    smtpUsername,
    smtpPassword,
    smtpFromEmail,
    smtpFromName,
    smtpSecureMode,
    nowIso(),
  ).first<IntegrationSettingsRow>();

  if (!row) throw new HttpError(500, 'Settings operation failed');
  return json(integrationSettingsToJson(row));
}

export async function isAiGenerationConfigured(env: Env): Promise<boolean> {
  const row = await getIntegrationSettingsRow(env);
  if (!row) return false;
  return Boolean(apiKeyForProvider(row, normalizeAiProvider(row.ai_provider)));
}

export async function isEmailConfiguredResponse(env: Env): Promise<Response> {
  const row = await getIntegrationSettingsRow(env);
  return json({ configured: isSmtpConfigured(row) });
}

export function isSmtpConfigured(row: IntegrationSettingsRow | null): boolean {
  return Boolean(row?.smtp_host && row.smtp_port && row.smtp_from_email);
}

export function requireSmtpSettings(row: IntegrationSettingsRow | null): RequiredSmtpSettings {
  if (!isSmtpConfigured(row)) {
    throw new HttpError(400, 'SMTP settings are not configured');
  }
  return {
    host: row!.smtp_host!,
    port: row!.smtp_port!,
    username: row!.smtp_username,
    password: row!.smtp_password,
    fromEmail: row!.smtp_from_email!,
    fromName: row!.smtp_from_name,
    secureMode: normalizeSecureMode(row!.smtp_secure_mode),
  };
}

export type RequiredSmtpSettings = {
  host: string;
  port: number;
  username: string | null;
  password: string | null;
  fromEmail: string;
  fromName: string | null;
  secureMode: SmtpSecureMode;
};

function integrationSettingsToJson(row: IntegrationSettingsRow | null) {
  const provider = normalizeAiProvider(row?.ai_provider ?? 'gemini');
  return {
    ai: {
      provider,
      gemini: aiProviderToJson(row?.gemini_api_key ?? null, provider === 'gemini'),
      openai: aiProviderToJson(row?.openai_api_key ?? null, provider === 'openai'),
      claude: aiProviderToJson(row?.claude_api_key ?? null, provider === 'claude'),
      cerebras: aiProviderToJson(row?.cerebras_api_key ?? null, provider === 'cerebras'),
    },
    smtp: {
      configured: isSmtpConfigured(row),
      host: row?.smtp_host ?? null,
      port: row?.smtp_port ?? null,
      username: row?.smtp_username ?? null,
      hasPassword: Boolean(row?.smtp_password),
      fromEmail: row?.smtp_from_email ?? null,
      fromName: row?.smtp_from_name ?? null,
      secureMode: normalizeSecureMode(row?.smtp_secure_mode ?? 'starttls'),
    },
    updatedAt: row?.updated_at ?? null,
  };
}

function aiProviderToJson(apiKey: string | null, selected: boolean) {
  return {
    enabled: selected && Boolean(apiKey),
    hasApiKey: Boolean(apiKey),
  };
}

export function normalizeAiProvider(value: string): AiProvider {
  return AI_PROVIDERS.has(value as AiProvider) ? value as AiProvider : 'gemini';
}

function optionalAiProvider(value: unknown): AiProvider | null {
  if (value == null || value === '') return null;
  const provider = String(value) as AiProvider;
  if (!AI_PROVIDERS.has(provider)) throw new HttpError(400, 'ai.provider is invalid');
  return provider;
}

export function apiKeyForProvider(row: IntegrationSettingsRow, provider: AiProvider): string | null {
  switch (provider) {
    case 'gemini':
      return row.gemini_api_key;
    case 'openai':
      return row.openai_api_key;
    case 'claude':
      return row.claude_api_key;
    case 'cerebras':
      return row.cerebras_api_key;
  }
}

function objectValue(value: unknown): Record<string, unknown> {
  return value && typeof value === 'object' && !Array.isArray(value)
    ? value as Record<string, unknown>
    : {};
}

function secretValue(input: { next: unknown; existing: string | null; clear: boolean }): string | null {
  if (input.clear) return null;
  if (typeof input.next === 'string' && input.next.trim().length > 0) return input.next.trim();
  return input.existing;
}

function optionalHost(value: unknown): string | null {
  const host = optionalString(value);
  if (host == null) return null;
  if (host.length > 253 || host.includes('://') || host.includes('/') || host.includes('@')) {
    throw new HttpError(400, 'smtp.host must be a hostname');
  }
  return host.toLowerCase();
}

function optionalPort(value: unknown): number | null {
  const port = optionalNumber(value);
  if (port == null) return null;
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new HttpError(400, 'smtp.port must be between 1 and 65535');
  }
  if (port === 25) {
    throw new HttpError(400, 'SMTP port 25 is not supported on Cloudflare Workers');
  }
  return port;
}

function optionalEmail(value: unknown, field: string): string | null {
  const email = optionalString(value);
  if (email == null) return null;
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new HttpError(400, `${field} must be a valid email address`);
  }
  return email;
}

function optionalSecureMode(value: unknown): SmtpSecureMode | null {
  if (value == null || value === '') return null;
  const mode = String(value) as SmtpSecureMode;
  if (!SMTP_SECURE_MODES.has(mode)) throw new HttpError(400, 'smtp.secureMode is invalid');
  return mode;
}

function normalizeSecureMode(value: string): SmtpSecureMode {
  return SMTP_SECURE_MODES.has(value as SmtpSecureMode) ? value as SmtpSecureMode : 'starttls';
}

function assertSmtpSettingsAreCoherent(settings: {
  host: string | null;
  port: number | null;
  fromEmail: string | null;
  username: string | null;
  password: string | null;
}): void {
  const anySmtpValue = Boolean(
    settings.host ||
      settings.port ||
      settings.fromEmail ||
      settings.username ||
      settings.password,
  );
  if (!anySmtpValue) return;
  if (!settings.host) throw new HttpError(400, 'smtp.host is required');
  if (!settings.port) throw new HttpError(400, 'smtp.port is required');
  if (!settings.fromEmail) throw new HttpError(400, 'smtp.fromEmail is required');
}
