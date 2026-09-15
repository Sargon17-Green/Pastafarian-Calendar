Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

. (Join-Path $root 'src/SourceLanguageCatalog.ps1')
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

function Get-Stage22ArraySignature {
    param([AllowNull()]$Values)
    if ($null -eq $Values) { return '<NULL>' }
    return (($Values | ForEach-Object {
        if ($null -eq $_) { '<NULL>' } else { [string]$_ }
    }) -join ',')
}

function New-Stage22ReadyContext {
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

    $counts = Get-Discovery05CountsFromContext -Context $ctx
    $ctx.legacyInitialBowls = Get-Discovery09InitialBowlsThroughOldFactory -Counts $counts
    return $ctx
}

function Get-Stage22ExpectedPours {
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][int]$I,
        [AllowNull()][Parameter(Mandatory)][System.Array]$Bowls
    )

    $drop = [System.Numerics.BigInteger]$Context.legacyVisibleDropTable[$I]
    $order = $Context.patch08OrderTable[$I]
    $stone = $Context.legacyStoneTable[$I]
    $pours = [System.Numerics.BigInteger[]]::new(7)

    $pours[1] = [System.Numerics.BigInteger](
        Get-Discovery04SavedValue -Value (
            $drop * $drop +
            [System.Numerics.BigInteger]$stone[0] *
                [System.Numerics.BigInteger]$Bowls[[int]$order[0]] +
            3 * $I
        )
    )
    $pours[2] = [System.Numerics.BigInteger](
        Get-Discovery04SavedValue -Value (
            $drop * $drop +
            [System.Numerics.BigInteger]$stone[1] *
                [System.Numerics.BigInteger]$Bowls[[int]$order[1]] +
            5 * $I
        )
    )
    $pours[3] = [System.Numerics.BigInteger](
        Get-Discovery04SavedValue -Value (
            $drop * $drop +
            [System.Numerics.BigInteger]$stone[2] *
                [System.Numerics.BigInteger]$Bowls[[int]$order[2]] +
            7 * $I
        )
    )
    return ,$pours
}

function Get-Stage22ExpectedDropRound {
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][int]$I,
        [AllowNull()][Parameter(Mandatory)][System.Array]$Bowls
    )

    $drop = [System.Numerics.BigInteger]$Context.legacyVisibleDropTable[$I]
    $order = $Context.patch08OrderTable[$I]
    $stone = $Context.legacyStoneTable[$I]
    $pours = Get-Stage22ExpectedPours -Context $Context -I $I -Bowls $Bowls

    $old = [System.Numerics.BigInteger[]]::new(7)
    $pending = [System.Numerics.BigInteger[]]::new(7)
    $kindByPosition = [int[]](0,1,2,3,4,0)

    for ($b = 1; $b -le 6; $b++) {
        $old[$b] = [System.Numerics.BigInteger]$Bowls[$b]
    }

    for ($position = 1; $position -le 6; $position++) {
        $bowlId = [int]$order[$position - 1]
        $prevId = [int]$order[(($position - 2 + 6) % 6)]
        $nextId = [int]$order[($position % 6)]
        $kind = [int]$kindByPosition[$position - 1]

        $s = [System.Numerics.BigInteger](
            [System.Numerics.BigInteger]$old[$bowlId] +
            2 * [System.Numerics.BigInteger]$old[$prevId] +
            3 * [System.Numerics.BigInteger]$old[$nextId] +
            [System.Numerics.BigInteger]$pours[$position] +
            $drop +
            [System.Numerics.BigInteger]$stone[$kind]
        )

        $pending[$bowlId] = [System.Numerics.BigInteger](
            Get-Discovery04SavedValue -Value (
                $s * $s +
                5 * [System.Numerics.BigInteger]$old[$prevId] *
                    [System.Numerics.BigInteger]$old[$nextId] +
                $I * $position
            )
        )
    }

    return ,$pending
}

