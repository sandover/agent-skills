# Local configuration

`windows-vmrun` reads the exact VM target and Keychain identifiers from:

```text
~/.config/windows-vm-control/config.json
```

`WINDOWS_VM_CONTROL_CONFIG` selects another file. Use this shape:

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

`ssh_alias` defaults to `windows-vm`. VM unlock fields are optional for an unencrypted VM.

Environment overrides are grouped by purpose:

- Target: `WINDOWS_VMRUN_PATH`, `WINDOWS_VM_VMX_PATH`, `WINDOWS_VM_SSH_ALIAS`, `WINDOWS_VM_GUEST_LOGIN`.
- Guest Operations credential: `WINDOWS_VM_GUEST_KEYCHAIN_ACCOUNT`, `WINDOWS_VM_GUEST_KEYCHAIN_SERVICE`.
- VM unlock credential: `WINDOWS_VM_UNLOCK_KEYCHAIN_ACCOUNT`, `WINDOWS_VM_UNLOCK_KEYCHAIN_SERVICE`.

Store passwords in Keychain, not JSON, prompts, history, or repositories. The wrapper passes a retrieved password to `vmrun` as a process argument. Another trusted local process can observe that argument while it runs.

Check only the capability needed for the chosen path:

```bash
scripts/windows-vmrun doctor
scripts/windows-vmrun doctor --require guest-ops
scripts/windows-vmrun doctor --require vm-unlock
scripts/windows-vm-status --require ssh
scripts/windows-vm-status --require codex
```

The base doctor checks `vmrun`, configuration, and the `.vmx` path. Require `guest-ops` for VMware guest files, processes, screenshots, or keystrokes and `vm-unlock` only for an encrypted VM. Key-based SSH does not require the guest password. A Keychain error can mean either a missing item or blocked access from the current process.

## Start the VM

Run startup commands with host access. Launch Fusion without taking focus, then list running VMs:

```bash
open -g -a 'VMware Fusion'
scripts/windows-vmrun list
```

If the configured `.vmx` is absent, start it without opening or raising its window:

```bash
scripts/windows-vmrun start nogui
scripts/windows-vm-status --require ssh --wait 90
```

The wait retries transient boot failures but stops immediately for a hard trust or policy failure. The wrapper supplies the configured `.vmx`; do not select another VM. Ask for foreground permission before opening its Fusion window.

## End a session

Leave the VM running. Ask before `suspend` or `stop soft`. A hard stop, snapshot revert, or Fusion shutdown also needs explicit authorization.
