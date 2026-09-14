Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

& (Join-Path $root 'tests/Stage01.Tests.ps1')
if ($LASTEXITCODE -ne 0) {
    throw 'Nabigo ang Stage 1 regression suite; hindi maaaring i-finalize ang Stage 4.'
}

& (Join-Path $root 'tests/Stage04.Tests.ps1')
if ($LASTEXITCODE -ne 0) {
    throw 'Nabigo ang Stage 4 Discovery 02 verification; hindi babaguhin ang DEVELOPMENT_STAGE.md.'
}

$stageFile = Join-Path $root 'DEVELOPMENT_STAGE.md'
$text = Get-Content -Raw -Encoding UTF8 $stageFile

if ($text -notmatch '(?m)^LAST_COMPLETED_STAGE=3\s*$') {
    throw 'Hindi wasto ang precondition: kailangang LAST_COMPLETED_STAGE=3 bago i-finalize ang Stage 4.'
}
if ($text -notmatch '(?m)^STAGE04_RUNTIME_VERIFICATION=AWAITING\s*$') {
    throw 'Hindi wasto ang precondition: kailangang naghihintay pa ng Stage 4 runtime verification.'
}

$text = $text -replace '(?m)^LAST_COMPLETED_STAGE=3\s*$', 'LAST_COMPLETED_STAGE=4'
$text = $text -replace '(?m)^STAGE04_RUNTIME_VERIFICATION=AWAITING\s*$', 'STAGE04_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED'
$text = $text -replace '(?ms)\r?\nPaalala:.*$', ''

Set-Content -Path $stageFile -Value $text -Encoding utf8
Write-Host 'STAGE04_FINALIZED=YES'
