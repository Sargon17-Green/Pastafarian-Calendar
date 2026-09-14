Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

. (Join-Path $root 'src/SourceLanguageCatalog.ps1')
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

$foundation = Get-NormFoundationDay

$metadata = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_STAGE=6\s*$') -Name 'Stage 6 ang kasalukuyang stage'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_KIND=DISCOVERY\s*$') -Name 'Discovery ang kasalukuyang uri'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_PATCH=03\s*$') -Name 'Discovery 03 ang kasalukuyang patch slot'
Assert-StageTrue -Condition ($metadata -match '(?m)^LAST_COMPLETED_STAGE=5\s*$') -Name 'Hindi pa minamarkahang kumpleto ang Stage 6 bago runtime'
Assert-StageTrue -Condition ($metadata -match '(?m)^EXPECTED_REPOSITORY_STATE=RED\s*$') -Name 'RED ang inaasahang Stage 6 repository state'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE05_RUNTIME_VERIFICATION=GREEN_CONFIRMED\s*$') -Name 'Nananatiling nakatala ang Stage 5 GREEN proof'

# Eksaktong raw historical formula.
Assert-StageEqual 0 (oldDistance -CalculationDay $foundation -TargetDay $foundation) 'oldDistance(F,F) ay 0'
Assert-StageEqual 2 (oldDistance -CalculationDay $foundation -TargetDay ($foundation + 1)) 'oldDistance(F,F+1) ay 2'
Assert-StageEqual 6 (oldDistance -CalculationDay $foundation -TargetDay ($foundation + 3)) 'oldDistance(F,F+3) ay 6'
Assert-StageEqual 1 (oldDistance -CalculationDay ($foundation - 1) -TargetDay $foundation) 'oldDistance(F-1,F) ay 1'
Assert-StageEqual 1 (oldDistance -CalculationDay ($foundation - 3) -TargetDay ($foundation + 3)) 'oldDistance(F-3,F+3) ay 1'

$expectedRedCount = 0
$matchCount = 0
$cases = @(
    [pscustomobject]@{ label = 'SAME_DAY'; calculation = $foundation; target = $foundation; expectedClass = 'EXPECTED_RED' },
    [pscustomobject]@{ label = 'F_TO_F_PLUS_1'; calculation = $foundation; target = $foundation + 1; expectedClass = 'MATCH' },
    [pscustomobject]@{ label = 'F_TO_F_PLUS_3'; calculation = $foundation; target = $foundation + 3; expectedClass = 'EXPECTED_RED' },
    [pscustomobject]@{ label = 'F_MINUS_1_TO_F'; calculation = $foundation - 1; target = $foundation; expectedClass = 'EXPECTED_RED' },
    [pscustomobject]@{ label = 'CROSS_F'; calculation = $foundation - 3; target = $foundation + 3; expectedClass = 'EXPECTED_RED' }
)

foreach ($case in $cases) {
    $ctx = Invoke-CalendarDateSpaghetti -CalculationDay $case.calculation -TargetDay $case.target
    $actual = [System.Numerics.BigInteger]$ctx.legacyDistanceValue
    $normCounts = Get-NormWorkCounts -CalculationDay $case.calculation -TargetDay $case.target
    $expected = [System.Numerics.BigInteger]$normCounts.distance

    # Previous patches must remain green.
    Assert-StageEqual 'SAVE_PATCH_ACTIVE' $ctx.patch01Status "Nananatiling aktibo ang Patch 01 para sa $($case.label)"
    Assert-StageEqual (Get-NormSave -X $case.calculation) $ctx.patch01PatchedValue "Nananatiling GREEN ang Patch 01 para sa $($case.label)"
    Assert-StageEqual 'DAY_TAG_PATCH_ACTIVE' $ctx.patch02Status "Nananatiling aktibo ang Patch 02 para sa $($case.label)"
    Assert-StageEqual (Get-NormDayCount -Day $case.calculation) $ctx.patch02ActionDayTag "GREEN ang Patch 02 action para sa $($case.label)"
    Assert-StageEqual (Get-NormDayCount -Day $case.target) $ctx.patch02TargetDayTag "GREEN ang Patch 02 target para sa $($case.label)"

    Assert-StageEqual 'LEGACY_DISTANCE_ACTIVE' $ctx.discovery03Status "Aktibo ang Discovery 03 adapter para sa $($case.label)"
    Assert-StageEqual 1 $ctx.discovery03InvocationCount "Isang Discovery 03 invocation para sa $($case.label)"
    Assert-StageEqual $case.calculation $ctx.legacyDistanceCalculationDay "Napanatili ang calculation day para sa $($case.label)"
    Assert-StageEqual $case.target $ctx.legacyDistanceTargetDay "Napanatili ang target day para sa $($case.label)"
    Assert-StageEqual $actual ([System.Numerics.BigInteger]$ctx.semanticCommitted['legacyDistanceValue']) "Committed ang raw legacy distance para sa $($case.label)"
    Assert-StageTrue -Condition ($ctx.metrics.ContainsKey('discovery03.legacyDistance.calls')) -Name "May Discovery 03 metric para sa $($case.label)"
    Assert-StageTrue -Condition (@($ctx.logs | Where-Object { $_.code -eq 'monster.discovery03.distance.adapter' }).Count -eq 1) -Name "Dumaan sa Discovery 03 adapter para sa $($case.label)"

    if ($actual -ne $expected) {
        $expectedRedCount++
        Write-Host "DISCOVERY03_CASE=$($case.label) ACTUAL=$actual EXPECTED=$expected CLASSIFICATION=EXPECTED_RED"
        Assert-StageEqual 'EXPECTED_RED' $case.expectedClass "Tamang classification para sa $($case.label)"
    }
    else {
        $matchCount++
        Write-Host "DISCOVERY03_CASE=$($case.label) ACTUAL=$actual EXPECTED=$expected CLASSIFICATION=MATCH"
        Assert-StageEqual 'MATCH' $case.expectedClass "Tamang classification para sa $($case.label)"
    }
}