function Get-Stage22ExpectedPostStir {
    param(
        [Parameter(Mandatory)][int]$Stir,
        [AllowNull()][Parameter(Mandatory)][System.Array]$Bowls
    )

    $old = [System.Numerics.BigInteger[]]::new(7)
    $sum = [System.Numerics.BigInteger]::Zero
    for ($b = 1; $b -le 6; $b++) {
        $old[$b] = [System.Numerics.BigInteger]$Bowls[$b]
        $sum += [System.Numerics.BigInteger]$old[$b]
    }

    $saved = [System.Numerics.BigInteger](
        Get-Discovery04SavedValue -Value (
            $sum + 149 * $Stir
        )
    )
    $order = patchedOrderFromDrop -DropValue $saved
    $pending = [System.Numerics.BigInteger[]]::new(7)

    for ($position = 1; $position -le 6; $position++) {
        $bowlId = [int]$order[$position - 1]
        $prevId = [int]$order[(($position - 2 + 6) % 6)]
        $nextId = [int]$order[($position % 6)]

        $s = [System.Numerics.BigInteger](
            [System.Numerics.BigInteger]$old[$bowlId] +
            3 * [System.Numerics.BigInteger]$old[$prevId] +
            5 * [System.Numerics.BigInteger]$old[$nextId] +
            $saved +
            $Stir +
            $position * $position
        )

        $pending[$bowlId] = [System.Numerics.BigInteger](
            Get-Discovery04SavedValue -Value (
                $s * $s +
                7 * [System.Numerics.BigInteger]$old[$prevId] *
                    [System.Numerics.BigInteger]$old[$nextId]
            )
        )
    }

    return [pscustomobject]@{
        Bowls = $pending
        Order = $order
        Saved = $saved
    }
}

$foundation = Get-NormFoundationDay
$target = $foundation + 3
$metadata = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')

Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_STAGE=22\s*$') -Name 'Stage 22 ang kasalukuyang stage'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_KIND=DISCOVERY\s*$') -Name 'Discovery ang kasalukuyang uri'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_PATCH=11\s*$') -Name 'Discovery 11 ang kasalukuyang patch slot'
Assert-StageTrue -Condition ($metadata -match '(?m)^LAST_COMPLETED_STAGE=21\s*$') -Name 'Hindi pa minamarkahang kumpleto ang Stage 22 bago runtime'
Assert-StageTrue -Condition ($metadata -match '(?m)^EXPECTED_REPOSITORY_STATE=RED\s*$') -Name 'EXPECTED_RED ang Stage 22 repository state'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE21_RUNTIME_VERIFICATION=GREEN_CONFIRMED\s*$') -Name 'Nananatiling nakatala ang Stage 21 GREEN proof'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE22_DISCOVERY=DROP46_ORDER_OVERWRITTEN_BY_POST_STIR_ORDER_MEMORY\s*$') -Name 'Discovery 11 metadata ay overwritable drop-46 order memory'

$ctx = New-Stage22ReadyContext -CalculationDay $foundation -TargetDay $target
$initialSignature = Get-Stage22ArraySignature $ctx.legacyInitialBowls

# Independent expected full 46-drop pass.
$expectedBowls = [System.Numerics.BigInteger[]]::new(7)
for ($b = 1; $b -le 6; $b++) {
    $expectedBowls[$b] = [System.Numerics.BigInteger]$ctx.legacyInitialBowls[$b]
}
for ($i = 1; $i -le 46; $i++) {
    $expectedBowls = Get-Stage22ExpectedDropRound -Context $ctx -I $i -Bowls $expectedBowls
}
$expectedAfter46 = $expectedBowls

# Independent expected 12 post-stirs.
$expectedLastStirOrder = $null
for ($stir = 1; $stir -le 12; $stir++) {
    $round = Get-Stage22ExpectedPostStir -Stir $stir -Bowls $expectedBowls
    $expectedBowls = $round.Bowls
    $expectedLastStirOrder = $round.Order
}
$expectedFinal = $expectedBowls

