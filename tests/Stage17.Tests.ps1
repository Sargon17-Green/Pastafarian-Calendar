Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

. (Join-Path $root 'src/SourceLanguageCatalog.ps1')
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

function Get-Stage17OrderSignature {
    param([AllowNull()]$Order)
    if ($null -eq $Order) {
        return '<UNDEFINED>'
    }
    return (($Order | ForEach-Object { [string]$_ }) -join ',')
}

function New-Stage17VisibleDropProbeTable {
    $drops = [object[]]::new(47)
    for ($i = 1; $i -le 46; $i++) {
        # Deterministic supplied visible-drop values. This is not a visible-drop builder.
        $drops[$i] = [System.Numerics.BigInteger](1 + ((($i - 1) * 137) % 720))
    }
    return ,$drops
}

$foundation = Get-NormFoundationDay
$target = $foundation + 3
$metadata = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')

Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_STAGE=17\s*$') -Name 'Stage 17 ang kasalukuyang stage'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_KIND=PATCH\s*$') -Name 'Patch ang kasalukuyang uri'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_PATCH=08\s*$') -Name 'Patch 08 ang kasalukuyang patch slot'
Assert-StageTrue -Condition ($metadata -match '(?m)^LAST_COMPLETED_STAGE=16\s*$') -Name 'Hindi pa minamarkahang kumpleto ang Stage 17 bago runtime'
Assert-StageTrue -Condition ($metadata -match '(?m)^EXPECTED_REPOSITORY_STATE=GREEN\s*$') -Name 'GREEN ang inaasahang Stage 17 repository state'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE16_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED\s*$') -Name 'Nananatiling nakatala ang Stage 16 expected-red proof'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE17_PATCH=ONE_BASED_TO_ZERO_BASED_PERMUTATION_RANK\s*$') -Name 'Patch 08 metadata ay one-based to zero-based permutation rank'

# 1. Raw Discovery 08 scar stays physically wrong.
$rawRedCount = 0
for ($drop = 1; $drop -le 720; $drop++) {
    $ctxRaw = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
    $raw = LegacyPermutationRankAdapter -Context $ctxRaw -DropValue ([System.Numerics.BigInteger]$drop)
    $expected = Get-NormBowlOrderFromDrop -DropValue ([System.Numerics.BigInteger]$drop)
    if ((Get-Stage17OrderSignature $raw) -ne (Get-Stage17OrderSignature $expected)) {
        $rawRedCount++
    }
}
Assert-StageEqual 720 $rawRedCount 'Nananatiling mali ang lahat ng 720 raw Discovery 08 ordinals'

