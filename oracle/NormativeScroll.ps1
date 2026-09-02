Set-StrictMode -Version Latest

$base = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $base

. (Join-Path $root 'src/SourceLanguageCatalog.ps1')
. (Join-Path $base 'NormativeCore.ps1')
. (Join-Path $base 'NormativeFamilies.ps1')
. (Join-Path $base 'NormativeCalendar.ps1')
