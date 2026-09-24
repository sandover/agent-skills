# Classify only the sandbox check. Unrelated doctor failures are not policy mismatches.
function ConvertFrom-CodexPolicyReport {
    param([string]$Json, [int]$DoctorExit)
    $result = [ordered]@{
        policy = 'failed'
        reason = 'invalid_json'
        doctor_exit = $DoctorExit
        approval = ''
        filesystem = ''
        network = ''
    }
    try { $report = ConvertFrom-Json -InputObject $Json -ErrorAction Stop }
    catch { return [pscustomobject]$result }
    $check = $report.checks.'sandbox.helpers'
    if ($null -eq $check) {
        $result.reason = 'missing_sandbox_check'
    } elseif ($check.status -ne 'ok') {
        $result.reason = 'sandbox_check_unhealthy'
    } else {
        $result.approval = $check.details.'approval policy'
        $result.filesystem = $check.details.'filesystem sandbox'
        $result.network = $check.details.'network sandbox'
        $missing = $false
        foreach ($field in @('approval', 'filesystem', 'network')) {
            if ($result[$field] -isnot [string] -or [string]::IsNullOrWhiteSpace($result[$field])) { $missing = $true }
        }
        if ($missing) {
            $result.reason = 'incomplete_policy_fields'
        } elseif ($result.approval -eq 'Never' -and $result.filesystem -eq 'unrestricted' -and $result.network -eq 'enabled') {
            $result.policy = 'ok'
            $result.reason = 'sandbox_policy_verified'
        } else {
            $result.policy = 'mismatch'
            $result.reason = 'unexpected_policy_fields'
        }
    }
    return [pscustomobject]$result
}

function Get-CodexPolicyEvidence {
    param([string]$CodexPath, [string]$WorkingDirectory)
    $pushed = $false
    try {
        if ($WorkingDirectory) {
            Push-Location -LiteralPath $WorkingDirectory -ErrorAction Stop
            $pushed = $true
        }
        $output = @(& $CodexPath doctor --json 2>$null)
        $doctorExit = $LASTEXITCODE
        ConvertFrom-CodexPolicyReport -Json ($output | Out-String) -DoctorExit $doctorExit
    } catch {
        [pscustomobject]@{policy='failed'; reason='doctor_invocation_failed'; doctor_exit=-1; approval=''; filesystem=''; network=''}
    } finally {
        if ($pushed) { Pop-Location }
    }
}

function Write-CodexPolicyEvidence {
    param($Evidence)
    Write-Output "codex_policy=$($Evidence.policy)"
    Write-Output "codex_policy_reason=$($Evidence.reason)"
    Write-Output "codex_doctor_exit=$($Evidence.doctor_exit)"
    foreach ($field in @('approval', 'filesystem', 'network')) {
        # Keep diagnostics single-line and bounded. Never print the whole doctor report.
        $value = [regex]::Replace([string]$Evidence.$field, '[\r\n\x00-\x1f]', ' ')
        if ($value.Length -gt 100) { $value = $value.Substring(0, 100) }
        Write-Output "codex_policy_${field}=$value"
    }
}
