Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

. (Join-Path $root 'src/SourceLanguageCatalog.ps1')
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

$m = Get-NormM
$zero = [System.Numerics.BigInteger]::Zero
$one = [System.Numerics.BigInteger]::One

$metadata = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_STAGE=3\s*$') -Name 'Stage 3 ang kasalukuyang stage'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_KIND=PATCH\s*$') -Name 'Patch ang kasalukuyang uri'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_PATCH=01\s*$') -Name 'Patch 01 ang kasalukuyang patch slot'
Assert-StageTrue -Condition ($metadata -match '(?m)^LAST_COMPLETED_STAGE=2\s*$') -Name 'Hindi pa minamarkahang kumpleto ang Stage 3 bago runtime'
Assert-StageTrue -Condition ($metadata -match '(?m)^EXPECTED_REPOSITORY_STATE=GREEN\s*$') -Name 'GREEN ang inaasahang repository state'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE02_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED\s*$') -Name 'Nananatiling nakatala ang Stage 2 discovery proof'

# Dapat manatili ang historical scar.
Assert-StageEqual $zero (oldRemainder -X $m) 'Nananatili ang oldRemainder(M)=0 historical scar'
Assert-StageEqual $zero (oldRemainder -X (2 * $m)) 'Nananatili ang oldRemainder(2M)=0 historical scar'
Assert-StageEqual $zero (oldRemainder -X (3 * $m)) 'Nananatili ang oldRemainder(3M)=0 historical scar'
Assert-StageEqual $one (oldRemainder -X ($m + 1)) 'Nananatili ang oldRemainder(M+1)=1 control behavior'

# Eksaktong save patch: zero lamang ang minamapa sa M.
Assert-StageEqual $m (savePatch -LegacyRemainder $zero) 'savePatch(0) ay M'
Assert-StageEqual $one (savePatch -LegacyRemainder $one) 'savePatch(1) ay 1'
Assert-StageEqual ($m - 1) (savePatch -LegacyRemainder ($m - 1)) 'Hindi binabago ng savePatch ang M-1'

$greenCount = 0
$cases = @(
    [pscustomobject]@{ label = 'M'; value = $m },
    [pscustomobject]@{ label = '2M'; value = 2 * $m },
    [pscustomobject]@{ label = '3M'; value = 3 * $m },
    [pscustomobject]@{ label = 'M+1'; value = $m + 1 },
    [pscustomobject]@{ label = 'ZERO'; value = $zero },
    [pscustomobject]@{ label = 'NEG_M'; value = -$m },
    [pscustomobject]@{ label = 'NEG_ONE'; value = -$one }
)

foreach ($case in $cases) {
    $ctx = Invoke-CalendarDateSpaghetti -CalculationDay $case.value -TargetDay $zero
    $actual = [System.Numerics.BigInteger]$ctx.patch01PatchedValue
    $expected = [System.Numerics.BigInteger](Get-NormSave -X $case.value)
    $legacyExpected = [System.Numerics.BigInteger](oldRemainder -X $case.value)

    Assert-StageEqual 'SAVE_PATCH_ACTIVE' $ctx.patch01Status "Aktibo ang Patch 01 adapter para sa $($case.label)"
    Assert-StageEqual 1 $ctx.patch01InvocationCount "Isang Patch 01 adapter invocation para sa $($case.label)"
    Assert-StageEqual $legacyExpected $ctx.legacyRemainderValue "Napanatili ang legacy value para sa $($case.label)"
    Assert-StageEqual $expected $actual "GREEN production value para sa $($case.label)"
    Assert-StageEqual $case.value ([System.Numerics.BigInteger]$ctx.semanticCommitted['legacyRemainderInput']) "Committed ang input para sa $($case.label)"
    Assert-StageEqual $legacyExpected ([System.Numerics.BigInteger]$ctx.semanticCommitted['legacyRemainderValue']) "Committed ang legacy value para sa $($case.label)"
    Assert-StageEqual $expected ([System.Numerics.BigInteger]$ctx.semanticCommitted['patch01PatchedValue']) "Committed ang patched value para sa $($case.label)"
    Assert-StageTrue -Condition ($ctx.metrics.ContainsKey('patch01.save.calls')) -Name "May per-invocation Patch 01 metric para sa $($case.label)"
    Assert-StageTrue -Condition (@($ctx.logs | Where-Object { $_.code -eq 'monster.patch01.save.adapter' }).Count -eq 1) -Name "Dumaan sa Patch 01 adapter route para sa $($case.label)"

    if ($actual -eq $expected) {
        $greenCount++
        Write-Host "PATCH01_CASE=$($case.label) LEGACY=$legacyExpected PATCHED=$actual EXPECTED=$expected CLASSIFICATION=GREEN"
    }
    else {
        Write-Host "PATCH01_CASE=$($case.label) LEGACY=$legacyExpected PATCHED=$actual EXPECTED=$expected CLASSIFICATION=FAIL"
        Assert-StageTrue -Condition $false -Name "Hindi GREEN ang Patch 01 para sa $($case.label)"
    }
}

