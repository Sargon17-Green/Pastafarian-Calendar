Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

. (Join-Path $root 'src/SourceLanguageCatalog.ps1')
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

function Get-Stage16OrderSignature {
    param([AllowNull()]$Order)
    if ($null -eq $Order) {
        return '<UNDEFINED>'
    }
    return (($Order | ForEach-Object { [string]$_ }) -join ',')
}

$foundation = Get-NormFoundationDay
$target = $foundation + 3
$metadata = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')

Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_STAGE=16\s*$') -Name 'Stage 16 ang kasalukuyang stage'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_KIND=DISCOVERY\s*$') -Name 'Discovery ang kasalukuyang uri'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_PATCH=08\s*$') -Name 'Discovery 08 ang kasalukuyang patch slot'
Assert-StageTrue -Condition ($metadata -match '(?m)^LAST_COMPLETED_STAGE=15\s*$') -Name 'Hindi pa minamarkahang kumpleto ang Stage 16 bago runtime'
Assert-StageTrue -Condition ($metadata -match '(?m)^EXPECTED_REPOSITORY_STATE=RED\s*$') -Name 'RED ang inaasahang Stage 16 repository state'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE15_RUNTIME_VERIFICATION=GREEN_CONFIRMED\s*$') -Name 'Nananatiling nakatala ang Stage 15 GREEN proof'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE16_DISCOVERY=ZERO_BASED_PERMUTATION_DIRECT_ONE_BASED_ORDINAL\s*$') -Name 'Discovery 08 metadata ay direct one-based ordinal bilang rank0'

# Raw helper itself is correct for rank0=0..719.
$rawFirst = oldPermutationUnrank0 -Rank0 ([System.Numerics.BigInteger]0)
$rawLast = oldPermutationUnrank0 -Rank0 ([System.Numerics.BigInteger]719)
$normFirst = Get-NormPermutationUnrank1 -Rank1 ([System.Numerics.BigInteger]1) -ItemsAscending ([int[]](1,2,3,4,5,6))
$normLast = Get-NormPermutationUnrank1 -Rank1 ([System.Numerics.BigInteger]720) -ItemsAscending ([int[]](1,2,3,4,5,6))
Assert-StageEqual (Get-Stage16OrderSignature $normFirst) (Get-Stage16OrderSignature $rawFirst) 'oldPermutationUnrank0 rank0=0 ay eksaktong unang permutation'
Assert-StageEqual (Get-Stage16OrderSignature $normLast) (Get-Stage16OrderSignature $rawLast) 'oldPermutationUnrank0 rank0=719 ay eksaktong huling permutation'
Assert-StageTrue -Condition ($null -eq (oldPermutationUnrank0 -Rank0 ([System.Numerics.BigInteger]720))) -Name 'oldPermutationUnrank0 rank0=720 ay undefined'

# Historical caller passes one-based ordinal directly as rank0.
$expectedRedCount = 0
$matchCount = 0

for ($drop = 1; $drop -le 720; $drop++) {
    $ctxCase = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
    $actual = LegacyPermutationRankAdapter -Context $ctxCase -DropValue ([System.Numerics.BigInteger]$drop)
    $expected = Get-NormBowlOrderFromDrop -DropValue ([System.Numerics.BigInteger]$drop)

    Assert-StageEqual $drop ([int]$ctxCase.legacyPermutationOneBasedOrdinal) "One-based ordinal ay eksaktong $drop"
    Assert-StageEqual $drop ([int]$ctxCase.legacyPermutationRank0Input) "Historical rank0 input ay maling kapareho ng one-based ordinal $drop"

    if ((Get-Stage16OrderSignature $actual) -eq (Get-Stage16OrderSignature $expected)) {
        $matchCount++
    }
    else {
        $expectedRedCount++
    }
}

Assert-StageEqual 720 $expectedRedCount 'Eksaktong 720 Discovery 08 EXPECTED_RED permutation ordinals'
Assert-StageEqual 0 $matchCount 'Walang Discovery 08 permutation ordinal na MATCH bago Patch 08'

