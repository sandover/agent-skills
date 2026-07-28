---
name: windows-vm-control
description: Control and automate a VMware Fusion Windows VM from a host Mac Codex session. Use for Windows commands, files, Git, builds, tests, VM lifecycle, native Windows GUI interaction, screenshots, login or UAC boundaries, and optional delegation to Codex inside the VM.
---

# Control a Windows VM from the host

## Working model

The host agent owns the task. It operates the Windows guest directly or
delegates a bounded outcome to a guest agent.

- **Host agent:** This Codex session. It owns the task, user communication,
  decisions, and final evidence.
- **Windows guest:** The VM. It supplies Windows-native tools, files, processes,
  applications, and UI.
- **Guest agent:** A Codex process launched inside Windows for a bounded
  delegated turn. It owns the delegated outcome, not the whole task.

Choose where reasoning runs:

| Mode | Use it when | How results return |
| --- | --- | --- |
| **Direct SSH** — default | The host agent can drive the work with Windows commands and inspect the results itself. | Command stdout and stderr return over SSH. No guest agent runs. |
| **Attached guest agent** | Open-ended Windows work benefits from a second agent that can inspect, debug, and adapt locally. | SSH runs `codex exec --json`; the guest agent's event stream and final answer return over the same SSH connection. |
| **Detached guest agent** | The guest agent must remain active after an SSH call ends or must work from the signed-in desktop session. | `vmrun` launches it in the desktop session; Plasmite carries acknowledgments, progress, results, and blockers. |

Use a guest agent for delegated reasoning. Use Plasmite only when SSH does not
carry the guest agent's request and response.

## Operating path

Use these phases as landmarks, not ceremony:

1. **Scope:** Establish the outcome, proof, boundaries, and authorized effects.
2. **Access:** Try the cheapest applicable connection. Repair only the layer
   that is unavailable.
3. **Choose:** Use direct SSH for command work, an attached guest agent for
   delegated reasoning, and desktop control for visible behavior.
4. **Execute:** Let one operator own each action. Add visual control only when
   command output cannot prove the behavior.
5. **Verify:** Match evidence to the claim. Record relevant limitations.
6. **Close:** Stop only task-owned processes and preserve guest state that the
   user may need. Note any material delay worth removing next time.

For a configured, running VM, start with the task itself:

```bash
ssh -o BatchMode=yes windows-vm \
  'powershell.exe -NoProfile -NonInteractive -Command "$env:COMPUTERNAME; whoami"'
```

Do not run a generic readiness inventory. If access is new or broken, read
[configuration.md](references/configuration.md).

## Control planes

Use each mechanism for what it does well:

| Plane | Use for | Do not use for |
| --- | --- | --- |
| SSH | PowerShell, files, Git, builds, tests, logs, and attached guest-agent turns | Inspecting or controlling the signed-in desktop |
| `scripts/windows-vmrun` | VM power, VMware Tools, guest processes, file transfer, screenshots, keyboard input, and launching a process in the signed-in session | A conversational shell or routine command execution |
| Windows automation or host control of Fusion | Named native controls, clicks, typing, and visual judgment | Work that a command or application API can prove |

Run bundled commands from this skill's directory, or resolve their absolute
paths before use.

SSH and VMware Guest Operations can have different users, environment
variables, PATHs, and desktop sessions. A failure in one does not prove that
the same command fails in another.

## Direct SSH

Use direct SSH for ordinary Windows work. The host agent reasons about each
result and sends the next command. No Codex process runs in Windows.

Run a short PowerShell command:

```bash
ssh windows-vm \
  'powershell.exe -NoProfile -NonInteractive -Command "$PSVersionTable.PSVersion"'
```

For multiline PowerShell, write a `.ps1`, copy it, and run it. This is more
reliable than escaping a long program through several shells. Windows
PowerShell 5.1 reads a BOM-less script as ANSI, so save the script as UTF-8
with BOM. When output can contain non-ASCII text, start the script with:

```powershell
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
```

The first line also makes non-terminating PowerShell errors fail the SSH
command instead of returning a misleading success.

```bash
scp ./task.ps1 windows-vm:task.ps1
ssh windows-vm \
  'powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\task.ps1'
```

Treat the guest as a persistent workstation. Inspect its existing repository,
branch, dirty state, tools, and credentials before changing setup. Reuse a
suitable checkout and tools. Change setup only when the task requires it.

## Attached guest-agent delegation

