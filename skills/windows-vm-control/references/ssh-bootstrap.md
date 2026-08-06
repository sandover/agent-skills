# SSH bootstrap

Use Windows OpenSSH Server as the normal command path. Installation, firewall changes, and authorized-key changes need task authorization.

## Resolve both addresses

Get the live guest address:

```bash
scripts/windows-vmrun getGuestIPAddress -wait
```

Get the Mac address on the same VMware network:

```bash
route -n get <GUEST_IP>
ipconfig getifaddr <INTERFACE>
```

Take `<INTERFACE>` from the route output.

The firewall rule should allow only this Mac address. It should not open SSH to the full Public network.

## Create one key and alias

Preserve the existing SSH configuration. Create the dedicated key only when it is absent:

```bash
install -d -m 700 ~/.ssh
ssh-keygen -t ed25519 -f ~/.ssh/windows-vm -N '' -C windows-vm
```

Use a stable alias:

```sshconfig
Host windows-vm
  HostName <GUEST_IP>
  User <WINDOWS_USER>
  IdentityFile ~/.ssh/windows-vm
  IdentitiesOnly yes
```

Probe before installation. An existing server may already work:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=10 \
  -o StrictHostKeyChecking=accept-new windows-vm \
  'powershell.exe -NoProfile -NonInteractive -Command "$env:COMPUTERNAME; whoami"'
```

Use `accept-new` only for a first identity enrollment through a route that you have already verified.

## Configure Windows

Run this PowerShell as an administrator. Replace all placeholders first:

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
Set-Service sshd -StartupType Automatic

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

`Get-LocalUser` needs the local account name. A Microsoft account display name or profile folder can differ from that name.

The VMware adapter may use the Windows Public profile. `Profile Any` avoids a profile mismatch. `RemoteAddress` keeps the rule narrow.

## Verify stored state

Run the normal SSH probe. Then check service and firewall state:

```powershell
Get-CimInstance Win32_Service -Filter "Name='sshd'" |
    Select-Object State, StartMode
Get-NetFirewallRule -Name OpenSSH-Server-In-TCP |
    Format-List Enabled, Profile, Direction, Action
Get-NetFirewallRule -Name OpenSSH-Server-In-TCP |
    Get-NetFirewallAddressFilter |
    Format-List RemoteAddress
```

Delete only the temporary setup script. Keep the key, alias, authorized key, service, and firewall rule.

The Mac VMware address can change after a network or VMware restart. When SSH times out, compare the current Mac address with the firewall rule's `RemoteAddress`.