$actualFinal = Invoke-Discovery11OverwritableOrderMemory -Context $ctx

Assert-StageEqual $initialSignature (Get-Stage22ArraySignature $ctx.legacyInitialBowls) 'Hindi binago ang initial bowls ng full Discovery 11 pass'
Assert-StageEqual (Get-Stage22ArraySignature $expectedAfter46) (Get-Stage22ArraySignature $ctx.legacyBowlsAfter46Drops) 'Exact ang 46-drop bowl pass'
Assert-StageEqual (Get-Stage22ArraySignature $expectedFinal) (Get-Stage22ArraySignature $actualFinal) 'Exact ang final bowls matapos ang 12 post-stirs'
Assert-StageEqual (Get-Stage22ArraySignature $expectedFinal) (Get-Stage22ArraySignature $ctx.legacyPostStirFinalBowls) 'Captured ang exact post-stir final bowls'

Assert-StageEqual 46 $ctx.patch09InvocationCount 'Eksaktong 46 Patch 09 current-bowl pour rounds'
Assert-StageEqual 46 $ctx.patch10InvocationCount 'Eksaktong 46 Patch 10 snapshot bowl rounds'
Assert-StageEqual 46 $ctx.discovery10InvocationCount 'Eksaktong 46 preserved raw Discovery 10 scar calls'
Assert-StageEqual 58 $ctx.legacyOrderMemoryWriteCount 'Eksaktong 58 writes sa iisang legacy order memory'
Assert-StageEqual 'stir' $ctx.legacyOrderMemoryLastSource.kind 'Post-stir ang huling legacy order-memory source'
Assert-StageEqual 12 $ctx.legacyOrderMemoryLastSource.index 'Stir 12 ang huling legacy order-memory source'
Assert-StageEqual (Get-Stage22ArraySignature $expectedLastStirOrder) (Get-Stage22ArraySignature $ctx.legacyOverwritableOrderMemory) 'Ang general order memory ay huling stir order'
Assert-StageTrue -Condition ((Get-Stage22ArraySignature $ctx.patch08OrderTable[46]) -ne (Get-Stage22ArraySignature $ctx.legacyOverwritableOrderMemory)) -Name 'Nabura ng post-stirs ang drop 46 order sa general memory'

$queried = Get-Discovery11LegacyQueriedOrder -Context $ctx
Assert-StageEqual (Get-Stage22ArraySignature $ctx.legacyOverwritableOrderMemory) (Get-Stage22ArraySignature $queried) 'Legacy query ay nagbabasa pa rin ng huling overwritten memory'

$expectedDrop46 = $ctx.patch08OrderTable[46]
$required = [int[]](1,2,6)
$red = [System.Collections.Generic.List[int]]::new()
$matchCount = 0
foreach ($position in $required) {
    $actualValue = [int]$queried[$position - 1]
    $expectedValue = [int]$expectedDrop46[$position - 1]
    if ($actualValue -eq $expectedValue) {
        $matchCount++
        Write-Host "DISCOVERY11_POSITION=$position CLASSIFICATION=MATCH"
    }
    else {
        $red.Add($position)
        Write-Host "DISCOVERY11_POSITION=$position CLASSIFICATION=EXPECTED_RED"
    }
}

Assert-StageEqual 3 $red.Count 'Eksaktong tatlong required Discovery 11 EXPECTED_RED probes'
Assert-StageEqual 0 $matchCount 'Walang required position 1,2,6 probe na MATCH'
Assert-StageEqual '1,2,6' (($red.ToArray() | ForEach-Object { [string]$_ }) -join ',') 'Eksaktong positions 1,2,6 ang required red probes'

