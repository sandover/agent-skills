# Set up another Mac or VM

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
  "vm_keychain_service": "windows-vm-control:vm-unlock",
  "plasmite_pool": "codex-bridge",
  "plasmite_mcp_url": "http://<host-vmnet-address>:9700/mcp",
  "plasmite_token_file": "/Users/me/.config/plasmite/codex-bridge/token"
}
```

`vm_keychain_account` and `vm_keychain_service` are optional when the VM is not
encrypted. Guest credentials are required for VMware Guest Operations.
`windows-vmrun doctor` checks the complete direct-control setup and therefore
expects them.

Environment variables override JSON values:

- `WINDOWS_VMRUN_PATH`
- `WINDOWS_VM_VMX_PATH`
- `WINDOWS_VM_GUEST_LOGIN`
- `WINDOWS_VM_GUEST_KEYCHAIN_ACCOUNT`
- `WINDOWS_VM_GUEST_KEYCHAIN_SERVICE`
- `WINDOWS_VM_UNLOCK_KEYCHAIN_ACCOUNT`
- `WINDOWS_VM_UNLOCK_KEYCHAIN_SERVICE`

Use Keychain Access to create or update password items when the user can enter
the password directly. Do not put a password in JSON, shell history, a command
you type, a Codex prompt, or a Plasmite message. `vmrun` requires password
arguments, so `windows-vmrun` reads them from Keychain and passes them directly.
Never echo, log, or copy those values.

## Plasmite channel

Use one pool for the guide and VM agent. `codex-bridge` is the default pool
name. Record the pool name, MCP URL, and token-file path in the local
configuration.

On the host Mac:

1. Install Plasmite.
2. Create the pool.
3. Run `plasmite serve` with launchd as a persistent user service on the VMware
   host-only network address. Require a token file. The current proof-of-concept
   uses port `9700`.
4. Use TLS if the endpoint is reachable beyond the host-only VM network. Never
   expose an unauthenticated writable endpoint.

In Windows, configure the VM Codex MCP server to use
`http://<host-vmnet-address>:9700/mcp`. Supply its bearer token from the guest
environment or credential store, not from a prompt or repository.

Confirm the channel with a short `hello` and `ack`. This proves that the VM
agent can both read and write the pool.

## PowerShell and Codex

Reuse the VM's existing Codex authentication and installation method. If the
official PowerShell installer must update Codex, stop Codex and run the update
from a separate PowerShell process. Do not use the in-session update prompt or
add Winget only to perform the same update.

For a new Mac:

1. Install VMware Fusion and create or import the Windows VM.
2. Install VMware Tools in the guest.
3. Locate `vmrun` and the VM's `.vmx` file.
4. Create the JSON configuration.
5. Store the guest password and optional VM unlock password in Keychain under
   the configured account and service names.
6. Establish the Plasmite channel.
7. Run `scripts/windows-vmrun doctor`.
8. Continue with the fast path in `SKILL.md`.

Use `scripts/windows-vmrun list` to inspect running VMs before selecting one.
When several stopped VMs exist, discover `.vmx` files locally and have the user
choose; do not guess.
