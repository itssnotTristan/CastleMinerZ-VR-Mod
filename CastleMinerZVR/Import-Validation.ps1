# Shared PC/Quest input and generated-output validation. Dot-source after runtimePath.
if(-not ('CmzGeneratedHud' -as [type])) { Add-Type -Path (Join-Path $runtimePath 'GeneratedHud.cs') }
function Assert-CmzSourceInputs([string]$GameDirectory) {
    $inputs = Get-Content -LiteralPath (Join-Path $runtimePath 'source-inputs.json') -Raw | ConvertFrom-Json
    foreach($entry in $inputs.files) {
        $relative=[string]$entry.path
        if($relative -notmatch '^[A-Za-z0-9_./ ;()\-]+$' -or $relative.Contains('..') -or $relative.StartsWith('/')) { throw 'Invalid source input path.' }
        $path=Join-Path $GameDirectory $relative
        Assert-PlainPath $path
        if(-not (Test-Path -LiteralPath $path -PathType Leaf) -or
           (Get-Item -LiteralPath $path).Length -ne $entry.bytes -or
           (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $entry.sha256) {
            throw "Unsupported or damaged original input: $relative. Verify CastleMiner Z 1.9.9.8 in Steam. Existing imports are preserved."
        }
    }
}
function Test-CmzGeneratedHud([string]$Directory,[string]$ExpectedHash) {
    [CmzGeneratedHud]::Validate((Join-Path $Directory 'hud-items.rgba'))
    $receipt=Join-Path $Directory 'hud-items.sha256'
    Assert-PlainPath $receipt
    if(-not (Test-Path -LiteralPath $receipt -PathType Leaf) -or (Get-Item -LiteralPath $receipt).Length -ne 65 -or
       [IO.File]::ReadAllText($receipt) -cne ($ExpectedHash+"`n")) {
        throw 'Generated HUD checksum receipt is missing or mismatched. Re-run conversion into a fresh folder.'
    }
}
function Save-CmzGeneratedHudReceipt([string]$Directory) {
    $path=Join-Path $Directory 'hud-items.rgba'
    Assert-PlainPath $path
    [CmzGeneratedHud]::Validate($path)
    $hash=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    [IO.File]::WriteAllText((Join-Path $Directory 'hud-items.sha256'),$hash+"`n",[Text.UTF8Encoding]::new($false))
    Write-Host "Generated HUD validated; local SHA256: $hash"
}
