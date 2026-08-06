#!/bin/zsh
# Exercise host-side readiness, payload, event, timeout, and cleanup behavior.
# Use only task-owned temporary copies and stubbed SSH transports.
# Keep the tests independent from VMware, Windows, credentials, and the network.
# Fail with the first concise assertion and remove all temporary files on exit.

set -euo pipefail

skill_dir=${0:A:h:h}
temp_dir=$(mktemp -d -t windows-vm-control-tests.XXXXXX)
trap 'rm -rf -- "$temp_dir"' EXIT

fail() {
  print -u2 -r -- "FAIL: $1"
  exit 1
}

run_capture() {
  local expected=$1
  shift
  set +e
  "$@" > "$temp_dir/out" 2> "$temp_dir/err"
  command_status=$?
  set -e
  if [[ "$command_status" != "$expected" ]]; then
    [[ ! -s "$temp_dir/out" ]] || { print -u2 'stdout:'; /bin/cat "$temp_dir/out" >&2; }
    [[ ! -s "$temp_dir/err" ]] || { print -u2 'stderr:'; /bin/cat "$temp_dir/err" >&2; }
    fail "expected exit $expected, got $command_status: $*"
  fi
}

run_capture_with_input() {
  local expected=$1 input_path=$2
  shift 2
  set +e
  "$@" < "$input_path" > "$temp_dir/out" 2> "$temp_dir/err"
  command_status=$?
  set -e
  if [[ "$command_status" != "$expected" ]]; then
    [[ ! -s "$temp_dir/out" ]] || { print -u2 'stdout:'; /bin/cat "$temp_dir/out" >&2; }
    [[ ! -s "$temp_dir/err" ]] || { print -u2 'stderr:'; /bin/cat "$temp_dir/err" >&2; }
    fail "expected exit $expected, got $command_status: $*"
  fi
}

status_dir="$temp_dir/status"
mkdir -p "$status_dir/bin" "$status_dir/stub"
cp "$skill_dir/scripts/windows-vm-status" "$status_dir/bin/"
cp "$skill_dir/scripts/guest-probe.ps1" "$status_dir/bin/"

cat > "$status_dir/stub/ssh" <<'STUB'
#!/bin/zsh
if [[ "${1:-}" == -G ]]; then
  print 'hostname 192.0.2.10'
  exit 0
fi
print -r -- "$*" >> "$TEST_SSH_LOG"
if [[ "${TEST_STATUS_MODE:-}" == probe-failed ]]; then
  print 'unexpected=output'
  exit 0
fi
print 'computer=TEST-WIN'
print 'user=test-win\agent'
if [[ "$*" == *WINDOWS_VM_CONTROL_CHECK_CODEX=1* ]]; then
  print 'codex=ok'
  print 'codex_path=C:\codex.exe'
  print 'codex_version=codex-cli test'
  print 'codex_policy=mismatch'
else
  print 'codex=skipped'
  print 'codex_path=not_checked'
  print 'codex_version=not_checked'
  print 'codex_policy=not_checked'
fi
STUB
chmod +x "$status_dir/stub/ssh"

: > "$temp_dir/ssh.log"
TEST_SSH_LOG="$temp_dir/ssh.log" PATH="$status_dir/stub:$PATH" \
  run_capture 0 "$status_dir/bin/windows-vm-status" --require ssh --wait 0
rg -q '^ssh=ok$' "$temp_dir/out" || fail 'SSH-only readiness did not succeed'
rg -q '^codex=' "$temp_dir/out" && fail 'SSH-only readiness emitted Codex fields'
rg -q 'WINDOWS_VM_CONTROL_CHECK_CODEX' "$temp_dir/ssh.log" && fail 'SSH-only readiness started the Codex probe'

: > "$temp_dir/ssh.log"
TEST_SSH_LOG="$temp_dir/ssh.log" PATH="$status_dir/stub:$PATH" \
  run_capture 1 "$status_dir/bin/windows-vm-status" --require codex --wait 5
[[ "$(wc -l < "$temp_dir/ssh.log" | tr -d '[:space:]')" == 1 ]] || fail 'policy mismatch was retried'
rg -q '^codex_policy=mismatch$' "$temp_dir/out" || fail 'policy mismatch was not reported'

: > "$temp_dir/ssh.log"
TEST_STATUS_MODE=probe-failed TEST_SSH_LOG="$temp_dir/ssh.log" PATH="$status_dir/stub:$PATH" \
  run_capture 1 "$status_dir/bin/windows-vm-status" --require ssh --wait 5
