Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')
$meta = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')
Assert-StageTrue -Condition ($meta -match '(?m)^CURRENT_STAGE=27\s*$') -Name 'Stage27 opened'
Assert-StageTrue -Condition ($meta -match '(?m)^LAST_COMPLETED_STAGE=(26|27|28)\s*$') -Name 'Stage26 sealed, Stage27 awaiting or sealed'
Assert-StageTrue -Condition ($meta -match '(?m)^STAGE26_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED\s*$') -Name 'Stage26 historical RED retained'
$stage27Awaiting = ($meta -match '(?m)^LAST_COMPLETED_STAGE=26\s*$') -and ($meta -match '(?m)^STAGE27_RUNTIME_VERIFICATION=AWAITING\s*$')
$stage27Sealed = ($meta -match '(?m)^LAST_COMPLETED_STAGE=27\s*$') -and ($meta -match '(?m)^STAGE27_RUNTIME_VERIFICATION=GREEN_CONFIRMED\s*$')
Assert-StageTrue -Condition ($stage27Awaiting -or $stage27Sealed) -Name 'Stage27 awaiting or Native-sealed metadata pair'
$m = Get-NormM
$cases = 0; $matching = 0; $rejecting = 0
foreach ($n in @([System.Numerics.BigInteger]1,[System.Numerics.BigInteger]2,[System.Numerics.BigInteger]3,
                  [System.Numerics.BigInteger]7,[System.Numerics.BigInteger]10,[System.Numerics.BigInteger]97,
                  [System.Numerics.BigInteger]720,($m - 1),$m)) {
    $limit = [System.Numerics.BigInteger](($m / $n) * $n)
    $firsts = @([System.Numerics.BigInteger]1,$limit,$m)
    if ($limit -lt $m) { $firsts += ($limit+1) }
    foreach ($first in ($firsts | Select-Object -Unique)) {
        foreach ($step in @(-1,1)) {
            $fixed = Get-Patch13AcceptedRank -First $first -Step $step -N $n
            $oracle = Get-NormChooseRankShort -Stream ([pscustomobject]@{First=$first;Step=$step}) -N $n
            Assert-StageEqual -Expected $oracle -Actual $fixed.Rank -Name "Oracle n=$n first=$first step=$step"
            Assert-StageTrue -Condition ($fixed.Accepted -ge 1 -and $fixed.Accepted -le $limit) -Name 'Accepted within threshold'
            if ($fixed.Rank -eq $oracle) {$matching++}
            if ($fixed.RejectedAnswers -gt 0) {$rejecting++}
            $cases++
        }
    }
}
Assert-StageEqual -Expected $cases -Actual $matching -Name 'All short oracle cases match'
Assert-StageTrue -Condition ($rejecting -gt 0) -Name 'Rejection paths exercised'
$red = 0
foreach ($n0 in @(3,10,97,720)) {
    $n = [System.Numerics.BigInteger]$n0
    $first = (($m / $n) * $n) + 1
    $oldRank = oldFirstAnswerModuloRank -First $first -N $n
    $fixed = Get-Patch13AcceptedRank -First $first -Step -1 -N $n
    Assert-StageEqual -Expected 1 -Actual $oldRank -Name "Stage26 modulo scar $n"
    Assert-StageEqual -Expected $n -Actual $fixed.Rank -Name "Stage27 repaired rank $n"
    Assert-StageEqual -Expected 1 -Actual $fixed.RejectedAnswers -Name "One rejected answer $n"
    if ($oldRank -ne $fixed.Rank) {$red++}
}
Assert-StageEqual -Expected 4 -Actual $red -Name 'Four historical boundary mismatches repaired'
$bad=0
try{[void](Get-Patch13AcceptedRank -First 0 -Step 1 -N 3)}catch{$bad++}
try{[void](Get-Patch13AcceptedRank -First ($m+1) -Step 1 -N 3)}catch{$bad++}
try{[void](Get-Patch13AcceptedRank -First 1 -Step 1 -N 0)}catch{$bad++}
try{[void](Get-Patch13AcceptedRank -First 1 -Step 1 -N ($m+1))}catch{$bad++}
try{[void](Get-Patch13AcceptedRank -First 1 -Step 0 -N 3)}catch{$bad++}
Assert-StageEqual -Expected 5 -Actual $bad -Name 'Five invalid domains rejected'
$f=Get-NormFoundationDay
$real=0
foreach($delta in @(0,3,11)){
    $target=$f+[System.Numerics.BigInteger]$delta
    $production=Invoke-Patch13RejectionRank -CalculationDay $f -TargetDay $target -N ([System.Numerics.BigInteger]720) -Seal 1
    $oracleSauce=Invoke-NormSauce -CalculationDay $f -TargetDay $target
    $oracleStream=Get-NormAnswerStream -SauceResult $oracleSauce -QueriedBowlId 1 -Seal 1
    $rank=Get-NormChooseRankShort -Stream $oracleStream -N ([System.Numerics.BigInteger]720)
    Assert-StageEqual -Expected $oracleStream.First -Actual $production.Stream.First -Name "Real first $delta"
    Assert-StageEqual -Expected $oracleStream.Step -Actual $production.Stream.Step -Name "Real step $delta"
    Assert-StageEqual -Expected $rank -Actual $production.Rank -Name "Real corrected rank $delta"
    Assert-StageEqual -Expected (oldFirstAnswerModuloRank -First $oracleStream.First -N ([System.Numerics.BigInteger]720)) -Actual $production.LegacyRank -Name "Historic modulo preserved $delta"
    Assert-StageEqual -Expected 58 -Actual $production.Context.legacyOrderMemoryWriteCount -Name "Real 58 writes $delta"
    Assert-StageEqual -Expected 1 -Actual $production.Context.patch12InvocationCount -Name "Patch12 precursor once $delta"
    Assert-StageEqual -Expected 'PATCH13_SHORT_REJECTION_ACTIVE' -Actual $production.Status -Name "Patch13 active $delta"
    $real++
}
Assert-StageEqual -Expected 3 -Actual $real -Name 'Three full predecessor histories'
$text=Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Patch13.ps1')
Assert-StageTrue -Condition ($text -match 'Invoke-Discovery13HistoricalRank' -and $text -match 'RejectedAnswers') -Name 'Real precursor and accepted answer used'
Assert-StageTrue -Condition ($text -notmatch 'Get-Norm|NormativeScroll|Get-NormChooseRank|Get-NormAnswerAt') -Name 'No normative oracle in production'
Write-Host "STAGE27_DIRECT_CASES=$cases"
Write-Host "STAGE27_ORACLE_MATCHES=$matching"
Write-Host "STAGE27_REJECTING_CASES=$rejecting"
Write-Host "STAGE27_HISTORICAL_REPAIRS=$red"
Write-Host "STAGE27_REAL_PRECURSOR_HISTORIES=$real"
$ok=Complete-StageTestRun
if(-not $ok){exit 1}
Write-Host 'STAGE27_RESULT=PASS'
exit 0
