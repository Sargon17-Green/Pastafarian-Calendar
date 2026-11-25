Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')
. (Join-Path $root 'src/StageMetadataState.ps1')
$stage43State = Assert-Stage43MetadataCompatibility -RepositoryRoot $root
$stage43Allowed = @('PENDING_SHAPE_ONLY','IMPLEMENTING_SHA_SHAPE_ONLY','SEALED_SHAPE_ONLY') -ccontains $stage43State.Profile

$md = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')
$metadataLines = @($md -split '\r?\n')
$predecessorsSealed = ($metadataLines -ccontains 'STAGE41_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED') -and
                    ($metadataLines -ccontains 'STAGE41_SEAL_COMMIT_NATIVE_RECHECK=PASS') -and
                    ($metadataLines -ccontains 'STAGE41_SEAL_CI_RUN=44633607543') -and
                    ($metadataLines -ccontains 'STAGE40_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED') -and
                    ($metadataLines -ccontains 'STAGE39_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED') -and
                    ($metadataLines -ccontains 'STAGE38_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED') -and
                    ($metadataLines -ccontains 'STAGE37_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED') -and
                    ($metadataLines -ccontains 'STAGE36_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED') -and
                    ($metadataLines -ccontains 'STAGE35_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED')
$stage42Preflight = ($metadataLines -ccontains 'CURRENT_STAGE=41') -and
                    ($metadataLines -ccontains 'LAST_COMPLETED_STAGE=41')
$stage42Evidence = ($metadataLines -ccontains 'STAGE42_PREFLIGHT_CI_RUN=44701413210') -and
                   ($metadataLines -ccontains 'STAGE42_PREFLIGHT_CI_SHA=c0d3ae0bc1578cd4cee6163eb0a4526e1f27c917') -and
                   ($metadataLines -ccontains 'STAGE42_PREFLIGHT_JOBS=16_OF_16_SUCCESS') -and
                   ($metadataLines -ccontains 'STAGE42_PREFLIGHT_ASSERTIONS_PASSED=1657') -and
                   ($metadataLines -ccontains 'STAGE42_PREFLIGHT_ASSERTIONS_FAILED=0')
$stage42Pending = ($metadataLines -ccontains 'CURRENT_STAGE=42') -and
                  ($metadataLines -ccontains 'CURRENT_DISCOVERY=27') -and
                  ($metadataLines -ccontains 'LAST_COMPLETED_STAGE=41') -and
                  ($metadataLines -ccontains 'STAGE42_RUNTIME_VERIFICATION=PENDING_NATIVE') -and $stage42Evidence
$stage42Sealed = ($metadataLines -ccontains 'CURRENT_STAGE=42') -and
                 ($metadataLines -ccontains 'CURRENT_DISCOVERY=27') -and
                 ($metadataLines -ccontains 'LAST_COMPLETED_STAGE=42') -and
                 ($metadataLines -ccontains 'STAGE42_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED') -and $stage42Evidence
$stage42Sealed = $stage42Sealed -or $stage43Allowed
$ready = ($metadataLines -ccontains 'TOTAL_STAGES=55') -and
         $predecessorsSealed -and ($stage42Preflight -or $stage42Pending -or $stage42Sealed)
