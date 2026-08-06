---
name: windows-vm-control
description: Control and automate a VMware Fusion Windows VM from a host Mac Codex session. Use for Windows commands, files, Git, builds, tests, VM lifecycle, native Windows UI, screenshots, login or UAC boundaries, and delegation to Codex inside the VM.
---

# Windows VM Control

Treat Windows as a separate, persistent computer. Inspect its live state before acting.

Invoking this skill for VM work authorizes launching VMware Fusion in the background and starting the configured VM. Do not ask before this startup. This authority does not cover another VM, a hard stop, a snapshot change, or deletion.

## Operating model

The Mac agent coordinates the task. It can reach Windows through four paths:

| Access path | Use it for | It proves |
| --- | --- | --- |
| VMware `vmrun` and Tools | Power, guest address, guest processes | Fusion and Tools reached the configured VM |
| SSH | Commands, files, builds, tests, background work | The route, host key, SSH account, and command worked |
| Fusion desktop | Visible apps, dialogs, login, focus, screenshots | The visible Windows session performed the action |
| Guest Codex | Adaptive Windows work | Guest Codex returned a result |

Each path proves only its own state. Verify a guest Codex claim through the path that owns the result.

Stored identity and configuration survive restarts. Live power, Tools, address, route, process environment, desktop login, focus, and processes can change at any time. A new process is required to observe a changed persistent environment value. Host files, guest files, user settings, Codex configuration, and desktop state are separate stores.

## Workflow

1. Ensure Fusion and the configured VM are running. Read [configuration.md](references/configuration.md).
2. Run the narrow status check with host access. A sandbox can block Fusion, Keychain, or the private VM network:

   ```bash
   scripts/windows-vm-status --require ssh
   ```

3. Classify the failed boundary before changing state. Read [state-and-access.md](references/state-and-access.md).
4. Choose the first suitable execution mode below.
5. Keep one writer for each checkout or process tree.
6. Verify through the access path that owns the result.

Run bundled recipes from this skill directory or use their absolute paths.

| Mode | Use it for | Recipe | Escalate when |
| --- | --- | --- | --- |
| Direct SSH | One or two exact commands | `ssh -o BatchMode=yes windows-vm whoami` | Quoting, multiline logic, or adaptation appears |
| Deterministic PowerShell | Exact multi-statement work | `scripts/windows-vm-powershell /absolute/host/task.ps1` | The script becomes adaptive or needs judgment |
| Bounded Codex | One adaptive Windows outcome | `scripts/windows-codex-run --cwd 'C:\src\project' < /absolute/host/handoff.txt` | Credentials, identity, destructive work, wider scope, or live steering appears |
| Tools or Fusion desktop | SSH recovery, boot, UAC, login, visible apps, screenshots | Read [configuration.md](references/configuration.md) or [desktop.md](references/desktop.md) | Foreground Mac control or identity input is needed |

After one quoting failure, nested logic, or about 30 seconds of command composition, stop composing and move to PowerShell or bounded Codex.

## Boundaries

- Treat an address as a route and the SSH host key as identity. Prove identity before changing a trusted key.
- Preserve existing tools, checkouts, dirty work, and unrelated processes. Do not run host and guest writers in the same checkout.
- Ask before bringing an app to the Mac foreground, changing macOS focus, or moving or capturing the mouse. Background launch, screenshots, SSH, and Guest Operations do not need this permission.
- Stop for passwords, passkeys, multifactor authentication, identity consent, destructive actions, or scope expansion.
- Remove only task-owned temporary files and processes.
- Do not claim a visible desktop result from SSH evidence.

## References

- [configuration.md](references/configuration.md): local configuration, Keychain, startup, and shutdown.
- [state-and-access.md](references/state-and-access.md): status, SSH recovery, process context, and exact PowerShell work.
- [ssh-bootstrap.md](references/ssh-bootstrap.md): first-time OpenSSH installation, key enrollment, and firewall scope.
- [desktop.md](references/desktop.md): visible UI, focus permission, UAC, and screenshots.
- [delegation.md](references/delegation.md): bounded guest Codex and client drift.
