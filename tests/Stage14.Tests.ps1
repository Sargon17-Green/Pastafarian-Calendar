Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

. (Join-Path $root 'src/SourceLanguageCatalog.ps1')
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

function New-Stage14ExpectedGrindRows {
    return ,([object[]]@(
        [pscustomobject]@{ a = 3;  b = 5;  c = 7;  d = 11; kind = 0; kindName = 'WHEAT'  },
        [pscustomobject]@{ a = 5;  b = 7;  c = 11; d = 13; kind = 1; kindName = 'BARLEY' },
        [pscustomobject]@{ a = 7;  b = 11; c = 13; d = 17; kind = 2; kindName = 'SALT'   },
        [pscustomobject]@{ a = 11; b = 13; c = 17; d = 19; kind = 3; kindName = 'BITTER' },
        [pscustomobject]@{ a = 13; b = 17; c = 19; d = 23; kind = 4; kindName = 'RED'    },
        [pscustomobject]@{ a = 17; b = 19; c = 23; d = 29; kind = 0; kindName = 'WHEAT'  },
        [pscustomobject]@{ a = 19; b = 23; c = 29; d = 31; kind = 1; kindName = 'BARLEY' },
        [pscustomobject]@{ a = 23; b = 29; c = 31; d = 37; kind = 2; kindName = 'SALT'   },
        [pscustomobject]@{ a = 29; b = 31; c = 37; d = 41; kind = 3; kindName = 'BITTER' },
        [pscustomobject]@{ a = 31; b = 37; c = 41; d = 43; kind = 4; kindName = 'RED'    },
        [pscustomobject]@{ a = 37; b = 41; c = 43; d = 47; kind = 0; kindName = 'WHEAT'  }
    ))
}

function Get-Stage14RowSignature {
    param([AllowNull()]$Row)
    if ($null -eq $Row) {
        return '<UNDEFINED>'
    }
    return '{0},{1},{2},{3},{4},{5}' -f `
        $Row.a, $Row.b, $Row.c, $Row.d, $Row.kind, $Row.kindName
}

$foundation = Get-NormFoundationDay
$target = $foundation + 3
$metadata = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')
$expectedRows = New-Stage14ExpectedGrindRows

Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_STAGE=14\s*$') -Name 'Stage 14 ang kasalukuyang stage'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_KIND=DISCOVERY\s*$') -Name 'Discovery ang kasalukuyang uri'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_PATCH=07\s*$') -Name 'Discovery 07 ang kasalukuyang patch slot'
Assert-StageTrue -Condition ($metadata -match '(?m)^LAST_COMPLETED_STAGE=13\s*$') -Name 'Hindi pa minamarkahang kumpleto ang Stage 14 bago runtime'
Assert-StageTrue -Condition ($metadata -match '(?m)^EXPECTED_REPOSITORY_STATE=RED\s*$') -Name 'RED ang inaasahang Stage 14 repository state'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE13_RUNTIME_VERIFICATION=GREEN_CONFIRMED\s*$') -Name 'Nananatiling nakatala ang Stage 13 GREEN proof'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE14_DISCOVERY=ZERO_BASED_VISIBLE_GRIND_TABLE_DIRECT_ORDINAL_INDEX\s*$') -Name 'Discovery 07 metadata ay zero-based direct ordinal indexing'

# 1. Physical table itself is correct and has no sentinel.
$legacyTable = Get-Discovery07LegacyVisibleGrindTable
Assert-StageEqual 11 $legacyTable.Count 'Eksaktong labing-isang tunay na zero-based grind rows'
for ($idx = 0; $idx -lt 11; $idx++) {
    Assert-StageEqual `
        (Get-Stage14RowSignature $expectedRows[$idx]) `
        (Get-Stage14RowSignature $legacyTable[$idx]) `
        "Physical zero-based row $idx ay tamang normative row $($idx + 1)"
}

# 2. Exact historical off-by-one discovery surface: all ordinals 1..11 RED.
$expectedRedCount = 0
$matchCount = 0

