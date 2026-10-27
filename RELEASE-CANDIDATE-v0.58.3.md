# v0.58.3 PC rendering and Quest 3 support

Version code **63**, app version **0.58.3-quest3-pc-eye**, retains shared-v0.58
gameplay, network protocol 3, existing imports, saves and the original Quest
signer. The exact reviewed packages were approved and published unchanged. [Release page](https://github.com/itssnotTristan/CastleMinerZ-VR-Mod/releases/tag/v0.58.3-public-beta) records the hashes and publication status; the archived Candidate filenames and enclosed notes are preserved.

## PC first-frame rendering

The intro could draw before terrain rendering initialized the shadow sampler.
That sampler defaulted to texture unit 0, already used by the diffuse sampler of
a different type. Desktop OpenGL rejected the first intro draw with error 1282.
All three PC shader programs now initialize distinct sampler units before any
draw. Driver error messages and separate intro/scene/presentation checkpoints
identify the failing operation and framebuffer/preset dimensions if another GL
error occurs. The log banner now records the actual app version.

The defect reproduced on the owner's RTX 4060 / NVIDIA 610.88 / OpenGL 4.5.
After correction, 216 production GPU intro/presentation cases passed: three eye
resolutions including the reported 2640x2880, four presets, three bloom levels,
both eye paths and three intro times. The visible intro contained 1,159,210 lit
pixels. All 16 retained scene diagnostics, four preset coverage checks and 120
storage-render frames also passed in fresh private profiles.

These are real GPU tests with ordinary eye-like textures, not a physical OpenXR
swapchain/headset test. The reporter's NVIDIA 621.01 / VirtualDesktopXR setup is
not available here and is not claimed accepted. No driver/runtime switch is
required by this repair.

## Quest 2 and Quest 3

The APK now explicitly declares **Quest 2 and Quest 3**. Optional Touch Plus
bindings are enabled only when the OpenXR runtime advertises the capability;
required legacy Touch bindings remain available and optional-profile rejection
does not abort startup. Runtime hardware/tracking properties are logged. Eye
targets remain bounded by runtime and GPU capabilities. Minimum SDK 29, target
SDK 34, GLES 3.2 and ARM64 requirements are unchanged. Quest 3S is not declared
or physically accepted by this release.

The GitHub build verifies the compiled APK device declaration, original signer,
sealed source and asset-free packaging, plus controller fallback and existing
validation/update/lifecycle regressions. No original game assets are packaged.
The legacy `Quest2` asset filenames now serve both declared models; use the
complete matching setup ZIP for a fresh installation.

The v0.58.2 ADB stderr/exit-status repair and v0.58.1 original-input/generated-HUD
checks remain in place. Source hashes establish supported original input identity;
the editable generated HUD receipt provides structural/corruption checks, not
original-pixel authenticity against a regenerated receipt. The executable check
does not establish Steam account entitlement.

## Install and update

- PC VR: use the complete `CastleMinerZ-PCVR-v0.58.3-SetupCandidate.zip`. Existing
  installations can use the matching code-only in-game update, which replaces
  runtime files while retaining imports and saves.
- Quest: extract `CastleMinerZVR-Quest2-v0.58.3-SetupCandidate.zip` on Windows and
  run **Setup Quest.cmd** with your own supported Steam version 1.9.9.8. Existing
  compatible imports can be retained by an in-place same-signer APK update.
- Close the app before setup. **Do not uninstall or clear app data.** A failed
  setup can retry; `-ImportDirectory` can reuse verified conversions. Old exact
  v0.58 imports remain accepted without a receipt migration.

No Quest is connected. Physical Quest 2/3 installation, upgrade/save preservation,
controller fit, gameplay, headset performance, another/reporting runtime or GPU,
and WAN acceptance remain untested. Installer doubles and host rollback checks
do not establish physical save preservation. Keep prior compatible packages and
backups available.

CastleMiner Z VR mod by ItssnotTristan; original game by DigitalDNA Games.
Unofficial mod. Coding/testing assistance: Codex (OpenAI). Third-party licenses
are included. Do not distribute imported original game content or private source.