Use this mode when independent Windows-native reasoning will save more effort
than coordination costs. The SSH process carries the complete Codex turn,
including its JSONL events and final response.

Before the first delegated turn, confirm that `codex` is available in the same
SSH environment:

```bash
ssh windows-vm 'codex --version'
```

Write a concise UTF-8 handoff file:

- **Outcome:** What the guest agent must accomplish.
- **Proof:** Evidence that demonstrates completion.
- **Boundaries:** Exclusions and conditions that require the host or user. Name
  the checkout to reuse and preserve unrelated dirty work, branches, and
  stashes.
- **Authority:** Approved installs, Git operations, UI actions, and other
  effects.

Let the guest agent choose its method. Tell it to own the delegated work end to
end and to stop with a clear blocker before any credential request, UAC prompt,
consequential ambiguity, or hard-to-reverse action needs the user.

Start an attached turn and retain its JSONL trace:

```bash
ssh -o ServerAliveInterval=30 windows-vm \
  'codex exec --json -C C:\src\project -m <MODEL> -c model_reasoning_effort=<EFFORT> -c service_tier=<TIER> -' \
  < handoff.txt | tee /tmp/windows-codex.jsonl
```

Ask the user for model, reasoning, or service-tier choices only when no
applicable choice is already known. Add
`--dangerously-bypass-approvals-and-sandbox` only when the user has authorized
maximum permissions for an isolated or disposable VM. Reuse standing
authorization for that VM; do not ask again for each turn.

The first `thread.started` event contains the session ID. Save it if follow-up
is likely:

```bash
jq -r 'select(.type == "thread.started") | .thread_id' \
  /tmp/windows-codex.jsonl | head -1
```

Continue the same guest-agent conversation:

```bash
ssh windows-vm \
  'codex exec resume <SESSION_ID> --json -' \
  < follow-up.txt | tee -a /tmp/windows-codex.jsonl
```

Monitor the streamed JSONL while the attached SSH command runs. The command
ends when the Codex turn ends. Treat tool results and the final agent message
as evidence, not as an instruction to duplicate the guest agent's work. The
host agent still decides whether the proof is sufficient and handles all user
consultation.

If the SSH environment cannot find `codex`, check that environment's PATH and
locate the explicit executable before changing the installation or control
mode.

## Desktop and visual work

An SSH success does not prove that a visible application changed. When the
claim concerns Windows UI, use the lowest-cost control that can prove it:

1. Application command, API, log, or saved artifact.
2. Windows UI Automation by control name, role, or state.
3. Fresh screenshot plus a deliberate keyboard or mouse action.

Launch a visible process in the signed-in session:

```bash
scripts/windows-vmrun runProgramInGuest \
  -noWait -activeWindow -interactive \
  'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' \
  -NoExit -NoProfile
```

Capture the display without foregrounding Fusion:

```bash
scripts/windows-vmrun captureScreen /tmp/windows-vm.png
```

Send literal keyboard input only after confirming the active window:

```bash
scripts/windows-vmrun typeKeystrokesInGuest 'literal text'
```

Keystroke injection is focus-sensitive. `vmrun` does not provide a reliable,
portable mouse-click command or special-key notation. Use Windows UI Automation
for repeatable control and host control of Fusion for occasional visual actions.
Confirm the result from fresh state after every state-changing UI action.

If a capture is black, check whether Windows is asleep or locked. Send one
harmless literal input, such as a space, and capture once more. If it remains
black, stop and report the control failure instead of exploring unrelated
mechanisms. Never type a password through keystroke injection; ask the user to
sign in.

## Detached guest-agent delegation

Use a detached guest agent only when attachment through SSH is unsuitable. It
runs in the signed-in desktop session and has no stdout connection to the host
agent. Plasmite supplies the missing observable message channel.

Before assigning work:

1. Confirm that the configured guest account is signed in at the Windows
   console. Capture the screen once to distinguish the desktop from a lock
   screen.
2. Account for existing task-owned Codex and PowerShell processes:

   ```bash
   scripts/windows-vmrun listProcessesInGuest
   ```

   Launch exactly one guest agent.
3. Confirm that the host Plasmite service and the guest MCP connection are
   available.
4. Send a brief hello and require an acknowledgment through Plasmite. This
   proves that the process can both read and write the channel.
5. Send the task only after the acknowledgment.

Use simple messages; do not invent a protocol:

