#!/usr/bin/env bash
# Run the web app locally against the real backend (same Firebase project,
# same deployed callables, same RevenueCat link as production).
#
# Usage: bash tool/run_local.sh [--live] [--release] [--analytics]
#
#   (no flags)   Scripted sims, no analytics, debug build. Safe default.
#   --live       Route LIVE_SCENARIOS onto the deployed session broker.
#   --release    dart2js build, matching what Cloudflare Pages ships.
#                The debug default runs on dartdevc, which is NOT what
#                users get; use this before trusting timing or bundle size.
#   --analytics  Send events to the REAL PostHog project. Off by default:
#                local clicking otherwise lands in the launch funnel, which
#                has no separate dev project to absorb it. Needs
#                POSTHOG_API_KEY in .env (see .env.example).
#
# Three things are real no matter which flags you pass:
#   - Upgrade opens the live Stripe checkout (kRcPurchaseLinkBase default).
#   - Every sim start increments sessionsUsed on your own users/{uid} doc.
#   - Firestore reads and writes hit the production project.
#
# Two things differ from production and always will, locally:
#   - Deep-link refreshes (/score/:sessionId) 404: the Pages _redirects SPA
#     fallback does not exist yet (LAUNCH_TODO).
#   - A dropped live call aborts and refunds rather than resuming: the
#     broker has no mid-call resume in v1 (LAUNCH_TODO).
set -euo pipefail

cd "$(dirname "$0")/.."

# Deployed production broker (closero-session-broker, Cloudflare).
BROKER_WSS_BASE="wss://closero-session-broker.osmanmcruzz.workers.dev"

# Scenarios routed onto the live pipeline with --live. Personas roll onto
# live one at a time; add ids here as each one is ready.
LIVE_SCENARIOS="cold-call-saas-gatekeeper"

# Browsers commonly ignore the requested 16kHz mic constraint and capture at
# the AudioContext native rate. 48000 is the assumption until a real-device
# measurement confirms it (LAUNCH_TODO). Set MIC_INPUT_RATE to override.
MIC_INPUT_RATE="${MIC_INPUT_RATE:-48000}"

LIVE=0
RELEASE=0
ANALYTICS=0
for arg in "$@"; do
  case "$arg" in
    --live) LIVE=1 ;;
    --release) RELEASE=1 ;;
    --analytics) ANALYTICS=1 ;;
    *) echo "run_local: unknown flag: $arg" >&2; exit 2 ;;
  esac
done

ARGS=(run -d chrome --dart-define=MIC_INPUT_RATE="$MIC_INPUT_RATE")

if [ "$RELEASE" = 1 ]; then
  ARGS+=(--release)
  echo "run_local: release build (dart2js), matching the Pages bundle."
else
  echo "run_local: debug build (dartdevc). Pass --release to match production."
fi

if [ "$LIVE" = 1 ]; then
  ARGS+=(--dart-define=BROKER_WSS_BASE="$BROKER_WSS_BASE")
  ARGS+=(--dart-define=LIVE_SCENARIOS="$LIVE_SCENARIOS")
  echo "run_local: LIVE pipeline on for: $LIVE_SCENARIOS"
  echo "run_local: mic assumed at ${MIC_INPUT_RATE}Hz, downsampled to the broker's 16kHz."
else
  echo "run_local: scripted sims (no broker). Pass --live for the real pipeline."
fi

if [ "$ANALYTICS" = 1 ]; then
  if [ ! -f .env ]; then
    echo "run_local: --analytics needs a .env with POSTHOG_API_KEY." >&2
    echo "Copy .env.example to .env and fill it in." >&2
    exit 2
  fi
  # shellcheck disable=SC1091
  set -a; . ./.env; set +a
  if [ -z "${POSTHOG_API_KEY:-}" ]; then
    echo "run_local: POSTHOG_API_KEY is empty in .env." >&2
    exit 2
  fi
  ARGS+=(--dart-define=POSTHOG_API_KEY="$POSTHOG_API_KEY")
  echo "run_local: analytics ON. These events land in the REAL launch funnel."
else
  echo "run_local: analytics off (no-op service, zero events)."
fi

echo "run_local: Upgrade opens a LIVE Stripe checkout. Sim starts count against your real cap."
exec flutter "${ARGS[@]}"