# 2. Direct corrected chain matches normative for every semantic ordinal.
$translatorGreenCount = 0
for ($drop = 1; $drop -le 720; $drop++) {
    $actual = patchedOrderFromDrop -DropValue ([System.Numerics.BigInteger]$drop)
    $expected = Get-NormBowlOrderFromDrop -DropValue ([System.Numerics.BigInteger]$drop)

    Assert-StageEqual `
        (Get-Stage17OrderSignature $expected) `
        (Get-Stage17OrderSignature $actual) `
        "patchedOrderFromDrop ay GREEN para sa ordinal=$drop"

    $translatorGreenCount++
}
Assert-StageEqual 720 $translatorGreenCount 'Eksaktong 720 Patch 08 translator ordinals ang GREEN'

# 3. Wrapper really runs the wrong caller first, then oneBased-1 correction.
$wrapperGreenCount = 0
foreach ($drop in ([int[]](1,2,17,570,719,720))) {
    $ctxCase = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
    $actual = Invoke-Patch08PermutationRankRepair `
        -Context $ctxCase `
        -DropIndex 1 `
        -DropValue ([System.Numerics.BigInteger]$drop)

    $expected = Get-NormBowlOrderFromDrop -DropValue ([System.Numerics.BigInteger]$drop)
    $oneBased = [int]((($drop - 1) % 720) + 1)

    Assert-StageEqual `
        (Get-Stage17OrderSignature $expected) `
        (Get-Stage17OrderSignature $actual) `
        "Patch 08 wrapper ay GREEN para sa drop=$drop"
    Assert-StageEqual 1 $ctxCase.discovery08InvocationCount "Talagang isang raw Discovery 08 call muna para sa drop=$drop"
    Assert-StageEqual $oneBased ([int]$ctxCase.patch08OneBasedOrdinal) "Tamang one-based ordinal para sa drop=$drop"
    Assert-StageEqual ($oneBased - 1) ([int]$ctxCase.patch08LegacyRank0) "Eksaktong oneBased-1 rank0 para sa drop=$drop"
    Assert-StageTrue -Condition $ctxCase.patch08Applied -Name "Applied ang Patch 08 para sa drop=$drop"
    Assert-StageEqual 'PERMUTATION_RANK_PATCH_ACTIVE' $ctxCase.patch08Status "Aktibo ang Patch 08 status para sa drop=$drop"
    Assert-StageEqual 1 $ctxCase.patch08InvocationCount "Isang Patch 08 invocation para sa drop=$drop"
    $wrapperGreenCount++
}
Assert-StageEqual 6 $wrapperGreenCount 'Lahat ng anim na Patch 08 wrapper boundary probes ay GREEN'

# 4. Exact scar/correction examples.
$ctx1 = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
$order1 = Invoke-Patch08PermutationRankRepair -Context $ctx1 -DropIndex 1 -DropValue ([System.Numerics.BigInteger]1)
Assert-StageEqual '1,2,3,4,6,5' (Get-Stage17OrderSignature $ctx1.patch08LegacyWrongOrder) 'Sa drop 1, raw scar ay nananatiling permutation 2'
Assert-StageEqual '1,2,3,4,5,6' (Get-Stage17OrderSignature $order1) 'Sa drop 1, corrected result ay permutation 1'
Assert-StageEqual 1 ([int]$ctx1.patch08OneBasedOrdinal) 'Sa drop 1, oneBased ay 1'
Assert-StageEqual 0 ([int]$ctx1.patch08LegacyRank0) 'Sa drop 1, corrected legacyRank0 ay 0'

$ctx570 = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
[void](Invoke-Patch08PermutationRankRepair -Context $ctx570 -DropIndex 1 -DropValue ([System.Numerics.BigInteger]570)
)
Assert-StageEqual 570 ([int]$ctx570.patch08OneBasedOrdinal) 'Sa drop 570, oneBased ay 570'
Assert-StageEqual 569 ([int]$ctx570.patch08LegacyRank0) 'Sa drop 570, oldPermutationUnrank0 input ay eksaktong 569'

$ctx720 = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
$order720 = Invoke-Patch08PermutationRankRepair -Context $ctx720 -DropIndex 1 -DropValue ([System.Numerics.BigInteger]720)
Assert-StageEqual 720 ([int]$ctx720.patch08OneBasedOrdinal) 'Sa drop 720, oneBased ay 720'
Assert-StageEqual 719 ([int]$ctx720.patch08LegacyRank0) 'Sa drop 720, corrected legacyRank0 ay 719'
Assert-StageTrue -Condition ($null -eq $ctx720.patch08LegacyWrongOrder) -Name 'Sa drop 720, raw wrong order ay null/undefined'
Assert-StageTrue -Condition $ctx720.patch08LegacyWrongUndefined -Name 'Sa drop 720, preserved ang raw undefined scar'
Assert-StageTrue -Condition ($null -ne $ctx720.patch08LegacyWrongError) -Name 'Sa drop 720, may preserved raw range-error scar text'
Assert-StageEqual '6,5,4,3,2,1' (Get-Stage17OrderSignature $order720) 'Sa drop 720, corrected result ay huling permutation'

# 5. A 46-slot supplied visible-drop order table is corrected without adding a visible-drop builder.
$visibleDrops = New-Stage17VisibleDropProbeTable
$tableCtx = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
$orderTable = Invoke-Patch08BuildOrderTable -Context $tableCtx -VisibleDrops $visibleDrops
$visibleOrderGreenCount = 0

for ($i = 1; $i -le 46; $i++) {
    $expected = Get-NormBowlOrderFromDrop -DropValue ([System.Numerics.BigInteger]$visibleDrops[$i])
    Assert-StageEqual `
        (Get-Stage17OrderSignature $expected) `
        (Get-Stage17OrderSignature $orderTable[$i]) `
        "GREEN ang supplied visible-drop order slot $i"
    $visibleOrderGreenCount++
}
Assert-StageEqual 46 $visibleOrderGreenCount 'Eksaktong 46 supplied visible-drop order slots ang GREEN'
Assert-StageEqual 46 $tableCtx.patch08OrderCount 'Patch 08 order-table count ay 46'
Assert-StageEqual 46 $tableCtx.patch08InvocationCount 'Eksaktong 46 Patch 08 calls ang order-table build'
Assert-StageEqual 46 $tableCtx.discovery08InvocationCount 'Eksaktong 46 raw Discovery 08 calls muna ang order-table build'

