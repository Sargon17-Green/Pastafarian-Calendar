Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

. (Join-Path $root 'src/SourceLanguageCatalog.ps1')
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

function Get-Stage11NormHiddenCoeff {
    param([Parameter(Mandatory)][int]$K)
    switch ($K) {
        1 { return ,([int[]](3,4,6,8)) }
        2 { return ,([int[]](5,7,10,12)) }
        3 { return ,([int[]](7,10,14,16)) }
        4 { return ,([int[]](9,13,18,20)) }
        5 { return ,([int[]](11,16,22,24)) }
        6 { return ,([int[]](13,19,26,28)) }
        7 { return ,([int[]](15,22,30,32)) }
        default { throw 'Stage 11 normative hidden k must be 1..7.' }
    }
}

function Get-Stage11NormHiddenValues {
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$CalculationDay,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$TargetDay
    )

    $counts = Get-NormWorkCounts $CalculationDay $TargetDay
    $stones = New-NormStoneTable
    $stoneKinds = [int[]](0,1,2,3,4,0,1)
    $hidden = [object[]]::new(8)

    for ($k = 1; $k -le 7; $k++) {
        $coeff = Get-Stage11NormHiddenCoeff -K $k
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

function New-Stage11ReadyHiddenContext {
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$CalculationDay,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$TargetDay
    )

    $ctx = New-BaseMonsterContext -CalculationDay $CalculationDay -TargetDay $TargetDay
    $p1 = Invoke-Patch01SaveAdapter -Context $ctx -Value $ctx.calculationDay
    $p2 = Invoke-Patch02DayTagAdapter -Context $p1
    $p3 = Invoke-Patch03DistanceAdapter -Context $p2
    $p4 = Invoke-Patch04StoneAdapter -Context $p3
    return Invoke-Discovery05LegacyHiddenAdapter -Context $p4
}

$foundation = Get-NormFoundationDay
$target = $foundation + 3
$metadata = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')

Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_STAGE=11\s*$') -Name 'Stage 11 ang kasalukuyang stage'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_KIND=PATCH\s*$') -Name 'Patch ang kasalukuyang uri'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_PATCH=05\s*$') -Name 'Patch 05 ang kasalukuyang patch slot'
Assert-StageTrue -Condition ($metadata -match '(?m)^LAST_COMPLETED_STAGE=10\s*$') -Name 'Hindi pa minamarkahang kumpleto ang Stage 11 bago runtime'
Assert-StageTrue -Condition ($metadata -match '(?m)^EXPECTED_REPOSITORY_STATE=GREEN\s*$') -Name 'GREEN ang inaasahang Stage 11 repository state'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE10_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED\s*$') -Name 'Nananatiling nakatala ang Stage 10 expected-red proof'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE11_PATCH=HIDDEN_BY_NEARNESS\s*$') -Name 'Patch 05 metadata ay hiddenByNearness'

$raw = New-Stage11ReadyHiddenContext -CalculationDay $foundation -TargetDay $target
$normative = Get-Stage11NormHiddenValues -CalculationDay $foundation -TargetDay $target

# 1. Panatilihin ang physical backward storage.
Assert-StageEqual $normative[7] $raw.legacyHiddenStorage[1] 'Physical slot 1 ay nananatiling hidden7'
Assert-StageEqual $normative[6] $raw.legacyHiddenStorage[2] 'Physical slot 2 ay nananatiling hidden6'
Assert-StageEqual $normative[5] $raw.legacyHiddenStorage[3] 'Physical slot 3 ay nananatiling hidden5'
Assert-StageEqual $normative[4] $raw.legacyHiddenStorage[4] 'Physical slot 4 ay nananatiling hidden4'
Assert-StageEqual $normative[3] $raw.legacyHiddenStorage[5] 'Physical slot 5 ay nananatiling hidden3'
Assert-StageEqual $normative[2] $raw.legacyHiddenStorage[6] 'Physical slot 6 ay nananatiling hidden2'
Assert-StageEqual $normative[1] $raw.legacyHiddenStorage[7] 'Physical slot 7 ay nananatiling hidden1'

