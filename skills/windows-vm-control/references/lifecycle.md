# VM lifecycle

Own the full task lifecycle: make the configured VM usable, do the work, then shut Windows down gracefully. The user's standing preference authorizes normal startup/resume and graceful shutdown for this workflow. Honor an explicit keep-running request. If Windows was already in use, establish that other users/agents and unsaved application work are safe before shutdown; ask only when that is unresolved. Record the initial state and any reason it must remain running.

## Start or resume only when needed

A successful task command proves its required capability. Otherwise use a narrow check:

```bash
scripts/windows-vm-status --require ssh
# Use --require codex for delegation; the delegation runners already check it.
```

If the host denies network/Fusion access, obtain the specific host tool permission and retry that check. `Operation not permitted` from the host is not evidence that Windows is off. Do not repair SSH or restart Windows for a host sandbox denial.

When the capability is unavailable, inspect the configured VM in Fusion and, when useful, its running list:

```bash
open -g -a 'VMware Fusion'
scripts/windows-vmrun list
```

A list entry proves the VM is running. Absence does not distinguish pause, suspend, and power-off. Use Fusion's **Virtual Machine** menu to distinguish those states. Verify the VM window matches the configured VM; preserve a user's report of pause/resume until new evidence resolves it.

| Observed state | Action |
| --- | --- |
| Running | Check the needed capability; do not start again. |
| Paused | `scripts/windows-vmrun unpause` |
| Suspended | Resume the saved state with Fusion's **Resume** action, or `scripts/windows-vmrun start nogui`. |
| Powered off | `scripts/windows-vmrun start nogui`; Fusion's **Start Up** action is the UI route. |
| Starting/resuming, including a user doing it | Wait for progress; do not issue competing power commands. |
| Unclear or conflicting evidence | Inspect Fusion's state and the configured VM's log before another power action. |

Run power commands in a tool session you can poll. A zero exit code alone does not prove startup: allow a bounded readiness check after the command returns:

```bash
scripts/windows-vm-status --require ssh --wait 30
```

If startup returns but Fusion still reports off and the VM is absent from the running list, use Fusion's **Start Up** once, then check readiness. On this installation, `start nogui` has returned zero with `Cannot determine message file path` / product-location messages without starting Windows; the UI route then worked. Do not repeatedly retry the same command. Inspect any actual warning: a missing installer ISO can leave only the virtual CD disconnected while Windows boots; it does not by itself justify changing disks or reinstalling Windows.

If boot/readiness is visibly progressing, allow another bounded wait. Otherwise diagnose the failed method in [access recovery](access-recovery.md), or use a working route. Do not require Tools and desktop access for command-only work. Do not reset, force-power-off, discard saved state, or remove locks to make startup work. If the user pauses Windows, stop attempts that could restart it.

## Sign in only when the task needs a desktop

SSH can work before Windows sign-in. For visible application work, inspect the screen and try the [desktop helper](desktop-work.md#inspect-the-windows-desktop). A missing interactive desktop (`72`) means the helper did not find the expected desktop process. Inspect the screen: ask for sign-in when it shows a sign-in prompt; otherwise diagnose that desktop/session without installing software or changing credentials.

Stop automated input and ask:

> Windows is ready for sign-in. Please enter your PIN in the Windows VM and leave it at the desktop; tell me when it is ready.

Never request the PIN in chat, type a stored password into the prompt, or enable automatic login. Bring the verified VM window forward using existing input consent when needed. After the user replies, verify the desktop with one narrow inspection and continue. After a restart, rediscover PIDs/window handles; after resume, verify their live identity before reuse.

## Shut down and verify

1. Finish or interrupt delegated work and reconcile its task processes. Preserve outputs and unsaved work. Resolve any other active owner before shutdown; a process list alone cannot establish that all work is safe to close.
2. Request an ordinary Windows shutdown:

   ```bash
   scripts/windows-vmrun stop soft
   ```

   Fusion's **Virtual Machine → Shut Down** is the UI route. **Power Off**, **Reset**, `stop hard`, and forced process termination are not graceful shutdown. Suspending or closing the Fusion window is not shutdown either.
3. Wait for the command and inspect completion. Fusion must report **Windows is off**, and `scripts/windows-vmrun list` must omit the configured VM. A disconnected SSH session or black screen alone does not prove shutdown. If a task requires headless verification, check the matching VM process and current VM log as additional evidence; never infer off solely from absence in the list.
4. If Windows shows unsaved-work, update, or shutdown-blocking prompts, preserve that state and resolve the specific blocker. Do not force-close apps or convert a slow shutdown into hard power-off. Report a still-running VM and the reason if safe shutdown cannot complete.

Before starting Windows again, complete the shutdown checks and wait for the configured VM's `vmware-vmx` process to exit. If it persists, inspect Fusion and the current VM log instead of issuing another power command. Do not wait for every `.lck` path to disappear; lock-file presence alone does not identify a running VM or a stale lock.

Leave Fusion itself open unless closing it is part of the user's request. Do not quit the application while another VM or owner is using it. Finish with the VM's verified final state and any blocker; do not silently leave it running.

## Lock errors: inspect before repair

Locks protect VM files against concurrent access. A `.lck` path alone does not establish a stale lock. In a live test, a `.vmx.lck` directory remained after successful shutdown while the disk lock disappeared; Windows subsequently started through Fusion without manually removing the remaining `.vmx.lck` directory. Do not promise that graceful shutdown fixes all lock errors.

If startup reports a lock error, stop repeated start attempts. Record the exact error and inspect only the configured VM's bundle, current `vmware.log`, Fusion state, and matching `vmware-vmx` process. Check for another owner, including another host if the bundle is shared. Do not kill all VMware processes or delete `.lck`, `.vmss`, `.vmem`, or disk files as routine cleanup.

Actual stale-lock repair is separate from normal startup/shutdown. Require evidence that no process/host owns the VM, identify the exact lock path, and obtain authorization for that repair. Preserve a recoverable copy if a repair is authorized. See Broadcom's [lock investigation](https://knowledge.broadcom.com/external/article/303398) and [Fusion power options](https://knowledge.broadcom.com/external/article/330650).

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
