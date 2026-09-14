Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

. (Join-Path $root 'src/SourceLanguageCatalog.ps1')
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

function Get-Stage10NormHiddenCoeff {
    param([Parameter(Mandatory)][int]$K)
    switch ($K) {
        1 { return ,([int[]](3,4,6,8)) }
        2 { return ,([int[]](5,7,10,12)) }
        3 { return ,([int[]](7,10,14,16)) }
        4 { return ,([int[]](9,13,18,20)) }
        5 { return ,([int[]](11,16,22,24)) }
        6 { return ,([int[]](13,19,26,28)) }
        7 { return ,([int[]](15,22,30,32)) }
        default { throw 'Stage 10 normative hidden k must be 1..7.' }
    }
}

function Get-Stage10NormHiddenValues {
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$CalculationDay,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$TargetDay
    )

    $counts = Get-NormWorkCounts $CalculationDay $TargetDay
    $stones = New-NormStoneTable
    $stoneKinds = [int[]](0,1,2,3,4,0,1)
    $hidden = [object[]]::new(8)

    for ($k = 1; $k -le 7; $k++) {
        $coeff = Get-Stage10NormHiddenCoeff -K $k
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

Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_STAGE=10\s*$') -Name 'Stage 10 ang kasalukuyang stage'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_KIND=DISCOVERY\s*$') -Name 'Discovery ang kasalukuyang uri'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_PATCH=05\s*$') -Name 'Discovery 05 ang kasalukuyang patch slot'
Assert-StageTrue -Condition ($metadata -match '(?m)^LAST_COMPLETED_STAGE=9\s*$') -Name 'Hindi pa minamarkahang kumpleto ang Stage 10 bago runtime'
Assert-StageTrue -Condition ($metadata -match '(?m)^EXPECTED_REPOSITORY_STATE=RED\s*$') -Name 'RED ang inaasahang Stage 10 repository state'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE09_RUNTIME_VERIFICATION=GREEN_CONFIRMED\s*$') -Name 'Nananatiling nakatala ang Stage 9 GREEN proof'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE10_DISCOVERY=BACKWARD_HIDDEN_DIRECT_ACCESS\s*$') -Name 'Discovery 05 metadata ay backward hidden direct access'

$ctx = Invoke-CalendarDateSpaghetti -CalculationDay $foundation -TargetDay $target
$normative = Get-Stage10NormHiddenValues -CalculationDay $foundation -TargetDay $target

Assert-StageEqual 'SAVE_PATCH_ACTIVE' $ctx.patch01Status 'Nananatiling aktibo ang Patch 01 sa Stage 10 production route'
Assert-StageEqual (Get-NormSave -X $foundation) $ctx.patch01PatchedValue 'Nananatiling GREEN ang Patch 01 sa Stage 10'
Assert-StageEqual 'DAY_TAG_PATCH_ACTIVE' $ctx.patch02Status 'Nananatiling aktibo ang Patch 02 sa Stage 10'
Assert-StageEqual (Get-NormDayCount -Day $foundation) $ctx.patch02ActionDayTag 'Nananatiling GREEN ang Patch 02 action sa Stage 10'
Assert-StageEqual (Get-NormDayCount -Day $target) $ctx.patch02TargetDayTag 'Nananatiling GREEN ang Patch 02 target sa Stage 10'
Assert-StageEqual 'DISTANCE_PATCH_ACTIVE' $ctx.patch03Status 'Nananatiling aktibo ang Patch 03 sa Stage 10'
Assert-StageEqual ([System.Numerics.BigInteger]4) $ctx.patch03DistanceValue 'Nananatiling GREEN ang Patch 03 distance sa Stage 10'
Assert-StageEqual 'STONE_PATCH_ACTIVE' $ctx.patch04Status 'Nananatiling aktibo ang Patch 04 sa Stage 10'
Assert-StageEqual 45 $ctx.patch04RowsPatched 'Nananatiling 45 ang patched stone rows sa Stage 10'

