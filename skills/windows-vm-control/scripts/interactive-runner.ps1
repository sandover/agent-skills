# Run one task PowerShell script inside the signed-in Windows desktop.
# Start the task in a child PowerShell process so the host can stop both PIDs.
# Write a start record before waiting and one terminal JSON record on every caught result.
# Capture task stdout and stderr without requiring a reporting contract from the task.
# Keep all paths caller-supplied so the host owns naming and cleanup.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$TaskPath,
    [Parameter(Mandatory = $true)][string]$StartedPath,
    [Parameter(Mandatory = $true)][string]$ResultPath,
    [Parameter(Mandatory = $true)][string]$StdoutPath,
    [Parameter(Mandatory = $true)][string]$StderrPath
)

$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$record = $null

function Write-JsonFile {
    param([string]$Path, [object]$Value)
    $json = $Value | ConvertTo-Json -Compress -Depth 6
    [System.IO.File]::WriteAllText($Path, $json, $utf8)
}

try {
    $powershell = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
    $escapedTaskPath = $TaskPath.Replace("'", "''")
    $taskCommand = "`$ErrorActionPreference = 'Stop'; & '$escapedTaskPath'"
    $encodedTask = [Convert]::ToBase64String(
        [System.Text.Encoding]::Unicode.GetBytes($taskCommand)
    )
    $arguments = @(
        '-NoLogo',
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy', 'Bypass',
        '-EncodedCommand', $encodedTask
    )
    $child = Start-Process -FilePath $powershell -ArgumentList $arguments `
        -NoNewWindow -PassThru `
        -RedirectStandardOutput $StdoutPath `
        -RedirectStandardError $StderrPath
    Write-JsonFile -Path $StartedPath -Value @{
        runner_pid = $PID
        child_pid = $child.Id
    }
    $child.WaitForExit()
    $stdout = if (Test-Path -LiteralPath $StdoutPath) {
        [System.IO.File]::ReadAllText($StdoutPath)
    } else { '' }
    $stderr = if (Test-Path -LiteralPath $StderrPath) {
        [System.IO.File]::ReadAllText($StderrPath)
    } else { '' }
    if ($child.ExitCode -eq 0) {
        $record = @{ status = 'ok'; exit_code = 0; output = $stdout }
    } else {
        $record = @{
            status = 'error'
            exit_code = $child.ExitCode
            output = $stdout
            message = $stderr
        }
    }
} catch {
    $record = @{ status = 'error'; message = $_.Exception.Message }
} finally {
    if ($null -eq $record) {
        $record = @{ status = 'error'; message = 'interactive runner produced no result' }
    }
    $temporaryResult = "$ResultPath.tmp"
    Write-JsonFile -Path $temporaryResult -Value $record
    Move-Item -LiteralPath $temporaryResult -Destination $ResultPath -Force
}
