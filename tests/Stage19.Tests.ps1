Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

. (Join-Path $root 'src/SourceLanguageCatalog.ps1')
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

function Get-Stage19ArraySignature {
    param([AllowNull()]$Values)
    if ($null -eq $Values) {
        return '<NULL>'
    }
    return (($Values | ForEach-Object {
        if ($null -eq $_) { '<NULL>' } else { [string]$_ }
    }) -join ',')
}

function Get-Stage19ExpectedPours {
    param(
        [Parameter(Mandatory)][int]$I,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$Drop,
        [AllowNull()][Parameter(Mandatory)][System.Array]$Stones,
        [AllowNull()][Parameter(Mandatory)][System.Array]$OldBowls,
        [AllowNull()][Parameter(Mandatory)][System.Array]$Order
    )

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

function New-Stage19ReadyContext {
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

    return $ctx
}

$foundation = Get-NormFoundationDay
$target = $foundation + 3
$metadata = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')

Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_STAGE=19\s*$') -Name 'Stage 19 ang kasalukuyang stage'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_KIND=PATCH\s*$') -Name 'Patch ang kasalukuyang uri'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_PATCH=09\s*$') -Name 'Patch 09 ang kasalukuyang patch slot'
Assert-StageTrue -Condition ($metadata -match '(?m)^LAST_COMPLETED_STAGE=18\s*$') -Name 'Hindi pa minamarkahang kumpleto ang Stage 19 bago runtime'
Assert-StageTrue -Condition ($metadata -match '(?m)^EXPECTED_REPOSITORY_STATE=GREEN\s*$') -Name 'GREEN ang inaasahang Stage 19 repository state'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE18_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED\s*$') -Name 'Nananatiling nakatala ang Stage 18 expected-red proof'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE19_PATCH=BOWL_ALIAS_POSITION_REPAIR\s*$') -Name 'Patch 09 metadata ay bowl-alias position repair'

# 1. Exact alias table.
$orderSample = [int[]](5,4,3,6,2,1)
$aliasSample = installOrderAliases -Order $orderSample
Assert-StageEqual '0,5,4,3,6,2,1' (Get-Stage19ArraySignature $aliasSample) 'Exact ang bowl alias mapping para sa sample order'

