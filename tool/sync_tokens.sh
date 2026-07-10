#!/usr/bin/env bash
# Pull design-tokens.json from the closero-site source of truth, regenerate
# the Dart tokens, and run the contract tests.
#
# Usage: bash tool/sync_tokens.sh
# Override the source location with CLOSERO_SITE_TOKENS=/path/to/design-tokens.json
set -euo pipefail

cd "$(dirname "$0")/.."

SITE_TOKENS="${CLOSERO_SITE_TOKENS:-$HOME/Desktop/Closero/All Work July 2026/Current Work/closero-site/design-tokens.json}"
APP_TOKENS="context/design-tokens.json"

if [ ! -f "$SITE_TOKENS" ]; then
  echo "sync_tokens: source not found: $SITE_TOKENS" >&2
  echo "Set CLOSERO_SITE_TOKENS to the closero-site design-tokens.json path." >&2
  exit 2
fi

if diff -q "$SITE_TOKENS" "$APP_TOKENS" >/dev/null 2>&1; then
  echo "sync_tokens: already in sync with $SITE_TOKENS"
else
  echo "sync_tokens: pulling changes from $SITE_TOKENS"
  diff "$APP_TOKENS" "$SITE_TOKENS" || true
  cp "$SITE_TOKENS" "$APP_TOKENS"
fi

dart run tool/gen_tokens.dart
flutter test test/theme/tokens_test.dart
echo "sync_tokens: done. Review and commit context/design-tokens.json + lib/core/theme/tokens.g.dart together."
