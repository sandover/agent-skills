---
name: claude-review
description: Use the local Claude CLI as a second-opinion reviewer for briefs, plans, architecture, and code, then selectively incorporate its feedback. Use when the user invokes $claude-review or asks for an Opus or Claude review.
---

# Task Overview

You will seed a prompt to the claude CLI and read back the results; the claude CLI may use tools but its review should be read-only.

Default to `claude-opus-5`, or use `claude-sonnet-5` when the user requests Sonnet. You remain responsible for deciding what feedback to incorporate

You should run claude from the same project directory you are working in so it sees the same AGENTS.md as you and the same directory context. Treat it as a peer agent. Claude may use tools.

## Recipe

1. Choose target artifacts based on the user's request and context
2. Plan a *brief* prompt for claude. Claude is plenty smart; lots of specification doesn't help.
      - Example: "Review the dirty working tree and propose improvements."
      - Example: "Review ergo epic ABCDEF and propose improvements. Learn ergo via `ergo --help`"
3. Show the prompt to the user, for transparency.
4. Invoke claude, and then monitor it. You probably need to run claude outside the sandbox.
5. Evaluate claude's feedback carefully and objectively. Adopt the best of it.
6. Inform the user.

## Example claude invocation command

```bash
claude -p \
  --model claude-opus-5 \
  --effort medium \
  --permission-mode auto \
  --tools Read,Glob,Grep,Bash \
  --no-session-persistence \
  --output-format json \
  "<review prompt>"
```

Use automatic permission mode instead of a command allowlist. It lets Claude
run ordinary read-only shell discovery even when it adds wrappers, pipelines,
or output limits, while retaining a permission boundary for risky operations.
The prompt should keep the review read-only. Add other tools when the review
needs them; do not use `--allowedTools` or bypass permission checks for a normal
review.

Opus at medium effort can take several minutes. Poll at intervals no
longer than 60 seconds and give the user concise progress updates. Do not
interrupt a live process merely because it has not emitted partial output.

If claude supplies token, cache, or cost metadata, relay to the user, for transparency.
