Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

. (Join-Path $root 'src/SourceLanguageCatalog.ps1')
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

function Get-Stage21ArraySignature {
    param([AllowNull()]$Values)
    if ($null -eq $Values) { return '<NULL>' }
    return (($Values | ForEach-Object {
        if ($null -eq $_) { '<NULL>' } else { [string]$_ }
    }) -join ',')
}

function Get-Stage21SnapshotExpected {
    param(
        [Parameter(Mandatory)][int]$I,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$Drop,
        [AllowNull()][Parameter(Mandatory)][System.Array]$Order,
        [AllowNull()][Parameter(Mandatory)][System.Array]$Pours,
        [AllowNull()][Parameter(Mandatory)][System.Array]$Stones,
        [AllowNull()][Parameter(Mandatory)][System.Array]$Bowls
    )

    $kindByPosition = [int[]](0,1,2,3,4,0)
    $old = [System.Numerics.BigInteger[]]::new(7)
    $pending = [System.Numerics.BigInteger[]]::new(7)

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

function New-Stage21ReadyContext {
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

Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_STAGE=21\s*$') -Name 'Stage 21 ang kasalukuyang stage'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_KIND=PATCH\s*$') -Name 'Patch ang kasalukuyang uri'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_PATCH=10\s*$') -Name 'Patch 10 ang kasalukuyang patch slot'
Assert-StageTrue -Condition ($metadata -match '(?m)^LAST_COMPLETED_STAGE=20\s*$') -Name 'Hindi pa minamarkahang kumpleto ang Stage 21 bago runtime'
Assert-StageTrue -Condition ($metadata -match '(?m)^EXPECTED_REPOSITORY_STATE=GREEN\s*$') -Name 'GREEN ang inaasahang Stage 21 repository state'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE20_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED\s*$') -Name 'Nananatiling nakatala ang Stage 20 expected-red proof'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE21_PATCH=SNAPSHOT_BOWL_UPDATE_WITH_PENDING_BATCH\s*$') -Name 'Patch 10 metadata ay snapshot/pending batch repair'

$ready = New-Stage21ReadyContext -CalculationDay $foundation -TargetDay $target
$i = 1
$bowls = $ready.legacyInitialBowls
$pours = $ready.patch09CorrectedPours
$drop = [System.Numerics.BigInteger]$ready.legacyVisibleDropTable[$i]
$order = $ready.patch08OrderTable[$i]

# 1. Raw Discovery 10 helper remains physically wrong.
$legacyWrong = legacyInPlaceBowlUpdateWrong `
    -I $i -Drop $drop -Order $order -Pours $pours `
    -Stones $ready.legacyStoneTable -Bowls $bowls

$expected = Get-Stage21SnapshotExpected `
    -I $i -Drop $drop -Order $order -Pours $pours `
    -Stones $ready.legacyStoneTable -Bowls $bowls

Assert-StageTrue `
    -Condition ((Get-Stage21ArraySignature $legacyWrong) -ne (Get-Stage21ArraySignature $expected)) `
    -Name 'Nananatiling mali ang raw Discovery 10 in-place helper'

# 2. Snapshot patch matches the complete one-drop expected result.
$snapshot = snapshotBowlUpdatePatched `
    -I $i -Drop $drop -Order $order -Pours $pours `
    -Stones $ready.legacyStoneTable -Bowls $bowls

