#!/usr/bin/env bash
set -euo pipefail

INVOCATION_DIR="$(pwd -P)"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKER_DIR="$ROOT_DIR/worker"
ADMIN_DIR="$ROOT_DIR/admin_dashboard"
WEB_DIR="$ROOT_DIR/web"
WRANGLER_BIN="$WORKER_DIR/node_modules/.bin/wrangler"

DEFAULT_WORKER_NAME="${DEFAULT_WORKER_NAME:-form-concierge-api}"
WORKER_NAME="${WORKER_NAME:-}"
DEFAULT_D1_DATABASE_NAME="${DEFAULT_D1_DATABASE_NAME:-form_concierge}"
D1_DATABASE_NAME="${D1_DATABASE_NAME:-}"
D1_DATABASE_ID="${D1_DATABASE_ID:-}"
PROJECT_ID="${PROJECT_ID:-}"
API_URL="${API_URL:-}"
DEFAULT_ADMIN_PROJECT="${DEFAULT_ADMIN_PROJECT:-form-concierge-admin}"
ADMIN_PROJECT="${ADMIN_PROJECT:-}"
DEFAULT_WEB_PROJECT="${DEFAULT_WEB_PROJECT:-form-concierge-web}"
WEB_PROJECT="${WEB_PROJECT:-}"
WEB_ASSET_BASE_URL="${WEB_ASSET_BASE_URL:-}"
DEFAULT_R2_BUCKET_NAME="${DEFAULT_R2_BUCKET_NAME:-form-concierge-media}"
R2_BUCKET_NAME="${R2_BUCKET_NAME:-}"
R2_BINDING="${R2_BINDING:-MEDIA_BUCKET}"
LOCAL_D1_PERSIST_TO="${LOCAL_D1_PERSIST_TO:-}"
REMOTE_BINDINGS_FOR_LOCAL_DEV="${REMOTE_BINDINGS_FOR_LOCAL_DEV:-}"
WRANGLER_UPDATE_CONFIG="${WRANGLER_UPDATE_CONFIG:-}"
SEED_FILE=""
LIST_LOCAL_PROJECTS=0
PREFLIGHT_ONLY=0

usage() {
  cat <<'USAGE'
Usage:
  ./setup.sh [options]
  ./setup.sh --seed-project-id <id> [options]

Options:
  --explain              Print setup overview without deploying
  --preflight-only
                           Check local tools and Cloudflare auth without deploying
  --list-local-projects
                           Print local project IDs from the local D1 database
  --seed-project-id <id>   Optional local Form Concierge project ID to seed remotely
  --project-id <id>        Alias for --seed-project-id
  --database-id <id>       Cloudflare D1 database UUID
  --database-name <name>   D1 database name
  --worker-name <name>     Worker name
  --r2-bucket-name <name>
                           R2 bucket for future media uploads
  --r2-binding <name>      Worker R2 binding name (default: MEDIA_BUCKET)
  --wrangler-update-config
                           Let Wrangler update config when creating D1/R2 resources
  --no-wrangler-update-config
                           Do not let Wrangler update config when creating D1/R2 resources
  --remote-bindings-for-local-dev
                           Use remote D1/R2 bindings during wrangler dev
  --local-bindings-for-local-dev
                           Use local D1/R2 bindings during wrangler dev (default)
  --api-url <url>          Public Worker API URL. If omitted, deploy output is used.
  --admin-project <name>   Pages project for admin
  --web-project <name>     Pages project for public assets
  --web-asset-base-url <url>
                           Asset base used by SSR HTML (default: https://<web-project>.pages.dev)
  --local-d1-persist-to <path>
                           Optional local D1 state path used when reading the source project
  -h, --help               Show help

Environment variables with the same names also work.
USAGE
}

no_args_instructions() {
  cat <<'INSTRUCTIONS'
Cloudflare setup creates/configures D1, R2, Worker, and Pages resources.

Required before running setup:

  cd worker
  npm install
  npx wrangler login
  npx wrangler whoami

Also install Dart, Flutter, Node.js/npm. Jaspr CLI is installed automatically
when missing.

Run setup:

  ./setup.sh

By default, wrangler dev uses local D1/R2 resources. To use remote bindings
for local dev too:

  ./setup.sh --remote-bindings-for-local-dev

Resource names are prompted during interactive setup. For non-interactive setup,
pass --worker-name, --database-name, --r2-bucket-name, --admin-project, and
--web-project, or set the matching environment variables.

After setup, open the deployed admin Pages URL, create the first admin, and
create projects there.

Optional: seed an existing local project into remote D1:

  ./setup.sh --list-local-projects
  ./setup.sh --seed-project-id <project-id>
INSTRUCTIONS
}

check_commands() {
  local missing=()
  for cmd in dart flutter node npm npx; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done
  if [[ "${#missing[@]}" -gt 0 ]]; then
    echo "Missing required command(s): ${missing[*]}" >&2
    echo "Install Dart, Flutter, Node.js/npm, then rerun setup." >&2
    exit 1
  fi
}

install_worker_dependencies() {
  echo "==> Install Worker dependencies"
  (cd "$WORKER_DIR" && npm install >/dev/null)
}

ensure_wrangler_auth() {
  echo "==> Wrangler auth"
  local output_file
  output_file="$(mktemp)"
  set +e
  (cd "$WORKER_DIR" && npx wrangler whoami) >"$output_file" 2>&1
  local status="$?"
  set -e
  if [[ "$status" -ne 0 ]]; then
    cat "$output_file" >&2
    rm -f "$output_file"
    cat >&2 <<'ERROR'

Wrangler preflight failed.

If this is an authentication failure, run one of:

  cd worker
  npx wrangler login

or set CLOUDFLARE_API_TOKEN with permissions for Workers, D1, R2, and Pages.

If Wrangler reported a configuration error above, fix worker/wrangler.jsonc first.
ERROR
    exit 1
  fi
  rm -f "$output_file"
}

ensure_jaspr() {
  if ! command -v jaspr >/dev/null 2>&1; then
    echo "==> Install Jaspr CLI"
    dart pub global activate jaspr_cli 0.23.1
    JASPR_CMD=(dart pub global run jaspr_cli:jaspr)
  else
    JASPR_CMD=(jaspr)
  fi
}

normalize_remote_bindings_for_local_dev() {
  case "$REMOTE_BINDINGS_FOR_LOCAL_DEV" in
    1|true|TRUE|y|Y|yes|YES) REMOTE_BINDINGS_FOR_LOCAL_DEV=1 ;;
    0|false|FALSE|n|N|no|NO|"") REMOTE_BINDINGS_FOR_LOCAL_DEV=0 ;;
    *)
      echo "REMOTE_BINDINGS_FOR_LOCAL_DEV must be 0/1, true/false, or yes/no." >&2
      exit 1
      ;;
  esac
}

