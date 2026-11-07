Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

# Stage37 Native: pending, sealed or exact Stage38-successor predecessor recheck.
# Oracle is the on-branch normative implementation, never the production stream.
$md=Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')
$stage37Pending = (($md -match '(?m)^CURRENT_STAGE=37\s*$') -and ($md -match '(?m)^LAST_COMPLETED_STAGE=36\s*$') -and ($md -match '(?m)^STAGE37_RUNTIME_VERIFICATION=PENDING_NATIVE\s*$') -and ($md -match '(?m)^STAGE36_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -and ($md -match '(?m)^STAGE35_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$'))
$stage38Pending = (($md -match '(?m)^CURRENT_STAGE=38\s*$') -and ($md -match '(?m)^LAST_COMPLETED_STAGE=37\s*$') -and ($md -match '(?m)^STAGE38_RUNTIME_VERIFICATION=PENDING_NATIVE\s*$') -and ($md -match '(?m)^STAGE37_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -and ($md -match '(?m)^STAGE36_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$'))
$stage38Sealed = (($md -match '(?m)^CURRENT_STAGE=(38|39)\s*$') -and ($md -match '(?m)^LAST_COMPLETED_STAGE=38\s*$') -and ($md -match '(?m)^STAGE38_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -and ($md -match '(?m)^STAGE37_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -and ($md -match '(?m)^STAGE36_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$'))
$stage37Sealed = (($md -match '(?m)^CURRENT_STAGE=37\s*$') -and ($md -match '(?m)^LAST_COMPLETED_STAGE=37\s*$') -and ($md -match '(?m)^STAGE37_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -and ($md -match '(?m)^STAGE36_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -and ($md -match '(?m)^STAGE35_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$')) -or $stage38Pending -or $stage38Sealed
Assert-StageTrue -Condition ($stage37Pending -or $stage37Sealed) -Name 'Stage37 exact Native pending or sealed state'
Assert-StageTrue -Condition (($stage37Pending -and ($md -match '(?m)^LAST_COMPLETED_STAGE=36\s*$')) -or ($stage37Sealed -and ($md -match '(?m)^LAST_COMPLETED_STAGE=(37|38)\s*$'))) -Name 'Stage37 exact last-completed pair'
Assert-StageTrue -Condition ($md -match '(?m)^STAGE36_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -Name 'Stage36 Native evidence seal'
Assert-StageTrue -Condition ($md -match '(?m)^STAGE35_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -Name 'Stage35 predecessor evidence seal'
Assert-StageTrue -Condition ($md -match '(?m)^STAGE26_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED\s*$') -Name 'Historical expected-red evidence'

$f=[System.Numerics.BigInteger](Get-NormFoundationDay)
$year=Get-NormYear5000 -CalculationDay $f
$o=[System.Numerics.BigInteger]$year.OpenGateDay
$c=[System.Numerics.BigInteger]$year.CloseGateDay
$m=[System.Numerics.BigInteger]$script:Discovery01M
Assert-StageEqual -Expected ([System.Numerics.BigInteger]5000) -Actual $year.Number -Name 'Independent normative year number'
Assert-StageTrue -Condition ($o -lt $f -and $f -le $c) -Name 'Foundation contained in normative year'
Assert-StageTrue -Condition (($c-$o) -ge 252 -and ($c-$o) -le 5778) -Name 'Normative year length bound'
Assert-StageTrue -Condition ($m -gt 0) -Name 'Positive first-answer modulus'

$calculationPairs=@(
    [pscustomobject]@{Label='OPEN';Start=$o},
    [pscustomobject]@{Label='CLOSE';Start=$c}
)
$targetPairs=@(
    [pscustomobject]@{Label='OPEN';Start=$o},
    [pscustomobject]@{Label='CLOSE';Start=$c}
)
$seals=@(1,5,10)
$sealPairs=@(
    [pscustomobject]@{A=1;B=5},
    [pscustomobject]@{A=5;B=10},
    [pscustomobject]@{A=1;B=10}
)
Assert-StageEqual -Expected 2 -Actual $calculationPairs.Count -Name 'Two calculation gate pairs'
Assert-StageEqual -Expected 2 -Actual $targetPairs.Count -Name 'Two target gate pairs'
Assert-StageEqual -Expected 3 -Actual $seals.Count -Name 'Three nonunit seal samples'

function Get-Stage37Residue {
    param(
      [System.Numerics.BigInteger]$From,
      [System.Numerics.BigInteger]$To,
      [System.Numerics.BigInteger]$Mod
    )
    return [System.Numerics.BigInteger]((($To-$From)%$Mod+$Mod)%$Mod)
}
function Get-Stage37Face {
    param([hashtable]$Grid,[int]$Seal,[string]$Kind,[System.Numerics.BigInteger]$Mod)
    $a=$Grid[$Seal]['0,0']; $b=$Grid[$Seal]['0,1']
    $c=$Grid[$Seal]['1,0']; $d=$Grid[$Seal]['1,1']
    if($Kind -eq 'Actual') {
        $aa=$a.Actual;$bb=$b.Actual;$cc=$c.Actual;$dd=$d.Actual
    } else {
        $aa=$a.Expected;$bb=$b.Expected;$cc=$c.Expected;$dd=$d.Expected
    }
    $top=Get-Stage37Residue -From ([System.Numerics.BigInteger]$aa.First) -To ([System.Numerics.BigInteger]$bb.First) -Mod $Mod
    $bottom=Get-Stage37Residue -From ([System.Numerics.BigInteger]$cc.First) -To ([System.Numerics.BigInteger]$dd.First) -Mod $Mod
    $dFirst=Get-Stage37Residue -From $top -To $bottom -Mod $Mod
    $qStep=[bool](($aa.Step -ne $bb.Step) -xor ($cc.Step -ne $dd.Step))
    return [pscustomobject]@{D=$dFirst;Q=$qStep}
}

$cubes=0;$contexts=0;$endpoints=0;$sealEdges=0;$faces=0;$sealFaceEdges=0
$unique=@{};$kZero=0;$kNonzero=0;$pTrue=0;$pFalse=0
foreach($cp in $calculationPairs) {
    foreach($tp in $targetPairs) {
        $label=('{0}x{1}' -f $cp.Label,$tp.Label)
        $grid=@{1=@{};5=@{};10=@{}}
        foreach($i in @(0,1)) {
            foreach($j in @(0,1)) {
                $dayC=[System.Numerics.BigInteger]($cp.Start+$i)
                $dayT=[System.Numerics.BigInteger]($tp.Start+$j)
                $unique[('{0}|{1}' -f $dayC,$dayT)]=$true
                $coord="$i,$j"
                foreach($seal in $seals) {
                    $ctx=Invoke-CalendarDateSpaghetti -CalculationDay $dayC -TargetDay $dayT
                    $actual=Get-Discovery13AnswerStreamFromContext -Context $ctx -QueriedBowlId 1 -Seal $seal
                    $expected=Get-NormAnswerStream -SauceResult (Invoke-NormSauce $dayC $dayT) -QueriedBowlId 1 -Seal $seal
                    $tag=('{0} {1} seal={2}' -f $label,$coord,$seal)
                    Assert-StageEqual -Expected $expected.First -Actual $actual.First -Name "First $tag"
                    Assert-StageEqual -Expected $expected.Step -Actual $actual.Step -Name "Step $tag"
                    Assert-StageTrue -Condition ($actual.First -ge 1 -and $actual.First -le $m) -Name "First domain $tag"
                    Assert-StageTrue -Condition ($actual.Step -eq -1 -or $actual.Step -eq 1) -Name "Step sign $tag"
                    Assert-StageEqual -Expected 58 -Actual $ctx.legacyOrderMemoryWriteCount -Name "Legacy write count $tag"
                    Assert-StageEqual -Expected 1 -Actual $ctx.patch12InvocationCount -Name "Patch12 call count $tag"
                    $grid[$seal][$coord]=[pscustomobject]@{Actual=$actual;Expected=$expected}
                    $endpoints++
                }
                $contexts++
            }
        }

        foreach($coord in @('0,0','0,1','1,0','1,1')) {
            foreach($sp in $sealPairs) {
                $p=$grid[$sp.A][$coord]; $q=$grid[$sp.B][$coord]
                $aDelta=Get-Stage37Residue -From ([System.Numerics.BigInteger]$p.Actual.First) -To ([System.Numerics.BigInteger]$q.Actual.First) -Mod $m
                $wDelta=Get-Stage37Residue -From ([System.Numerics.BigInteger]$p.Expected.First) -To ([System.Numerics.BigInteger]$q.Expected.First) -Mod $m
                Assert-StageEqual -Expected $wDelta -Actual $aDelta -Name "Seal First delta $label $coord $($sp.A)-$($sp.B)"
                Assert-StageEqual -Expected ($p.Expected.Step -ne $q.Expected.Step) -Actual ($p.Actual.Step -ne $q.Actual.Step) -Name "Seal Step flip $label $coord $($sp.A)-$($sp.B)"
                $sealEdges++
            }
            $a1=$grid[1][$coord].Actual;$a5=$grid[5][$coord].Actual;$a10=$grid[10][$coord].Actual
            $w1=$grid[1][$coord].Expected;$w5=$grid[5][$coord].Expected;$w10=$grid[10][$coord].Expected
            $aLong=Get-Stage37Residue -From ([System.Numerics.BigInteger]$a1.First) -To ([System.Numerics.BigInteger]$a10.First) -Mod $m
            $wShort=Get-Stage37Residue -From ([System.Numerics.BigInteger]$w1.First) -To ([System.Numerics.BigInteger]$w5.First) -Mod $m
            $wMid=Get-Stage37Residue -From ([System.Numerics.BigInteger]$w5.First) -To ([System.Numerics.BigInteger]$w10.First) -Mod $m
            $wantLong=[System.Numerics.BigInteger](($wShort+$wMid)%$m)
            Assert-StageEqual -Expected $wantLong -Actual $aLong -Name "Nonunit seal First composition $label $coord"
            $wantFlip=[bool](($w1.Step -ne $w5.Step) -xor ($w5.Step -ne $w10.Step))
            Assert-StageEqual -Expected $wantFlip -Actual ($a1.Step -ne $a10.Step) -Name "Nonunit seal Step composition $label $coord"

            $aShort=Get-Stage37Residue -From ([System.Numerics.BigInteger]$a1.First) -To ([System.Numerics.BigInteger]$a5.First) -Mod $m
            $aMid=Get-Stage37Residue -From ([System.Numerics.BigInteger]$a5.First) -To ([System.Numerics.BigInteger]$a10.First) -Mod $m
            $ka=[System.Numerics.BigInteger](((4*$aMid-5*$aShort)%$m+$m)%$m)
            $kw=[System.Numerics.BigInteger](((4*$wMid-5*$wShort)%$m+$m)%$m)
            Assert-StageEqual -Expected $kw -Actual $ka -Name "Nonunit seal First curvature $label $coord"
            $pa=[bool](($a1.Step -ne $a5.Step) -xor ($a5.Step -ne $a10.Step))
            $pw=[bool](($w1.Step -ne $w5.Step) -xor ($w5.Step -ne $w10.Step))
            Assert-StageEqual -Expected $pw -Actual $pa -Name "Nonunit seal Step parity $label $coord"
            if($ka -eq [System.Numerics.BigInteger]0){$kZero++}else{$kNonzero++}
            if($pa){$pTrue++}else{$pFalse++}
        }

        $actualFaces=@{};$wantedFaces=@{}
        foreach($seal in $seals) {
            $af=Get-Stage37Face -Grid $grid -Seal $seal -Kind 'Actual' -Mod $m
            $wf=Get-Stage37Face -Grid $grid -Seal $seal -Kind 'Expected' -Mod $m
            Assert-StageEqual -Expected $wf.D -Actual $af.D -Name "Gate mixed First $label seal=$seal"
            Assert-StageEqual -Expected $wf.Q -Actual $af.Q -Name "Gate mixed Step $label seal=$seal"
            $actualFaces[$seal]=$af;$wantedFaces[$seal]=$wf
            $faces++
        }
        foreach($sp in $sealPairs) {
            $afrom=$actualFaces[$sp.A];$ato=$actualFaces[$sp.B]
            $wfrom=$wantedFaces[$sp.A];$wto=$wantedFaces[$sp.B]
            $ad=Get-Stage37Residue -From $afrom.D -To $ato.D -Mod $m
            $wd=Get-Stage37Residue -From $wfrom.D -To $wto.D -Mod $m
            Assert-StageEqual -Expected $wd -Actual $ad -Name "Gate mixed First seal delta $label $($sp.A)-$($sp.B)"
            Assert-StageEqual -Expected ($wfrom.Q -xor $wto.Q) -Actual ($afrom.Q -xor $ato.Q) -Name "Gate mixed Step seal flip $label $($sp.A)-$($sp.B)"
            $sealFaceEdges++
        }
        $adLong=Get-Stage37Residue -From $actualFaces[1].D -To $actualFaces[10].D -Mod $m
        $wdShort=Get-Stage37Residue -From $wantedFaces[1].D -To $wantedFaces[5].D -Mod $m
        $wdMid=Get-Stage37Residue -From $wantedFaces[5].D -To $wantedFaces[10].D -Mod $m
        Assert-StageEqual -Expected ([System.Numerics.BigInteger](($wdShort+$wdMid)%$m)) -Actual $adLong -Name "Gate mixed First seal composition $label"
        Assert-StageEqual -Expected ($wantedFaces[1].Q -xor $wantedFaces[5].Q -xor $wantedFaces[5].Q -xor $wantedFaces[10].Q) -Actual ($actualFaces[1].Q -xor $actualFaces[10].Q) -Name "Gate mixed Step seal composition $label"
        $cubes++
        Write-Host ('STAGE37_CUBE LABEL={0} D1={1} D5={2} D10={3} Q1={4} Q5={5} Q10={6}' -f $label,$actualFaces[1].D,$actualFaces[5].D,$actualFaces[10].D,$actualFaces[1].Q,$actualFaces[5].Q,$actualFaces[10].Q)
    }
}
Write-Host "STAGE37_CUBES=$cubes"
Write-Host "STAGE37_CONTEXTS=$contexts"
Write-Host "STAGE37_UNIQUE_NUMERIC_CONTEXTS=$($unique.Count)"
Write-Host "STAGE37_ENDPOINTS=$endpoints"
Write-Host "STAGE37_SEAL_EDGES=$sealEdges"
Write-Host "STAGE37_FACES=$faces"
Write-Host "STAGE37_SEAL_FACE_EDGES=$sealFaceEdges"
Write-Host "STAGE37_K_ZERO=$kZero"
Write-Host "STAGE37_K_NONZERO=$kNonzero"
Write-Host "STAGE37_P_TRUE=$pTrue"
Write-Host "STAGE37_P_FALSE=$pFalse"
Write-Host "STAGE37_ASSERTIONS_PASSED=$script:StageTestPassed"
Write-Host "STAGE37_ASSERTIONS_FAILED=$script:StageTestFailed"
if($script:StageTestPassed -ne 516 -or $script:StageTestFailed -ne 0 -or $cubes -ne 4 -or $contexts -ne 16 -or $unique.Count -ne 16 -or $endpoints -ne 48 -or $sealEdges -ne 48 -or $faces -ne 12 -or $sealFaceEdges -ne 12) {
    Write-Host 'STAGE37_DISCOVERY22=FAIL';exit 1
}
Write-Host 'STAGE37_DISCOVERY22=BOUNDED_RESEARCH_ONLY'
exit 0
