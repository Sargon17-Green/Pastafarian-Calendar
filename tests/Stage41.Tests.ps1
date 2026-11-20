Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')
$md = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')
$metadataLines = @($md -split '\r?\n')
$stage41Pending = ($metadataLines -ccontains 'CURRENT_STAGE=41') -and ($metadataLines -ccontains 'LAST_COMPLETED_STAGE=40') -and ($metadataLines -ccontains 'STAGE41_RUNTIME_VERIFICATION=PENDING_NATIVE') -and ($metadataLines -ccontains 'STAGE41_PREFLIGHT_CI_RUN=44373929661') -and ($metadataLines -ccontains 'STAGE41_PREFLIGHT_JOBS=15_OF_15_SUCCESS') -and ($metadataLines -ccontains 'STAGE41_PREFLIGHT_ASSERTIONS_PASSED=481') -and ($metadataLines -ccontains 'STAGE41_PREFLIGHT_ASSERTIONS_FAILED=0')
$stage41Sealed = (($metadataLines -ccontains 'CURRENT_STAGE=41') -or ($metadataLines -ccontains 'CURRENT_STAGE=42')) -and ($metadataLines -ccontains 'LAST_COMPLETED_STAGE=41') -and ($metadataLines -ccontains 'STAGE41_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED') -and ($metadataLines -ccontains 'STAGE41_PREFLIGHT_CI_RUN=44373929661') -and ($metadataLines -ccontains 'STAGE41_PREFLIGHT_JOBS=15_OF_15_SUCCESS') -and ($metadataLines -ccontains 'STAGE41_PREFLIGHT_ASSERTIONS_PASSED=481') -and ($metadataLines -ccontains 'STAGE41_PREFLIGHT_ASSERTIONS_FAILED=0')
if(-not ($stage41Pending -or $stage41Sealed)) { throw 'Stage41 requires exact PENDING_NATIVE or evidence-sealed metadata backed by completed preflight' }
$required = @('STAGE40_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED','STAGE39_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED','STAGE38_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED','STAGE37_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED','STAGE36_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED','STAGE35_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED')
foreach($line in $required) { if(-not ($metadataLines -ccontains $line)) { throw "Stage41 predecessor seal missing $line" } }

