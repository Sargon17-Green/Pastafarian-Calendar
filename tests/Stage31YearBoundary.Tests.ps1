Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

$metadata = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_STAGE=30\s*$') -Name 'Research preserves Stage30 current stage'
Assert-StageTrue -Condition ($metadata -match '(?m)^LAST_COMPLETED_STAGE=30\s*$') -Name 'Research preserves Stage30 completed stage'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE30_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -Name 'Stage30 evidence-only gate preserved'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE26_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED\s*$') -Name 'Stage26 historical red preserved'

$foundation = [System.Numerics.BigInteger](Get-NormFoundationDay)
$m = [System.Numerics.BigInteger]$script:Discovery01M
$year = Get-NormYear5000 -CalculationDay $foundation
$yearLength = [System.Numerics.BigInteger]($year.CloseGateDay - $year.OpenGateDay)
Assert-StageEqual -Expected ([System.Numerics.BigInteger]5000) -Actual $year.Number -Name 'Normative year number'
Assert-StageTrue -Condition ($year.OpenGateDay -lt $foundation -and $foundation -le $year.CloseGateDay) -Name 'Foundation lies inside normative year 5000'
Assert-StageTrue -Condition ($yearLength -ge 252 -and $yearLength -le 5778) -Name 'Normative year length in declared bounds'
Assert-StageTrue -Condition (($year.CloseGateIndex - $year.OpenGateIndex) -ge 6) -Name 'Normative gate span at least six'

$targets = @(
    [pscustomobject]@{ Label='OPEN_MINUS_ONE'; Day=[System.Numerics.BigInteger]($year.OpenGateDay - 1) }
    [pscustomobject]@{ Label='OPEN'; Day=[System.Numerics.BigInteger]$year.OpenGateDay }
    [pscustomobject]@{ Label='OPEN_PLUS_ONE'; Day=[System.Numerics.BigInteger]($year.OpenGateDay + 1) }
    [pscustomobject]@{ Label='CLOSE_MINUS_ONE'; Day=[System.Numerics.BigInteger]($year.CloseGateDay - 1) }
    [pscustomobject]@{ Label='CLOSE'; Day=[System.Numerics.BigInteger]$year.CloseGateDay }
    [pscustomobject]@{ Label='CLOSE_PLUS_ONE'; Day=[System.Numerics.BigInteger]($year.CloseGateDay + 1) }
)
$positive = 0
$negative = 0
$firstSeen = @{}
$jointSeen = @{}
$rows = 0
Write-Host ('STAGE31_BOUNDARY_YEAR=' + $year.Number)
Write-Host ('STAGE31_BOUNDARY_OPEN=' + $year.OpenGateDay)
Write-Host ('STAGE31_BOUNDARY_CLOSE=' + $year.CloseGateDay)
Write-Host ('STAGE31_BOUNDARY_YEAR_DAYS=' + $yearLength)
foreach ($item in $targets) {
    foreach ($seal in @(1,2)) {
        $targetDay = [System.Numerics.BigInteger]$item.Day
        $context = Invoke-CalendarDateSpaghetti -CalculationDay $foundation -TargetDay $targetDay
        $stream = Get-Discovery13AnswerStreamFromContext -Context $context -QueriedBowlId 1 -Seal $seal
        $norm = Invoke-NormSauce $foundation $targetDay
        $expected = Get-NormAnswerStream -SauceResult $norm -QueriedBowlId 1 -Seal $seal
        Assert-StageEqual -Expected $expected.First -Actual $stream.First -Name "First oracle $($item.Label) Seal=$seal"
        Assert-StageEqual -Expected $expected.Step -Actual $stream.Step -Name "Step oracle $($item.Label) Seal=$seal"
        Assert-StageTrue -Condition ($stream.First -ge 1 -and $stream.First -le $m) -Name "First domain $($item.Label) Seal=$seal"
        Assert-StageTrue -Condition ($stream.Step -eq -1 -or $stream.Step -eq 1) -Name "Step sign $($item.Label) Seal=$seal"
        Assert-StageEqual -Expected 58 -Actual $context.legacyOrderMemoryWriteCount -Name "Legacy writes $($item.Label) Seal=$seal"
        Assert-StageEqual -Expected 1 -Actual $context.patch12InvocationCount -Name "Patch12 calls $($item.Label) Seal=$seal"
        $firstKey = $stream.First.ToString()
        $jointKey = ('{0}|{1}' -f $firstKey,$stream.Step)
        $firstSeen[$firstKey] = $true
        $jointSeen[$jointKey] = $true
        if ($stream.Step -eq 1) { $positive++ } else { $negative++ }
        $rows++
        Write-Host ('STAGE31_BOUNDARY_ROW LABEL={0} TARGET={1} SEAL={2} FIRST={3} STEP={4}' -f $item.Label,$targetDay,$seal,$firstKey,$stream.Step)
    }
}
Assert-StageEqual -Expected 12 -Actual $rows -Name 'Exactly twelve boundary observations'
Assert-StageEqual -Expected 12 -Actual ($positive + $negative) -Name 'Boundary sign conservation'
Assert-StageTrue -Condition ($firstSeen.Count -ge 1 -and $firstSeen.Count -le 12) -Name 'First distinct count bounded'
Assert-StageTrue -Condition ($jointSeen.Count -ge 1 -and $jointSeen.Count -le 12) -Name 'Joint distinct count bounded'
Assert-StageTrue -Condition (($rows - $jointSeen.Count) -ge 0) -Name 'Repeated joint count nonnegative'
Write-Host "STAGE31_BOUNDARY_ROWS=$rows"
Write-Host "STAGE31_BOUNDARY_STEP_POSITIVE=$positive"
Write-Host "STAGE31_BOUNDARY_STEP_NEGATIVE=$negative"
Write-Host ("STAGE31_BOUNDARY_DISTINCT_FIRST=" + $firstSeen.Count)
Write-Host ("STAGE31_BOUNDARY_DISTINCT_JOINT=" + $jointSeen.Count)
Write-Host "STAGE31_BOUNDARY_ASSERTIONS_PASSED=$script:StageTestPassed"
Write-Host "STAGE31_BOUNDARY_ASSERTIONS_FAILED=$script:StageTestFailed"
if ($script:StageTestFailed -ne 0) { Write-Host 'STAGE31_YEAR_BOUNDARY=FAIL'; exit 1 }
Write-Host 'STAGE31_YEAR_BOUNDARY=RESEARCH_ONLY'
exit 0
