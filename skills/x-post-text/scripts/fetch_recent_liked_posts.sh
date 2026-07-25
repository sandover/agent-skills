#!/usr/bin/env bash
# Purpose: Harvest recent liked X/Twitter posts and extract their compact text payloads.
# Key exports: stdout JSON object with likes-harvest metadata plus extracted post objects.
# Role: Keep deterministic browser work in code by chaining "collect liked post URLs" and
# "extract exact post text" into one repeatable wrapper for scrapbook-style updates.
# Invariants: Stop on known scrapbook status IDs, enforce bounded timeline work,
# isolate collection from extraction, and close every dedicated browser session.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  fetch_recent_liked_posts.sh [options]

Options:
  --auth default-or-auto|auto-connect|profile:NAME
  --session-prefix NAME
  --handle HANDLE
  --likes-url URL
  --limit N
  --max-scrolls N
  --stop-at-id STATUS_ID
  --stop-at-file PATH

Safety limits:
  At most 25 posts and 8 scrolls per run. If the result says limit_reached,
  keep that bounded batch and do not retry with larger values.

Examples:
  fetch_recent_liked_posts.sh --stop-at-file scrapbook.md
  fetch_recent_liked_posts.sh --handle sandover --limit 10
EOF
}

AUTH_MODE="profile:Default"
SESSION_PREFIX="x-post-text-liked"
HANDLE=""
LIKES_URL=""
LIMIT=25
MAX_SCROLLS=8
STOP_AT_ID=""
STOP_AT_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --auth)
      AUTH_MODE="${2:-}"
      shift 2
      ;;
    --session-prefix)
      SESSION_PREFIX="${2:-}"
      shift 2
      ;;
    --handle)
      HANDLE="${2:-}"
      shift 2
      ;;
    --likes-url)
      LIKES_URL="${2:-}"
      shift 2
      ;;
    --limit)
      LIMIT="${2:-}"
      shift 2
      ;;
    --max-scrolls)
      MAX_SCROLLS="${2:-}"
      shift 2
      ;;
    --stop-at-id)
      STOP_AT_ID="${2:-}"
      shift 2
      ;;
    --stop-at-file)
      STOP_AT_FILE="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COLLECT_SCRIPT="$SCRIPT_DIR/collect_liked_post_urls.sh"
FETCH_SCRIPT="$SCRIPT_DIR/fetch_x_posts.sh"
RUN_PREFIX="${SESSION_PREFIX}-$$"
COLLECT_SESSION="${RUN_PREFIX}-collect"
FETCH_SESSION="${RUN_PREFIX}-fetch"
collector_err="$(mktemp)"
fetch_err="$(mktemp)"

ensure_number() {
  local value="$1"
  local name="$2"
  if [[ ! "$value" =~ ^[0-9]+$ ]]; then
    echo "$name must be an integer: $value" >&2
    exit 2
  fi
}

close_session() {
  local session="$1"
  case "$AUTH_MODE" in
    auto-connect)
      agent-browser --auto-connect --session "$session" close >/dev/null 2>&1 || true
      ;;
    default-or-auto|profile:Default)
      agent-browser --profile Default --session "$session" close >/dev/null 2>&1 || true
      ;;
    profile:*)
      agent-browser --profile "${AUTH_MODE#profile:}" --session "$session" close >/dev/null 2>&1 || true
      ;;
  esac
}

ensure_number "$LIMIT" "limit"
ensure_number "$MAX_SCROLLS" "max-scrolls"
if (( LIMIT < 1 || LIMIT > 25 )); then
  echo "limit must be between 1 and 25; keep the completed batch instead of escalating." >&2
  exit 2
fi
if (( MAX_SCROLLS > 8 )); then
  echo "max-scrolls must be between 0 and 8; long X timelines can consume several GiB." >&2
  exit 2
fi

cleanup() {
  local status=$?
  rm -f "$collector_err" "$fetch_err"
  close_session "$COLLECT_SESSION"
  close_session "$FETCH_SESSION"
  return "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

collector_args=(
  --auth "$AUTH_MODE"
  --session "$COLLECT_SESSION"
  --limit "$LIMIT"
  --max-scrolls "$MAX_SCROLLS"
  --json
)

if [[ -n "$HANDLE" ]]; then
  collector_args+=(--handle "$HANDLE")
fi

if [[ -n "$LIKES_URL" ]]; then
  collector_args+=(--likes-url "$LIKES_URL")
fi

if [[ -n "$STOP_AT_ID" ]]; then
  collector_args+=(--stop-at-id "$STOP_AT_ID")
fi

if [[ -n "$STOP_AT_FILE" ]]; then
  collector_args+=(--stop-at-file "$STOP_AT_FILE")
fi

if ! collector_json="$("$COLLECT_SCRIPT" "${collector_args[@]}" 2>"$collector_err")"; then
  cat "$collector_err" >&2
  exit 1
fi

if ! jq -e 'type == "object" and (.collected_urls | type == "array")' >/dev/null 2>&1 <<<"$collector_json"; then
  echo "Collector returned invalid JSON." >&2
  exit 1
fi

collected_urls=()
while IFS= read -r collected_url; do
  collected_urls+=("$collected_url")
done < <(jq -r '.collected_urls[]?' <<<"$collector_json")

if [[ "${#collected_urls[@]}" -eq 0 ]]; then
  jq -c '. + {posts: []}' <<<"$collector_json"
  exit 0
fi

if ! posts_json="$(printf '%s\n' "${collected_urls[@]}" | "$FETCH_SCRIPT" --auth "$AUTH_MODE" --session "$FETCH_SESSION" 2>"$fetch_err")"; then
  cat "$fetch_err" >&2
  exit 1
fi

if ! jq -e 'type == "array"' >/dev/null 2>&1 <<<"$posts_json"; then
  echo "Post extractor returned invalid JSON." >&2
  exit 1
fi

jq -nc \
  --argjson harvest "$collector_json" \
  --argjson posts "$posts_json" \
  '$harvest + {posts: $posts}'
