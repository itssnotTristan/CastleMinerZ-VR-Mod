param(
    [string]$GameDirectory,
    [string]$Adb,
    [string]$Serial,
    [string]$Decoder,
    [string]$ImportDirectory,
    [switch]$PrepareOnly
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version 2
$package='org.codex.castleminerzvr'
$tools=Join-Path $PSScriptRoot 'Tools'
$manifest=Get-Content -LiteralPath (Join-Path $tools 'import-manifest.json') -Raw | ConvertFrom-Json
function Get-QuestImportDirectories {
    param([Parameter(Mandatory=$true)][object[]]$Assets)
    $directories=@{}
    $files=@{}
    foreach($asset in $Assets){
        $path=[string]$asset.path
        # Only manifest-relative, shell-safe paths may reach the headset.
        if($path -cnotmatch '^game/.+' -or $path -match '[\x00-\x1f\x7f\\:]' -or $files.ContainsKey($path)){
            throw "Invalid or duplicate Quest import manifest path: $path"
        }
        $files[$path]=$true
        $parts=$path.Substring(5).Split('/')
        foreach($part in $parts){if(-not $part -or $part -eq '.' -or $part -eq '..'){throw "Invalid or duplicate Quest import manifest path: $path"}}
        for($i=1;$i -lt $parts.Length;$i++){
            # Leaf filenames (including the original audio names with spaces
            # and semicolons) go through ADB sync/checksum data, never shell.
            if($parts[$i-1] -cnotmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$'){throw "Invalid or duplicate Quest import manifest path: $path"}
            $directories[($parts[0..($i-1)] -join '/')]=$true
        }
    }
    foreach($directory in $directories.Keys){
        if($files.ContainsKey('game/'+$directory)){throw "Quest import manifest file/directory conflict: $directory"}
    }
    return @($directories.Keys | Sort-Object Length,{$_})
}
$importDirectories=@(Get-QuestImportDirectories -Assets @($manifest.assets))
if(-not $GameDirectory){
    $roots=@('C:\Program Files (x86)\Steam')
    $steam=Get-ItemProperty -LiteralPath 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue
    if($steam -and $steam.PSObject.Properties['SteamPath']){$roots+=$steam.SteamPath}
    foreach($root in @($roots | Select-Object -Unique)){
        $libraries=Join-Path $root 'steamapps/libraryfolders.vdf'
        if(Test-Path -LiteralPath $libraries){foreach($match in [regex]::Matches((Get-Content -LiteralPath $libraries -Raw),'"path"\s+"([^"]+)"')){$roots+=$match.Groups[1].Value.Replace('\\','\')}}
    }
    foreach($root in @($roots | Select-Object -Unique)){$candidate=Join-Path $root 'steamapps/common/CastleMiner Z';if(Test-Path -LiteralPath (Join-Path $candidate 'CastleMinerZ.exe')){$GameDirectory=$candidate;break}}
    if(-not $GameDirectory){
        Add-Type -AssemblyName System.Windows.Forms
        $dialog=[Windows.Forms.FolderBrowserDialog]::new();$dialog.Description='Choose the Steam CastleMiner Z folder containing CastleMinerZ.exe.'
        try{if($dialog.ShowDialog() -ne [Windows.Forms.DialogResult]::OK){throw 'Select your Steam game folder to continue.'};$GameDirectory=$dialog.SelectedPath}finally{$dialog.Dispose()}
    }
}
$GameDirectory=(Resolve-Path -LiteralPath $GameDirectory).Path
& (Join-Path $PSScriptRoot 'Setup-QuestGameCheck.ps1') -GameDirectory $GameDirectory -CheckOnly
$cache=Join-Path $env:LOCALAPPDATA 'CastleMinerZ-Quest-Setup'
if(-not $ImportDirectory){
    $ImportDirectory=Join-Path $cache ([Guid]::NewGuid().ToString('N')+'/game')
    $arguments=@{GameDirectory=$GameDirectory;PrivateOutput=$ImportDirectory;PrepareOnly=$true}
    if($Decoder){$arguments.Decoder=$Decoder}
    & (Join-Path $tools 'Setup-CastleMinerZVR.ps1') @arguments
}
& (Join-Path $tools 'Setup-CastleMinerZVR.ps1') -GameDirectory $GameDirectory -PrivateOutput $ImportDirectory -VerifyOnly
if($PrepareOnly){Write-Host "Quest imports verified: $ImportDirectory. No headset changes made.";return}
if(-not $Adb){
    $command=Get-Command adb -ErrorAction SilentlyContinue
    if($command){$Adb=$command.Source}
    else{$candidate=Join-Path $env:LOCALAPPDATA 'Android/Sdk/platform-tools/adb.exe';if(Test-Path -LiteralPath $candidate){$Adb=$candidate}}
    if(-not $Adb){
        Add-Type -AssemblyName System.Windows.Forms
        $dialog=[Windows.Forms.OpenFileDialog]::new();$dialog.Title='Select adb.exe inside the Google platform-tools folder';$dialog.Filter='Android Debug Bridge (adb.exe)|adb.exe';$dialog.CheckFileExists=$true
        try{if($dialog.ShowDialog() -ne [Windows.Forms.DialogResult]::OK){throw 'Download and extract Google Android platform-tools, then select adb.exe. See START-HERE.html.'};$Adb=$dialog.FileName}finally{$dialog.Dispose()}
    }
}
$Adb=(Resolve-Path -LiteralPath $Adb).Path
function Quest {
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
function Copy-QuestImports {
    param([string]$ImportDirectory,[string]$Incoming,[string]$Serial,[string[]]$Directories)
    # adbd secure_mkdirs may attempt ownership changes when creating a missing
    # parent in app external storage. Let the checked shell mkdir create the
    # complete manifest tree first; never change permissions or ownership.
    foreach($relative in (@('')+@($Directories))){
        $destination=$Incoming
        if($relative){$destination+='/'+$relative}
        try { Quest -Arguments @('-s',$Serial,'shell','mkdir','-p',$destination) | Out-Null }
        catch { throw ("Quest staging directory could not be prepared: $destination. No APK installation or import commit was attempted. Keep the headset connected and unlocked, close the game and check free storage, then retry this Setup ZIP. Do not uninstall or clear app data. "+$_.Exception.Message) }
    }
    Write-Host 'Copying your converted game files. Keep the USB cable connected.'
    try { Quest -Arguments @('-s',$Serial,'push',($ImportDirectory.TrimEnd('\','/')+'/.'),$Incoming) | Out-Host }
    catch { throw ('Quest game-file copy failed before APK installation or import commit. Existing imports and saves were not changed. Check the USB connection and free headset storage, then retry this Setup ZIP; retry uses a new staging folder. Do not uninstall or clear app data. '+$_.Exception.Message) }
}
$devices=Quest -Arguments @('devices','-l');$ready=@([regex]::Matches($devices,'(?m)^([^\s]+)\s+device\b') | ForEach-Object {$_.Groups[1].Value} | Where-Object {-not $_.StartsWith('emulator-')})
if(-not $Serial){if($ready.Count -ne 1){throw 'Connect one Quest by USB and allow USB debugging inside the headset. See START-HERE.html.'};$Serial=$ready[0]}
if($ready -notcontains $Serial -or (Quest -Arguments @('-s',$Serial,'shell','getprop','ro.product.model')) -notmatch '(?i)quest'){throw 'The selected Quest is not connected and authorized.'}
$apk=Join-Path $PSScriptRoot 'CastleMinerZVR-Quest2-v0.58.3-PublicUpdate.apk'
if(-not (Test-Path -LiteralPath $apk -PathType Leaf)){throw 'Extract the complete Quest Setup ZIP. Its APK is missing.'}
$apkInfo=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'apk-info.json') -Raw | ConvertFrom-Json
if((Get-Item -LiteralPath $apk).Length -ne $apkInfo.bytes -or (Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash.ToLowerInvariant() -ne $apkInfo.sha256){throw 'The APK failed its integrity check. Re-extract the complete candidate Setup ZIP.'}
if((Quest -Arguments @('-s',$Serial,'shell',('if pidof '+$package+' >/dev/null; then echo running; fi'))).Trim() -eq 'running'){throw 'Close CastleMiner Z VR in the headset, then run setup again. Your game was not interrupted.'}
$remote='/sdcard/Android/data/'+$package+'/files'
$token=[Guid]::NewGuid().ToString('N')
$incoming=$remote+'/game-incoming-'+$token
$backup=$remote+'/game-before-setup-'+$token
Copy-QuestImports -ImportDirectory $ImportDirectory -Incoming $incoming -Serial $Serial -Directories $importDirectories
[IO.Directory]::CreateDirectory($cache) | Out-Null
$hashFile=Join-Path $cache ('checksums-'+$token+'.txt')
$checks=($manifest.assets | ForEach-Object {
    $relative=([string]$_.path).Substring(5)
    # Deterministic files were checked above. The GPU atlas uses its locally
    # validated digest, so USB verification checks the exact generated bytes.
    $hash=[string]$_.sha256
    if($relative -eq 'hud-items.rgba'){$hash=(Get-FileHash -LiteralPath (Join-Path $ImportDirectory $relative) -Algorithm SHA256).Hash.ToLowerInvariant()}
    $hash+'  '+$relative
}) -join "`n"
$receipt=Join-Path $ImportDirectory 'hud-items.sha256'
if(Test-Path -LiteralPath $receipt){$checks+="`n"+(Get-FileHash -LiteralPath $receipt -Algorithm SHA256).Hash.ToLowerInvariant()+'  hud-items.sha256'}
[IO.File]::WriteAllText($hashFile,$checks+"`n",[Text.UTF8Encoding]::new($false))
Quest -Arguments @('-s',$Serial,'push',$hashFile,($incoming+'/setup-checksums.txt')) | Out-Null
Quest -Arguments @('-s',$Serial,'shell',('cd '+$incoming+' && sha256sum -c setup-checksums.txt > setup-verification.txt')) | Out-Null
# Stage and verify before installing. Failure here leaves the current APK and
# active imports alone. -r keeps app data and enforces Android's existing signer.
Write-Host 'Installing the Quest app. Existing saves and settings are retained.'
Quest -Arguments @('-s',$Serial,'install','-r','--no-streaming',$apk) | Out-Host
# All remote paths above are fixed app paths plus generated hexadecimal tokens.
# Commit only after every transferred file verifies. Preserve previous imports.
Quest -Arguments @('-s',$Serial,'shell',('if [ -d '+$remote+'/game ]; then mv '+$remote+'/game '+$backup+' || exit 1; fi; if ! mv '+$incoming+' '+$remote+'/game; then if [ -d '+$backup+' ]; then mv '+$backup+' '+$remote+'/game; fi; exit 1; fi')) | Out-Null
& (Join-Path $PSScriptRoot 'Setup-QuestGameCheck.ps1') -GameDirectory $GameDirectory -Adb $Adb -Serial $Serial -NoLaunch
Write-Host 'Standalone Quest setup complete. Open Library > Unknown Sources > CastleMiner Z VR - Integration.'
Write-Host 'The PC and USB cable are no longer needed to play. Keep your local converted files for future updates.'
Write-Host "Previous headset imports, if any, were kept at $backup. Saves and settings were not removed."