normalize_wrangler_update_config() {
  case "$WRANGLER_UPDATE_CONFIG" in
    1|true|TRUE|y|Y|yes|YES|"") WRANGLER_UPDATE_CONFIG=1 ;;
    0|false|FALSE|n|N|no|NO) WRANGLER_UPDATE_CONFIG=0 ;;
    *)
      echo "WRANGLER_UPDATE_CONFIG must be 0/1, true/false, or yes/no." >&2
      exit 1
      ;;
  esac
}

select_wrangler_update_config() {
  if [[ -z "$WRANGLER_UPDATE_CONFIG" && -t 0 ]]; then
    local answer
    printf 'Let Wrangler add created D1/R2 resources to worker/wrangler.jsonc? [Y/n] ' >&2
    if read -r answer; then
      WRANGLER_UPDATE_CONFIG="$answer"
    fi
  fi
  normalize_wrangler_update_config
}

select_remote_bindings_for_local_dev() {
  if [[ -z "$REMOTE_BINDINGS_FOR_LOCAL_DEV" && -t 0 ]]; then
    local answer
    printf 'Use remote D1/R2 bindings for local wrangler dev? [y/N] ' >&2
    if read -r answer; then
      REMOTE_BINDINGS_FOR_LOCAL_DEV="$answer"
    fi
  fi
  normalize_remote_bindings_for_local_dev
}

prompt_name() {
  local label="$1"
  local default_value="$2"
  local value
  if [[ -t 0 ]]; then
    local answer
    printf '%s \033[2m%s\033[0m ' "$label" "$default_value" >&2
    if read -r answer; then
      value="${answer:-$default_value}"
    fi
  else
    value=""
  fi
  printf '%s' "$value"
}

