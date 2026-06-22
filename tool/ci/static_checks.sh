#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

export PATH="$HOME/.pub-cache/bin:$PATH"

if ! command -v jaspr >/dev/null 2>&1; then
  dart pub global activate jaspr_cli 0.23.1
fi

(
  cd client
  dart pub get
)

(
  cd web
  dart pub get
)

(
  cd widget
  flutter pub get
)

(
  cd admin_dashboard
  flutter pub get
)

(
  cd examples/inappform
  flutter pub get
)

dart format --set-exit-if-changed \
  admin_dashboard/lib \
  admin_dashboard/test \
  client/lib \
  client/test \
  examples/inappform/lib \
  examples/inappform/integration_test \
  web/lib \
  widget/lib \
  widget/test

mkdir -p .tmp

(
  cd worker
  npm ci
  npm test
  npm run typecheck
  rm -rf ../.tmp/ci-d1-static
  printf 'y\n' | npx wrangler d1 migrations apply form_concierge \
    --local \
    --persist-to ../.tmp/ci-d1-static
)

(
  cd client
  dart pub get
  dart analyze
  dart test
)

(
  cd web
  dart pub get
  dart analyze
  jaspr build
)

(
  cd widget
  flutter pub get
  flutter analyze
  flutter test
)

(
  cd admin_dashboard
  flutter pub get
  flutter analyze
  flutter test
)

(
  cd examples/inappform
  flutter pub get
  flutter analyze
)
