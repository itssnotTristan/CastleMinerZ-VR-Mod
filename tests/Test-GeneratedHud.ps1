param([Parameter(Mandatory=$true)][string]$Atlas,[Parameter(Mandatory=$true)][string]$Work)
$ErrorActionPreference='Stop'
$runtimePath=Join-Path (Split-Path $PSScriptRoot -Parent) 'QuestSetup/Tools'
function Assert-PlainPath([string]$Path) {
    if((Test-Path -LiteralPath $Path) -and ((Get-Item -LiteralPath $Path).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'Linked fixture'}
}
. (Join-Path $runtimePath 'Import-Validation.ps1')
[IO.Directory]::CreateDirectory($Work) | Out-Null
$file=Join-Path $Work 'hud-items.rgba'
$original=[IO.File]::ReadAllBytes($Atlas)
$checks=0
function Reject-Hud([byte[]]$Bytes,[string]$Case) {
    [IO.File]::WriteAllBytes($file,$Bytes)
    $rejected=$false
    try{Save-CmzGeneratedHudReceipt -Directory $Work}catch{$rejected=$true}
    if(-not $rejected){throw "Accepted malformed HUD: $Case"}
    $script:checks++
}
[IO.File]::WriteAllBytes($file,$original)
Save-CmzGeneratedHudReceipt -Directory $Work
$checks++
$variant=[byte[]]$original.Clone()
for($i=8;$i -lt $variant.Length;$i+=4){if($variant[$i+3] -gt 0 -and $variant[$i] -gt 1){$variant[$i]--;break}}
[IO.File]::WriteAllBytes($file,$variant)
$hash=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
$rejected=$false
try{Test-CmzGeneratedHud -Directory $Work -ExpectedHash $hash}catch{$rejected=$true}
if(-not $rejected){throw 'Changed bytes passed with old receipt'};$checks++
Save-CmzGeneratedHudReceipt -Directory $Work
Test-CmzGeneratedHud -Directory $Work -ExpectedHash $hash
$checks++
$bad=[byte[]]$original.Clone();$bad[1]=0
Reject-Hud $bad 'wrong dimensions'
Reject-Hud ([byte[]]$original[0..100]) 'truncated'
$bad=[byte[]]$original.Clone();[Array]::Clear($bad,8,$bad.Length-8)
Reject-Hud $bad 'blank atlas'
$bad=[byte[]]$original.Clone();for($i=8;$i -lt $bad.Length;$i+=4){$bad[$i]=0;$bad[$i+1]=0;$bad[$i+2]=0}
Reject-Hud $bad 'black icons'
$bad=[byte[]]$original.Clone();for($y=0;$y -lt 64;$y++){[Array]::Clear($bad,8+($y*512+64)*4,64*4)}
Reject-Hud $bad 'missing icon'
$bad=[byte[]]$original.Clone();$bad[8]=1
Reject-Hud $bad 'RGB in empty transparent cell'
Write-Output "GENERATED_HUD_PASS checks=$checks real_atlas=1 synthetic_variant=1 other_gpu=0"
