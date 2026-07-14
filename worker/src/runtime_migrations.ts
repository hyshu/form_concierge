import { SECRET_NAMES } from "./secret_names";
import { tryGetSecret, upsertSecret } from "./secrets_store";
import type { Env } from "./types";
import { logError } from "./utils";

type RuntimeMigration = {
  id: string;
  run: (env: Env) => Promise<void>;
};

const migrations: RuntimeMigration[] = [
  {
    id: "2026-07-prefix-secrets",
    run: migratePrefixedSecrets,
  },
];

export function scheduleRuntimeMigrations(
  env: Env,
  ctx: ExecutionContext,
): void {
  ctx.waitUntil(
    runRuntimeMigrations(env).catch((error) => {
      logError("runtime_migration_error", error);
    }),
  );
}

export async function runRuntimeMigrations(env: Env): Promise<void> {
  for (const migration of migrations) {
    await runMigration(env, migration);
  }
}

async function runMigration(
  env: Env,
  migration: RuntimeMigration,
): Promise<void> {
  await env.DB.prepare(
    `INSERT INTO runtime_migrations (id, status)
     VALUES (?, 'pending')
     ON CONFLICT(id) DO NOTHING`,
  )
    .bind(migration.id)
    .run();

  const claimed = await env.DB.prepare(
    `UPDATE runtime_migrations
     SET status = 'running', attempts = attempts + 1,
         updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now'), last_error = NULL
     WHERE id = ? AND (
       status = 'pending'
       OR (status = 'failed' AND updated_at <= strftime('%Y-%m-%dT%H:%M:%fZ', 'now', '-1 minute'))
       OR (status = 'running' AND updated_at <= strftime('%Y-%m-%dT%H:%M:%fZ', 'now', '-5 minutes'))
     )
     RETURNING id`,
  )
    .bind(migration.id)
    .first<{ id: string }>();
  if (!claimed) return;

  try {
    await migration.run(env);
    await env.DB.prepare(
      `UPDATE runtime_migrations
       SET status = 'completed', completed_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now'),
           updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now'), last_error = NULL
       WHERE id = ?`,
    )
      .bind(migration.id)
      .run();
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    await env.DB.prepare(
      `UPDATE runtime_migrations
       SET status = 'failed', last_error = ?,
           updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
       WHERE id = ?`,
    )
      .bind(message.slice(0, 1000), migration.id)
      .run();
    throw error;
  }
}

async function migratePrefixedSecrets(env: Env): Promise<void> {
  const copies: [SecretsStoreSecret, SecretsStoreSecret | undefined, string][] =
    [
      [env.GEMINI_API_KEY, env.LEGACY_GEMINI_API_KEY, SECRET_NAMES.gemini],
      [env.OPENAI_API_KEY, env.LEGACY_OPENAI_API_KEY, SECRET_NAMES.openai],
      [env.CLAUDE_API_KEY, env.LEGACY_CLAUDE_API_KEY, SECRET_NAMES.claude],
      [env.GROQ_API_KEY, env.LEGACY_GROQ_API_KEY, SECRET_NAMES.groq],
      [
        env.CEREBRAS_API_KEY,
        env.LEGACY_CEREBRAS_API_KEY,
        SECRET_NAMES.cerebras,
      ],
      [env.SMTP_PASSWORD, env.LEGACY_SMTP_PASSWORD, SECRET_NAMES.smtpPassword],
      [
        env.TURNSTILE_SITE_KEY,
        env.LEGACY_TURNSTILE_SITE_KEY,
        SECRET_NAMES.turnstileSiteKey,
      ],
      [
        env.TURNSTILE_SECRET_KEY,
        env.LEGACY_TURNSTILE_SECRET_KEY,
        SECRET_NAMES.turnstileSecretKey,
      ],
    ];

  for (const [currentBinding, legacyBinding, currentName] of copies) {
    if (!legacyBinding || isUsable(await tryGetSecret(currentBinding)))
      continue;
    const legacyValue = await tryGetSecret(legacyBinding);
    if (isUsable(legacyValue)) {
      await upsertSecret(env, currentName, legacyValue!);
    }
  }
}

function isUsable(value: string | null): boolean {
  return (
    value != null && value.trim().length > 0 && value.trim() !== "placeholder"
  );
}
