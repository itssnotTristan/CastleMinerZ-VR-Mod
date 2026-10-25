param([Parameter(Mandatory=$true)][string]$Work)
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$runtimePath=Join-Path $Work 'Tools'
$game=Join-Path $Work 'Synthetic Game'
[IO.Directory]::CreateDirectory($runtimePath) | Out-Null
[IO.Directory]::CreateDirectory((Join-Path $game 'Content')) | Out-Null
Copy-Item -LiteralPath (Join-Path $repo 'QuestSetup/Tools/GeneratedHud.cs') -Destination (Join-Path $runtimePath 'GeneratedHud.cs')
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'QuestSetup/Tools/Setup-CastleMinerZVR.ps1'),[ref]$tokens,[ref]$errors)
$function=$ast.Find({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Assert-PlainPath'},$true)
Invoke-Expression $function.Extent.Text
. (Join-Path $repo 'QuestSetup/Tools/Import-Validation.ps1')
$file=Join-Path $game 'Content/Texture.xnb'
[IO.File]::WriteAllText($file,'synthetic-input')
$entry=@{path='Content/Texture.xnb';bytes=(Get-Item $file).Length;sha256=(Get-FileHash $file -Algorithm SHA256).Hash.ToLowerInvariant()}
function Write-Manifest { [IO.File]::WriteAllText((Join-Path $runtimePath 'source-inputs.json'),(@{files=@($entry)}|ConvertTo-Json -Depth 4)) }
function Reject-Source([string]$Case){$rejected=$false;try{Assert-CmzSourceInputs -GameDirectory $game}catch{$rejected=$true};if(-not $rejected){throw "Accepted invalid source: $Case"}}
Write-Manifest
Assert-CmzSourceInputs -GameDirectory $game
[IO.File]::WriteAllText($file,'synthetic-inpuu')
Reject-Source 'same-size corruption'
$entry.sha256='a'*64;Write-Manifest
Reject-Source 'stale source manifest'
$entry.path='../Texture.xnb';Write-Manifest
Reject-Source 'traversal'
Write-Output "SOURCE_INPUTS_PASS checks=4 original_game_bytes=0"
