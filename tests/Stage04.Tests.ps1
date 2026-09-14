Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

. (Join-Path $root 'src/SourceLanguageCatalog.ps1')
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

$m = Get-NormM
$foundation = Get-NormFoundationDay

$metadata = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_STAGE=4\s*$') -Name 'Stage 4 ang kasalukuyang stage'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_KIND=DISCOVERY\s*$') -Name 'Discovery ang kasalukuyang uri'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_PATCH=02\s*$') -Name 'Discovery 02 ang kasalukuyang patch slot'
Assert-StageTrue -Condition ($metadata -match '(?m)^LAST_COMPLETED_STAGE=3\s*$') -Name 'Hindi pa minamarkahang kumpleto ang Stage 4 bago runtime'
Assert-StageTrue -Condition ($metadata -match '(?m)^EXPECTED_REPOSITORY_STATE=RED\s*$') -Name 'RED ang inaasahang Stage 4 repository state'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE03_RUNTIME_VERIFICATION=GREEN_CONFIRMED\s*$') -Name 'Nananatiling nakatala ang Stage 3 GREEN proof'

# Eksaktong historical function.
Assert-StageEqual 4 (oldDayTag -Day ($foundation - 2)) 'oldDayTag(FOUNDATION-2) ay 4'
Assert-StageEqual 2 (oldDayTag -Day ($foundation - 1)) 'oldDayTag(FOUNDATION-1) ay 2'
Assert-StageEqual 0 (oldDayTag -Day $foundation) 'oldDayTag(FOUNDATION) ay 0'
Assert-StageEqual 2 (oldDayTag -Day ($foundation + 1)) 'oldDayTag(FOUNDATION+1) ay 2'
Assert-StageEqual 4 (oldDayTag -Day ($foundation + 2)) 'oldDayTag(FOUNDATION+2) ay 4'

$expectedRedCount = 0
$matchCount = 0
$cases = @(
    [pscustomobject]@{ label = 'F_MINUS_2'; value = $foundation - 2; expectedClass = 'MATCH' },
    [pscustomobject]@{ label = 'F_MINUS_1'; value = $foundation - 1; expectedClass = 'MATCH' },
    [pscustomobject]@{ label = 'F'; value = $foundation; expectedClass = 'EXPECTED_RED' },
    [pscustomobject]@{ label = 'F_PLUS_1'; value = $foundation + 1; expectedClass = 'EXPECTED_RED' },
    [pscustomobject]@{ label = 'F_PLUS_2'; value = $foundation + 2; expectedClass = 'EXPECTED_RED' }
)

foreach ($case in $cases) {
    $ctx = Invoke-CalendarDateSpaghetti -CalculationDay $case.value -TargetDay ($foundation - 1)
    $actual = [System.Numerics.BigInteger]$ctx.legacyActionDayTag
    $expected = [System.Numerics.BigInteger](Get-NormDayCount -Day $case.value)
    $patch01Expected = [System.Numerics.BigInteger](Get-NormSave -X $case.value)

    Assert-StageEqual 'SAVE_PATCH_ACTIVE' $ctx.patch01Status "Nananatiling aktibo ang Patch 01 para sa $($case.label)"
    Assert-StageEqual $patch01Expected $ctx.patch01PatchedValue "Nananatiling GREEN ang Patch 01 para sa $($case.label)"
    Assert-StageEqual 'LEGACY_DAY_TAG_ACTIVE' $ctx.discovery02Status "Aktibo ang Discovery 02 adapter para sa $($case.label)"
    Assert-StageEqual 1 $ctx.discovery02InvocationCount "Isang Discovery 02 invocation para sa $($case.label)"
    Assert-StageEqual $actual ([System.Numerics.BigInteger]$ctx.semanticCommitted['legacyActionDayTag']) "Committed ang action day tag para sa $($case.label)"
    Assert-StageTrue -Condition ($ctx.metrics.ContainsKey('discovery02.legacyDayTag.calls')) -Name "May Discovery 02 metric para sa $($case.label)"
    Assert-StageTrue -Condition (@($ctx.logs | Where-Object { $_.code -eq 'monster.discovery02.daytag.adapter' }).Count -eq 1) -Name "Dumaan sa Discovery 02 adapter para sa $($case.label)"

    if ($actual -ne $expected) {
        $expectedRedCount++
        Write-Host "DISCOVERY02_CASE=$($case.label) ACTUAL=$actual EXPECTED=$expected CLASSIFICATION=EXPECTED_RED"
        Assert-StageEqual 'EXPECTED_RED' $case.expectedClass "Tamang classification para sa $($case.label)"
    }
    else {
        $matchCount++
        Write-Host "DISCOVERY02_CASE=$($case.label) ACTUAL=$actual EXPECTED=$expected CLASSIFICATION=MATCH"
        Assert-StageEqual 'MATCH' $case.expectedClass "Tamang classification para sa $($case.label)"
    }
}