Assert-StageEqual `
    (Get-Stage21ArraySignature $expected) `
    (Get-Stage21ArraySignature $snapshot) `
    'GREEN ang snapshot Patch 10 one-drop result'

# 3. Wrapper really calls the wrong scar first, then returns corrected snapshot result.
$wrapper = New-Stage21ReadyContext -CalculationDay $foundation -TargetDay $target
$original = $wrapper.legacyInitialBowls
$originalSignature = Get-Stage21ArraySignature $original

$actual = Invoke-Patch10SnapshotBowlUpdateRepair `
    -Context $wrapper `
    -I 1 `
    -Bowls $original `
    -Pours $wrapper.patch09CorrectedPours

$wrapperExpected = Get-Stage21SnapshotExpected `
    -I 1 `
    -Drop ([System.Numerics.BigInteger]$wrapper.legacyVisibleDropTable[1]) `
    -Order $wrapper.patch08OrderTable[1] `
    -Pours $wrapper.patch09CorrectedPours `
    -Stones $wrapper.legacyStoneTable `
    -Bowls $original

Assert-StageEqual 1 $wrapper.discovery10InvocationCount 'Eksaktong isang preserved Discovery 10 raw scar invocation sa wrapper'
Assert-StageEqual 1 $wrapper.patch10InvocationCount 'Eksaktong isang Patch 10 wrapper invocation'
Assert-StageEqual 1 $wrapper.patch10DropIndex 'Patch 10 wrapper drop index ay 1'
Assert-StageTrue -Condition $wrapper.patch10Applied -Name 'Applied ang Patch 10 wrapper'
Assert-StageTrue -Condition $wrapper.patch10CommitAfterSix -Name 'Commit-after-six marker ay true'
Assert-StageEqual 'SNAPSHOT_BOWL_UPDATE_PATCH_ACTIVE' $wrapper.patch10Status 'Aktibo ang Patch 10 status'
Assert-StageTrue `
    -Condition ((Get-Stage21ArraySignature $wrapper.patch10LegacyWrongResult) -ne (Get-Stage21ArraySignature $wrapper.patch10CorrectedResult)) `
    -Name 'Hiwalay at divergent ang preserved raw in-place result at corrected snapshot result'
Assert-StageEqual (Get-Stage21ArraySignature $wrapperExpected) (Get-Stage21ArraySignature $actual) 'Wrapper ay nagbabalik ng corrected snapshot result'
Assert-StageEqual (Get-Stage21ArraySignature $actual) (Get-Stage21ArraySignature $wrapper.patch10CorrectedResult) 'Captured ang corrected Patch 10 result'

# 4. vaultOld is a physical clone, pending is the committed result, input remains unchanged.
Assert-StageEqual $originalSignature (Get-Stage21ArraySignature $wrapper.patch10VaultOld) 'vaultOld ay value-equal sa original bowls'
Assert-StageTrue `
    -Condition (-not [object]::ReferenceEquals($wrapper.patch10VaultOld, $original)) `
    -Name 'vaultOld ay pisikal na hiwalay na clone'
Assert-StageEqual (Get-Stage21ArraySignature $actual) (Get-Stage21ArraySignature $wrapper.patch10Pending) 'pending ay ang committed six-position result'
Assert-StageEqual (Get-Stage21ArraySignature $actual) (Get-Stage21ArraySignature $wrapper.patch10CorrectedResult) 'corrected result ay pending batch result'
Assert-StageEqual $originalSignature (Get-Stage21ArraySignature $wrapper.legacyInitialBowls) 'Hindi binago ang original initial bowls'

# 5. All six positions are committed from the snapshot as one completed batch.
for ($position = 1; $position -le 6; $position++) {
    $bowlId = [int]$wrapper.patch08OrderTable[1][$position - 1]
    Assert-StageEqual `
        ([System.Numerics.BigInteger]$wrapperExpected[$bowlId]) `
        ([System.Numerics.BigInteger]$actual[$bowlId]) `
        "GREEN ang committed Patch 10 bowl sa position $position"
}

# 6. Patch state is invocation-local.
$clean = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
Assert-StageTrue -Condition ($null -eq $clean.patch10DropIndex) -Name 'Walang Patch 10 drop-index leak'
Assert-StageTrue -Condition ($null -eq $clean.patch10VaultOld) -Name 'Walang Patch 10 vaultOld leak'
Assert-StageTrue -Condition ($null -eq $clean.patch10Pending) -Name 'Walang Patch 10 pending leak'
Assert-StageTrue -Condition ($null -eq $clean.patch10LegacyWrongResult) -Name 'Walang Patch 10 legacy-wrong leak'
Assert-StageTrue -Condition ($null -eq $clean.patch10CorrectedResult) -Name 'Walang Patch 10 corrected-result leak'
Assert-StageTrue -Condition (-not $clean.patch10CommitAfterSix) -Name 'Walang Patch 10 commit-after-six leak'
Assert-StageTrue -Condition (-not $clean.patch10Applied) -Name 'Hindi applied ang Patch 10 sa bagong invocation'
Assert-StageEqual 0 $clean.patch10InvocationCount 'Walang Patch 10 invocation-count leak'

# 7. Stage 15 sentinel remains present through the real Patch 07 table.
$sentinelRow = grindRowWithSentinel -Grind 1
Assert-StageTrue -Condition ($null -ne $sentinelRow) -Name 'Nananatiling available ang Stage 15 sentinel-backed grind table'

