# Visible desktop control

Use desktop control only when the result depends on visible Windows state: an application, dialog, login, focus, clipboard, UAC prompt, or screenshot.

## Protect the user's desktop

Ask before bringing Fusion or another app to the Mac foreground, changing macOS focus, or moving or capturing the mouse. Approval covers only the bounded foreground interaction described to the user. Return control promptly.

Background Fusion launch, `captureScreen`, SSH, Guest Operations, and guest-side UI Automation do not require foreground permission when they leave the user's Mac input and focus unchanged.

## Use a capture-action-capture loop

1. Capture the VM display.
2. Identify the VM, Windows user, foreground app, and dialog.
3. Perform one small action.
4. Capture and check the result.

Do not send a long blind input sequence. Use an application interface or guest command when it proves the same result.

## Reach the signed-in session

Resolve a redirected Windows Desktop rather than assuming a profile path:

```powershell
[Environment]::GetFolderPath('Desktop')
```

Launch a process in the signed-in session:

```bash
scripts/windows-vmrun runProgramInGuest \
  -noWait -activeWindow -interactive \
  'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' \
  -NoExit -NoProfile
```

`-activeWindow -interactive` selects the signed-in session but does not guarantee focus.

Capture without foregrounding Fusion:

```bash
scripts/windows-vmrun captureScreen /tmp/windows-vm.png
```

Send literal guest text only after a capture proves the focused Windows target:

```bash
scripts/windows-vmrun typeKeystrokesInGuest 'literal text'
```

`vmrun` has no reliable portable mouse-click or special-key notation. Use Windows UI Automation for repeated guest control. Use the Fusion window only after foreground permission.

## Handle prompts and uncertain display state

A black or stale capture can mean lock, suspend, resolution change, or missing focus. It does not prove a Windows failure. Ask before activating Fusion or clicking inside the guest.

Capture again after a focus change. Mac, Fusion, and Windows can intercept the same shortcut differently.

The clipboard crosses a trust boundary. Do not place secrets on it without explicit approval.

The Mac agent may approve a known UAC result of an authorized action when the publisher and program are clear and no credential is required. Stop for a password, passkey, multifactor authentication, identity consent, or an unclear prompt.

## Prove the result

Use a current screenshot for a visible-state claim. Add a command check when the action should also create stored state. `captureScreen` proves only the Fusion console, not an RDP or other Windows session.

Only one operator controls the visible desktop. Stop input when the user or another operator takes control. Capture fresh state before resuming automation.
