# Configure VMware control

Read this file for first-time VMware Fusion setup, VM discovery, VMware Tools
repair, or migration to another Mac. Read [ssh.md](ssh.md) for SSH setup and
repair.

## Configure the wrapper

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

The VM unlock entries are optional for an unencrypted VM. Store guest and VM
passwords in macOS Keychain under the configured account and service names. Do
not put them in JSON, shell history, prompts, or repositories. Set
`guest_login` to the account used by the signed-in Windows console.

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

Run Keychain-backed wrapper commands on the host, not in the sandbox.

## Validate or repair VMware access

```bash
scripts/windows-vmrun doctor
scripts/windows-vmrun list
scripts/windows-vmrun checkToolsState
```

If the VM is stopped, start it in the mode required by the task:

```bash
scripts/windows-vmrun start gui
scripts/windows-vmrun start nogui
```

Use `gui` when desktop work is expected. If several VMs exist, list or discover
their `.vmx` files and have the user choose. Do not guess.

## Move to another Mac

1. Install VMware Fusion and import or create the VM.
2. Install VMware Tools.
3. Configure `windows-vmrun` and Keychain credentials.
4. Validate VMware access.
5. Bootstrap SSH with [ssh.md](ssh.md).
6. Install Codex in Windows only when delegation requires it.