for ($grind = 1; $grind -le 11; $grind++) {
    $actual = legacyGrindRow -Grind $grind
    $expected = $expectedRows[$grind - 1]
    $actualSig = Get-Stage14RowSignature $actual
    $expectedSig = Get-Stage14RowSignature $expected

    if ($actualSig -eq $expectedSig) {
        $matchCount++
        Write-Host "DISCOVERY07_GRIND=$grind CLASSIFICATION=MATCH"
    }
    else {
        $expectedRedCount++
        Write-Host "DISCOVERY07_GRIND=$grind CLASSIFICATION=EXPECTED_RED ERROR_ID=Pastafari:Discovery07:ZeroBasedOrdinalIndex"
    }
}

Assert-StageEqual 11 $expectedRedCount 'Eksaktong labing-isang Discovery 07 EXPECTED_RED grind ordinals'
Assert-StageEqual 0 $matchCount 'Walang Discovery 07 grind ordinal na MATCH bago Patch 07'
Assert-StageEqual `
    (Get-Stage14RowSignature $expectedRows[1]) `
    (Get-Stage14RowSignature (legacyGrindRow -Grind 1)) `
    'Grind 1 ay maling bumabasa sa physical row 2'
Assert-StageEqual `
    (Get-Stage14RowSignature $expectedRows[10]) `
    (Get-Stage14RowSignature (legacyGrindRow -Grind 10)) `
    'Grind 10 ay maling bumabasa sa physical row 11'
Assert-StageTrue -Condition ($null -eq (legacyGrindRow -Grind 11)) -Name 'Grind 11 ay undefined dahil wala ang physical index 11'

# 3. Adapter/handler chain keeps the defect and captures scar state.
$probeCtx = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
$probeRow = LegacyGrindTableAdapter -Context $probeCtx -Grind 1
Assert-StageEqual `
    (Get-Stage14RowSignature $expectedRows[1]) `
    (Get-Stage14RowSignature $probeRow) `
    'LegacyGrindTableAdapter ay talagang nagbabalik ng maling row 2 para sa grind 1'
Assert-StageEqual 1 $probeCtx.legacyGrindRequestedOrdinal 'Na-capture ang requested grind ordinal 1'
Assert-StageEqual 1 $probeCtx.legacyGrindDirectIndex 'Na-capture ang maling direct index 1'
Assert-StageEqual `
    (Get-Stage14RowSignature $expectedRows[1]) `
    (Get-Stage14RowSignature $probeCtx.legacyGrindRowValue) `
    'Na-capture ang maling legacy row value'
Assert-StageTrue -Condition (-not $probeCtx.legacyGrindUndefined) -Name 'Hindi undefined ang grind 1'
Assert-StageEqual 'ZERO_BASED_DIRECT_ORDINAL_INDEX_ACTIVE' $probeCtx.discovery07Status 'Aktibo ang Discovery 07 status'
Assert-StageEqual 1 $probeCtx.discovery07InvocationCount 'Isang Discovery 07 handler invocation'

$undefinedCtx = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
$undefinedRow = LegacyGrindTableAdapter -Context $undefinedCtx -Grind 11
Assert-StageTrue -Condition ($null -eq $undefinedRow) -Name 'Undefined ang adapter result para sa grind 11'
Assert-StageEqual 11 $undefinedCtx.legacyGrindDirectIndex 'Direct index 11 ang na-capture'
Assert-StageTrue -Condition $undefinedCtx.legacyGrindUndefined -Name 'Na-capture ang undefined flag para sa grind 11'