# 2. Panatilihin ang wrong direct accessor bilang totoong historical scar.
$wrongK1 = [System.Numerics.BigInteger](
    legacyHiddenDirectByAssumedNearness -LegacyHidden $raw.legacyHiddenStorage -K 1
)
Assert-StageEqual $normative[7] $wrongK1 'Ang raw direct accessor k=1 ay nananatiling hidden7'
Assert-StageTrue -Condition ($wrongK1 -ne $normative[1]) -Name 'Ang raw direct accessor k=1 ay nananatiling mali laban sa normative hidden1'

# 3. Ang 8-k translator mismo ay GREEN sa lahat ng pitong slots.
$translatorGreen = 0
for ($k = 1; $k -le 7; $k++) {
    $actual = [System.Numerics.BigInteger](
        hiddenByNearness -LegacyHidden $raw.legacyHiddenStorage -K $k
    )
    Assert-StageEqual $normative[$k] $actual "hiddenByNearness ay GREEN para sa k=$k"
    $translatorGreen++
}
Assert-StageEqual 7 $translatorGreen 'Eksaktong pitong translator slots ang GREEN'

# 4. Ang wrapper ay talagang nagpapatakbo muna ng maling accessor at pagkatapos ay nagko-correct.
$repairCtx = New-Stage11ReadyHiddenContext -CalculationDay $foundation -TargetDay $target
$actualK1 = [System.Numerics.BigInteger](
    Invoke-Patch05HiddenNearnessRepair -Context $repairCtx -K 1
)
Assert-StageEqual $normative[1] $actualK1 'Patch 05 k=1 authoritative result ay normative hidden1'
Assert-StageEqual 1 $repairCtx.patch05RequestedK 'Na-capture ang requested k=1'
Assert-StageEqual 7 $repairCtx.patch05TranslatedSlot 'Ang k=1 ay naisalin sa physical slot 7'
Assert-StageEqual $normative[7] $repairCtx.patch05LegacyDirectValue 'Na-capture muna ang maling direct legacy hidden7 scar'
Assert-StageEqual $normative[1] $repairCtx.patch05CorrectedValue 'Na-capture ang corrected hidden1 value'
Assert-StageTrue -Condition $repairCtx.patch05Applied -Name 'Naka-markang applied ang Patch 05'
Assert-StageEqual 'HIDDEN_NEARNESS_PATCH_ACTIVE' $repairCtx.patch05Status 'Aktibo ang Patch 05 status'
Assert-StageEqual 1 $repairCtx.patch05InvocationCount 'Isang Patch 05 invocation para sa isang repair call'
Assert-StageEqual $normative[1] $repairCtx.legacyHiddenLastReturnedValue 'Ang authoritative hidden last-returned value ay corrected'

# 5. Lahat ng pitong wrapper reads ay GREEN.
$allCtx = New-Stage11ReadyHiddenContext -CalculationDay $foundation -TargetDay $target
$wrapperGreen = 0
for ($k = 1; $k -le 7; $k++) {
    $actual = [System.Numerics.BigInteger](
        Invoke-Patch05HiddenNearnessRepair -Context $allCtx -K $k
    )
    Assert-StageEqual $normative[$k] $actual "Patch 05 wrapper ay GREEN para sa k=$k"
    $wrapperGreen++
}
Assert-StageEqual 7 $wrapperGreen 'Eksaktong pitong Patch 05 wrapper slots ang GREEN'
Assert-StageEqual 7 $allCtx.patch05RequestedK 'Huling requested k ay 7'
Assert-StageEqual 1 $allCtx.patch05TranslatedSlot 'Ang huling k=7 ay naisalin sa physical slot 1'
Assert-StageEqual $normative[1] $allCtx.patch05LegacyDirectValue 'Sa k=7, ang raw direct scar ay hidden1'
Assert-StageEqual $normative[7] $allCtx.patch05CorrectedValue 'Sa k=7, ang corrected value ay hidden7'

