#!/usr/bin/env bash
set -euo pipefail

# Publish selected Form Concierge packages to pub.dev in dependency order.
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

usage() {
  cat <<'EOF'
Usage: tool/publish.sh [PACKAGE ...] [--skip PACKAGE] [--plan]

Packages:
  client    form_concierge_client
  widget    form_concierge
  cli       form_concierge_cli
  all       all packages (default when no package is specified)

Examples:
  tool/publish.sh                   # Publish all packages
  tool/publish.sh client            # Publish only the client
  tool/publish.sh client widget     # Publish client, then widget
  tool/publish.sh --skip cli        # Publish client and widget
  tool/publish.sh --plan --skip widget
EOF
}

validate_package() {
  case "$1" in
    client | widget | cli | all) ;;
    *)
      echo "Unknown package: $1" >&2
      usage >&2
      exit 64
      ;;
  esac
}

requested=()
skipped=()
plan_only=false

while (($# > 0)); do
  case "$1" in
    --skip)
      if (($# < 2)); then
        echo "--skip requires a package name" >&2
        usage >&2
        exit 64
      fi
      validate_package "$2"
      skipped+=("$2")
      shift 2
      ;;
    --plan)
      plan_only=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 64
      ;;
    *)
      validate_package "$1"
      requested+=("$1")
      shift
      ;;
  esac
done

publish_client=false
publish_widget=false
publish_cli=false

select_package() {
  case "$1" in
    client) publish_client=true ;;
    widget) publish_widget=true ;;
    cli) publish_cli=true ;;
    all)
      publish_client=true
      publish_widget=true
      publish_cli=true
      ;;
  esac
}

skip_package() {
  case "$1" in
    client) publish_client=false ;;
    widget) publish_widget=false ;;
    cli) publish_cli=false ;;
    all)
      publish_client=false
      publish_widget=false
      publish_cli=false
      ;;
  esac
}

if ((${#requested[@]} == 0)); then
  select_package all
else
  for package in "${requested[@]}"; do
    select_package "$package"
  done
fi
if ((${#skipped[@]} > 0)); then
  for package in "${skipped[@]}"; do
    skip_package "$package"
  done
fi

selected=()
$publish_client && selected+=("client")
$publish_widget && selected+=("widget")
$publish_cli && selected+=("cli")

if ((${#selected[@]} == 0)); then
  echo "==> No packages selected."
  exit 0
fi

echo "==> Publish order: ${selected[*]}"
if $plan_only; then
  exit 0
fi

if $publish_client; then
  echo "==> Publishing form_concierge_client"
  (
    cd client
    dart pub publish
  )
fi

if $publish_widget; then
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
fi

if $publish_cli; then
  echo "==> Publishing form_concierge_cli"
  (
    cd cli
    dart pub publish
  )
fi

echo "==> Done. Published: ${selected[*]}"
