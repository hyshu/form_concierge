#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKER_DIR="$ROOT_DIR/worker"

API_URL="${API_URL:-}"
ADMIN_TOKEN="${ADMIN_TOKEN:-}"

usage() {
  cat <<'USAGE'
Usage:
  ADMIN_TOKEN="<token>" tool/cloudflare/smoke.sh [options]

Options:
  --api-url <url>          Public Worker API URL. Defaults to worker/wrangler.jsonc PUBLIC_BASE_URL.
  --admin-token <token>    Existing admin bearer token.
  -h, --help               Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --api-url) API_URL="$2"; shift 2 ;;
    --admin-token) ADMIN_TOKEN="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing command: $1" >&2
    exit 1
  fi
}

require_cmd curl
require_cmd jq
require_cmd node

if [[ -z "$API_URL" ]]; then
  API_URL="$(node - "$WORKER_DIR/wrangler.jsonc" <<'NODE'
const fs = require('fs');
const config = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
process.stdout.write(config.vars?.PUBLIC_BASE_URL ?? '');
NODE
)"
fi

if [[ -z "$API_URL" ]]; then
  echo "--api-url required" >&2
  exit 1
fi

if [[ -z "$ADMIN_TOKEN" ]]; then
  echo "--admin-token or ADMIN_TOKEN required" >&2
  exit 1
fi

API_URL="${API_URL%/}"
SMOKE_SLUG="cloudflare-smoke-$(date +%s)"

echo "==> Create smoke survey"
SURVEY_BODY="$(jq -n --arg slug "$SMOKE_SLUG" '{
  survey: {
    slug: $slug,
    customDomain: null,
    defaultLocale: "en",
    supportedLocales: ["en", "ja", "zh-Hans", "zh-Hant", "ko", "de"],
    titleTranslations: {
      en: "Cloudflare smoke test",
      ja: "Cloudflare smoke test",
      "zh-Hans": "Cloudflare smoke test",
      "zh-Hant": "Cloudflare smoke test",
      ko: "Cloudflare smoke test",
      de: "Cloudflare smoke test"
    },
    descriptionTranslations: {
      en: "Temporary deployment check",
      ja: "Temporary deployment check",
      "zh-Hans": "Temporary deployment check",
      "zh-Hant": "Temporary deployment check",
      ko: "Temporary deployment check",
      de: "Temporary deployment check"
    }
  },
  questions: [{
    textTranslations: {
      en: "Your name",
      ja: "Your name",
      "zh-Hans": "Your name",
      "zh-Hant": "Your name",
      ko: "Your name",
      de: "Your name"
    },
    type: "textSingle",
    isRequired: true,
    placeholderTranslations: {
      en: "Alice",
      ja: "Alice",
      "zh-Hans": "Alice",
      "zh-Hant": "Alice",
      ko: "Alice",
      de: "Alice"
    },
    minLength: 1,
    maxLength: 80,
    minSelected: null,
    maxSelected: null,
    visibilityConditionMode: "all",
    choiceTranslations: []
  }]
}')"

CREATED="$(curl -fsS -X POST "$API_URL/api/admin/surveys/with-questions" \
  -H "authorization: Bearer $ADMIN_TOKEN" \
  -H 'content-type: application/json' \
  -d "$SURVEY_BODY")"
SURVEY_ID="$(jq -r '.id' <<<"$CREATED")"

echo "==> Publish smoke survey"
curl -fsS -X POST "$API_URL/api/admin/surveys/$SURVEY_ID/publish" \
  -H "authorization: Bearer $ADMIN_TOKEN" >/dev/null

echo "==> Verify SSR HTML"
HTML="$(curl -fsS "$API_URL/$SMOKE_SLUG")"
if ! grep -q 'form-concierge-ssr' <<<"$HTML"; then
  echo "SSR payload missing" >&2
  exit 1
fi
if ! grep -q 'Cloudflare smoke test' <<<"$HTML"; then
  echo "SSR title missing" >&2
  exit 1
fi

echo "==> Submit anonymous response"
QUESTION_ID="$(curl -fsS "$API_URL/api/surveys/id/$SURVEY_ID/questions" | jq -r '.[0].id')"
ANON_TOKEN="$(curl -fsS -X POST "$API_URL/api/anonymous/accounts" | jq -r '.token')"
curl -fsS -X POST "$API_URL/api/surveys/id/$SURVEY_ID/responses" \
  -H "authorization: Bearer $ANON_TOKEN" \
  -H 'content-type: application/json' \
  -d "$(jq -n --argjson questionId "$QUESTION_ID" '{answers:[{questionId:$questionId,textValue:"setup smoke",selectedChoiceIds:null}]}')" >/dev/null

COUNT="$(curl -fsS "$API_URL/api/admin/surveys/$SURVEY_ID/responses/count" \
  -H "authorization: Bearer $ADMIN_TOKEN" | jq -r '.count')"
if [[ "$COUNT" != "1" ]]; then
  echo "Unexpected response count: $COUNT" >&2
  exit 1
fi

echo "Smoke survey: $API_URL/$SMOKE_SLUG"
echo "Smoke responses: $COUNT"
