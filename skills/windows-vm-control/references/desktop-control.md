# Control the signed-in Windows desktop

Use desktop control only when visible application state matters. SSH and
guest-agent output do not prove what appeared on screen.

## Choose evidence and control

Use the lowest-cost mechanism that proves the requested behavior:

1. Application command, API, log, or saved artifact.
2. Windows UI Automation by control name, role, or state.
3. Fresh screenshot plus deliberate keyboard or mouse input.

Resolve the signed-in Desktop instead of assuming `%USERPROFILE%\Desktop`:

```powershell
[Environment]::GetFolderPath('Desktop')
```

The Desktop may be redirected into OneDrive.

## Launch and focus an application

Launch a process in the signed-in session:

```bash
scripts/windows-vmrun runProgramInGuest \
  -noWait -activeWindow -interactive \
  'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' \
  -NoExit -NoProfile
```

`-activeWindow -interactive` selects the signed-in session but does not
guarantee foreground focus. Capture the screen once. If focus is wrong, activate
the task-owned window by UI Automation or its native window handle. Do not
relaunch the application or depend on an exact window title.

## Capture and inject input

Capture the guest display without foregrounding Fusion:

```bash
scripts/windows-vmrun captureScreen /tmp/windows-vm.png
```

Send literal keyboard input only after confirming the active window:

```bash
scripts/windows-vmrun typeKeystrokesInGuest 'literal text'
```

Keystroke injection is focus-sensitive. `vmrun` does not provide a reliable,
portable mouse-click command or special-key notation. Prefer Windows UI
Automation for repeatable control and host control of Fusion for occasional
visual actions. Confirm fresh state after every state-changing UI action.

If the Fusion window is black, activate it and click once inside the guest display to wake it; if Fusion is not open, open it and attach to the running VM first.

Never type a password through keystroke injection; ask the user to sign in.

If a visible action is unexpectedly quiet, capture once before starting another
process. Preserve unrelated applications and stop only known task-owned
duplicates.

## Handle UAC

Treat the UAC secure desktop as host-controlled Windows UI:

1. Capture or inspect the prompt through Fusion.
2. Confirm that the publisher, executable, and requested action match a known
   consequence of an authorized task.
3. Approve the prompt through host control of Fusion.
4. Capture or query fresh state to verify that elevation completed.

Do not ask the user to approve a routine prompt merely because it is UAC.
Escalate when the prompt is unexpected, ambiguous, requests credentials, or
exceeds the user's authority. Do not weaken UAC or bypass the secure desktop.
