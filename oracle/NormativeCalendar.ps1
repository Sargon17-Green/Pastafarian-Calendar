Set-StrictMode -Version Latest

$script:SealGateGap = 1
$script:SealYear5000 = 10
$script:SealNextYear = 11
$script:SealPreviousYear = 12
$script:SealCutletCount = 20
$script:SealCutletPartition = 21
$script:SealCutletNames = 22
$script:SealMonthCount = 30
$script:SealMonthLengths = 31
$script:SealMonthWeaving = 32
$script:SealMonthNames = 33

function Reset-NormGateCache {
    $script:NormGate = [System.Collections.Generic.Dictionary[System.Numerics.BigInteger,System.Numerics.BigInteger]]::new()
    $script:NormGate[[System.Numerics.BigInteger]::Zero] = $script:FoundationDay
    $script:NormMinKnownGateIndex = [System.Numerics.BigInteger]::Zero
    $script:NormMaxKnownGateIndex = [System.Numerics.BigInteger]::Zero
}

Reset-NormGateCache

function Get-NormPositiveGateGap {
    param([Parameter(Mandatory)][System.Numerics.BigInteger]$N)
    if ($N -lt 1) { throw 'Ang positive gate index magnitude ay dapat positibo.' }
    $r = Invoke-NormSauce $script:FoundationDay ($script:FoundationDay + $N)
    $stream = Get-NormAnswerStream $r 1 $script:SealGateGap
    return [System.Numerics.BigInteger](41 + (Get-NormChooseRank $stream 922))
}

function Get-NormNegativeGateGap {
    param([Parameter(Mandatory)][System.Numerics.BigInteger]$N)
    if ($N -lt 1) { throw 'Ang negative gate index magnitude ay dapat positibo.' }
    $r = Invoke-NormSauce $script:FoundationDay ($script:FoundationDay - $N)
    $stream = Get-NormAnswerStream $r 1 $script:SealGateGap
    return [System.Numerics.BigInteger](41 + (Get-NormChooseRank $stream 922))
}

function Get-NormGate {
    param([Parameter(Mandatory)][System.Numerics.BigInteger]$Index)
    Ensure-NormGateIndex $Index
    return [System.Numerics.BigInteger]$script:NormGate[$Index]
}

function Ensure-NormGateIndex {
    param([Parameter(Mandatory)][System.Numerics.BigInteger]$K)
    if ($K -gt $script:NormMaxKnownGateIndex) {
        $n = $script:NormMaxKnownGateIndex + 1
        while ($n -le $K) {
            $script:NormGate[$n] = $script:NormGate[$n - 1] + (Get-NormPositiveGateGap $n)
            $script:NormMaxKnownGateIndex = $n
            $n += 1
        }
    }
    if ($K -lt $script:NormMinKnownGateIndex) {
        $n = $script:NormMinKnownGateIndex - 1
        while ($n -ge $K) {
            $script:NormGate[$n] = $script:NormGate[$n + 1] - (Get-NormNegativeGateGap ([System.Numerics.BigInteger]::Abs($n)))
            $script:NormMinKnownGateIndex = $n
            $n -= 1
        }
    }
}

function Ensure-NormGatesCover {
    param([Parameter(Mandatory)][System.Numerics.BigInteger]$LowDay, [Parameter(Mandatory)][System.Numerics.BigInteger]$HighDay)
    if ($LowDay -gt $HighDay) { throw 'Baligtad ang saklaw ng mga araw.' }
    while ($script:NormGate[$script:NormMinKnownGateIndex] -gt $LowDay) { Ensure-NormGateIndex ($script:NormMinKnownGateIndex - 1) }
    while ($script:NormGate[$script:NormMaxKnownGateIndex] -lt $HighDay) { Ensure-NormGateIndex ($script:NormMaxKnownGateIndex + 1) }
}

function Get-NormGateIndexAtOrBefore {
    param([Parameter(Mandatory)][System.Numerics.BigInteger]$Day)
    Ensure-NormGatesCover $Day $Day
    $lo = $script:NormMinKnownGateIndex
    $hi = $script:NormMaxKnownGateIndex
    while ($lo -lt $hi) {
        $mid = $lo + (Get-NormFloorDiv ($hi - $lo + 1) 2)
        if ($script:NormGate[$mid] -le $Day) { $lo = $mid } else { $hi = $mid - 1 }
    }
    return [System.Numerics.BigInteger]$lo
}

