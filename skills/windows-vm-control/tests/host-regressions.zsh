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

payload_dir="$temp_dir/payload"
mkdir -p "$payload_dir/stub"
cp "$skill_dir/scripts/windows-vm-powershell" "$payload_dir/"
cat > "$payload_dir/stub/ssh" <<'STUB'
#!/bin/zsh
print called > "$TEST_SSH_MARKER"
exit 0
STUB
chmod +x "$payload_dir/stub/ssh"
perl -e 'print "# x\n" x 1500' > "$payload_dir/large.ps1"
TEST_SSH_MARKER="$temp_dir/ssh-called" PATH="$payload_dir/stub:$PATH" \
  run_capture 65 "$payload_dir/windows-vm-powershell" "$payload_dir/large.ps1"
[[ ! -e "$temp_dir/ssh-called" ]] || fail 'oversized payload connected before rejection'
rg -q 'encoded characters' "$temp_dir/err" || fail 'oversized payload diagnostic was not specific'

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
