---
name: napkin
description: |
  Per-repo durable rules file. Always active. Read before working, write only
  rules that pass the admission test, keep it under 80 lines.
  Lives at `.scratch/napkin.md`.
---

# Napkin

A per-repo file of **durable rules** that change your behavior in future
sessions. Always active — no trigger required.

## Mechanics

1. **Read** `.scratch/napkin.md` at session start. Apply silently.
2. **Write** when something clears the admission test (below). Write it as a
   rule, not a story.
3. **Compress** before ending any session where you wrote to it. If it's over
   80 lines when you open it, compress first.

If no napkin exists, create one with sections that fit the repo. Typical:
`Rules`, `User Preferences`, `Environment Facts`, `Mistakes to Avoid`.

## Admission Test

Before adding anything, ask:

> "Would a future session behave differently just from reading this — before
> inspecting the repo?"

No → don't write it.

## How to Write

- **Rules, not narration.** State what is true, not how you learned it.
  - ✅ "Always use absolute imports from `src/`."
  - ❌ "User corrected my import style today."
- **Replace, don't append.** New info supersedes old → rewrite, don't add
  a second bullet.
- **Repo-specific only.** General knowledge doesn't belong here.
- **Concrete.** "The API returns `{items: [...]}`, not a bare list."
- **No secrets, no logs, no session history, no task/epic IDs.**

## What Never Belongs

Session chronology. "Created file X." Transition-state narration. One-off
discoveries. General shell trivia (unless it repeatedly bites you *here*).

## Limits

Keep it under 80 lines of content. A 30-line napkin of hard-won rules beats
a 300-line log.
