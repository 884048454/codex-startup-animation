$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$headers = @{ 'User-Agent' = 'CodexStartupAnimation-Installer'; 'Accept' = 'application/vnd.github+json' }
$tempRoot = Join-Path $env:TEMP ('codex-startup-bundle-' + [guid]::NewGuid().ToString('N'))

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $node = Get-Command 'node.exe' -ErrorAction SilentlyContinue
    if (-not $node) {
        throw '完整安装需要 Node.js 22 或更新版本。请先从 https://nodejs.org/ 安装，再重新运行“安装.cmd”。若只要启动动画，请运行“仅安装动画.cmd”。'
    }
    $nodeVersion = (& $node.Source --version 2>$null | Select-Object -First 1)
    if ($nodeVersion -notmatch '^v?(\d+)\.') {
        throw '无法读取 Node.js 版本。请安装 Node.js 22 或更新版本，再重新运行“安装.cmd”。'
    }
    if ([int]$matches[1] -lt 22) {
        throw "检测到 Node.js $nodeVersion；完整安装需要 Node.js 22 或更新版本。请先升级，再重新运行“安装.cmd”。"
    }

    Write-Host '正在查询 Dream Skin Switcher 最新 Windows Release…'
    $release = Invoke-RestMethod -UseBasicParsing -Headers $headers `
        -Uri 'https://api.github.com/repos/bilbillm/Codex-Dream-Skin-Switcher/releases/latest'
    $zipAsset = @($release.assets | Where-Object { $_.name -match '^Codex-Dream-Skin-Switcher-.+-win-x64\.zip$' }) |
        Select-Object -First 1
    $sumAsset = @($release.assets | Where-Object { $_.name -eq 'SHA256SUMS.txt' }) | Select-Object -First 1
    if (-not $zipAsset -or -not $sumAsset) {
        throw 'Dream Skin Switcher Release 未提供预期的 Windows x64 ZIP 和 SHA256SUMS.txt，已停止安装。'
    }

    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    $zipPath = Join-Path $tempRoot $zipAsset.name
    $sumPath = Join-Path $tempRoot 'SHA256SUMS.txt'
    Write-Host "正在下载并校验 Dream Skin Switcher $($release.tag_name)…"
    Invoke-WebRequest -UseBasicParsing -Headers $headers -Uri $zipAsset.browser_download_url -OutFile $zipPath
    Invoke-WebRequest -UseBasicParsing -Headers $headers -Uri $sumAsset.browser_download_url -OutFile $sumPath

    $sumText = Get-Content -LiteralPath $sumPath -Raw -Encoding UTF8
    $sumPattern = '(?m)^\s*([0-9a-fA-F]{64})\s+\*?' + [regex]::Escape($zipAsset.name) + '\s*$'
    $sumMatch = [regex]::Match($sumText, $sumPattern)
    if (-not $sumMatch.Success) {
        throw 'SHA256SUMS.txt 中没有对应 ZIP 的哈希，已停止安装。'
    }
    $expectedHash = $sumMatch.Groups[1].Value.ToUpperInvariant()
    $actualHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToUpperInvariant()
    if ($actualHash -ne $expectedHash) {
        throw 'Dream Skin Switcher ZIP 的 SHA-256 校验失败，已停止安装。'
    }

    Write-Host '正在安装 Codex 启动动画…'
    & (Join-Path $PSScriptRoot 'Install.ps1')

    $safeVersion = [regex]::Replace([string]$release.tag_name, '[^A-Za-z0-9._-]', '_')
    $switcherRoot = Join-Path $env:LOCALAPPDATA 'CodexDreamSkinSwitcher'
    $switcherDir = Join-Path $switcherRoot $safeVersion
    New-Item -ItemType Directory -Path $switcherDir -Force | Out-Null
    Expand-Archive -LiteralPath $zipPath -DestinationPath $switcherDir -Force

    $shortcutInstaller = Join-Path $switcherDir '安装快捷方式.ps1'
    if (-not (Test-Path -LiteralPath $shortcutInstaller -PathType Leaf)) {
        throw 'Dream Skin Switcher ZIP 中缺少安装快捷方式.ps1，已停止创建启动入口。'
    }
    Write-Host '正在创建主题切换器和 Codex 启动快捷方式…'
    & (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') `
        -NoProfile -ExecutionPolicy Bypass -File $shortcutInstaller
    if ($LASTEXITCODE -ne 0) {
        throw 'Dream Skin Switcher 快捷方式安装失败。'
    }

    Write-Host ''
    Write-Host '整套安装完成。先打开“Codex 主题切换器”选择并应用主题；以后从“Codex 自定义主题”启动 Codex，即可播放启动动画并进入已选皮肤。' -ForegroundColor Green
    Write-Host "Dream Skin Switcher 安装目录：$switcherDir"
    Write-Host '若只想安装启动动画，请运行“仅安装动画.cmd”。'
} catch {
    Write-Host ''
    Write-Host ('安装未完成：' + $_.Exception.Message) -ForegroundColor Red
    exit 1
} finally {
    if ($tempRoot -and (Test-Path -LiteralPath $tempRoot)) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
