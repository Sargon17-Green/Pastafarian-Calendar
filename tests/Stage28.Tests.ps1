Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')
$meta = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')
Assert-StageTrue -Condition ($meta -match '(?m)^LAST_COMPLETED_STAGE=(27|28|29|30|31|32|33)\s*$') -Name 'Stage27 predecessor sealed'
Assert-StageTrue -Condition ($meta -match '(?m)^STAGE27_RUNTIME_VERIFICATION=GREEN_CONFIRMED\s*$') -Name 'Stage27 Native seal retained'
Assert-StageTrue -Condition ($meta -match '(?m)^STAGE28_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED\s*$') -Name 'Stage28 evidence-only Native seal retained'
$m = [System.Numerics.BigInteger](Get-NormM)
$space = [System.Numerics.BigInteger]($m * $m)
$cases = 0
$guardFailures = 0
$rejectionCases = 0
foreach ($n in @(($m+1),($m+2),($space-1),$space)) {
    $n = [System.Numerics.BigInteger]$n
    $limit = [System.Numerics.BigInteger](($space / $n) * $n)
    foreach ($first in @([System.Numerics.BigInteger]1,($m-1),$m)) {
        $first = [System.Numerics.BigInteger]$first
        foreach ($step in @(-1,1)) {
            $second = [System.Numerics.BigInteger](1 + (($first - 1 + $step + $m) % $m))
            $word = [System.Numerics.BigInteger](1 + ($first - 1) + $m * ($second - 1))
            $accepted = $word
            if ($word -gt $limit) {
                $rejectionCases++
                if ($step -eq -1) { $accepted = $limit }
                else { $accepted = [System.Numerics.BigInteger]::One }
            }
            $closedFormRank = [System.Numerics.BigInteger](1 + (($accepted - 1) % $n))
            $actual = Get-NormChooseRankWide -Stream ([pscustomobject]@{First=$first;Step=$step}) -N $n
            Assert-StageEqual -Expected $closedFormRank -Actual $actual -Name "Wide closed form N=$n F=$first S=$step"
            $thrown = $false
            try { [void](Get-Patch13AcceptedRank -First $first -Step $step -N $n) }
            catch { $thrown = $true }
            Assert-StageTrue -Condition $thrown -Name "Short path rejects wide N=$n F=$first S=$step"
            if ($thrown) { $guardFailures++ }
            $cases++
        }
    }
}
Assert-StageEqual -Expected 24 -Actual $cases -Name 'Twenty-four wide cases covered'
Assert-StageEqual -Expected 24 -Actual $guardFailures -Name 'All existing short-domain guards observed'
Assert-StageTrue -Condition ($rejectionCases -gt 0) -Name 'Wide reject/advance branch covered'

# Independent exhaustive toy experiment: independent digits are uniform after rejection.
$counts = @{}
for ($r = 1; $r -le 8; $r++) { $counts[$r] = 0 }
$reject = 0
for ($d0 = 0; $d0 -lt 7; $d0++) {
    for ($d1 = 0; $d1 -lt 7; $d1++) {
        $w = 1 + $d0 + 7*$d1
        if ($w -gt 48) { $reject++; continue }
        $rank = 1 + (($w - 1) % 8)
        $counts[$rank]++
    }
}
Assert-StageEqual -Expected 1 -Actual $reject -Name 'Toy independent: one rejected state'
for ($rank = 1; $rank -le 8; $rank++) {
    Assert-StageEqual -Expected 6 -Actual $counts[$rank] -Name "Toy independent: rank $rank has six preimages"
}
# Same domain, but successive +1 stream words rather than independent words.
$streamCounts = @{}
for ($rank = 1; $rank -le 8; $rank++) { $streamCounts[$rank] = 0 }
for ($first = 1; $first -le 7; $first++) {
    $second = 1 + ($first % 7)
    $w = $first + 7*($second-1)
    $rank = 1 + (($w - 1) % 8)
    $streamCounts[$rank]++
}
Assert-StageEqual -Expected 6 -Actual $streamCounts[8] -Name 'Toy actual successor gives six rank-8 outcomes'
Assert-StageEqual -Expected 1 -Actual $streamCounts[7] -Name 'Toy actual successor gives one rank-7 outcome'
for ($rank = 1; $rank -le 6; $rank++) {
    Assert-StageEqual -Expected 0 -Actual $streamCounts[$rank] -Name "Toy successor excludes rank $rank"
}
Write-Host "STAGE28_WIDE_CASES=$cases"
Write-Host "STAGE28_LEGACY_GUARD_CASES=$guardFailures"
Write-Host "STAGE28_REJECTION_CASES=$rejectionCases"
Write-Host "STAGE28_ASSERTIONS_PASSED=$script:StageTestPassed"
Write-Host "STAGE28_ASSERTIONS_FAILED=$script:StageTestFailed"
if ($script:StageTestFailed -ne 0) { Write-Host 'STAGE28_DISCOVERY_RESULT=FAIL'; exit 1 }
Write-Host 'STAGE28_DISCOVERY_RESULT=EVIDENCE_ONLY'
exit 0