select_resource_names() {
  if [[ -z "$WORKER_NAME" ]]; then
    WORKER_NAME="$(prompt_name "Worker name" "$DEFAULT_WORKER_NAME")"
  fi
  if [[ -z "$D1_DATABASE_NAME" ]]; then
    D1_DATABASE_NAME="$(prompt_name "D1 database name" "$DEFAULT_D1_DATABASE_NAME")"
  fi
  if [[ -z "$R2_BUCKET_NAME" ]]; then
    R2_BUCKET_NAME="$(prompt_name "R2 bucket name" "$DEFAULT_R2_BUCKET_NAME")"
  fi
  if [[ -z "$ADMIN_PROJECT" ]]; then
    ADMIN_PROJECT="$(prompt_name "Admin Pages project" "$DEFAULT_ADMIN_PROJECT")"
  fi
  if [[ -z "$WEB_PROJECT" ]]; then
    WEB_PROJECT="$(prompt_name "Public assets Pages project" "$DEFAULT_WEB_PROJECT")"
  fi

  if [[ -z "$WORKER_NAME" || -z "$D1_DATABASE_NAME" || -z "$R2_BUCKET_NAME" || -z "$ADMIN_PROJECT" || -z "$WEB_PROJECT" ]]; then
    cat >&2 <<'ERROR'
Resource names are required.

Run setup interactively, or pass one of:

  ./setup.sh --worker-name <worker-name> \
    --database-name <database-name> \
    --r2-bucket-name <bucket-name> \
    --admin-project <pages-project> \
    --web-project <pages-project>

or set environment variables:

  WORKER_NAME=<worker-name> \
    D1_DATABASE_NAME=<database-name> \
    R2_BUCKET_NAME=<bucket-name> \
    ADMIN_PROJECT=<pages-project> \
    WEB_PROJECT=<pages-project> \
    ./setup.sh

At minimum, include:

  ./setup.sh --r2-bucket-name <bucket-name>
ERROR
    exit 1
  fi
}