[[ "$(wc -l < "$temp_dir/ssh.log" | tr -d '[:space:]')" == 1 ]] || fail 'malformed SSH probe output was retried'
rg -q '^ssh=probe_failed$' "$temp_dir/out" || fail 'malformed SSH probe output was not classified'

payload_dir="$temp_dir/payload"
mkdir -p "$payload_dir/stub"
cp "$skill_dir/scripts/windows-vm-powershell" "$payload_dir/"
cat > "$payload_dir/stub/ssh" <<'STUB'
#!/bin/zsh
print -r -- "$*" >> "$TEST_SSH_LOG"
if [[ "$*" == *'Out.Write($env:TEMP)'* ]]; then
  print -r -- 'C:\Users\test\AppData\Local\Temp'
  exit 0
fi
if [[ -n "${TEST_REMOTE_FAIL_ONCE_FILE:-}" ]]; then
  if [[ ! -e "$TEST_REMOTE_FAIL_ONCE_FILE" ]]; then
    print failed > "$TEST_REMOTE_FAIL_ONCE_FILE"
    exit "${TEST_REMOTE_EXIT:-1}"
  fi
  exit "${TEST_CLEANUP_EXIT:-0}"
fi
exit "${TEST_REMOTE_EXIT:-0}"
STUB
cat > "$payload_dir/stub/scp" <<'STUB'
#!/bin/zsh
print -r -- "$*" >> "$TEST_SCP_LOG"
exit "${TEST_SCP_EXIT:-0}"
STUB
chmod +x "$payload_dir/stub/ssh" "$payload_dir/stub/scp"
print -r -- "Write-Output 'small'" > "$payload_dir/small.ps1"
perl -e 'print "# x\n" x 1500' > "$payload_dir/large.ps1"
: > "$temp_dir/payload-ssh.log"
: > "$temp_dir/payload-scp.log"
TEST_SSH_LOG="$temp_dir/payload-ssh.log" TEST_SCP_LOG="$temp_dir/payload-scp.log" \
  PATH="$payload_dir/stub:$PATH" \
  run_capture 0 "$payload_dir/windows-vm-powershell" "$payload_dir/small.ps1"
[[ ! -s "$temp_dir/payload-scp.log" ]] || fail 'small payload used file transfer'
[[ "$(wc -l < "$temp_dir/payload-ssh.log" | tr -d '[:space:]')" == 1 ]] || fail 'small payload did not use one SSH command'

: > "$temp_dir/payload-ssh.log"
: > "$temp_dir/payload-scp.log"
TEST_SSH_LOG="$temp_dir/payload-ssh.log" TEST_SCP_LOG="$temp_dir/payload-scp.log" \
  TEST_REMOTE_EXIT=0 PATH="$payload_dir/stub:$PATH" \
  run_capture 0 "$payload_dir/windows-vm-powershell" "$payload_dir/large.ps1"
rg -q 'Out.Write\(\$env:TEMP\)' "$temp_dir/payload-ssh.log" || fail 'large payload did not read the Windows temp directory'
rg -q -- '^-n ' "$temp_dir/payload-ssh.log" || fail 'temp-directory probe could consume task stdin'
rg -q 'windows-vm-control-.*\.ps1' "$temp_dir/payload-scp.log" || fail 'large payload did not use a unique guest script'
rg -q -- '-EncodedCommand' "$temp_dir/payload-ssh.log" || fail 'large payload did not run through the cleanup wrapper'
rg -q '# x' "$temp_dir/payload-ssh.log" && fail 'large payload contents leaked into SSH arguments'

: > "$temp_dir/payload-ssh.log"
: > "$temp_dir/payload-scp.log"
TEST_SSH_LOG="$temp_dir/payload-ssh.log" TEST_SCP_LOG="$temp_dir/payload-scp.log" \
  TEST_REMOTE_EXIT=37 TEST_REMOTE_FAIL_ONCE_FILE="$temp_dir/remote-failed-once" \
  PATH="$payload_dir/stub:$PATH" \
  run_capture 37 "$payload_dir/windows-vm-powershell" "$payload_dir/large.ps1"
[[ "$(wc -l < "$temp_dir/payload-ssh.log" | tr -d '[:space:]')" == 3 ]] || fail 'failed remote script did not verify guest cleanup'

