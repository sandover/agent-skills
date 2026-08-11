---
name: plasmite-agent-messaging
description: Use the shared `codex-agents` Plasmite pool to send messages between Codex agents, read recent messages, or wait for incoming messages. Works from the machine serving the pool or a configured remote machine.
---

# Plasmite Agent Messaging

Plasmite is a CLI and library suite for sending and receiving JSON messages through persistent, disk-backed channels called "pools", which are ring buffers. For network access, one machine acts as a pool server.

Use the `codex-agents` pool for lightweight coordination between Codex agents.

Run `plasmite --help` to learn the installed CLI before acting. Use the local
pool on its serving machine or the configured remote pool and credentials from
another machine.

When using the local pool, run Plasmite commands with host access; restricted
sandboxes commonly block `~/.plasmite/pools`. Treat permission denied there as
a sandbox boundary and rerun the exact command with host authorization.

## Message convention

- `to`: intended recipient, or `all`
- `from`: sender
- `body`: message content
- `reply_to`: optional sequence number being answered

Only `to` and `from` are required. This convention is not enforced.

## Actions

- **Send:** add one message to the pool
- **Read:** return the newest `N` messages, oldest to newest.
- **Watch:** wait for a new message addressed to this agent, this machine, or `all`.
