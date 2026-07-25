#!/usr/bin/env bash
# Purpose: Collect recent liked X/Twitter post URLs from the authenticated Likes timeline.
# Key exports: stdout JSON metadata or newline-delimited URLs for downstream extraction.
# Role: Do deterministic browser work only: open Likes, read status URLs, scroll, dedupe,
# and stop when a known status is encountered.
# Invariants: Prefer Chrome Default first, preserve newest-first order, cap timeline
# work to 25 posts and 8 scrolls, and always close the dedicated browser session.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  collect_liked_post_urls.sh [options]

Options:
  --auth default-or-auto|auto-connect|profile:NAME
  --session NAME
  --handle HANDLE
  --likes-url URL
  --limit N
  --max-scrolls N
  --stop-at-id STATUS_ID
  --stop-at-file PATH
  --json
  --urls-only

Safety limits:
  At most 25 posts and 8 scrolls per run. Start a separate bounded run rather
  than increasing these values; long X timelines can consume several GiB.

Examples:
  collect_liked_post_urls.sh --json
  collect_liked_post_urls.sh --stop-at-file scrapbook.md --limit 25 --json
  collect_liked_post_urls.sh --handle sandover --urls-only
EOF
}

AUTH_MODE="profile:Default"
SESSION_NAME="x-post-text-likes-$$"
HANDLE=""
LIKES_URL=""
LIMIT=25
MAX_SCROLLS=8
OUTPUT_MODE="json"
STOP_AT_ID=""
STOP_AT_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --auth)
      AUTH_MODE="${2:-}"
      shift 2
      ;;
    --session)
      SESSION_NAME="${2:-}"
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
    --json)
      OUTPUT_MODE="json"
      shift
      ;;
    --urls-only)
      OUTPUT_MODE="urls"
      shift
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

choose_auth_flags() {
  case "$AUTH_MODE" in
    auto-connect)
      ACTIVE_AUTH_FLAGS=(--auto-connect)
      ;;
    default-or-auto)
      ACTIVE_AUTH_FLAGS=()
      ;;
    profile:*)
      ACTIVE_AUTH_FLAGS=(--profile "${AUTH_MODE#profile:}")
      ;;
    *)
      echo "Unsupported auth mode: $AUTH_MODE" >&2
      exit 2
      ;;
  esac
}

run_browser() {
  agent-browser "${ACTIVE_AUTH_FLAGS[@]}" --session "$SESSION_NAME" "$@"
}

ensure_open() {
  local url="$1"

  if [[ "$AUTH_MODE" == "default-or-auto" ]]; then
    ACTIVE_AUTH_FLAGS=(--profile Default)
    SESSION_STARTED=1
    if run_browser open "$url" >/dev/null 2>&1; then
      return 0
    fi

    run_browser close >/dev/null 2>&1 || true
    ACTIVE_AUTH_FLAGS=(--auto-connect)
    run_browser open "$url" >/dev/null
    return 0
  fi

  SESSION_STARTED=1
  run_browser open "$url" >/dev/null
}

extract_status_id() {
  sed -E 's#^.*status/([0-9]+).*$#\1#' <<<"$1"
}

ensure_number() {
  local value="$1"
  local name="$2"
  if [[ ! "$value" =~ ^[0-9]+$ ]]; then
    echo "$name must be an integer: $value" >&2
    exit 2
  fi
}

build_known_ids_file() {
  local path="$1"

  : >"$path"

  if [[ -n "$STOP_AT_ID" ]]; then
    printf '%s\n' "$STOP_AT_ID" >>"$path"
  fi

  if [[ -n "$STOP_AT_FILE" ]]; then
    if [[ ! -f "$STOP_AT_FILE" ]]; then
      echo "Stop file not found: $STOP_AT_FILE" >&2
      exit 2
    fi

    if command -v rg >/dev/null 2>&1; then
      rg -o 'status/[0-9]+' "$STOP_AT_FILE" | sed 's#status/##' >>"$path" || true
    else
      grep -Eo 'status/[0-9]+' "$STOP_AT_FILE" | sed 's#status/##' >>"$path" || true
    fi
  fi

  sort -u -o "$path" "$path"
}

