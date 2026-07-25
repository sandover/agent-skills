---
name: windows-vm-control
description: Guide a Codex agent running in a VMware Fusion Windows VM through the full lifecycle of remote Windows software development and testing from a macOS host. Use for VM readiness, PowerShell and Codex setup, authentication, repository and branch setup, delegated implementation and debugging, Windows UI or UAC intervention, evidence collection, and clean handoff.
---

# Windows VM development guide

Use a Codex instance inside a VMware Fusion Windows guest to own Windows-native
development and testing. Treat `scripts/windows-vmrun` as the deterministic
host control path and Plasmite (an interprocess communication system) as the normal coordination path.

Read [configuration.md](references/configuration.md) during first-time setup or
when moving this workflow to another Mac or VM. Read
[plasmite-protocol.md](references/plasmite-protocol.md) whenever establishing
or repairing the message channel.

## Roles

- **Guide**: the Codex instance on macOS -- this is you. You own readiness, delegation,
  coordination, user communication, and host-only VM control.
- **VM agent**: the Codex instance inside the VM. It owns that machine, its
  separate repository clone, Windows implementation, builds, installation,
  debugging, testing, and evidence.
- **User**: retains decisions about permissions, credentials, material
  ambiguity, and one-way doors.

The VM agent resembles a subagent but is a separate-machine collaborator with
its own filesystem, credentials, processes, repository state, and elevated
capabilities. Do not treat it as a remote shell.

## Ask before starting

Ask once for any missing model, reasoning, and speed choices. Resolve the model
against Codex's actual menu or catalog; do not pass informal shorthand
literally or silently substitute a model.

## Lifecycle and phase gates

Use this state model:

`Contract -> Access -> Agent launched -> Handshake -> Ready -> Instructed -> Working -> Verified -> Closed`

Do not combine handshake with project setup or task execution. Require one
concise receipt before each transition. Treat the mutual decision stop as an
interrupt available in every phase.

Record each phase's start, end, and elapsed time. Distinguish normal work,
waiting, and recovery so later comparisons identify worthwhile acceleration
work without adding continuous telemetry.

### 1. Contract

Agree with the user on the task outcome, model, reasoning level, speed,
permissions, exclusions, and stop conditions. Record which Git operations,
installation, UI control, UAC actions, builds, tests, and external writes are
authorized.

Gate: the guide can state the task and authority without guessing.

### 2. Access

Run `scripts/windows-vmrun doctor`, resolve the intended VM without guessing,
and verify VMware Tools and guest reachability. Use Guest Operations while
Windows is locked for non-UI work. Read
[configuration.md](references/configuration.md) when setup or credentials are
missing.

Gate: the guide can reach the intended VM through one known control path.

### 3. Launch one VM agent

Use Guest Operations to install or repair PowerShell and Codex when needed.
Reuse guest-local Codex authentication; involve the user only at an actual
login, MFA, password, or secret boundary.

Keep one Codex installation owner. For the official PowerShell installation,
update from a separate process after stopping Codex; do not select the
in-session updater or add Winget. Launch one owned PowerShell/Codex tree and
record its PID, session ID when available, configuration, and initial pool
cursor.

Gate: exactly one owned VM-agent process tree is running, and the guide knows
how to identify and stop it.

### 4. Complete a side-effect-free handshake

Read and follow [plasmite-protocol.md](references/plasmite-protocol.md). Pass
the VM-agent bootstrap prompt to `codex exec` through stdin; Windows
command-line quoting is not reliable for a long prompt.

Send `hello` before any project instruction. Continue only after a matching
`hello_ack` proves both message directions, identity, configuration, cursor,
and stop conditions. If it does not match, remain in Handshake and debug that
layer only.

Gate: the guide has observed a valid `hello_ack` over Plasmite.

### 5. Establish project readiness

Send readiness separately from the task. Let the VM agent prepare its own
checkout and toolchain: clone or safely reconcile the repo, read its
instructions, prove remote access, select the intended branch or commit, and
install missing prerequisites. Preserve unrelated changes.

For Ergo projects, match host and guest versions and assign one backlog writer
at a time. Require a readiness receipt with repo, branch, HEAD, dirty state,
remote access, relevant tool versions, and gaps.

Gate: the guide has observed a readiness receipt and accepted or resolved every
reported gap.

### 6. Instruct

Send a self-contained task with outcome, Definition of Done, authority,
exclusions, evidence, cleanup, and feedback requirements. Require `task_ack`
that briefly restates the outcome, boundaries, and stop conditions.

After acceptance, the VM agent owns the Windows problem. Do not duplicate its
engineering from macOS.

Gate: the guide has observed a correct `task_ack`.

### 7. Execute and observe

Use Plasmite as the primary trace. Expect sparse milestone messages, not shell
transcripts. If a deadline passes, inspect the one owned process and its
redacted event log; inspect the screen only when a visible prompt is plausible.
Distinguish work, UAC, authentication, crash, and exit before intervening.

Ask once at a meaningful midpoint what was clear, what caused uncertainty, and
the single highest-value workflow or MCP improvement.

Gate: the VM agent reports that execution and agreed checks are complete.

### 8. Apply the mutual decision stop

For missing permission, material ambiguity, authentication or security
boundaries, or a one-way-door decision, both agents stop related work. The VM
agent sends `needs_user`; the guide gets the user's decision and explicitly
resumes the prior phase. Do not re-ask when existing authorization clearly
answers the question.

### 9. Verify and hand off

Require a final receipt covering outcome, limitations, Git state, checks and
evidence, installed or environment changes, running processes, and cleanup.
Verify proportionally; a sent message or zero exit code alone is not proof.

Gate: the Definition of Done is supported by evidence, and remote or local Git
state matches the authorization.

### 10. Close and learn

Collect final process feedback. Stop the exact owned agent, close task-specific
processes, and report what remains. Leave a polling agent only intentionally.

Gate: the guide has a cleanup receipt and no unexplained process, repository,
or installation state remains.

## Security and reliability

- Keep secrets in host and guest credential stores, never prompts, messages,
  transcripts, repositories, or shell tracing.
- Use Plasmite instead of the shared clipboard.
- Resolve exact targets before overwrite, termination, snapshot, reset,
  deletion, or restoration.
- Treat reset, snapshot restoration, deletion, and power-off as destructive.
