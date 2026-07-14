## 0.2.1

- Deploy only the Cloudflare components changed between the installed and
  target template versions during updates.
- Add version-aware deployment plans with safe full-deployment fallbacks and a
  `--force` override.

## 0.2.0

- Add `update cloudflare` to redeploy from saved deployment settings.
- Add `destroy cloudflare` with safe defaults and resumable cleanup.
- Add `build admin-macos` for local macOS admin application builds.
- Persist non-secret Cloudflare deployment settings for later updates and
  builds.
- Support named global deployment configurations and `--deployment` selection.
- Add optional admin Pages deployment and Groq secret provisioning.

## 0.1.1

- Align default template version with the monorepo release line (`0.1.1`).
- Standalone installs download `form-concierge-template-0.1.1` by default
  (includes CAPTCHA login and related worker/admin/client updates).

## 0.1.0

- First public release.
- `doctor` and `setup cloudflare` commands (pure Dart orchestration).
- Download, verify, cache, and use versioned GitHub Release templates when the
  CLI runs outside a Form Concierge checkout.
