# State and access

Use this guide to establish current access, recover a failed path, or resolve disagreement between paths.

## Contents

- [Check live state](#check-live-state)
- [Restore access](#restore-access)
  - [Refresh a changed route](#refresh-a-changed-route)
  - [Classify SSH failure](#classify-ssh-failure)
  - [Recover after restart or resume](#recover-after-restart-or-resume)
- [Validate process context](#validate-process-context)
- [Run exact Windows work](#run-exact-windows-work)
- [Diagnose a slow target](#diagnose-a-slow-target)

## Check live state

Run the narrowest required check with host access:

```bash
scripts/windows-vm-status --require ssh
scripts/windows-vm-status --require codex
scripts/windows-vm-status --require vm,tools
```

SSH does not require Tools. Codex requires SSH, an executable, and approved effective policy. With no explicit requirement, the script checks `vm`, `tools`, and `ssh`. Use `--no-ssh` before SSH setup and read [configuration.md](configuration.md) for persistent target configuration.

The script prints `key=value` lines and changes no state. `route_match=unknown` can mean the SSH alias uses DNS. An SSH-only check does not discover Codex. `ssh=ok` does not prove Tools or the visible desktop.

| Key | Values that affect the next action |
| --- | --- |
| `vm_power` | `running`, `stopped`, `unknown` |
| `tools` | `running`, `unavailable`, `unknown` |
| `route_match` | `yes`, `no`, `unknown`; DNS produces `unknown` |
| `ssh` | `ok`, `timeout`, `refused`, `alias_unresolved`, `host_key_failed`, `authentication_failed`, `probe_failed`, `failed` |
| `codex` | `ok`, `failed`, `not_found` |
| `codex_policy` | `ok`, `mismatch`, `failed`, `not_checked` |

Exit 0 means all requested capabilities are ready; exit 1 means at least one is not. Exit 64 means invalid arguments, 69 means a missing local tool, 73 means temporary-file creation failed, and 78 means invalid or missing configuration.

The SSH-only fast check leaves VM, Tools, and guest-address fields unknown. If SSH fails or route drift is possible, run `scripts/windows-vm-status` without `--require` to collect VM, Tools, address, route, and SSH evidence together.

Stop on an unexpected `computer` or `user`. Treat `codex_policy=mismatch` as a configuration failure; do not bypass it with command-line overrides.

## Restore access

### Refresh a changed route

The guest address can change. The SSH host key should remain stable.

1. Get the current address through Tools.
2. Get the VM host-key fingerprint through the Windows console or another trusted path.
3. Scan the public key at the new address from the Mac.
4. Compare fingerprints.
5. Update only the SSH alias route when they match.
6. Recheck the Windows computer and user through SSH.

Do not disable strict host-key checking or delete the trusted key to hide a mismatch. Read [ssh-bootstrap.md](ssh-bootstrap.md) when OpenSSH is absent.

### Classify SSH failure

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 -o ConnectionAttempts=1 windows-vm whoami
```

| Result | Boundary |
| --- | --- |
| Timeout | Route, VM network, firewall scope, or `sshd` reachability |
| Refused | No listener on the reachable address |
| Host-key failure | Endpoint identity differs from trusted state |
| Permission denied | Authentication or account authorization |
| Command not found | SSH process environment or executable path |

### Recover after restart or resume

Discard old addresses, SSH sessions, process IDs, and Codex-session assumptions. Recheck only the needed paths. Confirm the guest address, SSH route, Windows computer, and user. If SSH is slow or refused, compare the current Mac VMware address with the firewall rule's `RemoteAddress`. Check Codex immediately before a new bounded run.

SSH and guest Codex do not require a desktop login. Tools and SSH can recover at different times. Do not repeat a write until fresh evidence shows whether it completed.

## Validate process context

A persistent user or machine environment change does not update Explorer, an open terminal, `sshd`, or another running process. Start a new process or restart the owning service, then check the value there. Do not replace machine PATH to fix one user's PATH.

Use the Codex path reported by `windows-vm-status --require codex`. For manual diagnosis, ask the SSH shell first:

```powershell
Get-Command codex -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
```

If PATH lookup fails, check the standalone release directory without searching the full profile or disk:

```powershell
Get-ChildItem "$env:USERPROFILE\.codex\packages\standalone\releases\*\bin\codex.exe" `
  -ErrorAction SilentlyContinue |
  Where-Object { -not $_.PSIsContainer } |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1 -ExpandProperty FullName
```

Check the exact file with `Test-Path -LiteralPath <PATH> -PathType Leaf`, then run its version command. `Get-Item -File` is unavailable in some Windows PowerShell versions.

Keep approved guest policy in the guest Codex configuration. The runner verifies it and does not maintain another policy source.

## Run exact Windows work

Use the helper for exact multi-statement PowerShell. It uses the system Windows PowerShell and creates no guest file:

```bash
scripts/windows-vm-powershell --timeout 30 /absolute/host/task.ps1
```

If `pwsh.exe`, a WindowsApps alias, PATH lookup, quoting, or execution policy fails, call the exact system executable:

```powershell
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File C:\exact\task.ps1
```

Transfer a script only when it is too large for the helper or SSH recovery needs a guest file:

```bash
scp /absolute/host/script.ps1 'windows-vm:C:/Users/<USER>/AppData/Local/Temp/task.ps1'
ssh windows-vm 'C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File C:/Users/<USER>/AppData/Local/Temp/task.ps1'
```

Use one source and one exact destination. Multiple `scp` sources require a directory destination and can create an unexpected path shape. Verify the result is a file:

```powershell
$path = 'C:\Users\<USER>\AppData\Local\Temp\task.ps1'
if (!(Test-Path -LiteralPath $path -PathType Leaf)) { throw "not an exact file: $path" }
```

Windows PowerShell 5 can read UTF-8 without a byte-order mark as legacy text. Use UTF-8 with a byte-order mark for non-ASCII scripts. Set `$ErrorActionPreference = 'Stop'` when any error must fail the task. Keep secrets out of scripts and command lines.

Resolve and check any cleanup target. Do not recursively remove a profile, checkout root, drive root, or unresolved variable.

## Diagnose a slow target

Check resources only after two access paths are slow or a started command stalls. Run this read-only body through `windows-vm-powershell`:

```powershell
$ErrorActionPreference = 'Stop'
[pscustomobject]@{
  disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" |
    Select-Object DeviceID, FreeSpace, Size
  memory = Get-CimInstance Win32_OperatingSystem |
    Select-Object LastBootUpTime, FreePhysicalMemory, TotalVisibleMemorySize
  pending_reboot = (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') -or
    (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired')
  defender = Get-MpComputerStatus -ErrorAction SilentlyContinue |
    Select-Object AMRunningMode, RealTimeProtectionEnabled, FullScanInProgress, QuickScanInProgress
  top_processes = Get-Process | Sort-Object CPU -Descending |
    Select-Object -First 10 ProcessName, Id, CPU, WorkingSet64
}
```

Report the evidence and suspected boundary. Do not kill unrelated processes, disable security, or change Windows Update automatically.
