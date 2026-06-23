#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

export API_URL="${API_URL:-http://127.0.0.1:8787}"
export ADMIN_URL="${ADMIN_URL:-http://127.0.0.1:8080}"
export WEB_FORM_URL="${WEB_FORM_URL:-http://127.0.0.1:8081}"
export ADMIN_EMAIL="${ADMIN_EMAIL:-e2e-admin@example.com}"
export ADMIN_PASSWORD="${ADMIN_PASSWORD:-password12345}"
export PATH="$HOME/.pub-cache/bin:$PATH"

PIDS=()

cleanup() {
  for pid in "${PIDS[@]:-}"; do
    if kill -0 "$pid" >/dev/null 2>&1; then
      pkill -P "$pid" >/dev/null 2>&1 || true
      kill "$pid" >/dev/null 2>&1 || true
    fi
  done
}
trap cleanup EXIT

start_background() {
  "$@" &
  PIDS+=("$!")
}

wait_for() {
  local url="$1"
  local attempts="${2:-120}"
  for _ in $(seq 1 "$attempts"); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  echo "Timed out waiting for $url" >&2
  return 1
}

if ! command -v jaspr >/dev/null 2>&1; then
  dart pub global activate jaspr_cli 0.23.1
fi

mkdir -p .tmp e2e/.artifacts
rm -rf .tmp/e2e-d1 e2e/.artifacts/*

(
  cd worker
  npm ci
  printf 'y\n' | npx wrangler d1 migrations apply form_concierge \
    --local \
    --persist-to ../.tmp/e2e-d1
)

(
  cd e2e
  npm ci
  npx playwright install --with-deps chromium
)

start_background bash -lc "cd '$ROOT_DIR/worker' && npx wrangler dev --local --persist-to ../.tmp/e2e-d1 --ip 127.0.0.1 --port 8787 --log-level error"
wait_for "$API_URL/api/config"

node e2e/scripts/seed.mjs

(
  cd admin_dashboard
  flutter pub get
  flutter build web --release --dart-define=FORM_CONCIERGE_API_URL="$API_URL"
)
node <<'EOF'
const fs = require('fs');
const file = 'admin_dashboard/build/web/assets/assets/config.json';
const apiUrl = process.env.API_URL;
fs.writeFileSync(file, `${JSON.stringify({ apiUrl })}\n`);
EOF
start_background bash -lc "cd '$ROOT_DIR/e2e' && npx serve -s ../admin_dashboard/build/web -l tcp://127.0.0.1:8080 --no-clipboard"
wait_for "$ADMIN_URL"

(
  cd e2e
  ADMIN_URL="$ADMIN_URL" API_URL="$API_URL" npx playwright test tests/admin-dashboard.spec.mjs
)

(
  cd web
  dart pub get
  jaspr build
)

node <<'EOF'
const fs = require('fs');
const file = 'web/build/jaspr/index.html';
const apiUrl = process.env.API_URL;
let html = fs.readFileSync(file, 'utf8');
const meta = `<meta name="form-concierge-api-url" content="${apiUrl}">`;
const base = '<base href="/">';
if (!html.includes('<base ')) {
  html = html.replace('<head>', `<head>\n  ${base}`);
}
if (!html.includes('form-concierge-api-url')) {
  html = html.replace('</head>', `  ${meta}\n</head>`);
}
fs.writeFileSync(file, html);
EOF

start_background bash -lc "cd '$ROOT_DIR/e2e' && npx serve -s ../web/build/jaspr -l tcp://127.0.0.1:8081 --no-clipboard"
wait_for "$WEB_FORM_URL"

(
  cd e2e
  WEB_FORM_URL="$WEB_FORM_URL" npx playwright test tests/web-form.spec.mjs
)

if [[ "$(uname -s)" == "Linux" ]]; then
  flutter config --enable-linux-desktop
  (
    cd e2e/flutter_embedded_form
    flutter pub get
    flutter build linux \
      --dart-define=FORM_CONCIERGE_API_URL="$API_URL" \
      --dart-define=FORM_CONCIERGE_PROJECT_SLUG=demo-project \
      --dart-define=FORM_CONCIERGE_SURVEY_SLUG=customer-feedback
    xvfb-run -a flutter test integration_test/flutter_embedded_form_e2e_test.dart \
      -d linux \
      --dart-define=FORM_CONCIERGE_API_URL="$API_URL" \
      --dart-define=FORM_CONCIERGE_PROJECT_SLUG=demo-project \
      --dart-define=FORM_CONCIERGE_SURVEY_SLUG=customer-feedback
  )
else
  echo "Skipping Linux Flutter embedded form E2E on $(uname -s)."
fi
