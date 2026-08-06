# State and access

Use this guide when you first reach a VM. Use it again after suspend, restart, or a network change. Use it when two access paths disagree.

## Check live state

Run the read-only status script with the narrowest capability requirement:

```bash
scripts/windows-vm-status --require ssh
scripts/windows-vm-status --require codex
scripts/windows-vm-status --require vm,tools
```

An explicit `--require` list checks only those capabilities. SSH does not require VMware Tools. Guest Codex requires SSH, a working executable, and the approved effective policy. The default command checks `vm`, `tools`, and `ssh` for backward-compatible whole-target status.

The script reads the same local configuration as `windows-vmrun`. It reports VM power, Tools state, guest IP, SSH route, Windows identity, and guest Codex location. It does not change SSH configuration or trusted host keys.

Use `--vmx PATH`, `--vmrun PATH`, or `--ssh HOST` for a one-time override. Use `--no-ssh` before SSH setup. Read [configuration.md](configuration.md) for stored configuration.

## Read the result

The script emits `key=value` lines.

| Key | Values and meaning |
| --- | --- |
| `vm_power` | `running`, `stopped`, or `unknown` |
| `tools` | `running`, `unavailable`, or `unknown` |
| `guest_ip` | The Tools address or `unknown` |
| `ssh_route` | The SSH host route or `unknown` |
| `route_match` | `yes`, `no`, or `unknown`; a DNS route produces `unknown` |
| `ssh` | `ok`, `skipped`, `alias_unresolved`, `timeout`, `refused`, `host_key_failed`, `authentication_failed`, `probe_failed`, or `failed` |
| `computer`, `user` | Guest identity after `ssh=ok` |
| `codex_path`, `codex_version` | Guest values when `codex` is required |
| `codex` | `ok`, `failed`, or `not_found`; omitted when Codex is not required |
| `codex_policy` | `ok`, `mismatch`, `failed`, or `not_checked`; `ok` means the effective doctor result has no approvals and full filesystem and network access |
| `vmrun_error`, `tools_error`, `guest_ip_error` | A bounded diagnostic emitted only when the matching VMware check fails |

Exit 0 means that the requested checks succeeded. Exit 1 means that one requested capability is not ready. Read the keys to find the boundary. Exit 64 means invalid arguments. Exit 69 means a local tool is missing. Exit 73 means temporary-file creation failed. Exit 78 means configuration is missing or invalid.

The status check runs only the work needed for the requested capability. An SSH-only check does not discover or start Codex. `ssh=ok` does not prove VMware Tools, a visible desktop, or a Codex run. `codex_policy=mismatch` is an immediate configuration failure. Do not wait for it to recover or pass one-off policy overrides to bypass it.

An unexpected computer or user means that you reached the wrong target. Stop.

## Refresh an SSH route safely

An IP address can change. An SSH host key should remain stable.

1. Get the current guest IP through VMware Tools.
2. Get the VM SSH host-key fingerprint through a trusted path. The Windows console or a Tools command can provide this evidence.
3. Scan the public host key at the new IP from the Mac.
4. Compare the fingerprints.
5. Update the SSH alias route only when the fingerprints match.
6. Keep the stable SSH alias and trusted host identity.
7. Run the status script again. Check the Windows computer and user.

Do not use `StrictHostKeyChecking=no`. Do not delete a trusted host key as a shortcut.

Read [ssh-bootstrap.md](ssh-bootstrap.md) when OpenSSH Server is not installed or configured.

## Classify SSH failures

Each result points to a different boundary.

| Result | Boundary |
| --- | --- |
| Connection timeout | Route, VM network, firewall, or `sshd` reachability |
| Connection refused | The host is reachable, but no service listens on that port |
| Host-key mismatch | The endpoint identity differs from trusted state |
| Permission denied | The endpoint identity works, but authentication or authorization fails |
| Command not found | SSH works, but the process cannot find the program |

Use a short time limit during diagnosis:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 -o ConnectionAttempts=1 windows-vm whoami
```

## Understand Windows environments

Windows stores persistent user and machine environment values. Each running process has its own environment copy.

A persistent value change does not update Explorer, an open terminal, `sshd`, or a running agent.

Use this sequence for a user environment change:

1. Read the stored user value.
2. Change only the intended value.
3. Start a new process or restart the service that owns the process.
4. Read the new process value.
5. Check the dependent program.

Do not replace the machine PATH to fix a user PATH problem.

## Inspect guest Codex for another account

The status script reports `codex_path` for the SSH account. Use these commands only when you must inspect another account or diagnose the probe.

Ask that shell first:

```powershell
Get-Command codex -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
```

An SSH process may have a different PATH from an interactive terminal. Check the standalone release path next:

```powershell
Get-ChildItem "$env:USERPROFILE\.codex\packages\standalone\releases\*\bin\codex.exe" `
  -ErrorAction SilentlyContinue |
  Where-Object { -not $_.PSIsContainer } |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1 -ExpandProperty FullName
```

