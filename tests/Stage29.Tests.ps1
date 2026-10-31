Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')
$metadata = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_STAGE=(29|30|31|32)\s*$') -Name 'Stage29 Patch14 opened'
$stage29Awaiting = ($metadata -match '(?m)^LAST_COMPLETED_STAGE=28\s*$') -and ($metadata -match '(?m)^STAGE29_RUNTIME_VERIFICATION=AWAITING\s*$')
$stage29Sealed = ($metadata -match '(?m)^LAST_COMPLETED_STAGE=(29|30|31|32)\s*$') -and ($metadata -match '(?m)^STAGE29_RUNTIME_VERIFICATION=GREEN_CONFIRMED\s*$')
Assert-StageTrue -Condition ($stage29Awaiting -or $stage29Sealed) -Name 'Stage29 awaiting or verified sealed metadata pair'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE28_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -Name 'Stage28 Native discovery evidence sealed'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE27_RUNTIME_VERIFICATION=GREEN_CONFIRMED\s*$') -Name 'Stage27 green preserved'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE26_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED\s*$') -Name 'Stage26 intentional historical scar preserved'
$m = [System.Numerics.BigInteger](Get-NormM)
$space = [System.Numerics.BigInteger]($m * $m)
$cases=0
$rejects=0
foreach ($n in @(($m+1),($m+2),($space-1),$space)) {
    $n = [System.Numerics.BigInteger]$n
    $limit = [System.Numerics.BigInteger](($space / $n) * $n)
    foreach ($first in @([System.Numerics.BigInteger]1,($m-1),$m)) {
        $first = [System.Numerics.BigInteger]$first
        foreach ($step in @(-1,1)) {
            $actual = Get-Patch14WideAcceptedRank -First $first -Step $step -N $n
            $independent = Get-NormChooseRankWide -Stream ([pscustomobject]@{ First=$first; Step=$step }) -N $n
            Assert-StageEqual -Expected $independent -Actual $actual.Rank -Name "Patch14 wide oracle N=$n F=$first S=$step"
            Assert-StageTrue -Condition ($actual.Accepted -ge 1 -and $actual.Accepted -le $limit) -Name 'Accepted inside bounded threshold'
            Assert-StageEqual -Expected $space -Actual $actual.Space -Name 'Composite space fixed'
            if ($actual.RejectedCompositeWords -gt 0) { $rejects++ }
            $cases++
        }
    }
}
Assert-StageEqual -Expected 24 -Actual $cases -Name 'All 24 wide boundary cases verified'
Assert-StageTrue -Condition ($rejects -gt 0) -Name 'At least one full-composite rejection verified'
$bad=0
foreach ($testCase in @(
    @{First=1;Step=1;N=$m},
    @{First=1;Step=1;N=($space+1)},
    @{First=0;Step=1;N=($m+1)},
    @{First=($m+1);Step=1;N=($m+1)},
    @{First=1;Step=0;N=($m+1)}
)) {
    try { [void](Get-Patch14WideAcceptedRank -First ([System.Numerics.BigInteger]$testCase.First) -Step ([int]$testCase.Step) -N ([System.Numerics.BigInteger]$testCase.N)) }
    catch { $bad++ }
}
Assert-StageEqual -Expected 5 -Actual $bad -Name 'Wide invalid domains rejected'
$foundation = Get-NormFoundationDay
$real = 0
foreach ($delta in @(0,3,11)) {
    $target = $foundation + [System.Numerics.BigInteger]$delta
    $n = [System.Numerics.BigInteger]($m+1)
    $actual = Invoke-Patch14WideRank -CalculationDay $foundation -TargetDay $target -N $n -Seal 1
    $norm = Invoke-NormSauce -CalculationDay $foundation -TargetDay $target
    $expectedStream = Get-NormAnswerStream -SauceResult $norm -QueriedBowlId 1 -Seal 1
    $expectedRank = Get-NormChooseRankWide -Stream $expectedStream -N $n
    Assert-StageEqual -Expected $expectedStream.First -Actual $actual.Stream.First -Name "Real precursor First delta=$delta"
    Assert-StageEqual -Expected $expectedStream.Step -Actual $actual.Stream.Step -Name "Real precursor Step delta=$delta"
    Assert-StageEqual -Expected $expectedRank -Actual $actual.Rank -Name "Real wide compatibility delta=$delta"
    Assert-StageEqual -Expected 58 -Actual $actual.Context.legacyOrderMemoryWriteCount -Name "Real predecessor writes delta=$delta"
    Assert-StageEqual -Expected 1 -Actual $actual.Context.patch12InvocationCount -Name "Real single Patch12 delta=$delta"
    Assert-StageEqual -Expected 'PATCH14_WIDE_DETERMINISTIC_COMPATIBILITY' -Actual $actual.Status -Name "Wide status delta=$delta"
    $real++
}
Assert-StageEqual -Expected 3 -Actual $real -Name 'Three real wide precursor histories'
# Stage27 API remains valid and identical for the bounded short domain.
$short = Get-Patch13AcceptedRank -First ([System.Numerics.BigInteger]1) -Step 1 -N ([System.Numerics.BigInteger]720)
$shortOracle = Get-NormChooseRankShort -Stream ([pscustomobject]@{First=[System.Numerics.BigInteger]1;Step=1}) -N ([System.Numerics.BigInteger]720)
Assert-StageEqual -Expected $shortOracle -Actual $short.Rank -Name 'Stage27 short compatibility unchanged'
$source = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Patch14.ps1')
Assert-StageTrue -Condition ($source -notmatch 'Get-Norm|NormativeScroll|Get-NormChooseRank') -Name 'No oracle copied into Patch14 production'
Assert-StageTrue -Condition ($source -match 'Invoke-CalendarDateSpaghetti' -and $source -match 'Get-Discovery13AnswerStreamFromContext') -Name 'One real predecessor path'
Write-Host "STAGE29_DIRECT_CASES=$cases"
Write-Host "STAGE29_REJECTION_CASES=$rejects"
Write-Host "STAGE29_INVALID_REJECTIONS=$bad"
Write-Host "STAGE29_REAL_PRECURSOR_HISTORIES=$real"
$ok = Complete-StageTestRun
if (-not $ok) { exit 1 }
Write-Host 'STAGE29_PATCH14_NATIVE=PASS'
exit 0
