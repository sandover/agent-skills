# VM lifecycle

## Configure the VM

`windows-vmrun` reads the configuration for one VM from `~/.config/windows-vm-control/config.json`:

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

`WINDOWS_VM_CONTROL_CONFIG` selects another file. The VM unlock fields are optional for an unencrypted VM.

Store the Windows password used by Guest Operations in the named macOS Keychain item. SSH does not use this password. VMware file, process, capture, and keystroke commands do.

`vmrun` accepts these passwords only as command arguments. Another process owned by the Mac user may observe them while `vmrun` is running.

Use `doctor --require guest-ops` before Guest Operations. Add `--require vm-unlock` only when VMware needs a password to open an encrypted VM. A Keychain failure can mean that the item is absent or that the current process cannot access it.

## Start the configured VM

Use this recipe when Fusion or the VM may be stopped. It does not authorize starting another VM or bringing Fusion to the front.

Check the configured VM:

```bash
scripts/windows-vmrun doctor
```

Launch Fusion without changing Mac focus and inspect running VMs:

```bash
open -g -a 'VMware Fusion'
scripts/windows-vmrun list
```

If the configured VM is absent, start it without opening its window and wait for SSH:

```bash
scripts/windows-vmrun start nogui
scripts/windows-vm-status --require ssh --wait 90
```

The wait retries temporary startup failures. It stops for invalid configuration or an SSH host-key error. `ssh=ok` shows that the route, SSH host key, Windows account, and test command worked. It does not show Tools or the signed-in Windows desktop. If SSH fails, use [access recovery](access-recovery.md).

## After restart or resume

Discard old addresses, SSH sessions, process IDs, and assumptions about earlier Windows Codex runs. Recheck only the method the task needs. A Windows desktop login is not required for SSH or Windows Codex.

Tools and SSH can recover at different times.

Do not repeat a change until a current file, process, or application check shows whether the earlier change completed.

## End the task

Leave the VM running. Ask before suspend or a normal Windows shutdown. Also ask before a hard stop, snapshot change, or Fusion shutdown.
