# 黑魔伤常驻凝气于刃 / Infernal Rouge Always Buff

[简体中文](#简体中文) · [English](#english)

## 简体中文

《影之刃零》单机 Mod。打开开关并装备黑魔伤后，会维持一层原版「凝气于刃」效果，同时禁用擦刀动作。换到其他武器会移除效果，换回黑魔伤会恢复。关闭开关即可恢复手动擦刀。

**要求** · Windows x64、Steam build `26367565`、适用于该游戏版本的 UE4SS。

1. 在 **Releases** 下载并解压 Mod ZIP。
2. 在游戏关闭时，把 `mod/PBZHeiMoShangAlwaysBuff` 文件夹复制到游戏目录下的 `platform/steam/ue4ss/Mods/`。如果装过旧版，请先禁用旧版。
3. 运行 `PBZ-HeiMoShang-AlwaysBuff-x64.exe`。工具会自动检测正在运行的 Steam 版游戏，可以先开工具或先开游戏。
4. 启动游戏并载入存档，装备黑魔伤后勾选开关。
5. 卸载时先关闭开关、退出游戏和工具，再移除上面复制的 Mod 文件夹。

原版 Mod 效果在 build `26367565` 实机验证过。发布版已编译，自动检测尚未在游戏内复测。

## English

A single-player mod for Phantom Blade Zero. Enable the toggle and equip Infernal Rouge to keep one stack of its original weapon buff active while skipping the blade-wipe animation. Switching away removes the buff. Switching back reapplies it. Turn the toggle off to restore manual blade wiping.

**Requirements** · Windows x64, Steam build `26367565`, and a compatible UE4SS installation.

1. Download the mod ZIP from **Releases** and extract it.
2. With the game closed, copy `mod/PBZHeiMoShangAlwaysBuff` into `platform/steam/ue4ss/Mods/` inside the game directory. Disable any older version of this mod first.
3. Run `PBZ-HeiMoShang-AlwaysBuff-x64.exe`. It detects the running Steam game automatically. You can start either one first.
4. Start the game, load a save, equip Infernal Rouge, and enable the toggle.
5. To uninstall, turn the toggle off, close the game and utility, and remove the mod folder copied above.

The original in-game behavior was tested on build `26367565`. The release build compiles. Automatic detection has yet to be retested with the game.

## 构建 / Build

From the repository root, run the following in PowerShell on Windows x64 with .NET Framework 4.x installed.

```powershell
& "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /nologo /warnaserror /codepage:65001 /platform:x64 /target:winexe /out:PBZ-HeiMoShang-AlwaysBuff-x64.exe /reference:System.Windows.Forms.dll /reference:System.Drawing.dll (Resolve-Path src/PBZNoWipeWindow.cs).Path
```

UE4SS is installed separately.


