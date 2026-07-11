# form_concierge_cli

CLI for Form Concierge setup and local tooling.

Not published to pub.dev yet (`publish_to: none`).

## Install (local monorepo)

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

`setup cloudflare` accepts flags such as `--preflight-only`,
`--seed-project-id`, `--worker-name`, and others listed in
`form_concierge setup cloudflare --help`.

## Notes

- The CLI expects a full monorepo checkout (markers: `worker/wrangler.jsonc`
  and `admin_dashboard/pubspec.yaml`). Template download for a published-only
  install is not implemented yet.
- Backend setup shells out to Node.js / Wrangler / Flutter / Jaspr; the Dart CLI
  owns orchestration. Optional D1 helpers under `tool/cloudflare/*.mjs` are used
  for local project list/seed.
