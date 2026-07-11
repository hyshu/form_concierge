import type { Env, IntegrationSettingsRow } from './types';
import { tryGetSecret, upsertSecret, deleteSecret } from './secrets_store';
import { HttpError, json, nowIso, optionalBoolean, optionalInteger, readJson, requireObject } from './utils';

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
  return json(await integrationSettingsToJson(env, row));
}

export async function updateAdminIntegrationSettings(request: Request, env: Env): Promise<Response> {
  const body = await readJson(request);
  const ai = requireObject(body.ai, 'ai');
  const smtp = requireObject(body.smtp, 'smtp');
  const aiProvider = requireAiProvider(ai.provider);

  // Optimistic concurrency: the whole row is replaced, so a concurrent save
  // would otherwise silently overwrite the other admin's changes.
  if (body.expectedUpdatedAt != null) {
    if (typeof body.expectedUpdatedAt !== 'string') {
      throw new HttpError(400, 'expectedUpdatedAt must be a string');
    }
    const current = await getIntegrationSettingsRow(env);
    if (current?.updated_at != null
      && Date.parse(current.updated_at) !== Date.parse(body.expectedUpdatedAt)) {
      throw new HttpError(409, 'Settings were changed by someone else. Reload and try again.');
    }
  }

  const secretOps = buildSecretOps([
    { next: ai.geminiApiKey, clear: optionalBoolean(ai.clearGeminiApiKey, 'ai.clearGeminiApiKey') === true, field: 'ai.geminiApiKey', secretName: 'gemini_api_key' },
    { next: ai.openaiApiKey, clear: optionalBoolean(ai.clearOpenaiApiKey, 'ai.clearOpenaiApiKey') === true, field: 'ai.openaiApiKey', secretName: 'openai_api_key' },
    { next: ai.claudeApiKey, clear: optionalBoolean(ai.clearClaudeApiKey, 'ai.clearClaudeApiKey') === true, field: 'ai.claudeApiKey', secretName: 'claude_api_key' },
    { next: ai.cerebrasApiKey, clear: optionalBoolean(ai.clearCerebrasApiKey, 'ai.clearCerebrasApiKey') === true, field: 'ai.cerebrasApiKey', secretName: 'cerebras_api_key' },
    { next: smtp.password, clear: optionalBoolean(smtp.clearPassword, 'smtp.clearPassword') === true, field: 'smtp.password', secretName: 'smtp_password' },
  ]);

  const smtpHost = optionalHost(smtp.host);
  const smtpPort = optionalPort(smtp.port);
  const smtpUsername = optionalSettingsString(smtp.username, 'smtp.username');
  const smtpFromEmail = optionalEmail(smtp.fromEmail, 'smtp.fromEmail');
  const smtpFromName = optionalSettingsString(smtp.fromName, 'smtp.fromName');
  const smtpSecureMode = requireSecureMode(smtp.secureMode);

  const smtpPasswordForValidation: string | null = secretOps.some(
    op => op.secretName === 'smtp_password' && op.action === 'clear',
  ) ? null : (typeof smtp.password === 'string' ? smtp.password : (await tryGetSecret(env.SMTP_PASSWORD)));
  assertSmtpSettingsAreCoherent({
    host: smtpHost,
    port: smtpPort,
    fromEmail: smtpFromEmail,
    username: smtpUsername,
    password: smtpPasswordForValidation,
    secureMode: smtpSecureMode,
  });

  const [row] = await Promise.all([
    env.DB.prepare(
      `INSERT INTO integration_settings
         (id, ai_provider, smtp_host, smtp_port, smtp_username, smtp_from_email, smtp_from_name,
          smtp_secure_mode, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
       ON CONFLICT(id) DO UPDATE SET
         ai_provider = excluded.ai_provider,
         smtp_host = excluded.smtp_host,
         smtp_port = excluded.smtp_port,
         smtp_username = excluded.smtp_username,
         smtp_from_email = excluded.smtp_from_email,
         smtp_from_name = excluded.smtp_from_name,
         smtp_secure_mode = excluded.smtp_secure_mode,
         updated_at = excluded.updated_at
       RETURNING *`,
    ).bind(
      SETTINGS_ID,
      aiProvider,
      smtpHost,
      smtpPort,
      smtpUsername,
      smtpFromEmail,
      smtpFromName,
      smtpSecureMode,
      nowIso(),
    ).first<IntegrationSettingsRow>(),
    ...secretOps.map(op =>
      op.action === 'upsert'
        ? upsertSecret(env, op.secretName, op.value!)
        : deleteSecret(env, op.secretName),
    ),
  ]);

  if (!row) throw new HttpError(500, 'Settings operation failed');
  return json(await integrationSettingsToJson(env, row));
}

type SecretOp = {
  secretName: string;
  action: 'upsert' | 'clear';
  value?: string;
};

function buildSecretOps(
  specs: { next: unknown; clear: boolean; field: string; secretName: string }[],
): SecretOp[] {
  const ops: SecretOp[] = [];
  for (const spec of specs) {
    if (spec.clear) {
      ops.push({ secretName: spec.secretName, action: 'clear' });
      continue;
    }
    if (spec.next == null || spec.next === '') continue;
    if (typeof spec.next !== 'string') throw new HttpError(400, `${spec.field} must be a string`);
    const trimmed = spec.next.trim();
    if (trimmed.length > 0) {
      ops.push({ secretName: spec.secretName, action: 'upsert', value: trimmed });
    }
  }
  return ops;
}

export async function isAiGenerationConfigured(env: Env): Promise<boolean> {
  const row = await getIntegrationSettingsRow(env);
  if (!row) return false;
  return Boolean(await apiKeyForProvider(env, normalizeAiProvider(row.ai_provider)));
}

