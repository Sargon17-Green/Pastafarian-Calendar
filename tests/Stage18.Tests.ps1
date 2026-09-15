Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

. (Join-Path $root 'src/SourceLanguageCatalog.ps1')
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

function Get-Stage18ArraySignature {
    param([AllowNull()]$Values)
    if ($null -eq $Values) {
        return '<NULL>'
    }
    return (($Values | ForEach-Object {
        if ($null -eq $_) { '<NULL>' } else { [string]$_ }
    }) -join ',')
}

function Get-Stage18ExpectedInitialBowls {
    param([Parameter(Mandatory)]$Counts)

    $primes = @($null,17,19,23,29,31,37)
    $bowls = [object[]]::new(7)

    for ($bowlId = 1; $bowlId -le 6; $bowlId++) {
        $prime = [System.Numerics.BigInteger]$primes[$bowlId]
        $temp = [System.Numerics.BigInteger](
            [System.Numerics.BigInteger]$Counts.action +
            [System.Numerics.BigInteger]$Counts.target * $bowlId +
            [System.Numerics.BigInteger]$Counts.distance +
            [System.Numerics.BigInteger]$Counts.connection +
            [System.Numerics.BigInteger]$Counts.direction +
            $prime * $prime
        )
        $bowls[$bowlId] = [System.Numerics.BigInteger](
            Get-Discovery04SavedValue -Value ($temp * $temp + $bowlId)
        )
    }

    return ,$bowls
}

function Get-Stage18PositionBasedPours {
    param(
        [Parameter(Mandatory)][int]$I,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$Drop,
        [AllowNull()][Parameter(Mandatory)][System.Array]$Stones,
        [AllowNull()][Parameter(Mandatory)][System.Array]$OldBowls,
        [AllowNull()][Parameter(Mandatory)][System.Array]$Order
    )

    if ($null -eq $Stones -or $null -eq $OldBowls -or $null -eq $Order) {
        throw 'Hindi maaaring null ang normative-position pour inputs.'
    }

    $row = $Stones[$I]
    $pour = [object[]]::new(7)

    $pour[1] = [System.Numerics.BigInteger](
        Get-Discovery04SavedValue -Value (
            $Drop * $Drop +
            [System.Numerics.BigInteger]$row[0] * [System.Numerics.BigInteger]$OldBowls[[int]$Order[0]] +
            3 * $I
        )
    )
    $pour[2] = [System.Numerics.BigInteger](
        Get-Discovery04SavedValue -Value (
            $Drop * $Drop +
            [System.Numerics.BigInteger]$row[1] * [System.Numerics.BigInteger]$OldBowls[[int]$Order[1]] +
            5 * $I
        )
    )
    $pour[3] = [System.Numerics.BigInteger](
        Get-Discovery04SavedValue -Value (
            $Drop * $Drop +
            [System.Numerics.BigInteger]$row[2] * [System.Numerics.BigInteger]$OldBowls[[int]$Order[2]] +
            7 * $I
        )
    )

    return ,$pour
}

$foundation = Get-NormFoundationDay
$target = $foundation + 3
$metadata = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')

Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_STAGE=18\s*$') -Name 'Stage 18 ang kasalukuyang stage'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_KIND=DISCOVERY\s*$') -Name 'Discovery ang kasalukuyang uri'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_PATCH=09\s*$') -Name 'Discovery 09 ang kasalukuyang patch slot'
Assert-StageTrue -Condition ($metadata -match '(?m)^LAST_COMPLETED_STAGE=17\s*$') -Name 'Hindi pa minamarkahang kumpleto ang Stage 18 bago runtime'
Assert-StageTrue -Condition ($metadata -match '(?m)^EXPECTED_REPOSITORY_STATE=RED\s*$') -Name 'RED ang inaasahang Stage 18 repository state'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE17_RUNTIME_VERIFICATION=GREEN_CONFIRMED\s*$') -Name 'Nananatiling nakatala ang Stage 17 GREEN proof'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE18_DISCOVERY=FIXED_BOWL_IDS_INSTEAD_OF_ORDER_POSITIONS\s*$') -Name 'Discovery 09 metadata ay fixed bowl IDs sa halip na order positions'

# 1. Build the real Stage 18 support state on the exact Foundation fixture.
$ctx = Invoke-CalendarDateSpaghetti -CalculationDay $foundation -TargetDay $target