# 4. Production route keeps all earlier layers active and performs the real wrong grind-1 probe.
$ctx = Invoke-CalendarDateSpaghetti -CalculationDay $foundation -TargetDay $target
Assert-StageEqual 'SAVE_PATCH_ACTIVE' $ctx.patch01Status 'Nananatiling aktibo ang Patch 01 sa Stage 14'
Assert-StageEqual 'DAY_TAG_PATCH_ACTIVE' $ctx.patch02Status 'Nananatiling aktibo ang Patch 02 sa Stage 14'
Assert-StageEqual 'DISTANCE_PATCH_ACTIVE' $ctx.patch03Status 'Nananatiling aktibo ang Patch 03 sa Stage 14'
Assert-StageEqual 'STONE_PATCH_ACTIVE' $ctx.patch04Status 'Nananatiling aktibo ang Patch 04 sa Stage 14'
Assert-StageEqual 'BACKWARD_HIDDEN_STORAGE_ACTIVE' $ctx.discovery05Status 'Nananatiling aktibo ang Discovery 05 scar sa Stage 14'
Assert-StageEqual 'HIDDEN_NEARNESS_PATCH_ACTIVE' $ctx.patch05Status 'Nananatiling aktibo ang Patch 05 sa Stage 14'
Assert-StageEqual 'VISIBLE_ONLY_PRIOR_SCAR_PRESERVED' $ctx.discovery06Status 'Nananatiling preserved ang Discovery 06 scar sa Stage 14'
Assert-StageEqual 'PRIOR_PATCH_ACTIVE' $ctx.patch06Status 'Nananatiling aktibo ang Patch 06 sa Stage 14'
Assert-StageEqual 1 $ctx.patch06Slot 'Nananatiling visible slot 1 ang Patch 06 production probe'

Assert-StageEqual 'ZERO_BASED_DIRECT_ORDINAL_INDEX_ACTIVE' $ctx.discovery07Status 'Aktibo ang Discovery 07 sa production route'
Assert-StageEqual 1 $ctx.discovery07InvocationCount 'Eksaktong isang Discovery 07 production probe'
Assert-StageEqual 1 $ctx.legacyGrindRequestedOrdinal 'Production grind ordinal ay eksaktong 1'
Assert-StageEqual 1 $ctx.legacyGrindDirectIndex 'Production direct index ay eksaktong 1'
Assert-StageEqual `
    (Get-Stage14RowSignature $expectedRows[1]) `
    (Get-Stage14RowSignature $ctx.legacyGrindProbeRow) `
    'Production probe ay talagang maling row 2'
Assert-StageEqual `
    (Get-Stage14RowSignature $ctx.legacyGrindRowValue) `
    (Get-Stage14RowSignature $ctx.legacyGrindProbeRow) `
    'Pareho ang captured row at production probe row'
Assert-StageTrue -Condition $ctx.metrics.ContainsKey('discovery07.grind.probes') -Name 'May Discovery 07 production probe metric'
Assert-StageEqual ([System.Numerics.BigInteger]1) $ctx.metrics['discovery07.grind.probes'] 'Eksaktong isang Discovery 07 production probe metric increment'

# 5. Invocation ownership.
$clean = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
Assert-StageTrue -Condition ($null -eq $clean.legacyGrindRequestedOrdinal) -Name 'Walang requested-grind leak'
Assert-StageTrue -Condition ($null -eq $clean.legacyGrindDirectIndex) -Name 'Walang direct-index leak'
Assert-StageTrue -Condition ($null -eq $clean.legacyGrindRowValue) -Name 'Walang legacy-row leak'
Assert-StageTrue -Condition (-not $clean.legacyGrindUndefined) -Name 'Walang undefined-flag leak'
Assert-StageTrue -Condition ($null -eq $clean.legacyGrindProbeRow) -Name 'Walang production-probe-row leak'
Assert-StageEqual 0 $clean.discovery07InvocationCount 'Walang Discovery 07 invocation-count leak'

