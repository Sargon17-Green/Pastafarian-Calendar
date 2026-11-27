Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')
. (Join-Path $root 'src/StageMetadataState.ps1')
$state44 = Assert-Stage43MetadataCompatibility -RepositoryRoot $root
if ($state44.Profile -cne 'SEALED_SHAPE_ONLY') { throw 'Stage44 preflight requires sealed Stage43 shape' }

function Check44 {
    param([bool]$Ok, [string]$Label)
    Assert-StageTrue -Condition $Ok -Name $Label
    if (-not $Ok) { throw "Stage44 assertion failed: $Label" }
}
function Guard44 {
    param([bool]$Ok, [string]$Label)
    $script:GuardCount44++
    Check44 $Ok $Label
}
function Mod44 {
    param([System.Numerics.BigInteger]$X, [System.Numerics.BigInteger]$M44)
    return [System.Numerics.BigInteger]((($X % $M44) + $M44) % $M44)
}
function Mixed44 {
    param($A00,$A01,$A10,$A11,[System.Numerics.BigInteger]$M44)
    return (Mod44 (([System.Numerics.BigInteger]$A11.First) - ([System.Numerics.BigInteger]$A10.First) - ([System.Numerics.BigInteger]$A01.First) + ([System.Numerics.BigInteger]$A00.First)) $M44)
}
function Parity44 {
    param($A00,$A01,$A10,$A11)
    $negative = 0
    foreach ($entry in @($A00,$A01,$A10,$A11)) { if ($entry.Step -eq -1) { $negative++ } }
    return ($negative % 2)
}
function Key44 {
    param([int]$DIndex,[int]$TIndex,[int]$Seal44)
    return ('{0}|{1}|{2}' -f $DIndex,$TIndex,$Seal44)
}

