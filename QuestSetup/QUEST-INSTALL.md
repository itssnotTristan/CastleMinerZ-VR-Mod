# CastleMiner Z VR — Quest installation

Published **v0.58.2 Quest installer hotfix**: [download and testing limits](https://github.com/itssnotTristan/CastleMinerZ-VR-Mod/releases/tag/v0.58.2-public-beta). The game APK remains v0.58.1/code 62; the PC setup package remains v0.58.1. The exact approved ZIP retains its Candidate filename and enclosed review notes.

This fixes normal ADB startup notices stopping Windows PowerShell 5.1 setup.
Read [the hotfix notes and testing limits](RELEASE-CANDIDATE-v0.58.2.md).
Existing working v0.58.1 headset installs need no app update; do not uninstall or
clear app data when retrying setup.

This is the standalone Quest build. You use a Windows PC once to install it and import files from your own Steam copy. After setup, the game runs on the headset without Link, Air Link, or a connected PC.

## What you need

- A Quest 2, both controllers, and a USB cable that supports data.
- A Windows 10/11 PC with CastleMiner Z installed through Steam. This beta supports the original game version **1.9.9.8**. Launch the original game once so its XNA prerequisites are installed.
- Developer Mode enabled on the headset, and USB debugging allowed inside the headset.
- The **complete Quest Setup ZIP** for this release. The small APK alone does not contain the original game textures, models, music, or sounds.
- About 6 GB free on the PC for conversion and backups, and 3 GB free on the headset for installation and game files. Updating an existing installation keeps an additional copy of the old imported files.

## First installation

1. Follow Meta's [Developer Mode and headset setup guide](https://developers.meta.com/horizon/documentation/native/android/mobile-device-setup/). This is sideloading; you are not installing through the Quest store.
2. Download the **Quest Setup ZIP**, right-click it, choose **Extract All**, and open the extracted folder. Do not run setup from inside the ZIP. Keep all included files and folders together.
3. Download Google's official [Android SDK Platform-Tools for Windows](https://developer.android.com/tools/releases/platform-tools) and extract that ZIP too. You will select its `adb.exe` if setup cannot find it automatically. A SideQuest installation can also provide adb.
4. Connect your Quest by USB. Put on the headset, allow **USB debugging**, and wake both controllers. If the prompt does not appear, check that Developer Mode is on and that the cable supports data.
5. On the PC, double-click **Setup Quest.cmd**. It finds your Steam installation or asks you to choose the folder containing `CastleMinerZ.exe`. If prompted, select `adb.exe` in the platform-tools folder. Setup uses files on your PC; it does not ask for your Steam password.
6. Leave the setup window open. It converts your own game files, verifies them, stages and verifies the USB copy, installs the APK in place, and installs the original-file check. The audio converter downloads from its official release during the first conversion. The window must finish with **Standalone Quest setup complete**.
7. In the Quest app library, choose **Unknown Sources**, then **CastleMiner Z VR - Integration**. The library filter's location can vary with headset software. Keep both controllers awake if the headset shows a controllers-required screen. The DigitalDNA intro lasts about 14 seconds before the main menu.

Once the main menu opens, you can unplug USB. Select **Play Offline**, or use the multiplayer options with players on the matching PC/Quest version.

## Updating

Use the game's update option when a matching release is available. Updates retain imported files, saves, settings, and the original-file check. PC and Quest use the same shared gameplay release; download the package for your platform.

If the release adds or changes original game assets, download its complete Quest Setup ZIP and run **Setup Quest.cmd** again. It imports the newly required files from your Steam copy. Installing the APK alone cannot supply missing game content. Existing imports are backed up before replacement; saves and settings stay in place.

**Do not uninstall the app or clear its data to update.** Doing so can remove saves, settings, and the original-file check. Use the normal update or setup process instead.

## Common problems

| Message or symptom | What to do |
| --- | --- |
| No Quest detected / unauthorized | Keep the headset awake, allow USB debugging inside it, and use a data cable. Disconnect other Android devices or specify the Quest serial. |
| adb.exe not found | Extract Google's Platform-Tools ZIP and select the `adb.exe` inside it. Keep its DLLs beside it. |
| Original game missing or unsupported | Install and verify CastleMiner Z through Steam. Select the original game folder, not the mod folder. Supported original version: 1.9.9.8. |
| XNA 4 missing | Launch the original Steam game once and install its prerequisites, then retry setup. |
| Missing or different game files | Run the complete setup for this release. Keep the headset connected until both conversion and transfer verification finish. |
| Controllers required | Wake both controllers and open the app again. |
| Insufficient storage | Free space yourself before retrying. Setup preserves previous imports rather than deleting them automatically. |
| Update signature mismatch | Stop and check that the APK came from the official project release. Do not uninstall to force the update; report the error first. |
| Multiplayer version mismatch | Both players should use the matching shared PC/Quest release. Unmodified Steam desktop servers are not supported. |

For support, include the mod version, headset model, and exact error. Conversion logs are under `%LOCALAPPDATA%\CastleMinerZ-PCVR-Setup`. Review logs for personal information before sharing them.

## Advanced setup

From PowerShell in the extracted setup folder, you can supply paths explicitly:

```powershell
.\Setup-QuestStandalone.ps1 -GameDirectory 'D:\SteamLibrary\steamapps\common\CastleMiner Z' -Adb 'C:\platform-tools\adb.exe'
```

Use `-Serial` when more than one Android device is connected. `-PrepareOnly` converts and verifies files without changing the headset. `-ImportDirectory` can reuse a previously converted folder; setup verifies every required file before using it.

## Original-game requirement

Own CastleMiner Z and import files from your own Steam installation. Public downloads do not include the original game content. The app verifies the supported original executable file; it does **not** log in to Steam or verify account entitlement. Do not share your converted game-data folder or an APK repacked with original assets. This project is unofficial and is not endorsed by the game's developers.
