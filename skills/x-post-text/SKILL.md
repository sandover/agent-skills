---
name: x-post-text
description: Extract the text of one or more X/Twitter posts or tweets, especially when the user wants only the post content and the page must be read through an authenticated Chrome session.
---

# X Post Text

Extract only the fields we actually need from X/Twitter post pages, including longform article-style posts embedded in a status page.

Use this skill when the user gives tweet/post URLs or IDs and wants the post text without pulling full-page content into context. Prefer the bundled script over ad hoc browsing because it keeps the model payload small and reuses the user's Chrome authentication.

## Default Path

1. Prefer `scripts/fetch_x_posts.sh`.
2. Default to `agent-browser --profile Default`, which matches the common local Chrome setup on this Mac.
3. Use `--auto-connect` only when you know Chrome is already running in a mode that `agent-browser` can attach to.
4. Return the script output directly or summarize it, depending on what the user asked for.

Example:

```bash
skills/x-post-text/scripts/fetch_x_posts.sh \
  "https://x.com/jack/status/20" \
  "1881234567890123456"
```

## Likes Workflow

For scrapbook updates, prefer `scripts/fetch_recent_liked_posts.sh`.

Example:

```bash
skills/x-post-text/scripts/fetch_recent_liked_posts.sh \
  --stop-at-file /path/to/scrapbook-tweets.md
```

This wrapper:

- opens your authenticated Likes timeline
- collects recent liked post URLs
- stops when it encounters a status already present in the scrapbook file, if provided
- extracts compact post payloads for only the new likes
- limits each run to 25 posts and 8 scrolls
- uses separate collection and extraction sessions and closes both on exit
- returns machine-readable output for the model to merge into the scrapbook

If the harvest returns `stop_reason: limit_reached`, keep and merge that bounded batch. Do not rerun with a higher limit or scroll count. Long X timelines can retain several GiB in a renderer. Tell the user that the bounded batch reached its cap; a deeper catch-up needs a separate paginated workflow rather than one larger browser session.

If you only want the URLs before deciding what to do next, use `scripts/collect_liked_post_urls.sh`.

Example:

```bash
skills/x-post-text/scripts/collect_liked_post_urls.sh \
  --stop-at-file /path/to/scrapbook-tweets.md \
  --limit 25 \
  --json
```

This helper:

- opens your authenticated Likes timeline
- collects recent liked post URLs
- stops when it encounters a status already present in the scrapbook file, if provided
- returns machine-readable output so the model can decide what to do next

If you only want the URLs for piping into the main extractor, use `--urls-only`.

The script emits a JSON array with compact per-post objects:

- `url`
- `id`
- `author_handle`
- `author_name`
- `author_url`
- `created_at`
- `text`
- `markdown`
- `quoted_texts` for embedded/quoted tweet text separated from the main tweet body
- `quoted_posts` for embedded/quoted tweet text plus quoted author and status URLs when detectable
- `article_title` when longform article extraction is used
- `media` with image or video-thumbnail URLs, downloadable URLs, and alt text when detectable
- `extraction_path`
- `lang`
- `reason` when extraction fails closed

The likes collector emits a JSON object with:

- `likes_url`
- `handle`
- `collected_urls`
- `matched_existing_id` when it stopped on an already-known post
- `stop_reason`
- `scrolls_used`

The scrapbook wrapper emits the same harvest metadata plus:

- `posts`

For an Obsidian-friendly offline review/archive file, render the wrapper JSON with:

```bash
scripts/render_x_archive_markdown.mjs \
  --input /path/to/recent-liked-posts.json \
  --output /path/to/recent-liked-posts.md \
  --attachments-dir attachments \
  --image-width 360
```

The renderer downloads post images into the local attachments directory and inserts compact per-post headers plus Obsidian image embeds after the tweet text. The `--image-width` value maps to Obsidian's `![[path|width]]` display sizing. Normal extraction provenance such as `eval` is not included in the Markdown; only failed or abnormal extractions get an explicit issue note.

## Post-Processing: Fix Broken Mentions and URLs

After rendering, apply these two cleanup passes to the output markdown before writing it to its final destination. X's DOM represents `@mentions` and long URLs as separate span elements; the extractor joins them with newlines, which breaks readability.

**Pattern 1 — orphaned `@mention` on its own line:**
```
some text trailing space\n@handle\n leading space continues
```
→ join into: `some text trailing space @handle leading space continues` (collapsing the extra spaces to one).

**Pattern 2 — broken URL spread across lines:**
```
https://\nrest.of/url\nfragment
```
or any line whose only content is a URL fragment that continues from the line above (starts mid-domain or mid-path with no space).

→ concatenate the fragments into a single unbroken URL.

The safest approach: read each post's text block, identify lines that are *only* a `@mention` or a bare URL fragment (no surrounding prose), and rejoin them with the adjacent lines. Do not alter lines that stand alone as complete sentences.

## Why This Is Token-Efficient

- It uses `agent-browser eval` instead of `snapshot` or full-page text grabs.
- The extraction runs in the page and returns only the structured fields we care about.
- It avoids loading HTML, accessibility trees, screenshots, or unrelated timeline content into the model.
- For longform article posts, it first targets X's dedicated longform article nodes and returns the full article body instead of just the visible heading cards.
- For quote posts, it keeps embedded tweet text separate from the main tweet body and renders the embedded text as an Obsidian quote callout with a direct `open` link when the quoted status URL is detectable.
- It captures post image URLs for archive rendering while keeping the default JSON compact.
- It avoids heavyweight post-open load-state waits on X pages and instead polls for the post content to appear.
- It validates each per-post JSON object before adding it to the final array.
- If the DOM extractor keeps returning `pending`, it retries after a light `networkidle` wait and then fails closed with a machine-readable reason instead of guessing from unrelated page text.

## Fallback Ladder

Use these only when the default script does not produce the target post:

1. `agent-browser wait --load networkidle`, then retry.
2. If the script still returns `blocked`, inspect the page manually or with a one-off targeted browser command.
3. If the browser session is missing auth, ask the user to sign in in Chrome and rerun.

Do not start with full-page snapshots or generic page summarization.

## Notes

- X help currently says public posts are visible to anyone, while protected posts are visible only to followers. Even so, using the authenticated browser path is safer because it works for protected posts the user can access and avoids public-web gating quirks.
- If the user needs many posts repeatedly, this browser path is usually lower-friction than setting up an X developer app just to read text.
- On this machine, `--profile Default` has been the reliable authentication path. `--auto-connect` is optional and depends on a separately attachable Chrome session.
