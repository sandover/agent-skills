# Desktop work

Windows separates remote command processes from the signed-in Windows desktop. SSH and Guest Operations started without `-activeWindow -interactive` cannot reliably list or control that desktop's windows. Run UI Automation through an interactive launch.

Mac focus means the macOS application that receives keyboard and mouse input. Windows input focus means the Windows control that receives keystrokes.

Guest-side UI Automation, including `SetCursorPos`, may move the Windows pointer without asking when it does not move the Mac pointer or change Mac focus.

## Contents

- [Inspect and act](#inspect-and-act)
- [Reach the signed-in Windows desktop](#reach-the-signed-in-windows-desktop)
- [Black or stale capture](#black-or-stale-capture)
- [Stop conditions](#stop-conditions)
- [UAC prompts](#uac-prompts)

## Inspect and act

This recipe is for visible applications, dialogs, Windows input focus, UAC, and screenshots. It does not authorize bringing Fusion forward or changing Mac focus.

Check Guest Operations first:

```bash
scripts/windows-vmrun doctor --require guest-ops
```

1. Capture the Windows screen shown by Fusion:

   ```bash
   scripts/windows-vmrun captureScreen /tmp/windows-vm.png
   ```

2. If the requested window is visible, identify the Windows user, application, and dialog before sending input.
3. Perform one small action.
4. Capture again and confirm the expected change.

Send literal text only after the capture shows which Windows control has input focus:

```bash
scripts/windows-vmrun typeKeystrokesInGuest 'literal text'
```

`vmrun` has no reliable portable mouse-click or special-key notation. Use Windows UI Automation for those actions.

## Reach the signed-in Windows desktop

Run one UI Automation script in the signed-in Windows desktop:

```bash
scripts/windows-vm-interactive-run \
  --timeout 30 \
  --result /tmp/ui-result.json \
  /absolute/host/ui-task.ps1
```

The command creates unique Windows files, launches through `-activeWindow -interactive`, polls once per second, retrieves one terminal JSON result, and removes its files. It does not select which Windows control has input focus.

| Exit | Meaning |
| --- | --- |
| 0 | Task completed and cleanup succeeded |
| 71 | Guest Operations failed |
| 72 | No signed-in Windows desktop was found |
| 75 | Interactive launch, task, or result failed |
| 76 | Cleanup could not be confirmed |
| 124 | The caller-supplied timeout expired |

If Guest Operations disappears while the task is running, the helper reports the loss and exits 76 because it cannot confirm process or file cleanup.

## Black or stale capture

If the application process is responsive but the capture is black or stale:

1. Treat the Fusion screen and signed-in Windows desktop as not yet confirmed.
2. Do not restart the application or send input.
3. Run a UI Automation probe created for the current task through an interactive launch.
4. Act only after the probe or a later capture identifies the requested window.

A Fusion capture shows only the Windows screen displayed by Fusion. It does not show an RDP or other Windows desktop.

## Stop conditions

Ask before bringing Fusion forward, changing Mac focus, or moving or capturing the Mac pointer. Stop for a password, passkey, multifactor response, or a prompt that confirms the user's identity or grants account access.

## UAC prompts

UAC can switch Windows to its secure desktop. UI Automation and interactive Guest Operations may not see or control that desktop.

Use `captureScreen` to check whether Fusion shows the expected publisher, program, and requested action. If it does, ask before bringing Fusion forward and clicking the prompt with the Mac pointer. If Fusion does not show or control the secure desktop, or if the prompt needs a credential, stop for the user. Do not send blind keystrokes.
