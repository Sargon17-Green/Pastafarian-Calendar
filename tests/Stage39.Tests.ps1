Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

# Stage39 / Discovery24: cross-context full-seal PRE-FLIGHT ONLY.
# Same-branch independent normative oracle, fresh production context per endpoint.
# No mutation of DEVELOPMENT_STAGE, source, oracle, or predecessor seal.
$md=Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')
$stage38Sealed=(($md -match '(?m)^CURRENT_STAGE=38\s*$') -and ($md -match '(?m)^LAST_COMPLETED_STAGE=38\s*$') -and ($md -match '(?m)^STAGE38_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$'))
Assert-StageTrue -Condition $stage38Sealed -Name 'Stage38 exact sealed predecessor'
Assert-StageTrue -Condition ($md -match '(?m)^STAGE37_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -Name 'Stage37 predecessor evidence'
Assert-StageTrue -Condition ($md -match '(?m)^STAGE36_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -Name 'Stage36 predecessor evidence'
Assert-StageTrue -Condition ($md -match '(?m)^STAGE35_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -Name 'Stage35 predecessor evidence'
Assert-StageTrue -Condition ($md -match '(?m)^STAGE26_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED\s*$') -Name 'Historical expected red preserved'

$f=[System.Numerics.BigInteger](Get-NormFoundationDay)
$year=Get-NormYear5000 -CalculationDay $f
$o=[System.Numerics.BigInteger]$year.OpenGateDay
$c=[System.Numerics.BigInteger]$year.CloseGateDay
$m=[System.Numerics.BigInteger]$script:Discovery01M
$d=[System.Numerics.BigInteger]($f+[System.Numerics.BigInteger]36525)
Assert-StageEqual -Expected ([System.Numerics.BigInteger]5000) -Actual $year.Number -Name 'Normative year 5000'
Assert-StageTrue -Condition ($o -lt $f -and $f -le $c) -Name 'Foundation inside normative year gates'
Assert-StageTrue -Condition ($m -gt 0) -Name 'Positive modulus'
Assert-StageEqual -Expected ([System.Numerics.BigInteger]36525) -Actual ($d-$f) -Name 'Distant-day offset'

$calcs=@($f,$d)
$targets=@($f,$d)
$seals=@(1..10)
Assert-StageEqual -Expected 2 -Actual $calcs.Count -Name 'Two calculation days'
Assert-StageEqual -Expected 2 -Actual $targets.Count -Name 'Two target days'
Assert-StageEqual -Expected 10 -Actual $seals.Count -Name 'Ten legal seals'

function Get-Stage39Modulo {
    param([System.Numerics.BigInteger]$Value,[System.Numerics.BigInteger]$Modulus)
    return [System.Numerics.BigInteger]((($Value % $Modulus) + $Modulus) % $Modulus)
}
function Get-Stage39Face {
    param($P00,$P01,$P10,$P11,[System.Numerics.BigInteger]$Modulus)
    $raw=([System.Numerics.BigInteger]$P11.First)-([System.Numerics.BigInteger]$P10.First)-([System.Numerics.BigInteger]$P01.First)+([System.Numerics.BigInteger]$P00.First)
    $delta=Get-Stage39Modulo -Value $raw -Modulus $Modulus
    $flip=[bool](($P00.Step -ne $P01.Step) -xor ($P10.Step -ne $P11.Step))
    return [pscustomobject]@{D=$delta;Q=$flip}
}

$entries=@{}
$contexts=0;$endpoints=0
for($ci=0;$ci -lt 2;$ci++) {
    for($ti=0;$ti -lt 2;$ti++) {
        $contexts++
        foreach($seal in $seals) {
            $prod=Invoke-CalendarDateSpaghetti -CalculationDay $calcs[$ci] -TargetDay $targets[$ti]
            $actual=Get-Discovery13AnswerStreamFromContext -Context $prod -QueriedBowlId 1 -Seal $seal
            $wanted=Get-NormAnswerStream -SauceResult (Invoke-NormSauce $calcs[$ci] $targets[$ti]) -QueriedBowlId 1 -Seal $seal
            $tag=('{0},{1},seal={2}' -f $ci,$ti,$seal)
            Assert-StageEqual -Expected $wanted.First -Actual $actual.First -Name "First $tag"
            Assert-StageEqual -Expected $wanted.Step -Actual $actual.Step -Name "Step $tag"
            Assert-StageTrue -Condition ($actual.First -ge 1 -and $actual.First -le $m) -Name "First domain $tag"
            Assert-StageTrue -Condition ($actual.Step -eq -1 -or $actual.Step -eq 1) -Name "Step sign $tag"
            Assert-StageEqual -Expected 58 -Actual $prod.legacyOrderMemoryWriteCount -Name "Legacy writes $tag"
            Assert-StageEqual -Expected 1 -Actual $prod.patch12InvocationCount -Name "Patch12 calls $tag"
            $entries[('{0}|{1}|{2}' -f $ci,$ti,$seal)]=[pscustomobject]@{A=$actual;W=$wanted}
            $endpoints++
        }
    }
}

$actualFaces=@{};$normativeFaces=@{};$faces=0
$dZero=0;$dNonzero=0;$qTrue=0;$qFalse=0
foreach($seal in $seals) {
    $p00=$entries[('0|0|{0}' -f $seal)]
    $p01=$entries[('0|1|{0}' -f $seal)]
    $p10=$entries[('1|0|{0}' -f $seal)]
    $p11=$entries[('1|1|{0}' -f $seal)]
    $got=Get-Stage39Face -P00 $p00.A -P01 $p01.A -P10 $p10.A -P11 $p11.A -Modulus $m
    $want=Get-Stage39Face -P00 $p00.W -P01 $p01.W -P10 $p10.W -P11 $p11.W -Modulus $m
    Assert-StageEqual -Expected $want.D -Actual $got.D -Name "Mixed First face seal=$seal"
    Assert-StageEqual -Expected $want.Q -Actual $got.Q -Name "Mixed Step face seal=$seal"
    $actualFaces[$seal]=$got
    $normativeFaces[$seal]=$want
    if($got.D -eq 0) { $dZero++ } else { $dNonzero++ }
    if($got.Q) { $qTrue++ } else { $qFalse++ }
    $faces++
}

$pairs=0;$actualCollisions=0;$normativeCollisions=0
for($a=1;$a -le 9;$a++) {
    for($b=($a+1);$b -le 10;$b++) {
        $g1=$actualFaces[$a];$g2=$actualFaces[$b]
        $w1=$normativeFaces[$a];$w2=$normativeFaces[$b]
        $gotDelta=Get-Stage39Modulo -Value ([System.Numerics.BigInteger]($g2.D-$g1.D)) -Modulus $m
        $wantDelta=Get-Stage39Modulo -Value ([System.Numerics.BigInteger]($w2.D-$w1.D)) -Modulus $m
        Assert-StageEqual -Expected $wantDelta -Actual $gotDelta -Name "Mixed-face seal displacement $a-$b"
        Assert-StageEqual -Expected ([bool]($w1.Q -xor $w2.Q)) -Actual ([bool]($g1.Q -xor $g2.Q)) -Name "Mixed-face seal flip $a-$b"
        if(($g1.D -eq $g2.D) -and ($g1.Q -eq $g2.Q)) { $actualCollisions++ }
        if(($w1.D -eq $w2.D) -and ($w1.Q -eq $w2.Q)) { $normativeCollisions++ }
        $pairs++
    }
}
Assert-StageEqual -Expected $normativeCollisions -Actual $actualCollisions -Name 'Independent full mixed-face state collision count'

$triples=0;$kZero=0;$kNonzero=0;$tTrue=0;$tFalse=0
for($a=1;$a -le 8;$a++) {
    $g1=$actualFaces[$a];$g2=$actualFaces[($a+1)];$g3=$actualFaces[($a+2)]
    $w1=$normativeFaces[$a];$w2=$normativeFaces[($a+1)];$w3=$normativeFaces[($a+2)]
    $ga=Get-Stage39Modulo -Value ([System.Numerics.BigInteger]($g2.D-$g1.D)) -Modulus $m
    $gb=Get-Stage39Modulo -Value ([System.Numerics.BigInteger]($g3.D-$g2.D)) -Modulus $m
    $wa=Get-Stage39Modulo -Value ([System.Numerics.BigInteger]($w2.D-$w1.D)) -Modulus $m
    $wb=Get-Stage39Modulo -Value ([System.Numerics.BigInteger]($w3.D-$w2.D)) -Modulus $m
    $gotK=Get-Stage39Modulo -Value ([System.Numerics.BigInteger]($gb-$ga)) -Modulus $m
    $wantK=Get-Stage39Modulo -Value ([System.Numerics.BigInteger]($wb-$wa)) -Modulus $m
    $gotT=[bool](($g1.Q -ne $g2.Q) -xor ($g2.Q -ne $g3.Q))
    $wantT=[bool](($w1.Q -ne $w2.Q) -xor ($w2.Q -ne $w3.Q))
    Assert-StageEqual -Expected $wantK -Actual $gotK -Name "Mixed-face curvature triple=$a"
    Assert-StageEqual -Expected $wantT -Actual $gotT -Name "Mixed-face parity triple=$a"
    if($gotK -eq 0) { $kZero++ } else { $kNonzero++ }
    if($gotT) { $tTrue++ } else { $tFalse++ }
    $triples++
}
Write-Host "STAGE39_CONTEXTS=$contexts"
Write-Host "STAGE39_ENDPOINTS=$endpoints"
Write-Host "STAGE39_SEAL_VALUES=$($seals.Count)"
Write-Host "STAGE39_MIXED_FACES=$faces"
Write-Host "STAGE39_PAIRS=$pairs"
Write-Host "STAGE39_TRIPLES=$triples"
Write-Host "STAGE39_COLLISION_COMPARISONS=1"
Write-Host "STAGE39_ACTUAL_COLLISIONS=$actualCollisions"
Write-Host "STAGE39_NORMATIVE_COLLISIONS=$normativeCollisions"
Write-Host "STAGE39_D_ZERO=$dZero"
Write-Host "STAGE39_D_NONZERO=$dNonzero"
Write-Host "STAGE39_Q_TRUE=$qTrue"
Write-Host "STAGE39_Q_FALSE=$qFalse"
Write-Host "STAGE39_K_ZERO=$kZero"
Write-Host "STAGE39_K_NONZERO=$kNonzero"
Write-Host "STAGE39_T_TRUE=$tTrue"
Write-Host "STAGE39_T_FALSE=$tFalse"
Write-Host "STAGE39_ASSERTIONS_PASSED=$script:StageTestPassed"
Write-Host "STAGE39_ASSERTIONS_FAILED=$script:StageTestFailed"
if($script:StageTestPassed -ne 379 -or $script:StageTestFailed -ne 0 -or $contexts -ne 4 -or $endpoints -ne 40 -or $faces -ne 10 -or $pairs -ne 45 -or $triples -ne 8) {
    Write-Host 'STAGE39_DISCOVERY24_PREFLIGHT=FAIL'
    exit 1
}
Write-Host 'STAGE39_DISCOVERY24_PREFLIGHT=BOUNDED_RESEARCH_ONLY'
exit 0