$normStones = New-NormStoneTable
$expectedStone46 = [object[]]@(
    $normStones[46][1],
    $normStones[46][2],
    $normStones[46][3],
    $normStones[46][4],
    $normStones[46][5]
)
Assert-StageSequenceEqual $expectedStone46 $ctx.legacyStoneTable[46] 'Nananatiling GREEN ang patched stone table bago ang hidden layer'

Assert-StageEqual 'BACKWARD_HIDDEN_STORAGE_ACTIVE' $ctx.discovery05Status 'Aktibo ang Discovery 05 hidden adapter sa production route'
Assert-StageEqual 1 $ctx.discovery05InvocationCount 'Isang Discovery 05 storage build sa production route'
Assert-StageEqual 7 $ctx.legacyHiddenCount 'Eksaktong pitong hidden drops ang nasa legacy storage'
Assert-StageTrue -Condition ($null -ne $ctx.legacyHiddenStorage) -Name 'May invocation-owned backward hidden storage'

# Physical storage really is hidden7..hidden1.
Assert-StageEqual $normative[7] $ctx.legacyHiddenStorage[1] 'Physical slot 1 ay hidden7'
Assert-StageEqual $normative[6] $ctx.legacyHiddenStorage[2] 'Physical slot 2 ay hidden6'
Assert-StageEqual $normative[5] $ctx.legacyHiddenStorage[3] 'Physical slot 3 ay hidden5'
Assert-StageEqual $normative[4] $ctx.legacyHiddenStorage[4] 'Physical slot 4 ay hidden4'
Assert-StageEqual $normative[3] $ctx.legacyHiddenStorage[5] 'Physical slot 5 ay hidden3'
Assert-StageEqual $normative[2] $ctx.legacyHiddenStorage[6] 'Physical slot 6 ay hidden2'
Assert-StageEqual $normative[1] $ctx.legacyHiddenStorage[7] 'Physical slot 7 ay hidden1'

# The real production route performs the historical wrong k=1 read.
Assert-StageEqual 1 $ctx.legacyHiddenLastRequestedK 'Ang production route ay talagang humihiling ng near-ness k=1'
Assert-StageEqual $ctx.legacyHiddenStorage[1] $ctx.legacyHiddenLastReturnedValue 'Ang production route ay direktang bumabasa sa physical slot 1'
Assert-StageTrue -Condition ($ctx.legacyHiddenLastReturnedValue -ne $normative[1]) -Name 'Ang tunay na production k=1 read ay EXPECTED_RED'

$expectedRedCount = 0
$matchCount = 0

foreach ($k in @(1,2,4,6,7)) {
    $actual = [System.Numerics.BigInteger](
        Read-Discovery05LegacyHiddenByAssumedNearness -Context $ctx -K $k
    )
    $expected = [System.Numerics.BigInteger]$normative[$k]

    if ($actual -eq $expected) {
        $matchCount++
        Write-Host "DISCOVERY05_K=$k ACTUAL=$actual EXPECTED=$expected CLASSIFICATION=MATCH"
        Assert-StageEqual 4 $k "Tanging k=4 ang dapat MATCH; aktuwal na MATCH k=$k"
    }
    else {
        $expectedRedCount++
        Write-Host "DISCOVERY05_K=$k ACTUAL=$actual EXPECTED=$expected CLASSIFICATION=EXPECTED_RED ERROR_ID=Pastafari:Discovery05:BackwardHiddenDirectAccess"
        Assert-StageTrue -Condition ($k -in @(1,2,6,7)) -Name "Tamang EXPECTED_RED k=$k"
    }
}

Assert-StageEqual 4 $expectedRedCount 'Eksaktong apat na Discovery 05 EXPECTED_RED accesses'
Assert-StageEqual 1 $matchCount 'Eksaktong isang Discovery 05 MATCH access'
Assert-StageEqual 4 (
    @(
        1,2,6,7 | Where-Object {
            $ctx.legacyHiddenStorage[$_] -ne $normative[$_]
        }
    ).Count
) 'Ang k=1,2,6,7 ay lahat divergent'
Assert-StageEqual $normative[4] $ctx.legacyHiddenStorage[4] 'Ang k=4 ay fixed midpoint at nananatiling tama'

