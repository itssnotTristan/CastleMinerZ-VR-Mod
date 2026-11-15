param([Parameter(Mandatory=$true)][string]$ImportDirectory,[string]$OutputZip)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$ImportDirectory=(Resolve-Path -LiteralPath $ImportDirectory).Path
if(-not $OutputZip){$OutputZip=Join-Path ([Environment]::GetFolderPath('Desktop')) 'CastleMinerZ-PersonalGameData.zip'}
$OutputZip=[IO.Path]::GetFullPath($OutputZip)
if(Test-Path -LiteralPath $OutputZip){throw 'The output ZIP already exists. Choose another name to preserve it.'}
$manifest=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Tools/import-manifest.json') -Raw | ConvertFrom-Json
$files=@()
foreach($entry in $manifest.assets){
    $name=([string]$entry.path).Substring(5)
    if($name -notmatch '^[A-Za-z0-9_./ ;+\-]+$' -or $name.Contains('..')){throw 'Invalid import manifest path.'}
    $path=Join-Path $ImportDirectory $name
    if((Get-Item -LiteralPath $path).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Linked game-data files cannot be exported.'}
    for($part=[IO.DirectoryInfo]::new([IO.Path]::GetDirectoryName($path)); $part -and $part.FullName.StartsWith($ImportDirectory,[StringComparison]::OrdinalIgnoreCase);$part=$part.Parent){if($part.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Linked game-data paths cannot be exported.'}}
    if(-not(Test-Path -LiteralPath $path -PathType Leaf) -or (Get-Item -LiteralPath $path).Length -ne $entry.bytes){throw "Missing or incomplete converted file: $name. Run Setup Quest with -PrepareOnly first."}
    $hash=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    $legacyTerrain=$name -eq 'terrain.bin' -and $entry.sha256 -eq 'c8135587cb4a4fd5decffdff4ce452ec3f68c940cd33859ce8bf94616335966d' -and $hash -eq 'f84ad6092d7be8e63da95955f1e20b532155c0923fdc562bdfcae9416bc96eec'
    if($hash -ne $entry.sha256 -and -not $legacyTerrain){
        if($name -ne 'hud-items.rgba'){throw "Converted file failed verification: $name"}
        if(-not('CmzGeneratedHud' -as [type])){Add-Type -Path (Join-Path $PSScriptRoot 'Tools/GeneratedHud.cs')}
        [CmzGeneratedHud]::Validate($path)
        $receipt=Join-Path $ImportDirectory 'hud-items.sha256'
        if(-not(Test-Path -LiteralPath $receipt) -or [IO.File]::ReadAllText($receipt) -cne ($hash+"`n")){throw 'The generated HUD checksum receipt is missing or incorrect.'}
    }
    $files+=@{path=$path;name='game/'+$name}
}
$receipt=Join-Path $ImportDirectory 'hud-items.sha256'
if(Test-Path -LiteralPath $receipt){$files+=@{path=$receipt;name='game/hud-items.sha256'}}
$pending=$OutputZip+'.pending'
if(Test-Path -LiteralPath $pending){throw 'A pending export already exists. Choose another output name.'}
$stream=[IO.File]::Open($pending,[IO.FileMode]::CreateNew)
try{
    $zip=[IO.Compression.ZipArchive]::new($stream,[IO.Compression.ZipArchiveMode]::Create,$true)
    try{foreach($file in $files){[IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$file.path,$file.name,[IO.Compression.CompressionLevel]::Optimal) | Out-Null}}finally{$zip.Dispose()}
}finally{$stream.Dispose()}
Move-Item -LiteralPath $pending -Destination $OutputZip
Write-Host "Personal game-data ZIP created: $OutputZip"
Write-Host 'Copy it to your own headset Downloads folder, then choose Import game-data ZIP in the setup panel. This contains your converted original game files; keep it private.'