```bash
plasmite feed codex-bridge --tag host-guide \
  '{"msg":"Hello. Reply here when ready."}'
plasmite follow codex-bridge --tail 5
plasmite follow codex-bridge --timeout 60s --format jsonl
```

The JSON object is only the message payload required by `plasmite feed`, not a
coordination schema. Use `--format jsonl` when machine-readable follow output is
useful.

The detached agent must treat the assignment as one continuing turn: work,
report meaningful progress, wait again after an empty Plasmite wait, and send a
result or blocker before ending. `codex exec` runs one turn and exits. If the
channel is quiet, use `listProcessesInGuest` to distinguish a live turn from an
ended process. Keep waiting for a live process. If it ended without reporting,
relaunch once with the same bootstrap. Do not create a second live agent.

If no acknowledgment arrives during one bounded wait, capture the screen once
and report the launch failure. Do not launch another agent.

Tell the detached agent to notify the host through Plasmite before knowingly
triggering a permission, login, or UAC prompt. If either agent needs a user
decision, both stop and the host agent asks the user.

Launch a detached agent through `runProgramInGuest -activeWindow -interactive`
with an explicit Codex path verified in the signed-in user context. Guest
Operations often has a different PATH from interactive PowerShell. Put the
bootstrap instruction in a UTF-8 file rather than in injected keystrokes or a
deeply escaped command. The bootstrap tells the agent to acknowledge through
Plasmite and keep waiting; it does not contain the substantive task.

```bash
scripts/windows-vmrun copyFileFromHostToGuest \
  ./detached-bootstrap.txt 'C:\Temp\detached-bootstrap.txt'
scripts/windows-vmrun runProgramInGuest \
  -noWait -activeWindow -interactive \
  'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' \
  -NoExit -NoProfile -Command \
  "& '<CODEX_EXE>' exec -C '<PROJECT_DIR>' -m '<MODEL>' -c 'model_reasoning_effort=<EFFORT>' -c 'service_tier=<TIER>' (Get-Content -Raw -Encoding UTF8 'C:\Temp\detached-bootstrap.txt')"
```

Add `--dangerously-bypass-approvals-and-sandbox` to this launcher only with the
same disposable-VM authorization used for an attached agent. After the
acknowledgment arrives, send the compact outcome, proof, boundaries, and
authority handoff through Plasmite.

Use Plasmite only for coordination. The guest agent remains responsible for
its own Git, build, install, debug, test, and evidence work.

## Decision support

| State or need | Action |
| --- | --- |
| VM is stopped | Use `scripts/windows-vmrun start gui` when desktop work is expected; otherwise use `scripts/windows-vmrun start nogui`. |
| SSH works and the task is command-line work | Use direct SSH. |
| SSH works and open-ended local reasoning adds value | Run one attached guest-agent turn with `codex exec --json`. |
| SSH or VMware Tools is unavailable | Run `scripts/windows-vmrun doctor`, then use [configuration.md](references/configuration.md) to repair that layer. |
| A process must appear on the signed-in desktop | Launch it once with `runProgramInGuest -activeWindow -interactive`. |
| The task requires a persistent or asynchronous guest agent | Use one detached agent and Plasmite. |
| Several shells or agents exist | Identify the task-owned process. Preserve unrelated processes and stop only known duplicates. |
| A visible action is unexpectedly quiet | Capture the screen once. Do not start another shell merely because progress is unclear. |
| UAC, login, or another security prompt appears | Stop at the decision boundary. Use an already-authorized path or involve the user. Do not click blindly. |
| The user or another operator takes the desktop | Stop visible input and resynchronize before continuing. |

## Guardrails

- Keep passwords and tokens in credential stores. Do not put them in prompts,
  Plasmite, repositories, screenshots, command history, or the clipboard.
- Resolve the exact VM, process, path, repository, and desktop target before
  changing state.
- Preserve unrelated guest files, shells, agents, repositories, and dirty Git
  work.
- Treat VM reset, snapshot restoration, deletion, and power-off as destructive.
- Use UTF-8 for prompts and evidence exchanged between macOS and Windows. Save
  Windows PowerShell 5.1 scripts as UTF-8 with BOM.
- One operator controls a visible application at a time. Prefer named controls
  and fresh state over coordinates, stale screenshots, and fixed delays.
- UAC secure desktop is a separate boundary. Ordinary SSH, keystroke injection,
  and UI automation may not control it. Do not weaken UAC or invent an
  elevation path during a test.
- A command exit code, agent message, or screenshot proves only what it directly
  shows. Match evidence to the requested behavior.