# Invocation ownership.
$clean = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
Assert-StageTrue -Condition ($null -eq $clean.legacyHiddenStorage) -Name 'Walang hidden storage leak sa bagong invocation'
Assert-StageEqual 0 $clean.legacyHiddenCount 'Walang hidden count leak sa bagong invocation'
Assert-StageTrue -Condition ($null -eq $clean.legacyHiddenLastRequestedK) -Name 'Walang requested-k leak sa bagong invocation'
Assert-StageTrue -Condition ($null -eq $clean.legacyHiddenLastReturnedValue) -Name 'Walang returned-value leak sa bagong invocation'

Assert-StageTrue -Condition ([object]::ReferenceEquals($ctx.legacyHiddenStorage, $ctx.semanticCommitted['legacyHiddenStorage'])) -Name 'Committed ang parehong invocation-owned hidden storage'
Assert-StageEqual 7 $ctx.semanticCommitted['legacyHiddenCount'] 'Committed ang hidden count'
Assert-StageEqual 7 $ctx.semanticCommitted['legacyHiddenLastRequestedK'] 'Committed ang huling requested k pagkatapos ng probe sequence'
Assert-StageEqual $ctx.legacyHiddenLastReturnedValue $ctx.semanticCommitted['legacyHiddenLastReturnedValue'] 'Committed ang huling wrong-read value'

# Production purity and no Patch 05 yet.
$monsterText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/MonsterSkeleton.ps1')
$discovery05Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Discovery05.ps1')
$productionFiles = @(
    'src/Discovery01.ps1',
    'src/Patch01.ps1',
    'src/Discovery02.ps1',
    'src/Patch02.ps1',
    'src/Discovery03.ps1',
    'src/Patch03.ps1',
    'src/Discovery04.ps1',
    'src/Patch04.ps1',
    'src/Discovery05.ps1'
)
$productionText = $monsterText
foreach ($rel in $productionFiles) {
    $productionText += "`n" + (Get-Content -Raw -Encoding UTF8 (Join-Path $root $rel))
}

Assert-StageTrue -Condition ($productionText -notmatch 'Invoke-NormSauce|Get-NormCalendarDate|Get-NormSave|New-NormStoneTable') -Name 'Hindi tumatawag sa normative oracle ang Stage 10 production path'
Assert-StageTrue -Condition ($discovery05Text -match 'legacyHiddenDirectByAssumedNearness') -Name 'Pisikal ang wrong direct hidden accessor scar'
Assert-StageTrue -Condition ($discovery05Text -match '\$legacyHidden\[8 - \$k\]') -Name 'Pisikal na backward ang hidden storage'
Assert-StageTrue -Condition ($productionText -notmatch 'function\s+hiddenByNearness') -Name 'Wala pang Stage 11 hiddenByNearness translator'
$futureNames = @('orderAt46Latch','biasedLegacyPick','LEGACY_YEAR_MAX','VirtualLegacyList','oldContiguousMonthDayGuess')
foreach ($name in $futureNames) {
    Assert-StageTrue -Condition ($productionText -notmatch [regex]::Escape($name)) -Name "Walang future patch code: $name"
}

Write-Host "DISCOVERY05_EXPECTED_RED_COUNT=$expectedRedCount"
Write-Host "DISCOVERY05_MATCH_COUNT=$matchCount"
Write-Host 'DISCOVERY05_BACKWARD_STORAGE=HIDDEN7_TO_HIDDEN1'
Write-Host 'DISCOVERY05_FIXED_MIDPOINT_K4=MATCH'
Write-Host 'STAGE10_REPOSITORY_STATE=EXPECTED_RED'

$ok = Complete-StageTestRun
if (-not $ok) { exit 1 }
Write-Host 'STAGE10_RESULT=PASS'
exit 0
