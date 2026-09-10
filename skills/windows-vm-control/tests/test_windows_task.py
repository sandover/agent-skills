"""Exercise wrapper streaming, durable uncertainty, and process identity through stub helpers."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1]/'scripts/windows-vm-task'
STUB = '''#!/usr/bin/env python3
import json,os,sys,time
print('raw-output',end='' if os.environ.get('WAIT') else '\\n',flush=True)
if os.environ.get('EVENT'):
 print('windows_task='+json.dumps(dict(event='completed',exit_code=int(os.environ['CODE']))),file=sys.stderr,flush=True)
if os.environ.get('WAIT'): time.sleep(10)
sys.exit(int(os.environ.get('CODE','0')))
'''

class TaskTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory(); self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        self.tool=self.root/'windows-vm-task'; shutil.copy(SCRIPT,self.tool)
        helper=self.root/'windows-vm-powershell'; helper.write_text(STUB); helper.chmod(0o755)
        self.record=self.root/'record'
        ps=self.root/'ps'; ps.write_text('#!/bin/sh\necho stable-test-process-start\n'); ps.chmod(0o755)
        self.env=dict(os.environ,PATH=str(self.root)+os.pathsep+os.environ['PATH'])
    def run_task(self, **env):
        result=subprocess.run([str(self.tool),'run','--record',str(self.record),'powershell'],
            capture_output=True,text=True,env=dict(self.env,**env))
        return result,json.loads((self.record/'result.json').read_text())
    def test_streams_and_private_record(self):
        result,record=self.run_task()
        self.assertEqual(result.stdout,'raw-output\n')
        self.assertEqual(record['completion'],'confirmed')
        self.assertEqual((self.record/'stdout.log').read_text(),result.stdout)
        self.assertEqual((self.record/'result.json').stat().st_mode & 0o777,0o600)
        self.assertEqual(self.record.stat().st_mode & 0o777,0o700)
    def test_uncertain_transport_overrides_terminal_event(self):
        result,record=self.run_task(CODE='76',EVENT='1')
        self.assertEqual(record['completion'],'unknown')
        self.assertEqual(record['cleanup'],'unknown')
    def test_task_exit_and_timeout_have_evidence(self):
        for code in (37,124):
            with self.subTest(code=code):
                if self.record.exists(): shutil.rmtree(self.record)
                result,record=self.run_task(CODE=str(code),EVENT='1')
                self.assertEqual(result.returncode,code)
                self.assertEqual(record['completion'],'confirmed')
                self.assertEqual(record['state'],'timed_out' if code==124 else 'failed')
    def test_nonzero_without_execution_evidence_is_uncertain(self):
        _,record=self.run_task(CODE='75')
        self.assertEqual(record['completion'],'unknown')
    def test_existing_record_is_never_overwritten(self):
        _,record=self.run_task()
        before=(self.record/'result.json').read_bytes()
        result=subprocess.run([str(self.tool),'run','--record',str(self.record),'powershell'],capture_output=True)
        self.assertNotEqual(result.returncode,0)
        self.assertEqual((self.record/'result.json').read_bytes(),before)
    def test_orphaned_host_is_not_success(self):
        _,record=self.run_task()
        record.update(state='running',host=dict(pid=os.getpid(),started='wrong identity'))
        (self.record/'result.json').write_text(json.dumps(record))
        result=subprocess.run([str(self.tool),'status',str(self.record)],capture_output=True,text=True)
        self.assertEqual(json.loads(result.stdout)['state'],'unknown')
    def test_record_directory_is_automatic(self):
        result=subprocess.run([str(self.tool),'run','powershell'],capture_output=True,text=True,
            env=dict(self.env,TMPDIR=str(self.root)))
        self.assertEqual(result.returncode,0,result.stderr)
        record_path=Path(result.stderr.strip().split('task_record=')[-1])
        self.assertTrue(record_path.is_file())
        self.assertEqual(json.loads(record_path.read_text())['state'],'succeeded')

    def test_managed_stdin_and_state_are_preserved(self):
        helper=self.root/'windows-codex-session'
        helper.write_text("#!/usr/bin/env python3\nimport sys\nsys.stdout.write(sys.stdin.read())\n")
        helper.chmod(0o755)
        state=self.root/'controller.json';state.write_text(json.dumps(dict(turnStatus='completed')))
        action='{"action":"close"}\n'
        result=subprocess.run([str(self.tool),'run','--record',str(self.record),'managed','--state',str(state)],
            input=action,capture_output=True,text=True,env=self.env)
        self.assertEqual(result.stdout,action)
        record=json.loads((self.record/'result.json').read_text())
        self.assertEqual(record['completion'],'controller_closed')
        snapshot=subprocess.run([str(self.tool),'status',str(self.record)],capture_output=True,text=True,env=self.env)
        self.assertEqual(json.loads(snapshot.stdout)['controller']['turnStatus'],'completed')

    def test_running_status_and_incremental_record(self):
        process=subprocess.Popen([str(self.tool),'run','--record',str(self.record),'powershell'],
            env=dict(self.env,WAIT='1'),stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
        try:
            import time
            deadline=time.monotonic()+3
            while time.monotonic()<deadline:
                if (self.record/'stdout.log').exists() and (self.record/'stdout.log').read_bytes(): break
                time.sleep(.02)
            self.assertEqual((self.record/'stdout.log').read_bytes(),b'raw-output')
            result=subprocess.run([str(self.tool),'status',str(self.record)],capture_output=True,text=True,env=self.env)
            record=json.loads(result.stdout)
            self.assertTrue(record['host_alive'])
            self.assertEqual(record['state'],'running')
        finally:
            process.terminate();process.wait(timeout=5)

if __name__=='__main__': unittest.main()
