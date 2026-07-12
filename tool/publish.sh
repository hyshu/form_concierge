#!/usr/bin/env bash
set -euo pipefail

# Publish the three Form Concierge packages to pub.dev in dependency order.
#
#   form_concierge_client  ->  form_concierge (widget)  ->  form_concierge_cli
#
# The widget depends on form_concierge_client as a hosted dep, so the client
# must be live on pub.dev before the widget resolves. For the widget publish we
# temporarily move pubspec_overrides.yaml aside so pub resolves the client from
# pub.dev (no local path override) -- this keeps the publish free of the
# "Non-dev dependencies are overridden" hint. The override is restored
# afterwards so monorepo development keeps building against ../client.
#
# Requires `dart pub login` beforehand. Each `dart pub publish` still prompts
# for confirmation.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

export PATH="$HOME/.pub-cache/bin:$PATH"

echo "==> Publishing form_concierge_client"
(
  cd client
  dart pub publish
)

echo "==> Publishing form_concierge (widget)"
(
  cd widget
  OVERRIDES="pubspec_overrides.yaml"
  SHELVED=".pubspec_overrides.yaml.shelved"
  if [[ -f "$OVERRIDES" ]]; then
    mv "$OVERRIDES" "$SHELVED"
    # Restore the override no matter how the subshell exits.
    trap 'mv "$SHELVED" "$OVERRIDES"; dart pub get >/dev/null 2>&1 || true' EXIT
  fi
  dart pub publish
)

echo "==> Publishing form_concierge_cli"
(
  cd cli
  dart pub publish
)

echo "==> Done. All three packages published."
