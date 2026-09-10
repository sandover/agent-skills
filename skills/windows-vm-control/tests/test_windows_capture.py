import importlib.machinery
import importlib.util
from pathlib import Path
import struct
import os
import shutil
import subprocess
import tempfile
import unittest
import zlib

loader=importlib.machinery.SourceFileLoader('capture',str(Path(__file__).resolve().parents[1]/'scripts/windows-vm-capture'))
spec=importlib.util.spec_from_loader(loader.name,loader)
capture=importlib.util.module_from_spec(spec)
loader.exec_module(capture)

def chunk(kind,data):return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data))
def png(rgb):
 return b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',2,2,8,2,0,0,0))+chunk(b'IDAT',zlib.compress((b'\0'+bytes(rgb)*2)*2))+chunk(b'IEND',b'')
class CaptureTests(unittest.TestCase):
 def test_black_is_rejected_and_visible_pixels_accepted(self):
  with tempfile.TemporaryDirectory() as tmp:
   p=Path(tmp)/'test.png'
   p.write_bytes(png([0,0,0]));self.assertFalse(capture.usable_png(p))
   p.write_bytes(png([20,40,60]));self.assertTrue(capture.usable_png(p))
 def test_non_image_rejected(self):
  with tempfile.TemporaryDirectory() as tmp:
   p=Path(tmp)/'test.png';p.write_bytes(b'not png');self.assertFalse(capture.usable_png(p))
   p.write_bytes(b'\x89PNG\r\n\x1a\n');self.assertFalse(capture.usable_png(p))
 def test_fallback_preserves_cleanup_uncertainty_and_metadata(self):
  with tempfile.TemporaryDirectory() as tmp:
   root=Path(tmp)
   helper=root/'windows-vm-capture';shutil.copy(Path(capture.__file__),helper)
   vmrun=root/'windows-vmrun'
   vmrun.write_text("#!/bin/sh\nif [ \"$1\" = createTempFileInGuest ]; then echo 'C:\\\\Temp\\\\capture'; fi\nexit 0\n")
   vmrun.chmod(0o755)
   interactive=root/'windows-vm-interactive-run'
   interactive.write_text("#!/bin/sh\necho 'windows_task={\"event\":\"started\",\"pid\":42}' >&2\nexit 76\n")
   interactive.chmod(0o755)
   result=subprocess.run([str(helper),str(root/'image.png')],capture_output=True,text=True,env=dict(os.environ,WINDOWS_VM_TASK_EVENTS='1'))
   self.assertEqual(result.returncode,76,result.stderr)
   self.assertIn('"pid":42',result.stderr)
   self.assertIn('"event": "allocated"',result.stderr)
   self.assertFalse((root/'image.png').exists())
if __name__=='__main__':unittest.main()
