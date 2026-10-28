# Installer regression checks

These checks use disposable workspace folders. They never uninstall, clear app
data, or operate a real ADB device. Keep all converted original content private.

Compile `AdbStub.cs` with the .NET Framework C# compiler, referencing
`System.Web.Extensions.dll`, and place its executable in a path containing spaces.
Run `Test-AdbArguments.ps1` with `-Stub` and `-Log` under Windows PowerShell 5.1
and PowerShell 7. It extracts the actual production wrapper functions, tests native
argv boundaries, and reproduces the old 5.1 collection-binding defect.
It also checks successful stdout/stderr, stdout-only success, and the exact exit-7
failure message with the caller's native error preference both enabled and
disabled. Stderr alone must not fail a command; a nonzero exit must fail it.

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

Run the Python unittest script normally. Nine scenario groups execute production
scripts for PC fresh install, upgrade, injected commit failure, rollback/retry,
save/settings/HD preservation, APK corruption, device selection, an active game,
transfer/install/commit failure, generated checksums and unsupported originals.
Quest 2/Quest 3 discovery is exercised with inert device models.
Both Quest entry points must complete with a synthetic startup notice on stderr
and must reject a true native failure before any device writes.
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

`Test-QuestTransferPaths.ps1` exercises the actual manifest-directory function:
all416 supported files, nested parents, original audio leaf names with spaces
and semicolons, traversal, unsafe directories, duplicates and path conflicts.

`test_quest_transfer.py --adb <trusted-installed-adb.exe> --ps <shell.exe>
--work <new-workspace>` executes production transfer functions with the real
native client against `adb_transfer_server.py`, a loopback-only smart-socket,
sync and shell model. It injects failure of ADB's best-effort bulk mkdir,
rejects missing parents with the reported secure_mkdirs failure, and checks the
old exit1 path, corrected exact bytes, checked directory failures and partial
push failure. This is protocol/transaction evidence, NOT Android permission
reproduction or headset acceptance. The fixture never executes an Android shell
or connects to an Android device. It holds transfer bytes only in process memory.

For private full-entry tests, additionally pass `--full-entry <supported-game>
--imports <verified-private-imports> --script <extracted-setup-script>
--old-script <released-old-script>`. Both complete production entries retain
their original input/APK validation. Cases cover directory denial, partial push,
checksum mismatch, install failure, exact transferred bytes, backup/saves and
retry isolation with fresh GUIDs. Run both shells against the exact extracted
final package. Do not put original inputs or private logs in public CI/artifacts.
