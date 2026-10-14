param([switch]$Preview)
$ErrorActionPreference='Stop'
$dest=Join-Path $env:LOCALAPPDATA 'CodexStartupAnimation'
$runtime=Join-Path $dest 'webview2\runtime'
$content=Join-Path $dest 'codex-animation'
$userData=Join-Path $dest 'webview2\profile'
$log=Join-Path $dest 'host.log'
$core=Join-Path $runtime 'Microsoft.Web.WebView2.Core.dll'
$winforms=Join-Path $runtime 'Microsoft.Web.WebView2.WinForms.dll'
$env:PATH=$runtime+';'+$env:PATH

function Get-DreamSkinBridgeConfig {
    $themeRoot=Join-Path $env:LOCALAPPDATA 'CodexDreamSkin\active-theme'
    $manifest=Join-Path $themeRoot 'theme.json'
    $empty=[pscustomobject]@{Root='';Json='{}'}
    if(-not (Test-Path -LiteralPath $manifest -PathType Leaf)){return $empty}

    try {
        $theme=Get-Content -LiteralPath $manifest -Raw -Encoding UTF8 | ConvertFrom-Json
        $config=[ordered]@{}
        $appearance=([string]$theme.appearance).Trim().ToLowerInvariant()
        if($appearance -in @('light','dark','auto')){$config.theme=$appearance}
        $accent=([string]$theme.palette.accent).Trim()
        if($accent -match '^(?:#[0-9a-fA-F]{3,8}|(?:rgb|hsl|oklch|oklab)\([^;{}]{1,96}\))$'){$config.accent=$accent}

        $mappingRoot=''
        $image=[string]$theme.image
        if($image){
            if([IO.Path]::IsPathRooted($image)){throw 'Theme image path must be relative.'}
            $rootFull=[IO.Path]::GetFullPath($themeRoot)
            $rootPrefix=$rootFull.TrimEnd([char]92)+[char]92
            $imageFull=[IO.Path]::GetFullPath([IO.Path]::Combine($rootFull,$image))
            if(-not $imageFull.StartsWith($rootPrefix,[StringComparison]::OrdinalIgnoreCase)){
                throw 'Theme image path escapes the active theme directory.'
            }
            if([IO.Path]::GetExtension($imageFull) -notin @('.png','.jpg','.jpeg','.webp')){
                throw 'Theme image format is not supported.'
            }
            if(-not (Test-Path -LiteralPath $imageFull -PathType Leaf)){throw 'Theme image is missing.'}
            $item=Get-Item -LiteralPath $imageFull
            if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'Theme image cannot be a link.'}

            $relative=$imageFull.Substring($rootPrefix.Length).Replace([string][char]92,'/')
            $encoded=(@($relative.Split('/') | ForEach-Object {[Uri]::EscapeDataString($_)}) -join '/')
            $config.skinImage='https://codex-theme.local/'+$encoded
            $mappingRoot=$rootFull
        }

        return [pscustomobject]@{Root=$mappingRoot;Json=($config | ConvertTo-Json -Compress -Depth 5)}
    } catch {
        Add-Content -LiteralPath $log -Value ((Get-Date -Format 'yyyy-MM-dd HH:mm:ss')+' DREAM SKIN THEME IGNORED '+$_.Exception.Message) -Encoding UTF8
        return $empty
    }
}

try {
    $skin=Get-DreamSkinBridgeConfig
    [void][Reflection.Assembly]::LoadFrom($core)
    [void][Reflection.Assembly]::LoadFrom($winforms)
    $source=@"
using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;

public class CodexStartupHost : Form {
    [DllImport("user32.dll")] static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    const int SW_RESTORE=9;
    readonly string contentRoot, userDataRoot, logPath, skinRoot, skinConfigJson;
    readonly WebView2 browser=new WebView2();
    readonly Timer watchdog=new Timer();
    public CodexStartupHost(string content, string userData, string log, string skinAssets, string skinConfig) {
        contentRoot=content; userDataRoot=userData; logPath=log;
        skinRoot=skinAssets; skinConfigJson=skinConfig;
        FormBorderStyle=FormBorderStyle.None; ShowInTaskbar=false; TopMost=true;
        StartPosition=FormStartPosition.Manual; Bounds=Screen.PrimaryScreen.Bounds;
        KeyPreview=true; BackColor=Color.FromArgb(8,6,13); browser.Dock=DockStyle.Fill;
        watchdog.Interval=60000; watchdog.Tick+=(s,e)=>{WriteLog("Watchdog closed overlay after timeout");Close();};
        Controls.Add(browser); Shown += (s,e)=>{watchdog.Start();InitializeBrowser();};
    }
    async void InitializeBrowser() {
        try {
            var env=await CoreWebView2Environment.CreateAsync(null,userDataRoot);
            await browser.EnsureCoreWebView2Async(env);
            var core=browser.CoreWebView2;
            core.Settings.AreDefaultContextMenusEnabled=false;
            core.Settings.AreDevToolsEnabled=false;
            core.Settings.IsStatusBarEnabled=false;
            core.Settings.IsZoomControlEnabled=false;
            core.Settings.AreDefaultScriptDialogsEnabled=false;
            core.SetVirtualHostNameToFolderMapping("codex-startup.local",contentRoot,CoreWebView2HostResourceAccessKind.Allow);
            if(!String.IsNullOrWhiteSpace(skinRoot) && Directory.Exists(skinRoot)) {
                core.SetVirtualHostNameToFolderMapping("codex-theme.local",skinRoot,CoreWebView2HostResourceAccessKind.Allow);
            }
            await core.AddScriptToExecuteOnDocumentCreatedAsync("window.__DSH_STARTUP_SKIN__ = " + skinConfigJson + ";");
            core.WebMessageReceived += (s,e)=>{
                string action=""; try { action=e.TryGetWebMessageAsString(); } catch {}
                WriteLog("Web message: "+action);
                if(action=="complete" || action=="assetError") BeginInvoke(new Action(()=>Close()));
            };
            core.NavigationCompleted += (s,e)=>{WriteLog("Navigation completed: "+e.IsSuccess);if(!e.IsSuccess)BeginInvoke(new Action(()=>Close()));};
            core.Navigate("https://codex-startup.local/index.html?embedded");
        } catch(Exception ex) { WriteLog(ex.ToString()); BeginInvoke(new Action(()=>Close())); }
    }
    void WriteLog(string value){try{File.AppendAllText(logPath,DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss ")+value+Environment.NewLine);}catch{}}
    protected override void OnFormClosed(FormClosedEventArgs e){watchdog.Stop();watchdog.Dispose();base.OnFormClosed(e);foreach(var p in Process.GetProcessesByName("ChatGPT")){try{if(p.MainWindowHandle!=IntPtr.Zero){ShowWindow(p.MainWindowHandle,SW_RESTORE);SetForegroundWindow(p.MainWindowHandle);break;}}catch{}}}
}
"@
    Add-Type -TypeDefinition $source -ReferencedAssemblies @('System.Windows.Forms','System.Drawing',$core,$winforms)
    [System.Windows.Forms.Application]::EnableVisualStyles()
    [System.Windows.Forms.Application]::Run([CodexStartupHost]::new($content,$userData,$log,$skin.Root,$skin.Json))
} catch {
    Add-Content -LiteralPath $log -Value ((Get-Date -Format 'yyyy-MM-dd HH:mm:ss')+' POWERSHELL ERROR '+$_.Exception.ToString()) -Encoding UTF8
}