Assert-StageEqual 4 $expectedRedCount 'Eksaktong apat na Discovery 03 expected-red divergences'
Assert-StageEqual 1 $matchCount 'Eksaktong isang Discovery 03 matching control'

# Per-invocation ownership.
$ctxA = Invoke-CalendarDateSpaghetti -CalculationDay $foundation -TargetDay ($foundation + 3)
$ctxB = Invoke-CalendarDateSpaghetti -CalculationDay $foundation -TargetDay ($foundation + 1)
Assert-StageTrue -Condition (-not [object]::ReferenceEquals($ctxA, $ctxB)) -Name 'Magkahiwalay ang Discovery 03 invocation contexts'
Assert-StageEqual 6 $ctxA.legacyDistanceValue 'Hindi nabago ang unang legacy distance state'
Assert-StageEqual 2 $ctxB.legacyDistanceValue 'Sarili ang legacy distance state ng ikalawang invocation'

$monsterText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/MonsterSkeleton.ps1')
$productionFiles = @(
    'src/Discovery01.ps1',
    'src/Patch01.ps1',
    'src/Discovery02.ps1',
    'src/Patch02.ps1',
    'src/Discovery03.ps1'
)
$productionText = $monsterText
foreach ($rel in $productionFiles) {
    $productionText += "`n" + (Get-Content -Raw -Encoding UTF8 (Join-Path $root $rel))
}
$discovery03Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Discovery03.ps1')

Assert-StageTrue -Condition ($productionText -notmatch 'Invoke-NormSauce|Get-NormCalendarDate|Get-NormSave|Get-NormDayCount|Get-NormWorkCounts') -Name 'Hindi tumatawag sa normative oracle ang Stage 6 production path'
Assert-StageTrue -Condition ($discovery03Text -match 'function oldDistance') -Name 'May hiwalay na historical oldDistance function'
Assert-StageTrue -Condition ($discovery03Text -match 'dayTagWithFoundationScar') -Name 'Talagang ginagamit ng oldDistance ang Patch 02 day-tag helper'
Assert-StageTrue -Condition ($productionText -notmatch 'patchedCounts') -Name 'Walang Stage 7 Patch 03 patchedCounts correction'
$futureNames = @('mutateStonesWrong','orderAt46Latch','biasedLegacyPick','LEGACY_YEAR_MAX','VirtualLegacyList','oldContiguousMonthDayGuess')
foreach ($name in $futureNames) {
    Assert-StageTrue -Condition ($productionText -notmatch [regex]::Escape($name)) -Name "Walang future patch code: $name"
}

Write-Host "DISCOVERY03_EXPECTED_RED_COUNT=$expectedRedCount"
Write-Host "DISCOVERY03_MATCH_COUNT=$matchCount"
Write-Host 'STAGE06_REPOSITORY_STATE=EXPECTED_RED'

$ok = Complete-StageTestRun
if (-not $ok) { exit 1 }
Write-Host 'STAGE06_RESULT=PASS'
exit 0