function Mod41 { param([System.Numerics.BigInteger]$Value,[System.Numerics.BigInteger]$Modulus)
    return [System.Numerics.BigInteger]((($Value % $Modulus) + $Modulus) % $Modulus)
}
function Key41 { param([int]$C,[int]$T,[int]$S)
    return ('{0}|{1}|{2}' -f $C,$T,$S)
}
function Delta41 { param($P,$Q,[System.Numerics.BigInteger]$Modulus)
    return (Mod41 -Value (([System.Numerics.BigInteger]$Q.First)-([System.Numerics.BigInteger]$P.First)) -Modulus $Modulus)
}
function Pair41 { param($P,$Q,[System.Numerics.BigInteger]$Modulus,[string]$Label)
    Assert-StageEqual -Expected (Delta41 $P.W $Q.W $Modulus) -Actual (Delta41 $P.A $Q.A $Modulus) -Name "First $Label"
    Assert-StageEqual -Expected ([bool]($P.W.Step -ne $Q.W.Step)) -Actual ([bool]($P.A.Step -ne $Q.A.Step)) -Name "Step $Label"
}
$f = [System.Numerics.BigInteger](Get-NormFoundationDay)
$yr = Get-NormYear5000 -CalculationDay $f
$o = [System.Numerics.BigInteger]$yr.OpenGateDay
$c = [System.Numerics.BigInteger]$yr.CloseGateDay
$m = [System.Numerics.BigInteger]$script:Discovery01M
Assert-StageEqual -Expected ([System.Numerics.BigInteger]5000) -Actual $yr.Number -Name 'Normative year'
Assert-StageTrue -Condition ($o -lt $f -and $f -le $c) -Name 'Foundation in normative year'
Assert-StageTrue -Condition ($m -gt 0) -Name 'Positive modulus'
Assert-StageTrue -Condition ($o -lt $c) -Name 'Ordered gates'
$calc = @([System.Numerics.BigInteger]($o-1),$o,$c,[System.Numerics.BigInteger]($c+1))
$target = @($calc[0],$calc[1],$calc[2],$calc[3])
$seals = @(1,5,10)
Assert-StageEqual -Expected 4 -Actual $calc.Count -Name 'Calculation days'
Assert-StageEqual -Expected 4 -Actual $target.Count -Name 'Target days'
Assert-StageEqual -Expected 3 -Actual $seals.Count -Name 'Legal seals'
$uniqueCalc = @($calc | ForEach-Object { $_.ToString() } | Select-Object -Unique)
$uniqueTarget = @($target | ForEach-Object { $_.ToString() } | Select-Object -Unique)
Assert-StageEqual -Expected 4 -Actual $uniqueCalc.Count -Name 'Unique calculation days'
Assert-StageEqual -Expected 4 -Actual $uniqueTarget.Count -Name 'Unique target days'
$grid = @{}; $endpoints = 0
for($i=0;$i -lt 4;$i++) {
 for($j=0;$j -lt 4;$j++) {
  for($k=0;$k -lt 3;$k++) {
   $prod = Invoke-CalendarDateSpaghetti -CalculationDay $calc[$i] -TargetDay $target[$j]
   $actual = Get-Discovery13AnswerStreamFromContext -Context $prod -QueriedBowlId 1 -Seal $seals[$k]
   $normSauce = Invoke-NormSauce $calc[$i] $target[$j]
   $want = Get-NormAnswerStream -SauceResult $normSauce -QueriedBowlId 1 -Seal $seals[$k]
   $key = Key41 $i $j $k
   Assert-StageEqual -Expected $want.First -Actual $actual.First -Name "Endpoint First $key"
   Assert-StageEqual -Expected $want.Step -Actual $actual.Step -Name "Endpoint Step $key"
   Assert-StageTrue -Condition ($actual.First -ge 1 -and $actual.First -le $m) -Name "First domain $key"
   Assert-StageTrue -Condition ($actual.Step -eq -1 -or $actual.Step -eq 1) -Name "Step domain $key"
   Assert-StageEqual -Expected 58 -Actual $prod.legacyOrderMemoryWriteCount -Name "Legacy writes $key"
   Assert-StageEqual -Expected 1 -Actual $prod.patch12InvocationCount -Name "Patch12 count $key"
   $grid[$key] = [pscustomobject]@{ A=$actual; W=$want }
   $endpoints++
  }
 }
}
$edges = @(@(0,1),@(2,3))
$calculationSeams = 0
foreach($e in $edges) { for($j=0;$j -lt 4;$j++) { for($k=0;$k -lt 3;$k++) {
 Pair41 $grid[(Key41 $e[0] $j $k)] $grid[(Key41 $e[1] $j $k)] $m "Calculation seam $($e[0])-$($e[1])|$j|$k"
 $calculationSeams++
}}}
$targetSeams = 0
foreach($e in $edges) { for($i=0;$i -lt 4;$i++) { for($k=0;$k -lt 3;$k++) {
 Pair41 $grid[(Key41 $i $e[0] $k)] $grid[(Key41 $i $e[1] $k)] $m "Target seam $i|$($e[0])-$($e[1])|$k"
 $targetSeams++
}}}
$faces = 0
foreach($ce in $edges) { foreach($te in $edges) { for($k=0;$k -lt 3;$k++) {
 $p00=$grid[(Key41 $ce[0] $te[0] $k)]
 $p01=$grid[(Key41 $ce[0] $te[1] $k)]
 $p10=$grid[(Key41 $ce[1] $te[0] $k)]
 $p11=$grid[(Key41 $ce[1] $te[1] $k)]
 $expected = Mod41 (([System.Numerics.BigInteger]$p11.W.First)-([System.Numerics.BigInteger]$p10.W.First)-([System.Numerics.BigInteger]$p01.W.First)+([System.Numerics.BigInteger]$p00.W.First)) $m
 $observed = Mod41 (([System.Numerics.BigInteger]$p11.A.First)-([System.Numerics.BigInteger]$p10.A.First)-([System.Numerics.BigInteger]$p01.A.First)+([System.Numerics.BigInteger]$p00.A.First)) $m
 Assert-StageEqual -Expected $expected -Actual $observed -Name "Mixed face First $($ce[0])|$($te[0])|$k"
 $ep=([int]$p00.W.Step)*([int]$p01.W.Step)*([int]$p10.W.Step)*([int]$p11.W.Step)
 $ap=([int]$p00.A.Step)*([int]$p01.A.Step)*([int]$p10.A.Step)*([int]$p11.A.Step)
 Assert-StageEqual -Expected ([bool]($ep -lt 0)) -Actual ([bool]($ap -lt 0)) -Name "Mixed face Step $($ce[0])|$($te[0])|$k"
 $faces++
}}}
$sealPairs = 0
for($i=0;$i -lt 4;$i++) { for($j=0;$j -lt 4;$j++) { for($k=0;$k -lt 2;$k++) {
 Pair41 $grid[(Key41 $i $j $k)] $grid[(Key41 $i $j ($k+1))] $m "Seal response $i|$j|$k"
 $sealPairs++
}}}
Write-Host "STAGE41_ENDPOINTS=$endpoints"
Write-Host "STAGE41_CALC_SEAMS=$calculationSeams"
Write-Host "STAGE41_TARGET_SEAMS=$targetSeams"
Write-Host "STAGE41_MIXED_FACES=$faces"
Write-Host "STAGE41_SEAL_PAIRS=$sealPairs"
Write-Host "STAGE41_ASSERTIONS_PASSED=$script:StageTestPassed"
Write-Host "STAGE41_ASSERTIONS_FAILED=$script:StageTestFailed"
if($endpoints -ne 48 -or $calculationSeams -ne 24 -or $targetSeams -ne 24 -or $faces -ne 12 -or $sealPairs -ne 32 -or $script:StageTestPassed -ne 481 -or $script:StageTestFailed -ne 0) { Write-Host 'STAGE41_NATIVE=FAIL'; exit 1 }
if($stage41Sealed) { Write-Host 'STAGE41_NATIVE=SEALED_RECHECK_PASS' } else { Write-Host 'STAGE41_NATIVE=PASS_PENDING_NO_SEAL' }
exit 0
