# form_concierge_cli

Command-line tools for setting up and managing Form Concierge.

The CLI can create, update, and remove the required Cloudflare resources.

## Install

```bash
dart pub global activate form_concierge_cli
```

After installation, run the CLI with the `form_concierge` command:

```bash
form_concierge doctor
```

## Quick Start

Check that the required tools are available:

```bash
form_concierge doctor
```

Create a Cloudflare deployment:

```bash
form_concierge setup cloudflare
```

Setup creates and configures the required Cloudflare resources, including:

- D1
- R2
- Worker
- Web Pages
- Admin Pages, unless disabled

To see all available setup options:

```bash
form_concierge setup cloudflare --help
```

Common setup options include:

- `--preflight-only`
- `--seed-project-id`
- `--worker-name`
- `--deployment <name>`
- `--no-admin-pages`

## Commands

| Command                             | Description                                                          |
| ----------------------------------- | -------------------------------------------------------------------- |
| `form_concierge doctor`             | Check Dart, Flutter, Node.js, npm, Wrangler, and the monorepo layout |
| `form_concierge setup cloudflare`   | Create and configure a Cloudflare deployment                         |
| `form_concierge update cloudflare`  | Update an existing deployment using its saved settings               |
| `form_concierge destroy cloudflare` | Delete resources recorded in a saved deployment                      |
| `form_concierge build admin-macos`  | Build the macOS admin app and copy it to the selected destination    |

## Deployment Profiles

Deployment settings are stored under:

```text
~/.form_concierge/deployments/<name>.json
```

Use `--deployment <name>` to manage separate environments:

```bash
form_concierge setup cloudflare --deployment production
form_concierge update cloudflare --deployment production
form_concierge destroy cloudflare --deployment staging --dry-run
form_concierge build admin-macos --deployment production
```

When no deployment is specified:

- If only one saved deployment exists, it is selected automatically.
- If multiple deployments exist, an interactive command prompts you to select
  one.
- If multiple deployments exist, a non-interactive command requires
  `--deployment`.
- If no deployments exist, initial setup uses the name `default`.

Command-line values override saved values. If a required value is missing, the
CLI prompts for it and writes the result back to the deployment file.

## Admin Interface

Deploying the admin interface to Cloudflare Pages is optional.

By default, `setup cloudflare` creates an Admin Pages project. To skip it:

```bash
form_concierge setup cloudflare --no-admin-pages
```

This preference is saved in the selected deployment and reused by future
`update` commands.

Admin Pages can be enabled later:

```bash
form_concierge update cloudflare --admin-pages
```

On macOS, you can also build a local admin app connected to the saved Worker
URL:

```bash
form_concierge build admin-macos
```

Use `--deployment` to select the saved Worker URL:

```bash
form_concierge build admin-macos --deployment production
```

Use `--api-url` to override the Worker URL, and `--output` or `-o` to select
the copy destination.

This command is available only on macOS. If an app with the same name already
exists at the destination, it is replaced.

## Updating a Deployment

Update an existing deployment using its saved settings:

```bash
form_concierge update cloudflare
```

The CLI compares the saved `installedVersion` with the target template version
and deploys only the components changed by releases in that range.

Required Cloudflare resources are still checked on every update.

Use `--force` to run the full deployment plan:

```bash
form_concierge update cloudflare --force
```

A full deployment plan is also used when:

- No installed version is available
- The installed version is unknown
- The target version is a downgrade
- Deployment settings are explicitly overridden
- The deployment is being created for the first time

Existing secret values are never overwritten. Update only creates missing
placeholders and prompts for `CF_API_TOKEN` when it is actually absent.

## Secrets Store

Setup creates Worker Secrets Store bindings for supported provider keys.

Missing entries are created as placeholders for later configuration.

## Destroying a Deployment

Preview the deletion plan:

```bash
form_concierge destroy cloudflare --dry-run
```

Delete the recorded resources:

```bash
form_concierge destroy cloudflare
```

D1, R2, and Secrets Store are retained by default.

| Option                   | Description                                                                             |
| ------------------------ | --------------------------------------------------------------------------------------- |
| `--deployment <name>`    | Select the saved deployment to destroy                                                  |
| `--dry-run`              | Print the deletion plan without deleting resources                                      |
| `--include-data`         | Also delete D1 and the R2 bucket when it is empty                                       |
| `--empty-r2`             | Request R2 content deletion; currently stops with instructions for emptying it manually |
| `--delete-secrets-store` | Delete the Secrets Store and all of its values                                          |
| `--yes`, `-y`            | Skip interactive confirmation                                                           |

A non-empty R2 bucket is retained with a warning.

Successful deletions are removed from the deployment file as they happen. If a
destroy operation is interrupted or only partially succeeds, run the command
again to delete the remaining resources.

## Template Sources

When the CLI is run from a local Form Concierge checkout, it uses the local
template files when available.

A standalone installation downloads the matching versioned template from the
project's GitHub Release, verifies its SHA-256 checksum, and stores it in the
local platform cache for reuse.

Template options:

| Option               | Description                                    |
| -------------------- | ---------------------------------------------- |
| `--template-version` | Release version; defaults to the CLI version   |
| `--template-url`     | Custom template archive URL                    |
| `--template-sha256`  | Expected SHA-256 checksum for a custom archive |
| `--offline`          | Require a local checkout or cached template    |
| `--refresh-template` | Replace the cached template                    |

## Install from Source

From the `cli` directory:

```bash
cd cli
dart pub get
```

From anywhere inside the monorepo:

```bash
dart run form_concierge_cli setup cloudflare --preflight-only
```

The package defines a matching executable, so it can be run as
`dart run form_concierge_cli`.

To activate the `form_concierge` command from the local source:

```bash
dart pub global activate --source path .
```

You can then run:

```bash
form_concierge doctor
form_concierge setup cloudflare
```

## Cloudflare CLI lifecycle CI

The **Cloudflare CLI E2E** workflow in
`.github/workflows/cli-cloudflare-e2e.yml` runs the real CLI against the
`mail.hayami@gmail.com` Cloudflare account. It is started manually with
**Actions → Cloudflare CLI E2E → Run workflow**, using the `main` branch.
It does not run on pull requests or ordinary pushes. The regular CI runs the
orchestration's credential-free tests instead:

```bash
node --test tool/cloudflare/cli_e2e.test.mjs
```

Create a GitHub Environment named `cloudflare-cli-e2e` and register these
environment secrets before the first live run:

| Secret                        | Purpose                                                                                                                                       |
| ----------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `CF_CLI_E2E_API_TOKEN`        | User API token owned by `mail.hayami@gmail.com`, scoped to the Gmail account, for creating, updating, listing, and deleting test resources.   |
| `CF_CLI_E2E_WORKER_API_TOKEN` | Secrets Store Edit token stored in the temporary Worker's `CF_API_TOKEN` secret. The token created during the manual test can be reused here. |

For `CF_CLI_E2E_API_TOKEN`, grant the required permissions only on account
`bf981465797159e6eb390ded4e51b479`:

- Worker creation, deployment, secrets, and deletion: Workers Scripts Edit,
  or Workers product Admin where the newer Workers role UI is used.
- D1 Edit, Workers R2 Storage Edit, Cloudflare Pages Edit, Secrets Store Edit.
- Account Settings Read, plus User Details Read and Memberships Read so
  `wrangler whoami --json` can verify the email and account.
- Workers KV Storage Read: Wrangler checks for legacy Workers Sites namespaces
  after deleting a Worker, even though this deployment does not use KV. KV write
  access is not required. The runner verifies this read access before creation
  and refuses existing legacy asset namespaces matching this run's Worker name.

The deployment token and Worker token serve different purposes. A token with
only Secrets Store Edit cannot create all the test resources. Enter token values
directly into GitHub's secret settings; do not put them in workflow inputs,
command arguments, committed files, or issue comments. See Cloudflare's
[GitHub Actions authentication](https://developers.cloudflare.com/workers/ci-cd/external-cicd/github-actions/),
[Workers permissions](https://developers.cloudflare.com/workers/authorization/workers/),
and [Secrets Store access control](https://developers.cloudflare.com/secrets-store/access-control/).

The workflow performs these checks:

1. Verify the exact Gmail email and account ID, and confirm that the names for
   this run do not already exist. Refuse to run if any Secrets Store exists,
   because the CLI can reuse an account's existing store.
2. Create a uniquely named test store and supply the Worker token to Wrangler
   through stdin. This is the same preparation performed during the manual test.
3. Run `setup cloudflare` with a unique deployment, D1, R2, Worker, and both
   Pages project names. Check API responses and the Pages API configuration.
4. Run `update cloudflare` and verify that deployment IDs, data resource IDs,
   and secret metadata are unchanged.
5. Run `update cloudflare --force`, verify new Worker and Pages deployments,
   and check that data resource IDs and secret metadata are preserved.
6. Preview and run `destroy cloudflare --include-data --delete-secrets-store
--yes`, then verify remote absence and removal of the deployment profile.

Runs are serialized for the Gmail account. A separate `always()` cleanup step
uses an ownership journal written before the first mutation. If setup stops
before saving a complete profile, cleanup checks the exact names assigned to
that run and deletes only those resources. It also deletes the empty test store,
which the CLI normally retains. An unexpected identity, altered profile, or
foreign secret stops deletion. Existing application resources and stores are
not adopted for cleanup.

The workflow reserves time for cleanup and uploads sanitized logs, snapshots,
and the ownership journal as a 14-day artifact. A runner loss or forced workflow
termination can still interrupt cleanup; use the artifact's exact resource names
to inspect any leftovers before starting another live run. Do not run manual
Form Concierge setup on the Gmail account concurrently with this workflow.

## Development Notes

Local `worker/wrangler.jsonc` files are gitignored and generated from the
example configuration during setup.

Downloaded templates are stored in the platform-specific user cache.

The Dart CLI handles orchestration and invokes Node.js, Wrangler, Flutter, and
Jaspr as external processes. Optional D1 helpers under
`tool/cloudflare/*.mjs` are used for local project listing and seeding.

Every published CLI and template version must have an entry in:

```text
lib/src/cloudflare/cloudflare_release_manifest.dart
```

This includes releases that do not require any deployment changes.

| Version | Secrets | D1 migrations | Worker | Admin Pages | Web Pages |
| ------- | ------: | ------------: | -----: | ----------: | --------: |
| 0.1.0   |     Yes |           Yes |    Yes |         Yes |       Yes |
| 0.1.1   |      No |           Yes |    Yes |         Yes |        No |
| 0.2.0   |     Yes |           Yes |    Yes |         Yes |       Yes |
| 0.2.1   |      No |           Yes |    Yes |         Yes |        No |
| 0.3.0   |     Yes |           Yes |    Yes |         Yes |       Yes |
