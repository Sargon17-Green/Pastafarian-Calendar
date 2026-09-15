Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

. (Join-Path $root 'src/SourceLanguageCatalog.ps1')
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

function Get-Stage13NormHiddenCoeff {
    param([Parameter(Mandatory)][int]$K)
    switch ($K) {
        1 { return ,([int[]](3,4,6,8)) }
        2 { return ,([int[]](5,7,10,12)) }
        3 { return ,([int[]](7,10,14,16)) }
        4 { return ,([int[]](9,13,18,20)) }
        5 { return ,([int[]](11,16,22,24)) }
        6 { return ,([int[]](13,19,26,28)) }
        7 { return ,([int[]](15,22,30,32)) }
        default { throw 'Stage 13 normative hidden k must be 1..7.' }
    }
}

function Get-Stage13NormHiddenValues {
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$CalculationDay,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$TargetDay
    )

    $counts = Get-NormWorkCounts $CalculationDay $TargetDay
    $stones = New-NormStoneTable
    $stoneKinds = [int[]](0,1,2,3,4,0,1)
    $hidden = [object[]]::new(8)

    for ($k = 1; $k -le 7; $k++) {
        $coeff = Get-Stage13NormHiddenCoeff -K $k
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

function New-Stage13ReadyHiddenContext {
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$CalculationDay,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$TargetDay
    )

    $ctx = New-BaseMonsterContext -CalculationDay $CalculationDay -TargetDay $TargetDay
    $p1 = Invoke-Patch01SaveAdapter -Context $ctx -Value $ctx.calculationDay
    $p2 = Invoke-Patch02DayTagAdapter -Context $p1
    $p3 = Invoke-Patch03DistanceAdapter -Context $p2
    $p4 = Invoke-Patch04StoneAdapter -Context $p3
    $d5 = Invoke-Discovery05LegacyHiddenAdapter -Context $p4
    [void](Invoke-Patch05HiddenNearnessRepair -Context $d5 -K 1)
    return $d5
}

$foundation = Get-NormFoundationDay
$target = $foundation + 3
$metadata = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')

Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_STAGE=13\s*$') -Name 'Stage 13 ang kasalukuyang stage'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_KIND=PATCH\s*$') -Name 'Patch ang kasalukuyang uri'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_PATCH=06\s*$') -Name 'Patch 06 ang kasalukuyang patch slot'
Assert-StageTrue -Condition ($metadata -match '(?m)^LAST_COMPLETED_STAGE=12\s*$') -Name 'Hindi pa minamarkahang kumpleto ang Stage 13 bago runtime'
Assert-StageTrue -Condition ($metadata -match '(?m)^EXPECTED_REPOSITORY_STATE=GREEN\s*$') -Name 'GREEN ang inaasahang Stage 13 repository state'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE12_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED\s*$') -Name 'Nananatiling nakatala ang Stage 12 expected-red proof'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE13_PATCH=PRIOR_PATCH_HIDDEN_FALLBACK\s*$') -Name 'Patch 06 metadata ay prior hidden fallback'

$normativeHidden = Get-Stage13NormHiddenValues -CalculationDay $foundation -TargetDay $target

# 1. Raw historical scar remains physically wrong.
$rawStore = @{
    1 = [System.Numerics.BigInteger]101
    2 = [System.Numerics.BigInteger]202
    3 = [System.Numerics.BigInteger]303
}
Assert-StageEqual ([System.Numerics.BigInteger]303) (legacyPrior -DropStore $rawStore -I 4 -Back 1) 'Nananatiling gumagana ang raw legacyPrior sa valid visible slot'
$rawMissing = legacyPrior -DropStore @{} -I 1 -Back 1
Assert-StageTrue -Condition ($null -eq $rawMissing) -Name 'Nananatiling walang hidden-history kaalaman ang raw legacyPrior sa slot 0'

