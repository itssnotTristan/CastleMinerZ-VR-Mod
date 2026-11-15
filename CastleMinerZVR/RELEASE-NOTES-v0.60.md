# v0.60 — matching PC and Quest avatar/graphics update

Both apps use **build 64 / 0.60-quest-avatar-graphics**, shared-v0.58 gameplay, protocol 3, and the existing content fingerprint. Update both players for the new avatar features. PC retains its HD textures, lighting, bloom, shadows, and adjustable parallax.

- One ARM64 APK explicitly targets Quest 2, Quest 3, and Quest 3S. Legacy Touch bindings remain; optional Touch Plus bindings are capability gated.
- Quest 3/3S get **Options > Quest graphics > Block parallax**, with Off/Low/Medium and adjustable strength. Quest 2 keeps its original graphics profiles and does not allocate the relief texture.
- Quest startup checks and imports game data in a visible setup panel before entering VR. Missing files produce recovery buttons rather than an unseen pre-XR error. Existing imports/saves are preserved; an optional personal game-data ZIP can be imported on the headset.
- Player Avatar includes a 360sona headset editor panel and local GLB conversion. Export a complete 71-bone avatar in T-pose with embedded PNG/JPEG textures. PC also imports GLB directly. Existing tracked glove/weapon anchors remain.
- PC enemy HD loading restores the original emission mask and recovers diffuse pixels erased by treating that mask as opacity. Terrain parallax calculations bypass skinned actors. The exact reported black-enemy failure was not reproduced with the local HD pack.
- Keeps the newer public installer transfer checks, generated-HUD validation, and first-frame PC shadow-sampler initialization. Known legacy private terrain imports remain accepted.

## Install

For a fresh PC installation, extract the complete PC Setup ZIP into the Steam CastleMiner Z folder beside `CastleMinerZ.exe`, run **Setup CastleMiner Z VR.cmd**, then **Play CastleMiner Z VR.cmd**. Existing working installations can use the code-only update. Keep `game`, `graphics-hd`, and your profile data.

For a fresh standalone Quest installation, extract the complete Quest Setup ZIP and follow **QUEST-INSTALL.md**. Run **Setup Quest.cmd** with your own supported Steam installation and an authorized USB connection. The public APK alone contains no original game assets. Selecting the original EXE verifies that file; it does not import the rest of the game or check Steam account entitlement.

An existing complete installation can use the matching APK/update in place. Do not uninstall or clear app data. A full private test APK prepares its included imports automatically; that private package is separate from the public asset-free release.

## Verification limits

Real GPU checks cover all 53 enemy definitions with HD off/on/off, the actual Quest parallax shader, native GLB animated rendering, unchanged glove pixels and rig anchors, and avatar-menu pointer rows. Java checks cover extraction, startup file checks, complete existing imports, ZIP recovery and rejection paths. Production local peers exercise pose/edit/sound replication, authentication, and avatar transfer/switches. These are desktop/local checks.

No physical Quest is connected. Quest 2/3/3S installation, controller tracking, live 360sona export, headset frame rate/comfort, physical PC VR play, and different-home multiplayer acceptance remain untested in this release. Original-game feature parity remains incomplete.
