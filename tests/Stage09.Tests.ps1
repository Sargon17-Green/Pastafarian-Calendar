Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

. (Join-Path $root 'src/SourceLanguageCatalog.ps1')
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

$foundation = Get-NormFoundationDay
$metadata = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')

Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_STAGE=9\s*$') -Name 'Stage 9 ang kasalukuyang stage'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_KIND=PATCH\s*$') -Name 'Patch ang kasalukuyang uri'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_PATCH=04\s*$') -Name 'Patch 04 ang kasalukuyang patch slot'
Assert-StageTrue -Condition ($metadata -match '(?m)^LAST_COMPLETED_STAGE=8\s*$') -Name 'Hindi pa minamarkahang kumpleto ang Stage 9 bago runtime'
Assert-StageTrue -Condition ($metadata -match '(?m)^EXPECTED_REPOSITORY_STATE=GREEN\s*$') -Name 'GREEN ang inaasahang Stage 9 repository state'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE08_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED\s*$') -Name 'Nananatiling nakatala ang Stage 8 expected-red proof'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE09_PATCH=STONE_PATCH\s*$') -Name 'Patch 04 metadata ay stonePatch'

$normTable = New-NormStoneTable

# 1. Ang historical scar ay nananatiling pisikal, mali, at in-place.
$rawState = New-Discovery04StoneState
$rawSameObject = $rawState
$rawResult = mutateStonesWrong -I 2 -State $rawState
$rawRow2 = Get-Discovery04StoneRow -State $rawResult

Assert-StageTrue -Condition ([object]::ReferenceEquals($rawSameObject, $rawResult)) -Name 'Nananatiling in-place ang raw mutateStonesWrong scar'
Assert-StageEqual $normTable[2][1] $rawRow2[0] 'Raw row 2 w ay nananatiling nagkataong normative'
Assert-StageTrue -Condition ($rawRow2[1] -ne $normTable[2][2]) -Name 'Raw row 2 b ay nananatiling mali'
Assert-StageTrue -Condition ($rawRow2[2] -ne $normTable[2][3]) -Name 'Raw row 2 s ay nananatiling mali'
Assert-StageTrue -Condition ($rawRow2[3] -ne $normTable[2][4]) -Name 'Raw row 2 m ay nananatiling mali'
Assert-StageTrue -Condition ($rawRow2[4] -ne $normTable[2][5]) -Name 'Raw row 2 r ay nananatiling mali'

$rawTable = Get-Discovery04LegacyStoneTable
$rawRedCount = 0
foreach ($rowNumber in @(2,3,46)) {
    $rawExpected = [object[]]@(
        $normTable[$rowNumber][1],
        $normTable[$rowNumber][2],
        $normTable[$rowNumber][3],
        $normTable[$rowNumber][4],
        $normTable[$rowNumber][5]
    )
    $same = $true
    for ($j = 0; $j -lt 5; $j++) {
        if ($rawTable[$rowNumber][$j] -ne $rawExpected[$j]) {
            $same = $false
            break
        }
    }
    if (-not $same) {
        $rawRedCount++
    }
}
Assert-StageEqual 3 $rawRedCount 'Nananatili ang eksaktong tatlong Stage 8 raw divergences'

# 2. stonePatch: snapshot -> tunay na legacy clone -> garbage -> limang overwrite mula sa old snapshot.
$initial = New-Discovery04StoneState
$initialBefore = Copy-Discovery04StoneState -State $initial
$trace = [System.Collections.Generic.List[object]]::new()
$patchedRow2State = stonePatch -I 2 -State $initial -TraceCapture $trace
$patchedRow2 = Get-Discovery04StoneRow -State $patchedRow2State
$expectedRow2 = [object[]]@(
    $normTable[2][1],
    $normTable[2][2],
    $normTable[2][3],
    $normTable[2][4],
    $normTable[2][5]
)
$expectedRow1 = [object[]]@(17,29,43,71,101)

Assert-StageSequenceEqual $expectedRow1 (Get-Discovery04StoneRow -State $initial) 'Hindi minutate ng stonePatch ang original input state'
Assert-StageSequenceEqual $expectedRow1 (Get-Discovery04StoneRow -State $initialBefore) 'Tama ang old snapshot bago ang Patch 04'
Assert-StageEqual 1 $trace.Count 'Eksaktong isang trace entry para sa isang stonePatch call'
Assert-StageEqual 2 $trace[0].rowNumber 'Tamang row number ang na-capture'
Assert-StageSequenceEqual $expectedRow1 $trace[0].oldSnapshot 'Napanatili ang old snapshot scar'
Assert-StageTrue -Condition (-not ([string]::Join(',', $trace[0].legacyGarbage) -eq [string]::Join(',', $expectedRow2))) -Name 'Naobserbahan ang legacy garbage bago overwrite'
Assert-StageSequenceEqual $expectedRow2 $trace[0].committed 'Committed row 2 ay normative pagkatapos ng overwrite'
Assert-StageSequenceEqual $expectedRow2 $patchedRow2 'stonePatch row 2 ay normative'

