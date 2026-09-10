# Task results and recovery

Use `windows-vm-task` when output needs to survive an interrupted session or support follow-up work. Simple commands can use the existing helpers directly.

```bash
scripts/windows-vm-task run powershell --timeout 30 /private/tmp/check.ps1
scripts/windows-vm-task run desktop windows
scripts/windows-vm-task status /private/tmp/windows-task-EXAMPLE --probe
```

`run` accepts `powershell`, `interactive`, `desktop`, `capture`, `bounded`, or `managed`, followed by that helper’s normal arguments. It forwards stdin and streams stdout/stderr, preserving managed-session interaction. It prints the location of a private temporary record directory. Use `run --record /absolute/new-directory ...` only when a chosen location helps. Existing directories are refused.

Each directory contains raw stdout/stderr and `result.json` with:

- Task ID, timestamps, helper kind, and exit code.
- State, completion certainty, and temporary-file cleanup status.
- Recorded Windows process identities and temporary paths, when available.
- Evidence locations and the next useful check.

Success describes the helper’s result; inspect evidence for the requested outcome. Cleanup does not mean intentionally launched background applications ended. A managed run reports controller closure separately from turn completion and links its existing controller state. Reconnect using the same controller state file and a new task record.

`status` checks the host runner’s process identity and reads the latest managed state. `--probe` additionally checks recorded Windows PIDs and creation times through SSH. Neither retries nor terminates anything. Missing process evidence leaves completion unknown; an absent root does not establish that descendants stopped or effects were undone. Use the recorded identities and paths to reconcile partial effects before repeating a mutation.

Records contain raw application output and stay until removed. Delete their directory when the evidence is no longer needed. Direct helpers do not create these durable logs.
