# Request is base64 UTF-8 JSON supplied by windows-vm-desktop; no code interpolation.
$ErrorActionPreference='Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
$r=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($requestBase64)) | ConvertFrom-Json
$root=[Windows.Automation.AutomationElement]::RootElement
$all=$root.FindAll([Windows.Automation.TreeScope]::Children,[Windows.Automation.Condition]::TrueCondition)
function Describe($e) {
    $c=$e.Current
    [pscustomobject]@{name=$c.Name; automation_id=$c.AutomationId; pid=$c.ProcessId;
        window=$c.NativeWindowHandle; type=$c.ControlType.ProgrammaticName;
        enabled=$c.IsEnabled; offscreen=$c.IsOffscreen;
        patterns=@($e.GetSupportedPatterns() | ForEach-Object { $_.ProgrammaticName })}
}
if ($r.action -eq 'windows') {
    $rows=@($all | ForEach-Object { Describe $_ })
} else {
    $windows=@($all | Where-Object { $_.Current.NativeWindowHandle -eq $r.window -and $_.Current.ProcessId -eq $r.pid })
    if ($windows.Count -ne 1) { throw "Expected one current window; found $($windows.Count)" }
    $controls=$windows[0].FindAll([Windows.Automation.TreeScope]::Descendants,[Windows.Automation.Condition]::TrueCondition)
    $matches=@($controls | Where-Object {
        ($null -eq $r.automation_id -or $_.Current.AutomationId -ceq $r.automation_id) -and
        ($null -eq $r.name -or $_.Current.Name -ceq $r.name)
    })
    if ($r.action -eq 'controls') {
        $rows=@($matches | ForEach-Object { Describe $_ })
    } else {
        if ($matches.Count -ne 1) { throw "Expected one control; found $($matches.Count). Inspect controls before acting." }
        $target=$matches[0]
        if (-not $target.Current.IsEnabled -or $target.Current.IsOffscreen) { throw 'Control is disabled or offscreen' }
        if ($target.Current.IsPassword) { throw 'Identity controls belong to the user' }
        if ($r.action -eq 'invoke') {
            $target.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern).Invoke()
        } else {
            $pattern=$target.GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern)
            if ($pattern.Current.IsReadOnly) { throw 'Control is read-only' }
            $pattern.SetValue($r.value)
        }
        $rows=@([pscustomobject]@{action=$r.action; dispatched=$true; outcome='Verify application state separately'})
    }
}
ConvertTo-Json -InputObject $rows -Depth 5 -Compress