$differingFields = [System.Collections.Generic.List[int]]::new()
for ($j = 0; $j -lt 5; $j++) {
    if ($trace[0].legacyGarbage[$j] -ne $trace[0].committed[$j]) {
        $differingFields.Add($j)
    }
}
Assert-StageSequenceEqual ([int[]](1,2,3,4)) ([int[]]$differingFields.ToArray()) 'Sa row 2, b/s/m/r lamang ang kailangang ma-overwrite mula sa garbage'

# 3. Patunayan na hindi binabasa ng overwrite ang garbage.
$fakeMutator = {
    param($RowNumber, $LegacyState)
    return @{
        w = [System.Numerics.BigInteger]999001
        b = [System.Numerics.BigInteger]999002
        s = [System.Numerics.BigInteger]999003
        m = [System.Numerics.BigInteger]999004
        r = [System.Numerics.BigInteger]999005
    }
}
$fakeInput = New-Discovery04StoneState
$fakeResult = stonePatch -I 2 -State $fakeInput -LegacyMutator $fakeMutator
Assert-StageSequenceEqual $expectedRow2 (Get-Discovery04StoneRow -State $fakeResult) 'Ang limang overwrite ay bumabasa lamang sa old snapshot, hindi sa garbage'

# 4. Lahat ng 46 rows ng patched builder ay normative.
$builderTrace = [System.Collections.Generic.List[object]]::new()
$patchedTable = Get-Patch04StoneTableThroughLegacyBuilder -TraceCapture $builderTrace
Assert-StageEqual 47 $patchedTable.Count 'May 47 slots ang patched stone table'
Assert-StageEqual 45 $builderTrace.Count 'Eksaktong 45 rows ang dumaan sa stonePatch'

$greenRowCount = 0
for ($rowNumber = 1; $rowNumber -le 46; $rowNumber++) {
    $expected = [object[]]@(
        $normTable[$rowNumber][1],
        $normTable[$rowNumber][2],
        $normTable[$rowNumber][3],
        $normTable[$rowNumber][4],
        $normTable[$rowNumber][5]
    )
    $same = $true
    for ($j = 0; $j -lt 5; $j++) {
        if ($patchedTable[$rowNumber][$j] -ne $expected[$j]) {
            $same = $false
            break
        }
    }
    if ($same) {
        $greenRowCount++
    }
}
Assert-StageEqual 46 $greenRowCount 'Lahat ng rows 1 hanggang 46 ay GREEN pagkatapos ng Patch 04'

# 5. Production route at invocation-owned scar state.
$ctx = Invoke-CalendarDateSpaghetti -CalculationDay $foundation -TargetDay $foundation
$second = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $foundation

Assert-StageEqual 'SAVE_PATCH_ACTIVE' $ctx.patch01Status 'Nananatiling aktibo ang Patch 01 sa Stage 9 production route'
Assert-StageEqual (Get-NormSave -X $foundation) $ctx.patch01PatchedValue 'Nananatiling GREEN ang Patch 01 sa Stage 9'
Assert-StageEqual 'DAY_TAG_PATCH_ACTIVE' $ctx.patch02Status 'Nananatiling aktibo ang Patch 02 sa Stage 9'
Assert-StageEqual (Get-NormDayCount -Day $foundation) $ctx.patch02ActionDayTag 'Nananatiling GREEN ang Patch 02 action sa Stage 9'
Assert-StageEqual (Get-NormDayCount -Day $foundation) $ctx.patch02TargetDayTag 'Nananatiling GREEN ang Patch 02 target sa Stage 9'
Assert-StageEqual 'DISTANCE_PATCH_ACTIVE' $ctx.patch03Status 'Nananatiling aktibo ang Patch 03 sa Stage 9'
Assert-StageEqual ([System.Numerics.BigInteger]1) $ctx.patch03DistanceValue 'Nananatiling GREEN ang Patch 03 sa Stage 9'

Assert-StageEqual 'HISTORICAL_STONE_SCAR_CAPTURED' $ctx.discovery04Status 'Na-capture pa rin ang Discovery 04 historical scar sa production route'
Assert-StageEqual 1 $ctx.discovery04InvocationCount 'Isang Discovery 04 scar capture per production invocation'
Assert-StageEqual 'STONE_PATCH_ACTIVE' $ctx.patch04Status 'Aktibo ang Patch 04 adapter'
Assert-StageEqual 1 $ctx.patch04InvocationCount 'Isang Patch 04 adapter invocation'
Assert-StageEqual 45 $ctx.patch04RowsPatched 'Eksaktong 45 rows ang na-patch'
Assert-StageEqual 46 $ctx.legacyStoneRowsBuilt 'May 46 built stone rows ang production context'

