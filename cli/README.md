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
| `form_concierge setup cloudflare` | Delegate to `tool/cloudflare/setup.sh` (D1, R2, Worker, Pages) |

`setup cloudflare` forwards flags such as `--preflight-only`,
`--seed-project-id`, `--worker-name`, and the other options documented in
`./setup.sh --help`.

## Notes

- Today the CLI expects a full monorepo checkout (markers: `worker/` and
  `tool/cloudflare/setup.sh`). Template download for a published-only install
  is not implemented yet.
- Backend setup still requires Node.js and Wrangler; the Dart CLI orchestrates
  the existing shell setup script.
