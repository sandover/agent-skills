# The host supplies a base64 JSON identity, never executable caller text.
$ErrorActionPreference = 'Stop'
$request = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($requestBase64)) | ConvertFrom-Json
$result = @{ status = 'unknown'; pid = $request.pid }
$process = $null
$killer = $null
try {
    if ($env:COMPUTERNAME -ne $request.computer) { throw 'Wrong Windows computer' }
    $process = Get-Process -Id $request.pid -ErrorAction Stop
    # Hold the process handle through taskkill so its PID cannot be recycled.
    $handle = $process.Handle
    if ($process.HasExited -or $process.StartTime.ToUniversalTime().ToString('o') -cne $request.created) {
        throw 'Recorded process identity no longer matches'
    }
    $info = New-Object Diagnostics.ProcessStartInfo
    $info.FileName = "$env:SystemRoot\System32\taskkill.exe"
    $info.Arguments = "/PID $($process.Id) /T /F"
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $killer = [Diagnostics.Process]::Start($info)
    if (-not $killer.WaitForExit(10000)) { $killer.Kill(); throw 'Task-tree stop timed out' }
    if ($killer.ExitCode -ne 0 -or -not $process.WaitForExit(5000)) { throw 'Task-tree stop unconfirmed' }
    $result.status = 'stopped'
} catch {
    $result.message = $_.Exception.Message
} finally {
    if ($killer) { $killer.Dispose() }
    if ($process) { $process.Dispose() }
}
$json = $result | ConvertTo-Json -Compress
if ($request.result_path) {
    [IO.File]::WriteAllText($request.result_path, $json, (New-Object Text.UTF8Encoding($false)))
} else {
    [Console]::Out.WriteLine($json)
}
if ($result.status -ne 'stopped') { exit 76 }
