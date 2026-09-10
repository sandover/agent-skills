"""Host transport contract; real job termination is tested on Windows separately."""
import base64
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SSH = '''#!/usr/bin/env python3
import base64, os, sys
source=base64.b64decode(sys.argv[-1].split()[-1]).decode('utf-16le')
if 'Out.Write($env:TEMP)' in source:
 print(r'C:\\Temp'); sys.exit(0)
if 'Remove-Item' in source:
 sys.exit(int(os.environ.get('CLEANUP_EXIT','0')))
assert '-ExecutionPolicy Bypass' in sys.argv[-1]
assert '-OutputFormat Text' in sys.argv[-1]
print(sys.stdin.read(),end='')
sys.exit(int(os.environ.get('TASK_EXIT','0')))
'''
SCP = '''#!/usr/bin/env python3
from pathlib import Path
import os,sys
p=Path(sys.argv[-2])
if p.name=='task.ps1':
 data=p.read_bytes(); assert data.startswith(b'\\xef\\xbb\\xbf')
 Path(os.environ['COPIED']).write_bytes(data)
sys.exit(int(os.environ.get('TRANSFER_EXIT','0')))
'''

class TransportTests(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
  self.root=Path(self.temp.name);self.script=self.root/'task.ps1';self.copied=self.root/'copied'
  for name,source in [('ssh',SSH),('scp',SCP)]:
   p=self.root/name;p.write_text(source);p.chmod(0o755)
  self.env=dict(os.environ,PATH=str(self.root)+os.pathsep+os.environ['PATH'],COPIED=str(self.copied),WINDOWS_VM_CONTROL_CONFIG=str(self.root/'absent.json'))
  self.helper=Path(__file__).resolve().parents[1]/'scripts/windows-vm-powershell'
 def run_task(self,source,**env):
  self.script.write_bytes(source)
  return subprocess.run([str(self.helper),str(self.script)],input='stdin sentinel\n',text=True,capture_output=True,env=dict(self.env,**env))
 def test_bom_and_non_bom_small_and_large_are_normalized(self):
  for prefix in [b'',b'\xef\xbb\xbf']:
   for padding in ['', '# padding\n'*2000]:
    body=("Write-Output 'café'\n"+padding).encode()
    r=self.run_task(prefix+body)
    self.assertEqual(r.returncode,0,r.stderr)
    self.assertEqual(r.stdout,'stdin sentinel\n')
    self.assertEqual(self.copied.read_bytes(),b'\xef\xbb\xbf'+body)
 def test_native_exit_status_survives_cleanup(self):
  r=self.run_task(b'exit 37',TASK_EXIT='37');self.assertEqual(r.returncode,37)
 def test_guest_timeout_survives_cleanup(self):
  r=self.run_task(b'Start-Sleep 5',TASK_EXIT='124');self.assertEqual(r.returncode,124)
 def test_cleanup_failure_overrides_success(self):
  r=self.run_task(b'exit 0',CLEANUP_EXIT='1');self.assertEqual(r.returncode,76)
 def test_transfer_failure_does_not_launch_task(self):
  r=self.run_task(b'exit 0',TRANSFER_EXIT='9');self.assertEqual(r.returncode,9)
 def test_invalid_utf8_never_reaches_guest(self):
  r=self.run_task(b'\xff');self.assertEqual(r.returncode,65);self.assertFalse(self.copied.exists())

if __name__=='__main__':unittest.main()
