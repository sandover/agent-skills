---
name: claude-review
description: Use the local Claude CLI as a read-only second-opinion reviewer for briefs, plans, architecture decisions, code changes, and other substantial artifacts, then verify and selectively incorporate its feedback. Default to Opus; use another Claude model when the user requests one. Use when the user invokes $claude-review, asks for an Opus or Claude review, or asks to repeat the familiarize-review-incorporate workflow in any project.
---

# Claude Review

Use Claude for an independent review. Default to Opus. If the user names a
model, use that model for the review. Keep Codex responsible for deciding what
to change and for making all edits.

## Establish the review scope

1. Infer the target artifacts from the user's request and current conversation.
   Proceed without a question when the targets are clear. If none are named,
   inspect the relevant changed files and recent context before asking.
2. Run Claude from the target artifact's directory, or its nearest common
   parent. Do not invoke it from an unrelated workspace and compensate with
   extra directory-access flags.
3. Read the project's instructions, durable local guidance, primary README, the
   target artifacts, and only the nearby files that own affected product,
   architecture, or implementation contracts. Common instruction files include
   `AGENTS.md`, `CLAUDE.md`, and `.scratch/napkin.md`.
4. Preserve unrelated work. Do not ask Claude to edit files.

Choose context that lets Claude understand the project without flooding the
review. Normally include:

- the primary project or component README;
- the current product, data, or architecture contract affected by the work;
- the focused UI, API, persistence, or implementation files involved; and
- every brief that must be reviewed together.

## Run a read-only Claude review

Invoke the authenticated local CLI non-interactively:

```bash
claude -p \
  --model opus \
  --effort high \
  --permission-mode dontAsk \
  --tools Read,Glob,Grep \
  --allowedTools Read,Glob,Grep \
  --no-session-persistence \
  --output-format json \
  "<review prompt>"
```

Replace `opus` only when the user specifies another Claude model.

The prompt must:

- say that the review is read-only and Claude must not edit files;
- name the target files and the authoritative context it should read;
- require the complete assessment in one final response;
- forbid questions and plan-mode communication;
- ask for an executive judgment, prioritized must-fix issues with exact
  locations and concrete corrections, useful refinements, and what should
  remain unchanged;
- ask Claude to identify contradictions with live project contracts; and
- reject scope expansion, infrastructure, dependencies, or abstractions unless
  the promised outcome requires them.

Treat explicit invocation of this skill as authorization to make the requested
Claude CLI call. Follow the environment's normal approval boundary if the
command still requires host or network escalation.

Opus at high effort can take approximately five minutes. Poll at intervals no
longer than 60 seconds and give the user concise progress updates. Do not
interrupt a live process merely because it has not emitted partial output.

Read the JSON `result` field. Do not report token, cache, or cost metadata unless
the user asks. If the CLI returns only a closing question that refers to a
missing review, retry once with the command above and an explicit instruction
to return the complete assessment in its single final response. Do not use
`--permission-mode plan` for the retry.

If the command returns no result, retry once with a shorter prompt. If it still
does not return a result, report that failure plainly. Do not invent an
authentication or workspace diagnosis.

## Evaluate the feedback

Do not accept suggestions mechanically.

1. Verify every material factual claim against the live repository.
2. Keep user decisions, current product contracts, and the requested scope in
   control.
3. Prefer corrections that remove contradictions, hidden coupling, ambiguous
   ownership, or unimplementable promises.
4. Reject advice that is factually wrong, duplicates a source of truth, or
   broadens the feature without protecting its outcome.
5. If feedback exposes a material product choice the user has not already made,
   present that choice instead of silently deciding it.
6. Keep current-state documents accurate until the future feature is
   implemented. A proposal may name the authoritative documents that the
   implementation must update later.

Use `apply_patch` for accepted edits. Preserve unrelated changes.

## Validate and report

Run checks proportional to the files changed. For documentation, use
`git diff --check`, trailing-whitespace checks, and referenced-file checks.
Do not run code tests for a documentation-only revision.

Report:

- Claude's overall judgment;
- the material feedback incorporated;
- any important suggestion rejected and why;
- the files changed; and
- the checks run and checks skipped.
