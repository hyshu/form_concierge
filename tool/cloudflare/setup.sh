#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKER_DIR="$ROOT_DIR/worker"
ADMIN_DIR="$ROOT_DIR/admin_dashboard"
WEB_DIR="$ROOT_DIR/web"

WORKER_NAME="${WORKER_NAME:-form-concierge-api}"
D1_DATABASE_NAME="${D1_DATABASE_NAME:-form_concierge}"
D1_DATABASE_ID="${D1_DATABASE_ID:-}"
API_URL="${API_URL:-}"
ADMIN_PROJECT="${ADMIN_PROJECT:-form-concierge-admin}"
WEB_PROJECT="${WEB_PROJECT:-form-concierge-web}"
WEB_ASSET_BASE_URL="${WEB_ASSET_BASE_URL:-}"

usage() {
  cat <<'USAGE'
Usage:
  tool/cloudflare/setup.sh --database-id <d1-id> [options]

Options:
  --database-id <id>       Cloudflare D1 database UUID
  --database-name <name>   D1 database name (default: form_concierge)
  --worker-name <name>     Worker name (default: form-concierge-api)
  --api-url <url>          Public Worker API URL. If omitted, deploy output is used.
  --admin-project <name>   Pages project for admin (default: form-concierge-admin)
  --web-project <name>     Pages project for public assets (default: form-concierge-web)
  --web-asset-base-url <url>
                           Asset base used by SSR HTML (default: https://<web-project>.pages.dev)
  -h, --help               Show help

Environment variables with the same names also work.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --database-id) D1_DATABASE_ID="$2"; shift 2 ;;
    --database-name) D1_DATABASE_NAME="$2"; shift 2 ;;
    --worker-name) WORKER_NAME="$2"; shift 2 ;;
    --api-url) API_URL="$2"; shift 2 ;;
    --admin-project) ADMIN_PROJECT="$2"; shift 2 ;;
    --web-project) WEB_PROJECT="$2"; shift 2 ;;
    --web-asset-base-url) WEB_ASSET_BASE_URL="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$WEB_ASSET_BASE_URL" ]]; then
  WEB_ASSET_BASE_URL="https://${WEB_PROJECT}.pages.dev"
fi

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing command: $1" >&2
    exit 1
  fi
}

require_cmd curl
require_cmd dart
require_cmd flutter
require_cmd jq
require_cmd node
require_cmd npm
require_cmd npx

if ! command -v jaspr >/dev/null 2>&1; then
  dart pub global activate jaspr_cli
  JASPR_CMD=(dart pub global run jaspr_cli:jaspr)
else
  JASPR_CMD=(jaspr)
fi

read_wrangler_value() {
  node - "$WORKER_DIR/wrangler.jsonc" "$1" <<'NODE'
const fs = require('fs');
const [file, key] = process.argv.slice(2);
const config = JSON.parse(fs.readFileSync(file, 'utf8'));
if (key === 'database_id') {
  process.stdout.write(config.d1_databases?.[0]?.database_id ?? '');
} else if (key === 'public_base_url') {
  process.stdout.write(config.vars?.PUBLIC_BASE_URL ?? '');
}
NODE
}

if [[ -z "$D1_DATABASE_ID" ]]; then
  D1_DATABASE_ID="$(read_wrangler_value database_id)"
fi

if [[ -z "$D1_DATABASE_ID" || "$D1_DATABASE_ID" == replace-* ]]; then
  echo "--database-id required" >&2
  exit 1
fi

if [[ -z "$API_URL" ]]; then
  API_URL="$(read_wrangler_value public_base_url)"
fi

update_wrangler() {
  node - "$WORKER_DIR/wrangler.jsonc" "$WORKER_NAME" "$D1_DATABASE_NAME" "$D1_DATABASE_ID" "$API_URL" "$WEB_ASSET_BASE_URL" <<'NODE'
const fs = require('fs');
const [file, workerName, databaseName, databaseId, apiUrl, assetBaseUrl] = process.argv.slice(2);
const config = JSON.parse(fs.readFileSync(file, 'utf8'));
config.name = workerName;
config.d1_databases = [{
  binding: 'DB',
  database_name: databaseName,
  database_id: databaseId,
  migrations_dir: 'migrations',
}];
config.vars = config.vars ?? {};
if (apiUrl) config.vars.PUBLIC_BASE_URL = apiUrl.replace(/\/+$/, '');
config.vars.PUBLIC_FORM_ASSET_BASE_URL = assetBaseUrl.replace(/\/+$/, '');
fs.writeFileSync(file, `${JSON.stringify(config, null, 2)}\n`);
NODE
}

