import type { Env } from './types';

/**
 * Reads a secret binding and returns null when the value cannot be obtained.
 */
export async function tryGetSecret(binding: SecretsStoreSecret): Promise<string | null> {
  try {
    return await binding.get();
  } catch {
    return null;
  }
}

type CfApiSecretMeta = {
  id: string;
  name: string;
  created: string;
  modified: string;
  scopes: string[];
};

type CfApiResponse<T> = {
  success: boolean;
  result: T;
  errors: { code: number; message: string }[];
};

function secretsApiBase(env: Env): string {
  return `https://api.cloudflare.com/client/v4/accounts/${env.CF_ACCOUNT_ID}/secrets_store/stores/${env.CF_SECRETS_STORE_ID}/secrets`;
}

function cfHeaders(env: Env): Record<string, string> {
  return {
    Authorization: `Bearer ${env.CF_API_TOKEN}`,
    'Content-Type': 'application/json',
  };
}

async function findSecretByName(env: Env, name: string): Promise<CfApiSecretMeta | null> {
  const res = await fetch(secretsApiBase(env), { headers: cfHeaders(env) });
  if (!res.ok) throw new Error(`Secrets Store list failed: ${res.status}`);
  const data = (await res.json()) as CfApiResponse<CfApiSecretMeta[]>;
  return data.result?.find((s) => s.name === name) ?? null;
}

/**
 * Creates or replaces a named value in the deployment's Secrets Store.
 */
export async function upsertSecret(env: Env, name: string, value: string): Promise<void> {
  const base = secretsApiBase(env);
  const headers = cfHeaders(env);
  const existing = await findSecretByName(env, name);
  if (existing) {
    const res = await fetch(`${base}/${existing.id}`, {
      method: 'PATCH',
      headers,
      body: JSON.stringify({ value }),
    });
    if (!res.ok) throw new Error(`Secrets Store update failed: ${res.status}`);
  } else {
    const res = await fetch(base, {
      method: 'POST',
      headers,
      body: JSON.stringify({ name, value, scopes: ['workers'] }),
    });
    if (!res.ok) throw new Error(`Secrets Store create failed: ${res.status}`);
  }
}

/**
 * Deletes a named secret from the deployment's Secrets Store when present.
 */
export async function deleteSecret(env: Env, name: string): Promise<void> {
  const existing = await findSecretByName(env, name);
  if (!existing) return;
  const res = await fetch(`${secretsApiBase(env)}/${existing.id}`, {
    method: 'DELETE',
    headers: cfHeaders(env),
  });
  if (!res.ok) throw new Error(`Secrets Store delete failed: ${res.status}`);
}
