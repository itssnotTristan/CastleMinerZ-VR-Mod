# CastleMiner Z VR Mod

Unofficial PC VR and standalone Quest port by ItssnotTristan. For support, message **itssnottristan** on Discord and include the version, headset model, and exact error.

## v0.60 — matching PC and Quest update

[PC VR setup](https://github.com/itssnotTristan/CastleMinerZ-VR-Mod/releases/download/v0.60/CastleMinerZ-PCVR-v0.60-Setup.zip) · [Quest 2 / 3 / 3S setup](https://github.com/itssnotTristan/CastleMinerZ-VR-Mod/releases/download/v0.60/CastleMinerZVR-Quest-v0.60-Setup.zip) · [Release notes and testing limits](RELEASE-NOTES-v0.60.md)

Both platforms use build64 / **0.60-quest-avatar-graphics**, shared-v0.58 gameplay and protocol3. Existing PC HD textures, bloom, shadows, and parallax remain. Quest 3/3S get optional adjustable block parallax; Quest 2 keeps its existing graphics profiles. The avatar picker supports local GLB conversion, with a 360sona editor panel on Quest. [Avatar instructions](AVATARS.md).

## Installation

**PC VR:** Install CastleMiner Z 1.9.9.8 through Steam and launch the original once. Extract the complete PC Setup ZIP beside `CastleMinerZ.exe`. Run **Setup CastleMiner Z VR.cmd**, then **Play CastleMiner Z VR.cmd**. Enter Link/Air Link or your working OpenXR PC VR connection first. [Detailed PC setup](SETUP.md).

**Quest standalone:** Use the complete Quest Setup ZIP and follow [QUEST-INSTALL.md](QUEST-INSTALL.md). Connect the headset by USB, enable Developer Mode, allow USB debugging, and run **Setup Quest.cmd** on Windows. It converts your own Steam files and installs the app. After setup, no PC connection is needed to play. One APK targets Quest 2, Quest 3, and Quest 3S.

**Existing players:** Use the matching in-game update or replace the mod runtime/APK in place. Keep imported game data, `graphics-hd`, saves, and settings. Do not uninstall or clear app data. Public downloads contain no original game assets; an APK by itself cannot complete a fresh installation. Original-file checks remain, without a Steam login or Steam account entitlement check.

## Multiplayer

Matching PC VR and standalone Quest builds share the internet world list and LAN protocol. Unmodified Steam desktop servers are not supported. Cosmetic models are negotiated separately from shared gameplay. Local production peer checks pass; different-home and physical-headset acceptance for this release remain pending.

## Controls and settings

Left stick moves; right stick turns. Right trigger uses the selected item. Grips support weapons and manual magazines. Left X interacts with storage, doors, and special blocks; Left Y opens inventory, and holding it opens crafting. Left Menu opens pause/options. Use Options for seated/standing play, turning, reloading, hand fit, avatar selection, and graphics.

## Testing status

Desktop GPU, native conversion, file recovery, updater, and local peer checks passed. No physical Quest is connected: Quest 2/3/3S installation, live editor export, tracking, frame rate, comfort, and this release's physical PC VR/WAN play remain unaccepted. Original-game feature parity remains incomplete. See the release notes for exact scope.

[Possible future features](FEATURE-IDEAS.md) · [Credits and licenses](CastleMinerZVR/THIRD-PARTY-LICENSES.txt)

CastleMiner Z and its original assets belong to DigitalDNA Games. This project is unofficial and is not affiliated with or endorsed by the original developers. 360sona remains an external service.
