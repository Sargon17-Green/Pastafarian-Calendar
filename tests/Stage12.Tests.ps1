Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

. (Join-Path $root 'src/SourceLanguageCatalog.ps1')
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

function Get-Stage12NormHiddenCoeff {
    param([Parameter(Mandatory)][int]$K)
    switch ($K) {
        1 { return ,([int[]](3,4,6,8)) }
        2 { return ,([int[]](5,7,10,12)) }
        3 { return ,([int[]](7,10,14,16)) }
        4 { return ,([int[]](9,13,18,20)) }
        5 { return ,([int[]](11,16,22,24)) }
        6 { return ,([int[]](13,19,26,28)) }
        7 { return ,([int[]](15,22,30,32)) }
        default { throw 'Stage 12 normative hidden k must be 1..7.' }
    }
}

function Get-Stage12NormHiddenValues {
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$CalculationDay,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$TargetDay
    )

    $counts = Get-NormWorkCounts $CalculationDay $TargetDay
    $stones = New-NormStoneTable
    $stoneKinds = [int[]](0,1,2,3,4,0,1)
    $hidden = [object[]]::new(8)

    for ($k = 1; $k -le 7; $k++) {
        $coeff = Get-Stage12NormHiddenCoeff -K $k
        $row = $stones[$k]
        $sum = [System.Numerics.BigInteger]::Zero
        for ($j = 1; $j -le 5; $j++) {
            $sum += [System.Numerics.BigInteger]$row[$j]
        }

        $x = [System.Numerics.BigInteger](
            [System.Numerics.BigInteger]$counts.action +
            [System.Numerics.BigInteger]$coeff[0] * [System.Numerics.BigInteger]$counts.target +
            [System.Numerics.BigInteger]$coeff[1] * [System.Numerics.BigInteger]$counts.distance +
            [System.Numerics.BigInteger]$coeff[2] * [System.Numerics.BigInteger]$counts.connection +
            [System.Numerics.BigInteger]$coeff[3] * [System.Numerics.BigInteger]$counts.direction +
            $sum
        )
        $x = [System.Numerics.BigInteger](Get-NormSave -X $x)

        for ($grind = 1; $grind -le 7; $grind++) {
            $before = [System.Numerics.BigInteger]$x
            $kind = $stoneKinds[$grind - 1] + 1
            $x = [System.Numerics.BigInteger](Get-NormSave -X (
                $before * $before +
                3 * $before +
                [System.Numerics.BigInteger]$row[$kind] +
                $grind
            ))
        }

        $hidden[$k] = $x
    }

    return ,$hidden
}

$foundation = Get-NormFoundationDay
$target = $foundation + 3
$metadata = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')

Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_STAGE=12\s*$') -Name 'Stage 12 ang kasalukuyang stage'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_KIND=DISCOVERY\s*$') -Name 'Discovery ang kasalukuyang uri'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_PATCH=06\s*$') -Name 'Discovery 06 ang kasalukuyang patch slot'
Assert-StageTrue -Condition ($metadata -match '(?m)^LAST_COMPLETED_STAGE=11\s*$') -Name 'Hindi pa minamarkahang kumpleto ang Stage 12 bago runtime'
Assert-StageTrue -Condition ($metadata -match '(?m)^EXPECTED_REPOSITORY_STATE=RED\s*$') -Name 'RED ang inaasahang Stage 12 repository state'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE11_RUNTIME_VERIFICATION=GREEN_CONFIRMED\s*$') -Name 'Nananatiling nakatala ang Stage 11 GREEN proof'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE12_DISCOVERY=LEGACY_PRIOR_VISIBLE_ONLY\s*$') -Name 'Discovery 06 metadata ay visible-only legacyPrior'

# Valid visible slots still work.
$validCtx = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $foundation
$validStore = @{
    1 = [System.Numerics.BigInteger]101
    2 = [System.Numerics.BigInteger]202
    3 = [System.Numerics.BigInteger]303
}
$validA = Invoke-Discovery06LegacyPriorAdapter -Context $validCtx -DropStore $validStore -I 4 -Back 1
$validB = Invoke-Discovery06LegacyPriorAdapter -Context $validCtx -DropStore $validStore -I 4 -Back 3
Assert-StageEqual ([System.Numerics.BigInteger]303) $validA 'Nababasa pa rin ng legacyPrior ang valid visible slot 3'
Assert-StageEqual ([System.Numerics.BigInteger]101) $validB 'Nababasa pa rin ng legacyPrior ang valid visible slot 1'

# Missing hidden history leaves the scar state on the nonpositive slot.
$missingCtx = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $foundation
$emptyStore = @{}
$missing = Invoke-Discovery06LegacyPriorAdapter -Context $missingCtx -DropStore $emptyStore -I 1 -Back 1
Assert-StageTrue -Condition ($null -eq $missing) -Name 'Walang value ang raw legacyPrior sa missing slot 0'
Assert-StageEqual 1 $missingCtx.legacyPriorI 'Na-capture ang i=1 sa missing-history scar'
Assert-StageEqual 1 $missingCtx.legacyPriorBack 'Na-capture ang back=1 sa missing-history scar'
Assert-StageEqual 0 $missingCtx.legacyPriorSlot 'Na-capture ang nonpositive slot 0'
Assert-StageTrue -Condition ($null -eq $missingCtx.legacyPriorValue) -Name 'Nananatiling null ang missing-history legacy value'

