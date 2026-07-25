# Portable configuration

The skill must work on any Mac with VMware Fusion. Keep machine-specific,
non-secret values in a local JSON configuration file and passwords in macOS
Keychain.

By default, `scripts/windows-vmrun` reads:

```text
~/.config/windows-vm-control/config.json
```

Override that path with `WINDOWS_VM_CONTROL_CONFIG`.

Example:

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

`vm_keychain_account` and `vm_keychain_service` are optional when the VM is not
encrypted. Guest credentials are required only for commands that use VMware
Guest Operations.

Environment variables override JSON values:

- `WINDOWS_VMRUN_PATH`
- `WINDOWS_VM_VMX_PATH`
- `WINDOWS_VM_GUEST_LOGIN`
- `WINDOWS_VM_GUEST_KEYCHAIN_ACCOUNT`
- `WINDOWS_VM_GUEST_KEYCHAIN_SERVICE`
- `WINDOWS_VM_UNLOCK_KEYCHAIN_ACCOUNT`
- `WINDOWS_VM_UNLOCK_KEYCHAIN_SERVICE`

Use Keychain Access to create or update password items when interactive
authentication is appropriate. Do not put a password in JSON, shell history,
command arguments, a Codex prompt, or a Plasmite message.

For a new Mac:

1. Install VMware Fusion and create or import the Windows VM.
2. Install VMware Tools in the guest.
3. Locate `vmrun` and the VM's `.vmx` file.
4. Create the JSON configuration.
5. Store the guest password and optional VM unlock password in Keychain under
   the configured account and service names.
6. Run `scripts/windows-vmrun doctor`.
7. Continue with the lifecycle in `SKILL.md`.

Use `scripts/windows-vmrun list` to inspect running VMs before selecting one.
When several stopped VMs exist, discover `.vmx` files locally and have the user
choose; do not guess.