run_preflight() {
  echo "==> Preflight"
  check_commands
  install_worker_dependencies
  ensure_wrangler_auth
  ensure_jaspr
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

if [[ "${1:-}" == "--explain" ]]; then
  no_args_instructions
  exit 0
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --explain) no_args_instructions; exit 0 ;;
    --preflight-only) PREFLIGHT_ONLY=1; shift ;;
    --list-local-projects) LIST_LOCAL_PROJECTS=1; shift ;;
    --seed-project-id) PROJECT_ID="$2"; shift 2 ;;
    --project-id) PROJECT_ID="$2"; shift 2 ;;
    --database-id) D1_DATABASE_ID="$2"; shift 2 ;;
    --database-name) D1_DATABASE_NAME="$2"; shift 2 ;;
    --worker-name) WORKER_NAME="$2"; shift 2 ;;
    --r2-bucket-name) R2_BUCKET_NAME="$2"; shift 2 ;;
    --r2-binding) R2_BINDING="$2"; shift 2 ;;
    --wrangler-update-config) WRANGLER_UPDATE_CONFIG=1; shift ;;
    --no-wrangler-update-config) WRANGLER_UPDATE_CONFIG=0; shift ;;
    --remote-bindings-for-local-dev) REMOTE_BINDINGS_FOR_LOCAL_DEV=1; shift ;;
    --local-bindings-for-local-dev) REMOTE_BINDINGS_FOR_LOCAL_DEV=0; shift ;;
    --api-url) API_URL="$2"; shift 2 ;;
    --admin-project) ADMIN_PROJECT="$2"; shift 2 ;;
    --web-project) WEB_PROJECT="$2"; shift 2 ;;
    --web-asset-base-url) WEB_ASSET_BASE_URL="$2"; shift 2 ;;
    --local-d1-persist-to) LOCAL_D1_PERSIST_TO="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    [0-9]*)
      if [[ -n "$PROJECT_ID" ]]; then
        echo "Project ID specified more than once" >&2
        exit 1
      fi
      PROJECT_ID="$1"
      shift
      ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -n "$LOCAL_D1_PERSIST_TO" && "$LOCAL_D1_PERSIST_TO" != /* ]]; then
  LOCAL_D1_PERSIST_TO="$INVOCATION_DIR/$LOCAL_D1_PERSIST_TO"
fi

if [[ "$LIST_LOCAL_PROJECTS" == "1" ]]; then
  check_commands
  install_worker_dependencies
  D1_DATABASE_NAME="${D1_DATABASE_NAME:-$DEFAULT_D1_DATABASE_NAME}"
  (cd "$WORKER_DIR" && LOCAL_D1_PERSIST_TO="$LOCAL_D1_PERSIST_TO" node "$ROOT_DIR/tool/cloudflare/list_local_projects.mjs" "$D1_DATABASE_NAME")
  exit 0
fi

if [[ -n "$PROJECT_ID" ]]; then
  if [[ ! "$PROJECT_ID" =~ ^[0-9]+$ || "$PROJECT_ID" == "0" ]]; then
    echo "Project ID must be a positive integer." >&2
    exit 1
  fi
fi

cleanup() {
  if [[ -n "$SEED_FILE" ]]; then
    rm -f "$SEED_FILE"
  fi
}
trap cleanup EXIT

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

find_d1_database_id() {
  local json
  json="$(cd "$WORKER_DIR" && npx wrangler d1 list --json)"
  node - "$D1_DATABASE_NAME" "$json" <<'NODE'
const [name, raw] = process.argv.slice(2);
const parsed = JSON.parse(raw);
const databases = Array.isArray(parsed) ? parsed : parsed.result ?? parsed.databases ?? [];
const match = databases.find((db) => db.name === name || db.database_name === name);
process.stdout.write(match?.uuid ?? match?.id ?? match?.database_id ?? '');
NODE
}

ensure_d1_database() {
  if [[ -z "$D1_DATABASE_ID" || "$D1_DATABASE_ID" == replace-* ]]; then
    D1_DATABASE_ID="$(find_d1_database_id)"
  fi

  if [[ -z "$D1_DATABASE_ID" ]]; then
    local update_config_arg="false"
    local use_remote_arg="false"
    [[ "$WRANGLER_UPDATE_CONFIG" == "1" ]] && update_config_arg="true"
    [[ "$REMOTE_BINDINGS_FOR_LOCAL_DEV" == "1" ]] && use_remote_arg="true"

    echo "==> Create D1 database: $D1_DATABASE_NAME"
    (
      cd "$WORKER_DIR"
      npx wrangler d1 create "$D1_DATABASE_NAME" \
        "--update-config=$update_config_arg" \
        --binding=DB \
        "--use-remote=$use_remote_arg"
    )
    D1_DATABASE_ID="$(find_d1_database_id)"
  fi

  if [[ -z "$D1_DATABASE_ID" ]]; then
    echo "Could not resolve D1 database ID for $D1_DATABASE_NAME." >&2
    exit 1
  fi
}

ensure_r2_bucket() {
  if (cd "$WORKER_DIR" && npx wrangler r2 bucket info "$R2_BUCKET_NAME" >/dev/null 2>&1); then
    return 0
  fi

  echo "==> Create R2 bucket: $R2_BUCKET_NAME"
  local update_config_arg="false"
  local use_remote_arg="false"
  [[ "$WRANGLER_UPDATE_CONFIG" == "1" ]] && update_config_arg="true"
  [[ "$REMOTE_BINDINGS_FOR_LOCAL_DEV" == "1" ]] && use_remote_arg="true"

  (
    cd "$WORKER_DIR"
    npx wrangler r2 bucket create "$R2_BUCKET_NAME" \
      "--update-config=$update_config_arg" \
      "--binding=$R2_BINDING" \
      "--use-remote=$use_remote_arg"
  )
}

wait_for_r2_bucket() {
  local attempt
  for attempt in {1..30}; do
    if (cd "$WORKER_DIR" && npx wrangler r2 bucket info "$R2_BUCKET_NAME" >/dev/null 2>&1); then
      return 0
    fi
    sleep 2
  done

  echo "R2 bucket is not visible to Wrangler yet: $R2_BUCKET_NAME" >&2
  exit 1
}

export_local_project_seed() {
  SEED_FILE="$(mktemp)"
  (cd "$WORKER_DIR" && LOCAL_D1_PERSIST_TO="$LOCAL_D1_PERSIST_TO" node "$ROOT_DIR/tool/cloudflare/export_project_seed.mjs" "$D1_DATABASE_NAME" "$PROJECT_ID" "$SEED_FILE")
}

update_wrangler() {
  node - "$WORKER_DIR/wrangler.jsonc" "$WORKER_NAME" "$D1_DATABASE_NAME" "$D1_DATABASE_ID" "$API_URL" "$WEB_ASSET_BASE_URL" "$R2_BUCKET_NAME" "$R2_BINDING" "$REMOTE_BINDINGS_FOR_LOCAL_DEV" <<'NODE'
const fs = require('fs');
const [file, workerName, databaseName, databaseId, apiUrl, assetBaseUrl, r2BucketName, r2Binding, remoteBindingsForLocalDev] = process.argv.slice(2);
const remote = remoteBindingsForLocalDev === '1';
const config = JSON.parse(fs.readFileSync(file, 'utf8'));
config.name = workerName;
config.d1_databases = [{
  binding: 'DB',
  database_name: databaseName,
  database_id: databaseId,
  migrations_dir: 'migrations',
  remote,
}];
config.r2_buckets = [{
  binding: r2Binding,
  bucket_name: r2BucketName,
  remote,
}];
config.vars = config.vars ?? {};
if (apiUrl) config.vars.PUBLIC_BASE_URL = apiUrl.replace(/\/+$/, '');
config.vars.PUBLIC_FORM_ASSET_BASE_URL = assetBaseUrl.replace(/\/+$/, '');
fs.writeFileSync(file, `${JSON.stringify(config, null, 2)}\n`);
NODE
}

deploy_worker() {
  local attempt output_file parsed_url status
  for attempt in 1 2 3; do
    output_file="$(mktemp)"
    set +e
    (cd "$WORKER_DIR" && npx wrangler deploy) 2>&1 | tee "$output_file" >&2
    status="${PIPESTATUS[0]}"
    set -e

    parsed_url="$(grep -Eo 'https://[^[:space:]]+workers.dev' "$output_file" | tail -n 1 || true)"
    if [[ "$status" -eq 0 ]]; then
      rm -f "$output_file"
      if [[ -n "$parsed_url" ]]; then
        printf '%s' "$parsed_url"
      fi
      return 0
    fi

    if grep -q "R2 bucket .* not found" "$output_file" && [[ "$attempt" -lt 3 ]]; then
      rm -f "$output_file"
      echo "R2 bucket is not visible to Worker deploy yet; retrying..." >&2
      wait_for_r2_bucket
      sleep $((attempt * 5))
      continue
    fi

    rm -f "$output_file"
    return "$status"
  done
}

ensure_pages_project() {
  local project="$1"
  (cd "$ROOT_DIR" && "$WRANGLER_BIN" pages project create "$project" --production-branch=main) >/dev/null 2>&1 || true
}

seed_remote_project() {
  (cd "$WORKER_DIR" && npx wrangler d1 execute "$D1_DATABASE_NAME" --remote --file "$SEED_FILE" --yes)
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

run_preflight

if [[ "$PREFLIGHT_ONLY" == "1" ]]; then
  echo "Preflight OK."
  exit 0
fi

select_wrangler_update_config
select_remote_bindings_for_local_dev
select_resource_names

if [[ -z "$WEB_ASSET_BASE_URL" ]]; then
  WEB_ASSET_BASE_URL="https://${WEB_PROJECT}.pages.dev"
fi

if [[ "$WRANGLER_UPDATE_CONFIG" == "1" ]]; then
  echo "==> Wrangler config update: yes"
else
  echo "==> Wrangler config update: no"
fi

if [[ "$REMOTE_BINDINGS_FOR_LOCAL_DEV" == "1" ]]; then
  echo "==> Local dev bindings: remote D1/R2"
else
  echo "==> Local dev bindings: local D1/R2"
fi

if [[ -z "$API_URL" ]]; then
  API_URL="$(read_wrangler_value public_base_url)"
fi

if [[ "$API_URL" == replace-* || "$API_URL" == http://localhost:* || "$API_URL" == http://127.0.0.1:* ]]; then
  API_URL=""
fi

if [[ -n "$PROJECT_ID" ]]; then
  echo "==> Export local project seed: $PROJECT_ID"
  export_local_project_seed
else
  echo "==> Project seed: skipped"
fi

ensure_d1_database
ensure_r2_bucket
wait_for_r2_bucket

echo "==> Configure Worker"
update_wrangler

echo "==> Worker typecheck"
(cd "$WORKER_DIR" && npm run typecheck)

echo "==> Apply D1 migrations"
(cd "$WORKER_DIR" && CI=1 npx wrangler d1 migrations apply "$D1_DATABASE_NAME" --remote)

if [[ -n "$PROJECT_ID" ]]; then
  echo "==> Seed remote D1 project: $PROJECT_ID"
  seed_remote_project
fi

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
(cd "$ROOT_DIR" && "$WRANGLER_BIN" pages deploy "$ADMIN_DIR/build/web" --project-name "$ADMIN_PROJECT" --commit-dirty=true)

echo "==> Build public form assets"
(cd "$WEB_DIR" && dart pub get >/dev/null && "${JASPR_CMD[@]}" build)
inject_web_index_api_url

echo "==> Deploy public form assets Pages: $WEB_PROJECT"
ensure_pages_project "$WEB_PROJECT"
(cd "$ROOT_DIR" && "$WRANGLER_BIN" pages deploy "$WEB_DIR/build/jaspr" --project-name "$WEB_PROJECT" --commit-dirty=true)

echo "==> Done"
echo "API: $API_URL"
echo "Admin: https://${ADMIN_PROJECT}.pages.dev"
echo "Public assets: https://${WEB_PROJECT}.pages.dev"
echo "R2 bucket: $R2_BUCKET_NAME"
