Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

$md = @(Get-Content -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md'))
$sealed42 = ($md -ccontains 'TOTAL_STAGES=55') -and
            ($md -ccontains 'CURRENT_STAGE=42') -and
            ($md -ccontains 'CURRENT_DISCOVERY=27') -and
            ($md -ccontains 'LAST_COMPLETED_STAGE=42') -and
            ($md -ccontains 'STAGE42_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED') -and
            ($md -ccontains 'STAGE42_NATIVE_CI_RUN=44716461173') -and
            ($md -ccontains 'STAGE42_NATIVE_ASSERTIONS_PASSED=1657') -and
            ($md -ccontains 'STAGE42_NATIVE_ASSERTIONS_FAILED=0') -and
            ($md -ccontains 'STAGE41_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED')
if (-not $sealed42) { throw 'Stage43 research requires the sealed Stage42 predecessor; Stage43 must not be activated' }

function Require43 {
    param([bool]$Condition, [string]$Label)
    Assert-StageTrue -Condition $Condition -Name $Label
    if (-not $Condition) { throw "Stage43 assertion failed: $Label" }
}
function Equal43 {
    param($Expected, $Actual, [string]$Label)
    Assert-StageEqual -Expected $Expected -Actual $Actual -Name $Label
    if ($Expected -ne $Actual) { throw "Stage43 assertion failed: $Label" }
}
$script:Guards43 = 0
function Guard43 {
    param([bool]$Condition, [string]$Label)
    $script:Guards43++
    Require43 -Condition $Condition -Label $Label
}
function GuardEqual43 {
    param($Expected, $Actual, [string]$Label)
    $script:Guards43++
    Equal43 -Expected $Expected -Actual $Actual -Label $Label
}
function Mod43 {
    param([System.Numerics.BigInteger]$Value, [System.Numerics.BigInteger]$Modulus)
    return [System.Numerics.BigInteger]((($Value % $Modulus) + $Modulus) % $Modulus)
}
function Key43 {
    param([int]$CalculationIndex, [int]$TargetIndex, [int]$Seal)
    return ('{0}|{1}|{2}' -f $CalculationIndex, $TargetIndex, $Seal)
}
function Pair43 {
    param($Left, $Right, [System.Numerics.BigInteger]$Modulus, [string]$Label)
    $oracleDelta = Mod43 -Value (([System.Numerics.BigInteger]$Right.W.First) - ([System.Numerics.BigInteger]$Left.W.First)) -Modulus $Modulus
    $sourceDelta = Mod43 -Value (([System.Numerics.BigInteger]$Right.A.First) - ([System.Numerics.BigInteger]$Left.A.First)) -Modulus $Modulus
    Equal43 -Expected $oracleDelta -Actual $sourceDelta -Label "First delta $Label"
    Equal43 -Expected ([bool]($Left.W.Step -ne $Right.W.Step)) -Actual ([bool]($Left.A.Step -ne $Right.A.Step)) -Label "Step change $Label"
}

$f = [System.Numerics.BigInteger](Get-NormFoundationDay)
$seedYear = Get-NormYear5000 -CalculationDay $f
$c = [System.Numerics.BigInteger]$seedYear.CloseGateDay
$m = [System.Numerics.BigInteger](Get-NormM)
if ($m -le 0) { throw 'Normative oracle modulus must be positive' }
$calculationDays = @($f, $c)
Guard43 -Condition ($f -ne $c) -Label 'Distinct calculation contexts'
$endpoints = 0
$targetPairs = 0
$sealPairs = 0
$grid = @{}
$seals = @(1..10)

for ($i=0; $i -lt 2; $i++) {
    $d = [System.Numerics.BigInteger]$calculationDays[$i]
    $y0 = Get-NormYear5000 -CalculationDay $d
    $previous = Get-NormPreviousYear -CalculationDay $d -KnownYear $y0
    $next = Get-NormNextYear -CalculationDay $d -KnownYear $y0
    $gates = @(
        [System.Numerics.BigInteger]$previous.OpenGateDay,
        [System.Numerics.BigInteger]$previous.CloseGateDay,
        [System.Numerics.BigInteger]$y0.CloseGateDay,
        [System.Numerics.BigInteger]$next.CloseGateDay
    )
    $targets = @()
    foreach ($gate in $gates) {
        foreach ($offset in @(-1,0,1)) {
            $targets += [System.Numerics.BigInteger]($gate + $offset)
        }
    }

    GuardEqual43 -Expected ([System.Numerics.BigInteger]5000) -Actual $y0.Number -Label "Year5000 $i"
    GuardEqual43 -Expected ([System.Numerics.BigInteger]4999) -Actual $previous.Number -Label "Previous year $i"
    GuardEqual43 -Expected ([System.Numerics.BigInteger]5001) -Actual $next.Number -Label "Next year $i"
    GuardEqual43 -Expected $previous.CloseGateDay -Actual $y0.OpenGateDay -Label "Previous close/current open $i"
    GuardEqual43 -Expected $y0.CloseGateDay -Actual $next.OpenGateDay -Label "Current close/next open $i"
    Guard43 -Condition ($previous.OpenGateDay -lt $previous.CloseGateDay) -Label "Previous positive year $i"
    Guard43 -Condition ($y0.OpenGateDay -lt $y0.CloseGateDay) -Label "Current positive year $i"
    Guard43 -Condition ($next.OpenGateDay -lt $next.CloseGateDay) -Label "Next positive year $i"
    Guard43 -Condition ($gates.Count -eq 4 -and $gates[0] -lt $gates[1] -and $gates[1] -lt $gates[2] -and $gates[2] -lt $gates[3]) -Label "Four strictly ordered gates $i"
    $uniqueTargets = @($targets | ForEach-Object { $_.ToString() } | Select-Object -Unique)
    Guard43 -Condition ($targets.Count -eq 12 -and $uniqueTargets.Count -eq 12) -Label "Twelve distinct targets $i"
    Guard43 -Condition ($y0.OpenGateDay -lt $d -and $d -le $y0.CloseGateDay) -Label "Calculation in Year5000 $i"

    for ($t=0; $t -lt 12; $t++) {
        for ($s=1; $s -le 10; $s++) {
            $targetDay = [System.Numerics.BigInteger]$targets[$t]
            $source = Invoke-CalendarDateSpaghetti -CalculationDay $d -TargetDay $targetDay
            $actual = Get-Discovery13AnswerStreamFromContext -Context $source -QueriedBowlId 1 -Seal $s
            $normativeSauce = Invoke-NormSauce $d $targetDay
            $want = Get-NormAnswerStream -SauceResult $normativeSauce -QueriedBowlId 1 -Seal $s
            $key = Key43 -CalculationIndex $i -TargetIndex $t -Seal $s
            Equal43 -Expected $want.First -Actual $actual.First -Label "Endpoint First $key"
            Equal43 -Expected $want.Step -Actual $actual.Step -Label "Endpoint Step $key"
            Require43 -Condition ($actual.First -ge 1 -and $actual.First -le $m) -Label "First domain $key"
            Require43 -Condition ($actual.Step -eq 1 -or $actual.Step -eq -1) -Label "Step domain $key"
            Equal43 -Expected 58 -Actual $source.legacyOrderMemoryWriteCount -Label "Legacy writes $key"
            Equal43 -Expected 1 -Actual $source.patch12InvocationCount -Label "Patch12 invocations $key"
            $grid[$key] = [pscustomobject]@{ A=$actual; W=$want }
            $endpoints++
        }
    }

    for ($gateIndex=0; $gateIndex -lt 4; $gateIndex++) {
        for ($edge=0; $edge -lt 2; $edge++) {
            $leftIndex = $gateIndex * 3 + $edge
            for ($s=1; $s -le 10; $s++) {
                $left = $grid[(Key43 $i $leftIndex $s)]
                $right = $grid[(Key43 $i ($leftIndex+1) $s)]
                Pair43 -Left $left -Right $right -Modulus $m -Label "Target gate $i|$gateIndex|$edge|$s"
                $targetPairs++
            }
        }
    }
    for ($t=0; $t -lt 12; $t++) {
        for ($s=1; $s -lt 10; $s++) {
            $left = $grid[(Key43 $i $t $s)]
            $right = $grid[(Key43 $i $t ($s+1))]
            Pair43 -Left $left -Right $right -Modulus $m -Label "Seal response $i|$t|$s"
            $sealPairs++
        }
    }
}

Write-Host "STAGE43_ENDPOINTS=$endpoints"
Write-Host "STAGE43_TARGET_PAIRS=$targetPairs"
Write-Host "STAGE43_SEAL_PAIRS=$sealPairs"
Write-Host "STAGE43_STRUCTURAL_GUARDS=$script:Guards43"
Write-Host "STAGE43_ASSERTIONS_PASSED=$script:StageTestPassed"
Write-Host "STAGE43_ASSERTIONS_FAILED=$script:StageTestFailed"
if ($endpoints -ne 240 -or $targetPairs -ne 160 -or $sealPairs -ne 216 -or $script:Guards43 -ne 23 -or $script:StageTestPassed -ne 2215 -or $script:StageTestFailed -ne 0) {
    Write-Host 'STAGE43_PREFLIGHT=FAIL_COUNTS'
    exit 1
}
Write-Host 'STAGE43_PREFLIGHT=BOUNDED_ORACLE_PASS'
Write-Host 'STAGE43_ACTIVATION=NOT_ACTIVATED'
Write-Host 'STAGE43_STAGE_SEAL=NOT_CLAIMED'
exit 0
