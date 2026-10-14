# Notices and third-party materials

## dsh-startup-screen

The animation page and styles in this repository are adapted from [6shenhonghong9/dsh-startup-screen](https://github.com/6shenhonghong9/dsh-startup-screen), pinned to commit `4a2cfe642867fac013fdef90095981544a819a2a`. Its MIT license is included as `DSH-LICENSE.txt`.

This project changes the identity, colors, copy, and Windows launch integration for Codex. It is an unofficial community adaptation and is not affiliated with or endorsed by OpenAI, DeepSeek, or the upstream repository author.

## Voice and sound assets

The upstream README identifies narration and sound effects as third-party materials outside the upstream MIT code license. No MP3 files are included here. `Install.ps1` downloads the audio files from the pinned upstream archive to the installing user's computer. Review the upstream project and third-party rights before further redistribution or commercial use.

## Microsoft WebView2

This project includes Microsoft WebView2 .NET assemblies and their accompanying license and notice files under `webview2/`. The Microsoft Edge WebView2 Evergreen Runtime is a separate prerequisite and is not included.

## Optional Codex theme interoperability

The combined installer downloads the Windows release of [Codex Dream Skin Switcher](https://github.com/bilbillm/Codex-Dream-Skin-Switcher) from its upstream GitHub Releases and verifies it against the upstream `SHA256SUMS.txt`; it does not bundle or modify the switcher's source code. The startup animation reads the selected theme's `theme.json` and local image from its active theme directory. Dream Skin Switcher is an unofficial community project and is not affiliated with OpenAI.

## Project code

The installer, Windows host, watcher, and original adaptation changes in this repository are offered under the MIT License in `LICENSE`. That license does not grant additional rights to the third-party audio materials or Microsoft binaries.