# Exact Stage 12 expected-red surface.
$normativeHidden = Get-Stage12NormHiddenValues -CalculationDay $foundation -TargetDay $target
$cases = @(
    [pscustomobject]@{ i = 1; back = 1; slot = 0; hiddenK = 1 },
    [pscustomobject]@{ i = 1; back = 3; slot = -2; hiddenK = 3 },
    [pscustomobject]@{ i = 1; back = 7; slot = -6; hiddenK = 7 }
)

$expectedRedCount = 0
$matchCount = 0
foreach ($case in $cases) {
    $probeCtx = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
    $actual = Invoke-Discovery06LegacyPriorAdapter `
        -Context $probeCtx `
        -DropStore @{} `
        -I $case.i `
        -Back $case.back

    $expected = [System.Numerics.BigInteger]$normativeHidden[$case.hiddenK]
    Assert-StageEqual $case.slot $probeCtx.legacyPriorSlot "Tamang legacy slot para sa back=$($case.back)"
    Assert-StageTrue -Condition ($null -eq $actual) -Name "Raw visible-only prior ay walang hidden fallback para sa slot=$($case.slot)"

    if ($null -ne $actual -and $actual -eq $expected) {
        $matchCount++
        Write-Host "DISCOVERY06_SLOT=$($case.slot) HIDDEN_K=$($case.hiddenK) CLASSIFICATION=MATCH"
    }
    else {
        $expectedRedCount++
        Write-Host "DISCOVERY06_SLOT=$($case.slot) HIDDEN_K=$($case.hiddenK) CLASSIFICATION=EXPECTED_RED ERROR_ID=Pastafari:Discovery06:MissingHiddenHistory"
    }
}

Assert-StageEqual 3 $expectedRedCount 'Eksaktong tatlong Discovery 06 EXPECTED_RED hidden-history probes'
Assert-StageEqual 0 $matchCount 'Walang Discovery 06 hidden-history probe na MATCH bago Patch 06'

# Real production route uses a valid slot-1 probe and keeps all earlier patches green.
$ctx = Invoke-CalendarDateSpaghetti -CalculationDay $foundation -TargetDay $target
Assert-StageEqual 'SAVE_PATCH_ACTIVE' $ctx.patch01Status 'Nananatiling aktibo ang Patch 01 sa Stage 12 production route'
Assert-StageEqual (Get-NormSave -X $foundation) $ctx.patch01PatchedValue 'Nananatiling GREEN ang Patch 01 sa Stage 12'
Assert-StageEqual 'DAY_TAG_PATCH_ACTIVE' $ctx.patch02Status 'Nananatiling aktibo ang Patch 02 sa Stage 12'
Assert-StageEqual (Get-NormDayCount -Day $foundation) $ctx.patch02ActionDayTag 'Nananatiling GREEN ang Patch 02 action sa Stage 12'
Assert-StageEqual (Get-NormDayCount -Day $target) $ctx.patch02TargetDayTag 'Nananatiling GREEN ang Patch 02 target sa Stage 12'
Assert-StageEqual 'DISTANCE_PATCH_ACTIVE' $ctx.patch03Status 'Nananatiling aktibo ang Patch 03 sa Stage 12'
Assert-StageEqual ([System.Numerics.BigInteger]4) $ctx.patch03DistanceValue 'Nananatiling GREEN ang Patch 03 sa Stage 12'
Assert-StageEqual 'STONE_PATCH_ACTIVE' $ctx.patch04Status 'Nananatiling aktibo ang Patch 04 sa Stage 12'
Assert-StageEqual 45 $ctx.patch04RowsPatched 'Nananatiling 45 ang patched stone rows sa Stage 12'
Assert-StageEqual 'BACKWARD_HIDDEN_STORAGE_ACTIVE' $ctx.discovery05Status 'Nananatiling aktibo ang Discovery 05 storage scar'
Assert-StageEqual 'HIDDEN_NEARNESS_PATCH_ACTIVE' $ctx.patch05Status 'Nananatiling aktibo ang Patch 05 sa Stage 12'
Assert-StageEqual $normativeHidden[1] $ctx.patch05CorrectedValue 'Nananatiling GREEN ang Patch 05 production k=1'

Assert-StageEqual 'VISIBLE_ONLY_PRIOR_ACTIVE' $ctx.discovery06Status 'Aktibo ang Discovery 06 adapter sa production route'
Assert-StageEqual 1 $ctx.discovery06InvocationCount 'Eksaktong isang legacyPrior production probe'
Assert-StageEqual 2 $ctx.legacyPriorI 'Ang production probe i ay eksaktong 2'
Assert-StageEqual 1 $ctx.legacyPriorBack 'Ang production probe back ay eksaktong 1'
Assert-StageEqual 1 $ctx.legacyPriorSlot 'Ang production probe ay valid visible slot 1'
Assert-StageEqual $ctx.patch05CorrectedValue $ctx.legacyPriorValue 'Ang valid production legacyPrior read ay bumabasa sa probe slot 1'
Assert-StageEqual $ctx.patch05CorrectedValue $ctx.legacyPriorProbeValue 'Ang production probe value ay hindi binabago ang Patch 05 value'
Assert-StageTrue -Condition $ctx.metrics.ContainsKey('discovery06.prior.probes') -Name 'May production probe metric'
Assert-StageEqual ([System.Numerics.BigInteger]1) $ctx.metrics['discovery06.prior.probes'] 'Eksaktong isang production probe metric increment'

