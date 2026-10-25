param(
    [string]$GameDirectory = (Split-Path $PSScriptRoot -Parent),
    [string]$Decoder,
    [switch]$PrepareOnly,
    [string]$PrivateOutput,
    [switch]$VerifyOnly,
    [string]$ImportDirectory
)
$ErrorActionPreference = 'Stop'
$GameDirectory = (Resolve-Path -LiteralPath $GameDirectory).Path
$runtimePath = $PSScriptRoot
$manifest = Get-Content -LiteralPath (Join-Path $runtimePath 'import-manifest.json') -Raw | ConvertFrom-Json
. (Join-Path $runtimePath 'Import-Validation.ps1')
$originals = @(
    @{Name='CastleMinerZ.exe';Bytes=846848;Hash='45d951391f204a20803c5e249d7f43fec0acbf320f5cf6c3e42ccccfe778cea3'},
    @{Name='DNA.Common.dll';Bytes=634368;Hash='7e95dd85315ebf21b9256e58e26cb623a81a5cb5a4f4554a9574870ee6f708e8'},
    @{Name='DNA.Steam.dll';Bytes=115712;Hash='c58b940b4ec956e0c3249284397294aa7f64bc889a7a36a82fbbb6ea48c68be6'}
)
function Assert-PlainPath([string]$Path) {
    $current = [IO.Path]::GetFullPath($Path)
    while($current) {
        if(Test-Path -LiteralPath $current) {
            if((Get-Item -LiteralPath $current -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Setup folders cannot be links: $current" }
        }
        $parent = Split-Path $current -Parent
        if($parent -eq $current) { break }
        $current = $parent
    }
}
function Test-Imports([string]$Directory) {
    $problems = [Collections.Generic.List[string]]::new()
    foreach($asset in $manifest.assets) {
        $relative = [string]$asset.path
        if($relative -notmatch '^game/(audio/)?[A-Za-z0-9_. ;\-]+$' -or $relative.Contains('..')) { throw 'Invalid import manifest path.' }
        $path = Join-Path $Directory $relative.Substring(5)
        Assert-PlainPath $path
        if(-not (Test-Path -LiteralPath $path -PathType Leaf)) { $problems.Add("Missing: $relative"); continue }
        $actualHash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
        if((Get-Item -LiteralPath $path).Length -ne $asset.bytes) { $problems.Add("Wrong size: $relative"); continue }
        if($actualHash -ne $asset.sha256) {
            if($relative -eq 'game/hud-items.rgba' -and $asset.bytes -eq 2621448 -and
               $asset.sha256 -eq '08f7e76b44c428b01ddac6a2db5c8977a5e4f5799b9dbd14042fc070cbe5219c') {
                try { Test-CmzGeneratedHud -Directory $Directory -ExpectedHash $actualHash }
                catch { $problems.Add("Invalid generated HUD: $($_.Exception.Message)") }
            } else { $problems.Add("Different: $relative (expected $($asset.sha256), actual $actualHash)") }
        }
    }
    return $problems.ToArray()
}
Assert-PlainPath $GameDirectory
Assert-PlainPath $runtimePath
foreach($file in $originals) {
    $path = Join-Path $GameDirectory $file.Name
    if(-not (Test-Path -LiteralPath $path -PathType Leaf) -or (Get-Item -LiteralPath $path).Length -ne $file.Bytes -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $file.Hash) {
        throw "Missing or unsupported original $($file.Name). Install CastleMiner Z through Steam, verify its files, and extract this mod beside CastleMinerZ.exe. Supported game version: 1.9.9.8."
    }
}
Assert-CmzSourceInputs -GameDirectory $GameDirectory
if($VerifyOnly) {
    $checkPath = if($PrivateOutput) { [IO.Path]::GetFullPath($PrivateOutput) } else { Join-Path $runtimePath 'game' }
    $problems = @(Test-Imports $checkPath)
    if($problems.Count) { throw ($problems -join "`n") }
    Write-Output "Verified $($manifest.assets.Count) imported files and the original Steam installation."
    return
}
$running = @(Get-Process -Name CastleMinerZVR -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path -eq (Join-Path $runtimePath 'CastleMinerZVR.exe') })
if($running.Count){throw 'Close this CastleMiner Z VR installation before running setup. Your game was not interrupted.'}
$setupRoot = Join-Path $env:LOCALAPPDATA 'CastleMinerZ-PCVR-Setup'
Assert-PlainPath $setupRoot
[IO.Directory]::CreateDirectory($setupRoot) | Out-Null
$session = Join-Path $setupRoot ([Guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($session) | Out-Null
$output = if($ImportDirectory) { (Resolve-Path -LiteralPath $ImportDirectory).Path } elseif($PrivateOutput) { [IO.Path]::GetFullPath($PrivateOutput) } else { Join-Path $session 'converted' }
Assert-PlainPath $output
foreach($protected in @($GameDirectory,(Join-Path $runtimePath 'importer'))) {
    $protected = [IO.Path]::GetFullPath($protected).TrimEnd('\')
    if($output.Equals($protected,[StringComparison]::OrdinalIgnoreCase) -or $output.StartsWith($protected+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Conversion staging must stay outside the game and importer folders.' }
}
if(-not $ImportDirectory -and (Test-Path -LiteralPath $output)) { throw 'Choose an empty conversion destination. Existing files are preserved.' }
$log = Join-Path $session 'setup.log'
Start-Transcript -LiteralPath $log | Out-Null
try {
    Write-Host 'Preparing CastleMiner Z VR from your Steam installation. Keep this window open.'
    Write-Host "Setup log: $log"
    if(-not $ImportDirectory) {
    $xna = Join-Path $env:WINDIR 'Microsoft.NET/assembly/GAC_32/Microsoft.Xna.Framework'
    if(-not (Test-Path -LiteralPath $xna)) { throw 'XNA 4 is missing. Run the original Steam game once to install its prerequisites, then run setup again.' }
    if(-not $Decoder) {
        Write-Host 'Downloading the pinned vgmstream audio converter from its official GitHub release.'
        $archive = Join-Path $session 'vgmstream-win64.zip'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/vgmstream/vgmstream/releases/download/r2117/vgmstream-win64.zip' -OutFile $archive
        if((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne '6c4a8a3813864fefed081bbd337dbc0ad93bf88e0b92f5db98d7ab258b22dc6c') { throw 'Audio converter download failed its integrity check.' }
        $decoderFolder = Join-Path $session 'decoder'
        Expand-Archive -LiteralPath $archive -DestinationPath $decoderFolder
        $Decoder = Join-Path $decoderFolder 'vgmstream-cli.exe'
    }
    $Decoder = (Resolve-Path -LiteralPath $Decoder).Path
    $importerRoot = Join-Path $runtimePath 'importer'
    & (Join-Path $importerRoot 'Import.ps1') -Game $GameDirectory -PrivateOutput $output -Mode base
    if($LASTEXITCODE -ne 0) { throw 'Base game conversion failed.' }
    $converter = Join-Path (Split-Path $output -Parent) 'import-tools/ImportGame.exe'
    foreach($mode in @('catalog','presentation','generator','dragons','dragon-effects','effects','avatar','barrels','reloads','crosshair','selector','weapon-effects','scopes','storage-ui','feedback')) {
        Write-Host "Importing $mode..."
        & $converter $GameDirectory $output $mode
        if($LASTEXITCODE -ne 0) { throw "Game conversion failed: $mode" }
    }
    & (Join-Path $importerRoot 'ImportAudio.ps1') -Game $GameDirectory -PrivateOutput $output -Decoder $Decoder
    if($LASTEXITCODE -ne 0) { throw 'Audio conversion failed.' }
    Save-CmzGeneratedHudReceipt -Directory $output
    }
    $problems = @(Test-Imports $output)
    [IO.File]::WriteAllText((Join-Path $session 'import-verification.json'),(@{version=$manifest.version;checked=$manifest.assets.Count;problems=$problems;passed=($problems.Count -eq 0)} | ConvertTo-Json -Depth 5))
    if($problems.Count) { throw ("Imported files did not match the supported conversion:`n"+($problems -join "`n")) }
    if($PrepareOnly) { Write-Host "Verified import ready at $output"; return }
    $incoming = Join-Path $runtimePath ('game-import-'+[Guid]::NewGuid().ToString('N'))
    Assert-PlainPath $incoming
    [IO.Directory]::CreateDirectory($incoming) | Out-Null
    foreach($asset in $manifest.assets) {
        $relative = ([string]$asset.path).Substring(5)
        $target = Join-Path $incoming $relative
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null
        Copy-Item -LiteralPath (Join-Path $output $relative) -Destination $target
    }
    $receipt = Join-Path $output 'hud-items.sha256'
    if(Test-Path -LiteralPath $receipt){Copy-Item -LiteralPath $receipt -Destination (Join-Path $incoming 'hud-items.sha256')}
    $problems = @(Test-Imports $incoming)
    if($problems.Count) { throw 'Copied imports did not verify. The previous installation remains in place.' }
    $gamePath = Join-Path $runtimePath 'game'
    Assert-PlainPath $gamePath
    $backup = $null
    if(Test-Path -LiteralPath $gamePath) {
        $backup = Join-Path $runtimePath ('game-before-setup-'+[Guid]::NewGuid().ToString('N'))
        Move-Item -LiteralPath $gamePath -Destination $backup
    }
    try { Move-Item -LiteralPath $incoming -Destination $gamePath }
    catch { if($backup) { Move-Item -LiteralPath $backup -Destination $gamePath }; throw }
    Write-Host 'Setup complete. Enter Quest Link or Air Link, then run Play CastleMiner Z VR.cmd.'
    if($backup) { Write-Host "Previous imports are preserved at $backup" }
} finally { Stop-Transcript | Out-Null }
