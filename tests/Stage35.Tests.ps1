Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')
$md=Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')
$pending = ($md -match '(?m)^CURRENT_STAGE=35\s*$') -and ($md -match '(?m)^LAST_COMPLETED_STAGE=34\s*$') -and ($md -match '(?m)^STAGE35_RUNTIME_VERIFICATION=PENDING_NATIVE\s*$')
Assert-StageTrue -Condition $pending -Name 'Stage35 exact pending metadata'
Assert-StageTrue -Condition ($md -match '(?m)^STAGE34_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -Name 'Stage34 exact seal retained'
Assert-StageTrue -Condition (($md -match '(?m)^STAGE33_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -and ($md -match '(?m)^STAGE32_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$')) -Name 'Stage32 and Stage33 seals retained'
Assert-StageTrue -Condition ($md -match '(?m)^STAGE26_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED\s*$') -Name 'Historical expected-red retained'
$f=[System.Numerics.BigInteger](Get-NormFoundationDay)
$y=Get-NormYear5000 -CalculationDay $f
$m=[System.Numerics.BigInteger]$script:Discovery01M
Assert-StageEqual -Expected ([System.Numerics.BigInteger]5000) -Actual $y.Number -Name 'Normative year'
Assert-StageTrue -Condition ($y.OpenGateDay -lt $f -and $f -le $y.CloseGateDay) -Name 'Foundation inside year'
Assert-StageTrue -Condition (($y.CloseGateDay-$y.OpenGateDay) -ge 252 -and ($y.CloseGateDay-$y.OpenGateDay) -le 5778) -Name 'Year length'
Assert-StageTrue -Condition (($y.CloseGateIndex-$y.OpenGateIndex) -ge 6) -Name 'Gate span'
function Get-Stage35Mod {
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
$vectors=@([pscustomobject]@{L='A';A=2;B=1},[pscustomobject]@{L='B';A=1;B=2})
$cubes=0;$contexts=0;$endpoints=0;$sealEdges=0;$faces=0;$ez=0;$en=0;$rf=0;$rs=0;$scalePairs=0;$gz=0;$gn=0;$hf=0;$hs=0
$unique=@{};$seenE=@{}
foreach($item in $bases){
    $pair=@{}
    foreach($vector in $vectors){
    $grid=@{1=@{};2=@{}}
    foreach($i in @(0,1)){
        foreach($j in @(0,1)){
            $c=[System.Numerics.BigInteger]($f+$vector.A*$i)
            $t=[System.Numerics.BigInteger]($item.D+$vector.B*$j)
            $name=('{0} vec={1} i={2} j={3}' -f $item.L,$vector.L,$i,$j)
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
        $gd=Get-Stage35Mod -A ([System.Numerics.BigInteger]$a.G.First) -B ([System.Numerics.BigInteger]$b.G.First) -M $m
        $wd=Get-Stage35Mod -A ([System.Numerics.BigInteger]$a.W.First) -B ([System.Numerics.BigInteger]$b.W.First) -M $m
        Assert-StageEqual -Expected $wd -Actual $gd -Name "Seal-edge First $($item.L) $key"
        Assert-StageEqual -Expected ($a.W.Step -ne $b.W.Step) -Actual ($a.G.Step -ne $b.G.Step) -Name "Seal-edge Step $($item.L) $key"
        $sealEdges++
    }
    $d=@{};$q=@{}
    foreach($seal in @(1,2)){
        $a=$grid[$seal]['0,0'];$b=$grid[$seal]['0,1']
        $c=$grid[$seal]['1,0'];$e=$grid[$seal]['1,1']
        $g0=Get-Stage35Mod -A ([System.Numerics.BigInteger]$a.G.First) -B ([System.Numerics.BigInteger]$b.G.First) -M $m
        $g1=Get-Stage35Mod -A ([System.Numerics.BigInteger]$c.G.First) -B ([System.Numerics.BigInteger]$e.G.First) -M $m
        $w0=Get-Stage35Mod -A ([System.Numerics.BigInteger]$a.W.First) -B ([System.Numerics.BigInteger]$b.W.First) -M $m
        $w1=Get-Stage35Mod -A ([System.Numerics.BigInteger]$c.W.First) -B ([System.Numerics.BigInteger]$e.W.First) -M $m
        $dg=Get-Stage35Mod -A $g0 -B $g1 -M $m
        $dw=Get-Stage35Mod -A $w0 -B $w1 -M $m
        $qg=(($a.G.Step -ne $b.G.Step) -xor ($c.G.Step -ne $e.G.Step))
        $qw=(($a.W.Step -ne $b.W.Step) -xor ($c.W.Step -ne $e.W.Step))
        Assert-StageEqual -Expected $dw -Actual $dg -Name "Face First $($item.L) seal=$seal"
        Assert-StageEqual -Expected $qw -Actual $qg -Name "Face Step $($item.L) seal=$seal"
        $d[$seal]=[pscustomobject]@{G=$dg;W=$dw}
        $q[$seal]=[pscustomobject]@{G=$qg;W=$qw}
        $faces++
    }
    $ge=Get-Stage35Mod -A $d[1].G -B $d[2].G -M $m
    $we=Get-Stage35Mod -A $d[1].W -B $d[2].W -M $m
    $gr=($q[1].G -xor $q[2].G);$wr=($q[1].W -xor $q[2].W)
    Assert-StageEqual -Expected $we -Actual $ge -Name "Third-axis First $($item.L)"
    Assert-StageEqual -Expected $wr -Actual $gr -Name "Third-axis Step $($item.L)"
    if($ge -eq [System.Numerics.BigInteger]0){$ez++}else{$en++}
    if($gr){$rf++}else{$rs++}
    $seenE[$ge.ToString()]=$true
    $pair[$vector.L]=[pscustomobject]@{E=$ge;R=$gr;WantE=$we;WantR=$wr}
    $cubes++
    Write-Host ('STAGE35_CUBE LABEL={0} VECTOR={1} BASE={2} E={3} R={4}' -f $item.L,$vector.L,$item.D,$ge,$gr)
    }
    $g=Get-Stage35Mod -A $pair['B'].E -B $pair['A'].E -M $m
    $wantG=Get-Stage35Mod -A $pair['B'].WantE -B $pair['A'].WantE -M $m
    $h=($pair['A'].R -xor $pair['B'].R)
    $wantH=($pair['A'].WantR -xor $pair['B'].WantR)
    Assert-StageEqual -Expected $wantG -Actual $g -Name "Anisotropy G $($item.L)"
    Assert-StageEqual -Expected $wantH -Actual $h -Name "Anisotropy H $($item.L)"
    if($g -eq [System.Numerics.BigInteger]0){$gz++}else{$gn++}
    if($h){$hf++}else{$hs++}
    $scalePairs++
    Write-Host ('STAGE35_PAIR LABEL={0} BASE={1} G={2} H={3}' -f $item.L,$item.D,$g,$h)
}
# Labeled contexts may overlap numerically.
Assert-StageEqual -Expected 8 -Actual $bases.Count -Name 'Eight bases'
Assert-StageEqual -Expected 2 -Actual $vectors.Count -Name 'Two displacement vectors'
Assert-StageEqual -Expected 16 -Actual $cubes -Name '16 cubes'
Assert-StageEqual -Expected 64 -Actual $contexts -Name '64 labeled contexts'
Assert-StageEqual -Expected 128 -Actual $endpoints -Name '128 endpoints'
Assert-StageEqual -Expected 64 -Actual $sealEdges -Name '64 seal edges'
Assert-StageEqual -Expected 32 -Actual $faces -Name '32 faces'
Assert-StageEqual -Expected 8 -Actual $scalePairs -Name 'Eight paired anisotropy contrasts'
Write-Host "STAGE35_CUBES=$cubes"
Write-Host "STAGE35_SCALE_PAIRS=$scalePairs"
Write-Host "STAGE35_G_ZERO=$gz"
Write-Host "STAGE35_G_NONZERO=$gn"
Write-Host "STAGE35_H_FLIP=$hf"
Write-Host "STAGE35_H_SAME=$hs"
Write-Host "STAGE35_LABELED_CONTEXTS=$contexts"
Write-Host ("STAGE35_UNIQUE_NUMERIC_CONTEXTS="+$unique.Count)
Write-Host "STAGE35_ENDPOINTS=$endpoints"
Write-Host "STAGE35_SEAL_EDGES=$sealEdges"
Write-Host "STAGE35_FACES=$faces"
Write-Host "STAGE35_E_ZERO=$ez"
Write-Host "STAGE35_E_NONZERO=$en"
Write-Host "STAGE35_R_FLIP=$rf"
Write-Host "STAGE35_R_SAME=$rs"
Write-Host ("STAGE35_DISTINCT_E="+$seenE.Count)
Write-Host "STAGE35_ASSERTIONS_PASSED=$script:StageTestPassed"
Write-Host "STAGE35_ASSERTIONS_FAILED=$script:StageTestFailed"
if($script:StageTestPassed -ne 896 -or $script:StageTestFailed -ne 0){
    Write-Host 'STAGE35_DISCOVERY20=FAIL';exit 1
}
Write-Host 'STAGE35_DISCOVERY20=BOUNDED_RESEARCH_ONLY'
exit 0