Assert-StageEqual 46 $ctx.legacyVisibleDropCount 'Eksaktong 46 visible drops ang nasa Stage 18 production path'
Assert-StageEqual 46 $ctx.patch08OrderCount 'Eksaktong 46 corrected permutation orders ang nasa Stage 18 production path'
Assert-StageTrue -Condition ($null -ne $ctx.legacyInitialBowls) -Name 'Handa ang old initial bowls sa Stage 18 production path'

# 2. Initial bowl factory is exact and not the new scar.
$counts = Get-Discovery05CountsFromContext -Context $ctx
$expectedBowls = Get-Stage18ExpectedInitialBowls -Counts $counts
$actualBowls = Get-Discovery09InitialBowlsThroughOldFactory -Counts $counts

for ($bowlId = 1; $bowlId -le 6; $bowlId++) {
    Assert-StageEqual `
        ([System.Numerics.BigInteger]$expectedBowls[$bowlId]) `
        ([System.Numerics.BigInteger]$actualBowls[$bowlId]) `
        "Exact ang initial bowl $bowlId"
}

Assert-StageEqual ([System.Numerics.BigInteger]97345) ([System.Numerics.BigInteger]$actualBowls[1]) 'Exact fixture initial bowl 1'
Assert-StageEqual ([System.Numerics.BigInteger]152883) ([System.Numerics.BigInteger]$actualBowls[2]) 'Exact fixture initial bowl 2'
Assert-StageEqual ([System.Numerics.BigInteger]320359) ([System.Numerics.BigInteger]$actualBowls[3]) 'Exact fixture initial bowl 3'
Assert-StageEqual ([System.Numerics.BigInteger]783229) ([System.Numerics.BigInteger]$actualBowls[4]) 'Exact fixture initial bowl 4'
Assert-StageEqual ([System.Numerics.BigInteger]1024149) ([System.Numerics.BigInteger]$actualBowls[5]) 'Exact fixture initial bowl 5'
Assert-StageEqual ([System.Numerics.BigInteger]2036335) ([System.Numerics.BigInteger]$actualBowls[6]) 'Exact fixture initial bowl 6'

# 3. Exact visible-drop/order fixture needed by the historical Stage 18 scar.
Assert-StageEqual ([System.Numerics.BigInteger]93776941630358033507840162487924794010) ([System.Numerics.BigInteger]$ctx.legacyVisibleDropTable[1]) 'Exact Stage 18 visible drop 1'
Assert-StageEqual ([System.Numerics.BigInteger]151192890723378273255292874752459584099) ([System.Numerics.BigInteger]$ctx.legacyVisibleDropTable[2]) 'Exact Stage 18 visible drop 2'
Assert-StageEqual ([System.Numerics.BigInteger]157805722599731929902218376078867041321) ([System.Numerics.BigInteger]$ctx.legacyVisibleDropTable[3]) 'Exact Stage 18 visible drop 3'
Assert-StageEqual ([System.Numerics.BigInteger]96827098275814291613568419252693974562) ([System.Numerics.BigInteger]$ctx.legacyVisibleDropTable[46]) 'Exact Stage 18 visible drop 46'

Assert-StageEqual '5,4,3,6,2,1' (Get-Stage18ArraySignature $ctx.patch08OrderTable[1]) 'Exact order sa drop index 1'
Assert-StageEqual '1,6,2,4,3,5' (Get-Stage18ArraySignature $ctx.patch08OrderTable[2]) 'Exact order sa drop index 2'
Assert-StageEqual '1,3,5,6,2,4' (Get-Stage18ArraySignature $ctx.patch08OrderTable[3]) 'Exact order sa drop index 3'
Assert-StageEqual '1,2,3,4,6,5' (Get-Stage18ArraySignature $ctx.patch08OrderTable[46]) 'Exact order sa drop index 46'

# 4. Raw helper really reads fixed bowls 1,2,3.
$probeFixed = legacyFixedBowlPours `
    -I 1 `
    -Drop ([System.Numerics.BigInteger]$ctx.legacyVisibleDropTable[1]) `
    -Stones $ctx.legacyStoneTable `
    -OldBowls $ctx.legacyInitialBowls

$drop1 = [System.Numerics.BigInteger]$ctx.legacyVisibleDropTable[1]
$row1 = $ctx.legacyStoneTable[1]

$expectedFixed1 = [System.Numerics.BigInteger](
    Get-Discovery04SavedValue -Value (
        $drop1 * $drop1 +
        [System.Numerics.BigInteger]$row1[0] * [System.Numerics.BigInteger]$ctx.legacyInitialBowls[1] +
        3
    )
)
$expectedFixed2 = [System.Numerics.BigInteger](
    Get-Discovery04SavedValue -Value (
        $drop1 * $drop1 +
        [System.Numerics.BigInteger]$row1[1] * [System.Numerics.BigInteger]$ctx.legacyInitialBowls[2] +
        5
    )
)
$expectedFixed3 = [System.Numerics.BigInteger](
    Get-Discovery04SavedValue -Value (
        $drop1 * $drop1 +
        [System.Numerics.BigInteger]$row1[2] * [System.Numerics.BigInteger]$ctx.legacyInitialBowls[3] +
        7
    )
)

Assert-StageEqual $expectedFixed1 ([System.Numerics.BigInteger]$probeFixed[1]) 'Legacy pour position 1 ay talagang fixed bowl ID 1'
Assert-StageEqual $expectedFixed2 ([System.Numerics.BigInteger]$probeFixed[2]) 'Legacy pour position 2 ay talagang fixed bowl ID 2'
Assert-StageEqual $expectedFixed3 ([System.Numerics.BigInteger]$probeFixed[3]) 'Legacy pour position 3 ay talagang fixed bowl ID 3'

# 5. Historical normative regression: i=1,2,3 are all EXPECTED_RED.
$expectedRedCount = 0
$matchCount = 0
$redIndices = [System.Collections.Generic.List[int]]::new()

foreach ($i in ([int[]](1,2,3))) {
    $actual = legacyFixedBowlPours `
        -I $i `
        -Drop ([System.Numerics.BigInteger]$ctx.legacyVisibleDropTable[$i]) `
        -Stones $ctx.legacyStoneTable `
        -OldBowls $ctx.legacyInitialBowls

    $expected = Get-Stage18PositionBasedPours `
        -I $i `
        -Drop ([System.Numerics.BigInteger]$ctx.legacyVisibleDropTable[$i]) `
        -Stones $ctx.legacyStoneTable `
        -OldBowls $ctx.legacyInitialBowls `
        -Order $ctx.patch08OrderTable[$i]

    if ((Get-Stage18ArraySignature $actual) -eq (Get-Stage18ArraySignature $expected)) {
        $matchCount++
    }
    else {
        $expectedRedCount++
        $redIndices.Add($i)
        Write-Host "DISCOVERY09_I=$i CLASSIFICATION=EXPECTED_RED"
    }
}

