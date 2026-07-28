---
name: windows-vm-control
description: Communicate with and delegate tasks to a fellow Codex agent in a VMware Fusion Windows VM. Use for Windows administration, project setup, software development and testing, authentication, repository work, VMware Fusion management, Windows interface observation, and User Account Control.
---

# Windows VM peer-agent guide

## Roles

- **Guide**: this is you, the agent on the host Mac. You own delegation, user communication, and
  access to the VM.
- **VM agent**: the Codex instance inside the VM. It owns the VM, its repositories,
  and work performed there.

Treat the VM agent as a capable peer on a persistent workstation, not as a
remote shell. Delegate outcomes and let it solve problems itself. There is a simple message channel where the two of you can communicate.

As guide, you can inspect or control VMware Fusion via Computer Use, osascript, or VMWare Guest Operations when that will unblock or materially accelerate the VM agent, for example, clicking through a UAC prompt. The user retains decisions about
credentials, permissions, serious ambiguity, and hard-to-reverse actions.

## Typical flow

- Connect to the VM
- Start or ensure the agent
- Handshake with it
- Delegate a task
- Collaborate
- Verify
- Close

These are landmarks, not mandatory gates. Combine or skip them as makes sense.

## Communication

Plasmite is a CLI and library for sending and receiving JSON messages through persistent, disk-backed channels called "pools", which are ring buffers. For IPC across machine boundaries, `plasmite serve` exposes local pools securely and runs an MCP server.

Use a Plasmite pool as your communication channel with the VM agent. The user can observe this channel via `plasmite follow {poolname}`. By convention create and use the pool "codex-bridge" but another pool could be created if necessary.

You use the plasmite CLI installed on the host machine; if it's missing, let the user know. "plasmite serve" should be running on this machine as a persistent launchd service. The VM agent connects via MCP.

### Commands

#### Create the pool
`plasmite pool create codex-bridge`

#### Send a message 
`plasmite feed codex-bridge --tag host-guide '{"msg":"Hello. Reply here when ready."}'`

#### Read recent context and continue watching
`plasmite follow codex-bridge --tail 5`

#### Wait for one new message but time out after a minute
`plasmite follow codex-bridge --timeout 60s --format jsonl`

- Sign your messages with a tag so provenance is clear.
- Don't invent schema; keep things simple, cheap, cheerful and fast. 
- Read all message traffic, don't filter.
- Metadata is optional, not a protocol.
- For a new or uncertain session, send a brief hello and expect an acknowledgment
  through Plasmite as proof of live connection. Include the launcher-selected
  model settings in the hello.
- Keep idle waiting cheap and quiet. Resume promptly after an empty wait.
- Treat a polling timeout as normal. Do not start another shell because of one.

Use `scripts/windows-vmrun` to establish access or help with the VM directly.
Read [configuration.md](references/configuration.md) for first-time setup or a
new host or VM.

## VM agent working model

The VM agent is interactive, not a background service. It can receive a new
Plasmite message only while a Codex turn is active and checking the pool.

Treat one open assignment as one continuing turn:

1. Read and acknowledge the handoff.
2. Work independently and report meaningful progress.
3. If the assignment is still open, wait for another Plasmite message. After a
   timeout, wait again.
4. Before ending the turn, send a result or blocker through Plasmite.

No new message is not a reason to end the turn. End it only when the assignment
is complete, the guide must involve the user, or the guide says to stop.

## Brief the VM agent

When starting or materially redirecting the VM agent, make sure it understands
its context and its tasks. If its existing conversation has the relevant context, you can leverage that.

Use this compact handoff:

- **Outcome:** State what the VM agent must accomplish.
- **Proof:** State the evidence that will show completion.
- **Boundaries:** State the important exclusions and stop conditions.
- **Authority:** State which installs, Git changes, UI actions, and other
  effects are already authorized.

Include only task-specific facts. Let the VM agent choose the method.

Tell the VM agent that it should do all the following:

- Own its task end to end. It can use its judgment and do the Git, setup, build,
  install, debug, test, and evidence work inside the VM.
- Follow the working model above for the life of the assignment.
- BEFORE knowingly triggering an approval, UAC, login, or other permission
  prompt, notify you (the guide) with a plasmite message so a quiet channel is not mistaken for a stalled agent.
- Put related, low-risk checks in one command when this reduces interruptions.
- Use the narrowest check that can answer the current question. Do not run a
  broad search when a bounded check can distinguish the likely causes.
- Stop and ask you (the guide) when credentials, permission, consequential ambiguity,
  or a hard-to-reverse decision requires the user.
- Keep secrets out of messages. 

## Choose your control path

