---
name: codex-coordination
description: Coordinate multiple Codex instances across machines. Use when a machine needs to check for, discuss, decide, or act on work shared with another Codex instance.
---

# Codex coordination

Use the dedicated Google Chat `Codex Chat` space as the current shared record for communication between peer Codex instances and Brandon. Agents prefix their chat messages with their machine label, such as `[Air]` or `[Pro]`; Brandon's messages are unprefixed. Future machines may use another short label; right now there are only two.

The bundled helper only manages a local cursor for each machine label and reads Chat through `gog`. Message content stays in Chat.

The helper has two commands:

- `check` reads Chat and prints messages this Codex has not yet processed.
- `ack MESSAGE_RESOURCE` records that this Codex has processed through that message.

## Cursor

A cursor is this Codex instance's local checkpoint: the resource of the newest Chat message it has fully considered. It is not a shared read receipt, and it does not change Google Chat's read state.

`check` prints messages after the cursor without changing it. After completing an action or recording its outcome in Chat, use `ack` with the newest processed message resource to move the cursor. On a new machine, there is no cursor, so `check` prints the latest messages; choose the appropriate checkpoint only after reviewing them. If the cursor is older than the 50 messages `check` reads, it stops instead of replaying a partial history; inspect Chat and acknowledge a current checkpoint.

## Work naturally

Check Chat when the user asks, when reasonable, or when it could change the next action: when starting or resuming shared work that's shared with the peer, before work that affects the peer machine, etc. Do not poll it for unrelated local work.

After checking, use judgment:

- Carry out clear, safe, in-scope requests.
- Send a short update when another person or machine needs the result, location, decision, or next owner.
- Acknowledge messages only after their action is complete or their outcome is recorded in Chat.
- Escalate ambiguity, uncertainty, sensitive data, and consequential external actions to Brandon. Leave the message unacknowledged until resolved.

## Setup

1. Authenticate independently on each Mac. Do not copy OAuth tokens or credentials between machines.

   ```bash
   gog auth add <workspace-email> --services chat
   ```

The `check` command requires normal macOS Keychain access. If a restricted execution environment cannot read the token, rerun it through an approved local terminal context; do not fall back to browser polling.

## Transport

Use the helper and `gog` for reads. For an outbound update, use the Browser skill with the existing signed-in `Codex Chat` tab: verify the space, prefix the message with the machine label, and send it. Do not use the browser for polling.

The installed `gog` OAuth client can list Chat messages but cannot currently create them because Google requires a configured Google Chat app for that API call. Do not use `gog chat messages send` unless that configuration is added later.

```bash
scripts/codex-chat --account <workspace-email> --agent Air check
scripts/codex-chat --agent Air ack 'spaces/.../messages/...'
```

`check` does not advance the cursor. This prevents a message from being silently lost if its action fails or needs escalation.

`check` requires `--account EMAIL`, unless `GOG_CHAT_ACCOUNT` is set. `ack` only writes the local cursor, so it needs neither an account nor Keychain access.

## Safety

- Do not use Chat's `--unread` option. Air and Pro share a Google account, so its read state is not agent-specific.
- Prefix every agent-originated message with the selected agent name.
- Routine status, questions, and clear in-scope coordination may be sent without further confirmation. Ask before sending sensitive data or making consequential external changes.

## Commands

```text
codex-chat [--account EMAIL] [--agent LABEL] check
codex-chat [--account EMAIL] [--agent LABEL] ack MESSAGE_RESOURCE
```
