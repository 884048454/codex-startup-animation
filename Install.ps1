$ErrorActionPreference = 'Stop'
$taskName = 'CodexStartupAnimation'
$localRoot = Join-Path $env:LOCALAPPDATA 'CodexStartupAnimation'
$sourceRoot = $PSScriptRoot
$repoCommit = '4a2cfe642867fac013fdef90095981544a819a2a'
$tempRoot = Join-Path $env:TEMP ('dsh-startup-screen-' + [guid]::NewGuid().ToString('N'))
$archive = Join-Path $tempRoot 'source.zip'

function Test-WebView2Runtime {
    $clientRoots = @(
        'HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients',
        'HKCU:\Software\Microsoft\EdgeUpdate\Clients'
    )
    foreach ($root in $clientRoots) {
        if (-not (Test-Path -LiteralPath $root)) { continue }
        foreach ($client in (Get-ChildItem -LiteralPath $root -ErrorAction SilentlyContinue)) {
            $entry = Get-ItemProperty -LiteralPath $client.PSPath -ErrorAction SilentlyContinue
            if ($entry.name -match 'WebView2 Runtime' -and $entry.pv -and $entry.pv -ne '0.0.0.0') {
                return $true
            }
        }
    }
    $appRoots = @()
    foreach ($base in @([Environment]::GetEnvironmentVariable('ProgramFiles(x86)'), $env:ProgramFiles, $env:LOCALAPPDATA)) {
        if ($base) { $appRoots += Join-Path $base 'Microsoft\EdgeWebView\Application' }
    }
    foreach ($root in $appRoots) {
        if (Test-Path -LiteralPath $root) {
            foreach ($version in (Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue)) {
                if (Test-Path -LiteralPath (Join-Path $version.FullName 'msedgewebview2.exe')) { return $true }
            }
        }
    }
    return $false
}

try {
    if (-not (Test-WebView2Runtime)) {
        throw '未检测到 Microsoft Edge WebView2 Runtime。请先从 https://developer.microsoft.com/microsoft-edge/webview2/ 安装 Evergreen Runtime，然后重新运行“安装.cmd”。'
    }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
    Write-Host '正在从原项目 GitHub 下载旁白和音效…'
    $sourceUrl = "https://github.com/6shenhonghong9/dsh-startup-screen/archive/$repoCommit.zip"
    Invoke-WebRequest -Uri $sourceUrl -OutFile $archive
    Expand-Archive -LiteralPath $archive -DestinationPath $tempRoot -Force
    $repo = Get-ChildItem -LiteralPath $tempRoot -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName 'lib\assets') } |
        Select-Object -First 1
    if (-not $repo) { throw 'The downloaded project archive has an unexpected layout.' }

    $audioSource = Join-Path $repo.FullName 'lib\assets'
    $audioFiles = @(Get-ChildItem -LiteralPath $audioSource -Filter '*.mp3')
    if ($audioFiles.Count -lt 7) { throw 'Audio assets are incomplete; installation stopped.' }

    New-Item -ItemType Directory -Force -Path $localRoot | Out-Null
    Copy-Item (Join-Path $sourceRoot 'CodexStartup.ps1') $localRoot -Force
    Copy-Item (Join-Path $sourceRoot 'WatchCodex.ps1') $localRoot -Force
    Copy-Item (Join-Path $sourceRoot 'Uninstall.ps1') $localRoot -Force
    Copy-Item (Join-Path $sourceRoot '卸载.cmd') $localRoot -Force
    Copy-Item (Join-Path $sourceRoot 'README.md') $localRoot -Force
    Copy-Item (Join-Path $sourceRoot 'README_EN.md') $localRoot -Force
    Copy-Item (Join-Path $sourceRoot 'NOTICE.md') $localRoot -Force
    Copy-Item (Join-Path $sourceRoot 'LICENSE') $localRoot -Force
    Copy-Item (Join-Path $sourceRoot 'codex-animation') $localRoot -Recurse -Force
    New-Item -ItemType Directory -Force -Path (Join-Path $localRoot 'codex-animation\lib\assets') | Out-Null
    Copy-Item (Join-Path $sourceRoot 'webview2\runtime') (Join-Path $localRoot 'webview2') -Recurse -Force
    Copy-Item (Join-Path $sourceRoot 'webview2\LICENSE.txt') (Join-Path $localRoot 'webview2') -Force
    Copy-Item (Join-Path $sourceRoot 'webview2\NOTICE.txt') (Join-Path $localRoot 'webview2') -Force
    Copy-Item (Join-Path $sourceRoot 'DSH-LICENSE.txt') $localRoot -Force
    Get-ChildItem -LiteralPath $audioSource -Filter '*.mp3' |
        Copy-Item -Destination (Join-Path $localRoot 'codex-animation\lib\assets') -Force

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    $powershell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $watcher = Join-Path $localRoot 'WatchCodex.ps1'
    $action = New-ScheduledTaskAction -Execute $powershell -Argument ("-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$watcher`"")
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $identity
    $principal = New-ScheduledTaskPrincipal -UserId $identity -LogonType Interactive -RunLevel Limited
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null
    Start-ScheduledTask -TaskName $taskName

    Write-Host '安装完成。完全退出 Codex 后重新打开，就会播放启动动画。' -ForegroundColor Green
    Write-Host "卸载：运行 $localRoot\Uninstall.ps1"
    Write-Host '旁白和音效是第三方素材；请先阅读 NOTICE.md 中的说明。'
}
finally {
    if ($tempRoot -and (Test-Path -LiteralPath $tempRoot)) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
