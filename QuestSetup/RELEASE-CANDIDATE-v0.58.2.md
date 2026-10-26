# v0.58.2 Quest installer hotfix candidate

This is an unpublished Windows installer revision for [issue #3](https://github.com/itssnotTristan/CastleMinerZ-VR-Mod/issues/3).
It fixes setup stopping on ADB's normal daemon-startup notice under Windows
PowerShell 5.1. Both the standalone installer and original-file helper now capture
native stdout/stderr and reject explicit nonzero exit codes. Argument arrays,
including paths with spaces and compound shell commands, stay intact.

The enclosed APK is the unchanged, previously published v0.58.1 APK: version code
62, version name `0.58.1-installer-hud`, SHA-256
`a8ef28f26544ac415f0303c897704b0919ee3cf9f39f23fa60122aaa5a38674b`.
It was built on GitHub and retains the original signer. No APK rebuild, new
signing, PC runtime change, gameplay change or update-feed change is needed for
this Windows-only installer repair. PC users can keep the v0.58.1 PC setup ZIP.

## Retrying setup

Extract this complete Quest setup ZIP to a new folder and run **Setup Quest.cmd**.
Keep the included files together. Use the same supported Steam game folder and
allow USB debugging in the headset as usual. `-ImportDirectory` can reuse an
existing converted folder after setup verifies it. You do not need to uninstall
the app, clear app data, remove imports, reset debugging authorization, or change
your ADB installation to address the startup notice. Close the game before setup.

Already working v0.58.1 headset installations need no app update for this fix.
The APK, supported original-input hashes, import format and existing-import
compatibility are unchanged. See [the v0.58.1 notes](RELEASE-CANDIDATE-v0.58.1.md)
for the retained HUD, integrity and rollback behavior. Generated HUD receipts
remain structural/corruption checks, not original-pixel authenticity against a
regenerated receipt.

## Testing boundary

The released bug reproduced on the owner's Windows PC using installed Android
SDK ADB 37.0.0 (1.0.41) and Windows PowerShell 5.1.26100.9711. Cold startup failed
with `NativeCommandError` in both released entry points even though subsequent
real device discovery exited 0. Warm startup reached the expected no-Quest stop.

Both fixed full entry points passed cold and warm real-ADB discovery under
PowerShell 5.1.26100.9711 and 7.6.5, reaching the clear no-Quest message rather
than a native-stderr exception. An emulator appeared on the default server, so
remaining tests used a separate localhost port with process-local emulator and
Wi-Fi auto-discovery disabled. The default server was left running. No Quest
headset was connected; these checks did not install or launch an app or touch
device data. Regression checks also cover successful stderr, stdout-only success,
precise nonzero failures, argument boundaries, and simulated installer retry and
rollback paths.

Physical Quest installation, upgrades and save preservation, gameplay, another
or the reporter's PC/ADB version, GPU behavior, WAN and headset performance are
not established by these tests. The scripts run on a Windows PC; an APK-only
in-game update cannot replace them.