function Get-NormGateIndexAtOrAfter {
    param([Parameter(Mandatory)][System.Numerics.BigInteger]$Day)
    $i = Get-NormGateIndexAtOrBefore $Day
    if ($script:NormGate[$i] -eq $Day) { return $i }
    Ensure-NormGateIndex ($i + 1)
    return [System.Numerics.BigInteger]($i + 1)
}

function Get-NormExactGateIndex {
    param([Parameter(Mandatory)][System.Numerics.BigInteger]$Day)
    $i = Get-NormGateIndexAtOrBefore $Day
    if ($script:NormGate[$i] -eq $Day) { return [pscustomobject]@{ Found = $true; Index = $i } }
    return [pscustomobject]@{ Found = $false; Index = [System.Numerics.BigInteger]::Zero }
}

function Test-NormValidYearPair {
    param([Parameter(Mandatory)][System.Numerics.BigInteger]$OpenIndex, [Parameter(Mandatory)][System.Numerics.BigInteger]$CloseIndex)
    if (($CloseIndex - $OpenIndex) -lt 6) { return $false }
    Ensure-NormGateIndex $OpenIndex
    Ensure-NormGateIndex $CloseIndex
    $length = $script:NormGate[$CloseIndex] - $script:NormGate[$OpenIndex]
    return ($length -ge $script:YearMinDays -and $length -le $script:YearMaxDays)
}

function New-NormYearRecord {
    param([Parameter(Mandatory)][System.Numerics.BigInteger]$Number, [Parameter(Mandatory)][System.Numerics.BigInteger]$OpenIndex, [Parameter(Mandatory)][System.Numerics.BigInteger]$CloseIndex)
    return [pscustomobject]@{
        Number = $Number
        OpenGateIndex = $OpenIndex
        CloseGateIndex = $CloseIndex
        OpenGateDay = [System.Numerics.BigInteger]$script:NormGate[$OpenIndex]
        CloseGateDay = [System.Numerics.BigInteger]$script:NormGate[$CloseIndex]
    }
}

function Get-NormYear5000 {
    param([Parameter(Mandatory)][System.Numerics.BigInteger]$CalculationDay)
    Ensure-NormGatesCover ($CalculationDay - $script:YearMaxDays) ($CalculationDay + $script:YearMaxDays)
    $firstIndex = Get-NormGateIndexAtOrBefore ($CalculationDay - $script:YearMaxDays)
    $lastIndex = Get-NormGateIndexAtOrAfter ($CalculationDay + $script:YearMaxDays)
    $candidates = [System.Collections.Generic.List[object]]::new()
    $i = $firstIndex
    while ($i -lt $lastIndex) {
        $j = $i + 1
        while ($j -le $lastIndex) {
            $length = $script:NormGate[$j] - $script:NormGate[$i]
            if ($length -gt $script:YearMaxDays) { break }
            if (($j - $i) -ge 6 -and $length -ge $script:YearMinDays -and $script:NormGate[$i] -lt $CalculationDay -and $CalculationDay -le $script:NormGate[$j]) {
                $candidates.Add([pscustomobject]@{ OpenIndex = $i; CloseIndex = $j; Length = $length; OpenDay = $script:NormGate[$i] })
            }
            $j += 1
        }
        $i += 1
    }
    if ($candidates.Count -eq 0) { throw 'Walang candidate para sa year 5000.' }
    $ordered = @($candidates | Sort-Object -Property Length, OpenDay)
    $r = Invoke-NormSauce $CalculationDay $CalculationDay
    $stream = Get-NormAnswerStream $r 1 $script:SealYear5000
    $rank = Get-NormChooseRank $stream ([System.Numerics.BigInteger]$ordered.Count)
    $chosen = $ordered[[int]$rank - 1]
    return New-NormYearRecord 5000 $chosen.OpenIndex $chosen.CloseIndex
}