# 2. Every legacy position maps to the current order bowl ID.
$sampleBowls = [object[]]::new(7)
for ($b = 1; $b -le 6; $b++) {
    $sampleBowls[$b] = [System.Numerics.BigInteger](1000 + $b)
}
for ($position = 1; $position -le 6; $position++) {
    $expectedBowlId = [int]$orderSample[$position - 1]
    Assert-StageEqual `
        ([System.Numerics.BigInteger]$sampleBowls[$expectedBowlId]) `
        (bowlByLegacyPosition -OldBowls $sampleBowls -BowlAlias $aliasSample -Position $position) `
        "Tamang aliased bowl read sa position $position"
}

# 3. All corrected pour reads go through the alias helper and match position semantics.
$ready = New-Stage19ReadyContext -CalculationDay $foundation -TargetDay $target
$counts = Get-Discovery05CountsFromContext -Context $ready
$ready.legacyInitialBowls = Get-Discovery09InitialBowlsThroughOldFactory -Counts $counts

$i = 1
$drop = [System.Numerics.BigInteger]$ready.legacyVisibleDropTable[$i]
$order = $ready.patch08OrderTable[$i]
$alias = installOrderAliases -Order $order

$actualAliased = aliasedPositionPours `
    -I $i `
    -Drop $drop `
    -Stones $ready.legacyStoneTable `
    -OldBowls $ready.legacyInitialBowls `
    -BowlAlias $alias
$expectedAliased = Get-Stage19ExpectedPours `
    -I $i `
    -Drop $drop `
    -Stones $ready.legacyStoneTable `
    -OldBowls $ready.legacyInitialBowls `
    -Order $order

Assert-StageEqual (Get-Stage19ArraySignature $expectedAliased) (Get-Stage19ArraySignature $actualAliased) 'GREEN ang aliased position pours sa i=1'

# 4. Raw Discovery 09 fixed-bowl helper remains physically wrong.
$rawLegacy = legacyFixedBowlPours `
    -I $i `
    -Drop $drop `
    -Stones $ready.legacyStoneTable `
    -OldBowls $ready.legacyInitialBowls
Assert-StageTrue `
    -Condition ((Get-Stage19ArraySignature $rawLegacy) -ne (Get-Stage19ArraySignature $expectedAliased)) `
    -Name 'Nananatiling mali ang raw Discovery 09 fixed-bowl helper'

# 5. Wrapper really runs raw scar first, then alias correction.
$wrapperCtx = New-Stage19ReadyContext -CalculationDay $foundation -TargetDay $target
$corrected1 = Invoke-Patch09BowlAliasRepair -Context $wrapperCtx -I 1
$expected1 = Get-Stage19ExpectedPours `
    -I 1 `
    -Drop ([System.Numerics.BigInteger]$wrapperCtx.legacyVisibleDropTable[1]) `
    -Stones $wrapperCtx.legacyStoneTable `
    -OldBowls $wrapperCtx.legacyInitialBowls `
    -Order $wrapperCtx.patch08OrderTable[1]

Assert-StageEqual 1 $wrapperCtx.discovery09InvocationCount 'Eksaktong isang preserved Discovery 09 raw scar invocation sa wrapper'
Assert-StageEqual 1 $wrapperCtx.patch09InvocationCount 'Eksaktong isang Patch 09 wrapper invocation'
Assert-StageEqual 1 $wrapperCtx.patch09DropIndex 'Patch 09 wrapper drop index ay 1'
Assert-StageTrue -Condition $wrapperCtx.patch09Applied -Name 'Applied ang Patch 09 wrapper'
Assert-StageEqual 'BOWL_ALIAS_PATCH_ACTIVE' $wrapperCtx.patch09Status 'Aktibo ang Patch 09 status'
Assert-StageEqual '0,5,4,3,6,2,1' (Get-Stage19ArraySignature $wrapperCtx.patch09BowlAlias) 'Exact ang production-fixture bowl alias'
Assert-StageTrue `
    -Condition ((Get-Stage19ArraySignature $wrapperCtx.patch09LegacyFixedPours) -ne (Get-Stage19ArraySignature $wrapperCtx.patch09CorrectedPours)) `
    -Name 'Hiwalay at divergent ang preserved raw fixed pours at corrected pours'
Assert-StageEqual (Get-Stage19ArraySignature $expected1) (Get-Stage19ArraySignature $corrected1) 'Wrapper ay nagbabalik ng corrected pours'
Assert-StageEqual (Get-Stage19ArraySignature $corrected1) (Get-Stage19ArraySignature $wrapperCtx.patch09CorrectedPours) 'Captured ang corrected Patch 09 pours'

# 6. All 46 isolated pour sets match normative position semantics.
$all46 = New-Stage19ReadyContext -CalculationDay $foundation -TargetDay $target
$green46 = 0
for ($dropIndex = 1; $dropIndex -le 46; $dropIndex++) {
    $actual = Invoke-Patch09BowlAliasRepair -Context $all46 -I $dropIndex
    $expected = Get-Stage19ExpectedPours `
        -I $dropIndex `
        -Drop ([System.Numerics.BigInteger]$all46.legacyVisibleDropTable[$dropIndex]) `
        -Stones $all46.legacyStoneTable `
        -OldBowls $all46.legacyInitialBowls `
        -Order $all46.patch08OrderTable[$dropIndex]

    Assert-StageEqual `
        (Get-Stage19ArraySignature $expected) `
        (Get-Stage19ArraySignature $actual) `
        "GREEN ang isolated Patch 09 pour set i=$dropIndex"
    $green46++
}
Assert-StageEqual 46 $green46 'Eksaktong 46 isolated Patch 09 pour sets ang GREEN'
Assert-StageEqual 46 $all46.patch09InvocationCount 'Eksaktong 46 Patch 09 repairs sa isolated sweep'
Assert-StageEqual 46 $all46.discovery09InvocationCount 'Eksaktong 46 preserved raw Discovery 09 scar calls sa isolated sweep'

# 7. Invocation ownership.
$clean = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
Assert-StageTrue -Condition ($null -eq $clean.patch09DropIndex) -Name 'Walang Patch 09 drop-index leak'
Assert-StageTrue -Condition ($null -eq $clean.patch09BowlAlias) -Name 'Walang Patch 09 bowl-alias leak'
Assert-StageTrue -Condition ($null -eq $clean.patch09LegacyFixedPours) -Name 'Walang Patch 09 raw-pours leak'
Assert-StageTrue -Condition ($null -eq $clean.patch09CorrectedPours) -Name 'Walang Patch 09 corrected-pours leak'
Assert-StageTrue -Condition (-not $clean.patch09Applied) -Name 'Hindi applied ang Patch 09 sa bagong invocation'
Assert-StageEqual 0 $clean.patch09InvocationCount 'Walang Patch 09 invocation-count leak'

# 8. Observability neutrality.
$plain = New-Stage19ReadyContext -CalculationDay $foundation -TargetDay $target
$noisy = New-Stage19ReadyContext -CalculationDay $foundation -TargetDay $target
$noisy.logs.Add([pscustomobject]@{ code='noisy-before'; data=19 })
$noisy.logs.Add([pscustomobject]@{ code='noisy-before'; data=190 })
$noisy.metrics['observability.only'] = [System.Numerics.BigInteger]9090
$noisy.diagnostics.Add([pscustomobject]@{ code='diagnostic'; data=19 })

$plainResult = Invoke-Patch09BowlAliasRepair -Context $plain -I 3
$noisyResult = Invoke-Patch09BowlAliasRepair -Context $noisy -I 3
Assert-StageEqual (Get-Stage19ArraySignature $plainResult) (Get-Stage19ArraySignature $noisyResult) 'Hindi binabago ng observability state ang bowl-alias patch'

# 9. Production route.
$ctx = Invoke-CalendarDateSpaghetti -CalculationDay $foundation -TargetDay $target

Assert-StageEqual 'SAVE_PATCH_ACTIVE' $ctx.patch01Status 'Nananatiling aktibo ang Patch 01 sa Stage 19'
Assert-StageEqual 'DAY_TAG_PATCH_ACTIVE' $ctx.patch02Status 'Nananatiling aktibo ang Patch 02 sa Stage 19'
Assert-StageEqual 'DISTANCE_PATCH_ACTIVE' $ctx.patch03Status 'Nananatiling aktibo ang Patch 03 sa Stage 19'
Assert-StageEqual 'STONE_PATCH_ACTIVE' $ctx.patch04Status 'Nananatiling aktibo ang Patch 04 sa Stage 19'
Assert-StageEqual 'HIDDEN_NEARNESS_PATCH_ACTIVE' $ctx.patch05Status 'Nananatiling aktibo ang Patch 05 sa Stage 19'
Assert-StageEqual 'PRIOR_PATCH_ACTIVE' $ctx.patch06Status 'Nananatiling aktibo ang Patch 06 sa Stage 19'
Assert-StageEqual 'SENTINEL_GRIND_PATCH_ACTIVE' $ctx.patch07Status 'Nananatiling aktibo ang Patch 07 sa Stage 19'
Assert-StageEqual 'PERMUTATION_RANK_PATCH_ACTIVE' $ctx.patch08Status 'Nananatiling aktibo ang Patch 08 sa Stage 19'

Assert-StageEqual 'FIXED_BOWL_ID_POURS_ACTIVE' $ctx.discovery09Status 'Talagang pinatakbo ang preserved Discovery 09 scar sa Stage 19 production route'
Assert-StageEqual 1 $ctx.discovery09InvocationCount 'Eksaktong isang raw Discovery 09 production scar call'
Assert-StageEqual 'BOWL_ALIAS_PATCH_ACTIVE' $ctx.patch09Status 'Aktibo ang Patch 09 sa production route'
Assert-StageEqual 1 $ctx.patch09InvocationCount 'Eksaktong isang Patch 09 production invocation'
Assert-StageEqual 1 $ctx.patch09DropIndex 'Production Patch 09 drop index ay 1'
Assert-StageEqual '0,5,4,3,6,2,1' (Get-Stage19ArraySignature $ctx.patch09BowlAlias) 'Production bowl alias ay exact'
Assert-StageTrue `
    -Condition ((Get-Stage19ArraySignature $ctx.patch09LegacyFixedPours) -ne (Get-Stage19ArraySignature $ctx.patch09CorrectedPours)) `
    -Name 'Production raw fixed-bowl scar ay divergent bago correction'
Assert-StageEqual (Get-Stage19ArraySignature $ctx.patch09CorrectedPours) (Get-Stage19ArraySignature $ctx.patch09ProductionPours) 'Production result ay corrected Patch 09 pours'
Assert-StageEqual (Get-Stage19ArraySignature $ctx.patch09LegacyFixedPours) (Get-Stage19ArraySignature $ctx.legacyPourProbeValues) 'Raw Discovery 09 production scar remains separately observable'
Assert-StageEqual (Get-Stage19ArraySignature $ctx.patch09CorrectedPours) (Get-Stage19ArraySignature $ctx.legacyPourLastValues) 'Legacy pour last-values now expose corrected Patch 09 result'
Assert-StageTrue -Condition $ctx.metrics.ContainsKey('patch09.pour.probes') -Name 'May Patch 09 production probe metric'
Assert-StageEqual ([System.Numerics.BigInteger]1) $ctx.metrics['patch09.pour.probes'] 'Eksaktong isang Patch 09 production probe metric increment'

# 10. Physical route, helper usage, purity, and Stage 20 absence.
$monsterText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/MonsterSkeleton.ps1')
$discovery09Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Discovery09.ps1')
$patch09Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Patch09.ps1')

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
    'src/Discovery09.ps1',
    'src/Patch09.ps1'
)
$productionText = $monsterText
foreach ($rel in $productionFiles) {
    $productionText += "`n" + (Get-Content -Raw -Encoding UTF8 (Join-Path $root $rel))
}

