# Managed Windows Codex delegation

Read this when starting, steering, resuming, answering requests from, or closing a managed Windows Codex session.

## Start with clear ownership

The controller starts one Codex thread in the SSH account. It does not attach to an arbitrary open Windows Codex UI or place the process on the signed-in desktop. If the user named an existing executor, use its established channel. Use [desktop work](desktop-work.md) for visible Windows actions.

Use the handoff fields from [Command work](command-work.md#delegate-one-outcome), adding a user-assisted UI checkpoint when appropriate. Never include secrets in handoffs, actions, events, or state files.

## Start or resume the controller

```bash
scripts/windows-codex-session \
  --cwd 'C:\src\project-proof' \
  --state /private/tmp/windows-session.json \
  --handoff /private/tmp/windows-handoff.txt
```

Run in a persistent execution session that keeps stdin writable. With an exec tool, retain its returned session ID and send newline-terminated actions using its stdin tool. Do not run in a mode that closes stdin immediately. Stdout carries app-server JSONL plus `controller/*` events; save it when needed for evidence or reconnect diagnosis.

The state file stores identifiers/lifecycle state, not prompts or command output. If it names an existing thread, the controller resumes that thread and reconciles its turn state. `--new` intentionally replaces local controller state with a new thread; it does not delete the old thread.

The helper waits for Codex readiness and checks the approved policy described in [command work](command-work.md#delegate-one-outcome). `--readiness-wait` changes the independent startup allowance. `--ssh` selects an authorized alias override.

## Steer, stop, and continue

Each controller action is one JSON line:

| Need | Action |
| --- | --- |
| Inspect lifecycle state | `{"action":"status"}` |
| Guide the active turn | `{"action":"steer","text":"Finish the build, then stop before desktop navigation."}` |
| Interrupt the active turn | `{"action":"interrupt"}` |
| Start follow-up after it ends | `{"action":"start","text":"The user opened the PDF. Read its identity without saving it."}` |
| Close after it ends | `{"action":"close"}` |

Steering uses the active turn ID as a precondition. The controller briefly retries an explicit startup-race rejection for that same turn; it never redirects the instruction to another turn or retries an uncertain response. `close` is rejected while a turn is active. After interrupting, wait for terminal turn state and reconcile any task-owned desktop automation before giving the user control. An interrupted turn can leave files or application effects behind.

## Answer requests

The controller emits the original request plus `controller/attentionRequired`. Inspect its method, request ID, and context. Answer ordinary choices from the authorized task. Ask the user only for missing information or authorization, and leave identity proof to them.

For a standard command approval, use the exact ID from the request:

```json
{"action":"respond","requestId":91,"result":{"decision":"accept"}}
```

Use `"decline"` to deny that command while allowing the turn to continue. For structured user input, use its question IDs:

```json
{"action":"respond","requestId":"question-1","result":{"answers":{"scope":{"answers":["Current deliverable only"]}}}}
```

For an unsupported request, return an error rather than inventing a response shape:

```json
{"action":"respond","requestId":92,"error":{"code":-32000,"message":"This controller cannot provide authentication tokens."}}
```

Stale or unknown IDs are rejected locally. For a new method, consult the installed app-server schema. Approval requests are uncommon on the configured Never profile, but still need contextual review.

## Know what finished

| Event/state | Interpretation |
| --- | --- |
| `controller/ready` | Thread started or resumed; read reconciled state. |
| `turn/started` | Assignment accepted. |
| `item/started`, `item/*/delta` | Work/progress; not terminal evidence. |
| `item/completed` | Item finished; inspect its result. |
| `turn/completed` | Turn ended with `completed`, `failed`, or `interrupted`. |
| `controller/attentionRequired` | A response is pending. |
| `controller/transportLost` | Connection ended without establishing the active turn's result. |

The state file uses `inProgress`, `waitingForApproval`, `waitingForInput`, `waitingForResponse`, terminal states, and `unknown`. Silence, a final sentence, or one successful command does not establish turn completion. Once the turn ends, evaluate the accumulated evidence against the requested product outcome.

## Reconnect without duplicating work

After transport loss, run the same controller command with the same state file and without `--new`. Wait for `controller/ready` with `resumed: true`, then request status. Let the guest inspect current Git/process state and prior results before deciding what to repeat. A durable thread can preserve context even when live output was lost; reconnecting alone does not undo previous effects.

When the assignment has ended and its state is reconciled, follow [VM lifecycle](lifecycle.md) to check for other owners and shut down gracefully when safe.

| Exit | Interpretation |
| --- | --- |
| `0` | Controller closed with no turn failure in this controller session; evaluate task evidence separately. |
| `2`, `64` | Invalid arguments or handoff. |
| `65` | State unreadable or belongs to another host/directory. |
| `69`, `70`, `71` | Missing helper, Codex not ready, or SSH transport could not start. |
| `73` | Local OS/file operation failed. |
| `75` | Protocol request or delegated turn failed. |
| `76` | Transport lost; starting/running turn is unknown. |
| `124` | Controller request deadline expired. |
| `130` | Delegated turn interrupted. |
