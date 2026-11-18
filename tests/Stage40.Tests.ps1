Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

# Stage40 / Discovery25: calculation-day gate crossings, research preflight only.
# Each expected First/Step is obtained from an independent normative sauce call.
$md=Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')
$sealed=((($md -match '(?m)^CURRENT_STAGE=39\s*$') -or (($md -match '(?m)^CURRENT_STAGE=(40|41)\s*$') -and ($md -match '(?m)^STAGE40_RUNTIME_VERIFICATION=(PENDING_NATIVE|EVIDENCE_ONLY_CONFIRMED)\s*$'))) -and
         ($md -match '(?m)^LAST_COMPLETED_STAGE=(39|40|41)\s*$') -and
         ($md -match '(?m)^STAGE39_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -and
         ($md -match '(?m)^STAGE38_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -and
         ($md -match '(?m)^STAGE37_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -and
         ($md -match '(?m)^STAGE36_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -and
         ($md -match '(?m)^STAGE35_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$'))
Assert-StageTrue -Condition $sealed -Name 'Stage39 exact evidence-sealed predecessor'
Assert-StageTrue -Condition ($md -match '(?m)^STAGE26_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED\s*$') -Name 'Stage26 historical red preserved'

$f=[System.Numerics.BigInteger](Get-NormFoundationDay)
$year=Get-NormYear5000 -CalculationDay $f
$o=[System.Numerics.BigInteger]$year.OpenGateDay
$c=[System.Numerics.BigInteger]$year.CloseGateDay
$m=[System.Numerics.BigInteger]$script:Discovery01M
Assert-StageEqual -Expected ([System.Numerics.BigInteger]5000) -Actual $year.Number -Name 'Normative boundary year 5000'
Assert-StageTrue -Condition ($o -lt $f -and $f -le $c) -Name 'Foundation inside year 5000'
Assert-StageTrue -Condition ($m -gt 0) -Name 'Positive modulus'

$calcs=@([System.Numerics.BigInteger]($o-1),$o,$c,[System.Numerics.BigInteger]($c+1))
$targets=@($f,[System.Numerics.BigInteger]($f+36525))
$seals=@(1,2,3,5,8,10)
Assert-StageEqual -Expected 4 -Actual $calcs.Count -Name 'Four calculation days'
Assert-StageEqual -Expected 2 -Actual $targets.Count -Name 'Two target days'
Assert-StageEqual -Expected 6 -Actual $seals.Count -Name 'Six legal seals'
$uniqueDays=@($calcs | ForEach-Object { $_.ToString() } | Select-Object -Unique)
Assert-StageEqual -Expected 4 -Actual $uniqueDays.Count -Name 'Four distinct calculation days'

function Get-Stage40Mod {
    param([System.Numerics.BigInteger]$Value,[System.Numerics.BigInteger]$Modulus)
    return [System.Numerics.BigInteger]((($Value % $Modulus)+$Modulus) % $Modulus)
}
function Get-Stage40Displacement {
    param($First,$Second,[System.Numerics.BigInteger]$Modulus)
    $delta=([System.Numerics.BigInteger]$Second.First)-([System.Numerics.BigInteger]$First.First)
    return (Get-Stage40Mod -Value $delta -Modulus $Modulus)
}

$entries=@{};$endpoints=0
for($ci=0;$ci -lt 4;$ci++) {
    for($ti=0;$ti -lt 2;$ti++) {
        for($si=0;$si -lt 6;$si++) {
            $seal=$seals[$si]
            $prod=Invoke-CalendarDateSpaghetti -CalculationDay $calcs[$ci] -TargetDay $targets[$ti]
            $got=Get-Discovery13AnswerStreamFromContext -Context $prod -QueriedBowlId 1 -Seal $seal
            $normSauce=Invoke-NormSauce $calcs[$ci] $targets[$ti]
            $want=Get-NormAnswerStream -SauceResult $normSauce -QueriedBowlId 1 -Seal $seal
            $label=('{0}|{1}|{2}' -f $ci,$ti,$seal)
            Assert-StageEqual -Expected $want.First -Actual $got.First -Name "First $label"
            Assert-StageEqual -Expected $want.Step -Actual $got.Step -Name "Step $label"
            Assert-StageTrue -Condition ($got.First -ge 1 -and $got.First -le $m) -Name "First domain $label"
            Assert-StageTrue -Condition ($got.Step -eq -1 -or $got.Step -eq 1) -Name "Step sign $label"
            Assert-StageEqual -Expected 58 -Actual $prod.legacyOrderMemoryWriteCount -Name "Legacy writes $label"
            Assert-StageEqual -Expected 1 -Actual $prod.patch12InvocationCount -Name "Patch12 calls $label"
            $entries[('{0}|{1}|{2}' -f $ci,$ti,$si)]=[pscustomobject]@{A=$got;W=$want}
            $endpoints++
        }
    }
}

$seamPairs=0
foreach($edge in @(@(0,1),@(2,3))) {
    for($ti=0;$ti -lt 2;$ti++) {
        for($si=0;$si -lt 6;$si++) {
            $a=$entries[('{0}|{1}|{2}' -f $edge[0],$ti,$si)]
            $b=$entries[('{0}|{1}|{2}' -f $edge[1],$ti,$si)]
            $actualDelta=Get-Stage40Displacement -First $a.A -Second $b.A -Modulus $m
            $normDelta=Get-Stage40Displacement -First $a.W -Second $b.W -Modulus $m
            Assert-StageEqual -Expected $normDelta -Actual $actualDelta -Name "Gate First edge=$($edge[0])-$($edge[1]) target=$ti sealIndex=$si"
            Assert-StageEqual -Expected ([bool]($a.W.Step -ne $b.W.Step)) -Actual ([bool]($a.A.Step -ne $b.A.Step)) -Name "Gate Step edge=$($edge[0])-$($edge[1]) target=$ti sealIndex=$si"
            $seamPairs++
        }
    }
}

$sealPairs=0
for($ci=0;$ci -lt 4;$ci++) {
    for($ti=0;$ti -lt 2;$ti++) {
        for($si=0;$si -lt 5;$si++) {
            $a=$entries[('{0}|{1}|{2}' -f $ci,$ti,$si)]
            $b=$entries[('{0}|{1}|{2}' -f $ci,$ti,($si+1))]
            $actualDelta=Get-Stage40Displacement -First $a.A -Second $b.A -Modulus $m
            $normDelta=Get-Stage40Displacement -First $a.W -Second $b.W -Modulus $m
            Assert-StageEqual -Expected $normDelta -Actual $actualDelta -Name "Seal First calc=$ci target=$ti sealIndex=$si"
            Assert-StageEqual -Expected ([bool]($a.W.Step -ne $b.W.Step)) -Actual ([bool]($a.A.Step -ne $b.A.Step)) -Name "Seal Step calc=$ci target=$ti sealIndex=$si"
            $sealPairs++
        }
    }
}

Write-Host "STAGE40_CALC_DAYS=$($calcs.Count)"
Write-Host "STAGE40_TARGETS=$($targets.Count)"
Write-Host "STAGE40_SEALS=$($seals.Count)"
Write-Host "STAGE40_ENDPOINTS=$endpoints"
Write-Host "STAGE40_GATE_SEAMS=$seamPairs"
Write-Host "STAGE40_SEAL_PAIRS=$sealPairs"
Write-Host "STAGE40_ASSERTIONS_PASSED=$script:StageTestPassed"
Write-Host "STAGE40_ASSERTIONS_FAILED=$script:StageTestFailed"
if($script:StageTestPassed -ne 425 -or $script:StageTestFailed -ne 0 -or $endpoints -ne 48 -or $seamPairs -ne 24 -or $sealPairs -ne 40) {
    Write-Host 'STAGE40_DISCOVERY25_PREFLIGHT=FAIL'
    exit 1
}
Write-Host 'STAGE40_DISCOVERY25_PREFLIGHT=BOUNDED_RESEARCH_ONLY'
exit 0