Assert-StageEqual $cases.Count $greenCount 'Lahat ng Patch 01 regression cases ay GREEN'

# Dapat makita ang mismong correction sa dating divergent surface.
$ctxM = Invoke-CalendarDateSpaghetti -CalculationDay $m -TargetDay $zero
Assert-StageEqual $zero $ctxM.legacyRemainderValue 'Legacy M ay nananatiling zero sa context'
Assert-StageEqual $m $ctxM.patch01PatchedValue 'Patched M ay M sa context'

# Per-invocation ownership.
$ctxA = Invoke-CalendarDateSpaghetti -CalculationDay $m -TargetDay $zero
$ctxB = Invoke-CalendarDateSpaghetti -CalculationDay ($m + 1) -TargetDay $zero
Assert-StageTrue -Condition (-not [object]::ReferenceEquals($ctxA, $ctxB)) -Name 'Magkahiwalay ang Patch 01 invocation contexts'
Assert-StageEqual $m $ctxA.patch01PatchedValue 'Hindi nabago ang unang patched invocation state'
Assert-StageEqual $one $ctxB.patch01PatchedValue 'Sarili ang patched state ng ikalawang invocation'
Assert-StageEqual $m ([System.Numerics.BigInteger]$ctxA.semanticCommitted['patch01PatchedValue']) 'Hiwalay ang committed patched state A'
Assert-StageEqual $one ([System.Numerics.BigInteger]$ctxB.semanticCommitted['patch01PatchedValue']) 'Hiwalay ang committed patched state B'

$monsterText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/MonsterSkeleton.ps1')
$discoveryText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Discovery01.ps1')
$patchText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Patch01.ps1')
$productionText = $monsterText + "`n" + $discoveryText + "`n" + $patchText

Assert-StageTrue -Condition ($productionText -notmatch 'Invoke-NormSauce|Get-NormCalendarDate|Get-NormSave') -Name 'Hindi tumatawag sa normative oracle ang Stage 3 production path'
Assert-StageTrue -Condition ($discoveryText -match 'function oldRemainder') -Name 'Nananatiling hiwalay ang Discovery 01 legacy function'
Assert-StageTrue -Condition ($patchText -match 'function savePatch') -Name 'Hiwalay ang Patch 01 correction function'
Assert-StageTrue -Condition ($patchText -match 'Invoke-Patch01SaveAdapter') -Name 'May hiwalay na Patch 01 adapter'
$futureNames = @('oldDayTag','oldDistance','mutateStonesWrong','orderAt46Latch','biasedLegacyPick','LEGACY_YEAR_MAX','VirtualLegacyList','oldContiguousMonthDayGuess')
foreach ($name in $futureNames) {
    Assert-StageTrue -Condition ($productionText -notmatch [regex]::Escape($name)) -Name "Walang future patch code: $name"
}

Write-Host "PATCH01_GREEN_COUNT=$greenCount"
Write-Host "PATCH01_CASE_COUNT=$($cases.Count)"
Write-Host 'STAGE03_REPOSITORY_STATE=GREEN'

$ok = Complete-StageTestRun
if (-not $ok) { exit 1 }
Write-Host 'STAGE03_RESULT=PASS'
exit 0