# 2. Visible branch must really call legacyPrior and must not require hidden storage.
$script:Stage13OriginalLegacyPrior = (Get-Command legacyPrior -CommandType Function).ScriptBlock
$script:Stage13OriginalHiddenByNearness = (Get-Command hiddenByNearness -CommandType Function).ScriptBlock
$script:Stage13LegacyCalls = 0
$script:Stage13HiddenCalls = 0

Set-Item -Path Function:legacyPrior -Value {
    param(
        [hashtable]$DropStore,
        [int]$I,
        [int]$Back
    )
    $script:Stage13LegacyCalls++
    return & $script:Stage13OriginalLegacyPrior -DropStore $DropStore -I $I -Back $Back
}
Set-Item -Path Function:hiddenByNearness -Value {
    param(
        [AllowNull()][System.Array]$LegacyHidden,
        [int]$K
    )
    $script:Stage13HiddenCalls++
    return & $script:Stage13OriginalHiddenByNearness -LegacyHidden $LegacyHidden -K $K
}
try {
    $visibleResult = priorPatch -DropStore $rawStore -LegacyHidden $null -I 4 -Back 1
}
finally {
    Set-Item -Path Function:legacyPrior -Value $script:Stage13OriginalLegacyPrior
    Set-Item -Path Function:hiddenByNearness -Value $script:Stage13OriginalHiddenByNearness
}
Assert-StageEqual ([System.Numerics.BigInteger]303) $visibleResult 'GREEN ang Patch 06 visible branch nang walang hidden storage'
Assert-StageEqual 1 $script:Stage13LegacyCalls 'Eksaktong isang raw legacyPrior call sa visible branch'
Assert-StageEqual 0 $script:Stage13HiddenCalls 'Walang hiddenByNearness call sa visible branch'
$visibleLegacyCalls = $script:Stage13LegacyCalls

# 3. Exact hidden mapping, including the old Stage 12 red cases.
$ready = New-Stage13ReadyHiddenContext -CalculationDay $foundation -TargetDay $target
$hiddenCases = @(
    [pscustomobject]@{ i = 1; back = 1; slot = 0;  hiddenK = 1 },
    [pscustomobject]@{ i = 1; back = 3; slot = -2; hiddenK = 3 },
    [pscustomobject]@{ i = 1; back = 7; slot = -6; hiddenK = 7 },
    [pscustomobject]@{ i = 2; back = 3; slot = -1; hiddenK = 2 },
    [pscustomobject]@{ i = 4; back = 7; slot = -3; hiddenK = 4 }
)

$hiddenGreen = 0
foreach ($case in $hiddenCases) {
    $actual = priorPatch `
        -DropStore @{} `
        -LegacyHidden $ready.legacyHiddenStorage `
        -I $case.i `
        -Back $case.back
    Assert-StageEqual $case.slot ($case.i - $case.back) "Tamang computed slot para sa hiddenK=$($case.hiddenK)"
    Assert-StageEqual $normativeHidden[$case.hiddenK] $actual "GREEN ang priorPatch hiddenK=$($case.hiddenK)"
    $hiddenGreen++
}
Assert-StageEqual 5 $hiddenGreen 'Eksaktong limang hidden-branch mapping cases ang GREEN'

$stage12Cases = @(
    [pscustomobject]@{ i = 1; back = 1; hiddenK = 1 },
    [pscustomobject]@{ i = 1; back = 3; hiddenK = 3 },
    [pscustomobject]@{ i = 1; back = 7; hiddenK = 7 }
)
$stage12Green = 0
foreach ($case in $stage12Cases) {
    $ctxCase = New-Stage13ReadyHiddenContext -CalculationDay $foundation -TargetDay $target
    $actual = Invoke-Patch06LegacyPriorAdapter `
        -Context $ctxCase `
        -DropStore @{} `
        -I $case.i `
        -Back $case.back
    Assert-StageEqual $normativeHidden[$case.hiddenK] $actual "Stage 12 normative history case hiddenK=$($case.hiddenK) ay GREEN na"
    $stage12Green++
}
Assert-StageEqual 3 $stage12Green 'Eksaktong tatlong dating Stage 12 red cases ang GREEN'