if (-not $ready) { throw 'Stage42 requires the exact sealed Stage41 and one consistent Stage42 preflight/pending/sealed state' }
# Finite research oracle; the stage state determines whether this is preflight, activated Native, or a seal recheck.
function Mod42 { param([System.Numerics.BigInteger]$Value,[System.Numerics.BigInteger]$Modulus)
    return [System.Numerics.BigInteger]((($Value % $Modulus) + $Modulus) % $Modulus)
}
function Key42 { param([int]$C,[int]$T,[int]$S)
    return ('{0}|{1}|{2}' -f $C,$T,$S)
}
function Delta42 { param($P,$Q,[System.Numerics.BigInteger]$Modulus)
    return (Mod42 -Value (([System.Numerics.BigInteger]$Q.First)-([System.Numerics.BigInteger]$P.First)) -Modulus $Modulus)
}
function Pair42 { param($P,$Q,[System.Numerics.BigInteger]$Modulus,[string]$Label)
    Assert-StageEqual -Expected (Delta42 $P.W $Q.W $Modulus) -Actual (Delta42 $P.A $Q.A $Modulus) -Name "First $Label"
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
$seals = @(1..10)
Assert-StageEqual -Expected 4 -Actual $calc.Count -Name 'Calculation days'
Assert-StageEqual -Expected 4 -Actual $target.Count -Name 'Target days'
Assert-StageEqual -Expected 10 -Actual $seals.Count -Name 'Legal seals'
$uniqueCalc = @($calc | ForEach-Object { $_.ToString() } | Select-Object -Unique)
$uniqueTarget = @($target | ForEach-Object { $_.ToString() } | Select-Object -Unique)
Assert-StageEqual -Expected 4 -Actual $uniqueCalc.Count -Name 'Unique calculation days'
Assert-StageEqual -Expected 4 -Actual $uniqueTarget.Count -Name 'Unique target days'
$grid = @{}; $endpoints = 0
for($i=0;$i -lt 4;$i++) {
 for($j=0;$j -lt 4;$j++) {
  for($k=0;$k -lt 10;$k++) {
   $prod = Invoke-CalendarDateSpaghetti -CalculationDay $calc[$i] -TargetDay $target[$j]
   $actual = Get-Discovery13AnswerStreamFromContext -Context $prod -QueriedBowlId 1 -Seal $seals[$k]
   $normSauce = Invoke-NormSauce $calc[$i] $target[$j]
   $want = Get-NormAnswerStream -SauceResult $normSauce -QueriedBowlId 1 -Seal $seals[$k]
   $key = Key42 $i $j $k
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
foreach($e in $edges) { for($j=0;$j -lt 4;$j++) { for($k=0;$k -lt 10;$k++) {
 Pair42 $grid[(Key42 $e[0] $j $k)] $grid[(Key42 $e[1] $j $k)] $m "Calculation seam $($e[0])-$($e[1])|$j|$k"
 $calculationSeams++
}}}
$targetSeams = 0
foreach($e in $edges) { for($i=0;$i -lt 4;$i++) { for($k=0;$k -lt 10;$k++) {
 Pair42 $grid[(Key42 $i $e[0] $k)] $grid[(Key42 $i $e[1] $k)] $m "Target seam $i|$($e[0])-$($e[1])|$k"
 $targetSeams++
}}}
$faces = 0
foreach($ce in $edges) { foreach($te in $edges) { for($k=0;$k -lt 10;$k++) {
 $p00=$grid[(Key42 $ce[0] $te[0] $k)]
 $p01=$grid[(Key42 $ce[0] $te[1] $k)]
 $p10=$grid[(Key42 $ce[1] $te[0] $k)]
 $p11=$grid[(Key42 $ce[1] $te[1] $k)]
 $expected = Mod42 (([System.Numerics.BigInteger]$p11.W.First)-([System.Numerics.BigInteger]$p10.W.First)-([System.Numerics.BigInteger]$p01.W.First)+([System.Numerics.BigInteger]$p00.W.First)) $m
 $observed = Mod42 (([System.Numerics.BigInteger]$p11.A.First)-([System.Numerics.BigInteger]$p10.A.First)-([System.Numerics.BigInteger]$p01.A.First)+([System.Numerics.BigInteger]$p00.A.First)) $m
 Assert-StageEqual -Expected $expected -Actual $observed -Name "Mixed face First $($ce[0])|$($te[0])|$k"
 $ep=([int]$p00.W.Step)*([int]$p01.W.Step)*([int]$p10.W.Step)*([int]$p11.W.Step)
 $ap=([int]$p00.A.Step)*([int]$p01.A.Step)*([int]$p10.A.Step)*([int]$p11.A.Step)
 Assert-StageEqual -Expected ([bool]($ep -lt 0)) -Actual ([bool]($ap -lt 0)) -Name "Mixed face Step $($ce[0])|$($te[0])|$k"
 $faces++
}}}
$sealPairs = 0
for($i=0;$i -lt 4;$i++) { for($j=0;$j -lt 4;$j++) { for($k=0;$k -lt 9;$k++) {
 Pair42 $grid[(Key42 $i $j $k)] $grid[(Key42 $i $j ($k+1))] $m "Seal response $i|$j|$k"
 $sealPairs++
}}}
Write-Host "STAGE42_ENDPOINTS=$endpoints"
Write-Host "STAGE42_CALC_SEAMS=$calculationSeams"
Write-Host "STAGE42_TARGET_SEAMS=$targetSeams"
Write-Host "STAGE42_MIXED_FACES=$faces"
Write-Host "STAGE42_SEAL_PAIRS=$sealPairs"
Write-Host "STAGE42_ASSERTIONS_PASSED=$script:StageTestPassed"
Write-Host "STAGE42_ASSERTIONS_FAILED=$script:StageTestFailed"
if($endpoints -ne 160 -or $calculationSeams -ne 80 -or $targetSeams -ne 80 -or $faces -ne 40 -or $sealPairs -ne 144 -or $script:StageTestPassed -ne 1657 -or $script:StageTestFailed -ne 0) { Write-Host 'STAGE42_NATIVE=FAIL'; exit 1 }
if ($stage42Pending) { Write-Host 'STAGE42_NATIVE=PASS_PENDING_NO_SEAL' }
elseif ($stage42Sealed) { Write-Host 'STAGE42_NATIVE=SEALED_RECHECK_PASS' }
else { Write-Host 'STAGE42_PREFLIGHT=BOUNDED_RESEARCH_ONLY' }
exit 0
