# Setup and troubleshooting

Published [Quest setup **v0.58.4**](https://github.com/itssnotTristan/CastleMinerZ-VR-Mod/releases/download/v0.58.4-public-beta/CastleMinerZVR-Quest2-v0.58.4-SetupCandidate.zip) prepares and checks the complete asset directory tree
before copying, addressing the missing-audio-parent transfer failure. The app
stays **v0.58.3/code 63**; PC packages and in-game feeds are unchanged.
[Installer changes, tests and hardware limits](RELEASE-CANDIDATE-v0.58.4.md).
No physical Quest acceptance is claimed. Use the complete Setup ZIP for a failed
import; APK sideloading alone cannot supply game assets. Do not uninstall or clear data.


Published **v0.58.3 PC/Quest repair**: [downloads and testing limits](https://github.com/itssnotTristan/CastleMinerZ-VR-Mod/releases/tag/v0.58.3-public-beta). Both apps use code 63; Quest 2 and Quest 3 are declared targets. Physical headset acceptance remains untested. Approved ZIPs retain their Candidate filenames and enclosed notes.

## Folder layout

Use the folder opened by Steam → CastleMiner Z → Manage → Browse local files. After extracting the mod, it should look like this:

```text
CastleMiner Z/
  CastleMinerZ.exe             ← original Steam game
  DNA.Common.dll
  DNA.Steam.dll
  Content/
  Setup CastleMiner Z VR.cmd   ← run once
  Play CastleMiner Z VR.cmd    ← launch VR
  Generate HD Textures.cmd    ← optional, after setup
  CastleMinerZVR/
    CastleMinerZVR.exe
    Setup-CastleMinerZVR.ps1
    importer/
    game/                     ← created by setup
```

Avoid an extra nested ZIP folder. `CastleMinerZVR` must be directly inside the original game folder. Starting CastleMiner Z through its normal Steam Play button still starts the desktop game; use the new VR launcher for this mod.

## First setup

Run the original game once, then close it. Run **Setup CastleMiner Z VR.cmd**. Setup verifies the supported original executable/libraries, downloads the pinned vgmstream r2117 audio converter, and imports the required assets. It does not upload your game files or change the original executable.

Keep the setup window open until it reports completion. A failed import does not replace an existing imported game folder. Re-running successful setup keeps a backup of the previous import. For advanced/offline setup, download [vgmstream r2117](https://github.com/vgmstream/vgmstream/releases/tag/r2117), extract the Windows 64-bit ZIP, and pass its `vgmstream-cli.exe` path using the setup script's `-Decoder` option.

Setup checks the original game files at version **1.9.9.8**. This is an offline installation requirement; there is no Steam account login in the mod. Players still need their own Steam copy.

## Connect your headset

Connect Quest Link by USB, or enter Air Link with your PC. In the Meta Quest Link PC app, set Meta Quest Link as the active OpenXR runtime. Wake both controllers, enter the Link environment, then run **Play CastleMiner Z VR.cmd**.

Use a controller's pointing ray and trigger to select menu buttons. Choose Play Offline first to check tracking and controls. Recenter and adjust seated/standing height in Options if necessary.

## Optional HD textures

After a successful setup, run **Generate HD Textures.cmd**. It creates `CastleMinerZVR/graphics-hd` from your local game files using filtered 2× upscaling. The original imported textures remain in `game`. Existing HD packs are preserved. In the game, use HD textures On/Off, Block parallax On/Off, Parallax strength and the graphics preset options.

## Common problems

| Problem | Check |
| --- | --- |
| Installation required / unsupported original file | Verify game files in Steam; confirm the folder layout above and supported version 1.9.9.8. |
| XNA 4 is missing | Launch the original Steam game once to install its prerequisites. |
| Setup cannot download the converter | Check internet access to GitHub, or supply a locally downloaded r2117 converter using `-Decoder`. |
| Imported file verification fails | Keep the setup log and report the listed filenames. The previous import remains in place. |
| No headset or controllers | Enter Link/Air Link, select the Meta OpenXR runtime and wake both controllers before launching. |
| Game closes during launch | Open `%LOCALAPPDATA%/CastleMinerZ-PCVR/pcvr.log`. Check imported files and graphics drivers. |
| HD textures appear unchanged | Generate the local pack first, then enable HD textures in Options. |
| Can't see a friend's world | Both peers need the matching version. Ordinary Steam desktop servers and older Quest versions are not compatible. Internet hosting also needs the directory service and a working peer route. |

Setup logs are in `%LOCALAPPDATA%/CastleMinerZ-PCVR-Setup`, in the folder for that setup attempt. The game log and settings/saves are under `%LOCALAPPDATA%/CastleMinerZ-PCVR`.

## Update or uninstall

Close the VR game before updating. Extract the next compatible PC release into the same game folder. Follow that release's notes if a new import is required. Keep `game`, `graphics-hd` and your saves unless instructed otherwise.

To uninstall, remove the added `CastleMinerZVR` folder and the three added launcher files. The original Steam game files remain. Saves and settings stay under `%LOCALAPPDATA%/CastleMinerZ-PCVR`; remove them separately only if you want to erase them.

## v0.58 imports and gameplay

Run setup again after installing this release so it imports the original dragon fire/ice effects and player death clip. Setup keeps a backup of the previous import and preserves existing HD packs. Matching Quest/PC v0.58 adds dragon landing/rest, a red Click to Respawn screen and original far-world Lantern Land terrain near 46.3 km. Physical headset and different-home testing remain pending.

## Quest standalone installation manual

Download the [v0.58.3 Quest 2/3 setup ZIP](https://github.com/itssnotTristan/CastleMinerZ-VR-Mod/releases/download/v0.58.4-public-beta/CastleMinerZVR-Quest2-v0.58.4-SetupCandidate.zip). Both apps are v0.58.3/code 63. Extract the complete ZIP and open **START-HERE.html** before running **Setup Quest.cmd**. The setup kit includes the APK and local import tools. A Windows PC with your Steam installation is needed for setup; standalone play afterward does not need Link or a connected PC.

The [Quest installation manual](QUEST-INSTALL.md) covers Developer Mode, USB debugging, game-file import, Unknown Sources, updates that preserve saves, and troubleshooting. Installing the small APK alone does not supply original game content.

## v0.58 fixes

Restores the gold crate crafting icon and direct crafting-to-hotbar placement. Laser block destruction uses the original Laser/Harvest material tables and original BlasterFlash impact. Dragons use all four original trail layers and all four original impact layers, with the original fire/ice family mapping and emission timing. Distant dragons no longer inherit the loaded-terrain-edge fog. DigitalDNA intro art and original loading-screen artwork are included through your local import. Bounded spawn-location retries prevent failed placements from wasting natural spawn opportunities. PC HD textures, parallax and enhanced lighting remain available.

Current validation: fresh owned-file import, native PC/Quest builds, actual-app scripted crafting/combat/spawning, GPU feedback rendering, and local host/guest checks. Physical v0.58 headset and different-home multiplayer acceptance remain pending. Original-game feature parity is still in progress.
