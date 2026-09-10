# Command work

Use a known operation directly. Delegate when Windows-side diagnosis or implementation benefits from an agent. Use a managed session when follow-up direction or user input is likely; a bounded run is easiest when the assignment can finish without either.

## Run a command

For a simple command, use the configured SSH alias (`windows-vm` in these examples):

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 -o ConnectionAttempts=1 windows-vm whoami
```

For PowerShell variables, pipelines, JSON, or multiline logic, write a host `.ps1` file and use the helper. This avoids passing PowerShell through multiple shells. For example, save this as `/private/tmp/windows-check.ps1`:

```powershell
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[pscustomobject]@{
    computer = $env:COMPUTERNAME
    user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    directory = (Get-Location).Path
} | ConvertTo-Json -Compress
```

```bash
scripts/windows-vm-powershell --timeout 30 /private/tmp/windows-check.ps1
```

The helper runs Windows PowerShell, preserves stdin/stdout/stderr and exit status, and removes its temporary guest script. Exit `76` means cleanup was not confirmed; stderr identifies the remaining file. Small scripts use `EncodedCommand`. Save non-ASCII scripts as UTF-8 with a BOM for Windows PowerShell 5.

`$ErrorActionPreference = 'Stop'` handles PowerShell errors. Check `$LASTEXITCODE` explicitly after native commands:

```powershell
& git -C 'C:\src\project' status --short
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

An SSH process can have a different environment from an interactive terminal. Set required variables in the process that invokes the command. If an executable is missing, check its path and version in a new SSH process before installing anything. Existing processes do not acquire later environment changes.

## Delegate one outcome

Write a UTF-8 handoff file. Include the facts the guest needs to make decisions: outcome, exact checkout/revision, allowed effects, unrelated work to preserve, and evidence to return. Keep project-specific build and QA instructions in the project.

Example handoff, with paths and revision filled from current evidence:

```text
Build the specified revision in the isolated Windows worktree C:\src\project-proof.
Verify HEAD equals the supplied full SHA before building. Read the checkout's instructions.
Use the project's build command for the installed application's architecture.
Return the command exit status, first failure if any, artifact path/hash/architecture,
and final Git status. Build only; installation is outside this assignment.
Preserve unrelated work and cached dependencies. Do not push or deploy.
If a desktop step is needed, report the exact step for the user and finish this run.
```

```bash
scripts/windows-codex-run \
  --cwd 'C:\src\project-proof' \
  --timeout 900 \
  < /private/tmp/windows-handoff.txt
```

Keep the runner in an execution session you can poll or interrupt. Retain stdout (JSONL events) and stderr (readiness, process, and cleanup information) when needed for follow-up. Poll at meaningful intervals and keep the user informed during long builds.

The runner waits for readiness, locates Codex, and checks its active policy before launching. `--readiness-wait` controls this separate startup allowance; `--timeout` bounds the assignment. Use `--allow-non-git` only for an intentional non-checkout directory. Preserve the configured model and reasoning unless an authorized task choice requires an override.

The bundled runners currently require the approved VM profile: `approval_policy = "never"` and `sandbox_mode = "danger-full-access"`. A mismatch stops the runner. This is a local runner requirement, not a reason to weaken an arbitrary machine's settings. Report the mismatch and use an already-authorized direct route if suitable; do not override the policy on the command line or silently rewrite configuration.

| Exit | What to do |
| --- | --- |
| `0` | Read the final result and its supporting evidence. |
| `74` | User input requested. A bounded run cannot accept a continued conversation; resolve the question and issue a new scoped assignment, or use a managed session. |
| `77` | Inspect the approval request and compare it with existing authorization. |
| `76` | Cleanup is unconfirmed. Inspect the recorded task process tree before another executor starts. |
| `124` | Assignment timed out. Inspect partial results and changed files before deciding what remains. |
| Other nonzero | Read stderr to distinguish readiness, policy, checkout, process, and transport failures. |

A request for a routine implementation choice can be answered from the authorized scope. Identity prompts belong to the user. New destructive or external effects need authorization covering them.

## Interrupt or take over

For a bounded run, send an interrupt to the recorded host runner through its execution session. Its INT/TERM handler attempts to stop the recorded guest process tree. Check the runner's terminal result and cleanup report; closing a terminal or losing SSH alone does not prove Windows stopped.

If cleanup is unknown, inspect only the recorded PID, its descendants, and relevant task files using the PowerShell helper. Do not target processes solely by executable name. PID existence alone is insufficient after a restart or a long delay; verify process identity before termination.

For work likely to need steering or orderly interruption, use [managed delegation](managed-delegation.md). Before asking the user to operate Windows, confirm the active desktop automation has stopped. Reuse completed build evidence; a UI handoff does not require rebuilding.
