Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

. (Join-Path $root 'src/SourceLanguageCatalog.ps1')
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

function Get-Stage20ArraySignature {
    param([AllowNull()]$Values)
    if ($null -eq $Values) { return '<NULL>' }
    return (($Values | ForEach-Object {
        if ($null -eq $_) { '<NULL>' } else { [string]$_ }
    }) -join ',')
}

function Get-Stage20SnapshotExpected {
    param(
        [Parameter(Mandatory)][int]$I,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$Drop,
        [AllowNull()][Parameter(Mandatory)][System.Array]$Order,
        [AllowNull()][Parameter(Mandatory)][System.Array]$Pours,
        [AllowNull()][Parameter(Mandatory)][System.Array]$Stones,
        [AllowNull()][Parameter(Mandatory)][System.Array]$Bowls
    )

    $kindByPosition = [int[]](0,1,2,3,4,0)
    $old = [object[]]::new(7)
    $nextBowls = [object[]]::new(7)

    for ($b = 1; $b -le 6; $b++) {
        $old[$b] = [System.Numerics.BigInteger]$Bowls[$b]
    }

    for ($position = 1; $position -le 6; $position++) {
        $bowlId = [int]$Order[$position - 1]
        $prevId = [int]$Order[(($position - 2 + 6) % 6)]
        $nextId = [int]$Order[($position % 6)]
        $kind = [int]$kindByPosition[$position - 1]

        $s = [System.Numerics.BigInteger](
            [System.Numerics.BigInteger]$old[$bowlId] +
            2 * [System.Numerics.BigInteger]$old[$prevId] +
            3 * [System.Numerics.BigInteger]$old[$nextId] +
            [System.Numerics.BigInteger]$Pours[$position] +
            $Drop +
            [System.Numerics.BigInteger]$Stones[$I][$kind]
        )

        $nextBowls[$bowlId] = [System.Numerics.BigInteger](
            Get-Discovery04SavedValue -Value (
                $s * $s +
                5 * [System.Numerics.BigInteger]$old[$prevId] *
                    [System.Numerics.BigInteger]$old[$nextId] +
                $I * $position
            )
        )
    }

    return ,$nextBowls
}

function New-Stage20ReadyContext {
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$CalculationDay,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$TargetDay
    )

    $ctx = New-BaseMonsterContext -CalculationDay $CalculationDay -TargetDay $TargetDay
    $ctx = Invoke-Patch01SaveAdapter -Context $ctx -Value $ctx.calculationDay
    $ctx = Invoke-Patch02DayTagAdapter -Context $ctx
    $ctx = Invoke-Patch03DistanceAdapter -Context $ctx
    $ctx = Invoke-Patch04StoneAdapter -Context $ctx
    $ctx = Invoke-Discovery05LegacyHiddenAdapter -Context $ctx
    [void](Invoke-Patch05HiddenNearnessRepair -Context $ctx -K 1)

    $ctx.legacyVisibleDropTable = Get-Discovery09VisibleDropTableThroughCurrentLayers -Context $ctx
    $ctx.patch08OrderTable = Invoke-Patch08BuildOrderTable `
        -Context $ctx `
        -VisibleDrops $ctx.legacyVisibleDropTable

    [void](Invoke-Patch09BowlAliasRepair -Context $ctx -I 1)
    return $ctx
}

$foundation = Get-NormFoundationDay
$target = $foundation + 3
$metadata = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')

Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_STAGE=20\s*$') -Name 'Stage 20 ang kasalukuyang stage'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_KIND=DISCOVERY\s*$') -Name 'Discovery ang kasalukuyang uri'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_PATCH=10\s*$') -Name 'Discovery 10 ang kasalukuyang patch slot'
Assert-StageTrue -Condition ($metadata -match '(?m)^LAST_COMPLETED_STAGE=19\s*$') -Name 'Hindi pa minamarkahang kumpleto ang Stage 20 bago runtime'
Assert-StageTrue -Condition ($metadata -match '(?m)^EXPECTED_REPOSITORY_STATE=RED\s*$') -Name 'RED ang inaasahang Stage 20 repository state'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE19_RUNTIME_VERIFICATION=GREEN_CONFIRMED\s*$') -Name 'Nananatiling nakatala ang Stage 19 GREEN proof'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE20_DISCOVERY=IN_PLACE_BOWL_UPDATE_READS_UPDATED_WORKING_VALUES\s*$') -Name 'Discovery 10 metadata ay in-place bowl update contamination'

