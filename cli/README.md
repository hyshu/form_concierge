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

Destroy keeps D1, R2, and Secrets Store by default. Use `--include-data` to
delete D1 and an empty R2 bucket. A non-empty R2 bucket is retained with a
warning. Secrets Store deletion requires `--delete-secrets-store`.

`setup cloudflare` accepts flags such as `--preflight-only`,
`--seed-project-id`, `--worker-name`, and others listed in
`form_concierge setup cloudflare --help`.

Use `--no-admin-pages` to skip the admin Cloudflare Pages project. This choice
is saved in `.form_concierge/deployment.json` and reused by `update`. Use
`--admin-pages` on a later setup or update to enable it again.

Build a local macOS admin app using the saved Worker URL:

```bash
form_concierge build admin-macos
```

Use `--api-url` to override the Worker URL and `--output` to choose the copy
destination.

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
- Setup saves non-secret deployment settings in
  `.form_concierge/deployment.json`. Update uses that file as its source of
  truth and prompts for any missing settings.
- Backend setup shells out to Node.js / Wrangler / Flutter / Jaspr; the Dart CLI
  owns orchestration. Optional D1 helpers under `tool/cloudflare/*.mjs` are used
  for local project list/seed.
