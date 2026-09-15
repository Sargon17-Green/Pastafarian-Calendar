Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

. (Join-Path $root 'src/SourceLanguageCatalog.ps1')
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

function New-Stage15ExpectedGrindRows {
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

function Get-Stage15RowSignature {
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
$expectedRows = New-Stage15ExpectedGrindRows

Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_STAGE=15\s*$') -Name 'Stage 15 ang kasalukuyang stage'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_KIND=PATCH\s*$') -Name 'Patch ang kasalukuyang uri'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_PATCH=07\s*$') -Name 'Patch 07 ang kasalukuyang patch slot'
Assert-StageTrue -Condition ($metadata -match '(?m)^LAST_COMPLETED_STAGE=14\s*$') -Name 'Hindi pa minamarkahang kumpleto ang Stage 15 bago runtime'
Assert-StageTrue -Condition ($metadata -match '(?m)^EXPECTED_REPOSITORY_STATE=GREEN\s*$') -Name 'GREEN ang inaasahang Stage 15 repository state'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE14_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED\s*$') -Name 'Nananatiling nakatala ang Stage 14 expected-red proof'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE15_PATCH=SENTINEL_GRIND_TABLE_REPAIR\s*$') -Name 'Patch 07 metadata ay sentinel grind repair'

# 1. Raw Stage 14 scar remains byte-semantically present and wrong.
$rawTable = Get-Discovery07LegacyVisibleGrindTable
Assert-StageEqual 11 $rawTable.Count 'Nananatiling eksaktong 11 rows ang raw Stage 14 table'
$rawRedCount = 0
for ($grind = 1; $grind -le 11; $grind++) {
    $raw = legacyGrindRow -Grind $grind
    $expected = $expectedRows[$grind - 1]
    if ((Get-Stage15RowSignature $raw) -ne (Get-Stage15RowSignature $expected)) {
        $rawRedCount++
    }
}
Assert-StageEqual 11 $rawRedCount 'Nananatiling mali ang lahat ng 11 raw Stage 14 grind ordinals'

# 2. Sentinel table shape and exact mapping.
$patchedTable = Get-Patch07GrindTableWithSentinel
Assert-StageEqual 12 $patchedTable.Count 'Eksaktong 12 physical rows kasama ang sentinel'
Assert-StageEqual 0 $patchedTable[0].a 'Sentinel a ay zero'
Assert-StageEqual 0 $patchedTable[0].b 'Sentinel b ay zero'
Assert-StageEqual 0 $patchedTable[0].c 'Sentinel c ay zero'
Assert-StageEqual 0 $patchedTable[0].d 'Sentinel d ay zero'
Assert-StageTrue -Condition ($null -eq $patchedTable[0].kind) -Name 'Sentinel kind ay NONE/null'
Assert-StageEqual 'NONE' $patchedTable[0].kindName 'Sentinel kindName ay NONE'

for ($grind = 1; $grind -le 11; $grind++) {
    Assert-StageEqual `
        (Get-Stage15RowSignature $expectedRows[$grind - 1]) `
        (Get-Stage15RowSignature $patchedTable[$grind]) `
        "Sentinel table grind $grind ay eksaktong normative row $grind"
}

# 3. Direct corrected translator GREEN on all eleven ordinals.
$translatorGreenCount = 0
for ($grind = 1; $grind -le 11; $grind++) {
    $actual = grindRowWithSentinel -Grind $grind
    $expected = $expectedRows[$grind - 1]
    Assert-StageEqual `
        (Get-Stage15RowSignature $expected) `
        (Get-Stage15RowSignature $actual) `
        "grindRowWithSentinel ay GREEN para sa grind=$grind"
    $translatorGreenCount++
}
Assert-StageEqual 11 $translatorGreenCount 'Eksaktong labing-isang Patch 07 translator ordinals ang GREEN'

