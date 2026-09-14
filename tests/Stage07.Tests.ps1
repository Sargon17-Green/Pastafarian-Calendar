Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

. (Join-Path $root 'src/SourceLanguageCatalog.ps1')
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

$foundation = Get-NormFoundationDay

$metadata = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_STAGE=7\s*$') -Name 'Stage 7 ang kasalukuyang stage'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_KIND=PATCH\s*$') -Name 'Patch ang kasalukuyang uri'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_PATCH=03\s*$') -Name 'Patch 03 ang kasalukuyang patch slot'
Assert-StageTrue -Condition ($metadata -match '(?m)^LAST_COMPLETED_STAGE=6\s*$') -Name 'Hindi pa minamarkahang kumpleto ang Stage 7 bago runtime'
Assert-StageTrue -Condition ($metadata -match '(?m)^EXPECTED_REPOSITORY_STATE=GREEN\s*$') -Name 'GREEN ang inaasahang Stage 7 repository state'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE06_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED\s*$') -Name 'Nananatiling nakatala ang Stage 6 expected-red proof'

# Raw historical scar remains physically wrong.
Assert-StageEqual 0 (oldDistance -CalculationDay $foundation -TargetDay $foundation) 'Nananatili ang raw oldDistance(F,F)=0'
Assert-StageEqual 6 (oldDistance -CalculationDay $foundation -TargetDay ($foundation + 3)) 'Nananatili ang raw oldDistance(F,F+3)=6'
Assert-StageEqual 1 (oldDistance -CalculationDay ($foundation - 3) -TargetDay ($foundation + 3)) 'Nananatili ang raw oldDistance(F-3,F+3)=1'

$cases = @(
    [pscustomobject]@{ label='SAME_DAY'; calculation=$foundation; target=$foundation; expectedReplace=$false },
    [pscustomobject]@{ label='F_TO_F_PLUS_1'; calculation=$foundation; target=$foundation+1; expectedReplace=$true },
    [pscustomobject]@{ label='F_TO_F_PLUS_3'; calculation=$foundation; target=$foundation+3; expectedReplace=$true },
    [pscustomobject]@{ label='F_MINUS_1_TO_F'; calculation=$foundation-1; target=$foundation; expectedReplace=$false },
    [pscustomobject]@{ label='CROSS_F'; calculation=$foundation-3; target=$foundation+3; expectedReplace=$true },
    [pscustomobject]@{ label='AFTER_REVERSE'; calculation=$foundation+9; target=$foundation+2; expectedReplace=$true },
    [pscustomobject]@{ label='BEFORE_FORWARD'; calculation=$foundation-9; target=$foundation-2; expectedReplace=$true }
)

$greenCount = 0
$replacementCount = 0
$keptCount = 0