Assert-StageEqual 3 $expectedRedCount 'Eksaktong tatlong Discovery 09 EXPECTED_RED pour probes'
Assert-StageEqual 0 $matchCount 'Walang i=1,2,3 pour probe na MATCH bago Patch 09'
Assert-StageEqual '1,2,3' (($redIndices | ForEach-Object { [string]$_ }) -join ',') 'Eksaktong i=1,2,3 ang red indices'

# 6. i=46 is the intentional coincidence: first three positions are 1,2,3.
$actual46 = legacyFixedBowlPours `
    -I 46 `
    -Drop ([System.Numerics.BigInteger]$ctx.legacyVisibleDropTable[46]) `
    -Stones $ctx.legacyStoneTable `
    -OldBowls $ctx.legacyInitialBowls
$expected46 = Get-Stage18PositionBasedPours `
    -I 46 `
    -Drop ([System.Numerics.BigInteger]$ctx.legacyVisibleDropTable[46]) `
    -Stones $ctx.legacyStoneTable `
    -OldBowls $ctx.legacyInitialBowls `
    -Order $ctx.patch08OrderTable[46]
Assert-StageEqual (Get-Stage18ArraySignature $expected46) (Get-Stage18ArraySignature $actual46) 'i=46 ay incidental MATCH dahil order positions 1,2,3 ay bowl IDs 1,2,3'

# 7. Production path really invokes fixed-bowl pours at i=1.
Assert-StageEqual 'FIXED_BOWL_ID_POURS_ACTIVE' $ctx.discovery09Status 'Aktibo ang Discovery 09 sa production route'
Assert-StageEqual 1 $ctx.discovery09InvocationCount 'Eksaktong isang Discovery 09 production pour probe'
Assert-StageEqual 1 $ctx.legacyPourLastDropIndex 'Production fixed-bowl pour probe ay i=1'
Assert-StageEqual ([System.Numerics.BigInteger]$ctx.legacyVisibleDropTable[1]) ([System.Numerics.BigInteger]$ctx.legacyPourLastDropValue) 'Production pour gumagamit ng tunay na visible drop 1'
Assert-StageEqual '5,4,3,6,2,1' (Get-Stage18ArraySignature $ctx.legacyPourLastOrder) 'Production pour captures the corrected order but ignores it in fixed-bowl reads'
Assert-StageEqual (Get-Stage18ArraySignature $ctx.legacyPourLastValues) (Get-Stage18ArraySignature $ctx.legacyPourProbeValues) 'Production probe value ay raw fixed-bowl pour tuple'
Assert-StageTrue -Condition $ctx.metrics.ContainsKey('discovery09.pour.probes') -Name 'May Discovery 09 production probe metric'
Assert-StageEqual ([System.Numerics.BigInteger]1) $ctx.metrics['discovery09.pour.probes'] 'Eksaktong isang Discovery 09 production probe metric increment'

# Prior patch layers remain active.
Assert-StageEqual 'SAVE_PATCH_ACTIVE' $ctx.patch01Status 'Nananatiling aktibo ang Patch 01 sa Stage 18'
Assert-StageEqual 'DAY_TAG_PATCH_ACTIVE' $ctx.patch02Status 'Nananatiling aktibo ang Patch 02 sa Stage 18'
Assert-StageEqual 'DISTANCE_PATCH_ACTIVE' $ctx.patch03Status 'Nananatiling aktibo ang Patch 03 sa Stage 18'
Assert-StageEqual 'STONE_PATCH_ACTIVE' $ctx.patch04Status 'Nananatiling aktibo ang Patch 04 sa Stage 18'
Assert-StageEqual 'HIDDEN_NEARNESS_PATCH_ACTIVE' $ctx.patch05Status 'Nananatiling aktibo ang Patch 05 sa Stage 18'
Assert-StageEqual 'PRIOR_PATCH_ACTIVE' $ctx.patch06Status 'Nananatiling aktibo ang Patch 06 sa Stage 18'
Assert-StageEqual 'SENTINEL_GRIND_PATCH_ACTIVE' $ctx.patch07Status 'Nananatiling aktibo ang Patch 07 sa Stage 18'
Assert-StageEqual 'PERMUTATION_RANK_PATCH_ACTIVE' $ctx.patch08Status 'Nananatiling aktibo ang Patch 08 sa Stage 18'

# 8. Invocation ownership.
$clean = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
Assert-StageTrue -Condition ($null -eq $clean.legacyVisibleDropTable) -Name 'Walang visible-drop-table leak'
Assert-StageEqual 0 $clean.legacyVisibleDropCount 'Walang visible-drop-count leak'
Assert-StageTrue -Condition ($null -eq $clean.legacyInitialBowls) -Name 'Walang initial-bowl leak'
Assert-StageTrue -Condition ($null -eq $clean.legacyPourLastDropIndex) -Name 'Walang pour-index leak'
Assert-StageTrue -Condition ($null -eq $clean.legacyPourLastDropValue) -Name 'Walang pour-drop leak'
Assert-StageTrue -Condition ($null -eq $clean.legacyPourLastOrder) -Name 'Walang pour-order leak'
Assert-StageTrue -Condition ($null -eq $clean.legacyPourLastValues) -Name 'Walang pour-values leak'
Assert-StageEqual 0 $clean.discovery09InvocationCount 'Walang Discovery 09 invocation-count leak'

# 9. Observability neutrality of the pure historical helper.
$plain = legacyFixedBowlPours `
    -I 2 `
    -Drop ([System.Numerics.BigInteger]$ctx.legacyVisibleDropTable[2]) `
    -Stones $ctx.legacyStoneTable `
    -OldBowls $ctx.legacyInitialBowls
$ctx.logs.Add([pscustomobject]@{ code='noisy-before'; data=18 })
$ctx.metrics['observability.only'] = [System.Numerics.BigInteger]1818
$ctx.diagnostics.Add([pscustomobject]@{ code='diagnostic'; data=18 })
$noisy = legacyFixedBowlPours `
    -I 2 `
    -Drop ([System.Numerics.BigInteger]$ctx.legacyVisibleDropTable[2]) `
    -Stones $ctx.legacyStoneTable `
    -OldBowls $ctx.legacyInitialBowls
Assert-StageEqual (Get-Stage18ArraySignature $plain) (Get-Stage18ArraySignature $noisy) 'Hindi binabago ng observability state ang fixed-bowl pour result'

# 10. Production purity and no Patch 09 / Patch 10.
$monsterText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/MonsterSkeleton.ps1')
$discovery09Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Discovery09.ps1')

$productionFiles = @(
    'src/Discovery01.ps1',
    'src/Patch01.ps1',
    'src/Discovery02.ps1',
    'src/Patch02.ps1',
    'src/Discovery03.ps1',
    'src/Patch03.ps1',
    'src/Discovery04.ps1',
    'src/Patch04.ps1',
    'src/Discovery05.ps1',
    'src/Patch05.ps1',
    'src/Discovery06.ps1',
    'src/Patch06.ps1',
    'src/Discovery07.ps1',
    'src/Patch07.ps1',
    'src/Discovery08.ps1',
    'src/Patch08.ps1',
    'src/Discovery09.ps1'
)
$productionText = $monsterText
foreach ($rel in $productionFiles) {
    $productionText += "`n" + (Get-Content -Raw -Encoding UTF8 (Join-Path $root $rel))
}

