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
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_STAGE=2\s*$') -Name 'Stage 2 ang kasalukuyang stage'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_KIND=DISCOVERY\s*$') -Name 'Discovery ang kasalukuyang uri'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_PATCH=01\s*$') -Name 'Discovery 01 ang kasalukuyang patch slot'
Assert-StageTrue -Condition ($metadata -match '(?m)^LAST_COMPLETED_STAGE=1\s*$') -Name 'Hindi pa minamarkahang kumpleto ang Stage 2 bago runtime'
Assert-StageTrue -Condition ($metadata -match '(?m)^EXPECTED_REPOSITORY_STATE=RED\s*$') -Name 'RED ang inaasahang repository state'

Assert-StageEqual $zero (oldRemainder -X $m) 'oldRemainder(M) ay zero'
Assert-StageEqual $zero (oldRemainder -X (2 * $m)) 'oldRemainder(2M) ay zero'
Assert-StageEqual $zero (oldRemainder -X (3 * $m)) 'oldRemainder(3M) ay zero'
Assert-StageEqual $one (oldRemainder -X ($m + 1)) 'oldRemainder(M+1) ay isa'
Assert-StageEqual ($m - 1) (oldRemainder -X -1) 'regularMod semantics para sa negatibong input'

$expectedRedCount = 0
$matchCount = 0
$cases = @(
    [pscustomobject]@{ label = 'M'; value = $m; expectedClass = 'EXPECTED_RED' },
    [pscustomobject]@{ label = '2M'; value = 2 * $m; expectedClass = 'EXPECTED_RED' },
    [pscustomobject]@{ label = '3M'; value = 3 * $m; expectedClass = 'EXPECTED_RED' },
    [pscustomobject]@{ label = 'M+1'; value = $m + 1; expectedClass = 'MATCH' }
)

foreach ($case in $cases) {
    $ctx = Invoke-CalendarDateSpaghetti -CalculationDay $case.value -TargetDay $zero
    $actual = [System.Numerics.BigInteger]$ctx.legacyRemainderValue
    $expected = [System.Numerics.BigInteger](Get-NormSave -X $case.value)

    Assert-StageEqual 'LEGACY_REMAINDER_ACTIVE' $ctx.discovery01Status "Aktibo ang Discovery 01 adapter para sa $($case.label)"
    Assert-StageEqual 1 $ctx.discovery01InvocationCount "Isang adapter invocation para sa $($case.label)"
    Assert-StageEqual $actual ([System.Numerics.BigInteger]$ctx.semanticCommitted['legacyRemainderValue']) "Committed ang legacy value para sa $($case.label)"
    Assert-StageEqual $case.value ([System.Numerics.BigInteger]$ctx.semanticCommitted['legacyRemainderInput']) "Committed ang legacy input para sa $($case.label)"
    Assert-StageTrue -Condition ($ctx.metrics.ContainsKey('discovery01.legacyRemainder.calls')) -Name "May per-invocation metric para sa $($case.label)"
    Assert-StageTrue -Condition (@($ctx.logs | Where-Object { $_.code -eq 'monster.discovery01.legacy.adapter' }).Count -eq 1) -Name "Dumaan sa legacy adapter route para sa $($case.label)"

    if ($actual -ne $expected) {
        $expectedRedCount++
        Write-Host "DISCOVERY01_CASE=$($case.label) ACTUAL=$actual EXPECTED=$expected CLASSIFICATION=EXPECTED_RED ERROR_ID=Pastafari:Discovery01:LegacyRemainderDivergence"
        Assert-StageEqual 'EXPECTED_RED' $case.expectedClass "Tamang classification para sa $($case.label)"
    }
    else {
        $matchCount++
        Write-Host "DISCOVERY01_CASE=$($case.label) ACTUAL=$actual EXPECTED=$expected CLASSIFICATION=MATCH"
        Assert-StageEqual 'MATCH' $case.expectedClass "Tamang classification para sa $($case.label)"
    }
}

Assert-StageEqual 3 $expectedRedCount 'Eksaktong tatlong expected-red divergences'
Assert-StageEqual 1 $matchCount 'Eksaktong isang matching regression case'

$ctxA = Invoke-CalendarDateSpaghetti -CalculationDay $m -TargetDay $zero
$ctxB = Invoke-CalendarDateSpaghetti -CalculationDay ($m + 1) -TargetDay $zero
Assert-StageTrue -Condition (-not [object]::ReferenceEquals($ctxA, $ctxB)) -Name 'Magkahiwalay ang Discovery 01 invocation contexts'
Assert-StageEqual $zero $ctxA.legacyRemainderValue 'Hindi nabago ang unang invocation state'
Assert-StageEqual $one $ctxB.legacyRemainderValue 'Sarili ang state ng ikalawang invocation'
Assert-StageEqual $zero ([System.Numerics.BigInteger]$ctxA.semanticCommitted['legacyRemainderValue']) 'Hiwalay ang committed semantic state A'
Assert-StageEqual $one ([System.Numerics.BigInteger]$ctxB.semanticCommitted['legacyRemainderValue']) 'Hiwalay ang committed semantic state B'

$monsterText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/MonsterSkeleton.ps1')
$discoveryText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Discovery01.ps1')
$productionText = $monsterText + "`n" + $discoveryText

Assert-StageTrue -Condition ($productionText -notmatch 'Invoke-NormSauce|Get-NormCalendarDate|Get-NormSave') -Name 'Hindi tumatawag sa normative oracle ang Stage 2 production path'
Assert-StageTrue -Condition ($productionText -notmatch 'savePatch') -Name 'Walang Stage 3 savePatch sa Discovery 01'
$futureNames = @('oldDayTag','oldDistance','mutateStonesWrong','orderAt46Latch','biasedLegacyPick','LEGACY_YEAR_MAX','VirtualLegacyList','oldContiguousMonthDayGuess')
foreach ($name in $futureNames) {
    Assert-StageTrue -Condition ($productionText -notmatch [regex]::Escape($name)) -Name "Walang future patch code: $name"
}

Write-Host "DISCOVERY01_EXPECTED_RED_COUNT=$expectedRedCount"
Write-Host "DISCOVERY01_MATCH_COUNT=$matchCount"
Write-Host 'STAGE02_REPOSITORY_STATE=EXPECTED_RED'

$ok = Complete-StageTestRun
if (-not $ok) { exit 1 }
Write-Host 'STAGE02_RESULT=PASS'
exit 0
