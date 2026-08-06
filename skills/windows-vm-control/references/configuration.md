# Local configuration

The `windows-vmrun` wrapper keeps VM details in one host-side file. It gets guest and VM passwords from macOS Keychain.

The default file is:

```text
~/.config/windows-vm-control/config.json
```

`WINDOWS_VM_CONTROL_CONFIG` selects another file.

Use this shape:

```json
{
  "vmrun_path": "/Applications/VMware Fusion.app/Contents/Library/vmrun",
  "vmx_path": "/Users/me/Virtual Machines/Windows.vmwarevm/Windows.vmx",
  "ssh_alias": "windows-vm",
  "guest_login": "windows-user",
  "guest_keychain_account": "windows-user",
  "guest_keychain_service": "windows-vm-control:guest",
  "vm_keychain_account": "mac-user",
  "vm_keychain_service": "windows-vm-control:vm-unlock"
}
```

The `ssh_alias` field is optional. Its default is `windows-vm`. The VM unlock entries are optional for an unencrypted VM.

Store passwords in Keychain under the configured service and account. Do not put a password in JSON, a prompt, shell history, or a repository.

The wrapper retrieves a password from Keychain. VMware `vmrun` then requires that password in a process argument. Another local process may see the argument while `vmrun` runs. Run these commands on the trusted Mac host.

Environment values can override the file:

- `WINDOWS_VMRUN_PATH`
- `WINDOWS_VM_VMX_PATH`
- `WINDOWS_VM_SSH_ALIAS`
- `WINDOWS_VM_GUEST_LOGIN`
- `WINDOWS_VM_GUEST_KEYCHAIN_ACCOUNT`
- `WINDOWS_VM_GUEST_KEYCHAIN_SERVICE`
- `WINDOWS_VM_UNLOCK_KEYCHAIN_ACCOUNT`
- `WINDOWS_VM_UNLOCK_KEYCHAIN_SERVICE`

Check only the setup needed for the current path:

```bash
scripts/windows-vmrun doctor
scripts/windows-vmrun doctor --require guest-ops
scripts/windows-vmrun doctor --require vm-unlock
scripts/windows-vm-status --require ssh
scripts/windows-vm-status --require codex
scripts/windows-vm-powershell /absolute/host/task.ps1
scripts/windows-codex-run --cwd 'C:\src\project' < /absolute/host/handoff.txt
```

The base `doctor` check validates local `vmrun`, configuration, and the VMX path. Add `--require guest-ops` only for VMware guest-process or file operations. Add `--require vm-unlock` only when an encrypted VM must be unlocked. A Keychain error can mean that the item is missing or that the current process cannot access it. Key-based SSH does not use the guest Keychain credential.

Start a stopped VM only when the task authorizes it:

```bash
scripts/windows-vmrun start gui
scripts/windows-vmrun start nogui
```

Use `gui` when visible desktop work will follow. Do not guess when several `.vmx` files are available.

## End a session

Leave the VM running when later work needs the current processes. Use `suspend` when later work needs the current memory state. Use `stop soft` for a clean Windows shutdown. Do not use `stop hard`, revert a snapshot, or power off Fusion without explicit task authorization.