$expected45 = [object[]]@(
    $normTable[45][1],
    $normTable[45][2],
    $normTable[45][3],
    $normTable[45][4],
    $normTable[45][5]
)
$expected46 = [object[]]@(
    $normTable[46][1],
    $normTable[46][2],
    $normTable[46][3],
    $normTable[46][4],
    $normTable[46][5]
)
Assert-StageSequenceEqual $expected45 $ctx.patch04LastOldStones 'Last old snapshot ay normative row 45'
Assert-StageSequenceEqual $expected46 $ctx.patch04LastCommittedStones 'Last committed stones ay normative row 46'
Assert-StageTrue -Condition (-not ([string]::Join(',', $ctx.patch04LastLegacyGarbage) -eq [string]::Join(',', $ctx.patch04LastCommittedStones))) -Name 'Last legacy garbage ay tunay na naiiba sa committed row'
Assert-StageSequenceEqual $expected46 $ctx.legacyStoneTable[46] 'Production stone table row 46 ay GREEN'

Assert-StageEqual 0 $second.patch04RowsPatched 'Walang Patch 04 row leak sa ibang invocation'
Assert-StageTrue -Condition ($null -eq $second.patch04LastOldStones) -Name 'Walang old-snapshot leak sa ibang invocation'
Assert-StageTrue -Condition ($null -eq $second.patch04LastLegacyGarbage) -Name 'Walang garbage leak sa ibang invocation'
Assert-StageTrue -Condition ($null -eq $second.patch04LastCommittedStones) -Name 'Walang committed-stone leak sa ibang invocation'

# Observability neutrality.
$plain = New-BaseMonsterContext -CalculationDay ($foundation - 5) -TargetDay ($foundation + 8)
$noisy = New-BaseMonsterContext -CalculationDay ($foundation - 5) -TargetDay ($foundation + 8)
$noisy.logs.Add([pscustomobject]@{ code='noisy-before'; data=1 })
$noisy.metrics['observability.only'] = [System.Numerics.BigInteger]4242
$noisy.diagnostics.Add([pscustomobject]@{ code='diagnostic'; data=9 })
Invoke-Patch04StoneAdapter -Context $plain | Out-Null
Invoke-Patch04StoneAdapter -Context $noisy | Out-Null
Assert-StageSequenceEqual $plain.legacyStoneTable[46] $noisy.legacyStoneTable[46] 'Hindi binabago ng observability state ang Patch 04 result'

# 6. Production purity at walang Stage 10+.
$monsterText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/MonsterSkeleton.ps1')
$discovery04Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Discovery04.ps1')
$patch04Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Patch04.ps1')
$productionFiles = @(
    'src/Discovery01.ps1',
    'src/Patch01.ps1',
    'src/Discovery02.ps1',
    'src/Patch02.ps1',
    'src/Discovery03.ps1',
    'src/Patch03.ps1',
    'src/Discovery04.ps1',
    'src/Patch04.ps1'
)
$productionText = $monsterText
foreach ($rel in $productionFiles) {
    $productionText += "`n" + (Get-Content -Raw -Encoding UTF8 (Join-Path $root $rel))
}

Assert-StageTrue -Condition ($productionText -notmatch 'Invoke-NormSauce|Get-NormCalendarDate|Get-NormSave|New-NormStoneTable') -Name 'Hindi tumatawag sa normative oracle ang Stage 9 production path'
Assert-StageTrue -Condition ($discovery04Text -match 'function mutateStonesWrong') -Name 'Nananatiling pisikal ang raw mutateStonesWrong scar'
Assert-StageTrue -Condition ($patch04Text -match 'function stonePatch') -Name 'Pisikal at hiwalay ang stonePatch layer'
Assert-StageTrue -Condition ($patch04Text -match 'mutateStonesWrong') -Name 'Talagang tinatawag ng Patch 04 ang raw legacy mutator'
Assert-StageTrue -Condition ($patch04Text -match 'Copy-Discovery04StoneState') -Name 'May hiwalay na old snapshot at legacy clone'
$futureNames = @('orderAt46Latch','biasedLegacyPick','LEGACY_YEAR_MAX','VirtualLegacyList','oldContiguousMonthDayGuess')
foreach ($name in $futureNames) {
    Assert-StageTrue -Condition ($productionText -notmatch [regex]::Escape($name)) -Name "Walang future patch code: $name"
}

Write-Host "PATCH04_GREEN_ROW_COUNT=$greenRowCount"
Write-Host 'PATCH04_ROWS_PATCHED=45'
Write-Host 'PATCH04_LEGACY_SCAR=PRESENT'
Write-Host 'PATCH04_LAST_GARBAGE_DIVERGES=YES'
Write-Host 'STAGE09_REPOSITORY_STATE=GREEN'

$ok = Complete-StageTestRun
if (-not $ok) { exit 1 }
Write-Host 'STAGE09_RESULT=PASS'
exit 0
