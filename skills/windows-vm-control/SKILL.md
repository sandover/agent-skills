---
name: windows-vm-control
description: Run commands, delegate development, and inspect or operate Windows desktop apps in the configured VMware Fusion VM from a Mac. Includes VM lifecycle and access recovery.
---

# Windows VM Control

Work on the configured Windows VM as a persistent computer with its own files, processes, accounts, and desktop. Follow the user's authorization and execution preferences. Loading this skill does not authorize unrelated effects.

Run `scripts/...` from this skill directory, or use absolute paths. Host sandbox restrictions may require host access for Fusion, Keychain, and the private VM network; request access for the specific operation when needed.

## Choose a route

- **Commands:** Use SSH for simple commands and the PowerShell helper for scripts. Read [Command work](references/command-work.md). Use [task records](references/task-results.md) when output must survive an interrupted session or support follow-up.
- **Delegate:** Give Windows Codex one bounded outcome when the work benefits from Windows-side judgment. Read [Command work](references/command-work.md); use [managed delegation](references/managed-delegation.md) when the assignment needs steering, user input, or orderly interruption. For exact revisions and architecture-specific builds, see [Source and builds](references/source-and-builds.md).
- **Desktop:** Read [Desktop work](references/desktop-work.md) to inspect or operate signed-in Windows applications.

Use the operation needed for the task as the live check. If it succeeds on the intended VM and account, continue without checking unrelated capabilities. Delegation runners check their own prerequisites; use [Access recovery](references/access-recovery.md) only when the needed route fails. Follow [VM lifecycle](references/lifecycle.md) to start or resume the VM when needed and to shut it down gracefully after the task when no other work owns it.

## Keep boundaries clear

- **Scope:** Preserve unrelated files and ongoing work. Verify the computer, account, and target paths before destructive or identity-sensitive actions. Follow the lifecycle procedure for start, resume, and task-end shutdown. Changing accounts, taking over another checkout, resetting Windows, changing snapshots, or repairing access configuration requires authorization for that effect.
- **Identity:** The user enters passwords, PINs, passkeys, and MFA responses in identity prompts. Configured credentials may enable helpers; never copy secrets into prompts or logs. Approve UAC only for an authorized elevation with a verified program and action.
- **Input and ownership:** Get consent before taking Mac focus or controlling the Mac pointer, unless already authorized. Guest-only automation may proceed when it leaves Mac input alone. Choose one executor for guest changes and one driver for desktop input; after delegation, do not start competing work until the assignment ends or its state is reconciled.
- **Uncertain completion:** After a timeout or lost connection, inspect what ran and changed before repeating a mutation. Stop only task-owned processes; never kill every Codex, PowerShell, or Acrobat process as cleanup.

## Use evidence that answers the question

Access methods are independent: SSH proves command execution in its account; Tools enables Guest Operations; an interactive launch reaches the signed-in desktop; a Fusion capture shows the screen Fusion displays. A working route is enough for work it can complete. A failed route does not prove Windows is powered off.

For a build, retain the command result and artifact identity. For installation, check the installed artifact. For visible behavior, observe the application. Reuse evidence that still supports the claim and add a check only for a remaining gap. A guest's report is useful when backed by recorded commands and results; protocol completion proves only that the agent stopped.

Finish by stating the result, relevant proof, and any remaining limitation.