Use `Test-Path -LiteralPath <PATH> -PathType Leaf` for an exact file check. Then use an ordinary item inspection when you need metadata:

```powershell
$path = 'C:\Users\<USER>\AppData\Local\Temp\task.ps1'
if (!(Test-Path -LiteralPath $path -PathType Leaf)) { throw "not an exact file: $path" }
$item = Get-Item -LiteralPath $path
[pscustomobject]@{ Path = $item.FullName; Length = $item.Length; IsContainer = $item.PSIsContainer }
```

Do not depend on `Get-Item -File`; it is not available in every Windows PowerShell version. Do not search the full profile or disk recursively.

When the installed policy is intentional for the test VM, keep it in the guest Codex configuration as the one source of truth: `approval_policy = "never"` and `sandbox_mode = "danger-full-access"`. The runner verifies the effective policy and never adds command-line overrides. If the effective policy differs, stop and obtain approval for the exact guest user and configuration file before changing it.

## Recover after suspend or restart

Tools and SSH can recover at different times. Desktop login is not required for SSH or guest Codex. After a suspend, restart, network change, or unexpected disconnect:

1. Discard old PIDs, process assumptions, SSH sessions, and Codex session assumptions.
2. Run `scripts/windows-vm-status --require vm,tools` when VMware evidence is needed.
3. Run `scripts/windows-vm-status --require ssh` before reusing the SSH route.
4. Recheck the guest IP, SSH route, Windows computer, and user.
5. Recheck the Mac VMware address and the scoped Windows firewall `RemoteAddress` if SSH is slow or refused.
6. Run `scripts/windows-vm-status --require codex` immediately before a new bounded Codex run.

Do not resume a guest process by PID or repeat a write until the fresh checks show which action completed.

## Check resource pressure conditionally

Run a read-only resource check only after two independent access paths are slow, or after a command starts and stalls. Use the deterministic helper with a task-owned host script:

```bash
scripts/windows-vm-powershell --timeout 30 /absolute/host/resource-check.ps1
```

The script may inspect free space, CPU and memory pressure, restart markers, Defender activity, and the busiest processes:

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

Report the evidence and the suspected boundary. Do not kill unrelated processes, disable security, or change Windows Update state automatically.

## Copy and run a script

Use `scripts/windows-vm-powershell` for a small exact script. It is an executable transport helper, not a guest service. It uses the exact system Windows PowerShell path and creates no guest file:

```bash
scripts/windows-vm-powershell --timeout 30 /absolute/host/task.ps1
```

If `pwsh.exe`, a WindowsApps launcher, PATH lookup, quoting, or execution policy fails in a direct SSH or guest command, call the exact system path instead:

```powershell
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File C:\exact\task.ps1
```

Use explicit copy and execution only for an oversized exact script or recovery:

```bash
scp /absolute/host/script.ps1 'windows-vm:C:/Users/<USER>/AppData/Local/Temp/task.ps1'
ssh windows-vm 'C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File C:/Users/<USER>/AppData/Local/Temp/task.ps1'
```

Use one source and one exact destination in each `scp` command. Several `scp` sources require a directory destination. This difference can create the wrong path shape.

Check that the destination is an exact file after the copy:

```powershell
$path = 'C:\Users\<USER>\AppData\Local\Temp\task.ps1'
if (!(Test-Path -LiteralPath $path -PathType Leaf)) { throw "copy did not create the exact file: $path" }
$item = Get-Item -LiteralPath $path
if ($item.PSIsContainer) { throw "copy created a directory: $path" }
```

Windows PowerShell 5 treats a file without a byte-order mark as legacy text. Use UTF-8 with a byte-order mark when the script contains non-ASCII text. Set `$ErrorActionPreference = 'Stop'` when any PowerShell error must fail the remote command. Do not put secrets in the script or its command line.

Use an exact noninteractive cleanup command:

```powershell
cmd.exe /d /c del /f /q "C:\exact\temporary-file"
cmd.exe /d /c rmdir /s /q "C:\exact\temporary-directory"
```

Resolve and check the target first. Do not apply recursive cleanup to a profile, checkout root, drive root, or unresolved variable.
