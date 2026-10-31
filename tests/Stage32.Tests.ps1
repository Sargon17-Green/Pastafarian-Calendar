Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')
$metadata = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')
$stage32Awaiting = ($metadata -match '(?m)^CURRENT_STAGE=31\s*$') -and ($metadata -match '(?m)^LAST_COMPLETED_STAGE=31\s*$') -and ($metadata -match '(?m)^STAGE32_RUNTIME_VERIFICATION=PENDING_NATIVE\s*$')
$stage32Sealed = ((($metadata -match '(?m)^CURRENT_STAGE=32\s*$') -and ($metadata -match '(?m)^LAST_COMPLETED_STAGE=32\s*$')) -or (($metadata -match '(?m)^CURRENT_STAGE=33\s*$') -and ($metadata -match '(?m)^LAST_COMPLETED_STAGE=33\s*$'))) -and ($metadata -match '(?m)^STAGE32_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$')
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_STAGE=(31|32|33)\s*$') -Name 'Stage32 current or exact-seal recheck'
Assert-StageTrue -Condition ($stage32Awaiting -or $stage32Sealed) -Name 'Stage32 metadata is a consistent pending or sealed pair'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE31_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -Name 'Stage31 research evidence preserved'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE26_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED\s*$') -Name 'Historical Stage26 red preserved'
$f = [System.Numerics.BigInteger](Get-NormFoundationDay)
$y = Get-NormYear5000 -CalculationDay $f
$m = [System.Numerics.BigInteger]$script:Discovery01M
$yearLength = [System.Numerics.BigInteger]($y.CloseGateDay - $y.OpenGateDay)
Assert-StageEqual -Expected ([System.Numerics.BigInteger]5000) -Actual $y.Number -Name 'Normative year 5000'
Assert-StageTrue -Condition ($y.OpenGateDay -lt $f -and $f -le $y.CloseGateDay) -Name 'Foundation inside half-open year'
Assert-StageTrue -Condition ($yearLength -ge 252 -and $yearLength -le 5778) -Name 'Normative length bounded'
Assert-StageTrue -Condition (($y.CloseGateIndex - $y.OpenGateIndex) -ge 6) -Name 'Year gate index span'
$cases = @(
    [pscustomobject]@{ Label='BEFORE_OPEN'; Day=[System.Numerics.BigInteger]($y.OpenGateDay - 1) }
    [pscustomobject]@{ Label='AT_OPEN'; Day=[System.Numerics.BigInteger]$y.OpenGateDay }
    [pscustomobject]@{ Label='BEFORE_CLOSE'; Day=[System.Numerics.BigInteger]($y.CloseGateDay - 1) }
    [pscustomobject]@{ Label='AT_CLOSE'; Day=[System.Numerics.BigInteger]$y.CloseGateDay }
    [pscustomobject]@{ Label='BEFORE_FOUNDATION'; Day=[System.Numerics.BigInteger]($f - 1) }
    [pscustomobject]@{ Label='AT_FOUNDATION'; Day=[System.Numerics.BigInteger]$f }
    [pscustomobject]@{ Label='AFTER_FOUNDATION'; Day=[System.Numerics.BigInteger]($f + 1) }
    [pscustomobject]@{ Label='DISTANT_ORDINAL'; Day=[System.Numerics.BigInteger]($f + 36525) }
)
$pairs=0; $endpoints=0; $firstChanged=0; $firstSame=0; $signFlipped=0; $signSame=0; $gatePairs=0
$distinctDeltas = @{}
foreach ($item in $cases) {
    foreach ($seal in @(1,2)) {
        $observations = @()
        foreach ($increment in @(0,1)) {
            $day = [System.Numerics.BigInteger]($item.Day + $increment)
            $context = Invoke-CalendarDateSpaghetti -CalculationDay $f -TargetDay $day
            $actual = Get-Discovery13AnswerStreamFromContext -Context $context -QueriedBowlId 1 -Seal $seal
            $expected = Get-NormAnswerStream -SauceResult (Invoke-NormSauce $f $day) -QueriedBowlId 1 -Seal $seal
            $name = ('{0} Seal={1} Increment={2}' -f $item.Label,$seal,$increment)
            Assert-StageEqual -Expected $expected.First -Actual $actual.First -Name "First oracle $name"
            Assert-StageEqual -Expected $expected.Step -Actual $actual.Step -Name "Step oracle $name"
            Assert-StageTrue -Condition ($actual.First -ge 1 -and $actual.First -le $m) -Name "First domain $name"
            Assert-StageTrue -Condition ($actual.Step -eq -1 -or $actual.Step -eq 1) -Name "Step sign $name"
            Assert-StageEqual -Expected 58 -Actual $context.legacyOrderMemoryWriteCount -Name "58 writes $name"
            Assert-StageEqual -Expected 1 -Actual $context.patch12InvocationCount -Name "One Patch12 $name"
            $observations += [pscustomobject]@{ Actual=$actual; Expected=$expected }
            $endpoints++
        }
        $a=[System.Numerics.BigInteger]$observations[0].Actual.First
        $b=[System.Numerics.BigInteger]$observations[1].Actual.First
        $ea=[System.Numerics.BigInteger]$observations[0].Expected.First
        $eb=[System.Numerics.BigInteger]$observations[1].Expected.First
        $delta=[System.Numerics.BigInteger]((($b-$a)%$m+$m)%$m)
        $oracleDelta=[System.Numerics.BigInteger]((($eb-$ea)%$m+$m)%$m)
        $flip=($observations[0].Actual.Step -ne $observations[1].Actual.Step)
        $oracleFlip=($observations[0].Expected.Step -ne $observations[1].Expected.Step)
        Assert-StageEqual -Expected $oracleDelta -Actual $delta -Name "Adjacent modular delta $($item.Label) Seal=$seal"
        Assert-StageEqual -Expected $oracleFlip -Actual $flip -Name "Adjacent sign flip $($item.Label) Seal=$seal"
        if ($delta -eq [System.Numerics.BigInteger]0) { $firstSame++ } else { $firstChanged++ }
        if ($flip) { $signFlipped++ } else { $signSame++ }
        if ($item.Label -eq 'AT_OPEN' -or $item.Label -eq 'AT_CLOSE') { $gatePairs++ }
        $distinctDeltas[$delta.ToString()]=$true
        $pairs++
        Write-Host ('STAGE32_PAIR LABEL={0} SEAL={1} BASE={2} FIRST0={3} STEP0={4} FIRST1={5} STEP1={6} DELTA={7} FLIP={8}' -f $item.Label,$seal,$item.Day,$a,$observations[0].Actual.Step,$b,$observations[1].Actual.Step,$delta,$flip)
    }
}
Assert-StageEqual -Expected 8 -Actual $cases.Count -Name 'Eight bases'
Assert-StageEqual -Expected 16 -Actual $pairs -Name 'Sixteen adjacent pairs'
Assert-StageEqual -Expected 32 -Actual $endpoints -Name 'Thirty-two endpoints'
Assert-StageEqual -Expected 16 -Actual ($firstChanged+$firstSame) -Name 'First change conservation'
Assert-StageEqual -Expected 16 -Actual ($signFlipped+$signSame) -Name 'Step flip conservation'
Assert-StageEqual -Expected 4 -Actual $gatePairs -Name 'Four gate-crossing pairs'
Assert-StageTrue -Condition ($distinctDeltas.Count -ge 1 -and $distinctDeltas.Count -le 16) -Name 'Distinct deltas bounded'
Write-Host "STAGE32_ADJACENT_PAIRS=$pairs"
Write-Host "STAGE32_ENDPOINTS=$endpoints"
Write-Host "STAGE32_FIRST_CHANGED=$firstChanged"
Write-Host "STAGE32_FIRST_SAME=$firstSame"
Write-Host "STAGE32_STEP_FLIPPED=$signFlipped"
Write-Host "STAGE32_STEP_SAME=$signSame"
Write-Host ("STAGE32_DISTINCT_DELTAS=" + $distinctDeltas.Count)
Write-Host "STAGE32_ASSERTIONS_PASSED=$script:StageTestPassed"
Write-Host "STAGE32_ASSERTIONS_FAILED=$script:StageTestFailed"
if ($script:StageTestPassed -ne 239) { Write-Host 'STAGE32_ASSERTION_COUNT=FAIL_EXPECTED_239'; exit 1 }
if ($script:StageTestFailed -ne 0) { Write-Host 'STAGE32_DISCOVERY17=FAIL'; exit 1 }
Write-Host 'STAGE32_DISCOVERY17=BOUNDED_RESEARCH_ONLY'
exit 0
