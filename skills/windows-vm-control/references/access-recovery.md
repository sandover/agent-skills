# Access recovery

Find and recover the first failed check for the method you need. Tools and SSH are separate.

```text
Tools: Fusion -> VM -> Tools -> Guest Operations
SSH:   Fusion -> VM -> network -> route and SSH host key -> Windows account -> process
```

## Contents

- [Check current access](#check-current-access)
- [Interpret SSH failure](#interpret-ssh-failure)
- [Refresh a changed route](#refresh-a-changed-route)
- [Restore OpenSSH](#restore-openssh)
- [Check why the VM is slow](#check-why-the-vm-is-slow)

## Check current access

Use the narrowest check that can prove the method works:

```bash
scripts/windows-vm-status --require ssh
scripts/windows-vm-status --require codex
scripts/windows-vm-status --require vm,tools
```

If SSH fails or its route may be stale, run the combined check:

```bash
scripts/windows-vm-status
```

The script prints `key=value` status lines and makes no changes. Stop if `computer` or `user` names an unexpected Windows machine or account.

| Key | Possible values |
| --- | --- |
| `vm_power` | `running`, `stopped`, `unknown` |
| `tools` | `running`, `unavailable`, `unknown` |
| `route_match` | `yes`, `no`, `unknown`; DNS can produce `unknown` |
| `ssh` | `ok`, `timeout`, `refused`, `alias_unresolved`, `host_key_failed`, `authentication_failed`, `probe_failed`, `failed` |
| `codex_policy` | `ok`, `mismatch`, `failed`, `not_checked` |

## Interpret SSH failure

| SSH result | Meaning |
| --- | --- |
| Timeout | Route, VM network, firewall rule's allowed source address, or `sshd` reachability |
| Refused | No listener on the reachable address |
| Host-key failure | The observed SSH host key differs from the stored SSH host key |
| Permission denied | Authentication or account authorization |
| Alias unresolved | The configured SSH alias does not resolve to a host |
| Probe failed | SSH connected, but the expected Windows probe output was missing; check the OpenSSH default shell and PowerShell command |
| Failed | Read `ssh_error`; a missing command usually means the SSH process environment or executable path differs |

## Refresh a changed route

The VM address can change. The SSH host key identifies the VM.

1. Get the current VM address through Tools.
2. Get the VM host-key fingerprint from the Fusion screen or a VMware Tools command that uses the configured VM.
3. Scan the public key at the new address from the Mac.
4. Update the SSH alias only when the fingerprints match.
5. Recheck the Windows computer and user.

Do not disable strict host-key checking or delete a trusted key to suppress a mismatch.

Compare the trusted and observed fingerprints with:

```powershell
ssh-keygen.exe -lf C:\ProgramData\ssh\ssh_host_ed25519_key.pub
```

```bash
ssh-keyscan -t ed25519 <GUEST_IP> | ssh-keygen -lf -
```

## Restore OpenSSH

Ask before installing OpenSSH, changing the firewall, or changing `authorized_keys`.

Use the configured SSH alias and key. Create the dedicated key only when it is absent:

```bash
install -d -m 700 ~/.ssh
ssh-keygen -t ed25519 -f ~/.ssh/windows-vm -N '' -C windows-vm
```

```sshconfig
Host windows-vm
  HostName <GUEST_IP>
  User <LOCAL_WINDOWS_USER>
  IdentityFile ~/.ssh/windows-vm
  IdentitiesOnly yes
```

Restore the supported configuration through Guest Operations:

```bash
scripts/windows-vm-recover-ssh
```

The command makes no change when SSH already works. Otherwise, it derives the local Windows user and public key from the SSH alias, confirms that the alias names the configured VM address, derives the Mac address on that route, and restores OpenSSH. It preserves unrelated authorized keys and limits the firewall rule to the Mac address.

The command requires Guest Operations and an elevated Windows administrator token. Exit 77 means the configured Guest Operations account did not receive that token; stop for an administrator or UAC. Exit 76 means cleanup could not be confirmed. Exit 124 means the bounded recovery timed out.

On success, the JSON result includes the host-key fingerprint and the command verifies SSH. If recovery succeeds before the host key is trusted, compare that fingerprint with `ssh-keyscan` before storing the key. Never suppress a host-key mismatch.

## Check why the VM is slow

Run this check only when both SSH and Guest Operations are slow, or when a command starts and then stalls. Use `windows-vm-powershell`:

```powershell
$ErrorActionPreference = 'Stop'
[pscustomobject]@{
  disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" |
    Select-Object DeviceID, FreeSpace, Size
  memory = Get-CimInstance Win32_OperatingSystem |
    Select-Object LastBootUpTime, FreePhysicalMemory, TotalVisibleMemorySize
  defender = Get-MpComputerStatus -ErrorAction SilentlyContinue |
    Select-Object AMRunningMode, FullScanInProgress, QuickScanInProgress
  top_processes = Get-Process | Sort-Object CPU -Descending |
    Select-Object -First 10 ProcessName, Id, CPU, WorkingSet64
}
```

Report the measured disk, memory, Defender, and process values.
