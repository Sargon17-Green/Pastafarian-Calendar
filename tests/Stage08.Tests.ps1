Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

. (Join-Path $root 'src/SourceLanguageCatalog.ps1')
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

$foundation = Get-NormFoundationDay
$metadata = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')

Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_STAGE=8\s*$') -Name 'Stage 8 ang kasalukuyang stage'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_KIND=DISCOVERY\s*$') -Name 'Discovery ang kasalukuyang uri'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_PATCH=04\s*$') -Name 'Discovery 04 ang kasalukuyang patch slot'
Assert-StageTrue -Condition ($metadata -match '(?m)^LAST_COMPLETED_STAGE=7\s*$') -Name 'Hindi pa minamarkahang kumpleto ang Stage 8 bago runtime'
Assert-StageTrue -Condition ($metadata -match '(?m)^EXPECTED_REPOSITORY_STATE=RED\s*$') -Name 'RED ang inaasahang Stage 8 repository state'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE07_RUNTIME_VERIFICATION=GREEN_CONFIRMED\s*$') -Name 'Nananatiling nakatala ang Stage 7 GREEN proof'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE08_DISCOVERY=MUTATE_STONES_WRONG\s*$') -Name 'Discovery 04 metadata ay mutateStonesWrong'

$normTable = New-NormStoneTable

$state = New-Discovery04StoneState
$sameObject = $state
$result = mutateStonesWrong -I 2 -State $state
$row2Direct = Get-Discovery04StoneRow -State $result

Assert-StageTrue -Condition ([object]::ReferenceEquals($sameObject, $result)) -Name 'In-place ang mutateStonesWrong at ibinabalik ang parehong state object'
Assert-StageEqual $normTable[2][1] $row2Direct[0] 'Row 2 w ay nagkataong normative'
Assert-StageTrue -Condition ($row2Direct[1] -ne $normTable[2][2]) -Name 'Row 2 b ay nadumihan ng bagong w'
Assert-StageTrue -Condition ($row2Direct[2] -ne $normTable[2][3]) -Name 'Row 2 s ay nadumihan ng bagong b'
Assert-StageTrue -Condition ($row2Direct[3] -ne $normTable[2][4]) -Name 'Row 2 m ay nadumihan ng bagong s'
Assert-StageTrue -Condition ($row2Direct[4] -ne $normTable[2][5]) -Name 'Row 2 r ay nadumihan ng bagong w at m'

$table = Get-Discovery04LegacyStoneTable
Assert-StageEqual 47 $table.Count 'May 47 slots ang legacy stone table'
Assert-StageSequenceEqual ([object[]](17,29,43,71,101)) $table[1] 'Tama ang fixed row 1'

$expectedRedCount = 0
$matchCount = 0
foreach ($rowNumber in @(2,3,46)) {
    $actual = $table[$rowNumber]
    $expected = [object[]]@(
        $normTable[$rowNumber][1],
        $normTable[$rowNumber][2],
        $normTable[$rowNumber][3],
        $normTable[$rowNumber][4],
        $normTable[$rowNumber][5]
    )

    $matches = $true
    for ($i = 0; $i -lt 5; $i++) {
        if ($actual[$i] -ne $expected[$i]) {
            $matches = $false
            break
        }
    }

    if ($matches) {
        $matchCount++
        Write-Host "DISCOVERY04_ROW=$rowNumber CLASSIFICATION=MATCH"
    }
    else {
        $expectedRedCount++
        Write-Host "DISCOVERY04_ROW=$rowNumber CLASSIFICATION=EXPECTED_RED"
    }
}

Assert-StageEqual 3 $expectedRedCount 'Eksaktong tatlong Discovery 04 expected-red rows'
Assert-StageEqual 0 $matchCount 'Walang matching control sa tatlong historical row probes'

$first = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $foundation
$second = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $foundation
Invoke-Discovery04LegacyStoneAdapter -Context $first | Out-Null

Assert-StageEqual 'LEGACY_STONE_MUTATION_ACTIVE' $first.discovery04Status 'Aktibo ang Discovery 04 adapter'
Assert-StageEqual 1 $first.discovery04InvocationCount 'Isang Discovery 04 invocation'
Assert-StageEqual 46 $first.legacyStoneRowsBuilt 'Eksaktong 46 rows ang itinuring na built'
Assert-StageTrue -Condition ($null -ne $first.legacyStoneTable) -Name 'May legacy stone table ang unang invocation'
Assert-StageTrue -Condition ($null -eq $second.legacyStoneTable) -Name 'Walang stone table leak sa ikalawang invocation'
Assert-StageEqual 0 $second.legacyStoneRowsBuilt 'Malinis ang stone row count ng ikalawang invocation'
Assert-StageTrue -Condition (-not [object]::ReferenceEquals($first, $second)) -Name 'Magkahiwalay ang Discovery 04 invocation contexts'
Assert-StageTrue -Condition ([object]::ReferenceEquals($first.legacyStoneTable, $first.semanticCommitted['legacyStoneTable'])) -Name 'Committed ang parehong invocation-owned stone table'
Assert-StageEqual 46 $first.semanticCommitted['legacyStoneRowsBuilt'] 'Committed ang legacy stone row count'

