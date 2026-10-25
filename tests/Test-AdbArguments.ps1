param([Parameter(Mandatory=$true)][string]$Stub,[Parameter(Mandatory=$true)][string]$Log)
$ErrorActionPreference='Stop'
if((& $Stub --cmz-test-double-identity) -cne 'CMZ_ADB_TEST_DOUBLE_V1'){throw 'Use the inert AdbStub.exe, never real adb.exe.'}
$env:CMZ_ADB_LOG=$Log
$env:CMZ_ADB_MODE='argv'
$Adb=$Stub
$checks=0
foreach($pair in @(
    @('QuestSetup/Setup-QuestStandalone.ps1','Quest'),
    @('QuestSetup/Setup-QuestGameCheck.ps1','Invoke-QuestAdb')
)) {
    $path=Join-Path (Split-Path $PSScriptRoot -Parent) $pair[0]
    $tokens=$null;$errors=$null
    $ast=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$errors)
    if($errors.Count){throw ($errors|Out-String)}
    $function=$ast.Find({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $pair[1]},$true)
    Invoke-Expression $function.Extent.Text
    $vectors=[Collections.Generic.List[string[]]]::new()
    $vectors.Add(@('devices','-l'))
    $vectors.Add(@('-s','QUEST-STUB','push','C:\path with spaces\Audio; cue.wav','/remote path'))
    $vectors.Add(@('-s','QUEST-STUB','shell','cd /fixed/path && sha256sum -c setup-checksums.txt > setup-verification.txt'))
    $vectors.Add(@('-s','QUEST-STUB','install','-r','--no-streaming','C:\full path\Candidate.apk'))
    foreach($expected in $vectors) {
        & $pair[1] -Arguments $expected | Out-Null
        $actual=ConvertFrom-Json -InputObject (Get-Content -LiteralPath $Log -Tail 1)
        if($actual.Count -ne $expected.Count){throw "argv count mismatch in $($pair[1])"}
        for($i=0;$i -lt $expected.Count;$i++){if($actual[$i] -cne $expected[$i]){throw "argv value mismatch in $($pair[1])"}}
        $checks++
    }
    $env:CMZ_ADB_MODE='stderr';$rejected=$false
    try{& $pair[1] -Arguments @('devices','-l') | Out-Null}catch{$rejected=$true}
    if(-not $rejected){throw 'Native failure was swallowed'}
    $checks++;$env:CMZ_ADB_MODE='argv'
}
# Demonstrate the original regression with the same native stub.
function Legacy {param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Arguments) & $Adb @Arguments | Out-Null}
Legacy @('devices','-l')
$legacy=ConvertFrom-Json -InputObject (Get-Content -LiteralPath $Log -Tail 1)
if($PSVersionTable.PSVersion.Major -le 5){
    if($legacy.Count -ne 1 -or $legacy[0] -ne 'devices -l'){throw 'Legacy regression did not reproduce'}
} elseif($legacy.Count -ne 2){throw 'Unexpected legacy behavior in newer PowerShell'}
$checks++
Write-Output "ADB_ARGUMENTS_PASS checks=$checks PowerShell=$($PSVersionTable.PSVersion) physical_device=0"
