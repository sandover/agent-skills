# Access recovery

Recover the method the task needs. A failed SSH connection is not a diagnosis of Windows power state. A successful SSH command remains useful when Tools is unavailable.

```text
Guest Operations: Fusion → configured VM → VMware Tools → guest credentials → operation
SSH: configured alias → route/address → listener/host key → account → command environment
```

## Locate the failure

Use a narrow live probe (`windows-vm-status --require ssh`, `--require codex`, or `--require vm,tools`). Use combined status when the contrast between methods will change the next action. Stop mutations if the reported computer or account is unexpected.

| Observation | Distinguishing check or next action |
| --- | --- |
| `ssh=timeout` | Confirm VM state, then compare configured address/route with Tools' address if available. A firewall source restriction or unreachable listener is also possible. |
| `ssh=refused` | Check that the address is the configured VM and whether `sshd` is listening there. |
| `ssh=host_key_failed` | Verify the key through the configured VM before editing trust. Failure can mean an unknown key as well as a changed key. |
| `ssh=authentication_failed` | Check the selected account and key; do not reinstall SSH to fix account authorization. |
| `ssh=alias_unresolved` | Inspect the alias/hostname configuration. |
| `ssh=probe_failed` | SSH connected but the Windows probe did not return expected output; inspect default shell/PowerShell behavior. |
| `ssh=failed` | Read `ssh_error`; distinguish client launch, connection, and command errors. |
| `codex_policy=mismatch` | The active Codex configuration differs from the runner's approved profile; see [command work](command-work.md#delegate-one-outcome). |
| Tools unavailable, SSH works | Continue over SSH if it can produce the result. |
| SSH works, desktop unavailable | Use [desktop work](desktop-work.md); signing in is unnecessary for command-only work. |

Status also reports `vm_power=running|not_running|unknown`, `tools=running|unavailable|unknown`, and `route_match=yes|no|unknown`. DNS can leave route comparison unknown. These are observations, not a requirement to repair every field.

## Address or host-key changes

Get the current address through the configured VM:

```bash
scripts/windows-vmrun getGuestIPAddress
```

Avoid adding `-wait` during diagnosis unless a bounded wait is intentional. Obtain the guest fingerprint through an independently trusted route, such as a Guest Operations command targeting that VM or its visible terminal:

```powershell
ssh-keygen.exe -lf C:\ProgramData\ssh\ssh_host_ed25519_key.pub
```

The public-key file may require an elevated Windows token even when Guest Operations works. If reading it returns permission denied, use an already-authorized elevated trusted route or ask the user to run this command in an elevated Windows terminal and return the fingerprint. Leave verification pending until that evidence is available; do not change file permissions or reinstall SSH just to read the fingerprint.

Compare with the key observed at the address from the Mac:

```bash
ssh-keyscan -t ed25519 GUEST_IP | ssh-keygen -lf -
```

`ssh-keyscan` alone does not establish trust. Change the alias/trust entry only within authorized access maintenance and after the fingerprints match. Then verify the Windows computer and user. Never disable strict host-key checking or delete a trusted key merely to suppress a mismatch.

## Restore OpenSSH

Installation, firewall changes, and authorized-key changes require authorization for access repair. If already authorized, proceed without another permission round. Otherwise explain the concrete repair first.

Reuse the configured SSH alias and key. If the dedicated key is absent and its creation is authorized:

```bash
install -d -m 700 ~/.ssh
ssh-keygen -t ed25519 -f ~/.ssh/windows-vm -N '' -C windows-vm
```

Never overwrite an existing private key. Example alias:

```sshconfig
Host windows-vm
  HostName GUEST_IP
  User LOCAL_WINDOWS_USER
  IdentityFile ~/.ssh/windows-vm
  IdentitiesOnly yes
```

Run the bundled repair through Guest Operations:

```bash
scripts/windows-vm-recover-ssh
```

It makes no changes when SSH works. Otherwise it checks that the alias targets the configured VM address, derives the account/public key and Mac route address, restores OpenSSH, preserves unrelated authorized keys, and restricts the firewall rule to that Mac address. It needs Guest Operations and an elevated Windows administrator token.

| Exit | Meaning |
| --- | --- |
| `77` | No elevated administrator token; the user or an authorized UAC step is needed. |
| `76` | Cleanup could not be confirmed; inspect reported leftovers. |
| `124` | Recovery timed out; inspect effects before retrying. |

On success it returns the host-key fingerprint and checks SSH. If the key is not yet trusted, compare that fingerprint with `ssh-keyscan` before storing it.

## Slow or inconsistent commands

If one process works and another fails, compare executable paths, non-secret configuration, and the environment of a new process. Check the endpoint actually used. Test authentication without printing credentials, then one read-only operation. Do not rotate credentials or widen network access to hide an environment difference.

If commands start but stall and resource pressure is plausible, use the PowerShell helper for the relevant measurement:

```powershell
Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" |
    Select-Object DeviceID, FreeSpace, Size
Get-CimInstance Win32_OperatingSystem |
    Select-Object LastBootUpTime, FreePhysicalMemory, TotalVisibleMemorySize
Get-Process | Sort-Object CPU -Descending |
    Select-Object -First 10 ProcessName, Id, CPU, WorkingSet64
```

CPU here is accumulated process time, not current utilization. Use a time-based measurement if deciding which process is currently consuming CPU. Gather only what distinguishes the suspected cause.
