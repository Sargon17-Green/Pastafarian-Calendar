Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

. (Join-Path $root 'src/SourceLanguageCatalog.ps1')
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

$foundation = Get-NormFoundationDay

$metadata = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_STAGE=5\s*$') -Name 'Stage 5 ang kasalukuyang stage'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_KIND=PATCH\s*$') -Name 'Patch ang kasalukuyang uri'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_PATCH=02\s*$') -Name 'Patch 02 ang kasalukuyang patch slot'
Assert-StageTrue -Condition ($metadata -match '(?m)^LAST_COMPLETED_STAGE=4\s*$') -Name 'Hindi pa minamarkahang kumpleto ang Stage 5 bago runtime'
Assert-StageTrue -Condition ($metadata -match '(?m)^EXPECTED_REPOSITORY_STATE=GREEN\s*$') -Name 'GREEN ang inaasahang Stage 5 repository state'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE04_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED\s*$') -Name 'Nananatiling nakatala ang Stage 4 discovery proof'

# Raw historical scar must remain.
Assert-StageEqual 4 (oldDayTag -Day ($foundation - 2)) 'Nananatili ang raw oldDayTag(FOUNDATION-2)=4'
Assert-StageEqual 2 (oldDayTag -Day ($foundation - 1)) 'Nananatili ang raw oldDayTag(FOUNDATION-1)=2'
Assert-StageEqual 0 (oldDayTag -Day $foundation) 'Nananatili ang raw oldDayTag(FOUNDATION)=0'
Assert-StageEqual 2 (oldDayTag -Day ($foundation + 1)) 'Nananatili ang raw oldDayTag(FOUNDATION+1)=2'
Assert-StageEqual 4 (oldDayTag -Day ($foundation + 2)) 'Nananatili ang raw oldDayTag(FOUNDATION+2)=4'

# Patch helper must be normative on both sides of Foundation.
$helperCases = @(
    [pscustomobject]@{ label = 'F_MINUS_2'; value = $foundation - 2; expected = 4 },
    [pscustomobject]@{ label = 'F_MINUS_1'; value = $foundation - 1; expected = 2 },
    [pscustomobject]@{ label = 'F'; value = $foundation; expected = 1 },
    [pscustomobject]@{ label = 'F_PLUS_1'; value = $foundation + 1; expected = 3 },
    [pscustomobject]@{ label = 'F_PLUS_2'; value = $foundation + 2; expected = 5 }
)
foreach ($case in $helperCases) {
    $capture = [System.Collections.Generic.List[System.Numerics.BigInteger]]::new()
    $patched = [System.Numerics.BigInteger](dayTagWithFoundationScar -Day $case.value -LegacyCapture $capture)
    Assert-StageEqual 1 $capture.Count "Eksaktong isang raw capture para sa $($case.label)"
    Assert-StageEqual (oldDayTag -Day $case.value) $capture[0] "Raw capture ay oldDayTag para sa $($case.label)"
    Assert-StageEqual $case.expected $patched "Tamang patched helper value para sa $($case.label)"
    Assert-StageEqual (Get-NormDayCount -Day $case.value) $patched "Normative equivalence para sa $($case.label)"
}

$greenCount = 0
foreach ($case in $helperCases) {
    $ctx = Invoke-CalendarDateSpaghetti -CalculationDay $case.value -TargetDay ($foundation + 1)
    $expectedAction = [System.Numerics.BigInteger](Get-NormDayCount -Day $case.value)
    $expectedTarget = [System.Numerics.BigInteger](Get-NormDayCount -Day ($foundation + 1))
    $rawAction = [System.Numerics.BigInteger](oldDayTag -Day $case.value)
    $rawTarget = [System.Numerics.BigInteger](oldDayTag -Day ($foundation + 1))
    $patch01Expected = [System.Numerics.BigInteger](Get-NormSave -X $case.value)

    Assert-StageEqual 'SAVE_PATCH_ACTIVE' $ctx.patch01Status "Nananatiling aktibo ang Patch 01 para sa $($case.label)"
    Assert-StageEqual $patch01Expected $ctx.patch01PatchedValue "Nananatiling GREEN ang Patch 01 para sa $($case.label)"
    Assert-StageEqual 'DAY_TAG_PATCH_ACTIVE' $ctx.patch02Status "Aktibo ang Patch 02 para sa $($case.label)"
    Assert-StageEqual 1 $ctx.patch02InvocationCount "Isang Patch 02 invocation para sa $($case.label)"
    Assert-StageEqual $true $ctx.patch02ActionApplied "Applied ang action patch para sa $($case.label)"
    Assert-StageEqual $true $ctx.patch02TargetApplied "Applied ang target patch para sa $($case.label)"
    Assert-StageEqual $rawAction $ctx.legacyActionDayTag "Napanatili ang raw action scar para sa $($case.label)"
    Assert-StageEqual $rawTarget $ctx.legacyTargetDayTag "Napanatili ang raw target scar para sa $($case.label)"
    Assert-StageEqual $expectedAction $ctx.patch02ActionDayTag "GREEN action day tag para sa $($case.label)"
    Assert-StageEqual $expectedTarget $ctx.patch02TargetDayTag "GREEN target day tag para sa $($case.label)"
    Assert-StageEqual $rawAction ([System.Numerics.BigInteger]$ctx.semanticCommitted['legacyActionDayTag']) "Committed raw action para sa $($case.label)"
    Assert-StageEqual $expectedAction ([System.Numerics.BigInteger]$ctx.semanticCommitted['patch02ActionDayTag']) "Committed patched action para sa $($case.label)"
    Assert-StageTrue -Condition ($ctx.metrics.ContainsKey('patch02.dayTag.calls')) -Name "May Patch 02 metric para sa $($case.label)"
    Assert-StageTrue -Condition (@($ctx.logs | Where-Object { $_.code -eq 'monster.patch02.daytag.adapter' }).Count -eq 1) -Name "Dumaan sa Patch 02 adapter para sa $($case.label)"

    if ($ctx.patch02ActionDayTag -eq $expectedAction -and $ctx.patch02TargetDayTag -eq $expectedTarget) {
        $greenCount++
        Write-Host "PATCH02_CASE=$($case.label) RAW=$rawAction PATCHED=$expectedAction CLASSIFICATION=GREEN"
    }
    else {
        Assert-StageTrue -Condition $false -Name "Hindi GREEN ang Patch 02 para sa $($case.label)"
    }
}

