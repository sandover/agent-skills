# Plasmite coordination protocol

## Purpose

Plasmite is the normal message channel between the macOS guide and the Windows
VM agent. It replaces repeated screen reading, clipboard collisions, and
synthetic typing with an efficient, observable trace of instructions,
progress, decisions, feedback, and results.

The Mac runs the Plasmite server. The VM agent reaches it through MCP. Use one
durable pool for the relationship and tags to route messages.

## Message envelopes

Guide hello:

```json
{
  "kind": "hello",
  "protocol": "windows-vm-guide/1",
  "nonce": "unique-nonce",
  "to": "vm-agent",
  "expected": {
    "model": "full-model-id",
    "reasoning": "selected-level",
    "speed": "selected-speed"
  }
}
```

VM-agent hello acknowledgement:

```json
{
  "kind": "hello_ack",
  "protocol": "windows-vm-guide/1",
  "nonce": "unique-nonce",
  "from": "vm-agent",
  "to": "guide",
  "session_id": null,
  "model": "full-model-id",
  "reasoning": "selected-level",
  "speed": "selected-speed",
  "received_seq": 123,
  "next_after_seq": 123,
  "stop_conditions_understood": true
}
```

Guide command:

```json
{
  "kind": "command",
  "id": "stable-command-id",
  "to": "vm-agent",
  "prompt": "Self-contained instruction"
}
```

VM-agent command acknowledgement:

```json
{
  "kind": "task_ack",
  "from": "vm-agent",
  "in_reply_to": "stable-command-id",
  "phase": "readiness-or-task",
  "definition_of_done": "One-sentence restatement",
  "boundaries": ["Concise exclusions"],
  "stop_conditions_understood": true
}
```

VM-agent status:

```json
{
  "kind": "status",
  "from": "vm-agent",
  "in_reply_to": "stable-command-id",
  "status": "Concise progress and next expected event"
}
```

VM-agent result:

```json
{
  "kind": "result",
  "from": "vm-agent",
  "in_reply_to": "stable-command-id",
  "result": {
    "outcome": "What happened",
    "evidence": [],
    "remaining": []
  }
}
```

Use tags such as `kind:hello`, `kind:hello_ack`, `kind:command`,
`kind:task_ack`, `to:vm-agent`, `to:guide`, `from:vm-agent`, and
`id:<stable-command-id>`. Use agent-specific route names when more than one VM
agent shares a server.

For a user decision, publish `kind:needs_user` with the question, evidence,
options, and consequences, then stop related work.

For workflow feedback, publish `kind:feedback` with structured answers.

## Cursor and polling conventions

- Record the pool's high-water sequence before launching or resuming Codex.
- Pass that sequence into the session as its initial cursor.
- Pipe the bootstrap prompt to `codex exec ... -`; do not put a long prompt in
  the Windows command line.
- Process only messages after the cursor and advance it monotonically.
- Never hard-code a sequence or replay an already handled command.
- While a task is active, the VM agent checks for new routed commands with
  bounded waits after each work cycle. Direct text input may pre-empt polling.
- A timeout with no message is normal. It is not a failure or a reason to spawn
  another shell.
- After restart, resume the same Codex session when sound and continue from the
  latest cursor.
- Avoid a bare host `follow` immediately after `feed`: the acknowledgement can
  arrive before the follower captures its starting high-water mark. Retain the
  sequence returned by `feed`, then fetch or replay messages after that known
  sequence until the matching nonce or command ID appears.

## Required phase sequence

### Connection handshake

1. Record the pool high-water sequence.
2. Launch exactly one owned VM agent after that cursor.
3. Send a side-effect-free `hello` with protocol version, nonce, expected
   identity, and requested model configuration.
4. Require `hello_ack` with the same nonce before sending any project or task
   instruction.
5. Verify the outbound route, session identity, actual model configuration,
   next cursor, and stop-condition acknowledgement.

Receiving `hello` proves only guide-to-agent delivery. The handshake is not
complete until the guide observes the matching `hello_ack`.

### Readiness

1. Send readiness as a separate command.
2. Require `task_ack` before the VM agent performs setup.
3. Let the VM agent establish its own repository and tool state.
4. Require a readiness result containing repository path, branch, HEAD,
   dirty-state summary, Git access, relevant tool versions, and gaps.
5. Resolve gaps before task instruction.

### Task instruction

1. Send the task, authority, exclusions, Definition of Done, evidence, cleanup,
   and midpoint-feedback requirement.
2. Require `task_ack` that restates the Definition of Done, boundaries, and
   stop conditions.
3. Begin task work only after acknowledgement.

The VM agent may not combine `hello_ack`, readiness work, and task execution
into one response.

## Trace quality

- Keep messages concise but self-contained.
- Send milestones, decisions, blockers, and results rather than every shell
  command.
- Include exact evidence paths, hashes, versions, branches, and commit IDs when
  they matter.
- Never send secrets.
- Treat delivery as different from completion: require a VM-agent result and
  relevant evidence.
- Preserve the stream as a useful record for the user and for improving the
  workflow.
