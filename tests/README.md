# Installer regression checks

These checks use disposable workspace folders. They never uninstall, clear app
data, or operate a real ADB device. Keep all converted original content private.

Compile `AdbStub.cs` with the .NET Framework C# compiler, referencing
`System.Web.Extensions.dll`, and place its executable in a path containing spaces.
Run `Test-AdbArguments.ps1` with `-Stub` and `-Log` under Windows PowerShell 5.1
and PowerShell 7. It extracts the actual production wrapper functions, tests native
argv boundaries, and reproduces the old 5.1 collection-binding defect.

Run `Test-SourceInputs.ps1 -Work <new-workspace-folder>` under both shells. It
uses synthetic input bytes to check good files, same-size corruption, a stale
manifest and traversal. `Test-GeneratedHud.ps1 -Atlas <private-hud-items.rgba>
-Work <new-workspace-folder>` checks the actual generated policy, receipt
tampering, malformed dimensions, truncation, blank/black output, a missing icon
and invalid transparency. Its color variant is synthetic, not a second GPU test.

For `test_installers.py`, set these environment variables:

- `CMZ_REAL_GAME`: the supported owned Steam installation, read only.
- `CMZ_IMPORTS`: a freshly converted, fully verified private game folder.
- `CMZ_ADB_STUB`: the inert compiled stub, never a real `adb.exe`.
- `CMZ_TEST_WORK`: a new disposable workspace folder.
- `CMZ_TEST_PS`: the PowerShell executable to test (defaults to Windows 5.1).

Run the Python unittest script normally. Seven scenario groups execute production
scripts for PC fresh install, upgrade, injected commit failure, rollback/retry,
save/settings/HD preservation, APK corruption, device selection, an active game,
transfer/install/commit failure, generated checksums and unsupported originals.
All supported original inputs are checked. Transaction fixtures use a two-output
manifest for speed; a separate real fresh conversion and extracted-package run
must check all 416 outputs.

`test_quest_commit.py --adb-log <stub-log> --work <new-workspace-folder>` runs the
actual captured compound shell command with its fixed app path mapped into that
folder. Git Bash tests fresh install, upgrade, first-rename failure and second-
rename failure with rollback. This is host shell evidence, not Android filesystem
or physical save-preservation acceptance.

The private GitHub source workflow additionally runs the native generated policy
under ASan/UBSan and complete affected import, Java ZIP/download/installer,
JNI/JVM, startup, update menu, Android API and shutdown suites before signing.