# 4. Hidden branch must call hiddenByNearness exactly once and never legacyPrior.
$script:Stage13OriginalLegacyPrior = (Get-Command legacyPrior -CommandType Function).ScriptBlock
$script:Stage13OriginalHiddenByNearness = (Get-Command hiddenByNearness -CommandType Function).ScriptBlock
$script:Stage13LegacyCalls = 0
$script:Stage13HiddenCalls = 0
$script:Stage13LastHiddenK = $null

Set-Item -Path Function:legacyPrior -Value {
    param(
        [hashtable]$DropStore,
        [int]$I,
        [int]$Back
    )
    $script:Stage13LegacyCalls++
    return & $script:Stage13OriginalLegacyPrior -DropStore $DropStore -I $I -Back $Back
}
Set-Item -Path Function:hiddenByNearness -Value {
    param(
        [AllowNull()][System.Array]$LegacyHidden,
        [int]$K
    )
    $script:Stage13HiddenCalls++
    $script:Stage13LastHiddenK = $K
    return & $script:Stage13OriginalHiddenByNearness -LegacyHidden $LegacyHidden -K $K
}
try {
    $hiddenResult = priorPatch `
        -DropStore @{} `
        -LegacyHidden $ready.legacyHiddenStorage `
        -I 1 `
        -Back 7
}
finally {
    Set-Item -Path Function:legacyPrior -Value $script:Stage13OriginalLegacyPrior
    Set-Item -Path Function:hiddenByNearness -Value $script:Stage13OriginalHiddenByNearness
}
Assert-StageEqual 0 $script:Stage13LegacyCalls 'Walang raw legacyPrior call sa hidden branch'
Assert-StageEqual 1 $script:Stage13HiddenCalls 'Eksaktong isang hiddenByNearness call sa hidden branch'
Assert-StageEqual 7 $script:Stage13LastHiddenK 'Eksaktong hiddenK=7 ang ipinasa para sa slot -6'
Assert-StageEqual $normativeHidden[7] $hiddenResult 'Normative hidden7 ang hidden-branch result'
$hiddenLegacyCalls = $script:Stage13LegacyCalls
$hiddenNearnessCalls = $script:Stage13HiddenCalls

# 5. Adapter state is invocation-local and records hidden branch.
$first = New-Stage13ReadyHiddenContext -CalculationDay $foundation -TargetDay $target
$second = New-Stage13ReadyHiddenContext -CalculationDay $foundation -TargetDay $target
$adapterValue = Invoke-Patch06LegacyPriorAdapter -Context $first -DropStore @{} -I 1 -Back 3

Assert-StageEqual $normativeHidden[3] $adapterValue 'GREEN ang patched adapter para sa slot -2'
Assert-StageEqual -2 $first.patch06Slot 'Na-capture ang Patch 06 slot -2'
Assert-StageTrue -Condition $first.patch06UsedHidden -Name 'Naka-markang hidden branch ang slot -2'
Assert-StageEqual 3 $first.patch06HiddenK 'Na-capture ang hiddenK=3'
Assert-StageEqual $normativeHidden[3] $first.patch06Value 'Na-capture ang patched hidden3 value'
Assert-StageTrue -Condition $first.patch06Applied -Name 'Naka-markang applied ang Patch 06'
Assert-StageEqual 'PRIOR_PATCH_ACTIVE' $first.patch06Status 'Aktibo ang Patch 06 status'
Assert-StageEqual 1 $first.patch06InvocationCount 'Isang Patch 06 invocation sa hidden adapter case'
Assert-StageEqual 1 $first.legacyPriorI 'Preserved ang legacy i coordinate'
Assert-StageEqual 3 $first.legacyPriorBack 'Preserved ang legacy back coordinate'
Assert-StageEqual -2 $first.legacyPriorSlot 'Preserved ang legacy slot coordinate'
Assert-StageEqual $normativeHidden[3] $first.legacyPriorValue 'Authoritative patched result ang legacyPriorValue sa adapter'