# 6. Production route at lahat ng naunang patches.
$ctx = Invoke-CalendarDateSpaghetti -CalculationDay $foundation -TargetDay $target
Assert-StageEqual 'SAVE_PATCH_ACTIVE' $ctx.patch01Status 'Nananatiling aktibo ang Patch 01 sa Stage 11 production route'
Assert-StageEqual (Get-NormSave -X $foundation) $ctx.patch01PatchedValue 'Nananatiling GREEN ang Patch 01 sa Stage 11'
Assert-StageEqual 'DAY_TAG_PATCH_ACTIVE' $ctx.patch02Status 'Nananatiling aktibo ang Patch 02 sa Stage 11'
Assert-StageEqual (Get-NormDayCount -Day $foundation) $ctx.patch02ActionDayTag 'Nananatiling GREEN ang Patch 02 action sa Stage 11'
Assert-StageEqual (Get-NormDayCount -Day $target) $ctx.patch02TargetDayTag 'Nananatiling GREEN ang Patch 02 target sa Stage 11'
Assert-StageEqual 'DISTANCE_PATCH_ACTIVE' $ctx.patch03Status 'Nananatiling aktibo ang Patch 03 sa Stage 11'
Assert-StageEqual ([System.Numerics.BigInteger]4) $ctx.patch03DistanceValue 'Nananatiling GREEN ang Patch 03 sa Stage 11'
Assert-StageEqual 'STONE_PATCH_ACTIVE' $ctx.patch04Status 'Nananatiling aktibo ang Patch 04 sa Stage 11'
Assert-StageEqual 45 $ctx.patch04RowsPatched 'Nananatiling 45 ang patched stone rows sa Stage 11'
Assert-StageEqual 'BACKWARD_HIDDEN_STORAGE_ACTIVE' $ctx.discovery05Status 'Nananatiling aktibo ang backward Discovery 05 storage scar'
Assert-StageEqual 'HIDDEN_NEARNESS_PATCH_ACTIVE' $ctx.patch05Status 'Aktibo ang Patch 05 sa production route'
Assert-StageEqual 1 $ctx.patch05RequestedK 'Ang production route ay talagang humihiling ng k=1'
Assert-StageEqual 7 $ctx.patch05TranslatedSlot 'Ang production k=1 ay isinasalin sa slot 7'
Assert-StageEqual $normative[7] $ctx.patch05LegacyDirectValue 'Ang production route ay talagang kumukuha muna ng wrong hidden7 scar'
Assert-StageEqual $normative[1] $ctx.patch05CorrectedValue 'Ang production authoritative result ay hidden1'
Assert-StageEqual $normative[1] $ctx.legacyHiddenLastReturnedValue 'Corrected ang production hidden last-returned value'

# 7. Invocation ownership.
$clean = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
Assert-StageTrue -Condition ($null -eq $clean.patch05RequestedK) -Name 'Walang Patch 05 requested-k leak'
Assert-StageTrue -Condition ($null -eq $clean.patch05TranslatedSlot) -Name 'Walang Patch 05 translated-slot leak'
Assert-StageTrue -Condition ($null -eq $clean.patch05LegacyDirectValue) -Name 'Walang Patch 05 raw-scar leak'
Assert-StageTrue -Condition ($null -eq $clean.patch05CorrectedValue) -Name 'Walang Patch 05 corrected-value leak'
Assert-StageTrue -Condition (-not $clean.patch05Applied) -Name 'Hindi applied ang Patch 05 sa bagong invocation'
Assert-StageEqual 0 $clean.patch05InvocationCount 'Walang Patch 05 invocation-count leak'

Assert-StageEqual 1 $ctx.semanticCommitted['patch05RequestedK'] 'Committed ang production Patch 05 requested k'
Assert-StageEqual 7 $ctx.semanticCommitted['patch05TranslatedSlot'] 'Committed ang production translated slot'
Assert-StageEqual $normative[7] $ctx.semanticCommitted['patch05LegacyDirectValue'] 'Committed ang raw direct scar value'
Assert-StageEqual $normative[1] $ctx.semanticCommitted['patch05CorrectedValue'] 'Committed ang corrected value'
Assert-StageTrue -Condition $ctx.semanticCommitted['patch05Applied'] -Name 'Committed ang Patch 05 applied flag'

