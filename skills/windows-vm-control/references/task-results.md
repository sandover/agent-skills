# Task results and recovery

Use `windows-vm-task` when output needs to survive an interrupted session or support follow-up work. Simple commands can use the existing helpers directly.

```bash
scripts/windows-vm-task run powershell --timeout 30 /private/tmp/check.ps1
scripts/windows-vm-task run interactive --timeout 30 /private/tmp/check-desktop.ps1
scripts/windows-vm-task status /private/tmp/windows-task-EXAMPLE --probe
```

`run` accepts `powershell` or `interactive`, followed by the helper's normal arguments. It forwards stdin and streams stdout/stderr. Before launching, it prints `task_record=<directory>`; pass that directory directly to `status` (the `result.json` path also works). Use `run --record /absolute/new-directory ...` when you want a known location before starting. Existing directories are refused. Interactive results are stored inside the record directory, so omit the underlying helper's `--result` option.

Use desktop and capture commands directly. Delegation retains its existing runners and [managed-session recovery](managed-delegation.md#reconnect-without-duplicating-work).

Each directory contains raw stdout/stderr and `result.json` with:

- Task ID, timestamps, helper kind, and exit code.
- State, completion certainty, and temporary-file cleanup status.
- Recorded Windows process identities and temporary paths, when available.
- Evidence locations and the next useful check.

Helper success is not proof of the requested outcome; inspect the evidence. Task completion, temporary-file cleanup, and the lifetime of intentionally launched applications are separate facts. A cleanup failure does not erase an observed task exit.

`status` checks the host runner's process identity. `--probe` additionally checks recorded Windows PIDs and creation times through SSH, distinguishing running, missing, reused PID, wrong host, and unavailable observations. Transport failures return a `probe_error` in the JSON result. Neither retries nor terminates anything. Missing process evidence leaves completion unknown; an absent root does not establish that descendants stopped or effects were undone. Use the recorded identities and paths to reconcile partial effects before repeating a mutation.

Records contain raw application output and stay until removed. Delete their directory when the evidence is no longer needed. Direct helpers do not create these durable logs.
