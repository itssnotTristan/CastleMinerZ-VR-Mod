param([string]$Script=(Join-Path $PSScriptRoot '../QuestSetup/Setup-QuestStandalone.ps1'))
$ErrorActionPreference='Stop'
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($Script,[ref]$tokens,[ref]$errors)
if($errors.Count){throw ($errors|Out-String)}
$fn=$ast.Find({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Get-QuestImportDirectories'},$true)
Invoke-Expression $fn.Extent.Text
$checks=0
$manifest=Get-Content -LiteralPath (Join-Path (Split-Path $Script -Parent) 'Tools/import-manifest.json') -Raw | ConvertFrom-Json
$dirs=@(Get-QuestImportDirectories -Assets @($manifest.assets))
if($manifest.assets.Count -ne 416 -or $dirs.Count -ne 1 -or $dirs[0] -cne 'audio'){throw 'Unexpected supported import tree'}
$checks++
$dirs=@(Get-QuestImportDirectories -Assets @(@{path='game/audio/sfx-0024-LaserGun1; GunShot1.wav'}))
if($dirs.Count -ne 1 -or $dirs[0] -cne 'audio'){throw 'Supported original audio leaf name was rejected'};$checks++
$dirs=@(Get-QuestImportDirectories -Assets @(@{path='game/root.bin'},@{path='game/audio/cues.bin'},@{path='game/audio/deep/tone.bin'},@{path='game/other/a.bin'}))
if(($dirs -join ',') -cne 'audio,other,audio/deep'){throw "Wrong manifest parent order: $dirs"};$checks++
$dirs=@(Get-QuestImportDirectories -Assets @(@{path='game/root.bin'}))
if($dirs.Count){throw 'Root-only manifest invented directories'};$checks++
foreach($path in @('audio/cues.bin','game/../escape','game/audio/../../escape','game//audio/cues.bin','game/./audio/cues.bin','game/audio\cues.bin','/game/audio/cues.bin','game/audio;id/cues.bin','game/audio folder/cues.bin','game/audio/','game/-audio/cues.bin',"game/audio/line`nbreak")){
    $failure=$null;try{Get-QuestImportDirectories -Assets @(@{path=$path}) | Out-Null}catch{$failure=$_}
    if(-not $failure -or $failure.Exception.Message -notmatch 'Invalid or duplicate Quest import manifest path'){throw "Path was accepted: $path"};$checks++
}
foreach($paths in @(@('game/audio/cues.bin','game/audio/cues.bin'),@('game/audio/cues.bin','game/Audio/cues.bin'),@('game/audio','game/audio/cues.bin'))){
    $assets=@($paths | ForEach-Object {@{path=$_}})
    $failure=$null;try{Get-QuestImportDirectories -Assets $assets | Out-Null}catch{$failure=$_}
    if(-not $failure){throw "Conflicting paths accepted: $paths"};$checks++
}
Write-Host "QUEST_TRANSFER_PATHS_PASS checks=$checks"