Assert-StageTrue -Condition ($productionText -notmatch 'Get-NormBowlOrderFromDrop|Get-NormPermutationUnrank1|Invoke-NormSauce|Get-NormCalendarDate') -Name 'Hindi tumatawag sa normative oracle ang Stage 18 production path'
Assert-StageTrue -Condition ($discovery09Text -match 'function Get-Discovery09InitialBowlsThroughOldFactory') -Name 'Pisikal ang exact old initial-bowl factory'
Assert-StageTrue -Condition ($discovery09Text -match 'function legacyFixedBowlPours') -Name 'Pisikal ang raw fixed-bowl pour helper'
Assert-StageTrue -Condition ($discovery09Text -match '\$OldBowls\[1\]') -Name 'Pisikal ang fixed bowl ID 1 read'
Assert-StageTrue -Condition ($discovery09Text -match '\$OldBowls\[2\]') -Name 'Pisikal ang fixed bowl ID 2 read'
Assert-StageTrue -Condition ($discovery09Text -match '\$OldBowls\[3\]') -Name 'Pisikal ang fixed bowl ID 3 read'
Assert-StageTrue -Condition ($monsterText -match 'Invoke-Discovery09LegacyPourAdapter') -Name 'Dumadaan ang tunay na production route sa Discovery 09 pour adapter'