# Invocation ownership.
$clean = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
Assert-StageTrue -Condition ($null -eq $clean.legacyPriorI) -Name 'Walang legacy prior i leak'
Assert-StageTrue -Condition ($null -eq $clean.legacyPriorBack) -Name 'Walang legacy prior back leak'
Assert-StageTrue -Condition ($null -eq $clean.legacyPriorSlot) -Name 'Walang legacy prior slot leak'
Assert-StageTrue -Condition ($null -eq $clean.legacyPriorValue) -Name 'Walang legacy prior value leak'
Assert-StageTrue -Condition ($null -eq $clean.legacyPriorProbeValue) -Name 'Walang production probe value leak'
Assert-StageEqual 0 $clean.discovery06InvocationCount 'Walang Discovery 06 invocation-count leak'

# Observability state cannot change a valid visible read.
$plain = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
$noisy = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
$noisy.logs.Add([pscustomobject]@{ code='noisy-before'; data=12 })
$noisy.metrics['observability.only'] = [System.Numerics.BigInteger]1212
$noisy.diagnostics.Add([pscustomobject]@{ code='diagnostic'; data=12 })
$plainValue = Invoke-Discovery06LegacyPriorAdapter -Context $plain -DropStore $validStore -I 4 -Back 1
$noisyValue = Invoke-Discovery06LegacyPriorAdapter -Context $noisy -DropStore $validStore -I 4 -Back 1
Assert-StageEqual $plainValue $noisyValue 'Hindi binabago ng observability state ang raw legacyPrior result'

# Production purity and no Stage 13+ correction.
$monsterText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/MonsterSkeleton.ps1')
$discovery06Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Discovery06.ps1')
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
    'src/Discovery06.ps1'
)
$productionText = $monsterText
foreach ($rel in $productionFiles) {
    $productionText += "`n" + (Get-Content -Raw -Encoding UTF8 (Join-Path $root $rel))
}

Assert-StageTrue -Condition ($productionText -notmatch 'Invoke-NormSauce|Get-NormCalendarDate|Get-NormSave|New-NormStoneTable') -Name 'Hindi tumatawag sa normative oracle ang Stage 12 production path'
Assert-StageTrue -Condition ($discovery06Text -match 'function legacyPrior') -Name 'Pisikal ang raw legacyPrior helper'
Assert-StageTrue -Condition ($discovery06Text -match '\$DropStore\[\$I - \$Back\]') -Name 'Eksaktong visible dropStore[i-back] ang raw legacyPrior access'
Assert-StageTrue -Condition ($monsterText -match 'Invoke-Discovery06LegacyPriorAdapter') -Name 'Dumadaan ang tunay na production route sa Discovery 06 adapter'
Assert-StageTrue -Condition ($monsterText -match '\-I 2') -Name 'Eksaktong i=2 ang production probe'
Assert-StageTrue -Condition ($monsterText -match '\-Back 1') -Name 'Eksaktong back=1 ang production probe'
Assert-StageTrue -Condition ($discovery06Text -notmatch 'hiddenByNearness') -Name 'Walang hiddenByNearness fallback sa Discovery 06'
Assert-StageTrue -Condition ($discovery06Text -notmatch 'priorPatch') -Name 'Wala pang Stage 13 priorPatch'
Assert-StageTrue -Condition ($discovery06Text -notmatch '1\s*-\s*\$slot') -Name 'Wala pang hiddenK=1-slot translation'

$futureNames = @(
    'orderAt46Latch',
    'biasedLegacyPick',
    'LEGACY_YEAR_MAX',
    'VirtualLegacyList',
    'oldContiguousMonthDayGuess'
)
foreach ($name in $futureNames) {
    Assert-StageTrue -Condition ($productionText -notmatch [regex]::Escape($name)) -Name "Walang future patch code: $name"
}

Write-Host "DISCOVERY06_EXPECTED_RED_COUNT=$expectedRedCount"
Write-Host "DISCOVERY06_MATCH_COUNT=$matchCount"
Write-Host 'DISCOVERY06_RED_SLOTS=0,-2,-6'
Write-Host 'DISCOVERY06_PRODUCTION_PROBE_SLOT=1'
Write-Host 'DISCOVERY06_HIDDEN_FALLBACK=ABSENT'
Write-Host 'STAGE12_REPOSITORY_STATE=EXPECTED_RED'

$ok = Complete-StageTestRun
if (-not $ok) { exit 1 }
Write-Host 'STAGE12_RESULT=PASS'
exit 0
