#!/usr/bin/env -S uv run --script
# Exercise the managed Windows Codex controller without VMware or network access.
# Stub readiness and SSH while preserving the app-server JSONL request flow.
# Cover new and resumed threads, terminal authority, steering, and interruption.
# Cover approval and user-input response correlation by exact request ID.
# Prove malformed or lost transports leave active work unknown, never successful.
# Prove signals, configured host selection, and old turn history remain predictable.
# Keep every fixture in one temporary directory and remove it after each test.

from __future__ import annotations

import json
import os
import signal
import shutil
import subprocess
import tempfile
import time
import unittest
from pathlib import Path


STUB_SSH = r'''#!/usr/bin/env python3
import json
import os
import sys

mode = os.environ.get("TEST_APP_SERVER_MODE", "complete")
turn_id = os.environ.get("TEST_TURN_ID", "turn-1")
resumed_status = os.environ.get("TEST_RESUMED_STATUS", "completed")
log_path = os.environ["TEST_APP_SERVER_LOG"]

def emit(value):
    print(json.dumps(value, separators=(",", ":")), flush=True)

def log(value):
    with open(log_path, "a", encoding="utf-8") as handle:
        handle.write(json.dumps(value, separators=(",", ":")) + "\n")

def complete(status="completed"):
    emit({"method":"turn/completed","params":{"threadId":"thread-1","turn":{"id":turn_id,"status":status,"items":[]}}})

for raw in sys.stdin:
    message = json.loads(raw)
    log(message)
    method = message.get("method")
    request_id = message.get("id")
    if mode == "lost_initialize" and method == "initialize":
        sys.exit(9)
    if mode == "lost_turn_start" and method == "turn/start":
        sys.exit(9)
    if method == "initialize":
        emit({"id":request_id,"result":{"userAgent":"stub","platformFamily":"windows","platformOs":"windows"}})
    elif method == "initialized":
        continue
    elif method == "thread/start":
        emit({"id":request_id,"result":{"thread":{"id":"thread-1","status":{"type":"idle"},"turns":[]}}})
        emit({"method":"thread/started","params":{"thread":{"id":"thread-1"}}})
    elif method == "thread/resume":
        emit({"id":request_id,"result":{"thread":{"id":"thread-1","status":{"type":"idle"},"turns":[{"id":"turn-old","status":resumed_status,"items":[]}]}}})
    elif method == "turn/start":
        request_before_response = mode in {"approval", "input", "unsupported"}
        if not request_before_response:
            emit({"id":request_id,"result":{"turn":{"id":turn_id,"status":"inProgress","items":[]}}})
        emit({"method":"turn/started","params":{"threadId":"thread-1","turn":{"id":turn_id,"status":"inProgress","items":[]}}})
        if mode == "lost":
            sys.exit(9)
        if mode == "malformed":
            print("not-json", flush=True)
            sys.exit(0)
        if mode == "approval":
            emit({"method":"item/started","params":{"threadId":"thread-1","turnId":turn_id,"startedAtMs":1,"item":{"id":"item-1","type":"commandExecution","status":"inProgress","command":"git pull","cwd":"C:\\repo"}}})
            emit({"id":91,"method":"item/commandExecution/requestApproval","params":{"threadId":"thread-1","turnId":turn_id,"itemId":"item-1","startedAtMs":1}})
        elif mode == "input":
            emit({"id":"question-1","method":"item/tool/requestUserInput","params":{"threadId":"thread-1","turnId":turn_id,"itemId":"item-2","isBlocking":True,"questions":[]}})
        elif mode == "unsupported":
            emit({"id":92,"method":"account/chatgptAuthTokens/refresh","params":{"reason":"unauthorized"}})
        elif mode == "steer":
            continue
        else:
            emit({"method":"item/commandExecution/outputDelta","params":{"threadId":"thread-1","turnId":turn_id,"itemId":"item-1","delta":"ok\\n"}})
            emit({"method":"item/completed","params":{"threadId":"thread-1","turnId":turn_id,"completedAtMs":2,"item":{"id":"item-1","type":"commandExecution","status":"completed","exitCode":0,"aggregatedOutput":"ok\\n"}}})
            if mode == "failed":
                emit({"method":"error","params":{"threadId":"thread-1","turnId":turn_id,"willRetry":False,"error":{"message":"failed"}}})
                complete("failed")
            else:
                complete()
        if request_before_response:
            emit({"id":request_id,"result":{"turn":{"id":turn_id,"status":"inProgress","items":[]}}})
    elif method == "turn/steer":
        emit({"id":request_id,"result":{"turnId":turn_id}})
    elif method == "turn/interrupt":
        emit({"id":request_id,"result":{}})
        complete("interrupted")
    elif method == "thread/unsubscribe":
        emit({"id":request_id,"result":{}})
    elif method is None and request_id == 91:
        emit({"method":"serverRequest/resolved","params":{"threadId":"thread-1","requestId":91}})
        emit({"method":"item/completed","params":{"threadId":"thread-1","turnId":turn_id,"completedAtMs":3,"item":{"id":"item-1","type":"commandExecution","status":"completed","exitCode":0}}})
        complete()
    elif method is None and request_id == "question-1":
        emit({"method":"serverRequest/resolved","params":{"threadId":"thread-1","requestId":"question-1"}})
        complete()
    elif method is None and request_id == 92 and "error" in message:
        emit({"method":"serverRequest/resolved","params":{"threadId":"thread-1","requestId":92}})
        complete()
'''


class ControllerTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="windows-codex-session-test.")
        self.root = Path(self.temp.name)
        self.scripts = self.root / "scripts"
        self.bin = self.root / "bin"
        self.scripts.mkdir()
        self.bin.mkdir()
        source = Path(__file__).resolve().parents[1] / "scripts" / "windows-codex-session"
        shutil.copy2(source, self.scripts / "windows-codex-session")
        status = self.scripts / "windows-vm-status"
        status.write_text(
            "#!/bin/zsh\nread -r _discarded || true\nprint 'ssh=ok'\nprint 'codex=ok'\nprint 'codex_path=C:\\\\codex.exe'\nprint 'codex_version=codex-cli stub'\nprint 'codex_policy=ok'\n",
            encoding="utf-8",
        )
        status.chmod(0o755)
        ssh = self.bin / "ssh"
        ssh.write_text(STUB_SSH, encoding="utf-8")
        ssh.chmod(0o755)
        self.state = self.root / "state.json"
        self.handoff = self.root / "handoff.txt"
        self.handoff.write_text("Complete the delegated test task.", encoding="utf-8")
        self.log = self.root / "app-server.log"
        self.config = self.root / "config.json"
        self.config.write_text('{"ssh_alias":"configured-vm"}\n', encoding="utf-8")

    def tearDown(self) -> None:
        self.temp.cleanup()

    def controller_command(self, *, handoff: bool, start_new: bool = False) -> list[str]:
        command = [
            str(self.scripts / "windows-codex-session"),
            "--cwd",
            r"C:\repo",
            "--state",
            str(self.state),
            "--rpc-timeout",
            "2",
        ]
        if handoff:
            command.extend(["--handoff", str(self.handoff)])
        if start_new:
            command.append("--new")
        return command

    def controller_environment(
        self,
        mode: str,
        *,
        turn_id: str = "turn-1",
        resumed_status: str = "completed",
    ) -> dict[str, str]:
        environment = os.environ.copy()
        environment.pop("WINDOWS_VM_SSH_ALIAS", None)
        environment.update(
            {
                "PATH": str(self.bin) + os.pathsep + environment.get("PATH", ""),
                "WINDOWS_VM_CONTROL_CONFIG": str(self.config),
                "TEST_APP_SERVER_MODE": mode,
                "TEST_APP_SERVER_LOG": str(self.log),
                "TEST_TURN_ID": turn_id,
                "TEST_RESUMED_STATUS": resumed_status,
            }
        )
        return environment

    def run_controller(
        self,
        mode: str,
        actions: list[dict] | None = None,
        *,
        handoff: bool = True,
        turn_id: str = "turn-1",
        start_new: bool = False,
        resumed_status: str = "completed",
    ) -> subprocess.CompletedProcess[str]:
        input_text = "".join(json.dumps(action) + "\n" for action in actions or [])
        return subprocess.run(
            self.controller_command(handoff=handoff, start_new=start_new),
            input=input_text,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=self.controller_environment(
                mode,
                turn_id=turn_id,
                resumed_status=resumed_status,
            ),
            timeout=10,
            check=False,
        )

    def messages(self, result: subprocess.CompletedProcess[str]) -> list[dict]:
        return [json.loads(line) for line in result.stdout.splitlines() if line.startswith("{")]

    def logged_methods(self) -> list[str | None]:
        return [json.loads(line).get("method") for line in self.log.read_text(encoding="utf-8").splitlines()]

    def test_completed_turn_uses_authoritative_item_and_turn(self) -> None:
        result = self.run_controller("complete")
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        state = json.loads(self.state.read_text(encoding="utf-8"))
        self.assertEqual(state["turnStatus"], "completed")
        self.assertEqual(state["lastItem"], {"id": "item-1", "type": "commandExecution", "status": "completed"})
        self.assertIsNone(state["activeTurnId"])
        self.assertEqual(state["sshHost"], "configured-vm")
        self.assertNotIn("Complete the delegated test task.", self.state.read_text(encoding="utf-8"))
        self.assertIn("thread/unsubscribe", self.logged_methods())
        self.assertIn("item/completed", [message.get("method") for message in self.messages(result)])

    def test_existing_state_resumes_same_thread(self) -> None:
        first = self.run_controller("complete", turn_id="turn-1")
        self.assertEqual(first.returncode, 0, first.stderr + first.stdout)
        self.log.write_text("", encoding="utf-8")
        second = self.run_controller(
            "complete",
            [{"action": "start", "text": "Run the follow-up."}],
            handoff=False,
            turn_id="turn-2",
        )
        self.assertEqual(second.returncode, 0, second.stderr + second.stdout)
        methods = self.logged_methods()
        self.assertIn("thread/resume", methods)
        self.assertNotIn("thread/read", methods)
        self.assertNotIn("thread/start", methods)
        self.assertEqual(json.loads(self.state.read_text(encoding="utf-8"))["lastTurnId"], "turn-2")

    def test_status_action_reports_state_before_close(self) -> None:
        first = self.run_controller("complete")
        self.assertEqual(first.returncode, 0, first.stderr + first.stdout)
        second = self.run_controller(
            "complete",
            [{"action": "status"}, {"action": "close"}],
            handoff=False,
        )
        self.assertEqual(second.returncode, 0, second.stderr + second.stdout)
        status = next(
            message for message in self.messages(second) if message.get("method") == "controller/status"
        )
        self.assertEqual(status["params"]["threadId"], "thread-1")
        self.assertEqual(status["params"]["turnStatus"], "completed")

    def test_approval_response_uses_exact_request_id(self) -> None:
        result = self.run_controller(
            "approval",
            [{"action": "respond", "requestId": 91, "result": {"decision": "accept"}}],
        )
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        logged = [json.loads(line) for line in self.log.read_text(encoding="utf-8").splitlines()]
        self.assertIn({"id": 91, "result": {"decision": "accept"}}, logged)
        self.assertEqual(json.loads(self.state.read_text(encoding="utf-8"))["pendingRequests"], [])

    def test_user_input_response_accepts_string_request_id(self) -> None:
        result = self.run_controller(
            "input",
            [{"action": "respond", "requestId": "question-1", "result": {"answers": {"q": "continue"}}}],
        )
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        logged = [json.loads(line) for line in self.log.read_text(encoding="utf-8").splitlines()]
        self.assertIn({"id": "question-1", "result": {"answers": {"q": "continue"}}}, logged)

    def test_unfamiliar_request_accepts_json_rpc_error(self) -> None:
        error = {"code": -32000, "message": "This controller cannot provide authentication tokens."}
        result = self.run_controller(
            "unsupported",
            [{"action": "respond", "requestId": 92, "error": error}],
        )
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        logged = [json.loads(line) for line in self.log.read_text(encoding="utf-8").splitlines()]
        self.assertIn({"id": 92, "error": error}, logged)

    def test_steer_then_interrupt_targets_active_turn(self) -> None:
        result = self.run_controller(
            "steer",
            [
                {"action": "steer", "text": "Run the narrow test first."},
                {"action": "interrupt"},
            ],
        )
        self.assertEqual(result.returncode, 130, result.stderr + result.stdout)
        logged = [json.loads(line) for line in self.log.read_text(encoding="utf-8").splitlines()]
        steer = next(message for message in logged if message.get("method") == "turn/steer")
        self.assertEqual(steer["params"]["expectedTurnId"], "turn-1")
        self.assertIn("turn/interrupt", self.logged_methods())

    def test_failed_turn_returns_failure(self) -> None:
        result = self.run_controller("failed")
        self.assertEqual(result.returncode, 75, result.stderr + result.stdout)
        self.assertEqual(json.loads(self.state.read_text(encoding="utf-8"))["turnStatus"], "failed")

    def test_connection_loss_marks_active_turn_unknown(self) -> None:
        result = self.run_controller("lost")
        self.assertEqual(result.returncode, 76, result.stderr + result.stdout)
        state = json.loads(self.state.read_text(encoding="utf-8"))
        self.assertEqual(state["connectionStatus"], "lost")
        self.assertEqual(state["turnStatus"], "unknown")
        self.assertTrue(any(message.get("method") == "controller/transportLost" for message in self.messages(result)))

    def test_connection_loss_before_initialize_response_is_transport_loss(self) -> None:
        result = self.run_controller("lost_initialize")
        self.assertEqual(result.returncode, 76, result.stderr + result.stdout)
        self.assertEqual(json.loads(self.state.read_text(encoding="utf-8"))["connectionStatus"], "lost")

    def test_connection_loss_before_turn_start_response_is_unknown(self) -> None:
        result = self.run_controller("lost_turn_start")
        self.assertEqual(result.returncode, 76, result.stderr + result.stdout)
        state = json.loads(self.state.read_text(encoding="utf-8"))
        self.assertEqual(state["connectionStatus"], "lost")
        self.assertEqual(state["turnStatus"], "unknown")

    def test_resumed_failed_history_does_not_fail_current_session(self) -> None:
        first = self.run_controller("complete")
        self.assertEqual(first.returncode, 0, first.stderr + first.stdout)
        second = self.run_controller(
            "complete",
            [{"action": "close"}],
            handoff=False,
            resumed_status="failed",
        )
        self.assertEqual(second.returncode, 0, second.stderr + second.stdout)

    def test_sigterm_during_active_turn_exits_without_hanging(self) -> None:
        process = subprocess.Popen(
            self.controller_command(handoff=True),
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            env=self.controller_environment("steer"),
        )
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            if self.state.exists():
                state = json.loads(self.state.read_text(encoding="utf-8"))
                if state.get("activeTurnId"):
                    break
            time.sleep(0.05)
        else:
            process.kill()
            self.fail("controller did not start an active turn")
        process.send_signal(signal.SIGTERM)
        stdout, stderr = process.communicate(timeout=5)
        self.assertEqual(process.returncode, 130, stderr + stdout)
        self.assertEqual(json.loads(self.state.read_text(encoding="utf-8"))["turnStatus"], "unknown")

    def test_malformed_server_output_is_transport_failure(self) -> None:
        result = self.run_controller("malformed")
        self.assertEqual(result.returncode, 76, result.stderr + result.stdout)
        self.assertTrue(any(message.get("method") == "controller/protocolError" for message in self.messages(result)))


if __name__ == "__main__":
    unittest.main()
