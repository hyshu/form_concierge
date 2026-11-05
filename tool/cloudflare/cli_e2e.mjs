#!/usr/bin/env node
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import {
  appendFileSync,
  existsSync,
  mkdirSync,
  readFileSync,
  renameSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

export const ACCOUNT_ID = "bf981465797159e6eb390ded4e51b479";
export const ACCOUNT_EMAIL = "mail.hayami@gmail.com";
const SECRET_NAMES = new Set(
  [
    "gemini_api_key",
    "openai_api_key",
    "claude_api_key",
    "groq_api_key",
    "cerebras_api_key",
    "smtp_password",
    "turnstile_site_key",
    "turnstile_secret_key",
  ].map((name) => `form_concierge_${name}`),
);

export function resourcePlan(runId, attempt) {
  assert.match(
    runId ?? "",
    /^[1-9][0-9]{0,15}$/,
    "GITHUB_RUN_ID must be numeric",
  );
  assert.match(
    attempt ?? "",
    /^[1-9][0-9]{0,3}$/,
    "GITHUB_RUN_ATTEMPT must be numeric",
  );
  const prefix = `fc-cli-e2e-${runId}-${attempt}`;
  return {
    deployment: prefix,
    worker: `${prefix}-api`,
    database: `${prefix}-db`,
    bucket: `${prefix}-media`,
    admin: `${prefix}-admin`,
    web: `${prefix}-web`,
    store: `${prefix}-secrets`,
  };
}

export function assertIdentity(identity) {
  assert.equal(identity.loggedIn, true, "Wrangler is not authenticated");
  assert.equal(identity.email, ACCOUNT_EMAIL, "Refusing a non-Gmail identity");
  assert.deepEqual(
    identity.accounts?.map((account) => account.id),
    [ACCOUNT_ID],
    "Refusing an unexpected or ambiguous Cloudflare account",
  );
}

function clean(text) {
  return String(text ?? "").replace(/\x1b(?:\[[0-?]*[ -/]*[@-~]|[78])/g, "");
}

function cells(text) {
  return clean(text)
    .split(/\r?\n/)
    .filter((line) => line.includes("│"))
    .map((line) =>
      line
        .split("│")
        .map((cell) => cell.trim())
        .filter(Boolean),
    );
}

export function parseStores(result) {
  const output = clean(result.stdout + result.stderr);
  if (result.status !== 0) {
    assert.match(
      output,
      /List request returned no stores\./,
      "Could not list stores",
    );
    return [];
  }
  const stores = cells(result.stdout)
    .filter((row) => /^[a-f0-9]{32}$/.test(row[1]))
    .map(([name, id]) => ({ name, id }));
  assert.ok(
    stores.length,
    "Unrecognized Secrets Store listing; refusing to mutate",
  );
  return stores;
}

export function parseSecrets(result) {
  if (result.status !== 0) {
    assert.match(
      clean(result.stdout + result.stderr),
      /List request returned no secrets\./,
      "Could not list secrets",
    );
    return [];
  }
  const secrets = cells(result.stdout).filter((row) =>
    /^[a-f0-9]{32}$/.test(row[1]),
  );
  assert.ok(secrets.length, "Unrecognized secret listing; refusing to mutate");
  return secrets.sort(([a], [b]) => a.localeCompare(b));
}

export function assertProfile(profile, plan, storeId) {
  const cf = profile.cloudflare;
  assert.equal(cf?.accountId, ACCOUNT_ID, "Saved deployment account mismatch");
  for (const [actual, expected] of [
    [cf.worker?.name, plan.worker],
    [cf.d1?.databaseName, plan.database],
    [cf.r2?.bucketName, plan.bucket],
    [cf.pages?.admin?.projectName, plan.admin],
    [cf.pages?.web?.projectName, plan.web],
  ]) {
    // A partially completed destroy clears fields as it succeeds.
    if (actual != null)
      assert.equal(actual, expected, "Unexpected resource in saved deployment");
  }
  if (cf.secretsStore?.storeId != null) {
    assert.equal(
      cf.secretsStore.storeId,
      storeId,
      "Unexpected Secrets Store in saved deployment",
    );
  }
}

export function compareSnapshots(before, after, forced) {
  assert.deepEqual(
    after.profile,
    before.profile,
    "Saved deployment changed during update",
  );
  assert.deepEqual(
    after.database,
    before.database,
    "D1 identity changed during update",
  );
  assert.deepEqual(
    after.secrets,
    before.secrets,
    "Secret metadata changed during update",
  );
  assert.deepEqual(
    after.workerSecrets,
    before.workerSecrets,
    "Worker secret names changed",
  );
  for (const component of ["worker", "admin", "web"]) {
    const oldIds = before[component];
    const newIds = after[component];
    if (forced) {
      assert.ok(
        newIds.some((id) => !oldIds.includes(id)),
        `${component} was not redeployed`,
      );
    } else {
      assert.deepEqual(
        newIds,
        oldIds,
        `${component} was unnecessarily redeployed`,
      );
    }
  }
}

export class CliE2E {
  constructor({
    root,
    artifacts,
    env = process.env,
    home = homedir(),
    execute = spawnSync,
    request = fetch,
    sleep = (ms) => new Promise((done) => setTimeout(done, ms)),
    log = console.log,
  }) {
    this.root = root;
    this.artifacts = artifacts;
    this.sourceEnv = env;
    this.workerToken = env.CF_CLI_E2E_WORKER_API_TOKEN?.trim();
    this.plan = resourcePlan(env.GITHUB_RUN_ID, env.GITHUB_RUN_ATTEMPT);
    assert.equal(
      env.CLOUDFLARE_ACCOUNT_ID,
      ACCOUNT_ID,
      "CLOUDFLARE_ACCOUNT_ID must be the Gmail account",
    );
    this.env = { ...env, CI: "1", CLOUDFLARE_ACCOUNT_ID: ACCOUNT_ID };
    this.env.CLOUDFLARE_API_TOKEN = env.CLOUDFLARE_API_TOKEN?.trim();
    // The Worker token is used only for its access check and secret put, never
    // inherited by application builds.
    delete this.env.CF_CLI_E2E_WORKER_API_TOKEN;
    delete this.env.CLOUDFLARE_API_KEY;
    delete this.env.CLOUDFLARE_EMAIL;
    delete this.env.CF_API_TOKEN;
    delete this.env.CF_ACCOUNT_ID;
    this.execute = execute;
    this.request = request;
    this.sleep = sleep;
    this.output = log;
    this.profilePath = join(
      home,
      ".form_concierge",
      "deployments",
      `${this.plan.deployment}.json`,
    );
    this.journalPath = join(artifacts, "state.json");
    this.tokens = [
      ...new Set(
        [
          env.CLOUDFLARE_API_TOKEN,
          this.env.CLOUDFLARE_API_TOKEN,
          env.CF_CLI_E2E_WORKER_API_TOKEN,
          this.workerToken,
        ].filter(Boolean),
      ),
    ];
    mkdirSync(artifacts, { recursive: true, mode: 0o700 });
  }

  redact(value) {
    let text = clean(value);
    for (const token of this.tokens)
      text = text.replaceAll(token, "[REDACTED]");
    return text;
  }

  log(message) {
    const text = this.redact(message);
    this.output(text);
    appendFileSync(join(this.artifacts, "run.log"), text + "\n", {
      mode: 0o600,
    });
  }

  save(name, data) {
    const destination = join(this.artifacts, name);
    const temporary = destination + ".tmp";
    writeFileSync(
      temporary,
      this.redact(JSON.stringify(data, null, 2)) + "\n",
      { mode: 0o600 },
    );
    renameSync(temporary, destination);
  }

  command(
    executable,
    args,
    {
      cwd = join(this.root, "worker"),
      input,
      allowFailure = false,
      apiToken,
    } = {},
  ) {
    this.log(`$ ${executable} ${args.join(" ")}`);
    const result = this.execute(executable, args, {
      cwd,
      env: apiToken
        ? { ...this.env, CLOUDFLARE_API_TOKEN: apiToken }
        : this.env,
      input,
      encoding: "utf8",
      stdio: "pipe",
      timeout: 12 * 60 * 1000,
      maxBuffer: 32 * 1024 * 1024,
    });
    const normalized = {
      status: result.status ?? 1,
      stdout: result.stdout ?? "",
      stderr: result.stderr ?? "",
    };
    this.log(normalized.stdout + normalized.stderr);
    if (result.error) throw new Error(this.redact(result.error.message));
    if (!allowFailure && normalized.status !== 0) {
      throw new Error(
        this.redact(
          `Command failed (${normalized.status}): ${executable} ${args.join(" ")}`,
        ),
      );
    }
    return normalized;
  }

  wrangler(args, options) {
    return this.command(
      join(this.root, "worker", "node_modules", ".bin", "wrangler"),
      args,
      options,
    );
  }

  json(args) {
    const value = JSON.parse(this.wrangler(args).stdout);
    assert.ok(Array.isArray(value), `Expected a JSON list: ${args.join(" ")}`);
    return value;
  }

  identity() {
    assert.ok(
      this.env.CLOUDFLARE_API_TOKEN?.trim(),
      "Missing CF_CLI_E2E_API_TOKEN secret",
    );
    assert.ok(
      !/[\r\n]/.test(this.env.CLOUDFLARE_API_TOKEN),
      "CI token must be a single line",
    );
    assertIdentity(JSON.parse(this.wrangler(["whoami", "--json"]).stdout));
  }

  stores(apiToken) {
    return parseStores(
      this.wrangler(["secrets-store", "store", "list", "--remote"], {
        allowFailure: true,
        apiToken,
      }),
    );
  }

  verifyWorkerDeletion() {
    // Wrangler also scans legacy Workers Sites KV namespaces after deleting a
    // Worker, even when this application does not use KV.
    const result = this.wrangler(["kv", "namespace", "list"], {
      allowFailure: true,
    });
    assert.equal(
      result.status,
      0,
      "Could not verify Workers KV Storage Read access required by Wrangler deletion",
    );
    const namespaces = JSON.parse(result.stdout);
    assert.ok(Array.isArray(namespaces), "Unrecognized KV namespace listing");
    const assetNames = new Set([
      `__${this.plan.worker}-workers_sites_assets`,
      `__${this.plan.worker}-workers_sites_assets_preview`,
    ]);
    assert.ok(
      !namespaces.some(({ title }) => assetNames.has(title)),
      "Existing Workers Sites assets share this run's name; refusing to delete them",
    );
  }

  secrets(storeId) {
    return parseSecrets(
      this.wrangler(
        [
          "secrets-store",
          "secret",
          "list",
          storeId,
          "--per-page",
          "100",
          "--remote",
        ],
        { allowFailure: true },
      ),
    );
  }

  ownedSecrets(storeId) {
    const secrets = this.secrets(storeId);
    assert.ok(
      secrets.every(
        ([name, , comment]) =>
          SECRET_NAMES.has(name) &&
          comment === "form_concierge setup placeholder",
      ),
      "Unexpected secrets in test store; refusing to delete them",
    );
    return secrets;
  }

  worker() {
    const result = this.wrangler(
      ["deployments", "list", "--name", this.plan.worker, "--json"],
      { allowFailure: true },
    );
    if (result.status === 0) return JSON.parse(result.stdout);
    assert.match(
      result.stdout + result.stderr,
      /\b10007\b/,
      "Could not verify Worker absence",
    );
    return null;
  }

  inventory() {
    return {
      worker: this.worker(),
      databases: this.json(["d1", "list", "--json"]).filter(
        (db) => db.name === this.plan.database,
      ),
      pages: this.json(["pages", "project", "list", "--json"]).filter((page) =>
        [this.plan.admin, this.plan.web].includes(page["Project Name"]),
      ),
      bucket: this.wrangler(["r2", "bucket", "list"]).stdout.includes(
        this.plan.bucket,
      ),
    };
  }

  assertAbsent(inventory) {
    assert.equal(inventory.worker, null, "Worker still exists");
    assert.deepEqual(inventory.databases, [], "D1 still exists");
    assert.deepEqual(inventory.pages, [], "Pages still exist");
    assert.equal(inventory.bucket, false, "R2 still exists");
  }

  profile() {
    return JSON.parse(readFileSync(this.profilePath, "utf8"));
  }

  cli(action, args = []) {
    this.identity();
    const state = JSON.parse(readFileSync(this.journalPath, "utf8"));
    if (existsSync(this.profilePath))
      assertProfile(this.profile(), this.plan, state.storeId);
    if (action === "destroy") this.ownedSecrets(state.storeId);
    return this.command(
      "dart",
      [
        "run",
        "form_concierge_cli",
        action,
        "cloudflare",
        "--deployment",
        this.plan.deployment,
        ...args,
      ],
      { cwd: join(this.root, "cli") },
    );
  }

  snapshot(label, storeId) {
    const profile = this.profile();
    assertProfile(profile, this.plan, storeId);
    assert.ok(profile.installedVersion, "Installed version was not saved");
    const inventory = this.inventory();
    assert.equal(
      inventory.databases.length,
      1,
      "Expected exactly one test database",
    );
    assert.equal(inventory.databases[0].uuid, profile.cloudflare.d1.databaseId);
    assert.equal(inventory.bucket, true, "Test bucket is missing");
    assert.equal(inventory.pages.length, 2, "Expected both Pages projects");
    const secrets = this.secrets(storeId);
    assert.deepEqual(
      secrets.map(([name]) => name).sort(),
      [...SECRET_NAMES].sort(),
    );
    const workerSecrets = this.json([
      "secret",
      "list",
      "--format",
      "json",
      "--name",
      this.plan.worker,
    ]);
    assert.ok(workerSecrets.some((secret) => secret.name === "CF_API_TOKEN"));
    const snapshot = {
      profile,
      database: inventory.databases.map(({ name, uuid }) => ({ name, uuid })),
      secrets,
      workerSecrets,
      worker: inventory.worker.map(({ id }) => id).sort(),
      ...Object.fromEntries(
        ["admin", "web"].map((key) => [
          key,
          this.json([
            "pages",
            "deployment",
            "list",
            "--project-name",
            this.plan[key],
            "--json",
          ])
            .map((deployment) => deployment.Id)
            .sort(),
        ]),
      ),
    };
    this.save(`snapshot-${label}.json`, snapshot);
    return snapshot;
  }

  async httpChecks(label) {
    const apiUrl = this.profile().cloudflare.worker.url;
    const api = new URL(apiUrl);
    assert.equal(api.protocol, "https:");
    assert.ok(
      api.hostname.startsWith(this.plan.worker + ".") &&
        api.hostname.endsWith(".workers.dev"),
    );
    const checks = [
      [
        `${apiUrl}/api/config`,
        (body) => assert.equal(JSON.parse(body).aiGenerationEnabled, false),
      ],
      [
        `${apiUrl}/api/admin/bootstrap/status`,
        (body) => assert.deepEqual(JSON.parse(body), { isFirstUser: true }),
      ],
      [
        `https://${this.plan.admin}.pages.dev/`,
        (body) => assert.ok(body.includes("flutter_bootstrap.js")),
      ],
      [
        `https://${this.plan.admin}.pages.dev/assets/assets/config.json`,
        (body) => assert.deepEqual(JSON.parse(body), { apiUrl }),
      ],
      [
        `https://${this.plan.web}.pages.dev/`,
        (body) =>
          assert.ok(
            body.includes(
              `<meta name="form-concierge-api-url" content="${apiUrl}">`,
            ),
          ),
      ],
    ];
    for (const [url, validate] of checks) {
      let failure;
      for (let attempt = 0; attempt < 12; attempt++) {
        try {
          const response = await this.request(url, {
            signal: AbortSignal.timeout(10000),
          });
          assert.equal(response.status, 200, `HTTP check failed: ${url}`);
          validate(await response.text());
          failure = null;
          break;
        } catch (error) {
          failure = error;
          if (attempt < 11) await this.sleep(5000);
        }
      }
      if (failure) throw failure;
      this.log(`HTTP check passed: ${url}`);
    }
    this.save(`http-${label}.json`, {
      urls: checks.map(([url]) => url),
      passed: true,
    });
  }

  async run() {
    assert.ok(this.workerToken, "Missing CF_CLI_E2E_WORKER_API_TOKEN secret");
    assert.ok(
      !/[\r\n]/.test(this.workerToken),
      "Worker token must be a single line",
    );
    assert.ok(
      !existsSync(this.journalPath),
      "A journal already exists; run cleanup before reusing this directory",
    );
    this.identity();
    assert.ok(
      !existsSync(this.profilePath),
      "The test deployment profile already exists",
    );
    assert.ok(
      !existsSync(join(this.root, "worker", "wrangler.jsonc")),
      "Use a fresh checkout; refusing to replace an existing local Wrangler config",
    );
    this.verifyWorkerDeletion();
    this.assertAbsent(this.inventory());
    assert.deepEqual(
      this.stores(),
      [],
      "An existing Secrets Store is present; refusing to reuse or delete it",
    );
    assert.deepEqual(
      this.stores(this.workerToken),
      [],
      "The Worker token cannot access the expected Gmail Secrets Store account",
    );
    const state = {
      schemaVersion: 1,
      accountId: ACCOUNT_ID,
      runId: this.sourceEnv.GITHUB_RUN_ID,
      attempt: this.sourceEnv.GITHUB_RUN_ATTEMPT,
      plan: this.plan,
      baselineVerified: true,
    };
    this.save("state.json", state); // Persist ownership before the first mutation.
    const created = this.wrangler([
      "secrets-store",
      "store",
      "create",
      this.plan.store,
      "--remote",
    ]);
    const match = clean(created.stdout).match(/ID:\s*([a-f0-9]{32})/);
    if (match) {
      state.storeId = match[1];
      this.save("state.json", state);
    }
    const stores = this.stores();
    assert.equal(stores.length, 1);
    assert.equal(stores[0].name, this.plan.store);
    if (state.storeId) assert.equal(stores[0].id, state.storeId);
    state.storeId = stores[0].id;
    this.save("state.json", state);
    // This is the same normal Wrangler step performed manually before setup.
    // The token is never an argument, artifact, or inherited build variable.
    this.wrangler(
      ["secret", "put", "CF_API_TOKEN", "--name", this.plan.worker],
      {
        input: this.workerToken + "\n",
      },
    );
    this.cli("setup", [
      "--worker-name",
      this.plan.worker,
      "--database-name",
      this.plan.database,
      "--r2-bucket-name",
      this.plan.bucket,
      "--admin-project",
      this.plan.admin,
      "--web-project",
      this.plan.web,
      "--local-bindings-for-local-dev",
    ]);
    const initial = this.snapshot("setup", state.storeId);
    await this.httpChecks("setup");
    this.cli("update");
    compareSnapshots(initial, this.snapshot("update", state.storeId), false);
    this.cli("update", ["--force"]);
    compareSnapshots(initial, this.snapshot("force", state.storeId), true);
    await this.httpChecks("force");
    this.cli("destroy", [
      "--include-data",
      "--delete-secrets-store",
      "--dry-run",
    ]);
    this.cli("destroy", ["--include-data", "--delete-secrets-store", "--yes"]);
    this.assertAbsent(this.inventory());
    assert.ok(
      !existsSync(this.profilePath),
      "CLI left a deployment profile behind",
    );
    assert.deepEqual(
      this.secrets(state.storeId),
      [],
      "CLI left secret values behind",
    );
    state.lifecyclePassed = true;
    this.save("state.json", state);
    this.log("CLI create / update / forced update / destroy checks passed.");
  }

  async cleanup() {
    if (!existsSync(this.journalPath)) {
      this.log("No verified ownership journal; nothing to clean up.");
      return;
    }
    const state = JSON.parse(readFileSync(this.journalPath, "utf8"));
    assert.equal(state.schemaVersion, 1);
    assert.equal(state.accountId, ACCOUNT_ID);
    assert.equal(
      state.baselineVerified,
      true,
      "Missing resource ownership proof",
    );
    assert.deepEqual(
      resourcePlan(state.runId, state.attempt),
      this.plan,
      "Journal belongs to another run",
    );
    assert.deepEqual(state.plan, this.plan, "Modified resource ownership plan");
    this.identity();
    const stores = this.stores();
    const store = stores.find(({ name }) => name === this.plan.store);
    if (state.storeId && store)
      assert.equal(store.id, state.storeId, "Store identity changed");
    const storeId = state.storeId ?? store?.id;
    if (store) this.ownedSecrets(store.id);
    if (existsSync(this.profilePath)) {
      assertProfile(this.profile(), this.plan, storeId);
      // A failed setup can record Pages that were never created. Fall back to
      // individually deleting only names proven absent before this run.
      try {
        this.cli("destroy", [
          "--include-data",
          "--delete-secrets-store",
          "--yes",
        ]);
      } catch (error) {
        if (error.code === "ERR_ASSERTION") throw error;
        this.log(
          `CLI cleanup incomplete; inspecting owned resources: ${error.message}`,
        );
      }
    }
    const remaining = this.inventory();
    const errors = [];
    const remove = (args) => {
      try {
        this.wrangler(args);
      } catch (error) {
        errors.push(error.message);
      }
    };
    if (remaining.worker) remove(["delete", this.plan.worker, "--force"]);
    for (const page of remaining.pages)
      remove(["pages", "project", "delete", page["Project Name"], "--yes"]);
    if (remaining.databases.length)
      remove(["d1", "delete", this.plan.database, "--skip-confirmation"]);
    if (remaining.bucket) remove(["r2", "bucket", "delete", this.plan.bucket]);
    if (store) {
      const secrets = this.ownedSecrets(store.id);
      for (const [, id] of secrets)
        remove([
          "secrets-store",
          "secret",
          "delete",
          store.id,
          "--secret-id",
          id,
          "--remote",
        ]);
      if (!errors.length && this.secrets(store.id).length === 0) {
        remove(["secrets-store", "store", "delete", store.id, "--remote"]);
      }
    }
    assert.deepEqual(
      errors,
      [],
      "One or more test resources could not be deleted",
    );
    this.assertAbsent(this.inventory());
    assert.ok(
      !this.stores().some(
        ({ name, id }) => name === this.plan.store || id === storeId,
      ),
      "Test store still exists",
    );
    // Only this run's validated profile can be removed after remote cleanup.
    rmSync(this.profilePath, { force: true });
    state.cleanupPassed = true;
    this.save("state.json", state);
    this.log(
      "All owned E2E resources and the test deployment profile are absent.",
    );
  }
}

async function main() {
  const phase = process.argv[2];
  assert.ok(
    ["run", "cleanup"].includes(phase),
    "Usage: node tool/cloudflare/cli_e2e.mjs <run|cleanup>",
  );
  const root = resolve(dirname(fileURLToPath(import.meta.url)), "../..");
  const artifacts = process.env.CLI_E2E_ARTIFACT_DIR;
  assert.ok(artifacts, "CLI_E2E_ARTIFACT_DIR is required");
  const runner = new CliE2E({ root, artifacts });
  try {
    await runner[phase]();
  } catch (error) {
    runner.log(error.stack ?? error.message);
    process.exitCode = 1;
  }
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(resolve(process.argv[1])).href
) {
  main().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
}
