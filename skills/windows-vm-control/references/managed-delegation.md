# Managed Windows Codex delegation

Use a managed session when Windows Codex should own an assignment across turns or accept steering, interruption, approvals, or user input while it works. Use the bounded runner for one self-contained outcome.

## Contents

- [Ownership](#ownership)
- [Prepare the handoff](#prepare-the-handoff)
- [Start or resume](#start-or-resume)
- [Send actions](#send-actions)
- [Handle requests](#handle-requests)
- [Read the event stream](#read-the-event-stream)
- [Reconnect](#reconnect)
- [Exit results](#exit-results)

## Ownership

Windows Codex owns the delegated checkout and task. The Mac agent owns coordination, user communication, the controller, and host-only desktop support.

After delegation starts:

- Do not run independent commands or inspect changing files in the delegated checkout.
- Do not start a second Windows Codex for the same checkout.
- Answer a Windows Codex request or perform a specific desktop or UAC action that only the Mac can perform.
- Resume direct work only after the active turn ends and current Git and process state are known.

The app-server process runs in the SSH account. It does not control the signed-in Windows desktop. Use [desktop work](desktop-work.md) when visible Acrobat or Windows state matters.

## Prepare the handoff

Write a UTF-8 handoff file with only task-specific facts:

- **Outcome:** State the result Windows Codex must produce.
- **Work:** Name the repository, branch, and Ergo task IDs when relevant.
- **Proof:** Name the checks, artifacts, or observations required for completion.
- **Boundaries:** Name excluded paths, unrelated work to preserve, and stop conditions.
- **Authority:** Name approved Git changes, installs, builds, tests, and other effects.

Do not put passwords, tokens, or other secrets in the handoff, controller input, event log, or state file.

## Start or resume

Run the controller from the skill directory. Give it an explicit host state file. The state file contains identifiers and lifecycle state, not prompts or command output.

```bash
scripts/windows-codex-session \
  --cwd 'C:\Users\sando\src\gamma-gcp' \
  --state /private/tmp/claims-windows-session.json \
  --handoff /absolute/host/handoff.txt \
  | tee /private/tmp/claims-windows-events.jsonl
```

Keep the process active in a terminal or managed execution session. Controller stdin accepts one JSON action per line. Stdout contains the original app-server JSONL plus events whose method begins with `controller/`.

The controller uses the configured SSH alias unless `--ssh` overrides it. For agent-driven work, keep the controller in a managed execution session and send actions through that session's stdin. Save stdout when the event stream is needed as evidence.

If the state file already names a thread, the controller calls `thread/resume` and reconciles the returned turn state. Use `--new` only when a new thread is intentional. It replaces the local controller state but does not delete the previous Codex thread.

## Send actions

Start another turn after the current turn finishes:

```json
{"action":"start","text":"Inspect the failed check, fix the narrow cause, and rerun it."}
```

Add direction to the active turn:

```json
{"action":"steer","text":"Finish Ergo task ABC123 before starting ABC124."}
```

Steering includes the active turn ID as a precondition. App-server rejects the instruction if another turn is active.

Interrupt the active turn:

```json
{"action":"interrupt"}
```

Read the controller state:

```json
{"action":"status"}
```

Close only after the active turn ends:

```json
{"action":"close"}
```

The controller rejects `close` while a turn is active. Interrupt first when the work must stop.

## Handle requests

App-server can send approvals, questions, and other requests. The controller emits the original request and `controller/attentionRequired`. It records only the request ID and method in the state file.

Inspect the method and context before responding. Send the exact request ID and the result shape required by that method. On the standard VM, the approval policy is `Never`, so command approvals are uncommon.

Approve one command:

```json
{"action":"respond","requestId":91,"result":{"decision":"accept"}}
```

Decline one command while allowing the turn to continue:

```json
{"action":"respond","requestId":91,"result":{"decision":"decline"}}
```

Answer a structured question. Use the question IDs from the request:

```json
{"action":"respond","requestId":"question-1","result":{"answers":{"scope":{"answers":["Current deliverable only"]}}}}
```

Return a JSON-RPC error when the request cannot be answered safely:

```json
{"action":"respond","requestId":92,"error":{"code":-32000,"message":"This controller cannot provide authentication tokens."}}
```

Do not guess an unfamiliar response shape or put secrets in controller input. Generate the installed Windows Codex app-server schema or stop for the user. A response with a stale or unknown request ID is rejected locally.

## Read the event stream

The controller does not invent task progress from prose. App-server messages carry thread, turn, item, and request IDs; preserve them in the event log when later diagnosis may depend on them.

| Event | Meaning |
| --- | --- |
| `controller/ready` | The controller started or resumed the named thread. |
| `turn/started` | Codex accepted a turn and began work. |
| `item/started` | A command, file change, tool call, or message began. |
| `item/*/delta` | Partial progress for display or logging. |
| `item/completed` | Authoritative final state for that item. |
| `controller/attentionRequired` | An approval or input request needs a response. |
| `turn/completed` | Authoritative terminal turn status: `completed`, `failed`, or `interrupted`. |
| `controller/transportLost` | The connection ended without proving the active turn's result. |

Do not infer completion from silence, a final sentence, or a successful command. A successful command completes one item, not the assignment. Use the final `turn/completed` status and then verify the requested file, test, artifact, or visible behavior independently.

The state file uses these important turn states:

- `inProgress`: Codex owns the active turn.
- `waitingForApproval`, `waitingForInput`, or `waitingForResponse`: A server request is pending.
- `completed`, `failed`, or `interrupted`: App-server ended the turn.
- `unknown`: Transport ended while a turn was active. Success and failure are both unproven.

## Reconnect

Do not automatically repeat work after `controller/transportLost`. The prior turn may have changed files or started processes.

1. Run the same controller command with the same state file and without `--new`.
2. Wait for `controller/ready` with `resumed: true`.
3. Send `{"action":"status"}` and inspect the reconciled turn state.
4. Let Windows Codex inspect Git, processes, and prior test output before it decides whether to continue, repair, or repeat anything.

The Codex thread, not the SSH process, carries the durable context. Live deltas can be lost. The resumed thread and current Windows state are the basis for the model's recovery decision.

## Exit results

| Exit | Meaning |
| --- | --- |
| `0` | Controller closed without a turn failure in this controller session. |
| `2` | Command-line arguments were invalid. |
| `64` | The handoff was empty or invalid. |
| `65` | The state file was unreadable or belongs to another host or directory. |
| `69` | A required local helper was missing. |
| `70` | Windows Codex readiness failed. |
| `71` | SSH app-server transport could not start. |
| `73` | A local operating-system or file operation failed. |
| `75` | A protocol request or delegated turn failed. |
| `76` | Transport was lost. A turn being started or run is unknown. |
| `124` | App-server did not answer a controller request before its deadline. |
| `130` | The delegated turn was interrupted. |

A clean controller exit is not independent proof that the requested Windows or Acrobat behavior works.
