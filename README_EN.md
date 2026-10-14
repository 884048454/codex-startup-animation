# Codex Startup Animation (Windows)

A CODEX-themed adaptation of [dsh-startup-screen](https://github.com/6shenhonghong9/dsh-startup-screen), with a Windows desktop startup watcher and installer/uninstaller.

This runs as a separate fullscreen animation window when the desktop app starts. It does not modify Codex installation files and is not an official Codex plugin. The installer registers a logon task for the current Windows user. Animation, narration, and sound effects play locally.

## Share it

Send someone this project ZIP, or upload the project folder to a GitHub repository and share its link. They can download the repository ZIP, extract it, and run `安装.cmd` to install both the startup animation and Codex Dream Skin Switcher. The installer downloads the upstream Windows x64 release and verifies its SHA-256.

The combined setup requires Windows 10/11 x64, the Microsoft Store Codex app, WebView2, and Node.js 22+. To install only the startup animation, run `仅安装动画.cmd`; WebView2 is still required.

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

1. Install Node.js 22+, then download and extract the project ZIP.
2. Double-click `安装.cmd`. It downloads and verifies Dream Skin Switcher, then installs the animation and shortcuts for the current Windows user without administrator privileges.
3. Open “Codex 主题切换器” to select and apply a theme. For future sessions, launch Codex through “Codex 自定义主题”; the animation plays before the themed Codex window appears.

For animation-only setup, double-click `仅安装动画.cmd`, then fully exit and reopen Codex.

The watcher starts when the user signs in and plays the animation when it detects a new Codex main process. Restart Codex to see it again. The animation host has a 60-second failsafe timeout.

## Follow a Codex interface theme (optional)

This project reuses the theme selector and package format from [Codex Dream Skin Switcher](https://github.com/bilbillm/Codex-Dream-Skin-Switcher) instead of building a separate skin manager. `安装.cmd` installs the latest upstream Windows release; its current release includes light and dark themes you can select and apply. You can also import additional themes from [Codex Angelina Themes](https://github.com/bilbillm/Codex-Angelina-Themes).

Each time the animation plays, it reads `%LOCALAPPDATA%\CodexDreamSkin\active-theme\theme.json` and follows that theme's image, light/dark/automatic appearance, and accent color (hex, `rgb()`, `hsl()`, `oklch()`, and `oklab()` values accepted by the upstream project; `auto` uses the Windows/WebView system color preference). After the switcher successfully applies a theme, the next startup animation follows it; the switcher remains responsible for applying the theme to Codex itself. Without the switcher, the animation keeps its built-in CODEX appearance.

The bridge currently reuses the theme package's home `image`, `appearance`, and `palette.accent` fields. The upstream theme layout, task-page image, and Codex UI injection remain handled by the switcher; this project does not load theme CSS or scripts into the startup animation.

Dream Skin Switcher is an independent community project that styles the Codex interface through local CDP; it is not an official OpenAI feature. This project's combined installer downloads and invokes the upstream release; it does not copy or execute scripts from theme packages. See the upstream repository for requirements and details.

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