deploy_worker() {
  local output_file parsed_url
  output_file="$(mktemp)"
  (cd "$WORKER_DIR" && npx wrangler deploy) 2>&1 | tee "$output_file" >&2
  parsed_url="$(grep -Eo 'https://[^[:space:]]+workers.dev' "$output_file" | tail -n 1 || true)"
  rm -f "$output_file"
  if [[ -n "$parsed_url" ]]; then
    printf '%s' "$parsed_url"
  fi
}

ensure_pages_project() {
  local project="$1"
  (cd "$WORKER_DIR" && npx wrangler pages project create "$project" --production-branch=main) >/dev/null 2>&1 || true
}

inject_web_index_api_url() {
  local index_file="$WEB_DIR/build/jaspr/index.html"
  node - "$index_file" "$API_URL" <<'NODE'
const fs = require('fs');
const [file, apiUrl] = process.argv.slice(2);
let html = fs.readFileSync(file, 'utf8');
const meta = `<meta name="form-concierge-api-url" content="${apiUrl.replace(/&/g, '&amp;').replace(/"/g, '&quot;')}">`;
if (html.includes('name="form-concierge-api-url"')) {
  html = html.replace(/<meta name="form-concierge-api-url" content="[^"]*">/, meta);
} else {
  html = html.replace(/(<meta name="viewport"[^>]*>)/, `$1\n  ${meta}`);
}
fs.writeFileSync(file, html);
NODE
}

echo "==> Wrangler auth"
(cd "$WORKER_DIR" && npx wrangler whoami >/dev/null)

echo "==> Configure Worker"
update_wrangler

echo "==> Worker typecheck"
(cd "$WORKER_DIR" && npm install >/dev/null && npm run typecheck)

echo "==> Apply D1 migrations"
(cd "$WORKER_DIR" && npx wrangler d1 migrations apply "$D1_DATABASE_NAME" --remote)

echo "==> Deploy Worker"
DEPLOYED_API_URL="$(deploy_worker)"
if [[ -z "$API_URL" || "$API_URL" == replace-* ]]; then
  if [[ -z "$DEPLOYED_API_URL" ]]; then
    echo "Could not infer Worker URL. Re-run with --api-url." >&2
    exit 1
  fi
  API_URL="$DEPLOYED_API_URL"
  echo "==> Update Worker public URL: $API_URL"
  update_wrangler
  deploy_worker >/dev/null
fi

echo "==> Build admin"
(cd "$ADMIN_DIR" && flutter pub get >/dev/null && flutter build web --release)
printf '{"apiUrl":"%s"}' "$API_URL" > "$ADMIN_DIR/build/web/assets/assets/config.json"

echo "==> Deploy admin Pages: $ADMIN_PROJECT"
ensure_pages_project "$ADMIN_PROJECT"
(cd "$WORKER_DIR" && npx wrangler pages deploy "$ADMIN_DIR/build/web" --project-name "$ADMIN_PROJECT" --commit-dirty=true)

echo "==> Build public form assets"
(cd "$WEB_DIR" && dart pub get >/dev/null && "${JASPR_CMD[@]}" build)
inject_web_index_api_url

echo "==> Deploy public form assets Pages: $WEB_PROJECT"
ensure_pages_project "$WEB_PROJECT"
(cd "$WORKER_DIR" && npx wrangler pages deploy "$WEB_DIR/build/jaspr" --project-name "$WEB_PROJECT" --commit-dirty=true)

echo "==> Done"
echo "API: $API_URL"
echo "Admin: https://${ADMIN_PROJECT}.pages.dev"
echo "Public assets: https://${WEB_PROJECT}.pages.dev"