# 6. Production route: prior layers stay active, raw Discovery 08 really runs, Patch 08 corrects.
$ctx = Invoke-CalendarDateSpaghetti -CalculationDay $foundation -TargetDay $target
Assert-StageEqual 'SAVE_PATCH_ACTIVE' $ctx.patch01Status 'Nananatiling aktibo ang Patch 01 sa Stage 17'
Assert-StageEqual 'DAY_TAG_PATCH_ACTIVE' $ctx.patch02Status 'Nananatiling aktibo ang Patch 02 sa Stage 17'
Assert-StageEqual 'DISTANCE_PATCH_ACTIVE' $ctx.patch03Status 'Nananatiling aktibo ang Patch 03 sa Stage 17'
Assert-StageEqual 'STONE_PATCH_ACTIVE' $ctx.patch04Status 'Nananatiling aktibo ang Patch 04 sa Stage 17'
Assert-StageEqual 'HIDDEN_NEARNESS_PATCH_ACTIVE' $ctx.patch05Status 'Nananatiling aktibo ang Patch 05 sa Stage 17'
Assert-StageEqual 'PRIOR_PATCH_ACTIVE' $ctx.patch06Status 'Nananatiling aktibo ang Patch 06 sa Stage 17'
Assert-StageEqual 'SENTINEL_GRIND_PATCH_ACTIVE' $ctx.patch07Status 'Nananatiling aktibo ang Patch 07 sa Stage 17'

Assert-StageEqual 'ONE_BASED_ORDINAL_AS_RANK0_ACTIVE' $ctx.discovery08Status 'Talagang pinatakbo ang raw Discovery 08 scar sa Stage 17 production route'
Assert-StageEqual 1 $ctx.discovery08InvocationCount 'Eksaktong isang raw Discovery 08 production call'
Assert-StageEqual 1 ([int]$ctx.legacyPermutationOneBasedOrdinal) 'Production raw semantic ordinal ay 1'
Assert-StageEqual 1 ([int]$ctx.legacyPermutationRank0Input) 'Production raw wrong rank0 input ay 1'
Assert-StageEqual '1,2,3,4,6,5' (Get-Stage17OrderSignature $ctx.patch08LegacyWrongOrder) 'Production raw scar ay permutation 2'

