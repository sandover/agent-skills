---
name: windows-vm-control
description: Control and automate a VMware Fusion Windows VM from a host Mac Codex session. Use for Windows commands, files, Git, builds, tests, VM lifecycle, native Windows GUI interaction, screenshots, login or UAC boundaries, and bounded or managed delegation to Codex inside the VM.
---

# Control a Windows VM from the host

## Working model

- **Host:** The Mac running this Codex session and VMware Fusion.
- **Windows guest:** The Windows installation running inside VMware Fusion.
- **Host agent:** This Codex session. Own the task, user communication, VM
  management, authorization boundaries, and final evidence. In direct
  execution, it also owns the Windows work.
- **Guest agent:** An optional Codex process inside Windows. When delegation
  starts, it becomes the sole executor for the delegated outcome.

Choose both an execution mode and a Windows session.

### Choose the execution mode

| Mode | Use it when | Connection |
| --- | --- | --- |
| **Direct execution** — default | The host agent can use Windows tools, inspect or change guest files, and gather evidence itself. | SSH carries commands, stdout, and stderr. |
| **Bounded delegation** | One self-contained Windows outcome benefits from guest-local reasoning. | SSH runs one `codex exec --json` turn. |
| **Managed delegation** | The host must guide a guest agent across turns, interrupt it, or answer its requests. | SSH carries one tested `codex app-server --stdio` controller. |

Use one executor at a time. After a guest agent starts, the host agent stops
independent guest commands and file inspection until delegation ends. The host
may complete a specific support action requested by the guest or an action that
requires host control of the Windows desktop. Before resuming direct execution,
wait for the guest turn to end and inspect current state.

### Choose the Windows session

| Session | Use it when | Control |
| --- | --- | --- |
| **SSH session** | Files, Git, builds, tests, services, logs, and command-line applications are sufficient. | SSH |
| **Signed-in desktop** | A process must appear on screen or visible behavior matters. | VMware Guest Operations, Windows UI Automation, or host control of Fusion |
| **UAC secure desktop** | Windows requests protected elevation. | Inspect the prompt. Approve a known, expected consequence of an authorized action through host control of Fusion. Escalate when the prompt is unexpected, ambiguous, exceeds the task's authority, or needs user credentials. |

SSH and guest-agent output do not prove what appeared on screen. A guest agent
launched through SSH does not run in the signed-in desktop session. Keep
desktop control with the host agent.

## Operating path

1. **Scope:** Establish the outcome, proof, boundaries, and authorized effects.
2. **Access:** Try the cheapest applicable connection. Repair only the failed
   layer.
3. **Choose:** Prefer direct execution. Delegate only when guest-local reasoning
   repays its coordination cost. Add desktop control only for visible behavior.
4. **Execute:** Let the selected executor own the Windows work. Provide only
   host-controlled support during delegation.
5. **Verify:** Match evidence to the claim.
6. **Close:** Stop only task-owned processes and preserve useful guest state.

For a configured, running VM, try starting with the task through SSH:

```bash
ssh -o BatchMode=yes windows-vm \
  'powershell.exe -NoProfile -NonInteractive -Command "$env:COMPUTERNAME; whoami"'
```

Classify an access failure before changing setup:

- If `windows-vm` does not resolve, repair the host alias.
- If it resolves but cannot connect, inspect the guest address, `sshd`, firewall
  profile, and authentication.
- If the user authorizes setup changes, perform the repair and retry SSH.
  Approve known UAC prompts yourself through host control of Fusion.
- Without authorization, use Guest Operations only for an authorized desktop
  task it can complete directly; otherwise stop and give setup instructions.

Read [configuration.md](references/configuration.md) for VMware setup, Guest
Operations repair, or VM startup. Read [ssh.md](references/ssh.md) for SSH
bootstrapping and repair.

## Control planes

| Plane | Use for | Do not use for |
| --- | --- | --- |
| SSH | PowerShell, files, Git, builds, tests, logs, and guest-agent connections | Proving or controlling visible desktop state |
| `scripts/windows-vmrun` | VM power, VMware Tools, guest processes, file transfer, screenshots, keyboard input, and signed-in-session launches | Routine shell work or commands that need stdout |
| Windows automation or host control of Fusion | Named controls, foreground windows, UAC, clicks, typing, and visual judgment | Work a command or application API can prove |

Run bundled commands from this skill's directory or by absolute path. Run
Keychain-backed `windows-vmrun` commands on the host, not in the sandbox.

SSH and Guest Operations can have different users, environments, PATHs, and
sessions. A failure in one plane does not prove failure in another.

## Additional references

- Read [guest-delegation.md](references/guest-delegation.md) before bounded or
  managed delegation.
- Read [desktop-control.md](references/desktop-control.md) before visible
  application control, input injection, screenshots, or UAC.

## Guardrails

- Keep passwords and tokens in credential stores. Do not put them in prompts,
  repositories, screenshots, command history, or the clipboard.
- Resolve the exact VM, process, path, repository, and desktop target before
  changing state.
- Preserve unrelated guest files, shells, agents, repositories, and dirty Git
  work. Stop only known task-owned duplicates.
- Treat VM reset, snapshot restoration, deletion, and power-off as destructive.
- Let one operator control the visible desktop at a time. If the user or another
  operator takes control, stop input and resynchronize from fresh state.
- Approve UAC or a similar non-identity authorization only when the underlying
  action is already authorized, the target and consequence are clear, and no
  user credential is required. Ask the user to perform passkeys, passwords,
  multifactor authentication, and consent that represents the user's identity.
  Do not weaken UAC or invent an elevation path.
- Treat a command result, agent message, and screenshot as evidence only for
  what it directly shows.
