$ErrorActionPreference = 'Stop'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$source = Join-Path $PSScriptRoot 'CodexStartupAnimationSetup.cs'
$output = Join-Path $PSScriptRoot 'CodexStartupAnimationSetup.exe'
$icon = Join-Path $PSScriptRoot 'CodexStartupAnimationSetup.ico'

if (-not (Test-Path -LiteralPath $compiler)) {
    throw '找不到 Windows .NET Framework x64 编译器。请在 Windows 上安装 .NET Framework 4.8 Developer Pack，或使用已发布的 CodexStartupAnimationSetup.exe。'
}
if (-not (Test-Path -LiteralPath $source)) { throw "找不到安装向导源码：$source" }
& (Join-Path $PSScriptRoot 'New-SetupIcon.ps1') -OutputPath $icon

& $compiler /nologo /codepage:65001 /target:winexe /platform:x64 /optimize+ /reference:System.dll /reference:System.Drawing.dll /reference:System.Windows.Forms.dll "/win32icon:$icon" "/out:$output" $source
if ($LASTEXITCODE -ne 0) { throw "安装向导编译失败，编译器退出代码：$LASTEXITCODE" }
Write-Host "安装向导已生成：$output"
