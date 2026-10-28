# Quest setup v0.58.4: checked asset directories

This installer-only hotfix keeps app **v0.58.3/code 63**, its original signer,
Quest 2/3 declarations, PC renderer and existing update feeds unchanged.
Working installations need no new APK. For failed imports, extract the complete
v0.58.4 Quest Setup ZIP and run **Setup Quest.cmd** again with the same Steam
installation. APK sideloading alone cannot provide original game assets or
complete the original-file check; a select-game prompt can mean setup is incomplete.

Setup now derives every parent directory from validated manifest paths and
creates it with a checked `adb shell mkdir -p` before `adb push`. The supported
tree has 255 root files and 161 audio files. Original audio leaf names containing
spaces or semicolons remain valid; unsafe directory paths, traversal, duplicate
paths and file/directory conflicts are rejected. No chmod, chown, permission
grant, security change, uninstall or data clearing is used.

File verification still precedes APK installation and the import rename commit.
Directory and push failures stop before those stages. Every retry uses a fresh
GUID staging folder; failed partial copies do not become active imports. Existing
imports are backed up on commit. The original-input and HUD checks are retained.

## Evidence and limits

The old root-only sequence and released full entry are tested with the real
installed Google ADB client against a loopback-only sync/shell model. The fixture
explicitly injects best-effort bulk-mkdir failure and rejects missing nested
parents with `remote secure_mkdirs failed: Operation not permitted`. This checks
the native push/exit-code contract; it is **not Android permission reproduction**.
The patched path checks parents before pushing, verifies exact transferred bytes,
and covers directory denial, partial push, checksum failure, install failure,
retry isolation, local path spaces, original audio leaf names, prior imports and
save/settings sentinels. Windows PowerShell 5.1 and PowerShell 7 are tested,
including the final extracted ZIP. Existing native stdout/stderr/argv and ADB
cold/warm discovery checks are retained.

No Quest was connected. The installed Android emulator could not start because
this PC lacked its required free disk space. Physical Quest 3/2 permission behavior,
installation/upgrades, save preservation, gameplay and headset performance remain
unverified. Model/sentinel checks are not physical-device acceptance. AOSP's
[ADB sync implementation](https://android.googlesource.com/platform/packages/modules/adb/+/refs/heads/main/daemon/file_sync_service.cpp)
shows that creating missing parents can attempt ownership changes; this supports
preparing parents separately, but does not prove the reporter's exact OS cause.

## If setup still fails

Keep the complete error, headset model, headset OS and `adb version`. Check USB
connection, wake/unlock the headset, close the game, and check free headset storage.
Retry the full v0.58.4 Setup ZIP. If checked directory creation itself reports
Operation not permitted, setup stops safely: do not force storage permissions or
uninstall/clear data. If the app is absent, retain that fact with the error; this
hotfix does not speculatively move APK installation ahead of verified transfer.

Use your own supported Steam game v1.9.9.8. Public assets exclude original game
content; original-file hashes do not verify Steam entitlement. Generated HUD
receipts are structural/corruption checks, not original-pixel authentication.
Included licenses and original signing identity are retained. Installer repairs,
tests and packaging were assisted by OpenAI Codex; no new art/audio was generated.