export async function isEmailConfiguredResponse(env: Env): Promise<Response> {
  const row = await getIntegrationSettingsRow(env);
  return json({ configured: isSmtpConfigured(row) });
}

export function isSmtpConfigured(row: IntegrationSettingsRow | null): boolean {
  return Boolean(row?.smtp_host && row.smtp_port && row.smtp_from_email);
}

export async function requireSmtpSettings(row: IntegrationSettingsRow | null, env: Env): Promise<RequiredSmtpSettings> {
  if (!isSmtpConfigured(row)) {
    throw new HttpError(400, 'SMTP settings are not configured');
  }
  return {
    host: row!.smtp_host!,
    port: row!.smtp_port!,
    username: row!.smtp_username,
    password: await tryGetSecret(env.SMTP_PASSWORD),
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

const API_KEY_BINDINGS = {
  gemini: 'GEMINI_API_KEY',
  openai: 'OPENAI_API_KEY',
  claude: 'CLAUDE_API_KEY',
  cerebras: 'CEREBRAS_API_KEY',
} as const;

export async function apiKeyForProvider(env: Env, provider: AiProvider): Promise<string | null> {
  const binding = env[API_KEY_BINDINGS[provider]];
  return tryGetSecret(binding);
}

async function integrationSettingsToJson(env: Env, row: IntegrationSettingsRow | null) {
  const provider = normalizeAiProvider(row?.ai_provider ?? 'gemini');
  const [gemini, openai, claude, cerebras, smtpPwd] = await Promise.all([
    tryGetSecret(env.GEMINI_API_KEY),
    tryGetSecret(env.OPENAI_API_KEY),
    tryGetSecret(env.CLAUDE_API_KEY),
    tryGetSecret(env.CEREBRAS_API_KEY),
    tryGetSecret(env.SMTP_PASSWORD),
  ]);
  return {
    ai: {
      provider,
      gemini: aiProviderToJson(gemini, provider === 'gemini'),
      openai: aiProviderToJson(openai, provider === 'openai'),
      claude: aiProviderToJson(claude, provider === 'claude'),
      cerebras: aiProviderToJson(cerebras, provider === 'cerebras'),
    },
    smtp: {
      configured: isSmtpConfigured(row),
      host: row?.smtp_host ?? null,
      port: row?.smtp_port ?? null,
      username: row?.smtp_username ?? null,
      hasPassword: Boolean(smtpPwd),
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
  if (!AI_PROVIDERS.has(value as AiProvider)) {
    throw new HttpError(500, 'Invalid stored AI provider');
  }
  return value as AiProvider;
}

function requireAiProvider(value: unknown): AiProvider {
  if (value == null || value === '') {
    throw new HttpError(400, 'ai.provider is required');
  }
  if (typeof value !== 'string') throw new HttpError(400, 'ai.provider must be a string');
  const provider = value.trim() as AiProvider;
  if (provider.length === 0) throw new HttpError(400, 'ai.provider is required');
  if (!AI_PROVIDERS.has(provider)) throw new HttpError(400, 'ai.provider is invalid');
  return provider;
}

function optionalHost(value: unknown): string | null {
  const host = optionalSettingsString(value, 'smtp.host');
  if (host == null) return null;
  if (host.length > 253 || host.includes('://') || host.includes('/') || host.includes('@')) {
    throw new HttpError(400, 'smtp.host must be a hostname');
  }
  return host.toLowerCase();
}

function optionalPort(value: unknown): number | null {
  const port = optionalInteger(value, 'smtp.port', { min: 1, max: 65535 });
  if (port === 25) {
    throw new HttpError(400, 'SMTP port 25 is not supported on Cloudflare Workers');
  }
  return port;
}

function optionalEmail(value: unknown, field: string): string | null {
  const email = optionalSettingsString(value, field);
  if (email == null) return null;
  return requireValidSmtpEmail(email, field);
}

function requireValidSmtpEmail(email: string, field: string): string {
  const normalized = email.toLowerCase();
  if (/[\s<>]/.test(normalized) || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalized)) {
    throw new HttpError(400, `${field} must be a valid email address`);
  }
  return normalized;
}

function requireSecureMode(value: unknown): SmtpSecureMode {
  if (value == null || value === '') {
    throw new HttpError(400, 'smtp.secureMode is required');
  }
  if (typeof value !== 'string') throw new HttpError(400, 'smtp.secureMode must be a string');
  const mode = value.trim() as SmtpSecureMode;
  if (mode.length === 0) throw new HttpError(400, 'smtp.secureMode is required');
  if (!SMTP_SECURE_MODES.has(mode)) throw new HttpError(400, 'smtp.secureMode is invalid');
  return mode;
}

function normalizeSecureMode(value: string): SmtpSecureMode {
  if (!SMTP_SECURE_MODES.has(value as SmtpSecureMode)) {
    throw new HttpError(500, 'Invalid stored SMTP secure mode');
  }
  return value as SmtpSecureMode;
}

function optionalSettingsString(value: unknown, field: string): string | null {
  if (value == null || value === '') return null;
  if (typeof value !== 'string') throw new HttpError(400, `${field} must be a string`);
  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed;
}

function assertSmtpSettingsAreCoherent(settings: {
  host: string | null;
  port: number | null;
  fromEmail: string | null;
  username: string | null;
  password: string | null;
  secureMode: SmtpSecureMode;
}): void {
  if (settings.secureMode === 'none' && (settings.username || settings.password)) {
    throw new HttpError(400, 'smtp.secureMode must be starttls or tls when SMTP authentication is configured');
  }
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
