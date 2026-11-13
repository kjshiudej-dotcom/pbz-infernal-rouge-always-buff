using System;
using System.Drawing;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Windows.Forms;

internal static class PBZNoWipeWindow
{

    [STAThread]
    private static void Main()
    {
        using (var mutex = new Mutex(false, "PBZHeiMoShangNoWipe-26367565"))
        {
            try { if (!mutex.WaitOne(0)) return; }
            catch (AbandonedMutexException) { }
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Run();
        }
    }

    private static void Run()
    {
        using (var form = new Form())
        using (var timer = new System.Windows.Forms.Timer { Interval = 1000 })
        {
            form.Text = "影之刃零 · 黑魔伤 / Phantom Blade Zero · Infernal Rouge";
            form.Font = new Font("Microsoft YaHei UI", 11);
            form.AutoScaleMode = AutoScaleMode.Font;
            form.ClientSize = new Size(620, 155);
            form.StartPosition = FormStartPosition.CenterScreen;
            form.FormBorderStyle = FormBorderStyle.FixedDialog;
            form.MaximizeBox = false;

            var toggle = new CheckBox {
                AutoSize = true, Location = new Point(20, 20),
                Text = "黑魔伤常驻「凝气于刃」，跳过擦刀\r\nKeep Infernal Rouge buffed and skip the blade-wipe animation"
            };
            var status = new Label { AutoSize = true, Location = new Point(20, 85) };
            form.Controls.AddRange(new Control[] { toggle, status });
            string id = Guid.NewGuid().ToString("N");
            bool? writtenMode = null;
            bool wasCompatible = false;
            string bridge = null;

            Action update = delegate {
                try {
                    string gameFolder = FindRunningGame();
                    if (gameFolder == null)
                    {
                        wasCompatible = false;
                        toggle.Enabled = false;
                        toggle.Checked = false;
                        writtenMode = null;
                        status.Text = "请启动游戏 / Waiting for Phantom Blade Zero";
                        return;
                    }

                    string manifest = Path.GetFullPath(Path.Combine(gameFolder, "..", "..", "appmanifest_4115450.acf"));
                    string detectedBridge = Path.Combine(gameFolder, "platform", "steam", "ue4ss", "Mods", "PBZHeiMoShangAlwaysBuff");
                    if (!string.Equals(bridge, detectedBridge, StringComparison.OrdinalIgnoreCase))
                    {
                        if (wasCompatible && Directory.Exists(bridge)) WriteRequest(bridge, id, false);
                        bridge = detectedBridge;
                        wasCompatible = false;
                        writtenMode = null;
                    }
                    bool compatible = File.Exists(manifest) &&
                        Regex.IsMatch(File.ReadAllText(manifest), "(?m)^\\s*\"buildid\"\\s+\"26367565\"\\s*$") &&
                        File.Exists(Path.Combine(bridge, "enabled.txt")) &&
                        File.Exists(Path.Combine(bridge, "Scripts", "main.lua")) &&
                        File.Exists(Path.Combine(bridge, "Scripts", "PBZAbilityGate.lua")) &&
                        File.Exists(Path.Combine(bridge, "Scripts", "PBZTangBuff.lua"));
                    if (!compatible)
                    {
                        if (wasCompatible && Directory.Exists(bridge)) WriteRequest(bridge, id, false);
                        wasCompatible = false;
                        toggle.Enabled = false;
                        toggle.Checked = false;
                        writtenMode = null;
                        status.Text = "需要游戏 build 26367565 和 Mod 脚本 / Check build and mod files";
                        return;
                    }
                    wasCompatible = true;
                    toggle.Enabled = true;
                    bool enabled = toggle.Checked;
                    if (enabled || writtenMode != enabled)
                    {
                        WriteRequest(bridge, id, enabled);
                        writtenMode = enabled;
                    }
                    string acknowledgement = ReadStatus(bridge);
                    if (acknowledgement == id + " on" && enabled)
                        status.Text = "凝气于刃生效中 / Buff active";
                    else if (acknowledgement == id + " armed" && enabled)
                        status.Text = "已开启 · 请装备黑魔伤 / Equip Infernal Rouge";
                    else if (acknowledgement == id + " off" && !enabled)
                        status.Text = "已关闭 / Disabled";
                    else if (acknowledgement == id + " error")
                        status.Text = "游戏端错误 / In-game error";
                    else
                        status.Text = enabled ? "等待载入存档 / Waiting for game" : "已关闭 · 等待游戏确认\r\nDisabled · Waiting for game confirmation";
                }
                catch (IOException) { status.Text = "等待同步 / Waiting to sync"; }
                catch (UnauthorizedAccessException) { status.Text = "无法访问 Mod 目录 / Cannot access mod folder"; }
            };
            toggle.CheckedChanged += delegate {
                id = Guid.NewGuid().ToString("N");
                update();
            };
            timer.Tick += delegate { update(); };
            form.FormClosing += delegate {
                timer.Stop();
                if (!wasCompatible) return;
                try { WriteRequest(bridge, Guid.NewGuid().ToString("N"), false); }
                catch (IOException) { }
                catch (UnauthorizedAccessException) { }
            };
            update();
            timer.Start();
            Application.Run(form);
        }
    }

    private static string FindRunningGame()
    {
        string folder = null;
        foreach (var process in Process.GetProcessesByName("PBZ"))
        {
            using (process)
            {
                try
                {
                    string steam = Path.GetDirectoryName(process.MainModule.FileName);
                    string platform = Path.GetDirectoryName(steam);
                    if (string.Equals(Path.GetFileName(steam), "steam", StringComparison.OrdinalIgnoreCase) &&
                        string.Equals(Path.GetFileName(platform), "platform", StringComparison.OrdinalIgnoreCase))
                        folder = Path.GetDirectoryName(platform);
                }
                catch (System.ComponentModel.Win32Exception) { }
                catch (InvalidOperationException) { }
            }
        }
        return folder;
    }

    private static string ReadStatus(string bridge)
    {
        string path = Path.Combine(bridge, "trainer-status.txt");
        if (!File.Exists(path)) return "";
        if (File.GetLastWriteTimeUtc(path) < DateTime.UtcNow.AddSeconds(-5)) return "";
        using (var stream = new FileStream(path, FileMode.Open, FileAccess.Read,
            FileShare.ReadWrite | FileShare.Delete))
        using (var reader = new StreamReader(stream))
            return reader.ReadToEnd().Trim();
    }

    private static void WriteRequest(string bridge, string id, bool enabled)
    {
        string path = Path.Combine(bridge, "trainer-request.txt");
        string temp = path + ".tmp";
        long expiry = (long)(DateTime.UtcNow - new DateTime(1970, 1, 1, 0, 0, 0,
            DateTimeKind.Utc)).TotalSeconds + 10;
        File.WriteAllText(temp, id + " " + (enabled ? "1" : "0") + " " + expiry, Encoding.ASCII);
        if (File.Exists(path)) File.Replace(temp, path, null);
        else File.Move(temp, path);
    }
}




