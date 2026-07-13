# form_concierge_cli

CLI for Form Concierge setup and local tooling.

## Install

```bash
dart pub global activate form_concierge_cli
```

The CLI uses files from a local Form Concierge checkout when available.
Standalone installs download the matching versioned template from the project's
GitHub Release, verify its SHA-256 checksum, and reuse a local cache.

## Install from source

```bash
cd cli
dart pub get

# From anywhere inside the monorepo:
dart run form_concierge_cli setup cloudflare --preflight-only

# Or activate the executable name `form_concierge`:
dart pub global activate --source path .
form_concierge doctor
form_concierge setup cloudflare
```

`dart run form_concierge_cli` works because the package defines a matching
executable. After global activate, the command is also available as
`form_concierge`.

## Commands

| Command | Description |
|---------|-------------|
| `form_concierge doctor` | Check dart / flutter / node / npm / wrangler and monorepo layout |
| `form_concierge setup cloudflare` | Create/configure D1, R2, Worker, and Pages |
| `form_concierge update cloudflare` | Reuse saved deployment settings, migrate, build, and deploy |
| `form_concierge destroy cloudflare` | Delete resources recorded in deployment settings |
| `form_concierge build admin-macos` | Build the macOS admin app and copy it to the current directory |

Destroy keeps D1, R2, and Secrets Store by default:

```bash
form_concierge destroy cloudflare --dry-run
form_concierge destroy cloudflare
```

| Option | Description |
|--------|-------------|
| `--dry-run` | Print the deletion plan without deleting resources |
| `--include-data` | Also delete D1 and the R2 bucket when it is empty |
| `--empty-r2` | Request R2 content deletion; currently stops with manual-emptying instructions |
| `--delete-secrets-store` | Delete the Secrets Store and all its values |
| `--yes`, `-y` | Skip the interactive confirmation |

A non-empty R2 bucket is retained with a warning. Successful deletions are
removed from the deployment file as they happen, so an interrupted or partial
destroy can be run again for the remaining resources.

`setup cloudflare` accepts flags such as `--preflight-only`,
`--seed-project-id`, `--worker-name`, and others listed in
`form_concierge setup cloudflare --help`.

Setup creates Worker Secrets Store bindings for supported provider keys,
including `groq_api_key`, alongside the OpenAI, Claude, Gemini, and Cerebras
keys. Missing entries are created as placeholders for later configuration.

Update an existing deployment from its saved settings:

```bash
form_concierge update cloudflare
```

Command-line values override saved values. Missing values are prompted for and
the resulting settings are written back to
`~/.form_concierge/deployments/<name>.json`.

Use `--deployment <name>` to select a deployment explicitly:

```bash
form_concierge setup cloudflare --deployment production
form_concierge update cloudflare --deployment production
```

Without this option, the only saved deployment is selected automatically. If
multiple deployments exist, an interactive command prompts for one; a
non-interactive command requires `--deployment`. Initial setup uses `default`
when no deployments exist.

Use `--no-admin-pages` to skip the admin Cloudflare Pages project. This choice
is saved in the selected deployment file and reused by `update`. Use
`--admin-pages` on a later setup or update to enable it again.

Build a local macOS admin app using the saved Worker URL:

```bash
form_concierge build admin-macos
```

Use `--api-url` to override the Worker URL and `--output` / `-o` to choose the
copy destination. This command only runs on macOS. Existing destination apps
with the same name are replaced.

Template options:

| Option | Description |
|--------|-------------|
| `--template-version` | Release version; defaults to the CLI version |
| `--template-url` | Custom template archive URL |
| `--template-sha256` | Expected SHA-256 for a custom archive |
| `--offline` | Require a checkout or cached template |
| `--refresh-template` | Replace the cached template |

## Notes

- Local `worker/wrangler.jsonc` is gitignored and created from the example by
  setup. Downloaded templates are cached under the platform user cache.
- Setup saves non-secret deployment settings under
  `~/.form_concierge/deployments/`. Update uses the selected file as its source
  of truth and prompts for any missing settings.
- Backend setup shells out to Node.js / Wrangler / Flutter / Jaspr; the Dart CLI
  owns orchestration. Optional D1 helpers under `tool/cloudflare/*.mjs` are used
  for local project list/seed.
