Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
& (Join-Path $root 'tests/Stage01.Tests.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Nabigo ang Stage 1 regression suite.' }
& (Join-Path $root 'tests/Stage23.Tests.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Nabigo ang Stage 23 Native PATCH 11 verification.' }
$stageFile = Join-Path $root 'DEVELOPMENT_STAGE.md'
$content = Get-Content -Raw -Encoding UTF8 $stageFile
$lines = @(Get-Content -Encoding UTF8 $stageFile)
$preSeal = ($lines -contains 'LAST_COMPLETED_STAGE=22') -and
           ($lines -contains 'STAGE23_RUNTIME_VERIFICATION=AWAITING')
$postSeal = (($lines -contains 'LAST_COMPLETED_STAGE=23') -or ($lines -contains 'LAST_COMPLETED_STAGE=24') -or ($lines -contains 'LAST_COMPLETED_STAGE=25')) -and
            ($lines -contains 'STAGE23_RUNTIME_VERIFICATION=GREEN_CONFIRMED')
if ($preSeal) {
    $updatedLines = foreach ($line in $lines) {
        if ($line -eq 'LAST_COMPLETED_STAGE=22') {
            'LAST_COMPLETED_STAGE=23'
        }
        elseif ($line -eq 'STAGE23_RUNTIME_VERIFICATION=AWAITING') {
            'STAGE23_RUNTIME_VERIFICATION=GREEN_CONFIRMED'
        }
        else {
            $line
        }
    }
    Set-Content -Path $stageFile -Value $updatedLines -Encoding utf8
    Write-Host 'STAGE23_FINALIZED=YES'
}
elseif ($postSeal) {
    Write-Host 'STAGE23_ALREADY_FINALIZED=YES'
}
else {
    throw 'Mali ang Stage 23 sealing precondition.'
}