# Invocation ownership.
$clean = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
Assert-StageTrue -Condition ($null -eq $clean.legacyOverwritableOrderMemory) -Name 'Walang legacy order-memory leak'
Assert-StageEqual 0 $clean.legacyOrderMemoryWriteCount 'Walang order-memory write-count leak'
Assert-StageTrue -Condition ($null -eq $clean.legacyOrderMemoryLastSource) -Name 'Walang order-memory source leak'
Assert-StageTrue -Condition ($null -eq $clean.legacyBowlsAfter46Drops) -Name 'Walang after-46 bowl leak'
Assert-StageTrue -Condition ($null -eq $clean.legacyPostStirFinalBowls) -Name 'Walang post-stir final-bowl leak'
Assert-StageEqual 0 $clean.discovery11InvocationCount 'Walang Discovery 11 invocation-count leak'

# Observability neutrality.
$plain = New-Stage22ReadyContext -CalculationDay $foundation -TargetDay $target
$noisy = New-Stage22ReadyContext -CalculationDay $foundation -TargetDay $target
$noisy.logs.Add([pscustomobject]@{ code='noisy-before'; data=22 })
$noisy.metrics['observability.only'] = [System.Numerics.BigInteger]2200
$noisy.diagnostics.Add([pscustomobject]@{ code='diagnostic'; data=22 })

$plainFinal = Invoke-Discovery11OverwritableOrderMemory -Context $plain
$noisyFinal = Invoke-Discovery11OverwritableOrderMemory -Context $noisy
Assert-StageEqual (Get-Stage22ArraySignature $plainFinal) (Get-Stage22ArraySignature $noisyFinal) 'Hindi binabago ng observability state ang full bowl pass'
Assert-StageEqual (Get-Stage22ArraySignature (Get-Discovery11LegacyQueriedOrder -Context $plain)) (Get-Stage22ArraySignature (Get-Discovery11LegacyQueriedOrder -Context $noisy)) 'Hindi binabago ng observability state ang overwritten query order'

# Real production route.
$prod = Invoke-CalendarDateSpaghetti -CalculationDay $foundation -TargetDay $target
Assert-StageEqual 'DISCOVERY11_COMPLETE' $prod.status 'Aktibo ang Discovery 11 sa production route'
Assert-StageEqual 'OVERWRITABLE_ORDER_MEMORY_ACTIVE' $prod.discovery11Status 'Aktibo ang overwritable order-memory scar'
Assert-StageEqual 1 $prod.discovery11InvocationCount 'Eksaktong isang full Discovery 11 production pass'
Assert-StageEqual 58 $prod.legacyOrderMemoryWriteCount 'Production order memory ay may 58 writes'
Assert-StageEqual 'stir' $prod.legacyOrderMemoryLastSource.kind 'Production last source ay post-stir'
Assert-StageEqual 12 $prod.legacyOrderMemoryLastSource.index 'Production last source ay stir 12'
Assert-StageEqual (Get-Stage22ArraySignature $prod.legacyOverwritableOrderMemory) (Get-Stage22ArraySignature $prod.legacyQueriedOrder) 'Production query reads overwritten memory'
Assert-StageTrue -Condition ((Get-Stage22ArraySignature $prod.legacyQueriedOrder) -ne (Get-Stage22ArraySignature $prod.patch08OrderTable[46])) -Name 'Production query ay hindi drop-46 order'

