Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')
$md=Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')
$stage34Awaiting = ($md -match '(?m)^CURRENT_STAGE=34\s*$') -and ($md -match '(?m)^LAST_COMPLETED_STAGE=33\s*$') -and ($md -match '(?m)^STAGE34_RUNTIME_VERIFICATION=PENDING_NATIVE\s*$')
$stage34Sealed = ((($md -match '(?m)^CURRENT_STAGE=34\s*$') -and ($md -match '(?m)^LAST_COMPLETED_STAGE=34\s*$') -and ($md -match '(?m)^STAGE34_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$')) -or (($md -match '(?m)^CURRENT_STAGE=35\s*$') -and ($md -match '(?m)^LAST_COMPLETED_STAGE=34\s*$') -and ($md -match '(?m)^STAGE34_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -and ($md -match '(?m)^STAGE35_RUNTIME_VERIFICATION=PENDING_NATIVE\s*$'))) -or (($md -match '(?m)^CURRENT_STAGE=35\s*$') -and ($md -match '(?m)^LAST_COMPLETED_STAGE=35\s*$') -and ($md -match '(?m)^STAGE35_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -and ($md -match '(?m)^STAGE34_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$'))
Assert-StageTrue -Condition ($md -match '(?m)^CURRENT_STAGE=(34|35)\s*$') -Name 'Stage34 current or Stage35 predecessor recheck'
Assert-StageTrue -Condition ($stage34Awaiting -or $stage34Sealed) -Name 'Stage34 pending or evidence-sealed metadata pair'
Assert-StageTrue -Condition (($md -match '(?m)^STAGE33_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -and ($md -match '(?m)^STAGE32_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$')) -Name 'Stage32 and Stage33 evidence seals retained'
Assert-StageTrue -Condition ($md -match '(?m)^STAGE26_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED\s*$') -Name 'Historical RED preserved'
$f=[System.Numerics.BigInteger](Get-NormFoundationDay)
$y=Get-NormYear5000 -CalculationDay $f
$m=[System.Numerics.BigInteger]$script:Discovery01M
Assert-StageEqual -Expected ([System.Numerics.BigInteger]5000) -Actual $y.Number -Name 'Normative year'
Assert-StageTrue -Condition ($y.OpenGateDay -lt $f -and $f -le $y.CloseGateDay) -Name 'Foundation inside year'
Assert-StageTrue -Condition (($y.CloseGateDay-$y.OpenGateDay) -ge 252 -and ($y.CloseGateDay-$y.OpenGateDay) -le 5778) -Name 'Year length'
Assert-StageTrue -Condition (($y.CloseGateIndex-$y.OpenGateIndex) -ge 6) -Name 'Gate span'
function Get-Stage34Mod {
    param([System.Numerics.BigInteger]$A,[System.Numerics.BigInteger]$B,[System.Numerics.BigInteger]$M)
    return [System.Numerics.BigInteger]((($B-$A)%$M+$M)%$M)
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
$cubes=0;$contexts=0;$endpoints=0;$sealEdges=0;$faces=0;$ez=0;$en=0;$rf=0;$rs=0
$unique=@{};$seenE=@{}
foreach($item in $bases){
    $grid=@{1=@{};2=@{}}
    foreach($i in @(0,1)){
        foreach($j in @(0,1)){
            $c=[System.Numerics.BigInteger]($f+$i)
            $t=[System.Numerics.BigInteger]($item.D+$j)
            $name=('{0} i={1} j={2}' -f $item.L,$i,$j)
            $unique[('{0}|{1}' -f $c,$t)]=$true
            foreach($seal in @(1,2)){
                # Independent materialization: no potentially mutable context is shared between seals.
                $ctx=Invoke-CalendarDateSpaghetti -CalculationDay $c -TargetDay $t
                $got=Get-Discovery13AnswerStreamFromContext -Context $ctx -QueriedBowlId 1 -Seal $seal
                $want=Get-NormAnswerStream -SauceResult (Invoke-NormSauce $c $t) -QueriedBowlId 1 -Seal $seal
                if($seal -eq 1){
                    Assert-StageEqual -Expected 58 -Actual $ctx.legacyOrderMemoryWriteCount -Name "Legacy writes $name"
                    Assert-StageEqual -Expected 1 -Actual $ctx.patch12InvocationCount -Name "Patch12 $name"
                } elseif($ctx.legacyOrderMemoryWriteCount -ne 58 -or $ctx.patch12InvocationCount -ne 1){
                    throw "Invalid independent seal-2 context $name"
                }
                Assert-StageEqual -Expected $want.First -Actual $got.First -Name "First $name seal=$seal"
                Assert-StageEqual -Expected $want.Step -Actual $got.Step -Name "Step $name seal=$seal"
                Assert-StageTrue -Condition ($got.First -ge 1 -and $got.First -le $m) -Name "First domain $name seal=$seal"
                Assert-StageTrue -Condition ($got.Step -eq -1 -or $got.Step -eq 1) -Name "Step domain $name seal=$seal"
                $grid[$seal]["$i,$j"]=[pscustomobject]@{G=$got;W=$want}
                $endpoints++
            }
            $contexts++
        }
    }
    foreach($key in @('0,0','0,1','1,0','1,1')){
        $a=$grid[1][$key];$b=$grid[2][$key]
        $gd=Get-Stage34Mod -A ([System.Numerics.BigInteger]$a.G.First) -B ([System.Numerics.BigInteger]$b.G.First) -M $m
        $wd=Get-Stage34Mod -A ([System.Numerics.BigInteger]$a.W.First) -B ([System.Numerics.BigInteger]$b.W.First) -M $m
        Assert-StageEqual -Expected $wd -Actual $gd -Name "Seal-edge First $($item.L) $key"
        Assert-StageEqual -Expected ($a.W.Step -ne $b.W.Step) -Actual ($a.G.Step -ne $b.G.Step) -Name "Seal-edge Step $($item.L) $key"
        $sealEdges++
    }
    $d=@{};$q=@{}
    foreach($seal in @(1,2)){
        $a=$grid[$seal]['0,0'];$b=$grid[$seal]['0,1']
        $c=$grid[$seal]['1,0'];$e=$grid[$seal]['1,1']
        $g0=Get-Stage34Mod -A ([System.Numerics.BigInteger]$a.G.First) -B ([System.Numerics.BigInteger]$b.G.First) -M $m
        $g1=Get-Stage34Mod -A ([System.Numerics.BigInteger]$c.G.First) -B ([System.Numerics.BigInteger]$e.G.First) -M $m
        $w0=Get-Stage34Mod -A ([System.Numerics.BigInteger]$a.W.First) -B ([System.Numerics.BigInteger]$b.W.First) -M $m
        $w1=Get-Stage34Mod -A ([System.Numerics.BigInteger]$c.W.First) -B ([System.Numerics.BigInteger]$e.W.First) -M $m
        $dg=Get-Stage34Mod -A $g0 -B $g1 -M $m
        $dw=Get-Stage34Mod -A $w0 -B $w1 -M $m
        $qg=(($a.G.Step -ne $b.G.Step) -xor ($c.G.Step -ne $e.G.Step))
        $qw=(($a.W.Step -ne $b.W.Step) -xor ($c.W.Step -ne $e.W.Step))
        Assert-StageEqual -Expected $dw -Actual $dg -Name "Face First $($item.L) seal=$seal"
        Assert-StageEqual -Expected $qw -Actual $qg -Name "Face Step $($item.L) seal=$seal"
        $d[$seal]=[pscustomobject]@{G=$dg;W=$dw}
        $q[$seal]=[pscustomobject]@{G=$qg;W=$qw}
        $faces++
    }
    $ge=Get-Stage34Mod -A $d[1].G -B $d[2].G -M $m
    $we=Get-Stage34Mod -A $d[1].W -B $d[2].W -M $m
    $gr=($q[1].G -xor $q[2].G);$wr=($q[1].W -xor $q[2].W)
    Assert-StageEqual -Expected $we -Actual $ge -Name "Third-axis First $($item.L)"
    Assert-StageEqual -Expected $wr -Actual $gr -Name "Third-axis Step $($item.L)"
    if($ge -eq [System.Numerics.BigInteger]0){$ez++}else{$en++}
    if($gr){$rf++}else{$rs++}
    $seenE[$ge.ToString()]=$true
    $cubes++
    Write-Host ('STAGE34_CUBE LABEL={0} BASE={1} D1={2} D2={3} Q1={4} Q2={5} E={6} R={7}' -f $item.L,$item.D,$d[1].G,$d[2].G,$q[1].G,$q[2].G,$ge,$gr)
}
# 32 labeled contexts can contain duplicate numeric pairs: adjacent bases overlap.
Assert-StageEqual -Expected 8 -Actual $bases.Count -Name 'Eight bases'
Assert-StageEqual -Expected 8 -Actual $cubes -Name 'Eight cubes'
Assert-StageEqual -Expected 32 -Actual $contexts -Name '32 labeled contexts'
Assert-StageEqual -Expected 64 -Actual $endpoints -Name '64 endpoints'
Assert-StageEqual -Expected 32 -Actual $sealEdges -Name '32 seal edges'
Assert-StageEqual -Expected 16 -Actual $faces -Name '16 faces'
Assert-StageEqual -Expected 8 -Actual ($ez+$en) -Name 'E conservation'
Assert-StageEqual -Expected 8 -Actual ($rf+$rs) -Name 'R conservation'
Write-Host "STAGE34_CUBES=$cubes"
Write-Host "STAGE34_LABELED_CONTEXTS=$contexts"
Write-Host ("STAGE34_UNIQUE_NUMERIC_CONTEXTS="+$unique.Count)
Write-Host "STAGE34_ENDPOINTS=$endpoints"
Write-Host "STAGE34_SEAL_EDGES=$sealEdges"
Write-Host "STAGE34_FACES=$faces"
Write-Host "STAGE34_E_ZERO=$ez"
Write-Host "STAGE34_E_NONZERO=$en"
Write-Host "STAGE34_R_FLIP=$rf"
Write-Host "STAGE34_R_SAME=$rs"
Write-Host ("STAGE34_DISTINCT_E="+$seenE.Count)
Write-Host "STAGE34_ASSERTIONS_PASSED=$script:StageTestPassed"
Write-Host "STAGE34_ASSERTIONS_FAILED=$script:StageTestFailed"
if($script:StageTestPassed -ne 448 -or $script:StageTestFailed -ne 0){
    Write-Host 'STAGE34_DISCOVERY19=FAIL';exit 1
}
Write-Host 'STAGE34_DISCOVERY19=BOUNDED_RESEARCH_ONLY'
exit 0
