Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')
$meta=Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')
Assert-StageTrue -Condition ($meta -match '(?m)^CURRENT_STAGE=26\s*$') -Name 'Stage26 current'
Assert-StageTrue -Condition ($meta -match '(?m)^LAST_COMPLETED_STAGE=25\s*$') -Name 'Stage25 sealed'
Assert-StageTrue -Condition ($meta -match '(?m)^STAGE26_RUNTIME_VERIFICATION=AWAITING\s*$') -Name 'Stage26 has no premature Native seal'
Assert-StageTrue -Condition ($meta -match '(?m)^STAGE25_RUNTIME_VERIFICATION=GREEN_CONFIRMED\s*$') -Name 'Stage25 Native seal retained'
$m=Get-NormM
$red=0
foreach($n0 in @(3,10,97,720)){
    $n=[System.Numerics.BigInteger]$n0
    $limit=($m / $n) * $n
    $first=$limit+1
    $old=oldFirstAnswerModuloRank -First $first -N $n
    $oracle=Get-NormChooseRankShort -Stream ([pscustomobject]@{First=$first;Step=-1}) -N $n
    Assert-StageEqual -Expected 1 -Actual $old -Name "Legacy first-answer for n=$n0"
    Assert-StageEqual -Expected $n -Actual $oracle -Name "Independent rejection result for n=$n0"
    if($old -ne $oracle){$red++}
    Assert-StageEqual -Expected $n -Actual (oldFirstAnswerModuloRank -First $limit -N $n) -Name "Acceptable control for n=$n0"
}
Assert-StageEqual -Expected 4 -Actual $red -Name 'Four intentional historic EXPECTED_RED witnesses'
# Bounded direct comparison on accepted values and both stream directions.
$controls=0
foreach($n0 in @(1,2,3,10,97,720)){
    $n=[System.Numerics.BigInteger]$n0
    $limit=($m/$n)*$n
    foreach($step in @(-1,1)){
        foreach($first in @([System.Numerics.BigInteger]1, [System.Numerics.BigInteger]$limit)){
            $old=oldFirstAnswerModuloRank -First $first -N $n
            $oracle=Get-NormChooseRankShort -Stream ([pscustomobject]@{First=$first;Step=$step}) -N $n
            if($old -eq $oracle){$controls++}
        }
    }
}
Assert-StageEqual -Expected 24 -Actual $controls -Name 'Accepted direct controls 6x2x2'
# Real Stage25 predecessor: compare independent answer-stream formulas, not a mock input.
$f=Get-NormFoundationDay
$live=0
foreach($delta in @(0,3,11)){
    $target=$f+[System.Numerics.BigInteger]$delta
    $actual=Invoke-Discovery13HistoricalRank -CalculationDay $f -TargetDay $target -N ([System.Numerics.BigInteger]720) -Seal 1
    $oracleSauce=Invoke-NormSauce -CalculationDay $f -TargetDay $target
    $oracleStream=Get-NormAnswerStream -SauceResult $oracleSauce -QueriedBowlId 1 -Seal 1
    Assert-StageEqual -Expected $oracleStream.First -Actual $actual.Stream.First -Name "Real stream first delta=$delta"
    Assert-StageEqual -Expected $oracleStream.Step -Actual $actual.Stream.Step -Name "Real stream step delta=$delta"
    Assert-StageEqual -Expected 58 -Actual $actual.Context.legacyOrderMemoryWriteCount -Name "Real predecessor 58 writes delta=$delta"
    Assert-StageEqual -Expected 1 -Actual $actual.Context.patch12InvocationCount -Name "Patch12 invoked once delta=$delta"
    Assert-StageEqual -Expected (oldFirstAnswerModuloRank -First $oracleStream.First -N ([System.Numerics.BigInteger]720)) -Actual $actual.LegacyRank -Name "Historical rank uses real first delta=$delta"
    Assert-StageEqual -Expected 'HISTORICAL_NO_REJECTION_EXPECTED_RED' -Actual $actual.Status -Name "Historical scar status delta=$delta"
    $live++
}
Assert-StageEqual -Expected 3 -Actual $live -Name 'Three real precursor histories'
$invalid=0
foreach($case in @(
    @([System.Numerics.BigInteger]0,[System.Numerics.BigInteger]3),
    @($m+1,[System.Numerics.BigInteger]3),
    @([System.Numerics.BigInteger]1,[System.Numerics.BigInteger]0),
    @([System.Numerics.BigInteger]1,$m+1)
)){
    try{[void](oldFirstAnswerModuloRank -First $case[0] -N $case[1])}catch{$invalid++}
}
Assert-StageEqual -Expected 4 -Actual $invalid -Name 'Four invalid domain inputs rejected'
$source=Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Discovery13.ps1')
Assert-StageTrue -Condition ($source -match 'Invoke-CalendarDateSpaghetti' -and $source -match 'patch12ProductionResult' -and $source -match 'oldFirstAnswerModuloRank') -Name 'Real corrected precursor then historic modulo'
Assert-StageTrue -Condition ($source -notmatch 'Get-Norm|NormativeScroll|Get-NormChooseRank|RejectionSamplingPatch13') -Name 'No test oracle or Patch13 in production'
Write-Host "STAGE26_INTENTIONAL_EXPECTED_RED=$red"
Write-Host "STAGE26_ACCEPTED_CONTROLS=$controls"
Write-Host "STAGE26_REAL_PRECURSOR_HISTORIES=$live"
$ok=Complete-StageTestRun
if(-not $ok){exit 1}
Write-Host 'STAGE26_RESULT=EXPECTED_RED_CONFIRMED'
exit 0
