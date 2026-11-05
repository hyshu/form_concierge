import assert from "node:assert/strict";
import {
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import {
  ACCOUNT_EMAIL,
  ACCOUNT_ID,
  CliE2E,
  assertIdentity,
  parseSecrets,
  parseStores,
  resourcePlan,
} from "./cli_e2e.mjs";

const SECRET_NAMES = [
  "gemini_api_key",
  "openai_api_key",
  "claude_api_key",
  "groq_api_key",
  "cerebras_api_key",
  "smtp_password",
  "turnstile_site_key",
  "turnstile_secret_key",
];
const id = (n) => n.toString(16).padStart(32, "0");
const ok = (stdout = "") => ({ status: 0, stdout, stderr: "" });
const fail = (stderr) => ({ status: 1, stdout: "", stderr });
const json = (data) => ok(JSON.stringify(data));
const table = (rows) => rows.map((row) => `│ ${row.join(" │ ")} │`).join("\n");

class FakeCloudflare {
  constructor() {
    this.identity = {
      loggedIn: true,
      email: ACCOUNT_EMAIL,
      accounts: [{ id: ACCOUNT_ID }],
    };
    this.plan = resourcePlan("123456", "1");
    this.calls = [];
    this.mutations = [];
    this.store = null;
    this.worker = false;
    this.database = false;
    this.bucket = false;
    this.secrets = [];
    this.versions = 0;
    this.pages = { admin: 0, web: 0 };
    this.namespaces = [];
  }

  saveProfile() {
    mkdirSync(join(this.home, ".form_concierge", "deployments"), {
      recursive: true,
    });
    writeFileSync(
      this.profilePath,
      JSON.stringify({
        installedVersion: "0.3.0",
        cloudflare: {
          accountId: ACCOUNT_ID,
          worker: {
            name: this.plan.worker,
            url: `https://${this.plan.worker}.mail-hayami.workers.dev`,
          },
          d1: { databaseName: this.plan.database, databaseId: "database-uuid" },
          r2: { bucketName: this.plan.bucket },
          secretsStore: { name: "form-concierge", storeId: this.store.id },
          pages: {
            admin: { projectName: this.plan.admin },
            web: { projectName: this.plan.web },
          },
        },
      }),
    );
  }

  execute = (executable, args, options) => {
    this.calls.push({ executable, args, options });
    if (executable === "dart") {
      const action = args[2];
      if (args.includes("--dry-run")) return ok("Deletion plan");
      this.mutations.push([action, ...args]);
      if (action === "setup") {
        this.secrets = SECRET_NAMES.map((name, i) => [
          `form_concierge_${name}`,
          id(i + 10),
          "form_concierge setup placeholder",
          "workers",
          "active",
          "created",
          "modified",
        ]);
        this.database = true;
        this.bucket = true;
        if (this.failure === "before-profile")
          return fail("setup failed before profile save");
        this.saveProfile();
        if (this.failure === "after-profile")
          return fail("setup failed before Pages creation");
      }
      if (action === "setup" || args.includes("--force")) {
        this.versions++;
        this.pages.admin++;
        this.pages.web++;
        if (args.includes("--force") && this.failure === "changed-secret") {
          this.secrets[0][6] = "overwritten";
        }
      }
      if (action === "destroy") {
        assert.ok(
          args.includes("--yes"),
          "CI must not wait for a terminal confirmation",
        );
        this.worker = false;
        if (this.failure === "after-profile") {
          const profile = JSON.parse(readFileSync(this.profilePath, "utf8"));
          delete profile.cloudflare.worker;
          writeFileSync(this.profilePath, JSON.stringify(profile));
          return fail("Pages project does not exist");
        }
        this.database = this.bucket = false;
        this.pages = { admin: 0, web: 0 };
        this.secrets = [];
        rmSync(this.profilePath);
      }
      return ok("==> Done");
    }
    assert.ok(executable.endsWith("/wrangler"));
    const command = args.slice(0, 3).join(" ");
    if (args[0] === "whoami")
      return json(this.identitySequence?.shift() ?? this.identity);
    if (command === "kv namespace list")
      return this.failure === "kv-read"
        ? fail("Authentication error [code: 10000]")
        : json(this.namespaces);
    if (args[0] === "deployments") {
      return this.worker
        ? json(
            Array.from({ length: this.versions }, (_, i) => ({
              id: `worker-${i}`,
            })),
          )
        : fail("This Worker does not exist on your account. [code: 10007]");
    }
    if (command === "d1 list --json") {
      return json(
        this.database
          ? [{ name: this.plan.database, uuid: "database-uuid" }]
          : [],
      );
    }
    if (command === "pages project list") {
      return json(
        Object.entries(this.pages)
          .filter(([, n]) => n)
          .map(([key]) => ({ "Project Name": this.plan[key] })),
      );
    }
    if (command === "r2 bucket list")
      return ok(
        "Listing buckets...\n" +
          (this.bucket ? `name: ${this.plan.bucket}\n` : ""),
      );
    if (command === "secrets-store store list") {
      if (
        options.env.CLOUDFLARE_API_TOKEN === "worker-token-value" &&
        this.failure === "worker-token-account"
      ) {
        return fail("Forbidden: Worker token belongs to a different account");
      }
      return this.store
        ? ok(table([[this.store.name, this.store.id, ACCOUNT_ID]]))
        : fail("List request returned no stores.");
    }
    if (command === "secrets-store secret list") {
      return this.secrets.length
        ? ok(table(this.secrets))
        : fail("List request returned no secrets.");
    }
    if (args[0] === "secret" && args[1] === "list")
      return json([{ name: "CF_API_TOKEN", type: "secret_text" }]);
    if (command === "pages deployment list") {
      const name = args[args.indexOf("--project-name") + 1];
      const key = name === this.plan.admin ? "admin" : "web";
      return json(
        Array.from({ length: this.pages[key] }, (_, i) => ({
          Id: `${key}-${i}`,
          Status: "just now",
        })),
      );
    }
    this.mutations.push(args);
    if (command === "secrets-store store create") {
      this.store = { name: args[3], id: id(1) };
      if (this.failure === "store-create")
        return fail("Connection lost after store creation");
      return ok(
        `Created store! (Name: ${this.store.name}, ID: ${this.store.id})`,
      );
    }
    if (args[0] === "secret" && args[1] === "put") {
      assert.equal(options.input, "worker-token-value\n");
      assert.equal(options.env.CF_CLI_E2E_WORKER_API_TOKEN, undefined);
      assert.ok(!args.includes("worker-token-value"));
      this.worker = true;
      this.versions++;
      if (this.failure === "secret-put")
        return fail("Connection lost after Worker creation");
      // Even a misbehaving child must not leak either credential into artifacts.
      return ok("worker-token-value ci-token-value");
    }
    if (args[0] === "delete") {
      this.worker = false;
      return ok();
    }
    if (command === "pages project delete") {
      this.pages[args[3] === this.plan.admin ? "admin" : "web"] = 0;
      return ok();
    }
    if (args[0] === "d1" && args[1] === "delete") {
      this.database = false;
      return ok();
    }
    if (command === "r2 bucket delete") {
      this.bucket = false;
      return ok();
    }
    if (command === "secrets-store secret delete") {
      const secretId = args[args.indexOf("--secret-id") + 1];
      this.secrets = this.secrets.filter((row) => row[1] !== secretId);
      return ok();
    }
    if (command === "secrets-store store delete") {
      assert.equal(this.secrets.length, 0, "Never delete a non-empty store");
      this.store = null;
      return ok();
    }
    throw new Error(`Unexpected fake command: ${args.join(" ")}`);
  };

  request = async (url) => {
    this.httpCalls = (this.httpCalls ?? 0) + 1;
    if (this.failure === "http")
      return { status: 503, text: async () => "not ready" };
    if (url.endsWith("/api/config"))
      return { status: 200, text: async () => '{"aiGenerationEnabled":false}' };
    if (url.endsWith("/bootstrap/status"))
      return { status: 200, text: async () => '{"isFirstUser":true}' };
    if (url.endsWith("/config.json"))
      return {
        status: 200,
        text: async () =>
          JSON.stringify({
            apiUrl: `https://${this.plan.worker}.mail-hayami.workers.dev`,
          }),
      };
    return {
      status: 200,
      text: async () =>
        url.includes(this.plan.admin)
          ? '<script src="flutter_bootstrap.js"></script>'
          : `<meta name="form-concierge-api-url" content="https://${this.plan.worker}.mail-hayami.workers.dev">`,
    };
  };
}

function fixture(t) {
  const directory = mkdtempSync(join(tmpdir(), "fc-cli-e2e-test-"));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  const cloud = new FakeCloudflare();
  const env = {
    GITHUB_RUN_ID: "123456",
    GITHUB_RUN_ATTEMPT: "1",
    CLOUDFLARE_ACCOUNT_ID: ACCOUNT_ID,
    CLOUDFLARE_API_TOKEN: "ci-token-value",
    CF_CLI_E2E_WORKER_API_TOKEN: "worker-token-value",
  };
  const options = {
    root: join(directory, "repo"),
    artifacts: join(directory, "artifacts"),
    home: join(directory, "home"),
    env,
    execute: cloud.execute,
    request: cloud.request,
    sleep: async () => {},
    log: () => {},
  };
  cloud.home = options.home;
  cloud.profilePath = join(
    options.home,
    ".form_concierge",
    "deployments",
    `${cloud.plan.deployment}.json`,
  );
  const runner = new CliE2E(options);
  return { runner, cloud, options, env };
}

test("the complete lifecycle verifies updates and removes all owned resources", async (t) => {
  const { runner, cloud, options } = fixture(t);
  await runner.run();
  assert.equal(
    cloud.store.name,
    cloud.plan.store,
    "CLI retains the empty store",
  );
  await new CliE2E({
    ...options,
    env: { ...options.env, CF_CLI_E2E_WORKER_API_TOKEN: undefined },
  }).cleanup();
  assert.equal(cloud.store, null);
  assert.equal(cloud.worker, false);
  assert.equal(cloud.database, false);
  assert.equal(cloud.bucket, false);
  assert.deepEqual(cloud.pages, { admin: 0, web: 0 });
  assert.equal(existsSync(cloud.profilePath), false);
  const state = JSON.parse(readFileSync(runner.journalPath, "utf8"));
  assert.equal(state.lifecyclePassed, true);
  assert.equal(state.cleanupPassed, true);
  const log = readFileSync(join(options.artifacts, "run.log"), "utf8");
  assert.ok(log.includes("[REDACTED]"));
  assert.ok(!log.includes("worker-token-value"));
  assert.ok(!log.includes("ci-token-value"));
  for (const call of cloud.calls)
    assert.equal(call.options.env.CF_CLI_E2E_WORKER_API_TOKEN, undefined);
});

test("missing KV read access stops before creating resources or an ownership journal", async (t) => {
  const { runner, cloud } = fixture(t);
  cloud.failure = "kv-read";
  await assert.rejects(runner.run(), /Workers KV Storage Read/);
  assert.deepEqual(cloud.mutations, []);
  assert.equal(existsSync(runner.journalPath), false);
  await runner.cleanup();
  assert.deepEqual(cloud.mutations, []);
});

test("legacy Workers Sites namespaces are preserved when their names collide", async (t) => {
  for (const suffix of ["", "_preview"]) {
    const { runner, cloud } = fixture(t);
    cloud.namespaces = [
      {
        id: id(99),
        title: `__${cloud.plan.worker}-workers_sites_assets${suffix}`,
      },
    ];
    await assert.rejects(runner.run(), /Existing Workers Sites assets/);
    assert.deepEqual(cloud.mutations, []);
    assert.equal(existsSync(runner.journalPath), false);
  }
});

test("trimmed credentials are also redacted and internal newlines are rejected", async (t) => {
  const { options, cloud } = fixture(t);
  const runner = new CliE2E({
    ...options,
    env: {
      ...options.env,
      CLOUDFLARE_API_TOKEN: "  ci-token-value\n",
      CF_CLI_E2E_WORKER_API_TOKEN: " worker-token-value\n",
    },
  });
  await runner.run();
  await runner.cleanup();
  const log = readFileSync(join(options.artifacts, "run.log"), "utf8");
  assert.ok(!log.includes("ci-token-value"));
  assert.ok(!log.includes("worker-token-value"));
  const invalid = new CliE2E({
    ...options,
    env: {
      ...options.env,
      CF_CLI_E2E_WORKER_API_TOKEN: "worker-token-value\nsecond-line",
    },
  });
  cloud.mutations = [];
  await assert.rejects(invalid.run(), /Worker token must be a single line/);
  assert.deepEqual(cloud.mutations, []);
});

test("the real process adapter sends secrets through stdin without logging them", (t) => {
  const { options } = fixture(t);
  mkdirSync(options.root, { recursive: true });
  const runner = new CliE2E({ ...options, execute: undefined });
  const result = runner.command(
    process.execPath,
    ["-e", "process.stdout.write(require('node:fs').readFileSync(0, 'utf8'))"],
    { cwd: options.root, input: "worker-token-value\n" },
  );
  assert.equal(result.stdout, "worker-token-value\n");
  const log = readFileSync(join(options.artifacts, "run.log"), "utf8");
  assert.ok(log.includes("[REDACTED]"));
  assert.ok(!log.includes("worker-token-value"));
});

test("wrong email or account stops before any mutation", async (t) => {
  for (const identity of [
    {
      loggedIn: true,
      email: "hayami@zoome.co.jp",
      accounts: [{ id: ACCOUNT_ID }],
    },
    {
      loggedIn: true,
      email: ACCOUNT_EMAIL,
      accounts: [{ id: "e873c3578fe0286bf41ab87a425785af" }],
    },
    {
      loggedIn: true,
      email: ACCOUNT_EMAIL,
      accounts: [{ id: ACCOUNT_ID }, { id: "another" }],
    },
  ]) {
    const { runner, cloud } = fixture(t);
    cloud.identity = identity;
    await assert.rejects(runner.run(), /Refusing/);
    await runner.cleanup();
    assert.deepEqual(cloud.mutations, []);
  }
});

test("missing CI credentials never fall back to local OAuth", async (t) => {
  const { options, cloud } = fixture(t);
  const runner = new CliE2E({
    ...options,
    env: { ...options.env, CLOUDFLARE_API_TOKEN: "" },
  });
  await assert.rejects(runner.run(), /Missing CF_CLI_E2E_API_TOKEN/);
  assert.deepEqual(cloud.calls, []);
});

test("a Worker token for another account fails before resource creation", async (t) => {
  const { runner, cloud } = fixture(t);
  cloud.failure = "worker-token-account";
  await assert.rejects(runner.run(), /Could not list stores/);
  await runner.cleanup();
  assert.deepEqual(cloud.mutations, []);
});

test("existing stores and existing local configuration are preserved", async (t) => {
  const { runner, cloud } = fixture(t);
  cloud.store = { name: "unrelated-app", id: id(99) };
  await assert.rejects(runner.run(), /existing Secrets Store/);
  await runner.cleanup();
  assert.equal(cloud.store.id, id(99));
  assert.deepEqual(cloud.mutations, []);
  cloud.store = null;
  mkdirSync(join(runner.root, "worker"), { recursive: true });
  writeFileSync(
    join(runner.root, "worker", "wrangler.jsonc"),
    "production config",
  );
  await assert.rejects(runner.run(), /fresh checkout/);
  assert.deepEqual(cloud.mutations, []);
});

for (const failure of [
  "store-create",
  "secret-put",
  "before-profile",
  "after-profile",
  "http",
  "changed-secret",
]) {
  test(`cleanup recovers from ${failure} failure without relying on a complete profile`, async (t) => {
    const { runner, cloud } = fixture(t);
    cloud.failure = failure;
    await assert.rejects(runner.run());
    await runner.cleanup();
    assert.equal(cloud.worker, false);
    assert.equal(cloud.database, false);
    assert.equal(cloud.bucket, false);
    assert.equal(cloud.store, null);
    assert.equal(existsSync(cloud.profilePath), false);
    await runner.cleanup(); // A repeated cleanup must also be harmless.
  });
}

test("cleanup refuses an altered profile before issuing deletes", async (t) => {
  const { runner, cloud } = fixture(t);
  cloud.failure = "after-profile";
  await assert.rejects(runner.run());
  const profile = JSON.parse(readFileSync(cloud.profilePath, "utf8"));
  profile.cloudflare.worker.name = "japan-travel";
  writeFileSync(cloud.profilePath, JSON.stringify(profile));
  cloud.mutations = [];
  await assert.rejects(runner.cleanup(), /Unexpected resource/);
  assert.deepEqual(cloud.mutations, []);
});

test("cleanup refuses foreign secrets inside the owned store", async (t) => {
  const { runner, cloud } = fixture(t);
  cloud.failure = "before-profile";
  await assert.rejects(runner.run());
  cloud.secrets.push(["unrelated-key", id(500), "real application", "workers"]);
  cloud.mutations = [];
  await assert.rejects(runner.cleanup(), /Unexpected secrets/);
  assert.deepEqual(cloud.mutations, []);
  assert.ok(cloud.store);
  assert.ok(cloud.secrets.some(([name]) => name === "unrelated-key"));
  assert.ok(
    !cloud.mutations.some(
      (args) => args.slice(0, 3).join(" ") === "secrets-store store delete",
    ),
  );
});

test("an identity guard failure inside CLI cleanup cannot enter fallback deletion", async (t) => {
  const { runner, cloud } = fixture(t);
  cloud.failure = "after-profile";
  await assert.rejects(runner.run());
  cloud.identitySequence = [
    cloud.identity,
    { ...cloud.identity, email: "hayami@zoome.co.jp" },
  ];
  cloud.mutations = [];
  await assert.rejects(runner.cleanup(), /Refusing/);
  assert.deepEqual(cloud.mutations, []);
});

test("cleanup rechecks identity and journal ownership", async (t) => {
  const { runner, cloud } = fixture(t);
  cloud.failure = "before-profile";
  await assert.rejects(runner.run());
  cloud.identity.email = "hayami@zoome.co.jp";
  cloud.mutations = [];
  await assert.rejects(runner.cleanup(), /Refusing/);
  assert.deepEqual(cloud.mutations, []);
  const state = JSON.parse(readFileSync(runner.journalPath, "utf8"));
  state.plan.worker = "japan-travel";
  writeFileSync(runner.journalPath, JSON.stringify(state));
  await assert.rejects(runner.cleanup(), /Modified resource ownership plan/);
  assert.deepEqual(cloud.mutations, []);
});

test("resource names and table parsing fail closed on ambiguous input", () => {
  assert.throws(() => resourcePlan("../default", "1"));
  assert.throws(() => resourcePlan("123", "0"));
  assert.throws(() => assertIdentity({ loggedIn: false }));
  assert.throws(() => parseStores(ok("Unexpected table format")));
  assert.throws(() => parseStores(fail("Authentication failure")));
  assert.throws(() => parseSecrets(fail("Permission denied")));
  assert.deepEqual(parseStores(fail("List request returned no stores.")), []);
  assert.deepEqual(parseSecrets(fail("List request returned no secrets.")), []);
});
