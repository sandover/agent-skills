# VM lifecycle

Check the capability needed by the task. Do not make every access method healthy before doing useful work.

```bash
scripts/windows-vm-status --require ssh
scripts/windows-vm-status --require codex
scripts/windows-vm-status --require vm,tools
```

A successful task command can replace a separate readiness probe. Use the combined `scripts/windows-vm-status` only when comparing methods helps diagnose a failure.

## Start or resume

The configured VM is the target. A running-list entry is useful positive evidence; absence does not distinguish paused, suspended, and powered-off states. Preserve a user report of pause or suspend until better evidence changes it. `doctor` checks configuration, not power state.

Launch Fusion in the background if needed:

```bash
open -g -a 'VMware Fusion'
scripts/windows-vmrun list
```

| Known state | Action when making the VM available is authorized |
| --- | --- |
| Running | Probe the needed capability; do not start again. |
| Paused | `scripts/windows-vmrun unpause` |
| Suspended | Resume the saved VM state. Fusion's **Virtual Machine → Resume** is the user-assisted route; `vmrun start` resumes a suspended VM. |
| Powered off | `scripts/windows-vmrun start nogui` |
| Unclear | Inspect Fusion's state or ask the user if a quick answer resolves it. Do not infer a cold boot from failed SSH. |
| User is resuming it | Wait for the handoff, then probe the required capability. |

For the command-line suspended-state route, use `scripts/windows-vmrun start nogui`. Despite the command's name, suspend recovery uses `start`; pause recovery uses `unpause`. Never discard saved state, remove lock files, or reset the VM to make this work. These distinctions follow VMware's [vmrun reference](https://www.manuallib.com/download/pdf1/VMWARE-USING-VMRUN-TO-CONTROL-VIRTUAL-MACHINES-VMWARE-WORKSTATION-7.0-VMWARE-FUSION-3.0-VMWARE-VSPHERE-4-VMWARE-SERVER-2.0.PDF) and [Fusion power options](https://knowledge.broadcom.com/external/article?legacyId=1018242).

After start/resume, allow a bounded warm-up:

```bash
scripts/windows-vm-status --require ssh --wait 30
```

Use `--require codex` if that is the next task. The delegation runners already wait for it. A timeout means this capability did not become ready within the allowance.

- If Windows is visibly booting/resuming or readiness is improving, allow another bounded wait that fits the task.
- If the VM is running with no progress, inspect the failed access method using [access recovery](access-recovery.md).
- If another trustworthy method can finish the task, use it.
- If the VM disappears or the user pauses it, stop attempts that could restart it and reconcile the state.

Do not reboot a running VM because SSH, Tools, or Codex is slow. After a cold restart, rediscover process IDs and sessions. After resume, verify live process/session identity before using cached handles. Recheck an address only when routing or connectivity makes it doubtful; persistent files and configuration survive both.

## Configuration and credentials

The wrapper reads `~/.config/windows-vm-control/config.json`; `WINDOWS_VM_CONTROL_CONFIG` selects another file. Inspect the existing configuration before creating one. `scripts/windows-vmrun config-path` prints the selected path.

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

Guest Operations uses the named macOS Keychain password; SSH uses its own configured key. VM unlock fields are optional for an unencrypted VM. Check only the required local setup:

```bash
scripts/windows-vmrun doctor
scripts/windows-vmrun doctor --require guest-ops
scripts/windows-vmrun doctor --require vm-unlock
```

A missing/inaccessible Keychain item is an access problem, not proof the password is wrong. Do not print the secret to diagnose it. `vmrun` accepts passwords as arguments, so another process owned by the Mac user may observe them during execution; keep credential handling inside the wrapper.

Leave the VM running when finished unless the user requested another state. Shutdown, suspend, reset, snapshot changes, and Fusion shutdown require authorization for those effects.
