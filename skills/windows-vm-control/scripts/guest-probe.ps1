# Report Windows identity and optional guest Codex readiness.
# Skip Codex discovery for an SSH-only capability check.
# Check the PATH launcher before known standalone release locations.
# A broken launcher must not hide a working standalone installation.
# Emit stable key=value fields without changing guest state.

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$ProgressPreference = 'SilentlyContinue'

$checkCodex = $env:WINDOWS_VM_CONTROL_CHECK_CODEX -eq '1'
$codexPath = 'not_checked'
$codexVersion = 'not_checked'
$codexState = 'skipped'
$codexPolicy = 'not_checked'
$policyEvidence = $null

if ($checkCodex) {
    $candidates = [System.Collections.Generic.List[string]]::new()
    $codexCommand = Get-Command codex -ErrorAction SilentlyContinue
    if ($codexCommand -and $codexCommand.Source) {
        $candidates.Add($codexCommand.Source)
    }

    Get-ChildItem `
        "$env:USERPROFILE\.codex\packages\standalone\releases\*\bin\codex.exe" `
        -ErrorAction SilentlyContinue |
        Where-Object { -not $_.PSIsContainer } |
        Sort-Object LastWriteTime -Descending |
        ForEach-Object {
            if (!$candidates.Contains($_.FullName)) {
                $candidates.Add($_.FullName)
            }
        }

    $codexPath = 'not_found'
    $codexVersion = 'not_found'
    $codexState = 'not_found'
    foreach ($candidate in $candidates) {
        try {
            $versionOutput = & $candidate --version 2>$null
            if ($LASTEXITCODE -eq 0 -and $versionOutput) {
                $codexPath = $candidate
                $codexVersion = ($versionOutput | Select-Object -First 1).ToString().Trim()
                $codexState = 'ok'
                break
            }
            $codexState = 'failed'
        } catch {
            $codexState = 'failed'
        }
    }

    if ($codexState -eq 'ok') {
        $policyEvidence = Get-CodexPolicyEvidence -CodexPath $codexPath -WorkingDirectory $env:WINDOWS_VM_CONTROL_CWD
        $codexPolicy = $policyEvidence.policy
    }

}

Write-Output "computer=$env:COMPUTERNAME"
Write-Output "user=$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
Write-Output "codex=$codexState"
Write-Output "codex_path=$codexPath"
Write-Output "codex_version=$codexVersion"
if ($policyEvidence) { Write-CodexPolicyEvidence $policyEvidence }
else { Write-Output "codex_policy=$codexPolicy" }
