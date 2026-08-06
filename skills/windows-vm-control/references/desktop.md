# Visible desktop control

Use the desktop path when the result depends on visible Windows state. Examples include a native app, focus, login, a dialog, clipboard behavior, a browser session, UAC, or a screenshot.

## Use a capture-action-capture loop

1. Capture the VM display.
2. Check the VM, Windows user, foreground app, and dialog.
3. Perform one small input action.
4. Capture the display again.
5. Check the visible result.

Do not send a long blind input sequence. Window movement, scaling, focus, animation, and new dialogs can make old coordinates wrong.

## Choose the desktop only when needed

Use an application interface or guest command when it can prove the same result. Use Fusion desktop control when the app exists only in the visible session. Use it also when appearance or focus is part of the result.

Use VMware Tools for a guest process that does not need visible state.

Resolve the signed-in Desktop instead of assuming a profile path:

```powershell
[Environment]::GetFolderPath('Desktop')
```

OneDrive or another policy can redirect the Desktop.

Launch a process in the signed-in session with the Keychain-backed wrapper:

```bash
scripts/windows-vmrun runProgramInGuest \
  -noWait -activeWindow -interactive \
  'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' \
  -NoExit -NoProfile
```

`-activeWindow -interactive` selects the signed-in session. It does not guarantee focus.

Capture the display without bringing Fusion to the front:

```bash
scripts/windows-vmrun captureScreen /tmp/windows-vm.png
```

Send literal text only after a capture proves focus:

```bash
scripts/windows-vmrun typeKeystrokesInGuest 'literal text'
```

`vmrun` does not supply reliable portable mouse clicks or special-key notation. Use Windows UI Automation for repeated control. Use the Fusion window for occasional visual actions.

## Handle focus and display state

- A black or stale capture can mean that Windows is locked, suspended, changing resolution, or not focused. It does not prove a Windows failure. Activate Fusion and click once inside the guest display when a fresh capture stays black.
- Keystrokes go to the focused surface. Capture after a focus change.
- Mac, Fusion, and Windows shortcuts can conflict. Send one action. Then check the result.
- The clipboard crosses a trust boundary. Do not place secrets on it without explicit user approval.

## Stop at identity boundaries

UAC can ask for approval without asking for identity. The Mac agent may approve a known UAC prompt when the underlying action is authorized, the publisher and program are clear, and no credential is required.

Passwords, passkeys, MFA, and identity consent belong to the user.

Use this sequence when a prompt appears:

1. Capture enough state to identify the prompt. Exclude secrets.
2. Check whether the prompt asks for approval or for identity.
3. Approve only a known result of an authorized action.
4. Stop and ask the user when the prompt needs identity or has an unclear result.
5. Capture the display again before work continues.

Do not send passwords, recovery codes, private keys, or tokens through remote automation.

## Prove a visible result

Use a current screenshot for a visible-state claim. Add a command check when the same action should also create stored system state.

`captureScreen` captures the Fusion console. It does not prove the state of an RDP session or another Windows session.

Only one operator controls the visible desktop at a time. Stop input when the user or another operator takes control. Capture fresh state before automation resumes.