id_is_known() {
  local status_id="$1"
  local known_ids_file="$2"
  [[ -s "$known_ids_file" ]] && grep -Fxq "$status_id" "$known_ids_file"
}

array_to_json() {
  if [[ $# -eq 0 ]]; then
    printf '[]'
    return
  fi

  printf '%s\n' "$@" | jq -R . | jq -s .
}

build_infer_handle_b64() {
  base64 <<'EOF'
(() => {
  const explicit = document.querySelector('a[data-testid="AppTabBar_Profile_Link"]')?.getAttribute("href");
  if (explicit && /^\/[^/?#]+$/.test(explicit)) {
    return explicit.slice(1);
  }

  const reserved = new Set([
    "home",
    "explore",
    "notifications",
    "messages",
    "compose",
    "search",
    "settings",
    "tos",
    "privacy",
    "jobs",
    "premium",
    "i",
  ]);

  const counts = new Map();
  for (const link of document.querySelectorAll('a[href^="/"]')) {
    const href = link.getAttribute("href") || "";
    if (!/^\/[^/?#]+$/.test(href)) continue;
    const handle = href.slice(1);
    if (!handle || reserved.has(handle)) continue;
    counts.set(handle, (counts.get(handle) || 0) + 1);
  }

  const sorted = Array.from(counts.entries()).sort((a, b) => b[1] - a[1]);
  return sorted.length ? sorted[0][0] : null;
})()
EOF
}
INFER_HANDLE_B64="$(build_infer_handle_b64)"

build_collect_likes_b64() {
  base64 <<'EOF'
(() => {
  const canonicalStatusUrl = (href) => {
    if (!href) return null;
    const match = href.match(/(\/[^/?#]+\/status\/\d+)/);
    return match ? `https://x.com${match[1]}` : null;
  };

  const bodyText = document.body ? document.body.innerText : "";
  if (/sign in|log in|create account/i.test(bodyText) || bodyText.includes("Join X today")) {
    return { kind: "blocked", reason: "login_required_or_session_missing", urls: [] };
  }

  const urls = [];
  const seen = new Set();
  for (const article of document.querySelectorAll("article")) {
    for (const link of article.querySelectorAll('a[href*="/status/"]')) {
      const url = canonicalStatusUrl(link.getAttribute("href") || "");
      if (!url || seen.has(url)) continue;
      seen.add(url);
      urls.push(url);
    }
  }

  return {
    kind: "ok",
    url: location.href.split("?")[0],
    article_count: document.querySelectorAll("article").length,
    urls,
  };
})()
EOF
}
COLLECT_LIKES_B64="$(build_collect_likes_b64)"

infer_handle() {
  local payload handle

  ensure_open "https://x.com/home"
  payload="$(run_browser --json eval -b "$INFER_HANDLE_B64" 2>/dev/null || true)"
  handle="$(jq -r '.data.result // empty' <<<"$payload" 2>/dev/null || true)"

  if [[ -z "$handle" || "$handle" == "null" ]]; then
    echo "Could not infer the current X handle from the authenticated home page." >&2
    exit 1
  fi

  printf '%s\n' "$handle"
}

collect_visible_urls() {
  local payload
  payload="$(run_browser --json eval -b "$COLLECT_LIKES_B64" 2>/dev/null || true)"
  jq -c '.data.result // {}' <<<"$payload" 2>/dev/null || printf '{}\n'
}

emit_result() {
  local likes_url="$1"
  local handle="$2"
  local stop_reason="$3"
  local matched_existing_id="$4"
  local scrolls_used="$5"
  shift 5

  if [[ "$OUTPUT_MODE" == "urls" ]]; then
    printf '%s\n' "$@"
    return
  fi

  local collected_urls_json
  collected_urls_json="$(array_to_json "$@")"

  jq -nc \
    --arg likes_url "$likes_url" \
    --arg handle "$handle" \
    --arg stop_reason "$stop_reason" \
    --arg matched_existing_id "$matched_existing_id" \
    --argjson scrolls_used "$scrolls_used" \
    --argjson collected_urls "$collected_urls_json" \
    '{
      likes_url: $likes_url,
      handle: $handle,
      collected_urls: $collected_urls,
      stop_reason: $stop_reason,
      scrolls_used: $scrolls_used
    } + (
      if ($matched_existing_id | length) > 0
      then {matched_existing_id: $matched_existing_id}
      else {}
      end
    )'
}

ensure_number "$LIMIT" "limit"
ensure_number "$MAX_SCROLLS" "max-scrolls"

if (( LIMIT < 1 || LIMIT > 25 )); then
  echo "limit must be between 1 and 25; use separate bounded runs for larger harvests." >&2
  exit 2
fi

if (( MAX_SCROLLS > 8 )); then
  echo "max-scrolls must be between 0 and 8; long X timelines can consume several GiB." >&2
  exit 2
fi

choose_auth_flags

known_ids_file="$(mktemp)"
SESSION_STARTED=0
cleanup() {
  local status=$?
  rm -f "$known_ids_file"
  if (( SESSION_STARTED == 1 )); then
    run_browser close >/dev/null 2>&1 || true
  fi
  return "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

build_known_ids_file "$known_ids_file"

if [[ -z "$LIKES_URL" ]]; then
  if [[ -z "$HANDLE" ]]; then
    HANDLE="$(infer_handle)"
  fi
  LIKES_URL="https://x.com/${HANDLE}/likes"
fi

if [[ -z "$HANDLE" ]]; then
  HANDLE="$(sed -E 's#^https?://x\.com/([^/?#]+)/likes.*$#\1#' <<<"$LIKES_URL")"
fi

ensure_open "$LIKES_URL"

declare -a seen_ids=()
declare -a collected_urls=()
stop_reason="max_scrolls_exhausted"
matched_existing_id=""
scrolls_used=0
stagnant_rounds=0

for (( scroll_index=0; scroll_index<=MAX_SCROLLS; scroll_index++ )); do
  payload="$(collect_visible_urls)"
  kind="$(jq -r '.kind // ""' <<<"$payload" 2>/dev/null || true)"

  if [[ "$kind" == "blocked" ]]; then
    stop_reason="$(jq -r '.reason // "blocked"' <<<"$payload" 2>/dev/null || true)"
    break
  fi

  visible_urls=()
  while IFS= read -r url; do
    visible_urls+=("$url")
  done < <(jq -r '.urls[]?' <<<"$payload" 2>/dev/null || true)
  new_in_round=0

  for url in "${visible_urls[@]}"; do
    status_id="$(extract_status_id "$url")"
    if [[ -z "$status_id" || "$status_id" == "$url" ]]; then
      continue
    fi

    if printf '%s\n' "${seen_ids[@]}" | grep -Fxq "$status_id"; then
      continue
    fi
    seen_ids+=("$status_id")

    if id_is_known "$status_id" "$known_ids_file"; then
      stop_reason="matched_existing_id"
      matched_existing_id="$status_id"
      emit_result "$LIKES_URL" "$HANDLE" "$stop_reason" "$matched_existing_id" "$scrolls_used" "${collected_urls[@]}"
      exit 0
    fi

    collected_urls+=("$url")
    new_in_round=1

    if (( ${#collected_urls[@]} >= LIMIT )); then
      stop_reason="limit_reached"
      emit_result "$LIKES_URL" "$HANDLE" "$stop_reason" "$matched_existing_id" "$scrolls_used" "${collected_urls[@]}"
      exit 0
    fi
  done

  if (( scroll_index == MAX_SCROLLS )); then
    break
  fi

  if (( new_in_round == 0 )); then
    stagnant_rounds=$((stagnant_rounds + 1))
  else
    stagnant_rounds=0
  fi

  if (( stagnant_rounds >= 2 )); then
    stop_reason="no_new_urls_visible"
    break
  fi

  run_browser scroll down 1800 >/dev/null 2>&1 || true
  run_browser wait 900 >/dev/null 2>&1 || true
  scrolls_used=$((scrolls_used + 1))
done

emit_result "$LIKES_URL" "$HANDLE" "$stop_reason" "$matched_existing_id" "$scrolls_used" "${collected_urls[@]}"