$ready = New-Stage20ReadyContext -CalculationDay $foundation -TargetDay $target
$i = 1
$bowls = $ready.legacyInitialBowls
$pours = $ready.patch09CorrectedPours
$drop = [System.Numerics.BigInteger]$ready.legacyVisibleDropTable[$i]
$order = $ready.patch08OrderTable[$i]

# Historical pour tuples are zero-filled outside the three populated pour positions.
# This is required because the six-position bowl-update loop reads positions 1..6.
$rawPourZeroProbe = legacyFixedBowlPours `
    -I $i `
    -Drop $drop `
    -Stones $ready.legacyStoneTable `
    -OldBowls $ready.legacyInitialBowls

foreach ($position in ([int[]](4,5,6))) {
    Assert-StageEqual `
        ([System.Numerics.BigInteger]0) `
        ([System.Numerics.BigInteger]$rawPourZeroProbe[$position]) `
        "Raw Discovery 09 pour position $position ay historical zero"

    Assert-StageEqual `
        ([System.Numerics.BigInteger]0) `
        ([System.Numerics.BigInteger]$pours[$position]) `
        "Corrected Patch 09 pour position $position ay historical zero"
}

# 1. Historical helper and snapshot reference.
$actual = legacyInPlaceBowlUpdateWrong `
    -I $i `
    -Drop $drop `
    -Order $order `
    -Pours $pours `
    -Stones $ready.legacyStoneTable `
    -Bowls $bowls

$expected = Get-Stage20SnapshotExpected `
    -I $i `
    -Drop $drop `
    -Order $order `
    -Pours $pours `
    -Stones $ready.legacyStoneTable `
    -Bowls $bowls

$firstBowlId = [int]$order[0]
Assert-StageEqual `
    ([System.Numerics.BigInteger]$expected[$firstBowlId]) `
    ([System.Numerics.BigInteger]$actual[$firstBowlId]) `
    'Unang position ay wala pang contamination at tumutugma sa snapshot semantics'

$laterIds = @($order[1],$order[2],$order[3],$order[4],$order[5])
$laterDivergence = $false
foreach ($bowlId in $laterIds) {
    if ([System.Numerics.BigInteger]$actual[[int]$bowlId] -ne [System.Numerics.BigInteger]$expected[[int]$bowlId]) {
        $laterDivergence = $true
    }
}
Assert-StageTrue -Condition $laterDivergence -Name 'May contamination sa hindi bababa sa isang later position'

# 2. Historical required EXPECTED_RED probes are exactly positions 2,3,6.
$expectedRedCount = 0
$matchCount = 0
$redPositions = [System.Collections.Generic.List[int]]::new()

foreach ($position in ([int[]](2,3,6))) {
    $bowlId = [int]$order[$position - 1]
    if ([System.Numerics.BigInteger]$actual[$bowlId] -eq [System.Numerics.BigInteger]$expected[$bowlId]) {
        $matchCount++
    }
    else {
        $expectedRedCount++
        $redPositions.Add($position)
        Write-Host "DISCOVERY10_POSITION=$position CLASSIFICATION=EXPECTED_RED"
    }
}

Assert-StageEqual 3 $expectedRedCount 'Eksaktong tatlong required Discovery 10 EXPECTED_RED probes'
Assert-StageEqual 0 $matchCount 'Walang required position 2,3,6 probe na MATCH'
Assert-StageEqual '2,3,6' (($redPositions | ForEach-Object { [string]$_ }) -join ',') 'Eksaktong positions 2,3,6 ang required red probes'

# 3. Adapter state is invocation-owned.
$first = New-Stage20ReadyContext -CalculationDay $foundation -TargetDay $target
$second = New-Stage20ReadyContext -CalculationDay $foundation -TargetDay $target

$result = Invoke-Discovery10LegacyBowlUpdateAdapter `
    -Context $first `
    -I 1 `
    -Bowls $first.legacyInitialBowls `
    -Pours $first.patch09CorrectedPours

Assert-StageEqual 1 $first.legacyBowlUpdateLastDropIndex 'Legacy bowl-update drop index ay 1'
Assert-StageEqual (Get-Stage20ArraySignature $first.legacyInitialBowls) (Get-Stage20ArraySignature $first.legacyBowlUpdateLastInput) 'Captured ang bowl-update input'
Assert-StageEqual (Get-Stage20ArraySignature $first.patch09CorrectedPours) (Get-Stage20ArraySignature $first.legacyBowlUpdateLastPours) 'Captured ang corrected Patch 09 pours'
Assert-StageEqual (Get-Stage20ArraySignature $result) (Get-Stage20ArraySignature $first.legacyBowlUpdateLastResult) 'Captured ang legacy in-place result'
Assert-StageEqual 'IN_PLACE_BOWL_UPDATE_CONTAMINATION_ACTIVE' $first.discovery10Status 'Aktibo ang Discovery 10 status'
Assert-StageEqual 1 $first.discovery10InvocationCount 'Eksaktong isang Discovery 10 adapter call'

Assert-StageTrue -Condition ($null -eq $second.legacyBowlUpdateLastDropIndex) -Name 'Walang bowl-update index leak'
Assert-StageTrue -Condition ($null -eq $second.legacyBowlUpdateLastInput) -Name 'Walang bowl-update input leak'
Assert-StageTrue -Condition ($null -eq $second.legacyBowlUpdateLastPours) -Name 'Walang bowl-update pours leak'
Assert-StageTrue -Condition ($null -eq $second.legacyBowlUpdateLastResult) -Name 'Walang bowl-update result leak'
Assert-StageEqual 0 $second.discovery10InvocationCount 'Walang Discovery 10 invocation-count leak'

# 4. Observability neutrality.
$plain = New-Stage20ReadyContext -CalculationDay $foundation -TargetDay $target
$noisy = New-Stage20ReadyContext -CalculationDay $foundation -TargetDay $target
$noisy.logs.Add([pscustomobject]@{ code='noisy-before'; data=20 })
$noisy.metrics['observability.only'] = [System.Numerics.BigInteger]2020
$noisy.diagnostics.Add([pscustomobject]@{ code='diagnostic'; data=20 })

$plainResult = Invoke-Discovery10LegacyBowlUpdateAdapter `
    -Context $plain -I 1 -Bowls $plain.legacyInitialBowls -Pours $plain.patch09CorrectedPours
