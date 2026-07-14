import assert from "node:assert/strict";
import test from "node:test";

import {
  d1Database,
  d1Result,
  stubSecretsStoreEnv,
  stubSecretsStoreSecret,
} from "../test/helpers";
import { runRuntimeMigrations } from "./runtime_migrations";
import type { Env } from "./types";

test("runtime secret migration copies a usable legacy value over a placeholder", async (t) => {
  const statements: string[] = [];
  const db = d1Database((sql) => {
    statements.push(sql);
    return {
      bind() {
        return this;
      },
      async run() {
        return d1Result([]);
      },
      async first<T>() {
        return { id: "2026-07-prefix-secrets" } as T;
      },
    } as unknown as D1PreparedStatement;
  });
  const base = stubSecretsStoreEnv();
  const env = {
    ...base,
    DB: db,
    OPENAI_API_KEY: stubSecretsStoreSecret("placeholder"),
    LEGACY_OPENAI_API_KEY: stubSecretsStoreSecret("legacy-openai-key"),
  } as Env;

  const realFetch = globalThis.fetch;
  t.after(() => {
    globalThis.fetch = realFetch;
  });
  const requests: { method: string; body: string | null }[] = [];
  const responses = [
    new Response(
      JSON.stringify({
        success: true,
        result: [{ id: "new-openai", name: "form_concierge_openai_api_key" }],
        errors: [],
      }),
    ),
    new Response(JSON.stringify({ success: true, result: {}, errors: [] })),
  ];
  globalThis.fetch = (async (_input: RequestInfo | URL, init?: RequestInit) => {
    requests.push({
      method: init?.method ?? "GET",
      body: typeof init?.body === "string" ? init.body : null,
    });
    return responses.shift()!;
  }) as typeof fetch;

  await runRuntimeMigrations(env);

  assert.equal(requests.length, 2);
  assert.equal(requests[1].method, "PATCH");
  assert.deepEqual(JSON.parse(requests[1].body!), {
    value: "legacy-openai-key",
  });
  assert.ok(statements.some((sql) => sql.includes("status = 'completed'")));
});

test("runtime secret migration does not overwrite an already configured secret", async () => {
  const db = d1Database(() => {
    return {
      bind() {
        return this;
      },
      async run() {
        return d1Result([]);
      },
      async first<T>() {
        return { id: "2026-07-prefix-secrets" } as T;
      },
    } as unknown as D1PreparedStatement;
  });
  const base = stubSecretsStoreEnv();
  const env = {
    ...base,
    DB: db,
    OPENAI_API_KEY: stubSecretsStoreSecret("current-openai-key"),
    LEGACY_OPENAI_API_KEY: stubSecretsStoreSecret("legacy-openai-key"),
  } as Env;

  await runRuntimeMigrations(env);
});
