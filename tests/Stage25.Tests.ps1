Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')
$meta=Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')
Assert-StageTrue -Condition ($meta -match '(?m)^CURRENT_STAGE=(25|26)\s*$') -Name 'Stage25 is open'
Assert-StageTrue -Condition ($meta -match '(?m)^LAST_COMPLETED_STAGE=(24|25|26)\s*$') -Name 'Stage24 remains sealed through Stage25'
Assert-StageTrue -Condition ($meta -match '(?m)^STAGE24_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED\s*$') -Name 'Stage24 RED is sealed'
$awaiting = ($meta -match '(?m)^LAST_COMPLETED_STAGE=24\s*$') -and ($meta -match '(?m)^STAGE25_RUNTIME_VERIFICATION=AWAITING\s*$')
$sealed = ($meta -match '(?m)^LAST_COMPLETED_STAGE=25\s*$') -and ($meta -match '(?m)^STAGE25_RUNTIME_VERIFICATION=GREEN_CONFIRMED\s*$')
Assert-StageTrue -Condition ($awaiting -or $sealed) -Name 'Stage25 metadata must be consistently awaiting or Native-sealed'
$fixture=[int[]](4,5,2,3,6,1)
$old=[int[]](2,3,4,5,6,1)
$right=[int[]](4,3,6,5,2,1)
$red=0
for($id=1;$id -le 6;$id++){
    $numeric=oldNextBowlFixedName -QueriedBowlId $id
    $correct=Get-Patch12PositionalNext -Order $fixture -QueriedBowlId $id
    Assert-StageEqual -Expected $old[$id-1] -Actual $numeric -Name "Foundation legacy $id"
    Assert-StageEqual -Expected $right[$id-1] -Actual $correct -Name "Foundation patched $id"
    if($numeric -ne $correct){$red++}
}
Assert-StageEqual -Expected 3 -Actual $red -Name 'Foundation: 3 historic mismatches'
$cases=0;$green=0;$historicalRed=0;$wrapped=0
for($rank=1;$rank -le 720;$rank++){
    $order=Get-NormPermutationUnrank1 -Rank1 ([System.Numerics.BigInteger]$rank) -ItemsAscending ([int[]](1,2,3,4,5,6))
    for($id=1;$id -le 6;$id++){
        $pos=[Array]::IndexOf($order,$id)
        $expected=[int]$order[($pos+1)%6]
        $actual=Get-Patch12PositionalNext -Order $order -QueriedBowlId $id
        if($expected -eq $actual){$green++}
        if((oldNextBowlFixedName -QueriedBowlId $id) -ne $actual){$historicalRed++}
        if($pos -eq 5 -and $actual -eq [int]$order[0]){$wrapped++}
        $cases++
    }
}
Assert-StageEqual -Expected 4320 -Actual $cases -Name '720x6 cases'
Assert-StageEqual -Expected 4320 -Actual $green -Name 'Every positional next correct'
Assert-StageEqual -Expected 3456 -Actual $historicalRed -Name 'Historical numeric defect remains observable'
Assert-StageEqual -Expected 720 -Actual $wrapped -Name 'All wraparound cases'
$badIds=@(-1,0,7,42,1.5,'2',$null);$badCount=0
foreach($bad in $badIds){try{[void](Get-Patch12PositionalNext -Order $fixture -QueriedBowlId $bad)}catch{$badCount++}}
Assert-StageEqual -Expected 7 -Actual $badCount -Name 'Invalid IDs rejected'
$badOrders=0
try{[void](Get-Patch12PositionalNext -Order ([int[]](1,1,2,3,4,5)) -QueriedBowlId 1)}catch{$badOrders++}
try{[void](Get-Patch12PositionalNext -Order ([int[]](1,2,3,4,5,7)) -QueriedBowlId 1)}catch{$badOrders++}
try{[void](Get-Patch12PositionalNext -Order ([int[]](1,2,3,4,5)) -QueriedBowlId 1)}catch{$badOrders++}
Assert-StageEqual -Expected 3 -Actual $badOrders -Name 'Invalid permutations rejected'
$f=Get-NormFoundationDay
$ctx=Invoke-CalendarDateSpaghetti -CalculationDay $f -TargetDay ($f+3)
Assert-StageEqual -Expected 'PATCH12_COMPLETE' -Actual $ctx.status -Name 'Real production GREEN'
Assert-StageEqual -Expected 58 -Actual $ctx.legacyOrderMemoryWriteCount -Name 'Full historical 46+12 writes'
Assert-StageEqual -Expected 46 -Actual $ctx.patch11CapturedAtWrite -Name 'Drop46 latch'
Assert-StageEqual -Expected 1 -Actual $ctx.discovery12InvocationCount -Name 'Legacy consumer called once'
Assert-StageEqual -Expected 1 -Actual $ctx.patch12InvocationCount -Name 'Patch12 called once'
Assert-StageEqual -Expected 2 -Actual $ctx.discovery12ProductionResult -Name 'Legacy numeric production result'
Assert-StageEqual -Expected 2 -Actual $ctx.patch12LegacyNumericNext -Name 'Numeric scar separately preserved'
Assert-StageEqual -Expected 'HISTORICAL_NUMERIC_SUCCESSOR_EXPECTED_RED' -Actual $ctx.discovery12Status -Name 'Historical RED status unchanged'
Assert-StageEqual -Expected 'POSITIONAL_SUCCESSOR_PATCH_ACTIVE' -Actual $ctx.patch12Status -Name 'Patch active'
$norm=Get-NormNextBowlInDrop46Order -SauceResult ([pscustomobject]@{OrderAtDrop46=$ctx.orderAt46Latch}) -QueriedBowlId 1
Assert-StageEqual -Expected $norm -Actual $ctx.patch12ProductionResult -Name 'Corrected production matches test oracle'
Assert-StageEqual -Expected ([Array]::IndexOf($ctx.orderAt46Latch,1)) -Actual $ctx.patch12Position0 -Name 'Correct position'
Assert-StageTrue -Condition (-not [object]::ReferenceEquals($ctx.orderAt46Latch,$ctx.patch12OrderSnapshot)) -Name 'Snapshot not aliased'
$original=$ctx.orderAt46Latch -join ','
$ctx.patch12OrderSnapshot[0]=99
Assert-StageEqual -Expected $original -Actual ($ctx.orderAt46Latch -join ',') -Name 'Snapshot isolation'
$clean=New-BaseMonsterContext -CalculationDay $f -TargetDay ($f+3)
Assert-StageEqual -Expected 0 -Actual $clean.patch12InvocationCount -Name 'No invocation count leakage'
Assert-StageTrue -Condition ($null -eq $clean.patch12OrderSnapshot -and $null -eq $clean.patch12CorrectedNext) -Name 'No state leakage'
$rejected=0
foreach($bad in @(0,7,'2')){try{[void](Invoke-Patch12PositionalSuccessor -Context $clean -QueriedBowlId $bad)}catch{$rejected++}}
Assert-StageEqual -Expected 3 -Actual $rejected -Name 'Invalid production invocations rejected'
Assert-StageEqual -Expected 0 -Actual $clean.discovery12InvocationCount -Name 'Invalid calls cannot mutate legacy count'
$again=Invoke-CalendarDateSpaghetti -CalculationDay $f -TargetDay ($f+3)
Assert-StageEqual -Expected $ctx.patch12ProductionResult -Actual $again.patch12ProductionResult -Name 'Deterministic second invocation'
Assert-StageEqual -Expected 1 -Actual $again.patch12InvocationCount -Name 'Second invocation once'
Assert-StageEqual -Expected 58 -Actual $again.legacyOrderMemoryWriteCount -Name 'Second invocation 58 writes'
$p=Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Patch12.ps1')
$m=Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/MonsterSkeleton.ps1')
Assert-StageTrue -Condition ($p -match 'Invoke-Discovery12NumericSuccessor' -and $m -match 'Invoke-Patch12PositionalSuccessor') -Name 'Raw consumer then Patch12 production'
Assert-StageTrue -Condition (($p+$m) -notmatch 'Get-NormNextBowlInDrop46Order|Invoke-NormSauce|biasedLegacyPick') -Name 'Oracle independent; Stage26 absent'
Write-Host "STAGE25_CASES=$cases"
Write-Host "STAGE25_CORRECT=$green"
Write-Host "STAGE25_HISTORICAL_RED=$historicalRed"
Write-Host "STAGE25_WRAPAROUNDS=$wrapped"
$ok=Complete-StageTestRun
if(-not $ok){exit 1}
Write-Host 'STAGE25_RESULT=PASS'
exit 0
