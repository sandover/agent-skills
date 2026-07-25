#!/usr/bin/env bash
# Purpose: Extract only the text and a few core fields from X/Twitter post pages.
# Key exports: stdout JSON array of compact per-post objects.
# Role: Reuse the user's authenticated Chrome session through agent-browser,
# then run page-side JavaScript so we avoid full-page snapshots and large DOM dumps.
# Invariants: Prefer Chrome Default first, use a dedicated browser session, keep
# output machine-readable, fail closed, and close the session on every exit path.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  fetch_x_posts.sh [--auth default-or-auto|auto-connect|profile:NAME] [--session NAME] <url-or-id>...
  fetch_x_posts.sh [--auth ...] [--session NAME] < urls.txt

Examples:
  fetch_x_posts.sh https://x.com/jack/status/20
  fetch_x_posts.sh 1881234567890123456
  printf '%s\n' https://x.com/user/status/1 https://x.com/user/status/2 | fetch_x_posts.sh
EOF
}

AUTH_MODE="profile:Default"
SESSION_NAME="x-post-text-$$"

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
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      break
      ;;
  esac
done

normalize_target() {
  local raw="$1"
  if [[ "$raw" =~ ^https?:// ]]; then
    printf '%s\n' "$raw"
    return
  fi

  if [[ "$raw" =~ ^[0-9]+$ ]]; then
    printf 'https://x.com/i/status/%s\n' "$raw"
    return
  fi

  echo "Unsupported target: $raw" >&2
  exit 2
}

read_targets() {
  if [[ $# -gt 0 ]]; then
    printf '%s\n' "$@"
    return
  fi

  if [[ -t 0 ]]; then
    echo "No post URLs or IDs supplied." >&2
    usage >&2
    exit 2
  fi

  cat
}

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

is_valid_json_object() {
  jq -e 'type == "object"' >/dev/null 2>&1 <<<"$1"
}

extract_status_id() {
  sed -E 's#^.*status/([0-9]+).*$#\1#' <<<"$1"
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

build_extractor_b64() {
  base64 <<'EOF'
(() => {
  const currentUrl = window.location.href.split("?")[0];
  const statusMatch = currentUrl.match(/status\/(\d+)/);
  const targetId = statusMatch ? statusMatch[1] : null;
  const articles = Array.from(document.querySelectorAll("article"));
  const bodyText = document.body ? document.body.innerText : "";
  const unique = (values) =>
    values.filter(Boolean).filter((value, index, arr) => arr.indexOf(value) === index);
  const cleanLines = (text) =>
    (text || "")
      .split("\n")
      .map((line) => line.trim())
      .filter(Boolean);
  const canonicalStatusPath = (href) => {
    if (!href) return null;
    const match = href.match(/(\/[^/?#]+\/status\/\d+)/);
    return match ? match[1] : null;
  };
  // Walk a DOM node substituting href for the visible text of external links so
  // truncated/ellipsis URLs do not end up dead in output. External links on X use
  // https://t.co/… hrefs that redirect correctly. Relative hrefs (@mentions,
  // #hashtags) keep their innerText. Applied to all text extraction paths.
  const extractTextWithLinks = (node) => {
    let out = "";
    for (const child of node.childNodes) {
      if (child.nodeType === Node.TEXT_NODE) {
        out += child.textContent;
      } else if (child.tagName === "A") {
        const href = child.getAttribute("href") || "";
        out += (href.startsWith("http://") || href.startsWith("https://")) ? href : (child.innerText || "");
      } else if (child.tagName === "IMG") {
        out += child.getAttribute("alt") || "";
      } else {
        out += extractTextWithLinks(child);
      }
    }
    return out;
  };
  const renderMarkdownFromBlocks = (root, headingOffset = 0) => {
    const blocks = unique(
      Array.from(root.querySelectorAll("h1, h2, h3, h4, p, li, blockquote"))
        .map((node) => {
          const text = extractTextWithLinks(node).trim();
          if (!text) return null;
          const tag = node.tagName.toLowerCase();
          if (tag === "blockquote") return `> ${text}`;
          if (tag === "li") return `- ${text}`;
          if (/^h[1-4]$/.test(tag)) {
            const level = Math.min(6, Number(tag.slice(1)) + headingOffset);
            return `${"#".repeat(level)} ${text}`;
          }
          return text;
        })
        .filter(Boolean),
    );
    return blocks.join("\n\n");
  };
  const renderPlainTextFromBlocks = (root) =>
    unique(
      Array.from(root.querySelectorAll("h1, h2, h3, h4, p, li, blockquote"))
        .map((node) => extractTextWithLinks(node).trim())
        .filter(Boolean),
    ).join("\n\n");

  const exactArticle = articles.find((article) =>
    Array.from(article.querySelectorAll('a[href*="/status/"]')).some((link) => {
      const href = canonicalStatusPath(link.getAttribute("href") || "");
      return targetId ? href.endsWith(`/status/${targetId}`) : false;
    }),
  );

  const fallbackArticle =
    articles.find((candidate) => candidate.querySelector('div[data-testid="tweetText"], time')) ||
    null;

  const article = targetId ? exactArticle : fallbackArticle;

  if (!article) {
    const blocked =
      /sign in|log in|create account/i.test(bodyText) ||
      bodyText.includes("Join X today");

    return {
      kind: blocked ? "blocked" : "pending",
      url: currentUrl,
      reason: blocked ? "login_required_or_session_missing" : "post_not_found_yet",
    };
  }

  const statusLinks = Array.from(article.querySelectorAll('a[href*="/status/"]'))
    .map((link) => canonicalStatusPath(link.getAttribute("href")))
    .filter(Boolean);

  const preferredStatusLink =
    statusLinks.find((href) => (targetId ? href.endsWith(`/status/${targetId}`) : false)) ||
    statusLinks[0] ||
    null;

  const userLink =
    Array.from(article.querySelectorAll('a[href^="/"]'))
      .map((link) => link.getAttribute("href"))
      .find((href) => href && /^\/[^/?#]+$/.test(href) && !href.startsWith("/i/")) ||
    null;
  const handleFromStatusPath = (href) => {
    const match = (href || "").match(/^\/([^/?#]+)\/status\/\d+$/);
    return match ? match[1] : null;
  };
  const accountUrlForHandle = (handle) => (handle ? `https://x.com/${handle.replace(/^@/, "")}` : null);
  const authorName =
    Array.from(article.querySelectorAll('[data-testid="User-Name"] span'))
      .map((node) => (node.innerText || "").trim())
      .find((value) => value && !value.startsWith("@") && !/^\d+[smhd]$/.test(value) && value !== "·") ||
    null;

  const statusPathBelongsToTarget = (href) =>
    targetId ? href.endsWith(`/status/${targetId}`) : href === preferredStatusLink;
  const nodeStatusPaths = (root) =>
    Array.from(root.querySelectorAll('a[href*="/status/"]'))
      .map((link) => canonicalStatusPath(link.getAttribute("href") || ""))
      .filter(Boolean);
  const hasNonTargetStatusPath = (root) =>
    nodeStatusPaths(root).some((href) => !statusPathBelongsToTarget(href));
  // Single parent-chain traversal: returns the status path of the enclosing
  // quoted tweet container, or null if the node belongs to the primary tweet.
  const findEmbeddedStatusPath = (node) => {
    let current = node.parentElement;
    while (current && current !== article) {
      const role = current.getAttribute("role");
      const tabIndex = current.getAttribute("tabindex");
      if (role === "link" || tabIndex === "0") {
        const href = nodeStatusPaths(current).find((path) => !statusPathBelongsToTarget(path));
        if (href) return href;
      }
      current = current.parentElement;
    }
    return null;
  };
  const quoteMarkdown = (value) =>
    cleanLines(value)
      .map((line) => `> ${line}`)
      .join("\n");
  const tweetTextEntries = Array.from(article.querySelectorAll('div[data-testid="tweetText"]'))
    .map((node) => {
      const quoted_url_path = findEmbeddedStatusPath(node);
      return {
        text: extractTextWithLinks(node).trim(),
        embedded: quoted_url_path !== null,
        quoted_url_path,
      };
    })
    .filter((entry) => entry.text);
  const primaryTweetText = tweetTextEntries
    .filter((entry) => !entry.embedded)
    .map((entry) => entry.text)
    .join("\n\n");
  const quotedTweetEntries = tweetTextEntries
    .filter((entry) => entry.embedded)
    .map((entry) => ({
      text: entry.text,
      url: entry.quoted_url_path ? `https://x.com${entry.quoted_url_path}` : null,
      author_handle: handleFromStatusPath(entry.quoted_url_path),
      author_url: accountUrlForHandle(handleFromStatusPath(entry.quoted_url_path)),
    }));
  const quotedTweetTexts = quotedTweetEntries.map((entry) => entry.text);
  const quotedTweetMarkdown = quotedTweetEntries
    .map((entry) => {
      const title = [
        entry.author_handle && entry.author_url ? `[@${entry.author_handle}](${entry.author_url})` : null,
        entry.url ? `[link](${entry.url})` : null,
      ].filter(Boolean).join(" • ") || "Quoted tweet";
      return `> [!quote] ${title}\n${quoteMarkdown(entry.text)}`;
    })
    .join("\n\n");
  const quotedTweetPlainText = quotedTweetEntries
    .map((entry) => `${entry.url ? `Quoted tweet: ${entry.url}` : "Quoted tweet:"}\n\n${entry.text}`)
    .join("\n\n");
  const text = [primaryTweetText, quotedTweetPlainText].filter(Boolean).join("\n\n");
  const tweetMarkdown = [primaryTweetText, quotedTweetMarkdown]
    .filter(Boolean)
    .join("\n\n");

  const longformTitle =
    article.querySelector('[data-testid="twitter-article-title"]')?.innerText.trim() || null;
  const longformBodyNode =
    article.querySelector('[data-testid="twitterArticleRichTextView"]') ||
    article.querySelector('[data-testid="longformRichTextComponent"]') ||
    null;
  const longformMarkdownBody = longformBodyNode ? renderMarkdownFromBlocks(longformBodyNode, 1) : "";
  const longformTextBody = longformBodyNode ? renderPlainTextFromBlocks(longformBodyNode) : "";
  const longformMarkdown =
    longformTitle && longformMarkdownBody
      ? `# ${longformTitle}\n\n${longformMarkdownBody}`
      : longformTitle
        ? `# ${longformTitle}`
        : longformMarkdownBody;
  const longformText =
    longformTitle && longformTextBody
      ? `${longformTitle}\n\n${longformTextBody}`
      : longformTitle
        ? longformTitle
        : longformTextBody;

  const cleanedBlockEntries = Array.from(article.querySelectorAll("h1, h2, h3, p"))
    .map((node) => ({
      tag: node.tagName.toLowerCase(),
      text: node.innerText.trim(),
    }))
    .filter((entry) => entry.text)
    .filter((entry, index, arr) => arr.findIndex((candidate) => candidate.text === entry.text) === index)
    .filter((entry) => {
      const value = entry.text;
      if (userLink && value === userLink.slice(1)) return false;
      if (value.startsWith("@")) return false;
      if (/^\d{1,3}(\.\d+)?[KMB]?$/i.test(value)) return false;
      if (/^(Replying to|Translate post|Quote|Show more)$/i.test(value)) return false;
      return value.length > 20;
    });

  const articleBlocks = cleanedBlockEntries.map((entry) => entry.text);
  const articleTitle = longformTitle || articleBlocks.find((value) => value.length > 40) || null;
  const articleBody = articleBlocks.join("\n\n");
  const articleMarkdown = cleanedBlockEntries
    .map((entry) => {
      if (entry.tag === "h1") return `# ${entry.text}`;
      if (entry.tag === "h2") return `## ${entry.text}`;
      if (entry.tag === "h3") return `### ${entry.text}`;
      return entry.text;
    })
    .join("\n\n");
  const fallbackText = cleanLines(article.innerText || "")
    .filter((value, index, arr) => arr.indexOf(value) === index)
    .filter((value) => {
      if (userLink && value === userLink.slice(1)) return false;
      if (value.startsWith("@")) return false;
      if (/^\d{1,3}(\.\d+)?[KMB]?$/i.test(value)) return false;
      if (/^(Tweet|Post|Reply|Repost|Like|Bookmark|Share|Recent)$/i.test(value)) return false;
      if (/^\d{1,3}(\.\d+)?[KMB]?\s+Views$/i.test(value)) return false;
      if (/^\d+\s+(Quote Tweets|Retweets?)$/i.test(value)) return false;
      if (/^[0-9:.APM ·,-]+Twitter Web App$/i.test(value)) return false;
      return value.length > 20;
    })
    .join("\n\n");

  const resolvedText = text || longformText || articleBody || fallbackText;
  const resolvedMarkdown = tweetMarkdown || longformMarkdown || articleMarkdown || fallbackText;

  const timeEl = article.querySelector("time");
  const resolvedUrl = preferredStatusLink ? `https://x.com${preferredStatusLink}` : currentUrl;
  const resolvedIdMatch = resolvedUrl.match(/status\/(\d+)/);
  const media = Array.from(article.querySelectorAll('img[src*="pbs.twimg.com/media/"], img[src*="pbs.twimg.com/ext_tw_video_thumb/"]'))
    .map((img) => {
      const rawUrl = img.currentSrc || img.src || "";
      if (!rawUrl) return null;
      let downloadUrl = rawUrl;
      try {
        const parsed = new URL(rawUrl);
        if (parsed.hostname === "pbs.twimg.com") {
          parsed.searchParams.set("name", "orig");
          downloadUrl = parsed.toString();
        }
      } catch (_) {
        downloadUrl = rawUrl;
      }
      const alt = (img.getAttribute("alt") || "").trim();
      return {
        type: rawUrl.includes("/ext_tw_video_thumb/") ? "video_thumbnail" : "image",
        url: rawUrl,
        download_url: downloadUrl,
        alt_text: alt && !/^(image|photo|gif)$/i.test(alt) ? alt : null,
      };
    })
    .filter(Boolean)
    .filter((item, index, arr) => arr.findIndex((candidate) => candidate.download_url === item.download_url) === index);

  return {
    kind: "post",
    url: resolvedUrl,
    id: resolvedIdMatch ? resolvedIdMatch[1] : targetId,
    author_handle: userLink ? userLink.slice(1) : null,
    author_name: authorName,
    author_url: userLink ? `https://x.com${userLink}` : null,
    created_at: timeEl ? timeEl.getAttribute("datetime") : null,
    text: resolvedText,
    markdown: resolvedMarkdown,
    article_title: primaryTweetText ? null : articleTitle,
    quoted_texts: quotedTweetTexts,
    quoted_posts: quotedTweetEntries,
    media,
    extraction_path: "eval",
    lang: article.getAttribute("lang") || document.documentElement.lang || null,
  };
})()
EOF
}
EXTRACTOR_B64="$(build_extractor_b64)"

extract_post_via_eval() {
  local result=""
  local eval_output=""
  local attempt=0

  while (( attempt < 12 )); do
    if eval_output="$(run_browser --json eval -b "$EXTRACTOR_B64" 2>/dev/null)"; then
      if result="$(jq -c '.data.result' <<<"$eval_output" 2>/dev/null)" && is_valid_json_object "$result"; then
        if [[ "$(jq -r '.kind' <<<"$result")" != "pending" ]]; then
          printf '%s\n' "$result"
          return 0
        fi
      fi
    fi
    run_browser wait 250 >/dev/null 2>&1 || true
    attempt=$((attempt + 1))
  done

  printf '%s\n' "${result:-}"
}

blocked_result() {
  local url="$1"
  local reason="$2"
  local extraction_path="$3"
  local status_id=""

  status_id="$(extract_status_id "$url")"
  jq -nc \
    --arg url "${url%%\?*}" \
    --arg id "$status_id" \
    --arg reason "$reason" \
    --arg extraction_path "$extraction_path" \
    '{
      kind: "blocked",
      url: $url,
      reason: $reason,
      extraction_path: $extraction_path
    } + (
      if ($id | length) > 0
      then {id: $id}
      else {}
      end
    )'
}

extract_post() {
  local result=""
  local current_url=""
  local result_kind=""
  result="$(extract_post_via_eval)"

  if is_valid_json_object "$result"; then
    result_kind="$(jq -r '.kind // ""' <<<"$result" 2>/dev/null || true)"
    if [[ "$result_kind" == "post" ]]; then
      jq -c . <<<"$result"
      return 0
    fi
    if [[ "$result_kind" == "blocked" ]]; then
      jq -c . <<<"$result"
      return 0
    fi
  fi

  run_browser wait --load networkidle >/dev/null 2>&1 || true
  result="$(extract_post_via_eval)"
  if is_valid_json_object "$result"; then
    result_kind="$(jq -r '.kind // ""' <<<"$result" 2>/dev/null || true)"
    if [[ "$result_kind" == "post" ]]; then
      result="$(jq -c '. + {extraction_path: "eval_after_networkidle"}' <<<"$result")"
      jq -c . <<<"$result"
      return 0
    fi
    if [[ "$result_kind" == "blocked" ]]; then
      result="$(jq -c '. + {extraction_path: "eval_after_networkidle"}' <<<"$result")"
      jq -c . <<<"$result"
      return 0
    fi
  fi

  current_url="$(run_browser get url 2>/dev/null | tail -n 1 || true)"
  blocked_result "${current_url:-}" "exact_post_not_found_after_retries" "fail_closed"
}

choose_auth_flags

RAW_TARGETS=()
while IFS= read -r raw_target; do
  RAW_TARGETS+=("$raw_target")
done < <(read_targets "$@" | sed '/^[[:space:]]*$/d')

if [[ "${#RAW_TARGETS[@]}" -eq 0 ]]; then
  echo "No post URLs or IDs supplied." >&2
  exit 2
fi

tmp_results="$(mktemp)"
SESSION_STARTED=0
cleanup() {
  local status=$?
  rm -f "$tmp_results"
  if (( SESSION_STARTED == 1 )); then
    run_browser close >/dev/null 2>&1 || true
  fi
  return "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

for raw_target in "${RAW_TARGETS[@]}"; do
  target_url="$(normalize_target "$raw_target")"
  ensure_open "$target_url"
  post_json="$(extract_post)"
  jq -c . <<<"$post_json" >>"$tmp_results"
done

jq -s '.' "$tmp_results"