function Get-NormNextYear {
    param([Parameter(Mandatory)][System.Numerics.BigInteger]$CalculationDay, [Parameter(Mandatory)]$KnownYear)
    $openIndex = [System.Numerics.BigInteger]$KnownYear.CloseGateIndex
    $targetCover = $script:NormGate[$openIndex] + $script:YearMaxDays
    Ensure-NormGatesCover $script:NormGate[$openIndex] $targetCover
    $list = [System.Collections.Generic.List[object]]::new()
    $j = $openIndex + 1
    $ordinal = 0
    while ($true) {
        Ensure-NormGateIndex $j
        $length = $script:NormGate[$j] - $script:NormGate[$openIndex]
        if ($length -gt $script:YearMaxDays) { break }
        if (($j - $openIndex) -ge 6 -and $length -ge $script:YearMinDays) {
            $list.Add([pscustomobject]@{ Index = $j; Length = $length; Ordinal = $ordinal })
            $ordinal++
        }
        $j += 1
    }
    if ($list.Count -eq 0) { throw 'Walang candidate para sa susunod na taon.' }
    $ordered = @($list | Sort-Object -Property Length, Ordinal)
    $r = Invoke-NormSauce $CalculationDay $script:NormGate[$openIndex]
    $stream = Get-NormAnswerStream $r 1 $script:SealNextYear
    $rank = Get-NormChooseRank $stream ([System.Numerics.BigInteger]$ordered.Count)
    $closeIndex = $ordered[[int]$rank - 1].Index
    return New-NormYearRecord ($KnownYear.Number + 1) $openIndex $closeIndex
}

function Get-NormPreviousYear {
    param([Parameter(Mandatory)][System.Numerics.BigInteger]$CalculationDay, [Parameter(Mandatory)]$KnownYear)
    $closeIndex = [System.Numerics.BigInteger]$KnownYear.OpenGateIndex
    $targetCover = $script:NormGate[$closeIndex] - $script:YearMaxDays
    Ensure-NormGatesCover $targetCover $script:NormGate[$closeIndex]
    $list = [System.Collections.Generic.List[object]]::new()
    $i = $closeIndex - 1
    $ordinal = 0
    while ($true) {
        Ensure-NormGateIndex $i
        $length = $script:NormGate[$closeIndex] - $script:NormGate[$i]
        if ($length -gt $script:YearMaxDays) { break }
        if (($closeIndex - $i) -ge 6 -and $length -ge $script:YearMinDays) {
            $list.Add([pscustomobject]@{ Index = $i; Length = $length; Ordinal = $ordinal })
            $ordinal++
        }
        $i -= 1
    }
    if ($list.Count -eq 0) { throw 'Walang candidate para sa nakaraang taon.' }
    $ordered = @($list | Sort-Object -Property Length, Ordinal)
    $r = Invoke-NormSauce $CalculationDay $script:NormGate[$closeIndex]
    $stream = Get-NormAnswerStream $r 1 $script:SealPreviousYear
    $rank = Get-NormChooseRank $stream ([System.Numerics.BigInteger]$ordered.Count)
    $openIndex = $ordered[[int]$rank - 1].Index
    return New-NormYearRecord ($KnownYear.Number - 1) $openIndex $closeIndex
}

function Get-NormTargetYear {
    param([Parameter(Mandatory)][System.Numerics.BigInteger]$CalculationDay, [Parameter(Mandatory)][System.Numerics.BigInteger]$TargetDay)
    $y = Get-NormYear5000 $CalculationDay
    while ($TargetDay -gt $y.CloseGateDay) { $y = Get-NormNextYear $CalculationDay $y }
    while ($TargetDay -le $y.OpenGateDay) { $y = Get-NormPreviousYear $CalculationDay $y }
    if (-not ($y.OpenGateDay -lt $TargetDay -and $TargetDay -le $y.CloseGateDay)) { throw 'Hindi nasaklaw ng natagpuang taon ang target day.' }
    return $y
}