Assert-StageEqual 5 $greenCount 'Lahat ng limang Patch 02 Foundation probes ay GREEN'

# Foundation guard physical scar must be observable.
$foundationCtx = Invoke-CalendarDateSpaghetti -CalculationDay $foundation -TargetDay ($foundation - 1)
Assert-StageEqual $true $foundationCtx.patch02FoundationGuardSeen 'Nakita ang Foundation guard kapag Foundation ang action day'
Assert-StageEqual 0 $foundationCtx.legacyActionDayTag 'Raw Foundation action ay nananatiling 0'
Assert-StageEqual 1 $foundationCtx.patch02ActionDayTag 'Patched Foundation action ay 1'
Assert-StageEqual $true ([bool]$foundationCtx.semanticCommitted['patch02FoundationGuardSeen']) 'Committed ang Foundation guard observability'

# Separate invocation ownership.
$ctxA = Invoke-CalendarDateSpaghetti -CalculationDay $foundation -TargetDay ($foundation - 1)
$ctxB = Invoke-CalendarDateSpaghetti -CalculationDay ($foundation + 2) -TargetDay ($foundation + 1)
Assert-StageTrue -Condition (-not [object]::ReferenceEquals($ctxA, $ctxB)) -Name 'Magkahiwalay ang Patch 02 invocation contexts'
Assert-StageEqual 1 $ctxA.patch02ActionDayTag 'Hindi nabago ang unang patched action state'
Assert-StageEqual 5 $ctxB.patch02ActionDayTag 'Sarili ang patched action state ng ikalawang invocation'

$monsterText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/MonsterSkeleton.ps1')
$discovery1Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Discovery01.ps1')
$patch1Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Patch01.ps1')
$discovery2Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Discovery02.ps1')
$patch2Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Patch02.ps1')
$productionText = $monsterText + "`n" + $discovery1Text + "`n" + $patch1Text + "`n" + $discovery2Text + "`n" + $patch2Text

Assert-StageTrue -Condition ($productionText -notmatch 'Invoke-NormSauce|Get-NormCalendarDate|Get-NormSave|Get-NormDayCount') -Name 'Hindi tumatawag sa normative oracle ang Stage 5 production path'
Assert-StageTrue -Condition ($discovery2Text -match 'function oldDayTag') -Name 'Nananatiling hiwalay ang raw historical oldDayTag'
Assert-StageTrue -Condition ($patch2Text -match 'function dayTagWithFoundationScar') -Name 'May hiwalay na dayTagWithFoundationScar helper'
Assert-StageTrue -Condition ($patch2Text -match '\$Day -eq \$script:Discovery02FoundationDay -and \$n -ne') -Name 'Pisikal na nananatili ang redundant Foundation guard scar'
Assert-StageTrue -Condition ($productionText -notmatch 'oldDistance') -Name 'Walang Stage 6 oldDistance discovery'
$futureNames = @('mutateStonesWrong','orderAt46Latch','biasedLegacyPick','LEGACY_YEAR_MAX','VirtualLegacyList','oldContiguousMonthDayGuess')
foreach ($name in $futureNames) {
    Assert-StageTrue -Condition ($productionText -notmatch [regex]::Escape($name)) -Name "Walang future patch code: $name"
}

Write-Host "PATCH02_GREEN_COUNT=$greenCount"
Write-Host 'PATCH02_FOUNDATION_GUARD_SCAR=PRESENT'
Write-Host 'STAGE05_REPOSITORY_STATE=GREEN'

$ok = Complete-StageTestRun
if (-not $ok) { exit 1 }
Write-Host 'STAGE05_RESULT=PASS'
exit 0
