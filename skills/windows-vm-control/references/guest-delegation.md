# Delegate work to a guest Codex agent

Use this reference only after choosing bounded or managed delegation in
`SKILL.md`.

## Contents

- [Prepare the delegation](#prepare-the-delegation)
- [Run bounded delegation](#run-bounded-delegation)
- [Run managed delegation](#run-managed-delegation)
- [Recover managed state](#recover-managed-state)

## Prepare the delegation

Confirm that `codex` is available in the SSH environment:

```bash
ssh windows-vm 'codex --version'
```

Write a concise UTF-8 handoff:

- **Outcome:** State what the guest agent must accomplish.
- **Proof:** State the evidence that demonstrates completion.
- **Boundaries:** Name exclusions, the checkout to reuse, unrelated state to
  preserve, and conditions that require the host or user.
- **Authority:** State approved installs, Git operations, UI actions, and other
  effects.

Let the guest agent choose its implementation method. Require it to stop with a
clear blocker before a credential request, unexpected UAC prompt, consequential
ambiguity, or hard-to-reverse action exceeds its authority.

Keep visible desktop actions with the host agent. A guest agent launched through
SSH cannot control the signed-in desktop session.

## Run bounded delegation

Use bounded delegation for one self-contained outcome. The SSH process carries
the complete Codex turn, including its event stream and final response.

```bash
ssh -o ServerAliveInterval=30 windows-vm \
  'codex exec --json -C C:\src\project -m <MODEL> -c model_reasoning_effort=<EFFORT> -c service_tier=<TIER> -' \
  < handoff.txt | tee /tmp/windows-codex.jsonl
```

Ask the user for model, reasoning, or service-tier choices only when no
applicable choice is known. Add
`--dangerously-bypass-approvals-and-sandbox` only when the user authorized
maximum permissions for an isolated or disposable VM.

Save the session ID when follow-up is likely:

```bash
jq -r 'select(.type == "thread.started") | .thread_id' \
  /tmp/windows-codex.jsonl | head -1
```

Continue the same guest conversation:

```bash
ssh windows-vm \
  'codex exec resume <SESSION_ID> --json -' \
  < follow-up.txt | tee -a /tmp/windows-codex.jsonl
```

Monitor the JSONL until the turn ends. Treat tool results and the final guest
message as evidence; the host agent still decides whether proof is sufficient.

If the SSH environment cannot find `codex`, inspect that environment's PATH and
locate the explicit executable before changing the installation or mode.

## Run managed delegation

Use managed delegation only when a tested controller implements the exact
guest Codex app-server protocol. Otherwise use bounded delegation.

Run `codex app-server --stdio` through one persistent SSH connection. Generate
the schema from the exact guest build before relying on request shapes:

```bash
ssh windows-vm \
  'codex app-server generate-json-schema --out C:\Temp\codex-app-server-schema'
```

The controller must:

1. Start one task-owned `codex app-server --stdio` process through SSH.
2. Send `initialize`, then acknowledge with `initialized`.
3. Start or resume the exact intended thread.
4. Start work with `turn/start`.
5. Read every `turn/*` and `item/*` event.
6. Use `turn/steer` with the expected turn ID for guidance during an active
   turn.
7. Use `turn/start` for input after a completed turn.
8. Use `turn/interrupt` to stop an active turn.
9. Answer approval and user-input requests while continuing to read events.
10. Save the thread ID and stop only the task-owned app-server process.

Do not build app-server requests through ad hoc shell quoting. Use the default
stdio transport over SSH, and do not expose its experimental WebSocket listener
across the VM network.

Distinguish the connection, process, thread, turn, action, and visible UI:

| State | Evidence |
| --- | --- |
| SSH | The connection is open, or the controller recorded its loss. |
| App-server | The exact task-owned process is known. |
| Thread | A thread response returned the expected thread ID. |
| Turn | A turn event shows started, completed, failed, or interrupted state. |
| Action | An item event shows the command, edit, tool call, result, or pending decision. |
| Windows UI | Application state, UI Automation, or a fresh screenshot proves visible behavior. |

## Recover managed state

The stdio app-server process ends when its SSH connection ends. The Codex thread
remains on disk.

After a disconnect:

1. Start and initialize a new app-server process.
2. Read or resume the saved thread.
3. Determine whether the last turn and action completed.
4. Do not repeat an action that may already have changed state.

Use only authority already granted for the task when app-server requests an
approval or user input. Ask the user when a request exceeds that authority.