# 6. Observability neutrality.
$plain = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
$noisy = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
$noisy.logs.Add([pscustomobject]@{ code='noisy-before'; data=14 })
$noisy.metrics['observability.only'] = [System.Numerics.BigInteger]1414
$noisy.diagnostics.Add([pscustomobject]@{ code='diagnostic'; data=14 })
$plainRow = LegacyGrindTableAdapter -Context $plain -Grind 10
$noisyRow = LegacyGrindTableAdapter -Context $noisy -Grind 10
Assert-StageEqual `
    (Get-Stage14RowSignature $plainRow) `
    (Get-Stage14RowSignature $noisyRow) `
    'Hindi binabago ng observability state ang legacy grind-row result'

# 7. Production purity, physical scar, and no Stage 15+.
$monsterText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/MonsterSkeleton.ps1')
$discovery07Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Discovery07.ps1')
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
    'src/Discovery07.ps1'
)
$productionText = $monsterText
foreach ($rel in $productionFiles) {
    $productionText += "`n" + (Get-Content -Raw -Encoding UTF8 (Join-Path $root $rel))
}

Assert-StageTrue -Condition ($productionText -notmatch 'Invoke-NormSauce|Get-NormCalendarDate|Get-NormSave|New-NormStoneTable') -Name 'Hindi tumatawag sa normative oracle ang Stage 14 production path'
Assert-StageTrue -Condition ($discovery07Text -match 'LEGACY_VISIBLE_GRIND_TABLE_ZERO_BASED') -Name 'Pisikal ang zero-based legacy grind table'
Assert-StageTrue -Condition ($discovery07Text -match 'function legacyGrindRow') -Name 'Pisikal ang raw legacyGrindRow helper'
Assert-StageTrue -Condition ($discovery07Text -match '\$script:LEGACY_VISIBLE_GRIND_TABLE_ZERO_BASED\[\$Grind\]') -Name 'Direktang ginagamit ng raw helper ang one-based Grind bilang zero-based index'
Assert-StageTrue -Condition ($discovery07Text -match 'function LegacyGrindTableAdapter') -Name 'Pisikal ang LegacyGrindTableAdapter'
Assert-StageTrue -Condition ($discovery07Text -match 'function Discovery07GrindIndexHandler') -Name 'Pisikal ang Discovery07GrindIndexHandler'
Assert-StageTrue -Condition ($monsterText -match 'LegacyGrindTableAdapter') -Name 'Dumadaan ang tunay na production route sa LegacyGrindTableAdapter'

$stage15Names = @(
    'SENTINEL_GRIND_ROW',
    'GRIND_TABLE_WITH_SENTINEL',
    'grindRowWithSentinel',
    'LegacyVisibleDropBuilder',
    'visibleDropThroughCurrentLayers'
)
foreach ($name in $stage15Names) {
    Assert-StageTrue -Condition ($productionText -notmatch [regex]::Escape($name)) -Name "Wala pang Stage 15 code: $name"
}

$futureNames = @(
    'oldPermutationUnrank0',
    'orderPatchFromValue',
    'orderAt46Latch',
    'biasedLegacyPick',
    'LEGACY_YEAR_MAX',
    'VirtualLegacyList',
    'oldContiguousMonthDayGuess'
)
foreach ($name in $futureNames) {
    Assert-StageTrue -Condition ($productionText -notmatch [regex]::Escape($name)) -Name "Walang future patch code: $name"
}

Write-Host "DISCOVERY07_EXPECTED_RED_COUNT=$expectedRedCount"
Write-Host "DISCOVERY07_MATCH_COUNT=$matchCount"
Write-Host 'DISCOVERY07_RED_ORDINALS=1,2,3,4,5,6,7,8,9,10,11'
Write-Host 'DISCOVERY07_GRIND1_ACTUAL_PHYSICAL_INDEX=1'
Write-Host 'DISCOVERY07_GRIND10_ACTUAL_PHYSICAL_INDEX=10'
Write-Host 'DISCOVERY07_GRIND11=UNDEFINED'
Write-Host 'DISCOVERY07_PRODUCTION_PROBE_GRIND=1'
Write-Host 'DISCOVERY07_SENTINEL=ABSENT'
Write-Host 'STAGE14_REPOSITORY_STATE=EXPECTED_RED'

$ok = Complete-StageTestRun
if (-not $ok) { exit 1 }
Write-Host 'STAGE14_RESULT=PASS'
exit 0
