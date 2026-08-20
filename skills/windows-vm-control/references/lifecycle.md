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

## Make the configured VM available

Use judgment here. The configured VM may be running, paused or suspended, or powered off. `vmrun list` reports currently running VMs; absence from that list does not distinguish the other states. A user statement that the VM is paused or suspended is stronger evidence than an empty running list.

Check the configured VM:

```bash
scripts/windows-vmrun doctor
```

Launch Fusion without changing Mac focus and inspect running VMs when that check can answer the current question:

```bash
open -g -a 'VMware Fusion'
scripts/windows-vmrun list
```

If the VM is known to be paused or suspended, resume it rather than starting it. Use the user-reported state, Fusion state, or another check that actually distinguishes the states. If the user says they are resuming it, wait. Then check only the capability the task needs.

Start the VM without opening its window only when it is confirmed powered off, or when the user asked to start an unavailable VM and there is no indication that it was paused or suspended:

```bash
scripts/windows-vmrun start nogui
scripts/windows-vm-status --require ssh --wait 90
```

The wait retries temporary startup failures. It stops for invalid configuration or an SSH host-key error. `ssh=ok` shows that the route, SSH host key, Windows account, and test command worked. It does not show Tools or the signed-in Windows desktop. If a previously available VM disappears during readiness, do not start it again automatically; preserve the possibility of pause or suspend and surface the handoff. If SSH fails while the VM remains known running, use [access recovery](access-recovery.md).

## After restart or resume

Discard old addresses, SSH sessions, process IDs, and assumptions about earlier Windows Codex runs. Recheck only the method the task needs. A Windows desktop login is not required for SSH or Windows Codex.

Tools and SSH can recover at different times.

Do not repeat a change until a current file, process, or application check shows whether the earlier change completed.

## End the task

Leave the VM running. Ask before suspend or a normal Windows shutdown. Also ask before a hard stop, snapshot change, or Fusion shutdown.
