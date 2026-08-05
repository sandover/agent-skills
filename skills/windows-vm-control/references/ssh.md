# Bootstrap and use SSH

Use Windows OpenSSH Server as the normal command plane. Use this reference for
first-time setup, access repair, direct commands, file transfer, and persistent
guest work.

## Contents

- [Bootstrap SSH](#bootstrap-ssh)
- [Classify connection failures](#classify-connection-failures)
- [Run direct commands](#run-direct-commands)
- [Run multiline PowerShell](#run-multiline-powershell)
- [Work in persistent guest state](#work-in-persistent-guest-state)

## Bootstrap SSH

Installing OpenSSH Server, changing the firewall, and adding an authorized key
change the guest. Obtain the user's authority for those changes. After
authorization, perform the setup; do not hand routine steps back to the user.

### 1. Resolve the guest and host addresses

Run Keychain-backed VMware commands on the host:

```bash
scripts/windows-vmrun getGuestIPAddress -wait
```

Find the Mac interface and address used for that VMware subnet:

```bash
route -n get <GUEST_IP>
ipconfig getifaddr <INTERFACE>
```

Retain both exact addresses. Restrict the Windows firewall rule to the Mac's
VMware address instead of exposing SSH to the whole Public network.

### 2. Create a dedicated key and host alias

Preserve any existing `~/.ssh/config`. Create a dedicated key only when it does
not already exist:

```bash
install -d -m 700 ~/.ssh
ssh-keygen -t ed25519 -f ~/.ssh/windows-vm -N '' -C windows-vm
```

Add or update this host entry:

```sshconfig
Host windows-vm
  HostName <GUEST_IP>
  User <WINDOWS_USER>
  IdentityFile ~/.ssh/windows-vm
  IdentitiesOnly yes
```

### 3. Probe before installing

```bash
ssh -o BatchMode=yes -o ConnectTimeout=10 \
  -o StrictHostKeyChecking=accept-new windows-vm \
  'powershell.exe -NoProfile -NonInteractive -Command "$env:COMPUTERNAME; whoami"'
```

If this succeeds, skip installation. If it times out, use Guest Operations to
inspect whether `sshd` exists, listens on port 22, and has a firewall rule whose
profile matches the active Windows network.

### 4. Install and configure OpenSSH

Create a temporary PowerShell script from this recipe. Substitute the exact
Windows user, public key, and Mac VMware address:

```powershell
$ErrorActionPreference = 'Stop'

$userName = '<WINDOWS_USER>'
$publicKey = '<PUBLIC_KEY>'
$hostAddress = '<HOST_VMWARE_IP>'

$capability = Get-WindowsCapability -Online |
    Where-Object Name -Like 'OpenSSH.Server*' |
    Select-Object -First 1

if ($capability.State -ne 'Installed') {
    Add-WindowsCapability -Online -Name $capability.Name | Out-Null
}

Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

$user = Get-LocalUser -Name $userName
$isAdministrator = Get-LocalGroupMember -SID 'S-1-5-32-544' |
    Where-Object SID -EQ $user.SID

if ($isAdministrator) {
    $authorizedKeys = 'C:\ProgramData\ssh\administrators_authorized_keys'
    Set-Content -LiteralPath $authorizedKeys -Value $publicKey -Encoding ascii
    & icacls.exe $authorizedKeys /inheritance:r `
        /grant '*S-1-5-18:F' /grant '*S-1-5-32-544:F' | Out-Null
} else {
    $sshDirectory = Join-Path (Join-Path 'C:\Users' $userName) '.ssh'
    $authorizedKeys = Join-Path $sshDirectory 'authorized_keys'
    New-Item -ItemType Directory -Path $sshDirectory -Force | Out-Null
    Set-Content -LiteralPath $authorizedKeys -Value $publicKey -Encoding ascii
    & icacls.exe $sshDirectory /inheritance:r `
        /grant "*$($user.SID):(OI)(CI)F" | Out-Null
    & icacls.exe $authorizedKeys /inheritance:r `
        /grant "*$($user.SID):F" | Out-Null
}

$firewallRule = Get-NetFirewallRule `
    -Name OpenSSH-Server-In-TCP -ErrorAction SilentlyContinue

if ($firewallRule) {
    Set-NetFirewallRule -Name OpenSSH-Server-In-TCP `
        -Enabled True -Profile Any -RemoteAddress $hostAddress
} else {
    New-NetFirewallRule -Name OpenSSH-Server-In-TCP `
        -DisplayName 'OpenSSH Server (sshd)' `
        -Enabled True -Profile Any -Direction Inbound `
        -Protocol TCP -Action Allow -LocalPort 22 `
        -RemoteAddress $hostAddress | Out-Null
}
```

Copy the script into the guest and launch it in the signed-in session through
`Start-Process -Verb RunAs`:

```bash
scripts/windows-vmrun copyFileFromHostToGuest \
  ./setup-windows-ssh.ps1 \
  'C:\Users\<WINDOWS_USER>\AppData\Local\Temp\setup-windows-ssh.ps1'

scripts/windows-vmrun runProgramInGuest \
  -noWait -activeWindow -interactive \
  'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' \
  -NoProfile -NonInteractive -Command \
  "Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File \"C:\Users\<WINDOWS_USER>\AppData\Local\Temp\setup-windows-ssh.ps1\"'"
```

Inspect the UAC prompt and approve it through host control of Fusion when it
matches this authorized PowerShell setup. Do not ask the user to click a known,
expected prompt.

The OpenSSH installer can create a Private-profile firewall rule while the
VMware adapter is classified Public. The recipe uses `Profile Any` but limits
the remote address to the Mac's VMware interface, which avoids that mismatch
without opening port 22 to the broader network.

### 5. Verify and clean up

Retry the noninteractive SSH probe. Then verify persistence through SSH:

```powershell
Get-Service sshd
Get-CimInstance Win32_Service -Filter "Name='sshd'" |
    Select-Object State, StartMode
Get-NetFirewallRule -Name OpenSSH-Server-In-TCP |
    Format-List Enabled, Profile, Direction, Action
Get-NetFirewallRule -Name OpenSSH-Server-In-TCP |
    Get-NetFirewallAddressFilter |
    Format-List RemoteAddress
```

Delete only the task-owned temporary setup and inspection scripts. Keep the
dedicated key, host alias, authorized key, service, and scoped firewall rule.

## Classify connection failures

| Result | Failed layer | Next action |
| --- | --- | --- |
| `Could not resolve hostname windows-vm` | Host alias | Add or repair the `Host windows-vm` entry. |
| Connection timeout | Address, listener, or firewall | Refresh the guest IP; inspect `sshd`, port 22, the active network category, and firewall profile. |
| Connection refused | Guest listener | Install or start `sshd`; verify its startup mode and listening address. |
| `Permission denied (publickey)` | Authentication | Confirm the SSH user, selected key, administrator status, authorized-key path, and ACLs. |
| Host-key warning after an expected VM replacement | Host identity | Verify the new guest identity before removing the exact stale `known_hosts` entry. |

SSH and Guest Operations can use different Windows users and environments. A
successful Guest Operations command does not prove SSH authentication.

## Run direct commands

Use noninteractive PowerShell:

```bash
ssh windows-vm \
  'powershell.exe -NoProfile -NonInteractive -Command "$PSVersionTable.PSVersion"'
```

Set `$ErrorActionPreference = 'Stop'` when a non-terminating PowerShell error
must fail the SSH command.

## Run multiline PowerShell

Write a `.ps1`, copy it, and run it instead of escaping a long program through
several shells:

```bash
scp ./task.ps1 windows-vm:task.ps1
ssh windows-vm \
  'powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\task.ps1'
```

Windows PowerShell 5.1 reads a BOM-less script as ANSI. Save scripts as UTF-8
with BOM. For non-ASCII output, begin with:

```powershell
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
```

Delete copied task scripts after use unless they remain useful guest artifacts.

## Work in persistent guest state

Treat Windows as a persistent workstation:

1. Inspect the existing path, repository, branch, dirty state, tools, and
   credentials.
2. Reuse a suitable checkout and installed tools.
3. Preserve unrelated files, branches, stashes, processes, and local changes.
4. Change setup only when the task requires it and the user authorized it.
5. Verify the resulting file, process, build, test, or repository state through
   SSH.

Use Guest Operations separately when a process must appear in the signed-in
desktop session. SSH success alone does not prove visible application behavior.
