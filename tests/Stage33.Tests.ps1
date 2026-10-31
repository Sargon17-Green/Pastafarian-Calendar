Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')
$md=Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')
$stage33Sealed = ($md -match '(?m)^CURRENT_STAGE=33\s*$') -and ($md -match '(?m)^LAST_COMPLETED_STAGE=33\s*$') -and ($md -match '(?m)^STAGE33_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$')
Assert-StageTrue -Condition (($md -match '(?m)^CURRENT_STAGE=32\s*$') -or $stage33Sealed) -Name 'Stage32 baseline or Stage33 exact seal'
Assert-StageTrue -Condition (($md -match '(?m)^LAST_COMPLETED_STAGE=32\s*$') -or $stage33Sealed) -Name 'Stage32 completed or Stage33 exact seal'
Assert-StageTrue -Condition ($md -match '(?m)^STAGE32_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -Name 'Stage32 sealed'
Assert-StageTrue -Condition ($md -match '(?m)^STAGE26_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED\s*$') -Name 'Stage26 historical red'
$f=[System.Numerics.BigInteger](Get-NormFoundationDay)
$y=Get-NormYear5000 -CalculationDay $f
$m=[System.Numerics.BigInteger]$script:Discovery01M
Assert-StageEqual -Expected ([System.Numerics.BigInteger]5000) -Actual $y.Number -Name 'Year 5000'
Assert-StageTrue -Condition ($y.OpenGateDay -lt $f -and $f -le $y.CloseGateDay) -Name 'Foundation in year'
Assert-StageTrue -Condition (($y.CloseGateDay-$y.OpenGateDay) -ge 252 -and ($y.CloseGateDay-$y.OpenGateDay) -le 5778) -Name 'Year length'
Assert-StageTrue -Condition (($y.CloseGateIndex-$y.OpenGateIndex) -ge 6) -Name 'Gate span'
function Get-Stage33Delta {
    param([System.Numerics.BigInteger]$A,[System.Numerics.BigInteger]$B,[System.Numerics.BigInteger]$Modulus)
    return [System.Numerics.BigInteger]((($B-$A)%$Modulus+$Modulus)%$Modulus)
}
$bases=@(
    [pscustomobject]@{L='BEFORE_OPEN';D=[System.Numerics.BigInteger]($y.OpenGateDay-1)}
    [pscustomobject]@{L='AT_OPEN';D=[System.Numerics.BigInteger]$y.OpenGateDay}
    [pscustomobject]@{L='BEFORE_CLOSE';D=[System.Numerics.BigInteger]($y.CloseGateDay-1)}
    [pscustomobject]@{L='AT_CLOSE';D=[System.Numerics.BigInteger]$y.CloseGateDay}
    [pscustomobject]@{L='BEFORE_FOUNDATION';D=[System.Numerics.BigInteger]($f-1)}
    [pscustomobject]@{L='AT_FOUNDATION';D=[System.Numerics.BigInteger]$f}
    [pscustomobject]@{L='AFTER_FOUNDATION';D=[System.Numerics.BigInteger]($f+1)}
    [pscustomobject]@{L='DISTANT_ORDINAL';D=[System.Numerics.BigInteger]($f+36525)}
)
$squares=0;$endpoints=0;$edges=0;$crossings=0;$zeros=0;$nonzeros=0;$mixedFlips=0;$mixedNoFlips=0;$seen=@{}
foreach($case in $bases){
    foreach($seal in @(1,2)){
        $grid=@{}
        foreach($ci in @(0,1)){
            foreach($ti in @(0,1)){
                $c=[System.Numerics.BigInteger]($f+$ci)
                $t=[System.Numerics.BigInteger]($case.D+$ti)
                $ctx=Invoke-CalendarDateSpaghetti -CalculationDay $c -TargetDay $t
                $got=Get-Discovery13AnswerStreamFromContext -Context $ctx -QueriedBowlId 1 -Seal $seal
                $want=Get-NormAnswerStream -SauceResult (Invoke-NormSauce $c $t) -QueriedBowlId 1 -Seal $seal
                $label="$($case.L) seal=$seal c=$ci t=$ti"
                Assert-StageEqual -Expected $want.First -Actual $got.First -Name "First $label"
                Assert-StageEqual -Expected $want.Step -Actual $got.Step -Name "Step $label"
                Assert-StageTrue -Condition ($got.First -ge 1 -and $got.First -le $m) -Name "First domain $label"
                Assert-StageTrue -Condition ($got.Step -eq 1 -or $got.Step -eq -1) -Name "Step domain $label"
                Assert-StageEqual -Expected 58 -Actual $ctx.legacyOrderMemoryWriteCount -Name "Legacy writes $label"
                Assert-StageEqual -Expected 1 -Actual $ctx.patch12InvocationCount -Name "Patch12 $label"
                $grid["$ci,$ti"]=[pscustomobject]@{G=$got;W=$want}
                $endpoints++
            }
        }
        $specs=@(
            [pscustomobject]@{A='0,0';B='0,1'}
            [pscustomobject]@{A='1,0';B='1,1'}
            [pscustomobject]@{A='0,0';B='1,0'}
            [pscustomobject]@{A='0,1';B='1,1'}
        )
        foreach($edge in $specs){
            $a=$grid[$edge.A];$b=$grid[$edge.B]
            $d=Get-Stage33Delta -A ([System.Numerics.BigInteger]$a.G.First) -B ([System.Numerics.BigInteger]$b.G.First) -Modulus $m
            $o=Get-Stage33Delta -A ([System.Numerics.BigInteger]$a.W.First) -B ([System.Numerics.BigInteger]$b.W.First) -Modulus $m
            Assert-StageEqual -Expected $o -Actual $d -Name "Edge First $($case.L) seal=$seal $($edge.A) to $($edge.B)"
            Assert-StageEqual -Expected ($a.W.Step -ne $b.W.Step) -Actual ($a.G.Step -ne $b.G.Step) -Name "Edge Step $($case.L) seal=$seal $($edge.A) to $($edge.B)"
            $edges++
        }
        $a=$grid['0,0'];$b=$grid['0,1'];$c=$grid['1,0'];$d=$grid['1,1']
        $t0=Get-Stage33Delta -A ([System.Numerics.BigInteger]$a.G.First) -B ([System.Numerics.BigInteger]$b.G.First) -Modulus $m
        $t1=Get-Stage33Delta -A ([System.Numerics.BigInteger]$c.G.First) -B ([System.Numerics.BigInteger]$d.G.First) -Modulus $m
        $ot0=Get-Stage33Delta -A ([System.Numerics.BigInteger]$a.W.First) -B ([System.Numerics.BigInteger]$b.W.First) -Modulus $m
        $ot1=Get-Stage33Delta -A ([System.Numerics.BigInteger]$c.W.First) -B ([System.Numerics.BigInteger]$d.W.First) -Modulus $m
        $mixed=Get-Stage33Delta -A $t0 -B $t1 -Modulus $m
        $oracleMixed=Get-Stage33Delta -A $ot0 -B $ot1 -Modulus $m
        $flip=(($a.G.Step -ne $b.G.Step) -ne ($c.G.Step -ne $d.G.Step))
        $oracleFlip=(($a.W.Step -ne $b.W.Step) -ne ($c.W.Step -ne $d.W.Step))
        Assert-StageEqual -Expected $oracleMixed -Actual $mixed -Name "Mixed First $($case.L) seal=$seal"
        Assert-StageEqual -Expected $oracleFlip -Actual $flip -Name "Mixed Step $($case.L) seal=$seal"
        if($mixed -eq [System.Numerics.BigInteger]0){$zeros++}else{$nonzeros++}
        if($flip){$mixedFlips++}else{$mixedNoFlips++}
        if($case.L -eq 'AT_OPEN' -or $case.L -eq 'AT_CLOSE'){$crossings++}
        $seen[$mixed.ToString()]=$true;$squares++
        Write-Host ('STAGE33_SQUARE LABEL={0} SEAL={1} BASE={2} MIXED_DELTA={3} MIXED_STEP={4}' -f $case.L,$seal,$case.D,$mixed,$flip)
    }
}
Assert-StageEqual -Expected 8 -Actual $bases.Count -Name 'Eight bases'
Assert-StageEqual -Expected 16 -Actual $squares -Name 'Sixteen squares'
Assert-StageEqual -Expected 64 -Actual $endpoints -Name 'Sixty-four endpoints'
Assert-StageEqual -Expected 64 -Actual $edges -Name 'Sixty-four edges'
Assert-StageEqual -Expected 4 -Actual $crossings -Name 'Four gate squares'
Assert-StageEqual -Expected 16 -Actual ($zeros+$nonzeros) -Name 'Mixed First conservation'
Assert-StageEqual -Expected 16 -Actual ($mixedFlips+$mixedNoFlips) -Name 'Mixed Step conservation'
Assert-StageTrue -Condition ($seen.Count -ge 1 -and $seen.Count -le 16) -Name 'Mixed diversity bounded'
Write-Host "STAGE33_SQUARES=$squares"
Write-Host "STAGE33_ENDPOINTS=$endpoints"
Write-Host "STAGE33_EDGES=$edges"
Write-Host "STAGE33_MIXED_FIRST_ZERO=$zeros"
Write-Host "STAGE33_MIXED_FIRST_NONZERO=$nonzeros"
Write-Host "STAGE33_MIXED_STEP_FLIP=$mixedFlips"
Write-Host "STAGE33_MIXED_STEP_SAME=$mixedNoFlips"
Write-Host ("STAGE33_DISTINCT_MIXED="+$seen.Count)
Write-Host "STAGE33_ASSERTIONS_PASSED=$script:StageTestPassed"
Write-Host "STAGE33_ASSERTIONS_FAILED=$script:StageTestFailed"
if($script:StageTestPassed -ne 560){Write-Host 'STAGE33_ASSERTION_COUNT=FAIL_EXPECTED_560';exit 1}
if($script:StageTestFailed -ne 0){Write-Host 'STAGE33_DISCOVERY18=FAIL';exit 1}
Write-Host 'STAGE33_DISCOVERY18=BOUNDED_RESEARCH_ONLY'
exit 0