function Get-NormCutletCount {
    param([Parameter(Mandatory)]$StructureSauce, [Parameter(Mandatory)]$Year)
    $gateGaps = $Year.CloseGateIndex - $Year.OpenGateIndex
    $candidates = [System.Collections.Generic.List[int]]::new()
    for ($k = 6; $k -le 17; $k++) { if ([System.Numerics.BigInteger]$k -le $gateGaps) { $candidates.Add($k) } }
    if ($candidates.Count -eq 0) { throw 'Walang legal na cutlet count.' }
    $stream = Get-NormAnswerStream $StructureSauce 2 $script:SealCutletCount
    $rank = Get-NormChooseRank $stream ([System.Numerics.BigInteger]$candidates.Count)
    return [int]$candidates[[int]$rank - 1]
}

function Get-NormCutletPartition {
    param([Parameter(Mandatory)][System.Numerics.BigInteger]$CalculationDay, [Parameter(Mandatory)]$StructureSauce, [Parameter(Mandatory)]$Year, [Parameter(Mandatory)][int]$CutletCount)
    $gaps = [int]($Year.CloseGateIndex - $Year.OpenGateIndex)
    $exact = Get-NormExactGateIndex $CalculationDay
    [Nullable[int]]$required = $null
    if ($exact.Found -and $Year.OpenGateIndex -lt $exact.Index -and $exact.Index -lt $Year.CloseGateIndex) {
        $required = [int]($exact.Index - $Year.OpenGateIndex)
    }
    $count = Get-NormCutletPartitionCount $gaps $CutletCount $required
    $stream = Get-NormAnswerStream $StructureSauce 2 $script:SealCutletPartition
    $rank = Get-NormChooseRank $stream $count
    return ,(Get-NormCutletPartitionUnrank $gaps $CutletCount $required $rank)
}

function Get-NormCutletNameIndices {
    param([Parameter(Mandatory)]$StructureSauce, [Parameter(Mandatory)][int]$CutletCount)
    $n = Get-NormFallingFactorial 17 $CutletCount
    $stream = Get-NormAnswerStream $StructureSauce 5 $script:SealCutletNames
    $rank = Get-NormChooseRank $stream $n
    return ,(Get-NormDistinctIndexUnrank 17 $CutletCount $rank)
}

function Get-NormMaterializedCutlets {
    param([Parameter(Mandatory)]$Year, [Parameter(Mandatory)][int[]]$Partition, [Parameter(Mandatory)][int[]]$NameIndices)
    $out = [System.Collections.Generic.List[object]]::new()
    $cursor = [System.Numerics.BigInteger]$Year.OpenGateIndex
    for ($k = 0; $k -lt $Partition.Count; $k++) {
        $openIndex = $cursor
        $closeIndex = $cursor + $Partition[$k]
        Ensure-NormGateIndex $openIndex
        Ensure-NormGateIndex $closeIndex
        $out.Add([pscustomobject]@{
            NameIndex = $NameIndices[$k]
            OpenGateIndex = $openIndex
            CloseGateIndex = $closeIndex
            FirstDay = $script:NormGate[$openIndex] + 1
            LastDay = $script:NormGate[$closeIndex]
        })
        $cursor = $closeIndex
    }
    return ,$out.ToArray()
}

function Get-NormMonthCount {
    param([Parameter(Mandatory)]$StructureSauce, [Parameter(Mandatory)]$Year)
    $length = $Year.CloseGateDay - $Year.OpenGateDay
    $minMonths = [int](Get-NormCeilDiv $length 123)
    $maxByLength = [int](Get-NormFloorDiv $length 4)
    $maxMonths = [Math]::Min(47, $maxByLength)
    if ($minMonths -lt 3 -or $minMonths -gt $maxMonths -or $maxMonths -gt 47) { throw 'Hindi wasto ang month-count bounds.' }
    $stream = Get-NormAnswerStream $StructureSauce 3 $script:SealMonthCount
    $rank = Get-NormChooseRank $stream ([System.Numerics.BigInteger]($maxMonths - $minMonths + 1))
    return [int]($minMonths + [int]$rank - 1)
}