Assert-StageTrue -Condition ($null -eq $second.patch06Slot) -Name 'Walang Patch 06 slot leak'
Assert-StageTrue -Condition (-not $second.patch06UsedHidden) -Name 'Walang Patch 06 hidden-branch leak'
Assert-StageTrue -Condition ($null -eq $second.patch06HiddenK) -Name 'Walang Patch 06 hiddenK leak'
Assert-StageTrue -Condition ($null -eq $second.patch06Value) -Name 'Walang Patch 06 value leak'
Assert-StageTrue -Condition (-not $second.patch06Applied) -Name 'Hindi applied ang Patch 06 sa ibang invocation'
Assert-StageEqual 0 $second.patch06InvocationCount 'Walang Patch 06 invocation-count leak'

# 6. Visible adapter branch must not require hidden storage.
$visibleCtx = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $foundation
$visibleAdapterValue = Invoke-Patch06LegacyPriorAdapter `
    -Context $visibleCtx `
    -DropStore @{
        1 = [System.Numerics.BigInteger]111
        2 = [System.Numerics.BigInteger]222
    } `
    -I 3 `
    -Back 1

Assert-StageEqual ([System.Numerics.BigInteger]222) $visibleAdapterValue 'GREEN ang patched visible adapter nang walang hidden storage'
Assert-StageEqual 2 $visibleCtx.patch06Slot 'Visible adapter slot ay 2'
Assert-StageTrue -Condition (-not $visibleCtx.patch06UsedHidden) -Name 'Hindi hidden branch ang positive slot'
Assert-StageTrue -Condition ($null -eq $visibleCtx.patch06HiddenK) -Name 'Walang hiddenK sa positive slot'
Assert-StageEqual ([System.Numerics.BigInteger]222) $visibleCtx.patch06Value 'Visible value ang Patch 06 result'
Assert-StageTrue -Condition $visibleCtx.patch06Applied -Name 'Applied ang Patch 06 visible branch'

# 7. Hidden branch requires hidden storage and leaves Stage 12 coordinates visible.
$missingHiddenCtx = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $foundation
$hiddenStorageError = $false
try {
    [void](Invoke-Patch06LegacyPriorAdapter -Context $missingHiddenCtx -DropStore @{} -I 1 -Back 1)
}
catch {
    $hiddenStorageError = $true
}
Assert-StageTrue -Condition $hiddenStorageError -Name 'Tinatanggihan ng hidden branch ang missing hidden storage'
Assert-StageEqual 1 $missingHiddenCtx.legacyPriorI 'Na-capture pa rin ang i bago hidden-storage error'
Assert-StageEqual 1 $missingHiddenCtx.legacyPriorBack 'Na-capture pa rin ang back bago hidden-storage error'
Assert-StageEqual 0 $missingHiddenCtx.legacyPriorSlot 'Na-capture pa rin ang slot 0 bago hidden-storage error'
Assert-StageTrue -Condition ($null -eq $missingHiddenCtx.legacyPriorValue) -Name 'Null pa rin ang legacy value kapag nabigo bago patch result'

# 8. Observability neutrality.
$plain = New-Stage13ReadyHiddenContext -CalculationDay ($foundation - 5) -TargetDay ($foundation + 8)
$noisy = New-Stage13ReadyHiddenContext -CalculationDay ($foundation - 5) -TargetDay ($foundation + 8)
$noisy.logs.Add([pscustomobject]@{ code='noisy-before'; data=13 })
$noisy.metrics['observability.only'] = [System.Numerics.BigInteger]1313
$noisy.diagnostics.Add([pscustomobject]@{ code='diagnostic'; data=13 })
$plainValue = Invoke-Patch06LegacyPriorAdapter -Context $plain -DropStore @{} -I 1 -Back 7
$noisyValue = Invoke-Patch06LegacyPriorAdapter -Context $noisy -DropStore @{} -I 1 -Back 7
Assert-StageEqual $plainValue $noisyValue 'Hindi binabago ng observability state ang Patch 06 result'

