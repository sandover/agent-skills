# Supervise a task in a Windows job. A gate prevents task execution before job assignment.
# Inherit the SSH standard handles; keep stdout/stderr streaming and stdin available.
param([Parameter(Mandatory=$true)][string]$TaskPath,
      [Parameter(Mandatory=$true)][int]$TimeoutSeconds, [switch]$EmitEvents)
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
[Console]::OutputEncoding=New-Object System.Text.UTF8Encoding($false)
Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Diagnostics;
using System.Runtime.InteropServices;
public sealed class TaskJob : IDisposable {
    [StructLayout(LayoutKind.Sequential)] struct Basic {
        public long ProcessTime, JobTime; public uint Flags;
        public UIntPtr Min, Max; public uint Active; public UIntPtr Affinity;
        public uint Priority, Scheduling;
    }
    [StructLayout(LayoutKind.Sequential)] struct Io { public ulong A,B,C,D,E,F; }
    [StructLayout(LayoutKind.Sequential)] struct Extended {
        public Basic Basic; public Io Io;
        public UIntPtr ProcessMemory, JobMemory, PeakProcess, PeakJob;
    }
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    static extern IntPtr CreateJobObject(IntPtr attrs, string name);
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern bool SetInformationJobObject(IntPtr job, int kind, ref Extended value, uint size);
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern bool AssignProcessToJobObject(IntPtr job, IntPtr process);
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern bool TerminateJobObject(IntPtr job, uint code);
    [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr handle);
    IntPtr handle;
    public TaskJob() {
        handle=CreateJobObject(IntPtr.Zero,null);
        if(handle==IntPtr.Zero) throw new Win32Exception();
        try { SetKillOnClose(true); } catch { Dispose(); throw; }
    }
    public void SetKillOnClose(bool enabled) {
        var info=new Extended(); info.Basic.Flags=enabled ? 0x2000u : 0u;
        if(!SetInformationJobObject(handle,9,ref info,(uint)Marshal.SizeOf(info))) throw new Win32Exception();
    }
    public void Assign(Process process) {
        if(!AssignProcessToJobObject(handle,process.Handle)) throw new Win32Exception();
    }
    public void Stop() { if(!TerminateJobObject(handle,124)) throw new Win32Exception(); }
    public void Dispose() { if(handle!=IntPtr.Zero) { CloseHandle(handle); handle=IntPtr.Zero; } }
}
'@
$job=$null; $child=$null; $gate=$null; $result=1
try {
    $job=New-Object TaskJob
    $gateName='Local\codex-task-'+[Guid]::NewGuid().ToString('N')
    $gate=New-Object System.Threading.EventWaitHandle($false,[System.Threading.EventResetMode]::ManualReset,$gateName)
    $path=$TaskPath.Replace("'","''")
    $source=@"
`$ErrorActionPreference='Stop'
`$ProgressPreference='SilentlyContinue'
[Console]::InputEncoding=New-Object System.Text.UTF8Encoding(`$false)
[Console]::OutputEncoding=New-Object System.Text.UTF8Encoding(`$false)
`$OutputEncoding=[Console]::OutputEncoding
`$gate=[Threading.EventWaitHandle]::OpenExisting('$gateName')
if (-not `$gate.WaitOne(10000)) { exit 76 }
`$gate.Dispose()
`$global:LASTEXITCODE=0
try { & '$path'; exit `$LASTEXITCODE } catch { [Console]::Error.WriteLine(`$_.ToString()); exit 1 }
"@
    $encoded=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($source))
    $info=New-Object System.Diagnostics.ProcessStartInfo
    $info.FileName='C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
    $info.Arguments='-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -OutputFormat Text -EncodedCommand '+$encoded
    $info.UseShellExecute=$false
    $child=New-Object System.Diagnostics.Process
    $child.StartInfo=$info
    if (-not $child.Start()) { throw 'Cannot start task' }
    try { $job.Assign($child) } catch { $child.Kill(); throw }
    if ($EmitEvents) {
        $metadata=@{event='started'; pid=$child.Id; created=$child.StartTime.ToUniversalTime().ToString('o');
            computer=$env:COMPUTERNAME; user=[Security.Principal.WindowsIdentity]::GetCurrent().Name;
            task_path=$TaskPath; timeout_seconds=$TimeoutSeconds}
        [Console]::Error.WriteLine('windows_task='+($metadata | ConvertTo-Json -Compress))
    }
    $gate.Set() | Out-Null
    if (-not $child.WaitForExit($TimeoutSeconds*1000)) {
        $job.Stop()
        if (-not $child.WaitForExit(10000)) { throw 'Task stop could not be confirmed' }
        [Console]::Error.WriteLine('task_timeout=stopped')
        $result=124
    } else {
        $result=$child.ExitCode
        # Successful commands may intentionally launch a persistent process.
        if ($result -eq 0) { $job.SetKillOnClose($false) }
    }
} catch {
    [Console]::Error.WriteLine($_.ToString())
    $result=76
} finally {
    if ($job) { $job.Dispose() }
    if ($gate) { $gate.Dispose() }
    if ($child) { $child.Dispose() }
}
if ($EmitEvents -and $result -ne 76) {
    [Console]::Error.WriteLine('windows_task='+(@{event='completed'; exit_code=$result} | ConvertTo-Json -Compress))
}
exit $result