$ctx = Invoke-CalendarDateSpaghetti -CalculationDay $foundation -TargetDay $foundation

Assert-StageEqual 'SAVE_PATCH_ACTIVE' $ctx.patch01Status 'Nananatiling aktibo ang Patch 01 sa Stage 8 production route'
Assert-StageEqual (Get-NormSave -X $foundation) $ctx.patch01PatchedValue 'Nananatiling GREEN ang Patch 01 sa Stage 8 production route'
Assert-StageEqual 'DAY_TAG_PATCH_ACTIVE' $ctx.patch02Status 'Nananatiling aktibo ang Patch 02 sa Stage 8 production route'
Assert-StageEqual (Get-NormDayCount -Day $foundation) $ctx.patch02ActionDayTag 'Nananatiling GREEN ang Patch 02 action sa Stage 8'
Assert-StageEqual (Get-NormDayCount -Day $foundation) $ctx.patch02TargetDayTag 'Nananatiling GREEN ang Patch 02 target sa Stage 8'
Assert-StageEqual 'DISTANCE_PATCH_ACTIVE' $ctx.patch03Status 'Nananatiling aktibo ang Patch 03 sa Stage 8 production route'
Assert-StageEqual ([System.Numerics.BigInteger]1) $ctx.patch03DistanceValue 'Nananatiling GREEN ang Patch 03 distance sa same-day probe'
Assert-StageEqual 'LEGACY_STONE_MUTATION_ACTIVE' $ctx.discovery04Status 'Dumaan ang tunay na production route sa Discovery 04'
Assert-StageEqual 1 $ctx.discovery04InvocationCount 'Isang Discovery 04 build sa production route'
Assert-StageEqual 46 $ctx.legacyStoneRowsBuilt 'Nabuo ang legacy rows 1 hanggang 46 sa production route'
Assert-StageTrue -Condition ($ctx.metrics.ContainsKey('discovery04.legacyStoneTable.builds')) -Name 'May Discovery 04 metric'
Assert-StageTrue -Condition (@($ctx.logs | Where-Object { $_.code -eq 'monster.discovery04.legacyStone.adapter' }).Count -eq 1) -Name 'May Discovery 04 adapter log'

$monsterText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/MonsterSkeleton.ps1')
$discovery04Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Discovery04.ps1')
$productionFiles = @(
    'src/Discovery01.ps1',
    'src/Patch01.ps1',
    'src/Discovery02.ps1',
    'src/Patch02.ps1',
    'src/Discovery03.ps1',
    'src/Patch03.ps1',
    'src/Discovery04.ps1'
)
$productionText = $monsterText
foreach ($rel in $productionFiles) {
    $productionText += "`n" + (Get-Content -Raw -Encoding UTF8 (Join-Path $root $rel))
}

Assert-StageTrue -Condition ($productionText -notmatch 'Invoke-NormSauce|Get-NormCalendarDate|Get-NormSave|New-NormStoneTable') -Name 'Hindi tumatawag sa normative oracle ang Stage 8 production path'
Assert-StageTrue -Condition ($discovery04Text -match 'function mutateStonesWrong') -Name 'Pisikal at hiwalay ang mutateStonesWrong historical scar'
Assert-StageTrue -Condition ($discovery04Text -match '\$State\[''b''\].*\$State\[''w''\]' -or $discovery04Text -match '\$State\[''w''\]') -Name 'Sequential mutable-state implementation ang historical stone scar'
Assert-StageTrue -Condition ($productionText -notmatch 'function\s+stonePatch') -Name 'Walang Stage 9 stonePatch correction'
Assert-StageTrue -Condition ($productionText -notmatch 'legacyStoneGarbage|patch04LastOldStones|patch04RowsPatched') -Name 'Walang Stage 9 snapshot o garbage state'
$futureNames = @('orderAt46Latch','biasedLegacyPick','LEGACY_YEAR_MAX','VirtualLegacyList','oldContiguousMonthDayGuess')
foreach ($name in $futureNames) {
    Assert-StageTrue -Condition ($productionText -notmatch [regex]::Escape($name)) -Name "Walang future patch code: $name"
}

Write-Host "DISCOVERY04_EXPECTED_RED_COUNT=$expectedRedCount"
Write-Host "DISCOVERY04_MATCH_COUNT=$matchCount"
Write-Host 'DISCOVERY04_ROW2_FIRST_STONE_MATCH=YES'
Write-Host 'DISCOVERY04_REPOSITORY_STATE=EXPECTED_RED'

$ok = Complete-StageTestRun
if (-not $ok) { exit 1 }
Write-Host 'STAGE08_RESULT=PASS'
exit 0
