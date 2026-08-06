---
name: windows-vm-control
description: Control and automate a VMware Fusion Windows VM from a host Mac Codex session. Use for Windows commands, files, Git, builds, tests, VM lifecycle, native Windows GUI interaction, screenshots, login or UAC boundaries, and bounded or managed delegation to Codex inside the VM.
---

# Windows VM Control

Treat the Windows VM as another computer. Check its current state before you choose how to control it.

## System model

The Mac agent coordinates the work. The Windows VM is the target.

The Mac agent has four access paths:

| Access path | Use it for | A successful check proves |
| --- | --- | --- |
| VMware `vmrun` and VMware Tools | VM power, guest IP, and guest process launch | Fusion and Tools can reach this VM |
| SSH | Commands, files, Git, builds, tests, and background processes | The network, `sshd`, SSH trust, and one Windows account work |
| Fusion desktop | Visible apps, focus, login, dialogs, and screenshots | The visible Windows session did the action |
| Guest Codex | Longer Windows work that needs judgment | Guest Codex ran and returned text |

A check on one path proves only that path. An SSH result does not prove a visible desktop result. A screenshot does not prove that a background service is healthy. A guest Codex report still needs an independent check.

The system has stored state and live state.

Stored state remains across a restart. It includes the `.vmx` path, virtual disks, Windows identity, SSH host key, SSH alias, persistent user environment, and guest Codex configuration.

Live state can change at any time. It includes VM power, Tools readiness, guest IP, SSH reachability, desktop login, process environment, focus, and running commands.

The guest IP can change while the VM identity stays the same. A running Windows process keeps its old environment after a persistent environment value changes. Host files, guest files, user settings, Codex configuration, and desktop state are separate stores.

## Work sequence

1. Define the result. Name the access path that can prove it.
2. Run the read-only status check when access or identity may have changed. Run it with host access. A sandbox can block Fusion, Keychain, and the private VM network. Run bundled commands from the skill directory or use an absolute path:

   ```bash
   scripts/windows-vm-status
   ```

3. Classify a failure before you change state. Read [state-and-access.md](references/state-and-access.md).
4. Select the first applicable path in this order: direct SSH, deterministic PowerShell, bounded Codex, managed Codex, then VMware Tools or the Fusion desktop.
5. Use one writer for each checkout or process tree. The Mac agent keeps control of scope and final verification.
6. Check the result through the access path that owns it.
7. Remove temporary files and stop only task-owned temporary processes.

Escalate after one failed quoting attempt, nested or multiline logic, adaptive work, or about 30 seconds of host command composition. Do not keep composing a direct command after that point.

## Execution modes

Run each `scripts/...` recipe from the skill directory. Use the script's absolute path when your current directory is elsewhere.

| Path | Use it for | Canonical recipe | Stop or escalate when |
| --- | --- | --- | --- |
| Direct SSH | One or two exact commands | `ssh -o BatchMode=yes windows-vm whoami` | Quoting, multiline logic, or adaptation is needed |
| Deterministic PowerShell | Exact multi-statement work | `scripts/windows-vm-powershell /absolute/host/task.ps1` | The script is oversized, adaptive, or needs a guest prompt |
| Bounded Codex | One adaptive Windows outcome | `scripts/windows-codex-run --cwd 'C:\src\project' < /absolute/host/handoff.txt` | The task needs credentials, identity, destructive action, wider scope, or follow-up steering |
| Managed Codex | Live steering, interruption, or approval handling across turns | A tested `codex app-server --stdio` controller | No tested controller exists; use bounded Codex |
| VMware Tools or Fusion desktop | SSH recovery, boot, UAC, login, focus, visible apps, or screenshots | Read [configuration.md](references/configuration.md) or [desktop.md](references/desktop.md) | The action is not authorized, the prompt asks for identity, or visible evidence is not needed |

Read [delegation.md](references/delegation.md) for delegation rules.

## Failure map

Check boundaries from the outside to the inside.

1. The VM is stopped. Inspect Fusion state. Start the exact `.vmx` only when the task authorizes it.
2. Tools are unavailable. Windows may still be starting. This result says nothing about SSH yet.
3. The guest IP changed. Compare the live IP with the SSH route. Prove the SSH host key before you update the route.
4. TCP port 22 is unreachable. Check the VM network, firewall, and `sshd`. Compare the current Mac VMware address with the firewall rule's `RemoteAddress`.
5. The SSH host key does not match. Prove the VM identity through a trusted path. Do not delete the trusted key to hide the error.
6. SSH works but a command is missing. Check the SSH account and its process environment. The program may still exist in the visible desktop session.
7. A command works but the UI differs. Use the desktop path. Capture visible evidence.
8. A known UAC prompt appears for an authorized action. Check the publisher, program, and result. The Mac agent may approve it through Fusion when no credential is required.
9. Login, password, passkey, MFA, or identity consent appears. Stop. This boundary belongs to the user.

## Evidence rules

Use evidence that matches the claim.

- Use `vmrun list`, `checkToolsState`, or `getGuestIPAddress` for VM and Tools state.
- Use a short SSH or Tools command for Windows computer and user identity.
- Inspect the exact guest path after a file copy.
- Check the stored environment value. Then start a new process and check its effective value.
- Capture the desktop after a visible action.
- Record the process or session ID for long work. Confirm its final state.
- Check guest-agent claims against files, Git state, focused tests, process state, or the visible UI.

## Safety rules

- Keep passwords, tokens, private keys, and recovery data out of prompts, logs, arguments, screenshots, and repositories.
- Treat an IP address as a route. Treat an SSH host key as identity.
- Do not replace a trusted SSH key without separate identity evidence.
- Do not delete a VM, disk, snapshot, checkout, or broad directory without exact scope and approval.
- Do not run host and guest writers in the same checkout at the same time.
- Treat Windows as a persistent workstation. Inspect and preserve its existing tools, checkouts, dirty work, and processes.
- Set time limits for remote commands and guest-agent sessions.
- Use `windows-vm-powershell` for a normal exact script. Transfer a script only when it is too large for the helper or SSH recovery requires it.
- Do not claim visible desktop success from SSH evidence.

## References

- [configuration.md](references/configuration.md) covers the `vmrun` wrapper, local configuration, and Keychain use.
- [state-and-access.md](references/state-and-access.md) covers live status, SSH failures, file transfer, and stored Windows state.
- [ssh-bootstrap.md](references/ssh-bootstrap.md) covers first-time OpenSSH setup and its narrow firewall rule.
- [desktop.md](references/desktop.md) covers visible UI control, focus, login, and UAC.
- [delegation.md](references/delegation.md) covers guest Codex discovery, bounded delegation, and the managed-controller boundary.
