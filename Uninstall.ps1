$ErrorActionPreference = 'SilentlyContinue'
$taskName = 'CodexStartupAnimation'
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
Get-CimInstance Win32_Process -Filter "name='powershell.exe'" |
    Where-Object { $_.CommandLine -like '*CodexStartupAnimation\WatchCodex.ps1*' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
Write-Host '启动监听已关闭。安装文件仍保留在 %LOCALAPPDATA%\CodexStartupAnimation。'