# 8. Observability neutrality.
$plain = New-Stage21ReadyContext -CalculationDay $foundation -TargetDay $target
$noisy = New-Stage21ReadyContext -CalculationDay $foundation -TargetDay $target
$noisy.logs.Add([pscustomobject]@{ code='noisy-before'; data=21 })
$noisy.logs.Add([pscustomobject]@{ code='noisy-before'; data=210 })
$noisy.metrics['observability.only'] = [System.Numerics.BigInteger]10100
$noisy.diagnostics.Add([pscustomobject]@{ code='diagnostic'; data=21 })

$plainResult = Invoke-Patch10SnapshotBowlUpdateRepair `
    -Context $plain -I 1 -Bowls $plain.legacyInitialBowls -Pours $plain.patch09CorrectedPours
$noisyResult = Invoke-Patch10SnapshotBowlUpdateRepair `
    -Context $noisy -I 1 -Bowls $noisy.legacyInitialBowls -Pours $noisy.patch09CorrectedPours

Assert-StageEqual (Get-Stage21ArraySignature $plainResult) (Get-Stage21ArraySignature $noisyResult) 'Hindi binabago ng observability state ang snapshot Patch 10'

# 9. Real production route.
$ctx = Invoke-CalendarDateSpaghetti -CalculationDay $foundation -TargetDay $target

Assert-StageEqual 'SAVE_PATCH_ACTIVE' $ctx.patch01Status 'Nananatiling aktibo ang Patch 01 sa Stage 21'
Assert-StageEqual 'DAY_TAG_PATCH_ACTIVE' $ctx.patch02Status 'Nananatiling aktibo ang Patch 02 sa Stage 21'
Assert-StageEqual 'DISTANCE_PATCH_ACTIVE' $ctx.patch03Status 'Nananatiling aktibo ang Patch 03 sa Stage 21'
Assert-StageEqual 'STONE_PATCH_ACTIVE' $ctx.patch04Status 'Nananatiling aktibo ang Patch 04 sa Stage 21'
Assert-StageEqual 'HIDDEN_NEARNESS_PATCH_ACTIVE' $ctx.patch05Status 'Nananatiling aktibo ang Patch 05 sa Stage 21'
Assert-StageEqual 'PRIOR_PATCH_ACTIVE' $ctx.patch06Status 'Nananatiling aktibo ang Patch 06 sa Stage 21'
Assert-StageEqual 'SENTINEL_GRIND_PATCH_ACTIVE' $ctx.patch07Status 'Nananatiling aktibo ang Patch 07 sa Stage 21'
Assert-StageEqual 'PERMUTATION_RANK_PATCH_ACTIVE' $ctx.patch08Status 'Nananatiling aktibo ang Patch 08 sa Stage 21'
Assert-StageEqual 'BOWL_ALIAS_PATCH_ACTIVE' $ctx.patch09Status 'Nananatiling aktibo ang Patch 09 sa Stage 21'

Assert-StageEqual 'IN_PLACE_BOWL_UPDATE_CONTAMINATION_PRESERVED' $ctx.discovery10Status 'Preserved ang Discovery 10 scar sa Stage 21 production route'
Assert-StageEqual 1 $ctx.discovery10InvocationCount 'Eksaktong isang raw Discovery 10 production scar call'
Assert-StageEqual 'SNAPSHOT_BOWL_UPDATE_PATCH_ACTIVE' $ctx.patch10Status 'Aktibo ang Patch 10 sa production route'
Assert-StageEqual 1 $ctx.patch10InvocationCount 'Eksaktong isang Patch 10 production invocation'
Assert-StageEqual 1 $ctx.patch10DropIndex 'Production Patch 10 drop index ay 1'
Assert-StageTrue -Condition $ctx.patch10CommitAfterSix -Name 'Production Patch 10 commit-after-six ay true'
Assert-StageTrue `
    -Condition ((Get-Stage21ArraySignature $ctx.patch10LegacyWrongResult) -ne (Get-Stage21ArraySignature $ctx.patch10CorrectedResult)) `
    -Name 'Production raw Discovery 10 scar ay divergent bago snapshot correction'
