#!/usr/bin/env python3
"""Explicit live test: prove the Windows supervisor stops parent and descendant writes."""
import argparse
import base64
import json
from pathlib import Path
import subprocess
import tempfile
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--live', action='store_true', required=True,
                        help='authorize temporary test files on the configured running VM')
    parser.parse_args()
    helper = Path(__file__).resolve().parents[1] / 'scripts/windows-vm-powershell'
    with tempfile.TemporaryDirectory(prefix='windows-timeout-test-') as directory:
        script = Path(directory)/'test.ps1'
        def run(source, timeout=10):
            script.write_text(source, encoding='utf-8')
            return subprocess.run([str(helper), '--timeout', str(timeout), str(script)],
                                  capture_output=True, text=True, timeout=timeout+45)
        setup = run("$p=Join-Path $env:TEMP ('codex-timeout-'+[Guid]::NewGuid().ToString('N')); New-Item -ItemType Directory $p | Out-Null; [Console]::Write($p)")
        assert setup.returncode == 0, setup.stderr
        root = setup.stdout.strip().replace("'", "''")
        try:
            child = f"Start-Sleep -Seconds 5; [IO.File]::WriteAllText('{root}\\child-late','bad')"
            encoded = base64.b64encode(child.encode('utf-16le')).decode()
            result = run(f"""$i=New-Object Diagnostics.ProcessStartInfo
$i.FileName='C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe'
$i.Arguments='-NoProfile -NonInteractive -EncodedCommand {encoded}'
$i.UseShellExecute=$false
$i.CreateNoWindow=$true
$c=[Diagnostics.Process]::Start($i)
[IO.File]::WriteAllText('{root}\\pids',("$PID,"+$c.Id))
Start-Sleep -Seconds 5
[IO.File]::WriteAllText('{root}\\parent-late','bad')
""", timeout=2)
            assert result.returncode == 124, (result.returncode, result.stderr)
            assert 'task_timeout=stopped' in result.stderr, result.stderr
            time.sleep(4)
            verified = run(f"""$ids=([IO.File]::ReadAllText('{root}\\pids')).Split(',')
foreach ($idValue in $ids) {{ if (Get-Process -Id ([int]$idValue) -ErrorAction SilentlyContinue) {{ throw 'test process survived' }} }}
if ((Test-Path '{root}\\parent-late') -or (Test-Path '{root}\\child-late')) {{ throw 'late write survived timeout' }}
Write-Output 'parent-and-descendant-stopped'
""")
            assert verified.returncode == 0, verified.stderr
            print(verified.stdout.strip())
        finally:
            cleanup = run(f"Remove-Item -LiteralPath '{root}' -Recurse -Force")
            assert cleanup.returncode == 0, cleanup.stderr


if __name__ == '__main__':
    main()
