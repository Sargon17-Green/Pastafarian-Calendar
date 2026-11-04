Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

# Contract: docs/STAGE36_DISCOVERY21_DUAL_GATE_CONTRACT_20261102.md
# No production-derived expectations and no cross-branch fixtures.
$md=Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')
$pending = ($md -match '(?m)^CURRENT_STAGE=36\s*$') -and
           ($md -match '(?m)^LAST_COMPLETED_STAGE=35\s*$') -and
           ($md -match '(?m)^STAGE36_RUNTIME_VERIFICATION=PENDING_NATIVE\s*$')
$sealed = (($md -match '(?m)^CURRENT_STAGE=36\s*$') -and ($md -match '(?m)^LAST_COMPLETED_STAGE=36\s*$') -and ($md -match '(?m)^STAGE36_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -and ($md -match '(?m)^STAGE35_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$'))
$stage37Allowed = (($md -match '(?m)^CURRENT_STAGE=37\s*$') -and ($md -match '(?m)^LAST_COMPLETED_STAGE=36\s*$') -and ($md -match '(?m)^STAGE37_RUNTIME_VERIFICATION=PENDING_NATIVE\s*$') -and ($md -match '(?m)^STAGE36_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -and ($md -match '(?m)^STAGE35_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$')) -or (($md -match '(?m)^CURRENT_STAGE=37\s*$') -and ($md -match '(?m)^LAST_COMPLETED_STAGE=37\s*$') -and ($md -match '(?m)^STAGE37_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -and ($md -match '(?m)^STAGE36_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -and ($md -match '(?m)^STAGE35_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$'))
Assert-StageTrue -Condition ($pending -or $sealed -or $stage37Allowed) -Name 'Stage36 exact pending or sealed metadata'
Assert-StageTrue -Condition ($md -match '(?m)^STAGE35_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -Name 'Stage35 exact seal retained'
Assert-StageTrue -Condition ($md -match '(?m)^STAGE26_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED\s*$') -Name 'Historical expected-red retained'

$f=[System.Numerics.BigInteger](Get-NormFoundationDay)
$y=Get-NormYear5000 -CalculationDay $f
$o=[System.Numerics.BigInteger]$y.OpenGateDay
$c=[System.Numerics.BigInteger]$y.CloseGateDay
$m=[System.Numerics.BigInteger]$script:Discovery01M
Assert-StageEqual -Expected ([System.Numerics.BigInteger]5000) -Actual $y.Number -Name 'Independent normative year 5000'
Assert-StageTrue -Condition ($o -lt $f -and $f -le $c) -Name 'Foundation lies within (open, close]'
Assert-StageTrue -Condition (($c-$o) -ge 252 -and ($c-$o) -le 5778) -Name 'Normative year length is bounded'
Assert-StageTrue -Condition (($c-$o) -gt 0) -Name 'Positive open-close day span'
Assert-StageTrue -Condition ($m -gt 0) -Name 'Positive first-answer modulus'

function Get-Stage36ModDelta {
    param([System.Numerics.BigInteger]$Left,[System.Numerics.BigInteger]$Right,[System.Numerics.BigInteger]$Mod)
    return [System.Numerics.BigInteger]((($Right-$Left)%$Mod+$Mod)%$Mod)
}
function Get-Stage36Face {
    param([hashtable]$Grid,[int]$Seal,[string]$Field,[System.Numerics.BigInteger]$Mod)
    $a=$Grid[$Seal]['0,0'];$b=$Grid[$Seal]['0,1']
    $c=$Grid[$Seal]['1,0'];$d=$Grid[$Seal]['1,1']
    if($Field -eq 'Actual'){
        $top=Get-Stage36ModDelta -Left ([System.Numerics.BigInteger]$a.Actual.First) -Right ([System.Numerics.BigInteger]$b.Actual.First) -Mod $Mod
        $bottom=Get-Stage36ModDelta -Left ([System.Numerics.BigInteger]$c.Actual.First) -Right ([System.Numerics.BigInteger]$d.Actual.First) -Mod $Mod
        $q=[bool](($a.Actual.Step -ne $b.Actual.Step) -xor ($c.Actual.Step -ne $d.Actual.Step))
    } else {
        $top=Get-Stage36ModDelta -Left ([System.Numerics.BigInteger]$a.Expected.First) -Right ([System.Numerics.BigInteger]$b.Expected.First) -Mod $Mod
        $bottom=Get-Stage36ModDelta -Left ([System.Numerics.BigInteger]$c.Expected.First) -Right ([System.Numerics.BigInteger]$d.Expected.First) -Mod $Mod
        $q=[bool](($a.Expected.Step -ne $b.Expected.Step) -xor ($c.Expected.Step -ne $d.Expected.Step))
    }
    return [pscustomobject]@{D=(Get-Stage36ModDelta -Left $top -Right $bottom -Mod $Mod);Q=$q}
}

$calculationPairs=@(
    [pscustomobject]@{Label='OPEN';Start=[System.Numerics.BigInteger]$o},
    [pscustomobject]@{Label='CLOSE';Start=[System.Numerics.BigInteger]$c},
    [pscustomobject]@{Label='FOUNDATION';Start=[System.Numerics.BigInteger]($f-1)},
    [pscustomobject]@{Label='DISTANT';Start=[System.Numerics.BigInteger]($f+36525)}
)
$targetPairs=@(
    [pscustomobject]@{Label='OPEN';Start=[System.Numerics.BigInteger]$o},
    [pscustomobject]@{Label='CLOSE';Start=[System.Numerics.BigInteger]$c},
    [pscustomobject]@{Label='FOUNDATION';Start=[System.Numerics.BigInteger]($f-1)},
    [pscustomobject]@{Label='DISTANT';Start=[System.Numerics.BigInteger]($f+36525)}
)
Assert-StageEqual -Expected 4 -Actual $calculationPairs.Count -Name 'Four calculation pairs'
Assert-StageEqual -Expected 4 -Actual $targetPairs.Count -Name 'Four target pairs'

$cubes=0;$contexts=0;$endpoints=0;$sealEdges=0;$faces=0
$eZero=0;$eNonzero=0;$rFlip=0;$rSame=0
$unique=@{};$seenE=@{}
foreach($cp in $calculationPairs){
    foreach($tp in $targetPairs){
        $label=('{0}x{1}' -f $cp.Label,$tp.Label)
        $grid=@{1=@{};2=@{}}
        foreach($i in @(0,1)){
            foreach($j in @(0,1)){
                $dayC=[System.Numerics.BigInteger]($cp.Start+$i)
                $dayT=[System.Numerics.BigInteger]($tp.Start+$j)
                $unique[('{0}|{1}' -f $dayC,$dayT)]=$true
                foreach($seal in @(1,2)){
                    # Must create fresh production context and independent normative sauce for each seal.
                    $ctx=Invoke-CalendarDateSpaghetti -CalculationDay $dayC -TargetDay $dayT
                    $got=Get-Discovery13AnswerStreamFromContext -Context $ctx -QueriedBowlId 1 -Seal $seal
                    $wanted=Get-NormAnswerStream -SauceResult (Invoke-NormSauce $dayC $dayT) -QueriedBowlId 1 -Seal $seal
                    $loc=('{0}({1},{2}) seal={3}' -f $label,$i,$j,$seal)
                    Assert-StageEqual -Expected $wanted.First -Actual $got.First -Name "First $loc"
                    Assert-StageEqual -Expected $wanted.Step -Actual $got.Step -Name "Step $loc"
                    Assert-StageTrue -Condition ($got.First -ge 1 -and $got.First -le $m) -Name "First range $loc"
                    Assert-StageTrue -Condition ($got.Step -eq -1 -or $got.Step -eq 1) -Name "Step sign $loc"
                    Assert-StageEqual -Expected 58 -Actual $ctx.legacyOrderMemoryWriteCount -Name "Legacy write count $loc"
                    Assert-StageEqual -Expected 1 -Actual $ctx.patch12InvocationCount -Name "Patch12 call count $loc"
                    $grid[$seal]["$i,$j"]=[pscustomobject]@{Actual=$got;Expected=$wanted}
                    $endpoints++
                }
                $contexts++
            }
        }
        foreach($coord in @('0,0','0,1','1,0','1,1')){
            $a=$grid[1][$coord];$b=$grid[2][$coord]
            $actualDelta=Get-Stage36ModDelta -Left ([System.Numerics.BigInteger]$a.Actual.First) -Right ([System.Numerics.BigInteger]$b.Actual.First) -Mod $m
            $wantedDelta=Get-Stage36ModDelta -Left ([System.Numerics.BigInteger]$a.Expected.First) -Right ([System.Numerics.BigInteger]$b.Expected.First) -Mod $m
            Assert-StageEqual -Expected $wantedDelta -Actual $actualDelta -Name "Seal First delta $label $coord"
            Assert-StageEqual -Expected ($a.Expected.Step -ne $b.Expected.Step) -Actual ($a.Actual.Step -ne $b.Actual.Step) -Name "Seal Step flip $label $coord"
            $sealEdges++
        }
        $actualFaces=@{};$wantedFaces=@{}
        foreach($seal in @(1,2)){
            $af=Get-Stage36Face -Grid $grid -Seal $seal -Field 'Actual' -Mod $m
            $wf=Get-Stage36Face -Grid $grid -Seal $seal -Field 'Expected' -Mod $m
            Assert-StageEqual -Expected $wf.D -Actual $af.D -Name "Mixed First D $label seal=$seal"
            Assert-StageEqual -Expected $wf.Q -Actual $af.Q -Name "Mixed Step Q $label seal=$seal"
            $actualFaces[$seal]=$af;$wantedFaces[$seal]=$wf
            $faces++
        }
        $eActual=Get-Stage36ModDelta -Left $actualFaces[1].D -Right $actualFaces[2].D -Mod $m
        $eWanted=Get-Stage36ModDelta -Left $wantedFaces[1].D -Right $wantedFaces[2].D -Mod $m
        $rActual=[bool]($actualFaces[1].Q -xor $actualFaces[2].Q)
        $rWanted=[bool]($wantedFaces[1].Q -xor $wantedFaces[2].Q)
        Assert-StageEqual -Expected $eWanted -Actual $eActual -Name "Third-axis E $label"
        Assert-StageEqual -Expected $rWanted -Actual $rActual -Name "Third-axis R $label"
        if($eActual -eq [System.Numerics.BigInteger]0){$eZero++}else{$eNonzero++}
        if($rActual){$rFlip++}else{$rSame++}
        $seenE[$eActual.ToString()]=$true
        $cubes++
        Write-Host ('STAGE36_CUBE LABEL={0} C={1} T={2} D1={3} D2={4} Q1={5} Q2={6} E={7} R={8}' -f $label,$cp.Start,$tp.Start,$actualFaces[1].D,$actualFaces[2].D,$actualFaces[1].Q,$actualFaces[2].Q,$eActual,$rActual)
    }
}
Assert-StageEqual -Expected 16 -Actual $cubes -Name '16 labeled cubes'
Assert-StageEqual -Expected 128 -Actual $endpoints -Name '128 independent endpoint evaluations'
Write-Host "STAGE36_CUBES=$cubes"
Write-Host "STAGE36_LABELED_CONTEXTS=$contexts"
Write-Host ("STAGE36_UNIQUE_NUMERIC_CONTEXTS="+$unique.Count)
Write-Host "STAGE36_ENDPOINTS=$endpoints"
Write-Host "STAGE36_SEAL_EDGES=$sealEdges"
Write-Host "STAGE36_FACES=$faces"
Write-Host "STAGE36_E_ZERO=$eZero"
Write-Host "STAGE36_E_NONZERO=$eNonzero"
Write-Host "STAGE36_R_FLIP=$rFlip"
Write-Host "STAGE36_R_SAME=$rSame"
Write-Host ("STAGE36_DISTINCT_E="+$seenE.Count)
Write-Host "STAGE36_ASSERTIONS_PASSED=$script:StageTestPassed"
Write-Host "STAGE36_ASSERTIONS_FAILED=$script:StageTestFailed"
if($script:StageTestPassed -ne 1004 -or $script:StageTestFailed -ne 0){
    Write-Host 'STAGE36_DISCOVERY21=FAIL';exit 1
}
Write-Host 'STAGE36_DISCOVERY21=BOUNDED_RESEARCH_ONLY'
exit 0