$patch09Names = @(
    'installOrderAliases',
    'bowlByLegacyPosition',
    'aliasedPositionPours',
    'BowlAliasPatchWrapper',
    'bowlAlias',
    'patchedPours'
)
foreach ($name in $patch09Names) {
    Assert-StageTrue -Condition ($productionText -notmatch [regex]::Escape($name)) -Name "Wala pang Patch 09 code: $name"
}

$patch10Names = @(
    'vaultOld',
    'pendingBowlUpdates',
    'inPlaceBowlUpdatePatch'
)
foreach ($name in $patch10Names) {
    Assert-StageTrue -Condition ($productionText -notmatch [regex]::Escape($name)) -Name "Wala pang Patch 10 code: $name"
}

Write-Host "DISCOVERY09_EXPECTED_RED_COUNT=$expectedRedCount"
Write-Host "DISCOVERY09_MATCH_COUNT=$matchCount"
Write-Host 'DISCOVERY09_RED_DROP_INDICES=1,2,3'
Write-Host 'DISCOVERY09_I46=COINCIDENTAL_MATCH'
Write-Host 'DISCOVERY09_INITIAL_BOWLS=EXACT'
Write-Host 'DISCOVERY09_FIXED_BOWL_IDS=1,2,3'
Write-Host 'DISCOVERY09_PRODUCTION_PROBE_I=1'
Write-Host 'DISCOVERY09_DROP1_ORDINAL=570'
Write-Host 'DISCOVERY09_DROP2_ORDINAL=99'
Write-Host 'DISCOVERY09_DROP3_ORDINAL=41'
Write-Host 'DISCOVERY09_DROP46_ORDINAL=2'
Write-Host 'DISCOVERY09_PATCH09_ALIAS=ABSENT'
Write-Host 'STAGE18_REPOSITORY_STATE=EXPECTED_RED'

$ok = Complete-StageTestRun
if (-not $ok) { exit 1 }
Write-Host 'STAGE18_RESULT=PASS'
exit 0
