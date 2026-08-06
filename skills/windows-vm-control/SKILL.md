---
name: windows-vm-control
description: Control and automate a VMware Fusion Windows VM from Codex running on the Mac host. Use for Windows commands, files, builds, tests, VM lifecycle, native Windows UI, screenshots, Windows login and UAC prompts, and delegation to Codex inside the VM.
---

# Windows VM Control

Treat Windows as a separate, persistent computer. Invoking this skill authorizes a background launch of Fusion and the configured VM.

Run the bundled commands from this skill directory, or use absolute paths. Fusion, Keychain, and the private VM network require host access.

## System model

The Mac can work with the VM through separate methods. One method can work while another fails.

```text
Mac agent
  -> Fusion -> configured VM
       |-> Tools -> Guest Operations
       |          -> interactive launch -> signed-in Windows desktop -> application
       |-> virtual network -> SSH route and host key -> Windows account and process -> Windows Codex
       `-> Fusion screen -> captured image
```

Each method reaches different Windows components and can confirm different facts.

| Method | Reaches | Shows | Does not show |
| --- | --- | --- | --- |
| `vmrun` and Tools | VM, Windows files, and Windows processes | Power, Tools, address, and the requested file or process check | SSH or visible windows and dialogs |
| SSH | One Windows account and its inherited environment | Route, SSH host key, account, command output, and exit status | Signed-in Windows desktop or visible windows |
| Interactive launch | Signed-in Windows desktop | Output from the launched process | Which Windows control has input focus |
| Fusion capture | Windows screen shown by Fusion | Current Fusion screen image | An RDP or other Windows desktop |
| Windows Codex | Work where later steps depend on earlier output | What Windows Codex reports | Independent confirmation of completion |

VM disks, files, the SSH host key, settings, and configuration survive restarts. Power, Tools, addresses, routes, process environments, whether a Windows user is signed in, input focus, and running processes can change. A running process does not receive later environment changes.

## What the agent may do

| Action | Rule |
| --- | --- |
| Launch Fusion in the background; start the configured VM | Proceed |
| Run read-only checks; use SSH, background capture, or Guest Operations | Proceed for the VM, files, and actions named in the request |
| Bring an app forward; change Mac focus; move or capture the Mac pointer | Ask first |
| Enter a password, passkey, multifactor response, or approve a prompt that confirms the user's identity or grants account access | Stop for the user |
| Use another VM or account; suspend or stop Windows; revert a snapshot; delete persistent data; modify another checkout | Ask first |

Do not let two agents or processes modify the same checkout or process tree at the same time.

## Choose how to work

1. Name the check that would show the requested work is complete.
2. Choose the method that can run that check.
3. Check that method. If it fails, find the first component that did not respond as expected:

   ```text
   Tools:   Fusion -> VM -> Tools -> Guest Operations
   SSH:     Fusion -> VM -> network -> route and SSH host key -> Windows account -> process
   Desktop: Fusion -> VM -> Tools -> interactive launch -> signed-in Windows desktop -> application
   ```

4. Use the linked recipe. Read its output before acting again.

| Goal | Method | Recipe |
| --- | --- | --- |
| VM startup, power, Tools, or address | `vmrun` | [Lifecycle](references/lifecycle.md) |
| One or two commands known before execution | SSH | [Direct SSH](references/command-work.md#direct-ssh) |
| A multiline PowerShell script known before execution | SSH PowerShell helper | [Scripted PowerShell](references/command-work.md#scripted-powershell) |
| Work where each next step can depend on earlier output | Windows Codex | [One Windows Codex run](references/command-work.md#one-windows-codex-run) |
| Which window or dialog is visible and has Windows input focus | Interactive launch | [Desktop work](references/desktop-work.md) |
| SSH or route recovery | Tools, then SSH | [Access recovery](references/access-recovery.md) |

After one quoting failure, nested logic, or about 30 seconds of command composition, move from direct SSH to scripted PowerShell or one Windows Codex run.

## Finish

Use the method that can show completion. Do not treat an agent report as completion until the relevant file, process, test, or visible Windows check agrees. Remove only temporary files and processes created for the current task.