# 4. Wrapper first executes raw scar, then returns corrected row.
$wrapperGreenCount = 0
for ($grind = 1; $grind -le 11; $grind++) {
    $ctxCase = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
    $actual = Invoke-Patch07GrindRowRepair -Context $ctxCase -Grind $grind
    $expected = $expectedRows[$grind - 1]

    Assert-StageEqual `
        (Get-Stage15RowSignature $expected) `
        (Get-Stage15RowSignature $actual) `
        "Patch 07 wrapper ay GREEN para sa grind=$grind"
    Assert-StageEqual 1 $ctxCase.discovery07InvocationCount "Talagang isang raw Stage 14 call muna para sa grind=$grind"
    Assert-StageEqual $grind $ctxCase.legacyGrindRequestedOrdinal "Raw requested ordinal ay preserved para sa grind=$grind"
    Assert-StageEqual $grind $ctxCase.legacyGrindDirectIndex "Raw direct index scar ay preserved para sa grind=$grind"
    Assert-StageEqual $grind $ctxCase.patch07RequestedGrind "Patch 07 requested grind ay captured para sa grind=$grind"
    Assert-StageEqual $grind $ctxCase.patch07SentinelIndex "Patch 07 sentinel index ay captured para sa grind=$grind"
    Assert-StageEqual `
        (Get-Stage15RowSignature (legacyGrindRow -Grind $grind)) `
        (Get-Stage15RowSignature $ctxCase.patch07RawLegacyRow) `
        "Raw legacy row scar ay captured para sa grind=$grind"
    Assert-StageEqual `
        (Get-Stage15RowSignature $expected) `
        (Get-Stage15RowSignature $ctxCase.patch07CorrectedRow) `
        "Corrected row ay captured para sa grind=$grind"
    Assert-StageTrue -Condition $ctxCase.patch07Applied -Name "Applied ang Patch 07 para sa grind=$grind"
    Assert-StageEqual 'SENTINEL_GRIND_PATCH_ACTIVE' $ctxCase.patch07Status "Aktibo ang Patch 07 status para sa grind=$grind"
    Assert-StageEqual 1 $ctxCase.patch07InvocationCount "Isang Patch 07 invocation para sa grind=$grind"
    $wrapperGreenCount++
}
Assert-StageEqual 11 $wrapperGreenCount 'Eksaktong labing-isang Patch 07 wrapper ordinals ang GREEN'

# 5. Exact raw-vs-corrected scar examples.
$scar1 = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
[void](Invoke-Patch07GrindRowRepair -Context $scar1 -Grind 1)
Assert-StageEqual `
    (Get-Stage15RowSignature $expectedRows[1]) `
    (Get-Stage15RowSignature $scar1.patch07RawLegacyRow) `
    'Sa grind 1, raw scar ay nananatiling row 2'
Assert-StageEqual `
    (Get-Stage15RowSignature $expectedRows[0]) `
    (Get-Stage15RowSignature $scar1.patch07CorrectedRow) `
    'Sa grind 1, corrected result ay row 1'

$scar11 = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
[void](Invoke-Patch07GrindRowRepair -Context $scar11 -Grind 11)
Assert-StageTrue -Condition ($null -eq $scar11.patch07RawLegacyRow) -Name 'Sa grind 11, raw scar ay nananatiling undefined'
Assert-StageEqual `
    (Get-Stage15RowSignature $expectedRows[10]) `
    (Get-Stage15RowSignature $scar11.patch07CorrectedRow) `
    'Sa grind 11, corrected result ay row 11'

# 6. Production route: Patch 01..06 remain active, raw Discovery 07 scar really executes, Patch 07 corrects.
$ctx = Invoke-CalendarDateSpaghetti -CalculationDay $foundation -TargetDay $target
Assert-StageEqual 'SAVE_PATCH_ACTIVE' $ctx.patch01Status 'Nananatiling aktibo ang Patch 01 sa Stage 15'
Assert-StageEqual 'DAY_TAG_PATCH_ACTIVE' $ctx.patch02Status 'Nananatiling aktibo ang Patch 02 sa Stage 15'
Assert-StageEqual 'DISTANCE_PATCH_ACTIVE' $ctx.patch03Status 'Nananatiling aktibo ang Patch 03 sa Stage 15'
Assert-StageEqual 'STONE_PATCH_ACTIVE' $ctx.patch04Status 'Nananatiling aktibo ang Patch 04 sa Stage 15'
Assert-StageEqual 'BACKWARD_HIDDEN_STORAGE_ACTIVE' $ctx.discovery05Status 'Nananatiling aktibo ang Discovery 05 scar sa Stage 15'
Assert-StageEqual 'HIDDEN_NEARNESS_PATCH_ACTIVE' $ctx.patch05Status 'Nananatiling aktibo ang Patch 05 sa Stage 15'
Assert-StageEqual 'VISIBLE_ONLY_PRIOR_SCAR_PRESERVED' $ctx.discovery06Status 'Nananatiling preserved ang Discovery 06 scar sa Stage 15'
Assert-StageEqual 'PRIOR_PATCH_ACTIVE' $ctx.patch06Status 'Nananatiling aktibo ang Patch 06 sa Stage 15'

Assert-StageEqual 'ZERO_BASED_DIRECT_ORDINAL_INDEX_ACTIVE' $ctx.discovery07Status 'Talagang pinatakbo ang raw Discovery 07 scar sa Stage 15 production route'
Assert-StageEqual 1 $ctx.discovery07InvocationCount 'Eksaktong isang raw Discovery 07 call sa production Patch 07 probe'
Assert-StageEqual 1 $ctx.legacyGrindRequestedOrdinal 'Production raw grind ordinal ay 1'
Assert-StageEqual 1 $ctx.legacyGrindDirectIndex 'Production raw direct index ay 1'
Assert-StageEqual `
    (Get-Stage15RowSignature $expectedRows[1]) `
    (Get-Stage15RowSignature $ctx.patch07RawLegacyRow) `
    'Production raw scar ay talagang row 2'

Assert-StageEqual 'SENTINEL_GRIND_PATCH_ACTIVE' $ctx.patch07Status 'Aktibo ang Patch 07 sa production route'
Assert-StageEqual 1 $ctx.patch07InvocationCount 'Eksaktong isang Patch 07 production invocation'
Assert-StageEqual 1 $ctx.patch07RequestedGrind 'Production Patch 07 requested grind ay 1'
Assert-StageEqual 1 $ctx.patch07SentinelIndex 'Production Patch 07 sentinel index ay 1'
Assert-StageEqual `
    (Get-Stage15RowSignature $expectedRows[0]) `
    (Get-Stage15RowSignature $ctx.patch07CorrectedRow) `
    'Production Patch 07 corrected result ay row 1'
Assert-StageEqual `
    (Get-Stage15RowSignature $ctx.patch07CorrectedRow) `
    (Get-Stage15RowSignature $ctx.legacyGrindProbeRow) `
    'Production probe value ay corrected Patch 07 row'
Assert-StageTrue -Condition $ctx.metrics.ContainsKey('patch07.grind.probes') -Name 'May Patch 07 production probe metric'
Assert-StageEqual ([System.Numerics.BigInteger]1) $ctx.metrics['patch07.grind.probes'] 'Eksaktong isang Patch 07 production probe metric increment'

# 7. Invocation ownership.
$clean = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
Assert-StageTrue -Condition ($null -eq $clean.patch07RequestedGrind) -Name 'Walang Patch 07 requested-grind leak'
Assert-StageTrue -Condition ($null -eq $clean.patch07SentinelIndex) -Name 'Walang Patch 07 sentinel-index leak'
Assert-StageTrue -Condition ($null -eq $clean.patch07RawLegacyRow) -Name 'Walang Patch 07 raw-row leak'
Assert-StageTrue -Condition ($null -eq $clean.patch07CorrectedRow) -Name 'Walang Patch 07 corrected-row leak'
Assert-StageTrue -Condition (-not $clean.patch07Applied) -Name 'Hindi applied ang Patch 07 sa bagong invocation'
Assert-StageEqual 0 $clean.patch07InvocationCount 'Walang Patch 07 invocation-count leak'

# 8. Observability neutrality.
$plain = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
$noisy = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
$noisy.logs.Add([pscustomobject]@{ code='noisy-before'; data=15 })
$noisy.metrics['observability.only'] = [System.Numerics.BigInteger]1515
$noisy.diagnostics.Add([pscustomobject]@{ code='diagnostic'; data=15 })
$plainRow = Invoke-Patch07GrindRowRepair -Context $plain -Grind 10
$noisyRow = Invoke-Patch07GrindRowRepair -Context $noisy -Grind 10
Assert-StageEqual `
    (Get-Stage15RowSignature $plainRow) `
    (Get-Stage15RowSignature $noisyRow) `
    'Hindi binabago ng observability state ang Patch 07 result'

# 9. Production purity, preserved Stage 14 scar, and no Stage 16+.
$monsterText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/MonsterSkeleton.ps1')
$discovery07Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Discovery07.ps1')
$patch07Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Patch07.ps1')
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
    'src/Patch07.ps1'
)
$productionText = $monsterText
foreach ($rel in $productionFiles) {
    $productionText += "`n" + (Get-Content -Raw -Encoding UTF8 (Join-Path $root $rel))
}