function Get-NormMonthLengths {
    param([Parameter(Mandatory)]$StructureSauce, [Parameter(Mandatory)]$Year, [Parameter(Mandatory)][int]$MonthCount)
    $length = $Year.CloseGateDay - $Year.OpenGateDay
    $count = Get-NormBoundedCompositionCount $length $MonthCount 4 123
    $stream = Get-NormAnswerStream $StructureSauce 3 $script:SealMonthLengths
    $rank = Get-NormChooseRank $stream $count
    return ,(Get-NormBoundedCompositionUnrank $length $MonthCount 4 123 $rank)
}

function Get-NormMonthWeaving {
    param([Parameter(Mandatory)]$StructureSauce, [Parameter(Mandatory)][int[]]$MonthLengths)
    $count = Get-NormWeavingCount $MonthLengths
    $stream = Get-NormAnswerStream $StructureSauce 4 $script:SealMonthWeaving
    $rank = Get-NormChooseRank $stream $count
    return ,(Get-NormWeavingUnrank $MonthLengths $rank)
}

function Get-NormMonthNameIndices {
    param([Parameter(Mandatory)]$StructureSauce, [Parameter(Mandatory)][int]$MonthCount)
    $n = Get-NormFallingFactorial 47 $MonthCount
    $stream = Get-NormAnswerStream $StructureSauce 5 $script:SealMonthNames
    $rank = Get-NormChooseRank $stream $n
    return ,(Get-NormDistinctIndexUnrank 47 $MonthCount $rank)
}

function Get-NormYearStructure {
    param([Parameter(Mandatory)][System.Numerics.BigInteger]$CalculationDay, [Parameter(Mandatory)]$Year)
    $firstDay = $Year.OpenGateDay + 1
    $r = Invoke-NormSauce $CalculationDay $firstDay
    $cutletCount = Get-NormCutletCount $r $Year
    $partition = Get-NormCutletPartition $CalculationDay $r $Year $cutletCount
    $cutletNames = Get-NormCutletNameIndices $r $cutletCount
    $cutlets = Get-NormMaterializedCutlets $Year ([int[]]$partition) ([int[]]$cutletNames)
    $monthCount = Get-NormMonthCount $r $Year
    $monthLengths = Get-NormMonthLengths $r $Year $monthCount
    $weave = Get-NormMonthWeaving $r ([int[]]$monthLengths)
    $monthNames = Get-NormMonthNameIndices $r $monthCount
    return [pscustomobject]@{
        CutletCount = $cutletCount
        CutletPartition = [int[]]$partition
        CutletNameIndices = [int[]]$cutletNames
        Cutlets = $cutlets
        MonthCount = $monthCount
        MonthLengths = [int[]]$monthLengths
        MonthWeaving = [int[]]$weave
        MonthNameIndices = [int[]]$monthNames
    }
}

function Get-NormCalendarDate {
    param([Parameter(Mandatory)][System.Numerics.BigInteger]$CalculationDay, [Parameter(Mandatory)][System.Numerics.BigInteger]$TargetDay)
    $year = Get-NormTargetYear $CalculationDay $TargetDay
    $structure = Get-NormYearStructure $CalculationDay $year
    $chosenCutlet = $null
    foreach ($cutlet in $structure.Cutlets) {
        if ($cutlet.FirstDay -le $TargetDay -and $TargetDay -le $cutlet.LastDay) { $chosenCutlet = $cutlet; break }
    }
    if ($null -eq $chosenCutlet) { throw 'Hindi nakita ang cutlet na naglalaman sa target day.' }
    $dayInCutlet = $TargetDay - $chosenCutlet.FirstDay + 1
    $offset0 = [int]($TargetDay - ($year.OpenGateDay + 1))
    $monthId = $structure.MonthWeaving[$offset0]
    $dayInMonth = 0
    for ($p = 0; $p -le $offset0; $p++) { if ($structure.MonthWeaving[$p] -eq $monthId) { $dayInMonth++ } }
    $cutletString = Resolve-CutletSourceString $chosenCutlet.NameIndex
    $monthString = Resolve-MonthSourceString $structure.MonthNameIndices[$monthId - 1]
    return ,([object[]]@(
        [System.Numerics.BigInteger]$year.Number,
        [string]$cutletString,
        [System.Numerics.BigInteger]$dayInCutlet,
        [string]$monthString,
        [System.Numerics.BigInteger]$dayInMonth
    ))
}