# 8. Observability neutrality.
$plain = New-Stage11ReadyHiddenContext -CalculationDay ($foundation - 5) -TargetDay ($foundation + 8)
$noisy = New-Stage11ReadyHiddenContext -CalculationDay ($foundation - 5) -TargetDay ($foundation + 8)
$noisy.logs.Add([pscustomobject]@{ code='noisy-before'; data=1 })
$noisy.metrics['observability.only'] = [System.Numerics.BigInteger]5151
$noisy.diagnostics.Add([pscustomobject]@{ code='diagnostic'; data=11 })
$plainValue = Invoke-Patch05HiddenNearnessRepair -Context $plain -K 7
$noisyValue = Invoke-Patch05HiddenNearnessRepair -Context $noisy -K 7
Assert-StageEqual $plainValue $noisyValue 'Hindi binabago ng observability state ang Patch 05 result'

# 9. Production purity, preserved scars, at walang Stage 12+.
$monsterText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/MonsterSkeleton.ps1')
$discovery05Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Discovery05.ps1')
$patch05Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Patch05.ps1')
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
    'src/Patch05.ps1'
)
$productionText = $monsterText
foreach ($rel in $productionFiles) {
    $productionText += "`n" + (Get-Content -Raw -Encoding UTF8 (Join-Path $root $rel))
}

Assert-StageTrue -Condition ($productionText -notmatch 'Invoke-NormSauce|Get-NormCalendarDate|Get-NormSave|New-NormStoneTable') -Name 'Hindi tumatawag sa normative oracle ang Stage 11 production path'
Assert-StageTrue -Condition ($discovery05Text -match 'function legacyHiddenDirectByAssumedNearness') -Name 'Nananatiling pisikal ang wrong direct accessor scar'
Assert-StageTrue -Condition ($discovery05Text -match '\$legacyHidden\[8 - \$k\]') -Name 'Nananatiling pisikal na backward ang hidden storage'
Assert-StageTrue -Condition ($patch05Text -match 'function hiddenByNearness') -Name 'Pisikal at hiwalay ang hiddenByNearness Patch 05 translator'
Assert-StageTrue -Condition ($patch05Text -match 'legacyHiddenDirectByAssumedNearness') -Name 'Talagang tinatawag ng Patch 05 ang wrong direct accessor'
Assert-StageTrue -Condition ($patch05Text -match '\$LegacyHidden\[8 - \$K\]') -Name 'Ang Patch 05 translator ay eksaktong gumagamit ng physical slot 8-k'
Assert-StageTrue -Condition ($monsterText -match 'Invoke-Patch05HiddenNearnessRepair') -Name 'Dumadaan ang tunay na production route sa Patch 05'

$futureNames = @(
    'legacyPrior',
    'priorPatch',
    'LegacyPriorAdapter',
    'orderAt46Latch',
    'biasedLegacyPick',
    'LEGACY_YEAR_MAX',
    'VirtualLegacyList',
    'oldContiguousMonthDayGuess'
)
foreach ($name in $futureNames) {
    Assert-StageTrue -Condition ($productionText -notmatch [regex]::Escape($name)) -Name "Walang future patch code: $name"
}

Write-Host "PATCH05_TRANSLATOR_GREEN_COUNT=$translatorGreen"
Write-Host "PATCH05_WRAPPER_GREEN_COUNT=$wrapperGreen"
Write-Host 'PATCH05_BACKWARD_STORAGE=PRESERVED'
Write-Host 'PATCH05_WRONG_DIRECT_ACCESSOR=PRESERVED_AND_CALLED'
Write-Host 'PATCH05_PRODUCTION_K1_TRANSLATED_SLOT=7'
Write-Host 'STAGE11_REPOSITORY_STATE=GREEN'

$ok = Complete-StageTestRun
if (-not $ok) { exit 1 }
Write-Host 'STAGE11_RESULT=PASS'
exit 0
