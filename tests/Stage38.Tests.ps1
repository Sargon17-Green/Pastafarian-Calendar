Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

# Stage38 / Discovery23: pending Native with Stage37 exact predecessor sealed.
# Expectations are computed by the independently maintained normative oracle.
# No production-derived fixtures, mutations or cross-branch code.
$md=Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')
$stage38Pending = (($md -match '(?m)^CURRENT_STAGE=38\s*$') -and ($md -match '(?m)^LAST_COMPLETED_STAGE=37\s*$') -and ($md -match '(?m)^STAGE38_RUNTIME_VERIFICATION=PENDING_NATIVE\s*$'))
$stage38Sealed = (($md -match '(?m)^CURRENT_STAGE=(38|39)\s*$') -and ($md -match '(?m)^LAST_COMPLETED_STAGE=38\s*$') -and ($md -match '(?m)^STAGE38_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -and ($md -match '(?m)^STAGE37_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -and ($md -match '(?m)^STAGE36_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$'))
Assert-StageTrue -Condition ($stage38Pending -or $stage38Sealed) -Name 'Stage38 exact pending or sealed state'
Assert-StageTrue -Condition ($md -match '(?m)^STAGE37_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -Name 'Stage37 native evidence'
Assert-StageTrue -Condition ($md -match '(?m)^STAGE36_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -Name 'Stage36 native evidence'
Assert-StageTrue -Condition ($md -match '(?m)^STAGE35_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -Name 'Stage35 native evidence'
Assert-StageTrue -Condition ($md -match '(?m)^STAGE26_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED\s*$') -Name 'Historical expected red retained'

$f=[System.Numerics.BigInteger](Get-NormFoundationDay)
$year=Get-NormYear5000 -CalculationDay $f
$o=[System.Numerics.BigInteger]$year.OpenGateDay
$c=[System.Numerics.BigInteger]$year.CloseGateDay
$m=[System.Numerics.BigInteger]$script:Discovery01M
$d=[System.Numerics.BigInteger]($f+[System.Numerics.BigInteger]36525)
Assert-StageEqual -Expected ([System.Numerics.BigInteger]5000) -Actual $year.Number -Name 'Normative year 5000'
Assert-StageTrue -Condition ($o -lt $f -and $f -le $c) -Name 'Foundation inside year-5000 gates'
Assert-StageTrue -Condition ($m -gt 0) -Name 'Positive first-answer modulus'
Assert-StageEqual -Expected ([System.Numerics.BigInteger]36525) -Actual ($d-$f) -Name 'Exact distant-day offset'

$calculationDays=@(
    [pscustomobject]@{Label='FOUNDATION';Day=$f},
    [pscustomobject]@{Label='DISTANT';Day=$d}
)
$targetDays=@(
    [pscustomobject]@{Label='FOUNDATION';Day=$f},
    [pscustomobject]@{Label='DISTANT';Day=$d}
)
$seals=@(1..10)
Assert-StageEqual -Expected 2 -Actual $calculationDays.Count -Name 'Two calculation days'
Assert-StageEqual -Expected 2 -Actual $targetDays.Count -Name 'Two target days'
Assert-StageEqual -Expected 10 -Actual $seals.Count -Name 'All ten valid seal values'

function Get-Stage38Delta {
    param(
        [System.Numerics.BigInteger]$From,
        [System.Numerics.BigInteger]$To,
        [System.Numerics.BigInteger]$Mod
    )
    return [System.Numerics.BigInteger]((($To-$From)%$Mod+$Mod)%$Mod)
}

$contexts=0;$endpoints=0;$pairs=0;$triples=0;$collisionsCompared=0
$firstCollisions=0;$streamCollisions=0;$curvatureZero=0;$curvatureNonzero=0
$stepParityTrue=0;$stepParityFalse=0
foreach($calc in $calculationDays) {
    foreach($target in $targetDays) {
        $contexts++
        $label=('{0}x{1}' -f $calc.Label,$target.Label)
        $actuals=@{};$wanteds=@{}
        foreach($seal in $seals) {
            # A new mutable production context and a separately executed oracle
            # are created for each (calculation, target, seal) sample.
            $ctx=Invoke-CalendarDateSpaghetti -CalculationDay $calc.Day -TargetDay $target.Day
            $got=Get-Discovery13AnswerStreamFromContext -Context $ctx -QueriedBowlId 1 -Seal $seal
            $want=Get-NormAnswerStream -SauceResult (Invoke-NormSauce $calc.Day $target.Day) -QueriedBowlId 1 -Seal $seal
            $tag=('{0} seal={1}' -f $label,$seal)
            Assert-StageEqual -Expected $want.First -Actual $got.First -Name "First $tag"
            Assert-StageEqual -Expected $want.Step -Actual $got.Step -Name "Step $tag"
            Assert-StageTrue -Condition ($got.First -ge 1 -and $got.First -le $m) -Name "First domain $tag"
            Assert-StageTrue -Condition ($got.Step -eq -1 -or $got.Step -eq 1) -Name "Step sign $tag"
            Assert-StageEqual -Expected 58 -Actual $ctx.legacyOrderMemoryWriteCount -Name "Legacy writes $tag"
            Assert-StageEqual -Expected 1 -Actual $ctx.patch12InvocationCount -Name "Patch12 calls $tag"
            $actuals[$seal]=$got
            $wanteds[$seal]=$want
            $endpoints++
        }

        $gotStreamCollisions=0;$wantStreamCollisions=0
        foreach($i in @(1..9)) {
            foreach($j in @(($i+1)..10)) {
                $p=$actuals[$i];$q=$actuals[$j]
                $u=$wanteds[$i];$v=$wanteds[$j]
                $gotDelta=Get-Stage38Delta -From ([System.Numerics.BigInteger]$p.First) -To ([System.Numerics.BigInteger]$q.First) -Mod $m
                $wantDelta=Get-Stage38Delta -From ([System.Numerics.BigInteger]$u.First) -To ([System.Numerics.BigInteger]$v.First) -Mod $m
                Assert-StageEqual -Expected $wantDelta -Actual $gotDelta -Name "Pair First $label $i-$j"
                Assert-StageEqual -Expected ($u.Step -ne $v.Step) -Actual ($p.Step -ne $q.Step) -Name "Pair Step flip $label $i-$j"
                if($p.First -eq $q.First) { $firstCollisions++ }
                if(($p.First -eq $q.First) -and ($p.Step -eq $q.Step)) { $gotStreamCollisions++ }
                if(($u.First -eq $v.First) -and ($u.Step -eq $v.Step)) { $wantStreamCollisions++ }
                $pairs++
            }
        }
        Assert-StageEqual -Expected $wantStreamCollisions -Actual $gotStreamCollisions -Name "Full-stream collision count $label"
        $streamCollisions += $gotStreamCollisions
        $collisionsCompared++

        foreach($i in @(1..8)) {
            $p=$actuals[$i];$q=$actuals[($i+1)];$r=$actuals[($i+2)]
            $u=$wanteds[$i];$v=$wanteds[($i+1)];$w=$wanteds[($i+2)]
            $da=Get-Stage38Delta -From ([System.Numerics.BigInteger]$p.First) -To ([System.Numerics.BigInteger]$q.First) -Mod $m
            $db=Get-Stage38Delta -From ([System.Numerics.BigInteger]$q.First) -To ([System.Numerics.BigInteger]$r.First) -Mod $m
            $du=Get-Stage38Delta -From ([System.Numerics.BigInteger]$u.First) -To ([System.Numerics.BigInteger]$v.First) -Mod $m
            $dv=Get-Stage38Delta -From ([System.Numerics.BigInteger]$v.First) -To ([System.Numerics.BigInteger]$w.First) -Mod $m
            $ka=Get-Stage38Delta -From $da -To $db -Mod $m
            $kw=Get-Stage38Delta -From $du -To $dv -Mod $m
            $pa=[bool](($p.Step -ne $q.Step) -xor ($q.Step -ne $r.Step))
            $pw=[bool](($u.Step -ne $v.Step) -xor ($v.Step -ne $w.Step))
            Assert-StageEqual -Expected $kw -Actual $ka -Name "Consecutive seal curvature $label $i"
            Assert-StageEqual -Expected $pw -Actual $pa -Name "Consecutive Step parity $label $i"
            if($ka -eq [System.Numerics.BigInteger]0) { $curvatureZero++ } else { $curvatureNonzero++ }
            if($pa) { $stepParityTrue++ } else { $stepParityFalse++ }
            $triples++
        }
        Write-Host ('STAGE38_CONTEXT LABEL={0} STREAM_COLLISIONS={1}' -f $label,$gotStreamCollisions)
    }
}
Write-Host "STAGE38_CONTEXTS=$contexts"
Write-Host "STAGE38_ENDPOINTS=$endpoints"
Write-Host "STAGE38_SEAL_VALUES=$($seals.Count)"
Write-Host "STAGE38_ALL_PAIRS=$pairs"
Write-Host "STAGE38_CONSECUTIVE_TRIPLES=$triples"
Write-Host "STAGE38_COLLISION_COUNTS_COMPARED=$collisionsCompared"
Write-Host "STAGE38_FIRST_COLLISIONS=$firstCollisions"
Write-Host "STAGE38_STREAM_COLLISIONS=$streamCollisions"
Write-Host "STAGE38_CURVATURE_ZERO=$curvatureZero"
Write-Host "STAGE38_CURVATURE_NONZERO=$curvatureNonzero"
Write-Host "STAGE38_STEP_PARITY_TRUE=$stepParityTrue"
Write-Host "STAGE38_STEP_PARITY_FALSE=$stepParityFalse"
Write-Host "STAGE38_ASSERTIONS_PASSED=$script:StageTestPassed"
Write-Host "STAGE38_ASSERTIONS_FAILED=$script:StageTestFailed"
if($script:StageTestPassed -ne 680 -or $script:StageTestFailed -ne 0 -or $contexts -ne 4 -or $endpoints -ne 40 -or $pairs -ne 180 -or $triples -ne 32 -or $collisionsCompared -ne 4) {
    Write-Host 'STAGE38_DISCOVERY23=FAIL'
    exit 1
}
Write-Host 'STAGE38_DISCOVERY23=BOUNDED_RESEARCH_ONLY'
exit 0