Assert-StageEqual (Get-Stage21ArraySignature $ctx.patch10CorrectedResult) (Get-Stage21ArraySignature $ctx.patch10ProductionResult) 'Production result ay corrected Patch 10 snapshot result'
Assert-StageEqual (Get-Stage21ArraySignature $ctx.patch10LegacyWrongResult) (Get-Stage21ArraySignature $ctx.legacyBowlUpdateProductionResult) 'Raw Discovery 10 production scar remains separately observable'
Assert-StageEqual (Get-Stage21ArraySignature $ctx.patch10CorrectedResult) (Get-Stage21ArraySignature $ctx.legacyBowlUpdateLastResult) 'Legacy bowl-update last result now exposes corrected Patch 10 result'
Assert-StageTrue -Condition $ctx.metrics.ContainsKey('patch10.bowlUpdate.probes') -Name 'May Patch 10 production probe metric'
Assert-StageEqual ([System.Numerics.BigInteger]1) $ctx.metrics['patch10.bowlUpdate.probes'] 'Eksaktong isang Patch 10 production probe metric increment'

# 10. Physical source contract, no oracle, no Patch 11/future logic.
$monsterText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/MonsterSkeleton.ps1')
$discovery10Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Discovery10.ps1')
$patch10Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Patch10.ps1')

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
    'src/Discovery10.ps1','src/Patch10.ps1'
)
$productionText = $monsterText
foreach ($rel in $productionFiles) {
    $productionText += "`n" + (Get-Content -Raw -Encoding UTF8 (Join-Path $root $rel))
}

Assert-StageTrue -Condition ($productionText -notmatch 'Get-NormBowlOrderFromDrop|Get-NormPermutationUnrank1|Invoke-NormSauce|Get-NormCalendarDate') -Name 'Hindi tumatawag sa normative oracle ang Stage 21 production path'
Assert-StageTrue -Condition ($discovery10Text -match 'function legacyInPlaceBowlUpdateWrong') -Name 'Nananatiling pisikal ang raw Discovery 10 helper'
Assert-StageTrue -Condition ($patch10Text -match 'function snapshotBowlUpdatePatched') -Name 'Pisikal ang snapshot Patch 10 helper'
Assert-StageTrue -Condition ($patch10Text -match 'function Invoke-Patch10SnapshotBowlUpdateRepair') -Name 'Pisikal ang Patch 10 wrapper'
Assert-StageTrue -Condition ($patch10Text -match 'legacyInPlaceBowlUpdateWrong') -Name 'Talagang tinatawag muna ng Patch 10 wrapper ang raw Discovery 10 scar'
Assert-StageTrue -Condition ($patch10Text -match '\$vaultOld\[\$bowlId\]') -Name 'Current-bowl reads ay mula sa vaultOld'
Assert-StageTrue -Condition ($patch10Text -match '\$vaultOld\[\$prevId\]') -Name 'Previous-bowl reads ay mula sa vaultOld'
Assert-StageTrue -Condition ($patch10Text -match '\$vaultOld\[\$nextId\]') -Name 'Next-bowl reads ay mula sa vaultOld'
Assert-StageTrue -Condition ($patch10Text -match '\$pending\[\$bowlId\]') -Name 'Lahat ng writes ay sa pending table'
Assert-StageTrue -Condition ($monsterText -match 'Invoke-Patch10SnapshotBowlUpdateRepair') -Name 'Dumadaan ang tunay na production route sa Patch 10 wrapper'

$futureNames = @(
    'orderAt46Latch',
    'biasedLegacyPick',
    'LEGACY_YEAR_MAX',
    'VirtualLegacyList',
    'oldContiguousMonthDayGuess'
)
foreach ($name in $futureNames) {
    Assert-StageTrue -Condition ($productionText -notmatch [regex]::Escape($name)) -Name "Wala pang Patch 11 o mas huling patch code: $name"
}

Write-Host 'PATCH10_RAW_DISCOVERY10_SCAR=PRESERVED_AND_CALLED'
Write-Host 'PATCH10_VAULT_OLD=PHYSICAL_CLONE'
Write-Host 'PATCH10_READ_SOURCE=VAULT_OLD_ONLY'
Write-Host 'PATCH10_WRITE_TARGET=PENDING_ONLY'
Write-Host 'PATCH10_COMMIT_AFTER_SIX=YES'
Write-Host 'PATCH10_SIX_POSITIONS_GREEN=6'
Write-Host 'PATCH10_PRODUCTION_I=1'
Write-Host 'PATCH10_PATCH11_ORDER_AT_46=ABSENT'
Write-Host 'STAGE21_REPOSITORY_STATE=GREEN'

$ok = Complete-StageTestRun
if (-not $ok) { exit 1 }
Write-Host 'STAGE21_RESULT=PASS'
exit 0
