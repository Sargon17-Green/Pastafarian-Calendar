Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

& (Join-Path $root 'tests/Stage01.Tests.ps1')
if ($LASTEXITCODE -ne 0) {
    throw 'Nabigo ang Stage 1 regression suite; hindi maaaring i-finalize ang Stage 21.'
}

& (Join-Path $root 'tests/Stage21.Tests.ps1')
if ($LASTEXITCODE -ne 0) {
    throw 'Nabigo ang Stage 21 Patch 10 verification; hindi babaguhin ang DEVELOPMENT_STAGE.md.'
}

$stageFile = Join-Path $root 'DEVELOPMENT_STAGE.md'
$text = Get-Content -Raw -Encoding UTF8 $stageFile

if ($text -notmatch '(?m)^LAST_COMPLETED_STAGE=20\s*$') {
    throw 'Hindi wasto ang precondition: kailangang LAST_COMPLETED_STAGE=20 bago i-finalize ang Stage 21.'
}
if ($text -notmatch '(?m)^STAGE21_RUNTIME_VERIFICATION=AWAITING\s*$') {
    throw 'Hindi wasto ang precondition: kailangang naghihintay pa ng Stage 21 runtime verification.'
}

$text = $text -replace '(?m)^LAST_COMPLETED_STAGE=20\s*$', 'LAST_COMPLETED_STAGE=21'
$text = $text -replace '(?m)^STAGE21_RUNTIME_VERIFICATION=AWAITING\s*$', 'STAGE21_RUNTIME_VERIFICATION=GREEN_CONFIRMED'
$text = $text -replace '(?ms)\r?\nPaalala:.*$', ''

Set-Content -Path $stageFile -Value $text -Encoding utf8
Write-Host 'STAGE21_FINALIZED=YES'
