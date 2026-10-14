$ErrorActionPreference='Stop'
$log=Join-Path $env:LOCALAPPDATA 'CodexStartupAnimation\watcher.log'
function Write-Log([string]$message){Add-Content -LiteralPath $log -Value ((Get-Date -Format 'yyyy-MM-dd HH:mm:ss')+' '+$message) -Encoding UTF8}
try {
    $animation=Join-Path $env:LOCALAPPDATA 'CodexStartupAnimation\CodexStartup.ps1'
    $seen=[Collections.Generic.HashSet[int]]::new()
    $codexRootPattern='\\WindowsApps\\OpenAI\.Codex_[^\\]+\\app\\ChatGPT\.exe'
    function Get-CodexRoots {
        Get-CimInstance Win32_Process -Filter "name='ChatGPT.exe'" | Where-Object {
            $_.CommandLine -match $codexRootPattern -and $_.CommandLine -notmatch '--type='
        }
    }
    $initial=Get-CodexRoots
    foreach($p in $initial){[void]$seen.Add([int]$p.ProcessId)}
    Write-Log ("Listener started. Existing Codex roots: "+$seen.Count)
    while($true){
        Start-Sleep -Milliseconds 1000
        $roots=@(Get-CodexRoots)
        $alive=[Collections.Generic.HashSet[int]]::new()
        foreach($p in $roots){
            $id=[int]$p.ProcessId
            [void]$alive.Add($id)
            if($seen.Add($id)){
                Write-Log ("Detected Codex PID "+$id+"; launching animation")
                try { Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') -WindowStyle Hidden -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',('"'+$animation+'"')) }
                catch { Write-Log ("Animation launch failed: "+$_.Exception.Message) }
            }
        }
        foreach($id in @($seen)){if(-not $alive.Contains($id)){[void]$seen.Remove($id)}}
    }
} catch { Write-Log ("Listener failed: "+$_.Exception.ToString()); exit 1 }
