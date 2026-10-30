Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')
function Get-Signature24 {
    param([AllowNull()]$Values)
    if ($null -eq $Values) { return '<NULL>' }
    return (($Values | ForEach-Object { [string]$_ }) -join ',')
}
$meta = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')
Assert-StageTrue -Condition ($meta -match '(?m)^CURRENT_STAGE=(24|25)\s*$') -Name 'Stage24 opened'
$preSeal = ($meta -match '(?m)^LAST_COMPLETED_STAGE=23\s*$') -and ($meta -match '(?m)^STAGE24_RUNTIME_VERIFICATION=AWAITING\s*$')
$postSeal = ($meta -match '(?m)^LAST_COMPLETED_STAGE=24\s*$') -and ($meta -match '(?m)^STAGE24_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED\s*$')
Assert-StageTrue -Condition ($preSeal -or $postSeal) -Name 'Stage24 metadata has an awaiting or a Native-sealed pair'
Assert-StageTrue -Condition ($meta -match '(?m)^STAGE23_RUNTIME_VERIFICATION=GREEN_CONFIRMED\s*$') -Name 'Stage23 seal still intact'
$fixture=[int[]](4,5,2,3,6,1); $correct=[int[]](4,3,6,5,2,1); $numerical=[int[]](2,3,4,5,6,1)
$foundationRed=0
for ($id=1;$id -le 6;$id++) {
    $old=oldNextBowlFixedName -QueriedBowlId $id
    $pos=[Array]::IndexOf($fixture,$id)
    $actualCorrect=[int]$fixture[($pos+1)%6]
    Assert-StageEqual -Expected $numerical[$id-1] -Actual $old -Name "Foundation numeric $id"
    Assert-StageEqual -Expected $correct[$id-1] -Actual $actualCorrect -Name "Foundation oracle $id"
    if ($old -ne $actualCorrect) { $foundationRed++ }
}
Assert-StageEqual -Expected 3 -Actual $foundationRed -Name 'Foundation RED 3/6'
$red=0;$match=0;$wrapRed=0
for ($rank=1;$rank -le 720;$rank++) {
    $order=Get-NormPermutationUnrank1 -Rank1 ([System.Numerics.BigInteger]$rank) -ItemsAscending ([int[]](1,2,3,4,5,6))
    for ($id=1;$id -le 6;$id++) {
        $old=oldNextBowlFixedName -QueriedBowlId $id
        $position=[Array]::IndexOf($order,$id)
        $right=[int]$order[($position+1)%6]
        if ($old -eq $right) { $match++ }
        else { $red++; if ($position -eq 5) { $wrapRed++ } }
    }
}
Assert-StageEqual -Expected 4320 -Actual ($red+$match) -Name '720 x 6 cases'
Assert-StageEqual -Expected 3456 -Actual $red -Name 'EXPECTED_RED count'
Assert-StageEqual -Expected 864 -Actual $match -Name 'Incidental match count'
Assert-StageEqual -Expected 576 -Actual $wrapRed -Name 'Wrap mismatch count'
Assert-StageEqual -Expected 1 -Actual (oldNextBowlFixedName -QueriedBowlId 6) -Name 'Numeric wrap'
$invalid=@(-1,0,7,42,1.5,'2',$null);$reject=0
foreach($bad in $invalid) { try {[void](oldNextBowlFixedName -QueriedBowlId $bad)} catch {$reject++} }
Assert-StageEqual -Expected $invalid.Count -Actual $reject -Name 'All invalid IDs rejected'
$f=Get-NormFoundationDay
$ctx=Invoke-CalendarDateSpaghetti -CalculationDay $f -TargetDay ($f+3)
$expectedStatus = if ($meta -match '(?m)^CURRENT_STAGE=25\s*$') { 'PATCH12_COMPLETE' } else { 'DISCOVERY12_EXPECTED_RED' }
Assert-StageEqual -Expected $expectedStatus -Actual $ctx.status -Name 'Real production route'
Assert-StageEqual -Expected 58 -Actual $ctx.legacyOrderMemoryWriteCount -Name '46+12 memory writes'
Assert-StageEqual -Expected 46 -Actual $ctx.patch11CapturedAtWrite -Name 'Correct latch capture'
Assert-StageEqual -Expected 1 -Actual $ctx.patch11InvocationCount -Name 'Patch11 once'
Assert-StageEqual -Expected 1 -Actual $ctx.discovery12InvocationCount -Name 'Discovery12 once'
Assert-StageEqual -Expected 1 -Actual $ctx.discovery12QueriedBowlId -Name 'Query ID one'
Assert-StageEqual -Expected 2 -Actual $ctx.discovery12ProductionResult -Name 'Production returns historical numeric two'
Assert-StageEqual -Expected 2 -Actual $ctx.discovery12OldNumericNext -Name 'Wrong result logged'
Assert-StageEqual -Expected 'HISTORICAL_NUMERIC_SUCCESSOR_EXPECTED_RED' -Actual $ctx.discovery12Status -Name 'Historical RED status'
Assert-StageEqual -Expected (Get-Signature24 $ctx.orderAt46Latch) -Actual (Get-Signature24 $ctx.discovery12OrderAt46Snapshot) -Name 'Saved latch witness'
Assert-StageTrue -Condition (-not [object]::ReferenceEquals($ctx.orderAt46Latch,$ctx.discovery12OrderAt46Snapshot)) -Name 'No latch alias'
Assert-StageEqual -Expected 47 -Actual $ctx.patch09InvocationCount -Name 'Patch09 regression'
Assert-StageEqual -Expected 47 -Actual $ctx.patch10InvocationCount -Name 'Patch10 regression'
$normNext=Get-NormNextBowlInDrop46Order -SauceResult ([pscustomobject]@{OrderAtDrop46=$ctx.orderAt46Latch}) -QueriedBowlId 1
Assert-StageEqual -Expected ([int]$ctx.orderAt46Latch[([Array]::IndexOf($ctx.orderAt46Latch,1)+1)%6]) -Actual $normNext -Name 'Oracle only used in test'
$invalidCaller=0
foreach($bad in @(0,7,'2')) {try {[void](Invoke-Discovery12NumericSuccessor -Context $ctx -QueriedBowlId $bad)} catch {$invalidCaller++}}
Assert-StageEqual -Expected 3 -Actual $invalidCaller -Name 'Invalid caller queries fail'
Assert-StageEqual -Expected 1 -Actual $ctx.discovery12InvocationCount -Name 'Invalid calls cannot mutate context'
$unchanged=Get-Signature24 $ctx.orderAt46Latch
$ctx.discovery12OrderAt46Snapshot[0]=99
Assert-StageEqual -Expected $unchanged -Actual (Get-Signature24 $ctx.orderAt46Latch) -Name 'Snapshot isolation'
$clean=New-BaseMonsterContext -CalculationDay $f -TargetDay ($f+3)
Assert-StageTrue -Condition ($null -eq $clean.discovery12OrderAt46Snapshot) -Name 'No witness leak'
Assert-StageTrue -Condition ($null -eq $clean.discovery12OldNumericNext) -Name 'No next-value leak'
Assert-StageEqual -Expected 0 -Actual $clean.discovery12InvocationCount -Name 'No counter leak'
$again=Invoke-CalendarDateSpaghetti -CalculationDay $f -TargetDay ($f+3)
Assert-StageEqual -Expected 1 -Actual $again.discovery12InvocationCount -Name 'Independent second invocation'
Assert-StageEqual -Expected $unchanged -Actual (Get-Signature24 $again.orderAt46Latch) -Name 'Deterministic latch'
Assert-StageEqual -Expected 58 -Actual $again.legacyOrderMemoryWriteCount -Name 'Second full 58-write path'
$monsterText=Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/MonsterSkeleton.ps1')
$d12Text=Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Discovery12.ps1')
$patch12Text=Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Patch12.ps1')
if ($meta -match '(?m)^CURRENT_STAGE=25\s*
Assert-StageTrue -Condition (($monsterText+$d12Text) -notmatch 'Invoke-NormSauce|Get-NormNextBowlInDrop46Order|biasedLegacyPick') -Name 'No oracle or later patch in production'
Write-Host 'STAGE24_CASES=4320'
Write-Host "STAGE24_EXPECTED_RED=$red"
Write-Host "STAGE24_MATCHES=$match"
Write-Host "STAGE24_WRAP_RED=$wrapRed"
$ok=Complete-StageTestRun
if (-not $ok) {exit 1}
Write-Host 'STAGE24_RESULT=PASS'
exit 0
) {
    Assert-StageTrue -Condition (($monsterText -match 'Invoke-Discovery11OverwritableOrderMemory[\s\S]*Invoke-Patch12PositionalSuccessor') -and ($patch12Text -match 'Invoke-Discovery12NumericSuccessor')) -Name 'Stage25 production delegates numeric scar via Patch12'
} else {
    Assert-StageTrue -Condition ($monsterText -match 'Invoke-Discovery11OverwritableOrderMemory[\s\S]*Invoke-Discovery12NumericSuccessor') -Name 'Stage24 production direct numeric scar'
}
Assert-StageTrue -Condition (($monsterText+$d12Text) -notmatch 'Invoke-NormSauce|Get-NormNextBowlInDrop46Order|biasedLegacyPick') -Name 'No oracle or later patch in production'
Write-Host 'STAGE24_CASES=4320'
Write-Host "STAGE24_EXPECTED_RED=$red"
Write-Host "STAGE24_MATCHES=$match"
Write-Host "STAGE24_WRAP_RED=$wrapRed"
$ok=Complete-StageTestRun
if (-not $ok) {exit 1}
Write-Host 'STAGE24_RESULT=PASS'
exit 0
