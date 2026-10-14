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
try {
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
    readonly string contentRoot, userDataRoot, logPath;
    readonly WebView2 browser=new WebView2();
    readonly Timer watchdog=new Timer();
    public CodexStartupHost(string content, string userData, string log) {
        contentRoot=content; userDataRoot=userData; logPath=log;
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
    [System.Windows.Forms.Application]::Run([CodexStartupHost]::new($content,$userData,$log))
} catch {
    Add-Content -LiteralPath $log -Value ((Get-Date -Format 'yyyy-MM-dd HH:mm:ss')+' POWERSHELL ERROR '+$_.Exception.ToString()) -Encoding UTF8
}