$script:GuardCount44 = 0
$modulus44 = [System.Numerics.BigInteger](Get-NormM)
if ($modulus44 -le 0) { throw 'Nonpositive normative modulus' }
$foundation44 = [System.Numerics.BigInteger](Get-NormFoundationDay)
$seed44 = Get-NormYear5000 -CalculationDay $foundation44
$open44 = [System.Numerics.BigInteger]$seed44.OpenGateDay
$close44 = [System.Numerics.BigInteger]$seed44.CloseGateDay
$days44 = @(
    ($open44 - 1), $open44, ($open44 + 1),
    ($close44 - 1), $close44, ($close44 + 1)
)
Guard44 (@($days44 | ForEach-Object { $_.ToString() } | Select-Object -Unique).Count -eq 6) 'Six distinct calculation days'
$grid44 = @{}
$sourceCount44 = 0
$oracleCount44 = 0
$endpointCount44 = 0
$rectangleCount44 = 0
for ($i44=0; $i44 -lt 6; $i44++) {
    $day44 = [System.Numerics.BigInteger]$days44[$i44]
    $year44 = Get-NormYear5000 -CalculationDay $day44
    $prior44 = Get-NormPreviousYear -CalculationDay $day44 -KnownYear $year44
    $next44 = Get-NormNextYear -CalculationDay $day44 -KnownYear $year44
    Guard44 ($prior44.Number -eq 4999) "Prior number $i44"
    Guard44 ($year44.Number -eq 5000) "Current number $i44"
    Guard44 ($next44.Number -eq 5001) "Next number $i44"
    Guard44 ($prior44.CloseGateDay -eq $year44.OpenGateDay) "Prior seam $i44"
    Guard44 ($year44.CloseGateDay -eq $next44.OpenGateDay) "Next seam $i44"
    Guard44 ($prior44.CloseGateDay -gt $prior44.OpenGateDay) "Prior span $i44"
    Guard44 ($year44.CloseGateDay -gt $year44.OpenGateDay) "Current span $i44"
    Guard44 ($next44.CloseGateDay -gt $next44.OpenGateDay) "Next span $i44"
    $gates44 = @(
        [System.Numerics.BigInteger]$prior44.OpenGateDay,
        [System.Numerics.BigInteger]$prior44.CloseGateDay,
        [System.Numerics.BigInteger]$year44.CloseGateDay,
        [System.Numerics.BigInteger]$next44.CloseGateDay
    )
    Guard44 ($gates44.Count -eq 4 -and $gates44[0] -lt $gates44[1] -and $gates44[1] -lt $gates44[2] -and $gates44[2] -lt $gates44[3]) "Ordered gates $i44"
    $targets44 = @()
    foreach ($gate44 in $gates44) {
        foreach ($off44 in @(-1,0,1)) { $targets44 += [System.Numerics.BigInteger]($gate44 + $off44) }
    }
    Guard44 ($targets44.Count -eq 12 -and @($targets44 | ForEach-Object { $_.ToString() } | Select-Object -Unique).Count -eq 12) "Distinct targets $i44"
    Guard44 ($year44.OpenGateDay -lt $day44 -and $day44 -le $year44.CloseGateDay) "Recomputed year membership $i44"
    Write-Host ('STAGE44_CONTEXT={0};DAY={1};GATES={2}' -f $i44,$day44,($gates44 -join ','))
    for ($t44=0; $t44 -lt 12; $t44++) {
        $target44 = [System.Numerics.BigInteger]$targets44[$t44]
        $actualContext44 = Invoke-CalendarDateSpaghetti -CalculationDay $day44 -TargetDay $target44
        $sourceCount44++
        $oracleContext44 = Invoke-NormSauce $day44 $target44
        $oracleCount44++
        for ($seal44=1; $seal44 -le 10; $seal44++) {
            $a44 = Get-Discovery13AnswerStreamFromContext -Context $actualContext44 -QueriedBowlId 1 -Seal $seal44
            $w44 = Get-NormAnswerStream -SauceResult $oracleContext44 -QueriedBowlId 1 -Seal $seal44
            $key44 = Key44 $i44 $t44 $seal44
            Check44 ($a44.First -eq $w44.First) "First $key44"
            Check44 ($a44.Step -eq $w44.Step) "Step $key44"
            Check44 ($a44.First -ge 1 -and $a44.First -le $modulus44) "First domain $key44"
            Check44 ($a44.Step -eq -1 -or $a44.Step -eq 1) "Step domain $key44"
            Check44 ($actualContext44.legacyOrderMemoryWriteCount -eq 58) "Legacy writes $key44"
            Check44 ($actualContext44.patch12InvocationCount -eq 1) "Patch12 count $key44"
            $grid44[$key44] = [pscustomobject]@{ A=$a44; W=$w44 }
            $endpointCount44++
        }
    }
}
foreach ($left44 in @(0,1,3,4)) {
    $right44 = $left44 + 1
    for ($g44=0; $g44 -lt 4; $g44++) {
        for ($edge44=0; $edge44 -lt 2; $edge44++) {
            $lo44 = 3*$g44 + $edge44
            $hi44 = $lo44 + 1
            for ($seal44=1; $seal44 -le 10; $seal44++) {
                $p00 = $grid44[(Key44 $left44 $lo44 $seal44)]
                $p01 = $grid44[(Key44 $left44 $hi44 $seal44)]
                $p10 = $grid44[(Key44 $right44 $lo44 $seal44)]
                $p11 = $grid44[(Key44 $right44 $hi44 $seal44)]
                $label44 = '{0}|{1}|{2}|{3}' -f $left44,$g44,$edge44,$seal44
                $actualMixed44 = Mixed44 $p00.A $p01.A $p10.A $p11.A $modulus44
                $oracleMixed44 = Mixed44 $p00.W $p01.W $p10.W $p11.W $modulus44
                Check44 ($actualMixed44 -eq $oracleMixed44) "Mixed First $label44"
                Check44 ((Parity44 $p00.A $p01.A $p10.A $p11.A) -eq (Parity44 $p00.W $p01.W $p10.W $p11.W)) "Mixed Step parity $label44"
                $rectangleCount44++
            }
        }
    }
}
Write-Host "STAGE44_SOURCE_CONTEXTS=$sourceCount44"
Write-Host "STAGE44_ORACLE_CONTEXTS=$oracleCount44"
Write-Host "STAGE44_ENDPOINTS=$endpointCount44"
Write-Host "STAGE44_RECTANGLES=$rectangleCount44"
Write-Host "STAGE44_STRUCTURAL_GUARDS=$script:GuardCount44"
Write-Host "STAGE44_ASSERTIONS_PASSED=$script:StageTestPassed"
Write-Host "STAGE44_ASSERTIONS_FAILED=$script:StageTestFailed"
if ($sourceCount44 -ne 72 -or $oracleCount44 -ne 72 -or $endpointCount44 -ne 720 -or $grid44.Count -ne 720 -or $rectangleCount44 -ne 320 -or $script:GuardCount44 -ne 67 -or $script:StageTestPassed -ne 5027 -or $script:StageTestFailed -ne 0) {
    throw 'Stage44 count gate mismatch'
}
Write-Host 'STAGE44_PREFLIGHT=BOUNDED_ORACLE_PASS'
Write-Host 'STAGE44_ACTIVATION=NOT_ACTIVATED'
exit 0
