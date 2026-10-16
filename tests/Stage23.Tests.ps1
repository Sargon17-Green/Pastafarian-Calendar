Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')

function Get-Stage23Signature {
    param([AllowNull()]$Values)
    if ($null -eq $Values) { return '<NULL>' }
    return (($Values | ForEach-Object { [string]$_ }) -join ',')
}

$metadata = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'DEVELOPMENT_STAGE.md')
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_STAGE=23\s*$') -Name 'Stage 23 metadata'
Assert-StageTrue -Condition ($metadata -match '(?m)^CURRENT_KIND=PATCH\s*$') -Name 'Patch 11 kind'
Assert-StageTrue -Condition ($metadata -match '(?m)^LAST_COMPLETED_STAGE=22\s*$') -Name 'Stage 22 sealed as predecessor'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE22_RUNTIME_VERIFICATION=EXPECTED_RED_CONFIRMED\s*$') -Name 'Historical Stage 22 RED preserved'
Assert-StageTrue -Condition ($metadata -match '(?m)^STAGE23_RUNTIME_VERIFICATION=AWAITING\s*$') -Name 'Stage 23 not prematurely sealed'

$foundation = Get-NormFoundationDay
$target = $foundation + 3
$ctx = Invoke-CalendarDateSpaghetti -CalculationDay $foundation -TargetDay $target
$expected = Get-NormBowlOrderFromDrop -DropValue ([System.Numerics.BigInteger]$ctx.legacyVisibleDropTable[46])
$expectedSignature = Get-Stage23Signature $expected
$corrected = Get-Patch11OrderAt46 -Context $ctx
$legacy = Get-Discovery11LegacyQueriedOrder -Context $ctx

Assert-StageEqual 'PATCH11_COMPLETE' $ctx.status 'Patch 11 production dispatch'
Assert-StageEqual 'DROP46_ORDER_LATCH_ACTIVE' $ctx.patch11Status 'Patch 11 active'
Assert-StageEqual 1 $ctx.patch11InvocationCount 'One drop-46 latch'
Assert-StageEqual 46 $ctx.patch11CapturedAtWrite 'Captured exactly at write 46'
Assert-StageEqual 58 $ctx.legacyOrderMemoryWriteCount 'All historical writes retained'
Assert-StageEqual 'stir' $ctx.legacyOrderMemoryLastSource.kind 'Historical final source remains stir'
Assert-StageEqual 12 $ctx.legacyOrderMemoryLastSource.index 'Historical final source is stir 12'
Assert-StageEqual $expectedSignature (Get-Stage23Signature $ctx.orderAt46Latch) 'Latched order matches independent normative unranking'
Assert-StageEqual $expectedSignature (Get-Stage23Signature $corrected) 'Corrected semantic query matches normative unranking'
Assert-StageEqual $expectedSignature (Get-Stage23Signature $ctx.patch11CorrectedOrder) 'Production uses corrected semantic query'
Assert-StageEqual (Get-Stage23Signature $legacy) (Get-Stage23Signature $ctx.patch11LegacyQueriedOrder) 'Old wrong query physically preserved'
Assert-StageEqual (Get-Stage23Signature $legacy) (Get-Stage23Signature $ctx.legacyQueriedOrder) 'Historical production query still overwritten'
$red = 0
foreach ($pos in @(1,2,6)) {
    if ([int]$legacy[$pos-1] -ne [int]$expected[$pos-1]) { $red++ }
}
Assert-StageEqual 3 $red 'Exactly three historical red positions remain'
Assert-StageEqual 47 $ctx.patch09InvocationCount '46 bowl rounds plus preserved production probe'
Assert-StageEqual 47 $ctx.patch10InvocationCount '46 snapshot rounds plus preserved production probe'
Assert-StageEqual 1 $ctx.discovery11InvocationCount 'Full historical pass retained'
Assert-StageEqual 'SNAPSHOT_BOWL_UPDATE_PATCH_ACTIVE' $ctx.patch10Status 'Predecessor Patch 10 remains active'
Assert-StageTrue -Condition (-not [object]::ReferenceEquals($ctx.orderAt46Latch,$ctx.legacyOverwritableOrderMemory)) -Name 'Latch does not alias general memory'
Assert-StageTrue -Condition (-not [object]::ReferenceEquals($corrected,$ctx.orderAt46Latch)) -Name 'Query result does not alias latch'
$corrected[0] = 99
Assert-StageEqual $expectedSignature (Get-Stage23Signature $ctx.orderAt46Latch) 'Returned result mutation does not change latch'
$ctx.legacyOverwritableOrderMemory[0] = 98
Assert-StageEqual $expectedSignature (Get-Stage23Signature $ctx.orderAt46Latch) 'Legacy memory mutation does not change latch'

$clean = New-BaseMonsterContext -CalculationDay $foundation -TargetDay $target
Assert-StageTrue -Condition ($null -eq $clean.orderAt46Latch) -Name 'No cross-invocation latch leak'
Assert-StageEqual 0 $clean.patch11InvocationCount 'No cross-invocation latch count leak'
Assert-StageTrue -Condition ($null -eq $clean.patch11LegacyQueriedOrder) -Name 'No cross-invocation legacy query leak'

$again = Invoke-CalendarDateSpaghetti -CalculationDay $foundation -TargetDay $target
Assert-StageEqual $expectedSignature (Get-Stage23Signature $again.patch11CorrectedOrder) 'Deterministic second invocation'
Assert-StageEqual 58 $again.legacyOrderMemoryWriteCount 'Deterministic historical write count'

$monsterText = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/MonsterSkeleton.ps1')
$d11Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Discovery11.ps1')
$p11Text = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/Patch11.ps1')
Assert-StageTrue -Condition ($d11Text -match 'Invoke-Patch11OrderAt46Latch') -Name 'Latch is physically captured in drop path'
Assert-StageTrue -Condition ($p11Text -match 'Get-Discovery11LegacyQueriedOrder') -Name 'Patch queries the old scar first'
Assert-StageTrue -Condition ($monsterText -match 'Get-Patch11OrderAt46') -Name 'Production route queries the corrected latch'
Assert-StageTrue -Condition (($monsterText+$d11Text+$p11Text) -notmatch 'biasedLegacyPick|queriedNextBowl|Patch12|PATCH12') -Name 'Stage 24 code not introduced'
Assert-StageTrue -Condition (($monsterText+$d11Text+$p11Text) -notmatch 'Get-NormBowlOrderFromDrop|Get-NormCalendarDate') -Name 'Production independent from test oracle'

Write-Host 'PATCH11_LATCH_WRITE_INDEX=46'
Write-Host 'PATCH11_LEGACY_MEMORY_WRITES=58'
Write-Host 'PATCH11_EXPECTED_RED_PRESERVED=3'
Write-Host 'PATCH11_NORMATIVE_GREEN=6'
Write-Host 'PATCH11_PATCH12=ABSENT'
Write-Host 'STAGE23_REPOSITORY_STATE=GREEN'
$ok = Complete-StageTestRun
if (-not $ok) { exit 1 }
Write-Host 'STAGE23_RESULT=PASS'
exit 0
