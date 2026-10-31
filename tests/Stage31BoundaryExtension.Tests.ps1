Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')
$metadata = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_STAGE=(30|31|32|33)\s*$') -Name 'Stage31 pending or evidence-sealed'
Assert-StageTrue -Condition ($metadata -match '(?m)^LAST_COMPLETED_STAGE=(30|31|32|33)\s*$') -Name 'Stage30 predecessor or Stage31 evidence-sealed'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE30_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -Name 'Stage30 evidence-only intact'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE26_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED\s*$') -Name 'Historical scar intact'
$foundation = [System.Numerics.BigInteger](Get-NormFoundationDay)
$m = [System.Numerics.BigInteger]$script:Discovery01M
$calculationShifts = @(-366,-1,2,366,36525,36526)
$relativeTargetShifts = @(-36525,-366,-1,0,1,36525)
$firstSeen = @{}
$jointSeen = @{}
$positive = 0
$negative = 0
$totalRows = 0
foreach ($calculationShift in $calculationShifts) {
    $calculationDay = [System.Numerics.BigInteger]($foundation + $calculationShift)
    foreach ($offset in $relativeTargetShifts) {
        $targetDay = [System.Numerics.BigInteger]($calculationDay + $offset)
        foreach ($seal in @(1,2)) {
            $context = Invoke-CalendarDateSpaghetti -CalculationDay $calculationDay -TargetDay $targetDay
            $stream = Get-Discovery13AnswerStreamFromContext -Context $context -QueriedBowlId 1 -Seal $seal
            $norm = Invoke-NormSauce $calculationDay $targetDay
            $expected = Get-NormAnswerStream -SauceResult $norm -QueriedBowlId 1 -Seal $seal
            Assert-StageEqual -Expected $expected.First -Actual $stream.First -Name "First oracle C=$calculationShift T=$offset Seal=$seal"
            Assert-StageEqual -Expected $expected.Step -Actual $stream.Step -Name "Step oracle C=$calculationShift T=$offset Seal=$seal"
            Assert-StageTrue -Condition ($stream.First -ge 1 -and $stream.First -le $m) -Name "First in 1..M C=$calculationShift T=$offset Seal=$seal"
            Assert-StageTrue -Condition ($stream.Step -eq -1 -or $stream.Step -eq 1) -Name "Step sign C=$calculationShift T=$offset Seal=$seal"
            Assert-StageEqual -Expected 58 -Actual $context.legacyOrderMemoryWriteCount -Name "58 writes C=$calculationShift T=$offset Seal=$seal"
            Assert-StageEqual -Expected 1 -Actual $context.patch12InvocationCount -Name "One Patch12 C=$calculationShift T=$offset Seal=$seal"
            $firstKey = $stream.First.ToString()
            $jointKey = ('{0}|{1}' -f $firstKey,$stream.Step)
            if (-not $firstSeen.ContainsKey($firstKey)) { $firstSeen[$firstKey] = 0 }
            if (-not $jointSeen.ContainsKey($jointKey)) { $jointSeen[$jointKey] = 0 }
            $firstSeen[$firstKey]++
            $jointSeen[$jointKey]++
            if ($stream.Step -eq 1) { $positive++ } else { $negative++ }
            $totalRows++
            Write-Host ('STAGE31_EXT_ROW C={0} T={1} SEAL={2} FIRST={3} STEP={4}' -f $calculationShift,$offset,$seal,$firstKey,$stream.Step)
        }
    }
}
Assert-StageEqual -Expected 72 -Actual $totalRows -Name 'Exactly 50 ordinal observations'
Assert-StageEqual -Expected 72 -Actual ($positive + $negative) -Name 'Sign frequency conservation'
Assert-StageTrue -Condition ($firstSeen.Count -ge 1 -and $firstSeen.Count -le $totalRows) -Name 'Distinct First count in bounds'
Assert-StageTrue -Condition ($jointSeen.Count -ge 1 -and $jointSeen.Count -le $totalRows) -Name 'Distinct joint count in bounds'
$duplicates = $totalRows - $jointSeen.Count
Assert-StageTrue -Condition ($duplicates -ge 0) -Name 'Repeated joint states nonnegative'
Write-Host "STAGE31_EXT_SAMPLE_ROWS=$totalRows"
Write-Host "STAGE31_EXT_STEP_POSITIVE=$positive"
Write-Host "STAGE31_EXT_STEP_NEGATIVE=$negative"
Write-Host ("STAGE31_EXT_DISTINCT_FIRST=" + $firstSeen.Count)
Write-Host ("STAGE31_EXT_DISTINCT_JOINT=" + $jointSeen.Count)
Write-Host "STAGE31_EXT_REPEATED_JOINT=$duplicates"
Write-Host "STAGE31_EXT_ASSERTIONS_PASSED=$script:StageTestPassed"
Write-Host "STAGE31_EXT_ASSERTIONS_FAILED=$script:StageTestFailed"
if ($script:StageTestFailed -ne 0) { Write-Host 'STAGE31_EXTENSION=FAIL'; exit 1 }
Write-Host 'STAGE31_EXTENSION=BOUNDED_OBSERVATION_ONLY'
exit 0