Assert-StageTrue -Condition ($productionText -notmatch 'Get-NormBowlOrderFromDrop|Get-NormPermutationUnrank1|Invoke-NormSauce|Get-NormCalendarDate') -Name 'Hindi tumatawag sa normative oracle ang Stage 19 production path'
Assert-StageTrue -Condition ($discovery09Text -match 'function legacyFixedBowlPours') -Name 'Nananatiling pisikal ang raw Discovery 09 fixed-bowl helper'
Assert-StageTrue -Condition ($patch09Text -match 'function installOrderAliases') -Name 'Pisikal ang Patch 09 alias installer'
Assert-StageTrue -Condition ($patch09Text -match 'function bowlByLegacyPosition') -Name 'Pisikal ang alias read helper'
Assert-StageTrue -Condition ($patch09Text -match 'function aliasedPositionPours') -Name 'Pisikal ang aliased pour helper'
Assert-StageTrue -Condition ($patch09Text -match 'function Invoke-Patch09BowlAliasRepair') -Name 'Pisikal ang Patch 09 wrapper'
Assert-StageTrue -Condition ($patch09Text -match 'legacyFixedBowlPours') -Name 'Talagang tinatawag muna ng Patch 09 wrapper ang raw fixed-bowl scar'
Assert-StageTrue -Condition ($patch09Text -match 'installOrderAliases') -Name 'Talagang ini-install ng wrapper ang current order aliases'
Assert-StageTrue -Condition ($patch09Text -match 'aliasedPositionPours') -Name 'Talagang tinatawag ng wrapper ang corrected aliased pours'
Assert-StageTrue -Condition (($patch09Text | Select-String -Pattern 'bowlByLegacyPosition' -AllMatches).Matches.Count -ge 4) -Name 'Nasa physical Patch 09 source ang alias helper at tatlong corrected position reads'
Assert-StageTrue -Condition ($monsterText -match 'Invoke-Patch09BowlAliasRepair') -Name 'Dumadaan ang tunay na production route sa Patch 09 wrapper'