Assert-StageTrue -Condition ($productionText -notmatch 'Invoke-NormSauce|Get-NormCalendarDate|Get-NormSave|New-NormStoneTable') -Name 'Hindi tumatawag sa normative oracle ang Stage 15 production path'
Assert-StageTrue -Condition ($discovery07Text -match 'LEGACY_VISIBLE_GRIND_TABLE_ZERO_BASED') -Name 'Nananatiling pisikal ang raw zero-based grind table'
Assert-StageTrue -Condition ($discovery07Text -match 'function legacyGrindRow') -Name 'Nananatiling pisikal ang raw legacyGrindRow'
Assert-StageTrue -Condition ($discovery07Text -match '\$script:LEGACY_VISIBLE_GRIND_TABLE_ZERO_BASED\[\$Grind\]') -Name 'Nananatiling eksakto ang raw direct-index scar'
Assert-StageTrue -Condition ($discovery07Text -notmatch 'SENTINEL_GRIND_ROW|GRIND_TABLE_WITH_SENTINEL|grindRowWithSentinel') -Name 'Hindi binago ang Discovery 07 file para itago ang Patch 07'
Assert-StageTrue -Condition ($patch07Text -match 'SENTINEL_GRIND_ROW') -Name 'Pisikal at hiwalay ang Patch 07 sentinel row'
Assert-StageTrue -Condition ($patch07Text -match 'GRIND_TABLE_WITH_SENTINEL') -Name 'Pisikal at hiwalay ang Patch 07 sentinel table'
Assert-StageTrue -Condition ($patch07Text -match 'function grindRowWithSentinel') -Name 'Pisikal at hiwalay ang corrected grind translator'
Assert-StageTrue -Condition ($patch07Text -match 'LegacyGrindTableAdapter') -Name 'Talagang tinatawag muna ng Patch 07 ang raw Stage 14 adapter'
Assert-StageTrue -Condition ($monsterText -match 'Invoke-Patch07GrindRowRepair') -Name 'Dumadaan ang tunay na production route sa Patch 07'

$futureNames = @(
    'LegacyVisibleDropBuilder',
    'visibleDropThroughCurrentLayers',
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

Write-Host "PATCH07_SENTINEL_TABLE_ROW_COUNT=$($patchedTable.Count)"
Write-Host "PATCH07_TRANSLATOR_GREEN_COUNT=$translatorGreenCount"
Write-Host "PATCH07_WRAPPER_GREEN_COUNT=$wrapperGreenCount"
Write-Host "PATCH07_RAW_STAGE14_RED_COUNT=$rawRedCount"
Write-Host 'PATCH07_PRODUCTION_GRIND=1'
Write-Host 'PATCH07_PRODUCTION_RAW=ROW2'
Write-Host 'PATCH07_PRODUCTION_CORRECTED=ROW1'
Write-Host 'PATCH07_STAGE14_SCAR=PRESERVED_AND_CALLED'
Write-Host 'PATCH07_VISIBLE_DROP_BUILDER=ABSENT'
Write-Host 'STAGE15_REPOSITORY_STATE=GREEN'

$ok = Complete-StageTestRun
if (-not $ok) { exit 1 }
Write-Host 'STAGE15_RESULT=PASS'
exit 0
