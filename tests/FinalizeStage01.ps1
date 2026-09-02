Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
& (Join-Path $root 'tests/Stage01.Tests.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Nabigo ang Stage 1 tests; hindi babaguhin ang DEVELOPMENT_STAGE.md.' }

$stageFile = Join-Path $root 'DEVELOPMENT_STAGE.md'
$text = Get-Content -Raw $stageFile
$text = $text -replace 'LAST_COMPLETED_STAGE=0', 'LAST_COMPLETED_STAGE=1'
$text = $text -replace '(?ms)\r?\nPaalala:.*$', ''
Set-Content -Path $stageFile -Value $text -Encoding utf8
Write-Host 'STAGE01_FINALIZED=YES'