$noisyResult = Invoke-Discovery10LegacyBowlUpdateAdapter `
    -Context $noisy -I 1 -Bowls $noisy.legacyInitialBowls -Pours $noisy.patch09CorrectedPours
Assert-StageEqual (Get-Stage20ArraySignature $plainResult) (Get-Stage20ArraySignature $noisyResult) 'Hindi binabago ng observability state ang in-place bowl update scar'

# 5. Real production path.
$ctx = Invoke-CalendarDateSpaghetti -CalculationDay $foundation -TargetDay $target

Assert-StageEqual 'SAVE_PATCH_ACTIVE' $ctx.patch01Status 'Nananatiling aktibo ang Patch 01 sa Stage 20'
Assert-StageEqual 'DAY_TAG_PATCH_ACTIVE' $ctx.patch02Status 'Nananatiling aktibo ang Patch 02 sa Stage 20'
Assert-StageEqual 'DISTANCE_PATCH_ACTIVE' $ctx.patch03Status 'Nananatiling aktibo ang Patch 03 sa Stage 20'
Assert-StageEqual 'STONE_PATCH_ACTIVE' $ctx.patch04Status 'Nananatiling aktibo ang Patch 04 sa Stage 20'
Assert-StageEqual 'HIDDEN_NEARNESS_PATCH_ACTIVE' $ctx.patch05Status 'Nananatiling aktibo ang Patch 05 sa Stage 20'
Assert-StageEqual 'PRIOR_PATCH_ACTIVE' $ctx.patch06Status 'Nananatiling aktibo ang Patch 06 sa Stage 20'
Assert-StageEqual 'SENTINEL_GRIND_PATCH_ACTIVE' $ctx.patch07Status 'Nananatiling aktibo ang Patch 07 sa Stage 20'
Assert-StageEqual 'PERMUTATION_RANK_PATCH_ACTIVE' $ctx.patch08Status 'Nananatiling aktibo ang Patch 08 sa Stage 20'
Assert-StageEqual 'BOWL_ALIAS_PATCH_ACTIVE' $ctx.patch09Status 'Nananatiling aktibo ang Patch 09 sa Stage 20'

Assert-StageEqual 'IN_PLACE_BOWL_UPDATE_CONTAMINATION_ACTIVE' $ctx.discovery10Status 'Aktibo ang Discovery 10 sa production route'
Assert-StageEqual 1 $ctx.discovery10InvocationCount 'Eksaktong isang Discovery 10 production invocation'
Assert-StageEqual 1 $ctx.legacyBowlUpdateLastDropIndex 'Production bowl update ay i=1'
Assert-StageEqual (Get-Stage20ArraySignature $ctx.patch09ProductionPours) (Get-Stage20ArraySignature $ctx.legacyBowlUpdateLastPours) 'Production bowl update gumagamit ng corrected Patch 09 pours'
Assert-StageEqual (Get-Stage20ArraySignature $ctx.legacyBowlUpdateLastResult) (Get-Stage20ArraySignature $ctx.legacyBowlUpdateProductionResult) 'Production probe result ay raw in-place bowl update'
Assert-StageTrue -Condition $ctx.metrics.ContainsKey('discovery10.bowlUpdate.probes') -Name 'May Discovery 10 production probe metric'
Assert-StageEqual ([System.Numerics.BigInteger]1) $ctx.metrics['discovery10.bowlUpdate.probes'] 'Eksaktong isang Discovery 10 production probe metric increment'

# 6. Physical scar, production purity, and no Patch 10.
$monsterText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/MonsterSkeleton.ps1')
$discovery10Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Discovery10.ps1')

$productionFiles = @(
    'src/Discovery01.ps1','src/Patch01.ps1',
    'src/Discovery02.ps1','src/Patch02.ps1',
    'src/Discovery03.ps1','src/Patch03.ps1',
    'src/Discovery04.ps1','src/Patch04.ps1',
    'src/Discovery05.ps1','src/Patch05.ps1',
    'src/Discovery06.ps1','src/Patch06.ps1',
    'src/Discovery07.ps1','src/Patch07.ps1',
    'src/Discovery08.ps1','src/Patch08.ps1',
    'src/Discovery09.ps1','src/Patch09.ps1',
    'src/Discovery10.ps1'
)
$productionText = $monsterText
foreach ($rel in $productionFiles) {
    $productionText += "`n" + (Get-Content -Raw -Encoding UTF8 (Join-Path $root $rel))
}

