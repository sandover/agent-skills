# Standalone contract tests for ConvertFrom-CodexPolicyReport.
# The helper is loaded by the live runner when this file is concatenated with it.
if (-not (Get-Command ConvertFrom-CodexPolicyReport -CommandType Function -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot '..\scripts\codex-policy.ps1')
}

function New-ReportJson {
    param(
        [string]$Status = 'ok',
        [string]$Approval = 'Never',
        [string]$Filesystem = 'unrestricted',
        [string]$Network = 'enabled',
        [switch]$OmitCheck,
        [string[]]$OmitFields = @()
    )

    $details = @{}
    if ($OmitFields -notcontains 'approval') { $details['approval policy'] = $Approval }
    if ($OmitFields -notcontains 'filesystem') { $details['filesystem sandbox'] = $Filesystem }
    if ($OmitFields -notcontains 'network') { $details['network sandbox'] = $Network }

    $checks = @{}
    if (-not $OmitCheck) {
        $checks['sandbox.helpers'] = @{ status = $Status; details = $details }
    }
    return (@{ checks = $checks } | ConvertTo-Json -Depth 8 -Compress)
}

$passed = 0

$healthyCases = @(
    @{ Name = 'healthy report'; Json = (New-ReportJson); DoctorExit = 0 },
    # Other doctor checks can fail while the sandbox policy check remains healthy.
    @{ Name = 'healthy report with unrelated doctor failure'; Json = (New-ReportJson); DoctorExit = 23 }
)
foreach ($case in $healthyCases) {
    $result = ConvertFrom-CodexPolicyReport -Json $case.Json -DoctorExit $case.DoctorExit
    if ($result.policy -ne 'ok') {
        throw "$($case.Name): expected policy 'ok', got '$($result.policy)'"
    }
    if ($result.doctor_exit -ne $case.DoctorExit) {
        throw "$($case.Name): expected doctor_exit $($case.DoctorExit), got '$($result.doctor_exit)'"
    }
    $passed++
}

$mismatchCases = @(
    @{ Name = 'approval differs'; Json = (New-ReportJson -Approval 'OnRequest') },
    @{ Name = 'filesystem differs'; Json = (New-ReportJson -Filesystem 'workspace-write') },
    @{ Name = 'network differs'; Json = (New-ReportJson -Network 'disabled') }
)
foreach ($case in $mismatchCases) {
    $result = ConvertFrom-CodexPolicyReport -Json $case.Json -DoctorExit 0
    if ($result.policy -ne 'mismatch') {
        throw "$($case.Name): expected policy 'mismatch', got '$($result.policy)'"
    }
    if ([string]::IsNullOrWhiteSpace([string]$result.reason)) {
        throw "$($case.Name): mismatch reason must be nonempty"
    }
    if ($result.doctor_exit -ne 0) {
        throw "$($case.Name): expected doctor_exit 0, got '$($result.doctor_exit)'"
    }
    $passed++
}

$failedCases = @(
    @{ Name = 'invalid JSON'; Json = '{not-json'; DoctorExit = 0 },
    @{ Name = 'missing sandbox check'; Json = (New-ReportJson -OmitCheck); DoctorExit = 0 },
    @{ Name = 'unhealthy sandbox check'; Json = (New-ReportJson -Status 'failed'); DoctorExit = 0 },
    @{ Name = 'missing approval field'; Json = (New-ReportJson -OmitFields @('approval')); DoctorExit = 0 },
    @{ Name = 'missing filesystem field'; Json = (New-ReportJson -OmitFields @('filesystem')); DoctorExit = 0 },
    @{ Name = 'missing network field'; Json = (New-ReportJson -OmitFields @('network')); DoctorExit = 0 }
)
foreach ($case in $failedCases) {
    $result = ConvertFrom-CodexPolicyReport -Json $case.Json -DoctorExit $case.DoctorExit
    if ($result.policy -ne 'failed') {
        throw "$($case.Name): expected policy 'failed', got '$($result.policy)'"
    }
    if ([string]::IsNullOrWhiteSpace([string]$result.reason)) {
        throw "$($case.Name): failure reason must be nonempty"
    }
    if ($result.doctor_exit -ne $case.DoctorExit) {
        throw "$($case.Name): expected doctor_exit $($case.DoctorExit), got '$($result.doctor_exit)'"
    }
    $passed++
}

Write-Output "PASS: $passed Codex policy cases"
