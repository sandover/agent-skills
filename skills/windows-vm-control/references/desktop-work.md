# Desktop work

Automate known, bounded actions using an existing project helper or the bundled commands below. For unfamiliar UI, inspect the relevant window and controls; continue if the intended target and effect become clear. Ask for assistance for identity prompts, unresolved ambiguity, or when further discovery would cost substantially more than the user’s step. Weigh interruption cost and an explicit preference for unattended work; a short human action alone is not a reason to stop automation.

## Hand a step to the user

Stop the current desktop driver and confirm it stopped. Give the application, exact action, and state to leave behind, for example:

> In Windows Acrobat, open any PDF through the Box sidebar. Leave it open without saving or registering it, then tell me when it is ready.

Name a specific file only when its actual location is known. If the test needs a particular fixture, explain that requirement; do not silently treat another file as equivalent. Resume with the narrow observation needed to verify the result. User assistance can establish setup, while the agent collects the evidence.

When discovery stops producing useful evidence, choose a targeted user handoff or explain the unattended blocker. Do not cycle through unrelated input techniques.

## Inspect the Windows desktop

SSH commands run in a remote process context. For semantic inspection of the signed-in desktop, use an interactive launch. A normal process listing cannot tell you which controls are visible or focused.

Use the bundled commands; no custom PowerShell is needed for ordinary inspection:

```bash
scripts/windows-vm-desktop windows
scripts/windows-vm-desktop controls --window 123456 --pid 1234
scripts/windows-vm-desktop invoke --window 123456 --pid 1234 --automation-id 'OpenButton'
scripts/windows-vm-desktop set-value --window 123456 --pid 1234 --automation-id 'FileName' --value 'C:\fixtures\sample.pdf'
```

Replace example identifiers with current inspection results. `--name` is an exact, case-sensitive selector; when supplied with `--automation-id`, both must match. Actions re-resolve the window handle and owning PID, require exactly one control, check visibility and enabled state, and use its supported pattern. Password controls are rejected. Successful dispatch still needs an observation of the resulting application state. Window handles and PIDs are short-lived selectors; re-inspect after an application restart.

Output is the interactive runner JSON envelope; its `output` contains the JSON array of windows, controls, or the dispatched action. Control rows include supported patterns. Unsupported patterns fail without falling back to blind input. Use `windows-vm-interactive-run` with a project-owned script for richer app-specific sequences.

The helper launches a hidden PowerShell process through interactive Guest Operations, captures the task's stdout/stderr in a terminal JSON envelope, and cleans up its unique files. The envelope has `status`, `exit_code` when available, and `output`; task JSON appears inside the output string. It does not select a target window or grant elevation.

Use the returned process/window identity to scope a more specific probe. Match the intended control and use its supported UI Automation pattern. If multiple controls match, inspect further before acting. Several known semantic actions can be batched; screenshots between every action are unnecessary.

| Exit | Meaning and next step |
| --- | --- |
| `0` | Task and cleanup completed; inspect the task output. |
| `71` | Guest Operations failed; check that capability. |
| `72` | No signed-in desktop; ask the user to sign in if the task requires one. |
| `75` | Launch, task, or result failed; read the error. |
| `76` | Cleanup unconfirmed, including loss of Guest Operations; reconcile task processes before retrying. |
| `124` | Timeout; inspect partial effects before repeating input. |

## Capture or send input

Capture through Fusion when appearance matters:

```bash
scripts/windows-vmrun captureScreen /private/tmp/windows-screen.png
```

Inspect the image before using its coordinates or drawing a visual conclusion. The helper tries Fusion first, then the signed-in desktop when Fusion fails or returns black pixels. It reports `capture_source=fusion` or `capture_source=windows-desktop`; the fallback is not evidence of secure-desktop/UAC state and may refer to a different session than Fusion. If neither produces usable pixels it exits `75`; cleanup failure exits `76`. A nonblack image can still be stale, so inspect it before acting. An unavailable capture leaves appearance unknown; it does not justify restarting Acrobat or sending blind input. Use a semantic probe or ask the user for the quick step.

Only send text after a current observation establishes the intended control's input focus:

```bash
scripts/windows-vmrun typeKeystrokesInGuest 'literal text'
```

`vmrun` has no reliable portable mouse-click or special-key notation. Use UI Automation patterns or a known guest-side helper. Guest pointer actions, including `SetCursorPos`, are acceptable when they do not move the Mac pointer or take Mac focus. If operating through Mac input is necessary, use existing consent or obtain it first.

`windows-vmrun doctor --require guest-ops` checks local configuration and credential availability. It does not prove a live interactive desktop; an actual probe does.

## Login and elevation

Leave identity prompts for the user. Stored Guest Operations credentials enable the helper but do not authorize typing a password into Windows login, website login, or an MFA prompt.

UAC may switch to a secure desktop that ordinary UI Automation cannot reach. Use a capture reported as `capture_source=fusion` to identify the program, publisher, and requested action. A desktop fallback cannot authorize a secure-desktop click. If the elevation and Mac input are already authorized, act on the verified prompt through the available Mac UI controls. Otherwise ask for the specific missing consent or have the user click it. If the prompt cannot be seen reliably or requests credentials, hand it to the user. Never approve by blind keystrokes.
