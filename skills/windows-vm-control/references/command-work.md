# Command work

Use the simplest method that fits the work. All commands below use the configured SSH alias unless overridden.

## Direct SSH

Use this when one or two commands are known before execution:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 -o ConnectionAttempts=1 windows-vm whoami
```

The exit status and output show only what happened in the SSH account, `PATH`, and inherited environment. If quoting or multiline logic appears, stop and use the PowerShell helper.

## Scripted PowerShell

Use this for a short PowerShell script whose commands are known before it runs:

```bash
scripts/windows-vm-powershell --timeout 30 /absolute/host/task.ps1
```

The helper uses the system Windows PowerShell and preserves stdin, stdout, stderr, and the script exit status. It uses `EncodedCommand` for a small script. For a larger script, it uses a unique file in the Windows temporary directory and removes that file after execution. Exit 76 means cleanup could not be confirmed; stderr names the remaining file.

Set `$ErrorActionPreference = 'Stop'` when any PowerShell error must fail the task. Use UTF-8 with a byte-order mark for non-ASCII Windows PowerShell 5 scripts.

## One Windows Codex run

Use this when each next step can depend on earlier output:

```bash
scripts/windows-codex-run \
  --cwd 'C:\src\project' \
  --timeout 300 \
  < /absolute/host/handoff.txt
```

The prompt names the requested outcome, allowed reads and changes, unrelated work to preserve, required checks, and forbidden actions outside the named VM and checkout. Add `--allow-non-git` only for an intentional non-checkout directory. Override the Windows Codex model or reasoning only when the task needs it.

Before each launch, the runner finds the current Codex executable and reads the active approval and sandbox settings. The Windows Codex configuration is the only place that sets these values. On the approved test VM they must be `approval_policy = "never"` and `sandbox_mode = "danger-full-access"`. Different values stop the run.

JSONL goes to stdout. Status, Windows process, and cleanup information goes to stderr. These exit codes require a decision:

| Exit | Meaning | Next action |
| --- | --- | --- |
| 74 | Windows Codex requested user input | Return control to the user |
| 76 | Process cleanup was not confirmed | Inspect Windows processes before retrying |
| 77 | Windows Codex requested approval | Review the specific request |
| 124 | Timeout | Inspect running processes and files changed before the timeout |

For another nonzero exit, read stderr. It names whether VM readiness, Codex settings, the checkout, the Windows process, or the SSH connection failed. Do not override the Windows Codex approval or sandbox settings on the command line.

Check the Windows Codex report with the method that can show completion. Stop if it requests credentials, asks the user to confirm identity, would delete, reset, or overwrite persistent data, names another VM, account, or checkout, or conflicts with another process modifying the same checkout.

This skill cannot steer a Windows Codex run after launch. Use a new run for a self-contained follow-up.

## SSH process environment

An SSH process can have a different `PATH` and environment from an interactive terminal. Use `windows-vm-status --require codex` for the current Windows Codex executable file and version. For another executable, check its specific file path and run its version command from a new process.

If a client works in one process but not another, compare its stored configuration without secrets, the environment of a new process, and the server address that process uses. Test authentication without printing credentials, then run one read-only operation. Do not rotate credentials or widen network access to hide the difference.
