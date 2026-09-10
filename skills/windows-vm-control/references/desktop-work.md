# Desktop work

Choose between user assistance and automation based on the work. When the user is present, a short request to open a PDF or dismiss a dialog often wins. Automate repeated sequences, unattended work, or actions whose repeatability is itself being tested. Prefer a project-owned desktop helper before inventing UI Automation or coordinate scripts.

## Hand a step to the user

Stop the current desktop driver and confirm it stopped. Give the application, exact action, and state to leave behind, for example:

> In Windows Acrobat, open any PDF through the Box sidebar. Leave it open without saving or registering it, then tell me when it is ready.

Name a specific file only when its actual location is known. If the test needs a particular fixture, explain that requirement; do not silently treat another file as equivalent. Resume with the narrow observation needed to verify the result. User assistance can establish setup, while the agent collects the evidence.

If an automation attempt reveals that the next step needs substantial UI discovery and the user can do it quickly, hand it over then. Do not exhaust several unrelated techniques first.

## Inspect the Windows desktop

SSH commands run in a remote process context. For semantic inspection of the signed-in desktop, use an interactive launch. A normal process listing cannot tell you which controls are visible or focused.

Save this read-only probe as `/private/tmp/windows-ui.ps1`:

```powershell
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
$desktop = [System.Windows.Automation.AutomationElement]::RootElement
$windows = $desktop.FindAll(
    [System.Windows.Automation.TreeScope]::Children,
    [System.Windows.Automation.Condition]::TrueCondition)
$rows = @()
foreach ($window in $windows) {
    $rows += [pscustomobject]@{
        name = $window.Current.Name
        process_id = $window.Current.ProcessId
        automation_id = $window.Current.AutomationId
    }
}
ConvertTo-Json -InputObject $rows -Compress
```

```bash
scripts/windows-vm-interactive-run \
  --timeout 30 \
  --result /private/tmp/windows-ui-result.json \
  /private/tmp/windows-ui.ps1
```

The helper launches through Guest Operations with `-activeWindow -interactive`, captures the task's stdout/stderr in a terminal JSON envelope, and cleans up its unique files. The envelope has `status`, `exit_code` when available, and `output`; task JSON appears inside the output string. It does not select a target window or grant elevation.

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

Inspect the image before using its coordinates or drawing a visual conclusion. It shows Fusion's displayed desktop, not an RDP desktop. A black or stale capture leaves appearance unknown; it does not justify restarting Acrobat or sending blind input. Use a semantic probe or ask the user for the quick step.

Only send text after a current observation establishes the intended control's input focus:

```bash
scripts/windows-vmrun typeKeystrokesInGuest 'literal text'
```

`vmrun` has no reliable portable mouse-click or special-key notation. Use UI Automation patterns or a known guest-side helper. Guest pointer actions, including `SetCursorPos`, are acceptable when they do not move the Mac pointer or take Mac focus. If operating through Mac input is necessary, use existing consent or obtain it first.

`windows-vmrun doctor --require guest-ops` checks local configuration and credential availability. It does not prove a live interactive desktop; an actual probe does.

## Login and elevation

Leave identity prompts for the user. Stored Guest Operations credentials enable the helper but do not authorize typing a password into Windows login, website login, or an MFA prompt.

UAC may switch to a secure desktop that ordinary UI Automation cannot reach. Use a Fusion capture to identify the program, publisher, and requested action. If the elevation and Mac input are already authorized, act on the verified prompt through the available Mac UI controls. Otherwise ask for the specific missing consent or have the user click it. If the prompt cannot be seen reliably or requests credentials, hand it to the user. Never approve by blind keystrokes.