foreach ($case in $cases) {
    $capture = [System.Collections.Generic.List[System.Numerics.BigInteger]]::new()
    $helperResult = [System.Numerics.BigInteger](patchedCounts `
        -CalculationDay $case.calculation `
        -TargetDay $case.target `
        -LegacyCapture $capture)
    $expected = [System.Numerics.BigInteger](Get-NormWorkCounts `
        -CalculationDay $case.calculation `
        -TargetDay $case.target).distance
    $raw = [System.Numerics.BigInteger](oldDistance `
        -CalculationDay $case.calculation `
        -TargetDay $case.target)
    $chronological = [System.Numerics.BigInteger]::Abs($case.target - $case.calculation)

    Assert-StageEqual 1 $capture.Count "Eksaktong isang raw capture para sa $($case.label)"
    Assert-StageEqual $raw $capture[0] "Capture ay raw oldDistance para sa $($case.label)"
    Assert-StageEqual $expected $helperResult "patchedCounts ay normative para sa $($case.label)"

    $ctx = Invoke-CalendarDateSpaghetti -CalculationDay $case.calculation -TargetDay $case.target

    Assert-StageEqual 'SAVE_PATCH_ACTIVE' $ctx.patch01Status "Nananatiling aktibo ang Patch 01 para sa $($case.label)"
    Assert-StageEqual (Get-NormSave -X $case.calculation) $ctx.patch01PatchedValue "Nananatiling GREEN ang Patch 01 para sa $($case.label)"
    Assert-StageEqual 'DAY_TAG_PATCH_ACTIVE' $ctx.patch02Status "Nananatiling aktibo ang Patch 02 para sa $($case.label)"
    Assert-StageEqual (Get-NormDayCount -Day $case.calculation) $ctx.patch02ActionDayTag "GREEN ang Patch 02 action para sa $($case.label)"
    Assert-StageEqual (Get-NormDayCount -Day $case.target) $ctx.patch02TargetDayTag "GREEN ang Patch 02 target para sa $($case.label)"

    Assert-StageEqual 'DISTANCE_PATCH_ACTIVE' $ctx.patch03Status "Aktibo ang Patch 03 para sa $($case.label)"
    Assert-StageEqual 1 $ctx.patch03InvocationCount "Isang Patch 03 invocation para sa $($case.label)"
    Assert-StageEqual $raw $ctx.legacyDistanceValue "Napanatili ang raw distance scar para sa $($case.label)"
    Assert-StageEqual $chronological $ctx.patch03ChronologicalDistance "Tamang chronological distance para sa $($case.label)"
    Assert-StageEqual $expected $ctx.patch03DistanceValue "GREEN patched distance para sa $($case.label)"
    Assert-StageEqual $case.expectedReplace $ctx.patch03LegacyReplaced "Tamang replacement flag para sa $($case.label)"
    Assert-StageEqual $true $ctx.patch03Applied "Applied ang Patch 03 para sa $($case.label)"
    Assert-StageEqual $raw ([System.Numerics.BigInteger]$ctx.semanticCommitted['legacyDistanceValue']) "Committed raw legacy distance para sa $($case.label)"
    Assert-StageEqual $expected ([System.Numerics.BigInteger]$ctx.semanticCommitted['patch03DistanceValue']) "Committed patched distance para sa $($case.label)"
    Assert-StageTrue -Condition ($ctx.metrics.ContainsKey('patch03.distance.calls')) -Name "May Patch 03 metric para sa $($case.label)"
    Assert-StageTrue -Condition (@($ctx.logs | Where-Object { $_.code -eq 'monster.patch03.distance.adapter' }).Count -eq 1) -Name "Dumaan sa Patch 03 adapter para sa $($case.label)"

    if ($ctx.patch03DistanceValue -eq $expected) {
        $greenCount++
        Write-Host "PATCH03_CASE=$($case.label) RAW=$raw CHRONOLOGICAL=$chronological PATCHED=$expected REPLACED=$($ctx.patch03LegacyReplaced) CLASSIFICATION=GREEN"
    }

    if ($ctx.patch03LegacyReplaced) { $replacementCount++ } else { $keptCount++ }
}

Assert-StageEqual 7 $greenCount 'Lahat ng pitong Patch 03 edge probes ay GREEN'
Assert-StageEqual 5 $replacementCount 'Eksaktong limang Patch 03 probes ang pumalit sa raw legacy distance'
Assert-StageEqual 2 $keptCount 'Eksaktong dalawang Patch 03 probes ang hindi nangangailangan ng replacement'

# Explicitly prove final +1 on a nonreplacement branch.
$noReplaceCapture = [System.Collections.Generic.List[System.Numerics.BigInteger]]::new()
$noReplaceResult = patchedCounts `
    -CalculationDay ($foundation - 1) `
    -TargetDay $foundation `
    -LegacyCapture $noReplaceCapture
Assert-StageEqual 1 $noReplaceCapture[0] 'Raw nonreplacement legacy distance ay 1'
Assert-StageEqual 1 ([System.Numerics.BigInteger]::Abs($foundation - ($foundation - 1))) 'Chronological nonreplacement difference ay 1'
Assert-StageEqual 2 $noReplaceResult 'May final inclusive +1 kahit walang replacement'

# Per-invocation ownership and observability neutrality.
$plain = New-BaseMonsterContext -CalculationDay ($foundation - 5) -TargetDay ($foundation + 8)
$noisy = New-BaseMonsterContext -CalculationDay ($foundation - 5) -TargetDay ($foundation + 8)
$noisy.logs.Add([pscustomobject]@{ code='noisy-before'; data=1 })
$noisy.metrics['observability.only'] = [System.Numerics.BigInteger]777
$noisy.diagnostics.Add([pscustomobject]@{ code='diagnostic'; data=2 })
Invoke-Patch01SaveAdapter -Context $plain -Value $plain.calculationDay | Out-Null
Invoke-Patch02DayTagAdapter -Context $plain | Out-Null
Invoke-Patch01SaveAdapter -Context $noisy -Value $noisy.calculationDay | Out-Null
Invoke-Patch02DayTagAdapter -Context $noisy | Out-Null
Invoke-Patch03DistanceAdapter -Context $plain | Out-Null
Invoke-Patch03DistanceAdapter -Context $noisy | Out-Null
Assert-StageEqual $plain.patch03DistanceValue $noisy.patch03DistanceValue 'Hindi binabago ng observability state ang Patch 03 result'

$ctxA = Invoke-CalendarDateSpaghetti -CalculationDay $foundation -TargetDay ($foundation + 3)
$ctxB = Invoke-CalendarDateSpaghetti -CalculationDay ($foundation - 1) -TargetDay $foundation
Assert-StageTrue -Condition (-not [object]::ReferenceEquals($ctxA, $ctxB)) -Name 'Magkahiwalay ang Patch 03 invocation contexts'
Assert-StageEqual 4 $ctxA.patch03DistanceValue 'Hindi nabago ang unang patched distance state'
Assert-StageEqual 2 $ctxB.patch03DistanceValue 'Sarili ang patched distance state ng ikalawang invocation'

$monsterText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/MonsterSkeleton.ps1')
$productionFiles = @(
    'src/Discovery01.ps1',
    'src/Patch01.ps1',
    'src/Discovery02.ps1',
    'src/Patch02.ps1',
    'src/Discovery03.ps1',
    'src/Patch03.ps1'
)
$productionText = $monsterText
foreach ($rel in $productionFiles) {
    $productionText += "`n" + (Get-Content -Raw -Encoding UTF8 (Join-Path $root $rel))
}
$discovery03Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Discovery03.ps1')
$patch03Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Patch03.ps1')

Assert-StageTrue -Condition ($productionText -notmatch 'Invoke-NormSauce|Get-NormCalendarDate|Get-NormSave|Get-NormDayCount|Get-NormWorkCounts') -Name 'Hindi tumatawag sa normative oracle ang Stage 7 production path'
Assert-StageTrue -Condition ($discovery03Text -match 'function oldDistance') -Name 'Nananatiling hiwalay at pisikal ang oldDistance scar'
Assert-StageTrue -Condition ($patch03Text -match 'function patchedCounts') -Name 'May hiwalay na patchedCounts helper'
Assert-StageTrue -Condition ($patch03Text -match 'oldDistance') -Name 'Talagang tumatawag ang Patch 03 sa raw oldDistance'
Assert-StageTrue -Condition ($patch03Text -match '\$legacy -ne \$chronological') -Name 'Pisikal ang conditional chronological replacement'
Assert-StageTrue -Condition ($patch03Text -match '\$legacy \+ \[System\.Numerics\.BigInteger\]::One') -Name 'Pisikal ang final inclusive +1'
Assert-StageTrue -Condition ($productionText -notmatch 'mutateStonesWrong') -Name 'Walang Stage 8 Discovery 04 logic'
$futureNames = @('orderAt46Latch','biasedLegacyPick','LEGACY_YEAR_MAX','VirtualLegacyList','oldContiguousMonthDayGuess')
foreach ($name in $futureNames) {
    Assert-StageTrue -Condition ($productionText -notmatch [regex]::Escape($name)) -Name "Walang future patch code: $name"
}

Write-Host "PATCH03_GREEN_COUNT=$greenCount"
Write-Host "PATCH03_REPLACEMENT_COUNT=$replacementCount"
Write-Host "PATCH03_KEPT_COUNT=$keptCount"
Write-Host 'PATCH03_OLD_DISTANCE_SCAR=PRESENT'
Write-Host 'STAGE07_REPOSITORY_STATE=GREEN'

$ok = Complete-StageTestRun
if (-not $ok) { exit 1 }
Write-Host 'STAGE07_RESULT=PASS'
exit 0
