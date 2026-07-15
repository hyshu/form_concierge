## 0.3.0

- Prefix Secrets Store entry names with `form_concierge_` to avoid collisions
  with other applications using the same store. Updates from 0.2.1 or earlier
  copy usable values from the previous unprefixed entries without overwriting
  values already configured under the new names.
- Before deploying the Worker, generate types from that deployment's
  `wrangler.jsonc` and type-check the Worker against its actual D1, R2, rate
  limiter, and Secrets Store bindings.
- Remove the `--r2-binding` option and always use the `MEDIA_BUCKET` binding
  required by the Worker source. The R2 bucket name remains configurable.
- Configure deployment quotas for responses, image uploads and retained
  storage, AI follow-up generation, and notification email. The generated
  `QUOTA_*` Worker variables can be adjusted before deployment.
- Improve resumable Cloudflare resource cleanup while retaining data stores by
  default.

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
