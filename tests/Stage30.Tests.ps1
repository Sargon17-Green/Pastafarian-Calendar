Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')
$metadata = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')
Assert-StageTrue -Condition ($metadata -match '(?m)^LAST_COMPLETED_STAGE=(29|30)\s*$') -Name 'Stage29 predecessor remains sealed'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE29_RUNTIME_VERIFICATION=GREEN_CONFIRMED\s*$') -Name 'Stage29 native green retained'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE28_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -Name 'Stage28 evidence-only status retained'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE26_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED\s*$') -Name 'Stage26 scar retained'

# Independent miniature oracle: iterative cyclic W successor (never the production O(1) jump).
$toyM = 7
$space = $toyM * $toyM
$histograms = @{}
$rejectedByCase = @{}
$totalStates = 0
foreach ($n in @(8,9,48,49)) {
    foreach ($step in @(-1,1)) {
        $counts = @{}
        for ($rank=1; $rank -le $n; $rank++) { $counts[$rank] = 0 }
        $rejectedStates = 0
        $limit = [int]([math]::Floor($space / $n) * $n)
        for ($first=1; $first -le $toyM; $first++) {
            $second = 1 + (($first - 1 + $step + $toyM) % $toyM)
            $accepted = $first + $toyM * ($second - 1)
            $skipped = 0
            while ($accepted -gt $limit) {
                $accepted = 1 + (($accepted - 1 + $step + $space) % $space)
                $skipped++
                if ($skipped -gt $space) { throw 'Unbounded miniature oracle traversal' }
            }
            if ($skipped -gt 0) { $rejectedStates++ }
            $rank = 1 + (($accepted - 1) % $n)
            Assert-StageTrue -Condition ($rank -ge 1 -and $rank -le $n) -Name "Toy domain N=$n S=$step F=$first"
            $counts[$rank]++
            $totalStates++
        }
        $sum = 0
        foreach ($value in $counts.Values) { $sum += [int]$value }
        Assert-StageEqual -Expected 7 -Actual $sum -Name "Toy state conservation N=$n S=$step"
        $histograms["$n,$step"] = $counts
        $rejectedByCase["$n,$step"] = $rejectedStates
    }
}
Assert-StageEqual -Expected 56 -Actual $totalStates -Name 'Bounded 56-state exhaustive model'
Assert-StageEqual -Expected 6 -Actual $histograms['8,1'][8] -Name 'Positive successor heavy rank 8'
Assert-StageEqual -Expected 1 -Actual $histograms['8,1'][7] -Name 'Positive successor wrap rank 7'
Assert-StageEqual -Expected 6 -Actual $histograms['8,-1'][2] -Name 'Negative successor heavy rank 2'
Assert-StageEqual -Expected 1 -Actual $histograms['8,-1'][3] -Name 'Negative successor wrap rank 3'
foreach ($rank in @(1,4,5,6)) {
    Assert-StageEqual -Expected 0 -Actual ($histograms['8,1'][$rank] + $histograms['8,-1'][$rank]) -Name "Mixed stream forbidden rank $rank"
}
Assert-StageEqual -Expected 1 -Actual $rejectedByCase['9,1'] -Name 'Actual iterative rejection at toy N=9 Step=+1'
$numerator = 0
for ($rank=1; $rank -le 8; $rank++) {
    $count = $histograms['8,1'][$rank] + $histograms['8,-1'][$rank]
    $numerator += [math]::Abs(8 * $count - 14)
}
Assert-StageEqual -Expected 136 -Actual $numerator -Name 'Mixed TVD numerator 136/224=17/28'

# Non-toy implementation check against analytic formulas, not against NormativeScroll.
$m = [System.Numerics.BigInteger]$script:Discovery01M
$nWide = [System.Numerics.BigInteger]($m + 1)
$analyticCases = 0
foreach ($first in @([System.Numerics.BigInteger]1,[System.Numerics.BigInteger]2,($m-1),$m)) {
    foreach ($step in @(-1,1)) {
        $actual = Get-Patch14WideAcceptedRank -First $first -Step $step -N $nWide
        $expectedRank = if ($step -eq 1) {
            if ($first -eq $m) { $m } else { $nWide }
        } else {
            if ($first -eq 1) { [System.Numerics.BigInteger]3 } else { [System.Numerics.BigInteger]2 }
        }
        Assert-StageEqual -Expected $expectedRank -Actual $actual.Rank -Name "Real M analytic rank F=$first S=$step"
        Assert-StageEqual -Expected ([System.Numerics.BigInteger]::Zero) -Actual $actual.RejectedCompositeWords -Name "Real M N=M+1 no rejection F=$first S=$step"
        $analyticCases++
    }
}
Assert-StageEqual -Expected 8 -Actual $analyticCases -Name 'Eight real M analytic witnesses'
Write-Host "STAGE30_TOY_EXHAUSTIVE_STATES=$totalStates"
Write-Host "STAGE30_REAL_M_ANALYTIC_CASES=$analyticCases"
Write-Host 'STAGE30_TOY_BALANCED_TVD=17/28'
Write-Host "STAGE30_ASSERTIONS_PASSED=$script:StageTestPassed"
Write-Host "STAGE30_ASSERTIONS_FAILED=$script:StageTestFailed"
if ($script:StageTestFailed -ne 0) { Write-Host 'STAGE30_DISCOVERY15=FAIL'; exit 1 }
Write-Host 'STAGE30_DISCOVERY15=EVIDENCE_ONLY'
exit 0
