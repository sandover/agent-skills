#!/usr/bin/env node
/*
Purpose: Render compact Obsidian-friendly Markdown from harvested X/Twitter JSON.
Key exports: CLI that writes one Markdown archive file and local media files.
Role: Keep archive presentation and image downloading deterministic outside the model.
Invariants: Preserve post order, keep tweet metadata compact, write media under one
attachments directory, and make Markdown point only at local attachment paths.
The script accepts the JSON shape emitted by fetch_recent_liked_posts.sh.
*/

import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";

function usage() {
  console.error(`Usage:
  render_x_archive_markdown.mjs --input liked.json --output archive.md [--attachments-dir attachments] [--image-width 360]
`);
}

function parseArgs(argv) {
  const args = {
    input: "",
    output: "",
    attachmentsDir: "attachments",
    imageWidth: 360,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--input") args.input = argv[++i] || "";
    else if (arg === "--output") args.output = argv[++i] || "";
    else if (arg === "--attachments-dir") args.attachmentsDir = argv[++i] || "";
    else if (arg === "--image-width") args.imageWidth = Number(argv[++i] || "");
    else if (arg === "-h" || arg === "--help") {
      usage();
      process.exit(0);
    } else {
      console.error(`Unknown argument: ${arg}`);
      usage();
      process.exit(2);
    }
  }

  if (!args.input || !args.output || !args.attachmentsDir || !Number.isFinite(args.imageWidth) || args.imageWidth <= 0) {
    usage();
    process.exit(2);
  }

  return args;
}

function cleanHandle(value) {
  return String(value || "unknown").replace(/^@/, "") || "unknown";
}

function accountUrl(post) {
  const handle = cleanHandle(post.author_handle);
  return post.author_url || (handle !== "unknown" ? `https://x.com/${handle}` : "");
}

function statusId(post) {
  const match = String(post.url || "").match(/status\/(\d+)/);
  return String(post.id || match?.[1] || "unknown");
}

function dateOnly(value) {
  if (!value) return "unknown date";
  const parsed = new Date(value);
  return Number.isNaN(parsed.valueOf()) ? String(value) : parsed.toISOString().slice(0, 10);
}

function imageExtension(url) {
  try {
    const parsed = new URL(url);
    const format = parsed.searchParams.get("format");
    if (format && /^[a-z0-9]+$/i.test(format)) return `.${format.toLowerCase()}`;
    const ext = path.extname(parsed.pathname);
    if (ext && ext.length <= 6) return ext.toLowerCase();
  } catch {
    return ".jpg";
  }
  return ".jpg";
}

function localMediaName(post, media, index) {
  const id = statusId(post);
  const handle = cleanHandle(post.author_handle).replace(/[^a-z0-9_-]+/gi, "-").slice(0, 40);
  const ext = imageExtension(media.download_url || media.url || "");
  return `x-${id}-${handle}-${String(index + 1).padStart(2, "0")}${ext}`;
}

async function downloadMedia(url, destination) {
  const response = await fetch(url, {
    headers: {
      "user-agent": "Mozilla/5.0 x-post-text-archive",
      accept: "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8",
    },
  });
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`);
  }
  const buffer = Buffer.from(await response.arrayBuffer());
  await writeFile(destination, buffer);
}

function compactHeader(post) {
  const handle = cleanHandle(post.author_handle);
  const authorName = String(post.author_name || "").trim();
  const displayName = authorName || `@${handle}`;
  const bits = [
    dateOnly(post.created_at),
    `${displayName} / [@${handle}](${accountUrl(post)})`,
    `[link](${post.url || ""})`,
  ];
  if (post.reason) bits.push(`issue: ${post.reason}`);
  return `## ${bits.join(" • ")}`;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const payload = JSON.parse(await readFile(args.input, "utf8"));
  const posts = Array.isArray(payload) ? payload : payload.posts || [];
  const outputDir = path.dirname(path.resolve(args.output));
  const attachmentsAbs = path.resolve(outputDir, args.attachmentsDir);
  await mkdir(attachmentsAbs, { recursive: true });

  const lines = [
    `# Recent liked tweets - ${new Date().toISOString().slice(0, 10)}`,
    "",
    "Harvested from X Likes via authenticated Chrome session. Newest-first as collected.",
    "",
  ];

  for (const [postIndex, post] of posts.entries()) {
    const mediaItems = Array.isArray(post.media) ? post.media.filter((item) => item?.download_url || item?.url) : [];
    const localMedia = [];

    for (const [mediaIndex, media] of mediaItems.entries()) {
      const fileName = localMediaName(post, media, mediaIndex);
      const destination = path.join(attachmentsAbs, fileName);
      const relativePath = path.posix.join(args.attachmentsDir.replaceAll(path.sep, "/"), fileName);
      try {
        await downloadMedia(media.download_url || media.url, destination);
        localMedia.push({ ...media, relativePath });
      } catch (error) {
        localMedia.push({ ...media, error: error.message });
      }
    }

    lines.push(compactHeader(post));
    lines.push("");

    lines.push(String(post.markdown || post.text || "").trim() || "_No text extracted._");
    lines.push("");

    for (const media of localMedia) {
      if (media.relativePath) {
        lines.push(`![[${media.relativePath}|${args.imageWidth}]]`);
      } else {
        lines.push(`- Image download failed: ${media.download_url || media.url} (${media.error || "unknown error"})`);
      }
    }

    if (localMedia.length > 0) lines.push("");
    if (post.reason) lines.push(`_Extraction issue: ${post.reason}_`);
    lines.push("");
    if (postIndex < posts.length - 1) {
      lines.push("---");
      lines.push("");
    }
  }

  await writeFile(args.output, `${lines.join("\n").replace(/\n{4,}/g, "\n\n\n").trim()}\n`, "utf8");
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
