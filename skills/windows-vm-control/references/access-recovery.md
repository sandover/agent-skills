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

Run the [direct SSH probe](command-work.md#direct-ssh) first. If it succeeds, do not change the server, key, or firewall.

Get the VM address and the Mac interface on its route:

```bash
scripts/windows-vmrun getGuestIPAddress -wait
route -n get <GUEST_IP>
ipconfig getifaddr <INTERFACE>
```

Create one dedicated key only when it is absent, then add a stable `windows-vm` SSH alias:

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

Run the following as a Windows administrator after replacing the placeholders:

```powershell
$ErrorActionPreference = 'Stop'
$userName = '<LOCAL_WINDOWS_USER>'
$publicKey = '<PUBLIC_KEY>'
$hostAddress = '<MAC_VMWARE_ADDRESS>'

function Add-AuthorizedKey {
  param([string]$KeyFile, [string]$KeyText)
  $newFields = $KeyText.Trim() -split '\s+'
  if ($newFields.Count -lt 2) { throw 'invalid SSH public key' }
  $keyBody = $newFields[1]
  $existing = if (Test-Path -LiteralPath $KeyFile -PathType Leaf) {
    @(Get-Content -LiteralPath $KeyFile)
  } else {
    @()
  }
  $present = $existing | Where-Object {
    $fields = $_.Trim() -split '\s+'
    $fields -ccontains $keyBody
  }
  if (-not $present) {
    Add-Content -LiteralPath $KeyFile -Value $KeyText -Encoding ascii
  }
}

$capability = Get-WindowsCapability -Online |
  Where-Object Name -Like 'OpenSSH.Server*' | Select-Object -First 1
if ($capability.State -ne 'Installed') {
  Add-WindowsCapability -Online -Name $capability.Name | Out-Null
}
Start-Service sshd
Set-Service sshd -StartupType Automatic

$user = Get-LocalUser -Name $userName
$isAdmin = Get-LocalGroupMember -SID 'S-1-5-32-544' |
  Where-Object SID -EQ $user.SID
if ($isAdmin) {
  $keys = 'C:\ProgramData\ssh\administrators_authorized_keys'
  Add-AuthorizedKey -KeyFile $keys -KeyText $publicKey
  & icacls.exe $keys /inheritance:r `
    /grant '*S-1-5-18:F' /grant '*S-1-5-32-544:F' | Out-Null
} else {
  $directory = Join-Path (Join-Path 'C:\Users' $userName) '.ssh'
  $keys = Join-Path $directory 'authorized_keys'
  New-Item -ItemType Directory -Path $directory -Force | Out-Null
  Add-AuthorizedKey -KeyFile $keys -KeyText $publicKey
  & icacls.exe $directory /inheritance:r `
    /grant "*$($user.SID):(OI)(CI)F" | Out-Null
  & icacls.exe $keys /inheritance:r /grant "*$($user.SID):F" | Out-Null
}

$rule = Get-NetFirewallRule -Name OpenSSH-Server-In-TCP -ErrorAction SilentlyContinue
if ($rule) {
  Set-NetFirewallRule -Name OpenSSH-Server-In-TCP `
    -Enabled True -Profile Any -RemoteAddress $hostAddress
} else {
  New-NetFirewallRule -Name OpenSSH-Server-In-TCP `
    -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Profile Any `
    -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 `
    -RemoteAddress $hostAddress | Out-Null
}
```

`Add-AuthorizedKey` compares the key body, preserves every existing line, and appends the dedicated key only when absent.

Use the local account name, not a Microsoft account display name or profile directory. The VMware adapter can use the Public profile, so the rule uses `Profile Any` and limits `RemoteAddress` to the Mac.

Before storing the SSH host key, confirm the configured VM through Tools or the Fusion screen. Do not use `accept-new` before this check.

After comparing the fingerprints, store the SSH host key and verify SSH:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=10 \
  -o StrictHostKeyChecking=accept-new windows-vm \
  'powershell.exe -NoProfile -NonInteractive -Command "$env:COMPUTERNAME; whoami"'
scripts/windows-vm-status --require ssh
```

The Mac VMware address may change after sleep, restart, or a VMware network change. Compare it with the firewall rule before widening access.

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
