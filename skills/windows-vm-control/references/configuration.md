# Set up another Mac or VM

Read this file for first-time setup, after moving to another Mac, or when SSH or
VMware Guest Operations must be repaired.

## Configure VMware control

Install VMware Fusion and VMware Tools. Locate Fusion's `vmrun` executable and
the intended VM's `.vmx` file.

By default, `scripts/windows-vmrun` reads:

```text
~/.config/windows-vm-control/config.json
```

Override the path with `WINDOWS_VM_CONTROL_CONFIG`.

```json
{
  "vmrun_path": "/Applications/VMware Fusion.app/Contents/Library/vmrun",
  "vmx_path": "/Users/me/Virtual Machines/Windows.vmwarevm/Windows.vmx",
  "guest_login": "windows-user",
  "guest_keychain_account": "windows-user",
  "guest_keychain_service": "windows-vm-control:guest",
  "vm_keychain_account": "mac-user",
  "vm_keychain_service": "windows-vm-control:vm-unlock"
}
```

The VM unlock entries are optional when the VM is not encrypted. Store guest
and VM passwords in macOS Keychain under the configured account and service
names. Do not put them in JSON, shell history, prompts, or repositories.
Set `guest_login` to the account used for the signed-in Windows console when
interactive Guest Operations must create visible processes.

The wrapper retrieves passwords from Keychain, but `vmrun` requires them in its
process arguments. Other local processes may be able to observe those arguments
while the command runs.

Environment variables override JSON values:

- `WINDOWS_VMRUN_PATH`
- `WINDOWS_VM_VMX_PATH`
- `WINDOWS_VM_GUEST_LOGIN`
- `WINDOWS_VM_GUEST_KEYCHAIN_ACCOUNT`
- `WINDOWS_VM_GUEST_KEYCHAIN_SERVICE`
- `WINDOWS_VM_UNLOCK_KEYCHAIN_ACCOUNT`
- `WINDOWS_VM_UNLOCK_KEYCHAIN_SERVICE`

Validate the setup:

```bash
scripts/windows-vmrun doctor
scripts/windows-vmrun list
scripts/windows-vmrun checkToolsState
```

## Configure SSH

Use Windows OpenSSH Server as the normal command plane. Installing it and
opening its firewall rule changes the guest and requires the user's authority.

From an elevated PowerShell session in Windows:

```powershell
Get-WindowsCapability -Online |
  Where-Object Name -Like 'OpenSSH.Server*'
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
if (!(Get-NetFirewallRule -Name OpenSSH-Server-In-TCP -ErrorAction SilentlyContinue)) {
  New-NetFirewallRule -Name OpenSSH-Server-In-TCP `
    -DisplayName 'OpenSSH Server (sshd)' -Enabled True `
    -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
}
```

Prefer public-key authentication. A normal account uses
`$HOME\.ssh\authorized_keys`. An administrator account instead uses
`C:\ProgramData\ssh\administrators_authorized_keys`; grant access only to
`SYSTEM` and the built-in Administrators group as required by Windows OpenSSH.

Create a host alias in `~/.ssh/config`:

```sshconfig
Host windows-vm
  HostName 192.168.0.10
  User windows-user
  IdentityFile ~/.ssh/windows-vm
  IdentitiesOnly yes
```

Use the guest's current address from:

```bash
scripts/windows-vmrun getGuestIPAddress -wait
```

Use a stable host-only address or a deliberate Fusion port forwarding rule when
the VM address changes frequently. Do not expose SSH beyond the intended host
network without an explicit security decision.

Confirm noninteractive access:

```bash
ssh -o BatchMode=yes windows-vm \
  'powershell.exe -NoProfile -NonInteractive -Command "$env:COMPUTERNAME; whoami"'
```

An SSH session is not the signed-in Windows desktop and cannot answer UAC.
Launch visible processes through `runProgramInGuest -activeWindow -interactive`
when the task requires the desktop session.

## Optional guest agent

Install Codex in Windows only when a task benefits from delegated reasoning.
Reuse the guest's normal authentication and installation method.

## Optional Plasmite channel

Plasmite is optional and serves only as the message stream between the host and
detached guest agent. Run the server on the Mac, bind it only to an appropriate
interface, require a token, and configure the guest Codex MCP connection from a
guest credential store. Keep the pool name intelligible; `codex-bridge` is the
usual default.

Do not install or operate Plasmite for direct SSH, attached `codex exec`, or
ordinary `vmrun` control.

## Move to another Mac

1. Install VMware Fusion and import or create the VM.
2. Install VMware Tools.
3. Configure `windows-vmrun` and Keychain credentials.
4. Configure the SSH alias and key.
5. Run `scripts/windows-vmrun doctor`.
6. Confirm noninteractive SSH.
7. Add Codex only when a task requires delegation.
8. Add Plasmite only when detached delegation requires a message channel.

If several VMs exist, list or discover their `.vmx` files and have the user
choose. Do not guess.