# Exact boundary examples.
$ctx1 = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
$order1 = LegacyPermutationRankAdapter -Context $ctx1 -DropValue ([System.Numerics.BigInteger]1)
$expected1 = Get-NormBowlOrderFromDrop -DropValue ([System.Numerics.BigInteger]1)
Assert-StageEqual '1,2,3,4,6,5' (Get-Stage16OrderSignature $order1) 'Drop 1 ay maling nagbabalik ng ikalawang lexicographic permutation'
Assert-StageEqual '1,2,3,4,5,6' (Get-Stage16OrderSignature $expected1) 'Normative drop 1 ay unang permutation'

$ctx719 = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
$order719 = LegacyPermutationRankAdapter -Context $ctx719 -DropValue ([System.Numerics.BigInteger]719)
$expected719 = Get-NormBowlOrderFromDrop -DropValue ([System.Numerics.BigInteger]719)
Assert-StageEqual (Get-Stage16OrderSignature $normLast) (Get-Stage16OrderSignature $order719) 'Drop 719 ay maling nagbabalik ng huling permutation'
Assert-StageTrue -Condition ((Get-Stage16OrderSignature $order719) -ne (Get-Stage16OrderSignature $expected719)) -Name 'Drop 719 ay divergent laban sa normative rank 719'

$ctx720 = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
$order720 = LegacyPermutationRankAdapter -Context $ctx720 -DropValue ([System.Numerics.BigInteger]720)
Assert-StageTrue -Condition ($null -eq $order720) -Name 'Drop 720 ay undefined dahil ipinasa ang rank0=720'
Assert-StageTrue -Condition $ctx720.legacyPermutationUndefined -Name 'Na-capture ang undefined flag para sa drop 720'

$ctx721 = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
$order721 = LegacyPermutationRankAdapter -Context $ctx721 -DropValue ([System.Numerics.BigInteger]721)
Assert-StageEqual 1 ([int]$ctx721.legacyPermutationOneBasedOrdinal) 'Drop 721 ay bumabalik sa one-based ordinal 1'
Assert-StageEqual (Get-Stage16OrderSignature $order1) (Get-Stage16OrderSignature $order721) 'Pareho ang historical result ng drops 1 at 721'

# Scar state.
Assert-StageEqual 1 $ctx1.discovery08InvocationCount 'Isang Discovery 08 invocation sa probe case'
Assert-StageEqual 'ONE_BASED_ORDINAL_AS_RANK0_ACTIVE' $ctx1.discovery08Status 'Aktibo ang Discovery 08 status'
Assert-StageEqual 1 ([int]$ctx1.legacyPermutationDropValue) 'Na-capture ang drop value 1'
Assert-StageEqual 1 ([int]$ctx1.legacyPermutationOneBasedOrdinal) 'Na-capture ang one-based ordinal 1'
Assert-StageEqual 1 ([int]$ctx1.legacyPermutationRank0Input) 'Na-capture ang maling rank0 input 1'
Assert-StageEqual '1,2,3,4,6,5' (Get-Stage16OrderSignature $ctx1.legacyPermutationOrder) 'Na-capture ang maling legacy order'
Assert-StageTrue -Condition (-not $ctx1.legacyPermutationUndefined) -Name 'Hindi undefined ang drop 1'

