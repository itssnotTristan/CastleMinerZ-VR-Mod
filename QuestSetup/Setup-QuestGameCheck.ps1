param(
    [string]$GameDirectory,
    [string]$Adb,
    [string]$Serial,
    [switch]$CheckOnly,
    [switch]$NoLaunch
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2
$expected = '45d951391f204a20803c5e249d7f43fec0acbf320f5cf6c3e42ccccfe778cea3'
function Get-CmzGameHash([string]$Path) {
    $stream = [IO.File]::OpenRead($Path)
    $hash = [Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($hash.ComputeHash($stream)).Replace('-','').ToLowerInvariant() }
    finally { $hash.Dispose(); $stream.Dispose() }
}
if (-not $GameDirectory) {
    $roots = @('C:\Program Files (x86)\Steam')
    $steam = Get-ItemProperty -LiteralPath 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue
    if ($steam -and $steam.PSObject.Properties['SteamPath']) { $roots += $steam.SteamPath }
    foreach ($root in @($roots | Select-Object -Unique)) {
        $libraries = Join-Path $root 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $libraries) {
            foreach ($match in [regex]::Matches((Get-Content -LiteralPath $libraries -Raw), '"path"\s+"([^"]+)"')) {
                $roots += $match.Groups[1].Value.Replace('\\','\')
            }
        }
    }
    foreach ($root in @($roots | Select-Object -Unique)) {
        $candidate = Join-Path $root 'steamapps\common\CastleMiner Z'
        if (Test-Path -LiteralPath (Join-Path $candidate 'CastleMinerZ.exe')) { $GameDirectory = $candidate; break }
    }
}
if (-not $GameDirectory) { throw 'CastleMiner Z was not found. Run this script with -GameDirectory followed by your Steam game folder.' }
$game = Join-Path $GameDirectory 'CastleMinerZ.exe'
$file = Get-Item -LiteralPath $game
if ($file.PSIsContainer -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -or $file.Length -ne 846848 -or (Get-CmzGameHash $file.FullName) -ne $expected) {
    throw 'This is not the supported original CastleMiner Z 1.9.9.8 executable. Verify the Steam installation. Do not rename another file.'
}
Write-Host 'Original CastleMiner Z installation file verified. Steam account ownership is not checked.'
if ($CheckOnly) { return }
if (-not $Adb) {
    $command = Get-Command adb -ErrorAction SilentlyContinue
    if ($command) { $Adb = $command.Source }
    else { $Adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe' }
}
if (-not (Test-Path -LiteralPath $Adb -PathType Leaf)) { throw 'Android platform-tools (adb) was not found. Supply -Adb with the adb.exe used to install the APK.' }
function Invoke-QuestAdb {
    param([Parameter(Mandatory=$true)][string[]]$Arguments)
    # Windows PowerShell turns native stderr (including successful ADB startup
    # notices) into ErrorRecords. Capture it, then decide using the exit code.
    $previousPreference=$ErrorActionPreference
    $global:LASTEXITCODE=$null
    try {
        $ErrorActionPreference='Continue'
        $PSNativeCommandUseErrorActionPreference=$false
        $result=& $Adb @Arguments 2>&1
        $exitCode=$global:LASTEXITCODE
    } finally { $ErrorActionPreference=$previousPreference }
    if($null -eq $exitCode){throw ('Quest USB command could not start: '+($result -join "`n"))}
    if($exitCode -ne 0){throw ('Quest USB command failed (exit '+$exitCode+'): '+($result -join "`n"))}
    return ($result -join "`n")
}
$devices = Invoke-QuestAdb -Arguments @('devices','-l')
$ready = @([regex]::Matches($devices, '(?m)^([^\s]+)\s+device\b') | ForEach-Object { $_.Groups[1].Value } | Where-Object { -not $_.StartsWith('emulator-') })
if (-not $Serial) {
    if ($ready.Count -ne 1) { throw 'Connect one Quest by USB, allow USB debugging in the headset, or specify -Serial when multiple devices are connected.' }
    $Serial = $ready[0]
}
if ($ready -notcontains $Serial) { throw 'The selected Quest is not connected and authorized for USB debugging.' }
$model = Invoke-QuestAdb -Arguments @('-s',$Serial,'shell','getprop','ro.product.model')
if ($model -notmatch '(?i)quest') { throw 'The selected device is not identified as a Quest headset.' }
$installed = Invoke-QuestAdb -Arguments @('-s',$Serial,'shell','pm','path','org.codex.castleminerzvr')
if ($installed -notmatch 'package:') { throw 'Install the CastleMiner Z VR Quest APK first, then run this helper again.' }
$remote = '/sdcard/Android/data/org.codex.castleminerzvr/files/owned-game'
if((Invoke-QuestAdb -Arguments @('-s',$Serial,'shell','if pidof org.codex.castleminerzvr >/dev/null; then echo running; fi')).Trim() -eq 'running'){throw 'Close CastleMiner Z VR in the headset, then run setup again. Your game was not interrupted.'}
Invoke-QuestAdb -Arguments @('-s',$Serial,'shell','mkdir','-p',$remote) | Out-Null
Invoke-QuestAdb -Arguments @('-s',$Serial,'push',$file.FullName,($remote + '/CastleMinerZ.exe.pending')) | Out-Null
$remoteHash = Invoke-QuestAdb -Arguments @('-s',$Serial,'shell','sha256sum',($remote + '/CastleMinerZ.exe.pending'))
if (-not $remoteHash.StartsWith($expected, [StringComparison]::OrdinalIgnoreCase)) { throw 'USB transfer did not match the original file. Run setup again.' }
Invoke-QuestAdb -Arguments @('-s',$Serial,'shell','mv',($remote + '/CastleMinerZ.exe.pending'),($remote + '/CastleMinerZ.exe')) | Out-Null
if(-not $NoLaunch){Invoke-QuestAdb -Arguments @('-s',$Serial,'shell','am','start','-n','org.codex.castleminerzvr/.VrActivity') | Out-Null}
Write-Host 'Quest setup complete. The game will verify the file and keep it in private app storage. Normal updates retain it; reinstalling or clearing app data requires setup again.'