: > "$temp_dir/payload-ssh.log"
: > "$temp_dir/payload-scp.log"
TEST_SSH_LOG="$temp_dir/payload-ssh.log" TEST_SCP_LOG="$temp_dir/payload-scp.log" \
  TEST_SCP_EXIT=9 PATH="$payload_dir/stub:$PATH" \
  run_capture 9 "$payload_dir/windows-vm-powershell" "$payload_dir/large.ps1"
[[ "$(wc -l < "$temp_dir/payload-ssh.log" | tr -d '[:space:]')" == 2 ]] || fail 'failed transfer did not verify guest cleanup'

: > "$temp_dir/payload-ssh.log"
: > "$temp_dir/payload-scp.log"
TEST_SSH_LOG="$temp_dir/payload-ssh.log" TEST_SCP_LOG="$temp_dir/payload-scp.log" \
  TEST_SCP_EXIT=9 TEST_REMOTE_EXIT=12 PATH="$payload_dir/stub:$PATH" \
  run_capture 76 "$payload_dir/windows-vm-powershell" "$payload_dir/large.ps1"
rg -q 'cleanup=unverified' "$temp_dir/err" || fail 'large-payload cleanup failure was not reported'

interactive_dir="$temp_dir/interactive"
mkdir -p "$interactive_dir"
cp "$skill_dir/scripts/windows-vm-interactive-run" "$interactive_dir/"
cp "$skill_dir/scripts/interactive-runner.ps1" "$interactive_dir/"
cat > "$interactive_dir/windows-vmrun" <<'STUB'
#!/bin/zsh
print -r -- "$*" >> "$TEST_INTERACTIVE_LOG"
command_name=${1:-}
shift || true
case "$command_name" in
  doctor)
    [[ "$TEST_INTERACTIVE_MODE" != guest-ops-failure ]]
    ;;
  listProcessesInGuest)
    if [[ "$TEST_INTERACTIVE_MODE" == guest-ops-lost ]]; then
      if [[ -e "$TEST_INTERACTIVE_STATE" ]]; then
        exit 1
      fi
      print reached > "$TEST_INTERACTIVE_STATE"
      print -r -- '456 explorer.exe'
    elif [[ "$TEST_INTERACTIVE_MODE" == missing-desktop ]]; then
      print -r -- '123 notepad.exe'
    else
      print -r -- '456 explorer.exe'
    fi
    ;;
  createTempFileInGuest)
    print -r -- 'C:\Temp\vmware-seed.tmp'
    ;;
  copyFileFromHostToGuest)
    ;;
  runProgramInGuest)
    [[ "$TEST_INTERACTIVE_MODE" != launch-failure ]]
    ;;
  fileExistsInGuest)
    guest_path=${1:-}
    if [[ "$guest_path" == *.result.json ]]; then
      [[ "$TEST_INTERACTIVE_MODE" == success || "$TEST_INTERACTIVE_MODE" == task-failure || "$TEST_INTERACTIVE_MODE" == cleanup-failure ]]
    elif [[ "$guest_path" == *.started.json ]]; then
      [[ "$TEST_INTERACTIVE_MODE" == timeout ]]
    else
      return 0
    fi
    ;;
  copyFileFromGuestToHost)
    guest_path=${1:-}
    host_path=${2:-}
    if [[ "$guest_path" == *.started.json ]]; then
      print -r -- '{"runner_pid":111,"child_pid":222}' > "$host_path"
    elif [[ "$TEST_INTERACTIVE_MODE" == task-failure ]]; then
      print -r -- '{"status":"error","exit_code":9,"message":"failed"}' > "$host_path"
    else
      print -r -- '{"status":"ok","exit_code":0,"output":"done"}' > "$host_path"
    fi
    ;;
  killProcessInGuest)
    ;;
  deleteFileInGuest)
    [[ "$TEST_INTERACTIVE_MODE" != cleanup-failure ]]
    ;;
  *)
    print -u2 -r -- "unexpected vmrun command: $command_name"
    exit 99
    ;;
esac
STUB
chmod +x "$interactive_dir/windows-vmrun" "$interactive_dir/windows-vm-interactive-run"

: > "$temp_dir/interactive.log"
TEST_INTERACTIVE_MODE=success TEST_INTERACTIVE_LOG="$temp_dir/interactive.log" \
  run_capture 0 "$interactive_dir/windows-vm-interactive-run" --timeout 2 \
  --result "$temp_dir/interactive-result.json" "$payload_dir/small.ps1"
