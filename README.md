# Codex 启动动画（Windows）

把基于 [dsh-startup-screen](https://github.com/6shenhonghong9/dsh-startup-screen) 的启动界面改成 CODEX 风格，并提供 Windows 桌面版 Codex 的自动启动、安装和卸载脚本。

本项目是在 Codex 启动时显示的独立全屏动画窗口；它不会修改 Codex 安装文件，也不是 Codex 官方插件。安装器会为当前 Windows 用户注册登录启动监听器。动画内容和旁白/音效在本地播放。

## 分享给别人

最简单的方法是把本项目 ZIP 发给对方。对方解压后运行 `安装.cmd` 即可一次安装启动动画和 Codex Dream Skin Switcher；安装器会从上游 GitHub Release 下载 Windows x64 程序并核对 SHA-256。也可以把本目录上传到 GitHub，然后把仓库链接发给对方；对方在 GitHub 点 **Code → Download ZIP**，解压后运行 `安装.cmd`。

完整安装需要 Windows 10/11 x64、微软商店版 Codex、WebView2 和 Node.js 22+。若只想装启动动画、不装换肤器，运行 `仅安装动画.cmd`；仍需 WebView2。

如果你要从本机推送到新建的 GitHub 空仓库，在本目录打开 PowerShell，按 GitHub 提供的仓库地址执行：

```powershell
git init -b main
git add .
git commit -m "Initial Codex startup animation"
git remote add origin https://github.com/你的用户名/你的仓库名.git
git push -u origin main
```

## 安装要求

- Windows 10 或 Windows 11 的 64 位桌面版 Codex。
- Microsoft Edge WebView2 Evergreen Runtime。缺少时，安装器会停止并提示安装；官方安装页：[WebView2](https://developer.microsoft.com/microsoft-edge/webview2/)。
- 首次安装时可访问 GitHub。安装器从上游固定版本下载旁白和音效；这些 MP3 没有打包在本仓库中。
- 自动检测目前针对 Windows Store/MSIX 版 Codex（`WindowsApps\OpenAI.Codex_...\app\ChatGPT.exe`）。CLI、网页版、macOS/Linux，以及其他未匹配该程序路径的安装方式不在此适配范围内。

## 安装和使用

1. 安装 Node.js 22+，从 GitHub 下载 ZIP 并解压到本机。
2. 双击 `安装.cmd`。安装器会下载并校验 Dream Skin Switcher，再安装启动动画和快捷方式；全程为当前 Windows 用户操作，不需要管理员权限。
3. 打开“Codex 主题切换器”选择并应用主题；以后从“Codex 自定义主题”启动 Codex，动画结束或点击跳过后会进入已换肤的 Codex。

如果只安装启动动画，双击 `仅安装动画.cmd`，然后完全退出 Codex 再重新打开。

动画会在 Windows 登录时启动监听器；监听器在检测到新的 Codex 主进程后播放一次。关闭并重新打开 Codex 可以再次播放。动画窗口有 60 秒保护超时。

## 跟随 Codex 主界面主题（可选）

本项目复用 [Codex Dream Skin Switcher](https://github.com/bilbillm/Codex-Dream-Skin-Switcher) 的主题选择器和主题包格式，不另做一套皮肤管理器。运行 `安装.cmd` 会自动安装上游最新 Windows Release；当前 Release 内置浅色和深色主题，选择并应用即可。也可从 [Codex Angelina Themes](https://github.com/bilbillm/Codex-Angelina-Themes) 导入其他主题。

每次播放启动动画时，会读取上游保存的 `%LOCALAPPDATA%\CodexDreamSkin\active-theme\theme.json`，同步主题图片、浅/深/自动外观和强调色（支持上游接受的十六进制、`rgb()`、`hsl()`、`oklch()`、`oklab()` 色值；`auto` 按 Windows/WebView 的系统配色偏好解析）。换肤器成功应用主题后，下一次启动动画会跟随它；Codex 主界面的应用和启动方式仍由换肤器负责。没有安装主题切换器时，启动动画继续使用内置 CODEX 外观。

目前复用主题包中的首页 `image`、`appearance` 和 `palette.accent` 三项；上游主题布局、任务页图片和 Codex 界面注入仍由换肤器自身处理，不会把网页 CSS 或脚本加载进启动动画。

Dream Skin Switcher 是独立的社区项目，通过本机 CDP 修改 Codex 主界面；它不是 OpenAI 官方功能。本项目的整合安装器只下载并调用上游 Release，不复制或执行主题包里的脚本。详情和要求请查看上游仓库。

## 卸载

在已安装目录运行 `卸载.cmd`，或运行 `%LOCALAPPDATA%\CodexStartupAnimation\Uninstall.ps1`。这会关闭启动监听器并保留安装文件。若要彻底删除，再手动删除 `%LOCALAPPDATA%\CodexStartupAnimation` 文件夹。

## 排错

- 安装器提示缺少 WebView2：按提示安装 Microsoft Edge WebView2 Evergreen Runtime，再运行一次安装器。
- 安装成功但没播放：完全退出后重新打开 Codex，并确认使用的是上面列出的 Windows 桌面版安装方式。
- 查看监听日志：`%LOCALAPPDATA%\CodexStartupAnimation\watcher.log`；动画窗口日志：`%LOCALAPPDATA%\CodexStartupAnimation\host.log`。

## 许可和素材来源

- 改编动画代码的上游是 [6shenhonghong9/dsh-startup-screen](https://github.com/6shenhonghong9/dsh-startup-screen)，固定到提交 `4a2cfe642867fac013fdef90095981544a819a2a`。保留的上游 MIT 许可见 [`DSH-LICENSE.txt`](DSH-LICENSE.txt)。
- 原项目说明旁白和音效属于第三方素材，不在其 MIT 代码许可范围内。因此本仓库不分发 MP3；安装器从上游下载到用户本机。分享或商用这些音频前，请先确认权利。
- Microsoft WebView2 .NET 程序集随项目附带，许可与通知见 [`webview2/LICENSE.txt`](webview2/LICENSE.txt) 和 [`webview2/NOTICE.txt`](webview2/NOTICE.txt)。使用者电脑还需安装 WebView2 Evergreen Runtime。
- 本项目的许可和第三方来源说明见 [`NOTICE.md`](NOTICE.md)。

英文说明：[README_EN.md](README_EN.md)。
