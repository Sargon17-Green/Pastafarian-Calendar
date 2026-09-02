Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $root 'src/SourceLanguageCatalog.ps1')
. (Join-Path $root 'src/MonsterSkeleton.ps1')
. (Join-Path $root 'oracle/NormativeScroll.ps1')
. (Join-Path $root 'tests/TestHarness.ps1')
$fixtures = Import-PowerShellDataFile (Join-Path $root 'tests/fixtures/stage01-fixtures.psd1')

$mExpected = [System.Numerics.BigInteger]::Parse($fixtures.M)
Assert-StageEqual $mExpected (Get-NormM) 'Eksakto ang M = 2^127 - 1'
Assert-StageEqual ([System.Numerics.BigInteger]::Parse($fixtures.FoundationDay)) (Get-NormFoundationDay) 'Eksakto ang Foundation day'
Assert-StageEqual ([System.Numerics.BigInteger]::Parse($fixtures.TabletsDay)) (Get-NormTabletsDay) 'Eksakto ang Tablets day'
Assert-StageEqual ([System.Numerics.BigInteger]14777149) ((Get-NormTabletsDay) - (Get-NormFoundationDay)) 'Eksakto ang pagitan ng Tablets at Foundation'

foreach ($case in $fixtures.SaveCases) {
    $x = [System.Numerics.BigInteger]::Parse($case.x)
    $expected = [System.Numerics.BigInteger]::Parse($case.expected)
    Assert-StageEqual $expected (Get-NormSave $x) "Tamang SAVE para sa $($case.x)"
}

foreach ($case in $fixtures.DayCountCases) {
    $day = [System.Numerics.BigInteger]::Parse($case.day)
    $expected = [System.Numerics.BigInteger]::Parse($case.expected)
    Assert-StageEqual $expected (Get-NormDayCount $day) "Tamang dayCount para sa $($case.day)"
}

$f = Get-NormFoundationDay
$countsSame = Get-NormWorkCounts $f $f
Assert-StageEqual ([System.Numerics.BigInteger]1) $countsSame.action 'Action count sa Foundation'
Assert-StageEqual ([System.Numerics.BigInteger]1) $countsSame.target 'Target count sa Foundation'
Assert-StageEqual ([System.Numerics.BigInteger]1) $countsSame.distance 'Distance ay isa kapag pareho ang araw'
Assert-StageEqual ([System.Numerics.BigInteger]2) $countsSame.connection 'Connection sa Foundation pair'
Assert-StageEqual 2 $countsSame.direction 'Direction ay dalawa kapag pareho ang araw'

$countsForward = Get-NormWorkCounts $f ($f + 1)
Assert-StageEqual ([System.Numerics.BigInteger]2) $countsForward.distance 'Chronological distance ang ginagamit'
Assert-StageEqual 3 $countsForward.direction 'Forward direction ay tatlo'

Assert-StageSequenceEqual ([int[]](1,2,3,4,5,6)) (Get-NormPermutationUnrank1 1 ([int[]](1,2,3,4,5,6))) 'Unang permutation'
Assert-StageSequenceEqual ([int[]](6,5,4,3,2,1)) (Get-NormPermutationUnrank1 720 ([int[]](1,2,3,4,5,6))) 'Ika-720 permutation'
Assert-StageSequenceEqual ([int[]](1,2,3)) (Get-NormDistinctIndexUnrank 5 3 1) 'Unang distinct-name rank'
Assert-StageSequenceEqual ([int[]](5,4,3)) (Get-NormDistinctIndexUnrank 5 3 60) 'Huling distinct-name rank'

Assert-StageEqual ([System.Numerics.BigInteger]3) (Get-NormBoundedCompositionCount 10 2 4 6) 'Bilang ng maliit na bounded compositions'
Assert-StageSequenceEqual ([int[]](4,6)) (Get-NormBoundedCompositionUnrank 10 2 4 6 1) 'Unang bounded composition'
Assert-StageSequenceEqual ([int[]](5,5)) (Get-NormBoundedCompositionUnrank 10 2 4 6 2) 'Ikalawang bounded composition'
Assert-StageSequenceEqual ([int[]](6,4)) (Get-NormBoundedCompositionUnrank 10 2 4 6 3) 'Ikatlong bounded composition'

[Nullable[int]]$none = $null
[Nullable[int]]$boundary3 = 3
Assert-StageEqual ([System.Numerics.BigInteger]5) (Get-NormCutletPartitionCount 6 2 $none) 'Lahat ng positive compositions para sa maliit na cutlet family'
Assert-StageEqual ([System.Numerics.BigInteger]1) (Get-NormCutletPartitionCount 6 2 $boundary3) 'Boundary-filtered cutlet family'
Assert-StageSequenceEqual ([int[]](3,3)) (Get-NormCutletPartitionUnrank 6 2 $boundary3 1) 'Eksaktong partition na tumatama sa boundary'

Assert-StageEqual ([System.Numerics.BigInteger]1) (Get-NormWeavingCount ([int[]](1,1))) 'Bilang ng weaving para sa 1,1'
Assert-StageSequenceEqual ([int[]](1,2)) (Get-NormWeavingUnrank ([int[]](1,1)) 1) 'Weaving para sa 1,1'
Assert-StageEqual ([System.Numerics.BigInteger]2) (Get-NormWeavingCount ([int[]](2,2))) 'Bilang ng weaving para sa 2,2'
Assert-StageSequenceEqual ([int[]](1,1,2,2)) (Get-NormWeavingUnrank ([int[]](2,2)) 1) 'Unang weaving para sa 2,2'
Assert-StageSequenceEqual ([int[]](1,2,1,2)) (Get-NormWeavingUnrank ([int[]](2,2)) 2) 'Ikalawang weaving para sa 2,2'

