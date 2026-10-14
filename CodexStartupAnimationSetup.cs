using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Windows.Forms;

[assembly: AssemblyTitle("Codex 启动动画安装向导")]
[assembly: AssemblyProduct("Codex Startup Animation")]
[assembly: AssemblyCompany("Open Source Community Project")]
[assembly: AssemblyDescription("安装 Codex 启动动画与可选主题切换器")]
[assembly: AssemblyVersion("1.0.0.0")]

internal static class Program
{
    [STAThread]
    private static void Main(string[] args)
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        bool animationOnly = false;
        foreach (string arg in args) if (String.Equals(arg, "/animation-only", StringComparison.OrdinalIgnoreCase)) animationOnly = true;
        Application.Run(new SetupForm(animationOnly));
    }
}

internal sealed class SetupForm : Form
{
    private readonly Color ink = Color.FromArgb(29, 42, 57);
    private readonly Color muted = Color.FromArgb(94, 108, 124);
    private readonly Color blue = Color.FromArgb(36, 113, 194);
    private readonly Panel fullCard;
    private readonly Panel animationCard;
    private readonly RadioButton fullChoice;
    private readonly RadioButton animationChoice;
    private readonly Label status;
    private readonly ProgressBar progress;
    private readonly RichTextBox log;
    private readonly Button installButton;
    private readonly Button closeButton;
    private Process worker;
    private bool completed;
    private bool installing;