rg -q '"status":"ok"' "$temp_dir/interactive-result.json" || fail 'interactive success result was not retrieved'
rg -q -- '-activeWindow -interactive' "$temp_dir/interactive.log" || fail 'interactive launch flags were omitted'
rg -q 'copyFileFromHostToGuest .* C:\\Temp\\vmware-seed.tmp.task.ps1' "$temp_dir/interactive.log" || fail 'interactive task did not use a PowerShell extension'
rg -q 'deleteFileInGuest C:\\Temp\\vmware-seed.tmp.runner.ps1' "$temp_dir/interactive.log" || fail 'interactive runner file was not cleaned up'

: > "$temp_dir/interactive.log"
TEST_INTERACTIVE_MODE=task-failure TEST_INTERACTIVE_LOG="$temp_dir/interactive.log" \
  run_capture 75 "$interactive_dir/windows-vm-interactive-run" --timeout 2 \
  --result "$temp_dir/interactive-error.json" "$payload_dir/small.ps1"
rg -q '"exit_code":9' "$temp_dir/interactive-error.json" || fail 'interactive task failure result was not preserved'

: > "$temp_dir/interactive.log"
TEST_INTERACTIVE_MODE=missing-desktop TEST_INTERACTIVE_LOG="$temp_dir/interactive.log" \
  run_capture 72 "$interactive_dir/windows-vm-interactive-run" --timeout 2 \
  --result "$temp_dir/interactive-missing.json" "$payload_dir/small.ps1"
rg -q 'interactive_desktop=missing' "$temp_dir/err" || fail 'missing desktop was not reported'
rg -q 'copyFileFromHostToGuest' "$temp_dir/interactive.log" && fail 'missing desktop still copied task files'

: > "$temp_dir/interactive.log"
TEST_INTERACTIVE_MODE=timeout TEST_INTERACTIVE_LOG="$temp_dir/interactive.log" \
  run_capture 124 "$interactive_dir/windows-vm-interactive-run" --timeout 1 \
  --result "$temp_dir/interactive-timeout.json" "$payload_dir/small.ps1"
rg -q 'killProcessInGuest 222' "$temp_dir/interactive.log" || fail 'interactive timeout did not stop the child process'
rg -q 'killProcessInGuest 111' "$temp_dir/interactive.log" || fail 'interactive timeout did not stop the runner process'
rg -q 'interactive_timeout=1s' "$temp_dir/err" || fail 'interactive timeout was not reported'

: > "$temp_dir/interactive.log"
TEST_INTERACTIVE_MODE=guest-ops-failure TEST_INTERACTIVE_LOG="$temp_dir/interactive.log" \
  run_capture 71 "$interactive_dir/windows-vm-interactive-run" --timeout 2 \
  --result "$temp_dir/interactive-guest-ops.json" "$payload_dir/small.ps1"
rg -q 'guest_operations=unavailable' "$temp_dir/err" || fail 'Guest Operations failure was not reported'

: > "$temp_dir/interactive.log"
TEST_INTERACTIVE_MODE=guest-ops-lost TEST_INTERACTIVE_LOG="$temp_dir/interactive.log" \
  TEST_INTERACTIVE_STATE="$temp_dir/interactive-state" \
  run_capture 76 "$interactive_dir/windows-vm-interactive-run" --timeout 1 \
  --result "$temp_dir/interactive-lost.json" "$payload_dir/small.ps1"
rg -q 'guest_operations=lost-during-wait' "$temp_dir/err" || fail 'lost Guest Operations was not reported'
rg -q 'cleanup=unverified' "$temp_dir/err" || fail 'lost Guest Operations did not report unverified cleanup'

: > "$temp_dir/interactive.log"
TEST_INTERACTIVE_MODE=cleanup-failure TEST_INTERACTIVE_LOG="$temp_dir/interactive.log" \
  run_capture 76 "$interactive_dir/windows-vm-interactive-run" --timeout 2 \
  --result "$temp_dir/interactive-cleanup.json" "$payload_dir/small.ps1"
rg -q 'cleanup=unverified' "$temp_dir/err" || fail 'interactive cleanup failure was not reported'