$streamForward = [pscustomobject]@{ First = [System.Numerics.BigInteger]1; Step = 1 }
Assert-StageEqual ([System.Numerics.BigInteger]1) (Get-NormChooseRankShort $streamForward 1) 'Short selection para sa N=1'
Assert-StageEqual ([System.Numerics.BigInteger]1) (Get-NormChooseRankShort $streamForward (Get-NormM)) 'Short selection para sa N=M'
$wideN = (Get-NormM) + 1
Assert-StageEqual $wideN (Get-NormChooseRankWide $streamForward $wideN) 'Wide selection para sa N=M+1'

$cutlets = @(Get-CutletCatalog)
$months = @(Get-MonthCatalog)
Assert-StageEqual 17 $cutlets.Count 'May eksaktong 17 cutlet source names'
Assert-StageEqual 47 $months.Count 'May eksaktong 47 month source names'
Assert-StageSequenceEqual ([int[]](1..17)) ([int[]]($cutlets.canonicalIndex)) 'Sunod-sunod ang cutlet canonicalIndex'
Assert-StageSequenceEqual ([int[]](1..47)) ([int[]]($months.canonicalIndex)) 'Sunod-sunod ang month canonicalIndex'
Assert-StageEqual 'Trigo' (Resolve-CutletSourceString 12) 'Filipino source string ng wheat entry'
Assert-StageEqual 'Asin' (Resolve-MonthSourceString 44) 'Filipino source string ng salt entry'

$ctx1 = New-BaseMonsterContext ([System.Numerics.BigInteger]10) ([System.Numerics.BigInteger]20)
$ctx2 = New-BaseMonsterContext ([System.Numerics.BigInteger]10) ([System.Numerics.BigInteger]20)
Assert-StageTrue -Condition (-not [object]::ReferenceEquals($ctx1, $ctx2)) -Name 'Magkahiwalay ang invocation contexts'
$ctx1.semanticCommitted['x'] = [System.Numerics.BigInteger]7
Assert-StageTrue -Condition (-not $ctx2.semanticCommitted.ContainsKey('x')) -Name 'Hindi tumatagas ang semantic state sa ibang invocation'
Add-BaseMetric $ctx1 'probe'
Assert-StageEqual ([System.Numerics.BigInteger]7) $ctx1.semanticCommitted['x'] 'Hindi binabago ng metrics ang semantic state'

Start-BaseSemanticTransaction $ctx1
$ctx1.semanticPending['x'] = [System.Numerics.BigInteger]9
Complete-BaseSemanticTransaction $ctx1 { param($pending) return ($pending['x'] -eq 9) }
Assert-StageEqual ([System.Numerics.BigInteger]9) $ctx1.semanticCommitted['x'] 'Validated commit sa neutral transaction shell'

$monsterText = Get-Content -Raw (Join-Path $root 'src/MonsterSkeleton.ps1')
Assert-StageTrue -Condition ($monsterText -notmatch 'Invoke-NormSauce|Get-NormCalendarDate') -Name 'Hindi tumatawag sa oracle ang production skeleton'
$futureNames = @('oldRemainder','oldDayTag','oldDistance','mutateStonesWrong','orderAt46Latch','biasedLegacyPick','LEGACY_YEAR_MAX','VirtualLegacyList','oldContiguousMonthDayGuess')
foreach ($name in $futureNames) {
    Assert-StageTrue -Condition ($monsterText -notmatch [regex]::Escape($name)) -Name "Walang future patch code: $name"
}

$projectTextFiles = Get-ChildItem -Path $root -Recurse -File | Where-Object { $_.Extension -in @('.ps1','.psd1','.md') }
$hasHebrew = $false
foreach ($file in $projectTextFiles) {
    $textForLanguageAudit = Get-Content -Raw $file.FullName
    if ($file.Name -eq 'DEVELOPMENT_STAGE.md') { $textForLanguageAudit = $textForLanguageAudit -replace '(?m)^NATURAL_LANGUAGE=.*$', 'NATURAL_LANGUAGE=MACHINE_METADATA' }
    if ($textForLanguageAudit -match '[\u0590-\u05FF]') { $hasHebrew = $true; break }
}
Assert-StageTrue -Condition (-not $hasHebrew) -Name 'Walang Hebrew prose sa human-authored project files'

# Malalim ngunit hindi end-to-end na smoke test ng sauce upang patunayan ang determinismo ng core oracle.
$sauce1 = Invoke-NormSauce $f $f
$sauce2 = Invoke-NormSauce $f $f
Assert-StageSequenceEqual ([int[]]$sauce1.OrderAtDrop46) ([int[]]$sauce2.OrderAtDrop46) 'Deterministic ang order sa ika-46 na patak'
for ($id = 1; $id -le 6; $id++) {
    Assert-StageEqual $sauce1.Bowls[$id] $sauce2.Bowls[$id] "Deterministic ang final bowl $id"
    Assert-StageTrue -Condition ($sauce1.Bowls[$id] -ge 1 -and $sauce1.Bowls[$id] -le (Get-NormM)) -Name "Nasa 1..M ang final bowl $id"
}

$ok = Complete-StageTestRun
if (-not $ok) { exit 1 }