# Previous patch states remain active after the full pass.
Assert-StageEqual 'SAVE_PATCH_ACTIVE' $prod.patch01Status 'Nananatiling aktibo ang Patch 01 sa Stage 22'
Assert-StageEqual 'DAY_TAG_PATCH_ACTIVE' $prod.patch02Status 'Nananatiling aktibo ang Patch 02 sa Stage 22'
Assert-StageEqual 'DISTANCE_PATCH_ACTIVE' $prod.patch03Status 'Nananatiling aktibo ang Patch 03 sa Stage 22'
Assert-StageEqual 'STONE_PATCH_ACTIVE' $prod.patch04Status 'Nananatiling aktibo ang Patch 04 sa Stage 22'
Assert-StageEqual 'HIDDEN_NEARNESS_PATCH_ACTIVE' $prod.patch05Status 'Nananatiling aktibo ang Patch 05 sa Stage 22'
Assert-StageEqual 'PRIOR_PATCH_ACTIVE' $prod.patch06Status 'Nananatiling aktibo ang Patch 06 sa Stage 22'
Assert-StageEqual 'SENTINEL_GRIND_PATCH_ACTIVE' $prod.patch07Status 'Nananatiling aktibo ang Patch 07 sa Stage 22'
Assert-StageEqual 'PERMUTATION_RANK_PATCH_ACTIVE' $prod.patch08Status 'Nananatiling aktibo ang Patch 08 sa Stage 22'
Assert-StageEqual 'BOWL_ALIAS_PATCH_ACTIVE' $prod.patch09Status 'Nananatiling aktibo ang Patch 09 sa Stage 22'
Assert-StageEqual 'SNAPSHOT_BOWL_UPDATE_PATCH_ACTIVE' $prod.patch10Status 'Nananatiling aktibo ang Patch 10 sa Stage 22'

# Physical source contract: no latch and no Patch 12.
$monsterText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/MonsterSkeleton.ps1')
$d11Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Discovery11.ps1')
$p09Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Patch09.ps1')
$productionText = $monsterText + "`n" + $d11Text + "`n" + $p09Text

Assert-StageTrue -Condition ($p09Text -match 'function Invoke-Patch09BowlAliasRepairWithBowls') -Name 'Pisikal ang Patch 09 current-bowl call-with-bowls path'
Assert-StageTrue -Condition ($d11Text -match 'function postStirRoundExact') -Name 'Pisikal ang exact post-stir helper'
Assert-StageTrue -Condition ($d11Text -match 'function Invoke-Discovery11OverwritableOrderMemory') -Name 'Pisikal ang overwritable order-memory adapter'
Assert-StageTrue -Condition ($d11Text -match 'legacyOverwritableOrderMemory') -Name 'Iisang general order memory ang ginagamit'
Assert-StageTrue -Condition ($productionText -notmatch 'orderAt46Latch') -Name 'Wala pang hiwalay na orderAt46 latch'
Assert-StageTrue -Condition (-not ($prod.PSObject.Properties.Name -contains 'orderAt46Latch')) -Name 'Wala pang orderAt46 latch state field'
Assert-StageTrue -Condition ($productionText -notmatch 'queriedNextBowl|Patch12|PATCH12') -Name 'Wala pang Patch 12 next-bowl logic'
Assert-StageTrue -Condition ($productionText -notmatch 'Get-NormBowlOrderFromDrop|Get-NormPermutationUnrank1|Invoke-NormSauce|Get-NormCalendarDate') -Name 'Hindi tumatawag sa normative oracle ang Stage 22 production path'

Write-Host 'DISCOVERY11_DROP_ROUNDS=46'
Write-Host 'DISCOVERY11_POST_STIRS=12'
Write-Host 'DISCOVERY11_ORDER_MEMORY_WRITES=58'
Write-Host 'DISCOVERY11_LAST_SOURCE=STIR_12'
Write-Host 'DISCOVERY11_QUERY_SOURCE=OVERWRITABLE_MEMORY'
Write-Host 'DISCOVERY11_EXPECTED_RED_COUNT=3'
Write-Host "DISCOVERY11_MATCH_COUNT=$matchCount"
Write-Host "DISCOVERY11_RED_POSITIONS=$((($red.ToArray() | ForEach-Object { [string]$_ }) -join ','))"
Write-Host 'DISCOVERY11_ORDER_AT_46_LATCH=ABSENT'
Write-Host 'DISCOVERY11_PATCH12=ABSENT'
Write-Host 'STAGE22_REPOSITORY_STATE=EXPECTED_RED'

$ok = Complete-StageTestRun
if (-not $ok) { exit 1 }
Write-Host 'STAGE22_RESULT=PASS'
exit 0
