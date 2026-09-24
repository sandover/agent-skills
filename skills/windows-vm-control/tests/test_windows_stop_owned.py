#!/usr/bin/env python3
"""Exercise the host stop wrapper with stubbed PowerShell and vmrun."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


SKILL = Path(__file__).resolve().parents[1]
HELPER = SKILL / 'scripts' / 'windows-vm-stop-owned'


VMRUN_STUB = r'''#!/usr/bin/env python3
import base64, json, os, re, sys
from pathlib import Path

args = sys.argv[1:]
command = args[0] if args else ''
with open(os.environ['VMRUN_LOG'], 'a') as log:
    log.write(json.dumps(args) + '\n')

def record_request(script):
    match = re.search(r"^\$requestBase64='([^']+)'$", script, re.M)
    if not match:
        raise SystemExit('stop request missing')
    request = json.loads(base64.b64decode(match.group(1)).decode('utf-8'))
    with open(os.environ['REQUEST_LOG'], 'a') as log:
        log.write(json.dumps(request, separators=(',', ':')) + '\n')
    return request

if command == 'createTempFileInGuest':
    print(r'C:\Temp\windows-stop-result.json')
elif command == 'runProgramInGuest':
    try:
        encoded = args[args.index('-EncodedCommand') + 1]
        script = base64.b64decode(encoded).decode('utf-16le')
        request = record_request(script)
    except (ValueError, IndexError) as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(98)
    status = os.environ.get('STOP_RESULT_STATUS', 'stopped')
    result = {'status': status, 'pid': request['pid']}
    Path(os.environ['GUEST_RESULT_FILE']).write_text(json.dumps(result))
    raise SystemExit(int(os.environ.get('VM_LAUNCH_CODE', '0')))
elif command == 'copyFileFromGuestToHost':
    if os.environ.get('VM_COPY_FAIL') == '1':
        raise SystemExit(1)
    Path(args[2]).write_text(Path(os.environ['GUEST_RESULT_FILE']).read_text())
elif command == 'deleteFileInGuest':
    raise SystemExit(int(os.environ.get('VM_DELETE_CODE', '0')))
else:
    print('unexpected vmrun command: ' + command, file=sys.stderr)
    raise SystemExit(99)
'''


POWERSHELL_STUB = r'''#!/usr/bin/env python3
import base64, json, os, re, sys
from pathlib import Path

args = sys.argv[1:]
with open(os.environ['POWERSHELL_LOG'], 'a') as log:
    log.write(json.dumps(args) + '\n')
script = Path(args[-1]).read_text(encoding='utf-8-sig')
match = re.search(r"^\$requestBase64='([^']+)'$", script, re.M)
if not match:
    print('stop request missing', file=sys.stderr)
    raise SystemExit(98)
request = json.loads(base64.b64decode(match.group(1)).decode('utf-8'))
with open(os.environ['REQUEST_LOG'], 'a') as log:
    log.write(json.dumps(request, separators=(',', ':')) + '\n')
status = os.environ.get('STOP_RESULT_STATUS', 'stopped')
print(json.dumps({'status': status, 'pid': request['pid']}))
raise SystemExit(0 if status == 'stopped' else 76)
'''


class StopOwnedTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='windows-stop-owned-test-')
        self.root = Path(self.temp.name)
        self.scripts = self.root / 'scripts'
        self.scripts.mkdir()
        shutil.copy2(HELPER, self.scripts / HELPER.name)
        shutil.copy2(SKILL / 'scripts' / 'stop-owned-process.ps1', self.scripts)
        self.vmrun = self.scripts / 'windows-vmrun'
        self.vmrun.write_text(VMRUN_STUB)
        self.vmrun.chmod(0o755)
        self.powershell = self.scripts / 'windows-vm-powershell'
        self.powershell.write_text(POWERSHELL_STUB)
        self.powershell.chmod(0o755)
        self.identity = self.root / 'identity.json'
        self.request_log = self.root / 'requests.jsonl'
        self.vmrun_log = self.root / 'vmrun.jsonl'
        self.powershell_log = self.root / 'powershell.jsonl'
        self.guest_result = self.root / 'guest-result.json'
        self.env = os.environ.copy()
        self.env.update({
            'REQUEST_LOG': str(self.request_log),
            'VMRUN_LOG': str(self.vmrun_log),
            'POWERSHELL_LOG': str(self.powershell_log),
            'GUEST_RESULT_FILE': str(self.guest_result),
        })

    def tearDown(self):
        self.temp.cleanup()

    def write_identity(self, value=None):
        if value is None:
            value = {'pid': 4321, 'created': '2026-09-24T18:30:00.0000000Z', 'computer': 'TEST-WIN'}
        self.identity.write_text(json.dumps(value))

    def run_helper(self, *args, env=None):
        return subprocess.run(
            [str(self.scripts / HELPER.name), *args],
            capture_output=True, text=True, timeout=10,
            env=self.env | (env or {}),
        )

    def read_json_lines(self, path):
        if not path.exists():
            return []
        return [json.loads(line) for line in path.read_text().splitlines()]

    def assert_unknown(self, result):
        self.assertEqual(result.returncode, 76, result.stderr)
        self.assertEqual(json.loads(result.stdout)['status'], 'unknown')

    def test_missing_or_malformed_identity_stops_before_any_remote_call(self):
        result = self.run_helper('--guest-ops', str(self.root / 'missing.json'))
        self.assert_unknown(result)
        self.assertFalse(self.vmrun_log.exists())

        for value in (
            'not json',
            json.dumps({'pid': True, 'created': 'time', 'computer': 'TEST-WIN'}),
            json.dumps({'pid': 4321, 'created': '', 'computer': 'TEST-WIN'}),
            json.dumps({'pid': 4321, 'created': 'time'}),
        ):
            with self.subTest(value=value):
                self.identity.write_text(value)
                result = self.run_helper('--guest-ops', str(self.identity))
                self.assert_unknown(result)
                self.assertFalse(self.vmrun_log.exists())

    def test_ssh_route_passes_full_identity_and_keeps_mismatch_unknown(self):
        self.write_identity()
        result = self.run_helper('--ssh', 'windows-vm', str(self.identity),
                                 env={'STOP_RESULT_STATUS': 'unknown'})
        self.assert_unknown(result)
        self.assertEqual(self.read_json_lines(self.request_log), [{
            'pid': 4321,
            'created': '2026-09-24T18:30:00.0000000Z',
            'computer': 'TEST-WIN',
        }])
        invocation = self.read_json_lines(self.powershell_log)[0]
        self.assertEqual(invocation[:4], ['--ssh', 'windows-vm', '--timeout', '20'])
        self.assertFalse(self.vmrun_log.exists())

    def test_guest_ops_reads_explicit_result_and_cleans_result_file(self):
        self.write_identity()
        result = self.run_helper('--guest-ops', str(self.identity), env={
            'STOP_RESULT_STATUS': 'stopped',
            # The guest launch may report a nonzero exit even when its explicit result proves success.
            'VM_LAUNCH_CODE': '76',
        })
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)['status'], 'stopped')
        calls = self.read_json_lines(self.vmrun_log)
        self.assertEqual([call[0] for call in calls], [
            'createTempFileInGuest', 'runProgramInGuest',
            'copyFileFromGuestToHost', 'deleteFileInGuest',
        ])
        request = self.read_json_lines(self.request_log)[0]
        self.assertEqual(request['pid'], 4321)
        self.assertEqual(request['created'], '2026-09-24T18:30:00.0000000Z')
        self.assertEqual(request['computer'], 'TEST-WIN')
        self.assertEqual(request['result_path'], r'C:\Temp\windows-stop-result.json')

    def test_guest_ops_mismatch_or_result_cleanup_failure_returns_76(self):
        self.write_identity()
        mismatch = self.run_helper('--guest-ops', str(self.identity),
                                   env={'STOP_RESULT_STATUS': 'unknown', 'VM_LAUNCH_CODE': '76'})
        self.assert_unknown(mismatch)
        self.assertEqual(self.read_json_lines(self.vmrun_log)[-1][0], 'deleteFileInGuest')

        self.vmrun_log.unlink()
        self.request_log.unlink()
        cleanup = self.run_helper('--guest-ops', str(self.identity),
                                  env={'STOP_RESULT_STATUS': 'stopped', 'VM_DELETE_CODE': '1'})
        self.assertEqual(cleanup.returncode, 76)
        self.assertEqual(json.loads(cleanup.stdout)['status'], 'stopped')
        self.assertIn('cleanup=unverified', cleanup.stderr)


if __name__ == '__main__':
    unittest.main()
