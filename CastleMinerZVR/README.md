# CastleMiner Z PC VR

Review candidate **v0.58.3/code 63** adds explicit Quest 3 and optional Touch Plus support, preserves Quest 2 and the ADB/HUD repairs, and fixes the reproduced PC intro sampler collision. Physical headset and reporter VirtualDesktopXR acceptance remain untested. [Changes, install/update guidance and evidence](https://github.com/itssnotTristan/CastleMinerZ-VR-Mod/releases/tag/v0.58.3-public-beta).

An unofficial PC VR mod for the Steam version of CastleMiner Z, by ItssnotTristan. Play with tracked head movement, motion controllers, two-handed weapons and VR menus. PC graphics include bloom, dynamic shadows, adjustable block parallax and four quality presets.

**[Download the PC VR beta](https://github.com/itssnotTristan/CastleMinerZ-PCVR/releases/tag/v0.58-public-beta)** · **[Full setup guide](SETUP.md)**

## Install

1. Install CastleMiner Z through Steam and launch the original game once. This beta supports game version **1.9.9.8**.
2. In Steam, right-click CastleMiner Z → **Manage → Browse local files**.
3. Download `CastleMinerZ-PCVR-v0.58-PublicBeta.zip` from Releases. Extract its **entire contents** into that game folder, beside `CastleMinerZ.exe`.
4. Run **Setup CastleMiner Z VR.cmd** and leave its window open until it says setup is complete. It converts the required files from your own installation. The first setup downloads the audio converter from its official release.
5. Enter **Quest Link or Air Link**, wake both controllers, and make Meta Quest Link your active OpenXR runtime.
6. Run **Play CastleMiner Z VR.cmd**. Point a controller at **Play Offline** and squeeze its trigger.

The ZIP contains the mod and setup tools. Original game textures, models, music and sounds are imported locally; they are not included in the download. The original game executable stays unchanged. Setup requires Windows 10/11 64-bit, the game's XNA 4 prerequisites and an OpenGL 4.5-capable graphics driver. Allow about 2 GB free for conversion and imported files, plus another 1.5 GB for the optional local HD pack.

## Controls

| Control | Action |
| --- | --- |
| Left stick | Walk |
| Left stick click | Sprint |
| Right stick | Turn / hotbar selection, depending on bindings |
| Right stick click | Switch hotbar row |
| Right A | Jump; press again in the air to double jump using stamina |
| Right trigger | Fire / use selected item |
| Right B | Reload, or eject a magazine in Manual mode |
| Grips | Grab items, hold a magazine or support a weapon |
| Left X | Interact with doors, storage and special blocks |
| Left Y | Inventory; hold for crafting |
| Left menu button | Pause / options |

Options includes seated/standing modes, turn speed, controller bindings, automatic/manual reload and hand calibration. Saved custom bindings can change these defaults.

## Graphics

Choose Performance, Balanced, Quality or Ultra in Options. Bloom and parallax can be adjusted independently. Hardware ray tracing is not included.

To create an optional HD pack from your local imports, run **Generate HD Textures.cmd** after setup. It applies filtered 2× upscaling on your PC and preserves original files. Switch it using **HD textures On/Off**. An existing HD pack is kept. Enhanced texture packs are not bundled in this public download.

## Multiplayer and updates

This PC beta uses **shared-v0.58**, network protocol **3**, guest checkpoint version **2**, and content fingerprint **15070507204261208425**. Quest peers need the matching v0.58 build and their own imported game files. Earlier Quest public updates, including v0.53, are not the matching release. Unmodified desktop Steam servers are not supported.

Use Nearby for the same network, or Host Internet / Join Internet for the shared internet world list. Internet connections depend on the directory service and a working peer connection. Different-home PC/Quest headset testing remains pending.

Both platforms use the shared update repository. Match the PC and Quest v0.58 releases. Code updates retain imports and saves; when a release changes imported assets, run its complete setup again. This release requires five new original presentation/effect files and an updated icon atlas.

## Status and support

This is a playable beta, with original-game feature parity still in progress. The public installer has been tested against the supported Steam installation; rendering and local host/guest checks are automated. This new public installation path still needs wearer testing. See [SETUP.md](SETUP.md) for logs, troubleshooting and uninstall steps.

This repository contains player downloads and local setup tools. Historical private development/test archives are kept separately. Please include your mod version, headset and `pcvr.log` when reporting a problem; remove personal information before sharing logs.

Dependencies include OpenXR, GLFW, GLEW, zlib, libdatachannel, mbedTLS, miniaudio and vgmstream. Their notices accompany the distribution. CastleMiner Z and its original content belong to their respective owners. This project is unofficial and is not endorsed by the game's developers.

## v0.58 imports and gameplay

Run setup again after installing this release so it imports the original dragon fire/ice effects and player death clip. Setup keeps a backup of the previous import and preserves existing HD packs. Matching Quest/PC v0.58 adds dragon landing/rest, a red Click to Respawn screen and original far-world Lantern Land terrain near 46.3 km. Physical headset and different-home testing remain pending.

## Quest standalone installation manual

Download the [v0.58.2 Quest setup ZIP](https://github.com/itssnotTristan/CastleMinerZ-VR-Mod/releases/download/v0.58.2-public-beta/CastleMinerZVR-Quest2-v0.58.2-SetupCandidate.zip). Setup is v0.58.2; its APK remains v0.58.1/code 62. Extract the complete ZIP and open **START-HERE.html** before running **Setup Quest.cmd**. The setup kit includes the APK and local import tools. A Windows PC with your Steam installation is needed for setup; standalone play afterward does not need Link or a connected PC.

The [Quest installation manual](../QUEST-INSTALL.md) covers Developer Mode, USB debugging, game-file import, Unknown Sources, updates that preserve saves, and troubleshooting. Installing the small APK alone does not supply original game content.

## v0.58 fixes

Restores the gold crate crafting icon and direct crafting-to-hotbar placement. Laser block destruction uses the original Laser/Harvest material tables and original BlasterFlash impact. Dragons use all four original trail layers and all four original impact layers, with the original fire/ice family mapping and emission timing. Distant dragons no longer inherit the loaded-terrain-edge fog. DigitalDNA intro art and original loading-screen artwork are included through your local import. Bounded spawn-location retries prevent failed placements from wasting natural spawn opportunities. PC HD textures, parallax and enhanced lighting remain available.

Current validation: fresh owned-file import, native PC/Quest builds, actual-app scripted crafting/combat/spawning, GPU feedback rendering, and local host/guest checks. Physical v0.58 headset and different-home multiplayer acceptance remain pending. Original-game feature parity is still in progress.