Assert-StageEqual 'PERMUTATION_RANK_PATCH_ACTIVE' $ctx.patch08Status 'Aktibo ang Patch 08 sa production route'
Assert-StageEqual 1 $ctx.patch08InvocationCount 'Eksaktong isang Patch 08 production invocation'
Assert-StageEqual 1 ([int]$ctx.patch08OneBasedOrdinal) 'Production Patch 08 oneBased ay 1'
Assert-StageEqual 0 ([int]$ctx.patch08LegacyRank0) 'Production Patch 08 corrected rank0 ay 0'
Assert-StageEqual '1,2,3,4,5,6' (Get-Stage17OrderSignature $ctx.patch08CorrectedOrder) 'Production corrected result ay permutation 1'
Assert-StageEqual (Get-Stage17OrderSignature $ctx.patch08CorrectedOrder) (Get-Stage17OrderSignature $ctx.patch08ProductionOrder) 'Production probe value ay corrected Patch 08 order'
Assert-StageEqual (Get-Stage17OrderSignature $ctx.patch08LegacyWrongOrder) (Get-Stage17OrderSignature $ctx.legacyPermutationProbeOrder) 'Raw Stage 16 production scar remains observable'
Assert-StageTrue -Condition $ctx.metrics.ContainsKey('patch08.permutation.probes') -Name 'May Patch 08 production probe metric'
Assert-StageEqual ([System.Numerics.BigInteger]1) $ctx.metrics['patch08.permutation.probes'] 'Eksaktong isang Patch 08 production probe metric increment'

# 7. Invocation ownership.
$clean = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
Assert-StageTrue -Condition ($null -eq $clean.patch08DropIndex) -Name 'Walang Patch 08 drop-index leak'
Assert-StageTrue -Condition ($null -eq $clean.patch08DropValue) -Name 'Walang Patch 08 drop-value leak'
Assert-StageTrue -Condition ($null -eq $clean.patch08OneBasedOrdinal) -Name 'Walang Patch 08 one-based leak'
Assert-StageTrue -Condition ($null -eq $clean.patch08LegacyRank0) -Name 'Walang Patch 08 legacy-rank0 leak'
Assert-StageTrue -Condition ($null -eq $clean.patch08LegacyWrongOrder) -Name 'Walang Patch 08 raw-order leak'
Assert-StageTrue -Condition (-not $clean.patch08LegacyWrongUndefined) -Name 'Walang Patch 08 raw-undefined leak'
Assert-StageTrue -Condition ($null -eq $clean.patch08LegacyWrongError) -Name 'Walang Patch 08 raw-error leak'
Assert-StageTrue -Condition ($null -eq $clean.patch08CorrectedOrder) -Name 'Walang Patch 08 corrected-order leak'
Assert-StageTrue -Condition (-not $clean.patch08Applied) -Name 'Hindi applied ang Patch 08 sa bagong invocation'
Assert-StageEqual 0 $clean.patch08InvocationCount 'Walang Patch 08 invocation-count leak'

# 8. Observability neutrality.
$plain = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
$noisy = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
$noisy.logs.Add([pscustomobject]@{ code='noisy-before'; data=17 })
$noisy.metrics['observability.only'] = [System.Numerics.BigInteger]1717
$noisy.diagnostics.Add([pscustomobject]@{ code='diagnostic'; data=17 })

$plainOrder = Invoke-Patch08PermutationRankRepair -Context $plain -DropIndex 1 -DropValue ([System.Numerics.BigInteger]570)
$noisyOrder = Invoke-Patch08PermutationRankRepair -Context $noisy -DropIndex 1 -DropValue ([System.Numerics.BigInteger]570)
Assert-StageEqual (Get-Stage17OrderSignature $plainOrder) (Get-Stage17OrderSignature $noisyOrder) 'Hindi binabago ng observability state ang Patch 08 result'

# 9. Production purity, physical scar, exact oneBased-1 chain, and no Stage 18.
$monsterText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/MonsterSkeleton.ps1')
$discovery08Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Discovery08.ps1')
$patch08Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Patch08.ps1')

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
    'src/Patch08.ps1'
)
$productionText = $monsterText
foreach ($rel in $productionFiles) {
    $productionText += "`n" + (Get-Content -Raw -Encoding UTF8 (Join-Path $root $rel))
}