$stage20Names = @(
    'vaultOld',
    'pendingBowlUpdates',
    'inPlaceBowlUpdatePatch',
    'legacyInPlaceBowlUpdate',
    'BowlUpdatePatchWrapper'
)
foreach ($name in $stage20Names) {
    Assert-StageTrue -Condition ($productionText -notmatch [regex]::Escape($name)) -Name "Wala pang Stage 20 / Patch 10 code: $name"
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

Write-Host 'PATCH09_ALIAS_SAMPLE=0,5,4,3,6,2,1'
Write-Host "PATCH09_CORRECTED_46_GREEN_COUNT=$green46"
Write-Host 'PATCH09_ALIAS_READ_POSITIONS=1,2,3'
Write-Host 'PATCH09_RAW_DISCOVERY09_SCAR=PRESERVED_AND_CALLED'
Write-Host 'PATCH09_PRODUCTION_I=1'
Write-Host 'PATCH09_PRODUCTION_ORDER=5,4,3,6,2,1'
Write-Host 'PATCH09_STAGE20_IN_PLACE=ABSENT'
Write-Host 'STAGE19_REPOSITORY_STATE=GREEN'

$ok = Complete-StageTestRun
if (-not $ok) { exit 1 }
Write-Host 'STAGE19_RESULT=PASS'
exit 0