# Production route.
$ctx = Invoke-CalendarDateSpaghetti -CalculationDay $foundation -TargetDay $target
Assert-StageEqual 'SAVE_PATCH_ACTIVE' $ctx.patch01Status 'Nananatiling aktibo ang Patch 01 sa Stage 16'
Assert-StageEqual 'DAY_TAG_PATCH_ACTIVE' $ctx.patch02Status 'Nananatiling aktibo ang Patch 02 sa Stage 16'
Assert-StageEqual 'DISTANCE_PATCH_ACTIVE' $ctx.patch03Status 'Nananatiling aktibo ang Patch 03 sa Stage 16'
Assert-StageEqual 'STONE_PATCH_ACTIVE' $ctx.patch04Status 'Nananatiling aktibo ang Patch 04 sa Stage 16'
Assert-StageEqual 'BACKWARD_HIDDEN_STORAGE_ACTIVE' $ctx.discovery05Status 'Nananatiling aktibo ang Discovery 05 scar sa Stage 16'
Assert-StageEqual 'HIDDEN_NEARNESS_PATCH_ACTIVE' $ctx.patch05Status 'Nananatiling aktibo ang Patch 05 sa Stage 16'
Assert-StageEqual 'VISIBLE_ONLY_PRIOR_SCAR_PRESERVED' $ctx.discovery06Status 'Nananatiling preserved ang Discovery 06 scar sa Stage 16'
Assert-StageEqual 'PRIOR_PATCH_ACTIVE' $ctx.patch06Status 'Nananatiling aktibo ang Patch 06 sa Stage 16'
Assert-StageEqual 'ZERO_BASED_DIRECT_ORDINAL_INDEX_ACTIVE' $ctx.discovery07Status 'Nananatiling talagang tinatawag ang raw Discovery 07 scar sa Stage 16'
Assert-StageEqual 'SENTINEL_GRIND_PATCH_ACTIVE' $ctx.patch07Status 'Nananatiling aktibo ang Patch 07 sa Stage 16'
Assert-StageEqual 1 $ctx.patch07RequestedGrind 'Nananatiling grind 1 ang Patch 07 production probe'

Assert-StageEqual 'ONE_BASED_ORDINAL_AS_RANK0_ACTIVE' $ctx.discovery08Status 'Aktibo ang Discovery 08 sa production route'
Assert-StageEqual 1 $ctx.discovery08InvocationCount 'Eksaktong isang Discovery 08 production probe'
Assert-StageEqual 1 ([int]$ctx.legacyPermutationDropValue) 'Production permutation probe drop ay eksaktong 1'
Assert-StageEqual 1 ([int]$ctx.legacyPermutationOneBasedOrdinal) 'Production semantic ordinal ay eksaktong 1'
Assert-StageEqual 1 ([int]$ctx.legacyPermutationRank0Input) 'Production legacy rank0 input ay maling 1'
Assert-StageEqual '1,2,3,4,6,5' (Get-Stage16OrderSignature $ctx.legacyPermutationProbeOrder) 'Production Discovery 08 probe ay maling ikalawang permutation'
Assert-StageEqual (Get-Stage16OrderSignature $ctx.legacyPermutationOrder) (Get-Stage16OrderSignature $ctx.legacyPermutationProbeOrder) 'Pareho ang captured at production legacy permutation'
Assert-StageTrue -Condition $ctx.metrics.ContainsKey('discovery08.permutation.probes') -Name 'May Discovery 08 production probe metric'
Assert-StageEqual ([System.Numerics.BigInteger]1) $ctx.metrics['discovery08.permutation.probes'] 'Eksaktong isang Discovery 08 production probe metric increment'

# Invocation ownership.
$clean = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
Assert-StageTrue -Condition ($null -eq $clean.legacyPermutationDropValue) -Name 'Walang permutation drop-value leak'
Assert-StageTrue -Condition ($null -eq $clean.legacyPermutationOneBasedOrdinal) -Name 'Walang one-based ordinal leak'
Assert-StageTrue -Condition ($null -eq $clean.legacyPermutationRank0Input) -Name 'Walang legacy rank0 input leak'
Assert-StageTrue -Condition ($null -eq $clean.legacyPermutationOrder) -Name 'Walang legacy permutation order leak'
Assert-StageTrue -Condition (-not $clean.legacyPermutationUndefined) -Name 'Walang permutation undefined-flag leak'
Assert-StageTrue -Condition ($null -eq $clean.legacyPermutationProbeOrder) -Name 'Walang production permutation-probe leak'
Assert-StageEqual 0 $clean.discovery08InvocationCount 'Walang Discovery 08 invocation-count leak'

