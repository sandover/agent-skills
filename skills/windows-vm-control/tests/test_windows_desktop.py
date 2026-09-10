"""Verify desktop requests remain data and malformed selectors never launch a guest task."""
import base64
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SCRIPTS=Path(__file__).resolve().parents[1]/'scripts'
STUB='''#!/usr/bin/env python3
import base64,json,sys
from pathlib import Path
line=Path(sys.argv[-1]).read_text(encoding='utf-8-sig').splitlines()[0]
request=json.loads(base64.b64decode(line.split("'")[1]))
Path(sys.argv[sys.argv.index('--result')+1]).write_text(json.dumps(dict(status='ok',exit_code=0,output=json.dumps(request))))
'''
class DesktopTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory(); self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        for name in ('windows-vm-desktop','desktop.ps1'): shutil.copy(SCRIPTS/name,self.root/name)
        helper=self.root/'windows-vm-interactive-run'; helper.write_text(STUB); helper.chmod(0o755)
    def test_unicode_and_shell_characters_are_literal_data(self):
        value="café '$env:USER' `calc` $(whoami)\nsecond line"
        result=subprocess.run([str(self.root/'windows-vm-desktop'),'set-value','--window','42','--pid','7','--name',"user's field",'--value',value],capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stderr)
        request=json.loads(json.loads(result.stdout)['output'])
        self.assertEqual(request['value'],value)
        self.assertEqual(request['name'],"user's field")
    def test_incomplete_action_is_rejected_before_execution(self):
        for arguments in (['controls','--window','42','--pid','7','--limit','0'],['invoke'],['invoke','--window','42','--pid','7'],['set-value','--window','42','--pid','7','--name','x']):
            result=subprocess.run([str(self.root/'windows-vm-desktop'),*arguments],capture_output=True)
            self.assertEqual(result.returncode,2)
            self.assertEqual(result.stdout,b'')

if __name__=='__main__': unittest.main()