Assert-StageEqual 3 $expectedRedCount 'Eksaktong tatlong Discovery 02 expected-red divergences'
Assert-StageEqual 2 $matchCount 'Eksaktong dalawang Discovery 02 matching controls'

# Patunayan din ang target-day route.
$targetCtx = Invoke-CalendarDateSpaghetti -CalculationDay ($foundation - 1) -TargetDay ($foundation + 1)
Assert-StageEqual 2 $targetCtx.legacyTargetDayTag 'Legacy target day tag sa FOUNDATION+1 ay 2'
Assert-StageEqual 3 (Get-NormDayCount -Day ($foundation + 1)) 'Normative target day tag sa FOUNDATION+1 ay 3'
Assert-StageEqual 2 ([System.Numerics.BigInteger]$targetCtx.semanticCommitted['legacyTargetDayTag']) 'Committed ang target legacy day tag'

# Per-invocation ownership.
$ctxA = Invoke-CalendarDateSpaghetti -CalculationDay $foundation -TargetDay ($foundation - 1)
$ctxB = Invoke-CalendarDateSpaghetti -CalculationDay ($foundation + 2) -TargetDay ($foundation - 2)
Assert-StageTrue -Condition (-not [object]::ReferenceEquals($ctxA, $ctxB)) -Name 'Magkahiwalay ang Discovery 02 invocation contexts'
Assert-StageEqual 0 $ctxA.legacyActionDayTag 'Hindi nabago ang unang action day tag'
Assert-StageEqual 4 $ctxB.legacyActionDayTag 'Sarili ang action day tag ng ikalawang invocation'

$monsterText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/MonsterSkeleton.ps1')
$discovery1Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Discovery01.ps1')
$patch1Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Patch01.ps1')
$discovery2Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Discovery02.ps1')
$productionText = $monsterText + "`n" + $discovery1Text + "`n" + $patch1Text + "`n" + $discovery2Text

Assert-StageTrue -Condition ($productionText -notmatch 'Invoke-NormSauce|Get-NormCalendarDate|Get-NormSave|Get-NormDayCount') -Name 'Hindi tumatawag sa normative oracle ang Stage 4 production path'
Assert-StageTrue -Condition ($discovery2Text -match 'function oldDayTag') -Name 'May hiwalay na historical oldDayTag function'
Assert-StageTrue -Condition ($productionText -notmatch 'dayTagWithFoundationScar') -Name 'Walang Stage 5 Patch 02 correction'
$futureNames = @('oldDistance','mutateStonesWrong','orderAt46Latch','biasedLegacyPick','LEGACY_YEAR_MAX','VirtualLegacyList','oldContiguousMonthDayGuess')
foreach ($name in $futureNames) {
    Assert-StageTrue -Condition ($productionText -notmatch [regex]::Escape($name)) -Name "Walang future patch code: $name"
}

Write-Host "DISCOVERY02_EXPECTED_RED_COUNT=$expectedRedCount"
Write-Host "DISCOVERY02_MATCH_COUNT=$matchCount"
Write-Host 'STAGE04_REPOSITORY_STATE=EXPECTED_RED'

$ok = Complete-StageTestRun
if (-not $ok) { exit 1 }
Write-Host 'STAGE04_RESULT=PASS'
exit 0