# Observability neutrality.
$plain = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
$noisy = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
$noisy.logs.Add([pscustomobject]@{ code='noisy-before'; data=16 })
$noisy.metrics['observability.only'] = [System.Numerics.BigInteger]1616
$noisy.diagnostics.Add([pscustomobject]@{ code='diagnostic'; data=16 })
$plainOrder = LegacyPermutationRankAdapter -Context $plain -DropValue ([System.Numerics.BigInteger]17)
$noisyOrder = LegacyPermutationRankAdapter -Context $noisy -DropValue ([System.Numerics.BigInteger]17)
Assert-StageEqual (Get-Stage16OrderSignature $plainOrder) (Get-Stage16OrderSignature $noisyOrder) 'Hindi binabago ng observability state ang legacy permutation result'

# Production purity, physical scar, and no Stage 17/18 logic.
$monsterText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/MonsterSkeleton.ps1')
$discovery08Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Discovery08.ps1')
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
    'src/Discovery08.ps1'
)
$productionText = $monsterText
foreach ($rel in $productionFiles) {
    $productionText += "`n" + (Get-Content -Raw -Encoding UTF8 (Join-Path $root $rel))
}

Assert-StageTrue -Condition ($productionText -notmatch 'Invoke-NormSauce|Get-NormCalendarDate|Get-NormSave|Get-NormBowlOrderFromDrop|Get-NormPermutationUnrank1') -Name 'Hindi tumatawag sa normative oracle ang Stage 16 production path'
Assert-StageTrue -Condition ($discovery08Text -match 'function oldPermutationUnrank0') -Name 'Pisikal ang raw oldPermutationUnrank0 helper'
Assert-StageTrue -Condition ($discovery08Text -match 'function LegacyPermutationRankAdapter') -Name 'Pisikal ang LegacyPermutationRankAdapter'
Assert-StageTrue -Condition ($discovery08Text -match '\$legacyRank0Input = \[System\.Numerics\.BigInteger\]\$oneBasedOrdinal') -Name 'Direktang ipinapasa ang one-based ordinal bilang rank0'
Assert-StageTrue -Condition ($monsterText -match 'LegacyPermutationRankAdapter') -Name 'Dumadaan ang tunay na production route sa Discovery 08 adapter'

$stage17Names = @(
    'orderPatchFromValue',
    'PermutationRankPatch',
    'legacyRank0Corrected',
    'oneBasedMinusOne'
)
foreach ($name in $stage17Names) {
    Assert-StageTrue -Condition ($productionText -notmatch [regex]::Escape($name)) -Name "Wala pang Stage 17 Patch 08 code: $name"
}

$futureNames = @(
    'bowlAlias',
    'installOrderAliases',
    'bowlByLegacyPosition',
    'patchedPours',
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

Write-Host "DISCOVERY08_EXPECTED_RED_COUNT=$expectedRedCount"
Write-Host "DISCOVERY08_MATCH_COUNT=$matchCount"
Write-Host 'DISCOVERY08_RED_ORDINAL_RANGE=1..720'
Write-Host 'DISCOVERY08_DROP1_LEGACY_RANK0=1'
Write-Host 'DISCOVERY08_DROP1_ACTUAL=1,2,3,4,6,5'
Write-Host 'DISCOVERY08_DROP1_EXPECTED=1,2,3,4,5,6'
Write-Host 'DISCOVERY08_DROP720=UNDEFINED'
Write-Host 'DISCOVERY08_PRODUCTION_PROBE_DROP=1'
Write-Host 'DISCOVERY08_PATCH08_BRIDGE=ABSENT'
Write-Host 'STAGE16_REPOSITORY_STATE=EXPECTED_RED'

$ok = Complete-StageTestRun
if (-not $ok) { exit 1 }
Write-Host 'STAGE16_RESULT=PASS'
exit 0