# 9. Production route: same valid probe, now through Patch 06, and truly through raw legacyPrior.
$script:Stage13OriginalLegacyPrior = (Get-Command legacyPrior -CommandType Function).ScriptBlock
$script:Stage13ProductionLegacyCalls = 0
Set-Item -Path Function:legacyPrior -Value {
    param(
        [hashtable]$DropStore,
        [int]$I,
        [int]$Back
    )
    $script:Stage13ProductionLegacyCalls++
    return & $script:Stage13OriginalLegacyPrior -DropStore $DropStore -I $I -Back $Back
}
try {
    $ctx = Invoke-CalendarDateSpaghetti -CalculationDay $foundation -TargetDay $target
}
finally {
    Set-Item -Path Function:legacyPrior -Value $script:Stage13OriginalLegacyPrior
}

Assert-StageEqual 1 $script:Stage13ProductionLegacyCalls 'Eksaktong isang raw legacyPrior call sa production Patch 06 probe'
Assert-StageEqual 'SAVE_PATCH_ACTIVE' $ctx.patch01Status 'Nananatiling aktibo ang Patch 01 sa Stage 13'
Assert-StageEqual 'DAY_TAG_PATCH_ACTIVE' $ctx.patch02Status 'Nananatiling aktibo ang Patch 02 sa Stage 13'
Assert-StageEqual 'DISTANCE_PATCH_ACTIVE' $ctx.patch03Status 'Nananatiling aktibo ang Patch 03 sa Stage 13'
Assert-StageEqual 'STONE_PATCH_ACTIVE' $ctx.patch04Status 'Nananatiling aktibo ang Patch 04 sa Stage 13'
Assert-StageEqual 'BACKWARD_HIDDEN_STORAGE_ACTIVE' $ctx.discovery05Status 'Nananatiling aktibo ang Discovery 05 scar sa Stage 13'
Assert-StageEqual 'HIDDEN_NEARNESS_PATCH_ACTIVE' $ctx.patch05Status 'Nananatiling aktibo ang Patch 05 sa Stage 13'
Assert-StageEqual $normativeHidden[1] $ctx.patch05CorrectedValue 'Nananatiling GREEN ang Patch 05 production k=1'
Assert-StageEqual 'VISIBLE_ONLY_PRIOR_SCAR_PRESERVED' $ctx.discovery06Status 'Preserved ang Discovery 06 raw visible-only scar status'
Assert-StageEqual 'PRIOR_PATCH_ACTIVE' $ctx.patch06Status 'Aktibo ang Patch 06 sa production route'
Assert-StageEqual 1 $ctx.patch06InvocationCount 'Eksaktong isang Patch 06 production invocation'
Assert-StageEqual 1 $ctx.patch06Slot 'Production Patch 06 slot ay visible slot 1'
Assert-StageTrue -Condition (-not $ctx.patch06UsedHidden) -Name 'Visible branch ang production probe'
Assert-StageTrue -Condition ($null -eq $ctx.patch06HiddenK) -Name 'Walang hiddenK sa production visible probe'
Assert-StageEqual $ctx.patch05CorrectedValue $ctx.patch06Value 'Patch 05 corrected value ang production visible probe result'
Assert-StageEqual $ctx.patch06Value $ctx.legacyPriorProbeValue 'Patch 06 result ang production probe value'

# 10. Semantic committed state.
Assert-StageEqual 1 $ctx.semanticCommitted['patch06Slot'] 'Committed ang production Patch 06 slot'
Assert-StageTrue -Condition (-not $ctx.semanticCommitted['patch06UsedHidden']) -Name 'Committed ang visible-branch flag'
Assert-StageTrue -Condition ($null -eq $ctx.semanticCommitted['patch06HiddenK']) -Name 'Committed na null ang visible hiddenK'
Assert-StageEqual $ctx.patch06Value $ctx.semanticCommitted['patch06Value'] 'Committed ang Patch 06 value'
Assert-StageTrue -Condition $ctx.semanticCommitted['patch06Applied'] -Name 'Committed ang Patch 06 applied flag'