runner_dir="$temp_dir/runner"
mkdir -p "$runner_dir/stub"
cp "$skill_dir/scripts/windows-codex-run" "$runner_dir/"
cat > "$runner_dir/windows-vm-status" <<'STUB'
#!/bin/zsh
print -r -- 'ssh=ok'
print -r -- 'codex=ok'
print -r -- 'codex_path=C:\codex.exe'
print -r -- 'codex_version=codex-cli test'
print -r -- 'codex_policy=ok'
STUB
cat > "$runner_dir/windows-vm-powershell" <<'STUB'
#!/bin/zsh
print -u2 'guest_runner_pid=4321'
case "$TEST_RUNNER_MODE" in
  prompt)
    IFS= read -r prompt || true
    print -r -- "$prompt" > "$TEST_PROMPT_LOG"
    print '{"type":"turn.completed","thread_id":"thread-0"}'
    exit 0
    ;;
  turn-failed)
    print '{"type":"turn.failed","thread_id":"thread-1"}'
    exit 0
    ;;
  approval)
    print '{"type":"approval.requested","thread_id":"thread-2"}'
    sleep 30
    ;;
  timeout)
    sleep 30
    ;;
esac
STUB
cat > "$runner_dir/stub/ssh" <<'STUB'
#!/bin/zsh
print -r -- "$*" >> "$TEST_CLEANUP_LOG"
exit 0
STUB
chmod +x "$runner_dir/windows-vm-status" "$runner_dir/windows-vm-powershell" "$runner_dir/stub/ssh"

: > "$temp_dir/cleanup.log"
print -r -- 'preserve this prompt exactly' > "$temp_dir/prompt.txt"
mkdir "$runner_dir/no-jq"
ln -s /bin/cat "$runner_dir/no-jq/cat"
set +e
PATH="$runner_dir/no-jq" "$runner_dir/windows-codex-run" --cwd 'C:\repo' --timeout 2 \
  < "$temp_dir/prompt.txt" > "$temp_dir/out" 2> "$temp_dir/err"
command_status=$?
set -e
[[ "$command_status" == 69 ]] || fail "missing jq returned $command_status instead of 69"
rg -q 'jq is required to classify Codex events' "$temp_dir/err" || fail 'missing jq was not reported'

TEST_RUNNER_MODE=prompt TEST_PROMPT_LOG="$temp_dir/prompt.log" TEST_CLEANUP_LOG="$temp_dir/cleanup.log" PATH="$runner_dir/stub:$PATH" \
  run_capture_with_input 0 "$temp_dir/prompt.txt" "$runner_dir/windows-codex-run" --cwd 'C:\repo' --timeout 2
[[ "$(<"$temp_dir/prompt.log")" == 'preserve this prompt exactly' ]] || fail 'runner did not preserve prompt stdin'

: > "$temp_dir/cleanup.log"
TEST_RUNNER_MODE=turn-failed TEST_CLEANUP_LOG="$temp_dir/cleanup.log" PATH="$runner_dir/stub:$PATH" \
  run_capture_with_input 75 "$temp_dir/prompt.txt" "$runner_dir/windows-codex-run" --cwd 'C:\repo' --timeout 2
rg -q 'codex=turn-failed' "$temp_dir/err" || fail 'turn.failed event was not classified'

: > "$temp_dir/cleanup.log"
TEST_RUNNER_MODE=approval TEST_CLEANUP_LOG="$temp_dir/cleanup.log" PATH="$runner_dir/stub:$PATH" \
  run_capture_with_input 77 "$temp_dir/prompt.txt" "$runner_dir/windows-codex-run" --cwd 'C:\repo' --timeout 2
rg -q 'taskkill.exe /PID 4321 /T /F' "$temp_dir/cleanup.log" || fail 'approval did not target the guest process tree'
rg -q 'guest_cleanup=ok root_pid=4321' "$temp_dir/err" || fail 'approval cleanup was not reported'

: > "$temp_dir/cleanup.log"
TEST_RUNNER_MODE=timeout TEST_CLEANUP_LOG="$temp_dir/cleanup.log" PATH="$runner_dir/stub:$PATH" \
  run_capture_with_input 124 "$temp_dir/prompt.txt" "$runner_dir/windows-codex-run" --cwd 'C:\repo' --timeout 1
rg -q 'taskkill.exe /PID 4321 /T /F' "$temp_dir/cleanup.log" || fail 'timeout did not target the guest process tree'
rg -q 'codex_timeout=1s' "$temp_dir/err" || fail 'timeout was not reported'

print 'host regressions: ok'
