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
  cd cli
  dart pub get
)

(
  cd admin_dashboard
  flutter pub get
)

(
  cd e2e/flutter_embedded_form
  flutter pub get
)

(
  cd examples/flutter_mobile_simple
  flutter pub get
)

(
  cd examples/flutter_mobile_full
  flutter pub get
)

dart run tool/generate_localizations.dart
git diff --exit-code -- \
  admin_dashboard/lib/src/core/localization/admin_messages.g.dart \
  client/lib/src/models/survey_messages.g.dart

dart format --set-exit-if-changed \
  admin_dashboard/lib \
  admin_dashboard/test \
  client/lib \
  client/test \
  e2e/flutter_embedded_form/lib \
  e2e/flutter_embedded_form/integration_test \
  examples/flutter_mobile_simple/lib \
  examples/flutter_mobile_simple/test \
  examples/flutter_mobile_full/lib \
  examples/flutter_mobile_full/test \
  web/lib \
  widget/lib \
  widget/test \
  cli/bin \
  cli/lib \
  cli/test

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
  cd cli
  dart pub get
  dart analyze
  dart test
)

(
  cd admin_dashboard
  flutter pub get
  flutter analyze
  flutter test
)

(
  cd e2e/flutter_embedded_form
  flutter pub get
  flutter analyze
)

(
  cd examples/flutter_mobile_simple
  flutter pub get
  flutter analyze
  flutter test
)

(
  cd examples/flutter_mobile_full
  flutter pub get
  flutter analyze
  flutter test
)
