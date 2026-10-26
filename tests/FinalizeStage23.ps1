Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
& (Join-Path $root 'tests/Stage01.Tests.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Nabigo ang Stage 1 regression suite.' }
& (Join-Path $root 'tests/Stage23.Tests.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Nabigo ang Stage 23 Native PATCH 11 verification.' }
$stageFile = Join-Path $root 'DEVELOPMENT_STAGE.md'
$content = Get-Content -Raw -Encoding UTF8 $stageFile
$preSeal = ($content -match '(?m)^LAST_COMPLETED_STAGE=22\s*) -and
           ($content -match '(?m)^STAGE23_RUNTIME_VERIFICATION=AWAITING\s*)
$postSeal = ($content -match '(?m)^LAST_COMPLETED_STAGE=23\s*) -and
            ($content -match '(?m)^STAGE23_RUNTIME_VERIFICATION=GREEN_CONFIRMED\s*)
if ($preSeal) {
    $content = $content -replace '(?m)^LAST_COMPLETED_STAGE=22\s*, 'LAST_COMPLETED_STAGE=23'
    $content = $content -replace '(?m)^STAGE23_RUNTIME_VERIFICATION=AWAITING\s*, 'STAGE23_RUNTIME_VERIFICATION=GREEN_CONFIRMED'
    Set-Content -Path $stageFile -Value $content -Encoding utf8
    Write-Host 'STAGE23_FINALIZED=YES'
}
elseif ($postSeal) {
    Write-Host 'STAGE23_ALREADY_FINALIZED=YES'
}
else {
    throw 'Mali ang Stage 23 sealing precondition.'
}