    public SetupForm(bool animationOnly)
    {
        Text = "Codex 启动动画 | 安装向导";
        StartPosition = FormStartPosition.CenterScreen;
        ClientSize = new Size(900, 720);
        MinimumSize = new Size(820, 680);
        BackColor = Color.FromArgb(247, 249, 252);
        Font = new Font("Microsoft YaHei UI", 9F, FontStyle.Regular, GraphicsUnit.Point);
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = false;

        var header = new Panel { Dock = DockStyle.Top, Height = 112, BackColor = Color.FromArgb(22, 39, 59) };
        header.Paint += DrawHeaderMark;
        Controls.Add(header);
        header.Controls.Add(new Label {
            Text = "Codex 启动动画", ForeColor = Color.White, Font = new Font("Microsoft YaHei UI", 22F, FontStyle.Bold),
            AutoSize = true, Location = new Point(104, 24)
        });
        header.Controls.Add(new Label {
            Text = "安装动画，并可选接入 Codex Dream Skin Switcher", ForeColor = Color.FromArgb(205, 218, 231),
            AutoSize = true, Location = new Point(107, 67)
        });
        header.Controls.Add(new Label {
            Text = "社区开源项目   ·   当前 Windows 用户   ·   无需管理员权限", ForeColor = Color.FromArgb(168, 189, 208),
            AutoSize = true, Anchor = AnchorStyles.Top | AnchorStyles.Right, Location = new Point(526, 73)
        });

        var body = new Panel { Dock = DockStyle.Fill, Padding = new Padding(28, 18, 28, 8) };
        Controls.Add(body);

        body.Controls.Add(new Label { Text = "选择安装内容", Font = new Font(Font, FontStyle.Bold), ForeColor = ink, AutoSize = true, Location = new Point(28, 17) });
        body.Controls.Add(new Label {
            Text = "可以只安装启动动画，也可以同时安装主题切换器。安装内容和联网下载会在下方说明。",
            ForeColor = muted, AutoSize = true, Location = new Point(28, 44)
        });

        fullCard = MakeCard(28, 76, 406, 154);
        animationCard = MakeCard(448, 76, 396, 154);
        body.Controls.Add(fullCard);
        body.Controls.Add(animationCard);
        fullChoice = AddChoice(fullCard, "动画 + 主题切换器", "安装 Codex 启动动画和 Dream Skin Switcher。\r\n需要 Node.js 22+。首次安装会从上游\r\nGitHub Release 下载 Windows x64 程序。", !animationOnly);
        animationChoice = AddChoice(animationCard, "仅启动动画", "安装动画播放器和启动监听器。\r\n不安装主题切换器，也不需要 Node.js。\r\n需要 Microsoft Edge WebView2 Runtime。", animationOnly);
        fullChoice.CheckedChanged += delegate { if (fullChoice.Checked) animationChoice.Checked = false; UpdateCards(); };
        animationChoice.CheckedChanged += delegate { if (animationChoice.Checked) fullChoice.Checked = false; UpdateCards(); };
        fullCard.Click += delegate { fullChoice.Checked = true; };
        animationCard.Click += delegate { animationChoice.Checked = true; };
        foreach (Control child in fullCard.Controls) child.Click += delegate { fullChoice.Checked = true; };
        foreach (Control child in animationCard.Controls) child.Click += delegate { animationChoice.Checked = true; };
        UpdateCards();

        var disclosure = new Panel {
            Location = new Point(28, 244), Size = new Size(816, 112), BackColor = Color.FromArgb(239, 244, 249),
            Padding = new Padding(14)
        };
        body.Controls.Add(disclosure);
        disclosure.Controls.Add(new Label { Text = "安装行为与来源", Font = new Font(Font, FontStyle.Bold), ForeColor = ink, AutoSize = true, Location = new Point(14, 10) });
        disclosure.Controls.Add(new Label {
            Text = "会运行本目录中可查看的 PowerShell 安装脚本；只为当前用户安装，不修改 Codex 程序文件。完整安装会从\r\nGitHub 下载 Dream Skin Switcher，并用上游 SHA-256 清单校验 ZIP。仅对本次进程临时放宽脚本执行限制，不修改系统策略。",
            ForeColor = muted, AutoSize = true, Location = new Point(14, 35)
        });
        var sourceLink = new LinkLabel { Text = "查看本项目源码", AutoSize = true, Location = new Point(14, 82), LinkColor = blue };
        sourceLink.LinkClicked += delegate { OpenUrl("https://github.com/884048454/codex-startup-animation"); };
        disclosure.Controls.Add(sourceLink);
        var upstreamLink = new LinkLabel { Text = "查看 Dream Skin Switcher 上游", AutoSize = true, Location = new Point(132, 82), LinkColor = blue };
        upstreamLink.LinkClicked += delegate { OpenUrl("https://github.com/bilbillm/Codex-Dream-Skin-Switcher"); };
        disclosure.Controls.Add(upstreamLink);

        status = new Label { Text = "准备就绪", ForeColor = muted, AutoSize = true, Location = new Point(28, 369) };
        body.Controls.Add(status);
        progress = new ProgressBar { Location = new Point(28, 393), Size = new Size(816, 10), Style = ProgressBarStyle.Blocks, Value = 0 };
        body.Controls.Add(progress);
        body.Controls.Add(new Label { Text = "安装日志", Font = new Font(Font, FontStyle.Bold), ForeColor = ink, AutoSize = true, Location = new Point(28, 418) });
        log = new RichTextBox {
            Location = new Point(28, 444), Size = new Size(816, 90), ReadOnly = true, BorderStyle = BorderStyle.FixedSingle,
            BackColor = Color.White, ForeColor = Color.FromArgb(59, 72, 87), DetectUrls = true, Font = new Font("Consolas", 9F),
            Text = "选择安装选项后，点击“开始安装”。详细步骤会显示在这里。"
        };
        body.Controls.Add(log);

        var footer = new Panel { Dock = DockStyle.Bottom, Height = 72, BackColor = Color.White, Padding = new Padding(28, 12, 28, 12) };
        Controls.Add(footer);
        body.SendToBack();
        header.BringToFront();
        footer.Controls.Add(new Label {
            Text = "未进行代码签名；Windows SmartScreen 可能显示“未知发布者”。可先查看源码。",
            ForeColor = muted, AutoSize = true, Location = new Point(28, 25)
        });
        installButton = new Button {
            Text = "开始安装", Size = new Size(132, 42), Location = new Point(600, 14), BackColor = blue,
            ForeColor = Color.White, FlatStyle = FlatStyle.Flat, Font = new Font(Font, FontStyle.Bold), Cursor = Cursors.Hand
        };
        installButton.FlatAppearance.BorderSize = 0;
        installButton.Click += StartInstall;
        footer.Controls.Add(installButton);
        closeButton = new Button {
            Text = "关闭", Size = new Size(80, 42), Location = new Point(744, 14), FlatStyle = FlatStyle.Flat, Cursor = Cursors.Hand
        };
        closeButton.Click += delegate { Close(); };
        footer.Controls.Add(closeButton);

        FormClosing += delegate(object sender, FormClosingEventArgs e) {
            if (installing) {
                e.Cancel = true;
                MessageBox.Show(this, "安装还在进行中。请等待安装完成后再关闭向导。", "正在安装", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
        };
    }

    private Panel MakeCard(int x, int y, int width, int height)
    {
        var panel = new Panel { Location = new Point(x, y), Size = new Size(width, height), BackColor = Color.White, Cursor = Cursors.Hand };
        panel.Paint += delegate(object sender, PaintEventArgs e) {
            var p = (Panel)sender;
            var color = Object.ReferenceEquals(p, fullCard) ? (fullChoice != null && fullChoice.Checked ? blue : Color.FromArgb(215, 223, 232))
                                                            : (animationChoice != null && animationChoice.Checked ? blue : Color.FromArgb(215, 223, 232));
            using (var pen = new Pen(color, 2F)) e.Graphics.DrawRectangle(pen, 1, 1, p.Width - 3, p.Height - 3);
        };
        return panel;
    }

    private RadioButton AddChoice(Panel panel, string title, string description, bool selected)
    {
        var radio = new RadioButton {
            Text = title, Checked = selected, AutoSize = true, Location = new Point(16, 14),
            Font = new Font(Font, FontStyle.Bold), ForeColor = ink, Cursor = Cursors.Hand
        };
        panel.Controls.Add(radio);
        panel.Controls.Add(new Label {
            Text = description, AutoSize = true, ForeColor = muted, Location = new Point(40, 48), Cursor = Cursors.Hand
        });
        return radio;
    }

    private void UpdateCards()
    {
        if (fullCard != null) fullCard.Invalidate();
        if (animationCard != null) animationCard.Invalidate();
    }

    private void DrawHeaderMark(object sender, PaintEventArgs e)
    {
        e.Graphics.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
        using (var brush = new SolidBrush(Color.FromArgb(64, 153, 220))) e.Graphics.FillEllipse(brush, 30, 26, 54, 54);
        using (var pen = new Pen(Color.White, 4F)) {
            e.Graphics.DrawArc(pen, 40, 36, 34, 34, 20, 300);
            e.Graphics.DrawLine(pen, 61, 54, 75, 42);
        }
        using (var brush = new SolidBrush(Color.White)) e.Graphics.FillEllipse(brush, 57, 50, 8, 8);
    }

    private void StartInstall(object sender, EventArgs e)
    {
        if (completed) { Close(); return; }
        var scriptName = fullChoice.Checked ? "Install-All.ps1" : "Install.ps1";
        var scriptPath = Path.Combine(Path.GetDirectoryName(Application.ExecutablePath), scriptName);
        if (!File.Exists(scriptPath)) {
            MessageBox.Show(this, "找不到安装脚本：" + scriptPath + "\r\n请从项目完整 ZIP 解压后再运行本向导。", "文件不完整", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return;
        }

        log.Clear();
        AppendLog("启动安装脚本：" + scriptName);
        AppendLog("PowerShell -ExecutionPolicy Bypass 仅作用于这个子进程，不会更改系统设置。");
        status.Text = "安装中，请保持此窗口打开…";
        status.ForeColor = blue;
        progress.Style = ProgressBarStyle.Marquee;
        progress.MarqueeAnimationSpeed = 24;
        installButton.Enabled = false;
        closeButton.Enabled = false;
        fullChoice.Enabled = false;
        animationChoice.Enabled = false;
        installing = true;

        try {
            var powershell = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), "WindowsPowerShell\\v1.0\\powershell.exe");
            var start = new ProcessStartInfo {
                FileName = powershell,
                Arguments = "-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File \"" + scriptPath + "\"",
                WorkingDirectory = Path.GetDirectoryName(Application.ExecutablePath),
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            };
            worker = new Process { StartInfo = start, EnableRaisingEvents = true };
            worker.OutputDataReceived += delegate(object s, DataReceivedEventArgs args) { if (args.Data != null) AppendLog(args.Data); };
            worker.ErrorDataReceived += delegate(object s, DataReceivedEventArgs args) { if (args.Data != null) AppendLog(args.Data); };
            worker.Exited += WorkerExited;
            worker.Start();
            worker.BeginOutputReadLine();
            worker.BeginErrorReadLine();
        }
        catch (Exception ex) { FinishInstall(-1, "无法启动安装进程：" + ex.Message); }
    }

    private void WorkerExited(object sender, EventArgs e)
    {
        var process = (Process)sender;
        int code = process.ExitCode;
        process.WaitForExit();
        if (IsDisposed || !IsHandleCreated) return;
        BeginInvoke(new Action(delegate { FinishInstall(code, null); }));
    }

    private void FinishInstall(int exitCode, string startupError)
    {
        installing = false;
        progress.Style = ProgressBarStyle.Blocks;
        progress.MarqueeAnimationSpeed = 0;
        installButton.Enabled = true;
        installButton.Text = exitCode == 0 ? "完成" : "关闭";
        closeButton.Enabled = true;
        completed = true;
        if (!String.IsNullOrEmpty(startupError)) AppendLog(startupError);
        if (exitCode == 0) {
            progress.Value = 100;
            status.Text = "安装完成。完全退出并重新打开 Codex 后即可体验。";
            status.ForeColor = Color.FromArgb(31, 130, 85);
            AppendLog("安装完成。");
        } else {
            progress.Value = 0;
            status.Text = "安装未完成。请根据日志处理问题，再重新运行向导。";
            status.ForeColor = Color.FromArgb(180, 75, 58);
            AppendLog("安装进程退出代码：" + exitCode);
        }
    }

    private void AppendLog(string message)
    {
        if (log == null || log.IsDisposed) return;
        if (log.InvokeRequired) {
            try { log.BeginInvoke(new Action<string>(AppendLog), message); } catch { }
            return;
        }
        log.AppendText("[" + DateTime.Now.ToString("HH:mm:ss") + "] " + message + Environment.NewLine);
        log.SelectionStart = log.TextLength;
        log.ScrollToCaret();
    }

    private static void OpenUrl(string url)
    {
        try { Process.Start(new ProcessStartInfo(url) { UseShellExecute = true }); }
        catch (Exception ex) { MessageBox.Show("无法打开链接：" + ex.Message, "打开链接", MessageBoxButtons.OK, MessageBoxIcon.Warning); }
    }
}
