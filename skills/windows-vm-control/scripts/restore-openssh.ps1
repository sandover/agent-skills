# Restore the supported OpenSSH server configuration from VMware Guest Operations.
# Require an elevated Windows token before changing capabilities, services, keys, or firewall rules.
# Preserve unrelated authorized keys and add the configured public key only when absent.
# Restrict the inbound SSH rule to the Mac address supplied by the host helper.
# Write bounded machine-readable start and terminal records for host polling and cleanup.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$UserName,
    [Parameter(Mandatory = $true)][string]$PublicKeyPath,
    [Parameter(Mandatory = $true)][string]$HostAddress,
    [Parameter(Mandatory = $true)][string]$StartedPath,
    [Parameter(Mandatory = $true)][string]$ResultPath
)

$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$record = $null
$errorCode = 'restore_failed'

function Write-JsonFile {
    param([string]$Path, [object]$Value)
    $json = $Value | ConvertTo-Json -Compress -Depth 6
    [System.IO.File]::WriteAllText($Path, $json, $utf8)
}

function Add-AuthorizedKey {
    param([string]$KeyFile, [string]$KeyText)

    $newFields = $KeyText.Trim() -split '\s+'
    if ($newFields.Count -lt 2) { throw 'invalid SSH public key' }
    $keyBody = $newFields[1]
    $existing = if (Test-Path -LiteralPath $KeyFile -PathType Leaf) {
        @(Get-Content -LiteralPath $KeyFile)
    } else {
        @()
    }
    $present = $existing | Where-Object {
        $fields = $_.Trim() -split '\s+'
        $fields -ccontains $keyBody
    }
    if ($present) { return $false }
    Add-Content -LiteralPath $KeyFile -Value $KeyText -Encoding ascii
    return $true
}

function Invoke-Icacls {
    param([string[]]$Arguments)
    & "$env:SystemRoot\System32\icacls.exe" @Arguments | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "icacls failed with exit $LASTEXITCODE" }
}

try {
    Write-JsonFile -Path $StartedPath -Value @{ pid = $PID }

    $PublicKey = Get-Content -LiteralPath $PublicKeyPath |
        Where-Object { $_.Trim() } |
        Select-Object -First 1
    if (-not $UserName -or -not $PublicKey -or -not $HostAddress) { throw 'OpenSSH recovery input is incomplete' }

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        $errorCode = 'administrator_required'
        throw 'OpenSSH recovery requires an elevated Windows administrator token'
    }

    $user = Get-LocalUser -Name $UserName
    $capability = Get-WindowsCapability -Online |
        Where-Object Name -Like 'OpenSSH.Server*' |
        Select-Object -First 1
    if ($null -eq $capability) { throw 'OpenSSH Server capability is unavailable' }

    $installed = $false
    if ($capability.State -ne 'Installed') {
        Add-WindowsCapability -Online -Name $capability.Name | Out-Null
        $installed = $true
    }
    Start-Service sshd
    Set-Service sshd -StartupType Automatic

    $adminMember = Get-LocalGroupMember -SID 'S-1-5-32-544' |
        Where-Object { $_.SID -eq $user.SID }
    if ($adminMember) {
        $keys = 'C:\ProgramData\ssh\administrators_authorized_keys'
        $keyAdded = Add-AuthorizedKey -KeyFile $keys -KeyText $PublicKey
        Invoke-Icacls -Arguments @(
            $keys,
            '/inheritance:r',
            '/grant', '*S-1-5-18:F',
            '/grant', '*S-1-5-32-544:F'
        )
    } else {
        $directory = Join-Path (Join-Path 'C:\Users' $UserName) '.ssh'
        $keys = Join-Path $directory 'authorized_keys'
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
        $keyAdded = Add-AuthorizedKey -KeyFile $keys -KeyText $PublicKey
        Invoke-Icacls -Arguments @(
            $directory,
            '/inheritance:r',
            '/grant', "*$($user.SID):(OI)(CI)F"
        )
        Invoke-Icacls -Arguments @(
            $keys,
            '/inheritance:r',
            '/grant', "*$($user.SID):F"
        )
    }

    $rule = Get-NetFirewallRule -Name OpenSSH-Server-In-TCP -ErrorAction SilentlyContinue
    if ($rule) {
        Set-NetFirewallRule -Name OpenSSH-Server-In-TCP `
            -Enabled True -Profile Any -RemoteAddress $HostAddress
    } else {
        New-NetFirewallRule -Name OpenSSH-Server-In-TCP `
            -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Profile Any `
            -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 `
            -RemoteAddress $HostAddress | Out-Null
    }

    $hostKeyFile = 'C:\ProgramData\ssh\ssh_host_ed25519_key.pub'
    if (-not (Test-Path -LiteralPath $hostKeyFile -PathType Leaf)) {
        throw 'OpenSSH ED25519 host key is missing'
    }
    $hostKeyFingerprint = (& "$env:SystemRoot\System32\OpenSSH\ssh-keygen.exe" `
        -lf $hostKeyFile 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'could not read the OpenSSH host-key fingerprint' }

    $record = @{
        status = 'ok'
        user = $UserName
        key_file = $keys
        key_added = $keyAdded
        capability_installed = $installed
        firewall_remote_address = $HostAddress
        host_key_fingerprint = $hostKeyFingerprint
    }
} catch {
    $record = @{
        status = 'error'
        code = $errorCode
        message = $_.Exception.Message
    }
} finally {
    if ($null -eq $record) {
        $record = @{ status = 'error'; code = 'restore_failed'; message = 'OpenSSH recovery produced no result' }
    }
    $temporaryResult = "$ResultPath.tmp"
    Write-JsonFile -Path $temporaryResult -Value $record
    Move-Item -LiteralPath $temporaryResult -Destination $ResultPath -Force
}
