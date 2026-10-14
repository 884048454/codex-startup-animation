# Codex Startup Animation (Windows)

A CODEX-themed adaptation of [dsh-startup-screen](https://github.com/6shenhonghong9/dsh-startup-screen), with a Windows desktop startup watcher and installer/uninstaller.

This runs as a separate fullscreen animation window when the desktop app starts. It does not modify Codex installation files and is not an official Codex plugin. The installer registers a logon task for the current Windows user. Animation, narration, and sound effects play locally.

## Share it

Send someone this project ZIP, or upload the project folder to a GitHub repository and share its link. They can download the repository ZIP, extract it, and run `安装.cmd`.

To push this folder to a newly created empty GitHub repository, open PowerShell in this folder and use the repository URL from GitHub:

```powershell
git init -b main
git add .
git commit -m "Initial Codex startup animation"
git remote add origin https://github.com/YOUR-USER/YOUR-REPOSITORY.git
git push -u origin main
```

## Requirements and supported app

- 64-bit Windows 10 or Windows 11, with the Codex desktop app.
- Microsoft Edge WebView2 Evergreen Runtime. The installer stops with a helpful message if it cannot find the runtime. Install it from [Microsoft's WebView2 page](https://developer.microsoft.com/microsoft-edge/webview2/).
- GitHub access during installation. The installer downloads the narration and sound effects from a pinned upstream revision; MP3 files are not included in this repository.
- Automatic detection currently targets the Windows Store/MSIX Codex app at `WindowsApps\OpenAI.Codex_...\app\ChatGPT.exe`. Codex CLI, the web app, macOS/Linux, and other installation layouts are not covered.

## Install

1. Download and extract the project ZIP.
2. Double-click `安装.cmd`. The scheduled task is registered for the current Windows user; administrator access is not required.
3. Fully quit Codex and open it again. The animation plays before returning to Codex; use the on-screen skip control if desired.

The watcher starts when the user signs in and plays the animation when it detects a new Codex main process. Restart Codex to see it again. The animation host has a 60-second failsafe timeout.

## Uninstall

Run `卸载.cmd` from the installed folder, or run `%LOCALAPPDATA%\CodexStartupAnimation\Uninstall.ps1`. This disables the startup watcher and leaves the installed files in place. Delete `%LOCALAPPDATA%\CodexStartupAnimation` to remove those files too.

## Troubleshooting

- If the installer reports that WebView2 is missing, install the Microsoft Edge WebView2 Evergreen Runtime and run the installer again.
- If installation succeeds but the animation does not appear, fully quit and reopen Codex, and confirm that the installed app matches the Windows desktop layout listed above.
- Watcher log: `%LOCALAPPDATA%\CodexStartupAnimation\watcher.log`. Animation host log: `%LOCALAPPDATA%\CodexStartupAnimation\host.log`.

## License and third-party materials

- The adapted animation code comes from [6shenhonghong9/dsh-startup-screen](https://github.com/6shenhonghong9/dsh-startup-screen), pinned to commit `4a2cfe642867fac013fdef90095981544a819a2a`. The upstream MIT license is retained in [`DSH-LICENSE.txt`](DSH-LICENSE.txt).
- The upstream project identifies its narration and sound effects as third-party materials outside the MIT code license. This repository does not distribute MP3 files; the installer fetches them from upstream onto the user's computer. Confirm the rights before redistributing or using the audio commercially.
- Microsoft WebView2 .NET assemblies are included with their license and notice at [`webview2/LICENSE.txt`](webview2/LICENSE.txt) and [`webview2/NOTICE.txt`](webview2/NOTICE.txt). The WebView2 Evergreen Runtime must also be installed on the target computer.
- See [`NOTICE.md`](NOTICE.md) for attribution and licensing details.

中文说明：[README.md](README.md)。
