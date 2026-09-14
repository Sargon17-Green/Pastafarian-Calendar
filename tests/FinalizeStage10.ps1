Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

& (Join-Path $root 'tests/Stage01.Tests.ps1')
if ($LASTEXITCODE -ne 0) {
    throw 'Nabigo ang Stage 1 regression suite; hindi maaaring i-finalize ang Stage 10.'
}

& (Join-Path $root 'tests/Stage10.Tests.ps1')
if ($LASTEXITCODE -ne 0) {
    throw 'Nabigo ang Stage 10 Discovery 05 verification; hindi babaguhin ang DEVELOPMENT_STAGE.md.'
}

$stageFile = Join-Path $root 'DEVELOPMENT_STAGE.md'
$text = Get-Content -Raw -Encoding UTF8 $stageFile

if ($text -notmatch '(?m)^LAST_COMPLETED_STAGE=9\s*$') {
    throw 'Hindi wasto ang precondition: kailangang LAST_COMPLETED_STAGE=9 bago i-finalize ang Stage 10.'
}
if ($text -notmatch '(?m)^STAGE10_RUNTIME_VERIFICATION=AWAITING\s*$') {
    throw 'Hindi wasto ang precondition: kailangang naghihintay pa ng Stage 10 runtime verification.'
}

$text = $text -replace '(?m)^LAST_COMPLETED_STAGE=9\s*$', 'LAST_COMPLETED_STAGE=10'
$text = $text -replace '(?m)^STAGE10_RUNTIME_VERIFICATION=AWAITING\s*$', 'STAGE10_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED'
$text = $text -replace '(?ms)\r?\nPaalala:.*$', ''

Set-Content -Path $stageFile -Value $text -Encoding utf8
Write-Host 'STAGE10_FINALIZED=YES'
