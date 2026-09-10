---
name: windows-vm-control
description: Run commands, delegate development, and inspect or operate Windows desktop apps in the configured VMware Fusion VM from a Mac. Includes VM readiness and access recovery.
---

# Windows VM Control

Work on the configured Windows VM as a persistent computer with its own files, processes, accounts, and desktop. Use the user's existing authorization and execution preferences. An ordinary Windows task can include background use and making the configured VM available. Loading this skill alone does not authorize unrelated effects.

Run `scripts/...` from this skill directory, or use absolute paths. Host sandbox restrictions may require host access for Fusion, Keychain, and the private VM network; request that access for the specific operation when needed.

## Choose the next action

| Need | Default | Read when needed |
| --- | --- | --- |
| Run a known command or inspect a file/process | SSH for simple commands; PowerShell helper for scripts | [Command work](references/command-work.md) |
| Diagnose, implement, or build with Windows-side judgment | One bounded Windows Codex assignment | [Command work](references/command-work.md#delegate-one-outcome) |
| Steer the same assignment or handle interactive requests | Managed Windows Codex session | [Managed delegation](references/managed-delegation.md) |
| Build or test an exact source revision | Fetch the revision and use an isolated guest worktree | [Source and builds](references/source-and-builds.md) |
| Open a file, dismiss a dialog, or sign in while the user is present | Ask for the short UI step when faster than automation | [Desktop work](references/desktop-work.md) |
| Repeat desktop actions or inspect controls | Existing app helper, then interactive UI Automation | [Desktop work](references/desktop-work.md#inspect-the-windows-desktop) |
| Establish visual appearance | Validated Fusion capture, with signed-in desktop fallback | [Desktop work](references/desktop-work.md#capture-or-send-input) |
| Make Windows available | Check the required capability; start or resume only if needed | [VM lifecycle](references/lifecycle.md) |
| Repair failed access | Diagnose the failed method before changing configuration | [Access recovery](references/access-recovery.md) |

These method choices are defaults. A user's choice of executor or workflow takes precedence. Use a working route immediately; a successful SSH command does not need a separate all-capabilities preflight. Delegation helpers perform their own readiness checks.

## Keep the boundaries clear

- **Scope:** Preserve unrelated files and ongoing work. Verify the VM, account, and target paths before destructive or identity-sensitive actions. Changing VM/account, taking over another checkout, resetting or shutting down Windows, changing snapshots, or repairing access configuration needs authorization covering that effect. Do not ask again when it already exists.
- **Identity:** The user enters passwords, PINs, passkeys, and MFA responses in identity prompts. Existing configured credentials may be used by the helpers; never copy secrets into prompts or logs. Approve UAC only for an authorized elevation with a verified program and action.
- **Input:** Get consent before taking Mac focus or controlling the Mac pointer, unless already authorized. Guest-only automation can proceed without that consent when it leaves Mac input alone. Only one actor controls the Windows desktop at a time.
- **Ownership:** Once delegated, Windows Codex owns changes to its checkout and processes. The Mac coordinates and supplies requested host support. Do not run a competing implementation, build, or desktop driver. End or interrupt the active work and reconcile its state before taking over.
- **Uncertain completion:** After a timeout or lost connection, inspect what ran and changed before repeating a mutation. Stop only task-owned processes; never kill every Codex, PowerShell, or Acrobat process as cleanup.

## Use evidence that answers the question

The access methods are independent. SSH proves command execution in its account; Tools enables Guest Operations; an interactive launch reaches the signed-in desktop; a Fusion capture shows the screen Fusion displays. An unknown Tools or VM field does not invalidate a successful SSH result. A failed access method does not establish that Windows is powered off.

For a build, retain the command result and artifact identity. For installation, check the installed artifact. For visible behavior, observe the application. Reuse evidence that already supports the claim; add a check only for a remaining gap. A guest's final report is useful when backed by its recorded commands and results. Protocol completion establishes that the agent stopped, not that the product works.

When a quick user action would unblock the work, give the exact step and the state to leave behind. Stop automated input before handing over, then resume verification after the user is done. Do not spend minutes inventing UI automation for a ten-second action unless automation itself is the deliverable.

Finish by stating the result, the relevant proof, and any remaining limitation. Leave the VM running unless the user requested otherwise. Remove temporary files and processes created for this task when they are no longer needed.