Assert-StageTrue -Condition ($productionText -notmatch 'Get-NormBowlOrderFromDrop|Get-NormPermutationUnrank1|Invoke-NormSauce|Get-NormCalendarDate') -Name 'Hindi tumatawag sa normative oracle ang Stage 17 production path'
Assert-StageTrue -Condition ($discovery08Text -match 'function oldPermutationUnrank0') -Name 'Nananatiling pisikal ang raw oldPermutationUnrank0 helper'
Assert-StageTrue -Condition ($discovery08Text -match '\$legacyRank0Input = \[System\.Numerics\.BigInteger\]\$oneBasedOrdinal') -Name 'Nananatiling eksakto ang Discovery 08 direct one-based-as-rank0 scar'
Assert-StageTrue -Condition ($discovery08Text -notmatch 'patchedOrderFromDrop|Invoke-Patch08PermutationRankRepair') -Name 'Hindi binago ang Discovery 08 file para itago ang Patch 08'
Assert-StageTrue -Condition ($patch08Text -match 'function patchedOrderFromDrop') -Name 'Pisikal at hiwalay ang corrected permutation helper'
Assert-StageTrue -Condition ($patch08Text -match 'function Invoke-Patch08PermutationRankRepair') -Name 'Pisikal at hiwalay ang Patch 08 wrapper'
Assert-StageTrue -Condition ($patch08Text -match 'LegacyPermutationRankAdapter') -Name 'Talagang tinatawag muna ng Patch 08 ang raw Discovery 08 adapter'
Assert-StageTrue -Condition ($patch08Text -match '\$legacyRank0 = \[System\.Numerics\.BigInteger\]\(\$oneBased - 1\)') -Name 'Eksaktong oneBased-1 ang Patch 08 rank translation'
Assert-StageTrue -Condition ($patch08Text -match 'oldPermutationUnrank0 -Rank0 \$legacyRank0') -Name 'Ang corrected chain ay gumagamit pa rin ng preserved oldPermutationUnrank0'
Assert-StageTrue -Condition ($monsterText -match 'Invoke-Patch08PermutationRankRepair') -Name 'Dumadaan ang tunay na production route sa Patch 08'

$stage18Names = @(
    'legacyPourFixedBowl',
    'LegacyPourAdapter',
    'bowlAlias',
    'installOrderAliases',
    'bowlByLegacyPosition',
    'patchedPours'
)
foreach ($name in $stage18Names) {
    Assert-StageTrue -Condition ($productionText -notmatch [regex]::Escape($name)) -Name "Wala pang Stage 18 / Patch 09 code: $name"
}

$futureNames = @(
    'vaultOld',
    'orderAt46Latch',
    'biasedLegacyPick',
    'LEGACY_YEAR_MAX',
    'VirtualLegacyList',
    'oldContiguousMonthDayGuess'
)
foreach ($name in $futureNames) {
    Assert-StageTrue -Condition ($productionText -notmatch [regex]::Escape($name)) -Name "Walang future patch code: $name"
}

Write-Host "PATCH08_RAW_DISCOVERY08_RED_COUNT=$rawRedCount"
Write-Host "PATCH08_TRANSLATOR_GREEN_COUNT=$translatorGreenCount"
Write-Host "PATCH08_WRAPPER_BOUNDARY_GREEN_COUNT=$wrapperGreenCount"
Write-Host "PATCH08_VISIBLE_ORDER_GREEN_COUNT=$visibleOrderGreenCount"
Write-Host 'PATCH08_DROP1_RAW=1,2,3,4,6,5'
Write-Host 'PATCH08_DROP1_CORRECTED=1,2,3,4,5,6'
Write-Host 'PATCH08_DROP720_RAW=UNDEFINED'
Write-Host 'PATCH08_DROP720_CORRECTED=6,5,4,3,2,1'
Write-Host 'PATCH08_PRODUCTION_DROP=1'
Write-Host 'PATCH08_PRODUCTION_LEGACY_RANK0=0'
Write-Host 'PATCH08_DISCOVERY08_SCAR=PRESERVED_AND_CALLED'
Write-Host 'PATCH08_STAGE18_POURS=ABSENT'
Write-Host 'STAGE17_REPOSITORY_STATE=GREEN'

$ok = Complete-StageTestRun
if (-not $ok) { exit 1 }
Write-Host 'STAGE17_RESULT=PASS'
exit 0
