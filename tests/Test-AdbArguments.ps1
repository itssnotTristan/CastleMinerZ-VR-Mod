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
    # Exercise the caller preference used by both production entry points. On
    # PS7 also opt into native exit-code errors to check local isolation.
    foreach($nativePreference in @($false,$true)) {
        $PSNativeCommandUseErrorActionPreference=$nativePreference
        $env:CMZ_ADB_MODE='stdout-only'
        $result=& $pair[1] -Arguments @('devices','-l')
        if($result -cne 'synthetic stdout success'){throw 'stdout was lost'}
        $checks++
        $env:CMZ_ADB_MODE='success-stderr'
        $result=& $pair[1] -Arguments @('devices','-l')
        if($result -notmatch 'synthetic daemon startup notice' -or $result -notmatch 'synthetic stdout success'){throw 'Successful native stdout/stderr was lost'}
        if($ErrorActionPreference -ne 'Stop' -or $PSNativeCommandUseErrorActionPreference -ne $nativePreference){throw 'Caller preferences changed after success'}
        $checks++
        $env:CMZ_ADB_MODE='stderr';$failure=$null
        try{& $pair[1] -Arguments @('devices','-l') | Out-Null}catch{$failure=$_}
        if(-not $failure -or $failure.Exception.Message -cne 'Quest USB command failed (exit 7): synthetic USB failure'){
            throw "Wrong native failure: $failure"
        }
        if($failure.FullyQualifiedErrorId -match 'NativeCommandError|NativeCommandExitException'){throw 'PowerShell rejected stderr before the explicit exit-code check'}
        if($ErrorActionPreference -ne 'Stop' -or $PSNativeCommandUseErrorActionPreference -ne $nativePreference){throw 'Caller preferences changed after failure'}
        $checks++
    }
    $env:CMZ_ADB_MODE='argv'
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