Assert-StageTrue -Condition ($productionText -notmatch 'Get-NormBowlOrderFromDrop|Get-NormPermutationUnrank1|Invoke-NormSauce|Get-NormCalendarDate') -Name 'Hindi tumatawag sa normative oracle ang Stage 20 production path'
Assert-StageTrue -Condition ($discovery10Text -match 'function legacyInPlaceBowlUpdateWrong') -Name 'Pisikal ang raw in-place bowl update helper'
Assert-StageTrue -Condition ($discovery10Text -match '\$working\[\$bowlId\]') -Name 'Parehong working storage ang binabasa at sinusulatan'
Assert-StageTrue -Condition ($discovery10Text -match '\$working\[\$prevId\]') -Name 'Ang previous-bowl reads ay mula sa mutable working storage'
Assert-StageTrue -Condition ($discovery10Text -match '\$working\[\$nextId\]') -Name 'Ang next-bowl reads ay mula sa mutable working storage'
Assert-StageTrue -Condition ($monsterText -match 'Invoke-Discovery10LegacyBowlUpdateAdapter') -Name 'Dumadaan ang tunay na production route sa Discovery 10 adapter'

$patch10Names = @(
    'vaultOld',
    'pendingBowlUpdates',
    'snapshotBowlUpdatePatched',
    'BowlMutationPatchWrapper',
    'commitAfterSix'
)
foreach ($name in $patch10Names) {
    Assert-StageTrue -Condition ($productionText -notmatch [regex]::Escape($name)) -Name "Wala pang Patch 10 repair code: $name"
}

$futureNames = @(
    'orderAt46Latch',
    'biasedLegacyPick',
    'LEGACY_YEAR_MAX',
    'VirtualLegacyList',
    'oldContiguousMonthDayGuess'
)
foreach ($name in $futureNames) {
    Assert-StageTrue -Condition ($productionText -notmatch [regex]::Escape($name)) -Name "Walang mas huling patch code: $name"
}

Write-Host "DISCOVERY10_EXPECTED_RED_COUNT=$expectedRedCount"
Write-Host "DISCOVERY10_MATCH_COUNT=$matchCount"
Write-Host 'DISCOVERY10_RED_POSITIONS=2,3,6'
Write-Host 'DISCOVERY10_POSITION1=SNAPSHOT_MATCH'
Write-Host 'DISCOVERY10_WORKING_STORAGE=READ_WRITE_SHARED'
Write-Host 'DISCOVERY10_PRODUCTION_I=1'
Write-Host 'DISCOVERY10_PATCH09_POURS=USED'
Write-Host 'DISCOVERY10_POURS_4_5_6=ZERO'
Write-Host 'DISCOVERY10_PATCH10_SNAPSHOT=ABSENT'
Write-Host 'STAGE20_REPOSITORY_STATE=EXPECTED_RED'

$ok = Complete-StageTestRun
if (-not $ok) { exit 1 }
Write-Host 'STAGE20_RESULT=PASS'
exit 0