# 11. Production purity, physical scars, and no Stage 14+.
$monsterText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/MonsterSkeleton.ps1')
$discovery06Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Discovery06.ps1')
$patch06Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Patch06.ps1')
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
    'src/Patch06.ps1'
)
$productionText = $monsterText
foreach ($rel in $productionFiles) {
    $productionText += "`n" + (Get-Content -Raw -Encoding UTF8 (Join-Path $root $rel))
}

Assert-StageTrue -Condition ($productionText -notmatch 'Invoke-NormSauce|Get-NormCalendarDate|Get-NormSave|New-NormStoneTable') -Name 'Hindi tumatawag sa normative oracle ang Stage 13 production path'
Assert-StageTrue -Condition ($discovery06Text -match 'function legacyPrior') -Name 'Nananatiling pisikal ang raw legacyPrior helper'
Assert-StageTrue -Condition ($discovery06Text -match '\$DropStore\[\$I - \$Back\]') -Name 'Nananatiling eksaktong dropStore[i-back] ang raw scar'
Assert-StageTrue -Condition ($discovery06Text -notmatch 'priorPatch') -Name 'Hindi binago ang Discovery 06 file para itago ang Patch 06'
Assert-StageTrue -Condition ($patch06Text -match 'function priorPatch') -Name 'Pisikal at hiwalay ang priorPatch'
Assert-StageTrue -Condition ($patch06Text -match 'legacyPrior') -Name 'Pisikal na tinatawag ng visible branch ang raw legacyPrior'
Assert-StageTrue -Condition ($patch06Text -match 'hiddenByNearness') -Name 'Pisikal na ginagamit ng hidden branch ang hiddenByNearness'
Assert-StageTrue -Condition ($patch06Text -match '\$hiddenK = 1 - \$slot') -Name 'Eksaktong hiddenK=1-slot ang Patch 06 translation'
Assert-StageTrue -Condition ($monsterText -match 'Invoke-Patch06LegacyPriorAdapter') -Name 'Dumadaan ang tunay na production route sa Patch 06 adapter'

$futureNames = @(
    'legacyGrindRow',
    'LEGACY_VISIBLE_GRIND_TABLE',
    'SENTINEL_GRIND_ROW',
    'GRIND_TABLE_WITH_SENTINEL',
    'LegacyVisibleDropBuilder',
    'orderAt46Latch',
    'biasedLegacyPick',
    'LEGACY_YEAR_MAX',
    'VirtualLegacyList',
    'oldContiguousMonthDayGuess'
)
foreach ($name in $futureNames) {
    Assert-StageTrue -Condition ($productionText -notmatch [regex]::Escape($name)) -Name "Walang future patch code: $name"
}

Write-Host "PATCH06_STAGE12_REGRESSION_GREEN_COUNT=$stage12Green"
Write-Host "PATCH06_HIDDEN_CASE_GREEN_COUNT=$hiddenGreen"
Write-Host "PATCH06_VISIBLE_LEGACY_CALL_COUNT=$visibleLegacyCalls"
Write-Host "PATCH06_HIDDEN_LEGACY_CALL_COUNT=$hiddenLegacyCalls"
Write-Host "PATCH06_HIDDEN_BY_NEARNESS_CALL_COUNT=$hiddenNearnessCalls"
Write-Host "PATCH06_PRODUCTION_LEGACY_CALL_COUNT=$script:Stage13ProductionLegacyCalls"
Write-Host 'PATCH06_RAW_LEGACY_PRIOR_SCAR=PRESERVED'
Write-Host 'PATCH06_VISIBLE_BRANCH_REQUIRES_HIDDEN=NO'
Write-Host 'STAGE13_REPOSITORY_STATE=GREEN'

$ok = Complete-StageTestRun
if (-not $ok) { exit 1 }
Write-Host 'STAGE13_RESULT=PASS'
exit 0