In general, use `windows-vmrun` to establish, inspect, repair, or stop the VM agent. Use
Plasmite to communicate with a running VM agent.

| Current state | Action |
| --- | --- |
| No PowerShell and no Codex | Use `windows-vmrun runProgramInGuest` to start one interactive PowerShell/Codex tree. Then handshake through Plasmite. |
| PowerShell with a responsive Codex | Communicate through Plasmite. Do not launch or type into PowerShell. |
| PowerShell with Codex but no Plasmite response | Check the Plasmite service first. Then use `windows-vmrun` once to inspect the process and capture the screen. Do not start another agent. |
| Codex is waiting at its input prompt | Its previous turn ended, so it cannot poll. Use one authorized direct input or restart the standard launcher to begin a continuing turn. Then return to Plasmite. |
| Task-owned PowerShell with no Codex | Close that exact idle PowerShell with `windows-vmrun`. Then run the standard launcher. Do not paste a launcher into the shell. |
| Unrelated PowerShell with no Codex | Preserve it. Run the standard launcher to create a separate, identifiable task-owned tree. |
| Multiple Codex processes | Identify the responsive, task-owned agent. Stop only duplicate task-owned processes. Do not create another. |
| Codex running without PowerShell | Use it if it responds through Plasmite. If its interactive state is uncertain, stop that exact task-owned process and use the standard launcher. |
| Plasmite service is down | Repair or restart Plasmite. Do not restart a healthy VM agent because its message channel is unavailable. |
| VM is stopped, locked, or unreachable | Use `windows-vmrun` to inspect or restore access. Ask the user only at a real login or credential boundary. |
| UAC, login, or another visible prompt | Expect the VM agent to notify you first. Use `captureScreen` or authorized direct VM control. Do not launch another shell. |


## Fast path

Use this as a speed rail, not a mandatory ceremony:

1. For a new or uncertain session, send a brief hello. Account for existing
   task-owned processes before starting anything.
2. When the table calls for a launch, reuse one verified launcher. Fill in the
   values in this disposable-VM recipe:

   ```bash
   scripts/windows-vmrun runProgramInGuest \
     -noWait -activeWindow -interactive \
     'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' \
     -NoExit -NoProfile -Command \
     "& '<CODEX_EXE>' resume '<SESSION_ID>' --dangerously-bypass-approvals-and-sandbox -C '<PROJECT_DIR>' -m '<MODEL>' -c 'model_reasoning_effort=\"<EFFORT>\"' -c 'check_for_update_on_startup=false' 'Check codex-bridge and acknowledge the guide. Keep this turn active while the assignment is open: work, report meaningful progress, and wait again after an empty Plasmite wait. Send a result or blocker before ending.'"
   ```

   Use a Codex path verified in the interactive user context. Remove
   `resume '<SESSION_ID>'` to start a new conversation. Remove
   `--dangerously-bypass-approvals-and-sandbox` unless the user authorized
   maximum permissions for an isolated or disposable VM. The flag removes tool
   prompts, not the decision stop.
3. Require a clear reply through Plasmite as proof of startup; do not require a
   particular message shape. A sent instruction is not proof that the agent
   received or acted on it. If no reply arrives promptly, inspect that process
   and screen once. If the launcher used the wrong environment or cannot find
   Codex, stop exploring alternatives and report the failure.
4. Ask for model settings only when no applicable choice is already known.
   Skip a separate readiness check unless setup is substantial or uncertain.
5. When resuming an interactive Codex session, skip its in-session updater and
   use the recorded session directory unless the task needs another checkout.
6. Before a bounded UI test, clear an expected application login once. Ask the
   user only when the login actually requires user action.

## Guardrails

- A Guest Operations process can have different credentials, environment, and
  desktop state from the VM agent. Use interactive mode and a verified explicit
  path; a background-process failure does not prove that the interactive agent
  has the same problem.
- Use Guest Operations to launch the interactive agent. Do not use it as a
  second agent runtime.
- Record the start and end of a large wait so you can tell the user how long things took, so that we can continuously improve on the efficiency of this process.
- Keep host and VM secrets in credential stores, not Plasmite or the clipboard.
- After one unexpectedly quiet wait during visible work, run
  `scripts/windows-vmrun captureScreen <HOST_OUTPUT.png>` once. Check for an
  approval or login prompt. Do not start another shell because the message
  channel is quiet.
- If the capture is black, check whether the guest is asleep or locked. Bring Fusion forward, send one harmless wake
  input, and retry the capture. If it remains black, stop and report the
  problem. Do not try another control path.
- Treat snapshot restoration, reset, deletion, and power-off as destructive.
- While the workflow is evolving, note large delays and occasionally ask the VM
  agent what could be simplified.
