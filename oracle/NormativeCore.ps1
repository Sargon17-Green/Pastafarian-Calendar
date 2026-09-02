Set-StrictMode -Version Latest

$script:BI0 = [System.Numerics.BigInteger]::Zero
$script:BI1 = [System.Numerics.BigInteger]::One
$script:M = [System.Numerics.BigInteger]::Pow([System.Numerics.BigInteger]2, 127) - $script:BI1
$script:TabletsDay = [System.Numerics.BigInteger](-278522)
$script:FoundationDay = [System.Numerics.BigInteger](-15055671)
$script:YearMinDays = [System.Numerics.BigInteger]252
$script:YearMaxDays = [System.Numerics.BigInteger]5778

function Get-NormM { return $script:M }
function Get-NormFoundationDay { return $script:FoundationDay }
function Get-NormTabletsDay { return $script:TabletsDay }

function Get-NormFloorDiv {
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$A,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$B
    )
    if ($B -le 0) { throw 'Ang divisor ay dapat positibo.' }
    $q = $A / $B
    $r = $A % $B
    if ($r -lt 0) { $q -= $script:BI1 }
    return [System.Numerics.BigInteger]$q
}

function Get-NormRegularMod {
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$X,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$D
    )
    if ($D -lt 1) { throw 'Ang modulus ay dapat hindi bababa sa isa.' }
    return [System.Numerics.BigInteger]($X - (Get-NormFloorDiv -A $X -B $D) * $D)
}

function Get-NormSave {
    param([Parameter(Mandatory)][System.Numerics.BigInteger]$X)
    return [System.Numerics.BigInteger]($script:BI1 + (Get-NormRegularMod -X ($X - $script:BI1) -D $script:M))
}

function Get-NormCeilDiv {
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$A,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$B
    )
    if ($A -lt 0 -or $B -lt 1) { throw 'Hindi wasto ang input sa ceil division.' }
    return [System.Numerics.BigInteger](Get-NormFloorDiv -A ($A + $B - $script:BI1) -B $B)
}

function Get-NormWrap1 {
    param([Parameter(Mandatory)][int]$Position, [Parameter(Mandatory)][int]$Size)
    if ($Size -lt 1) { throw 'Ang laki ng ring ay dapat positibo.' }
    return [int]((Get-NormRegularMod -X ([System.Numerics.BigInteger]($Position - 1)) -D ([System.Numerics.BigInteger]$Size)) + 1)
}

function Get-NormDayCount {
    param([Parameter(Mandatory)][System.Numerics.BigInteger]$Day)
    if ($Day -eq $script:FoundationDay) { return $script:BI1 }
    if ($Day -gt $script:FoundationDay) { return [System.Numerics.BigInteger](2 * ($Day - $script:FoundationDay) + 1) }
    return [System.Numerics.BigInteger](2 * ($script:FoundationDay - $Day))
}

function Get-NormWorkCounts {
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$CalculationDay,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$TargetDay
    )
    $action = Get-NormDayCount -Day $CalculationDay
    $target = Get-NormDayCount -Day $TargetDay
    $distance = [System.Numerics.BigInteger]::Abs($TargetDay - $CalculationDay) + 1
    $direction = 2
    if ($TargetDay -lt $CalculationDay) { $direction = 1 }
    elseif ($TargetDay -gt $CalculationDay) { $direction = 3 }
    return [pscustomobject]@{
        action = $action
        target = $target
        distance = [System.Numerics.BigInteger]$distance
        connection = [System.Numerics.BigInteger]($action + $target)
        direction = $direction
    }
}

function New-NormStoneRow {
    param($W, $B, $S, $Muddy, $R)
    $row = [object[]]::new(6)
    $row[1] = [System.Numerics.BigInteger]$W
    $row[2] = [System.Numerics.BigInteger]$B
    $row[3] = [System.Numerics.BigInteger]$S
    $row[4] = [System.Numerics.BigInteger]$Muddy
    $row[5] = [System.Numerics.BigInteger]$R
    return ,$row
}

function New-NormStoneTable {
    $table = [object[]]::new(47)
    $table[1] = New-NormStoneRow 17 29 43 71 101
    for ($i = 2; $i -le 46; $i++) {
        $old = $table[$i - 1]
        $nw = Get-NormSave ($old[1] * $old[1] + 3 * $old[2] + $i)
        $nb = Get-NormSave ($old[2] * $old[2] + 5 * $old[3] + $old[1])
        $ns = Get-NormSave ($old[3] * $old[3] + 7 * $old[4] + $old[2])
        $nm = Get-NormSave ($old[4] * $old[4] + 11 * $old[5] + $old[3])
        $nr = Get-NormSave ($old[5] * $old[5] + 13 * $old[1] + $old[4])
        $table[$i] = New-NormStoneRow $nw $nb $ns $nm $nr
    }
    return ,$table
}

$script:NormStoneTable = New-NormStoneTable

$script:HiddenCoeff = @(
    $null,
    @(3,4,6,8), @(5,7,10,12), @(7,10,14,16), @(9,13,18,20),
    @(11,16,22,24), @(13,19,26,28), @(15,22,30,32)
)
$script:HiddenGrindStone = @($null,1,2,3,4,5,1,2)

function Get-NormHiddenDrops {
    param([Parameter(Mandatory)]$Counts)
    $hidden = [object[]]::new(8)
    for ($k = 1; $k -le 7; $k++) {
        $coef = $script:HiddenCoeff[$k]
        $row = $script:NormStoneTable[$k]
        $x = $Counts.action + $coef[0] * $Counts.target + $coef[1] * $Counts.distance + $coef[2] * $Counts.connection + $coef[3] * $Counts.direction
        for ($kind = 1; $kind -le 5; $kind++) { $x += $row[$kind] }
        $x = Get-NormSave $x
        for ($g = 1; $g -le 7; $g++) {
            $oldX = $x
            $x = Get-NormSave ($oldX * $oldX + 3 * $oldX + $row[$script:HiddenGrindStone[$g]] + $g)
        }
        $hidden[$k] = $x
    }
    return ,$hidden
}

$script:VisibleGrinds = @(
    $null,
    @(3,5,7,11,1), @(5,7,11,13,2), @(7,11,13,17,3), @(11,13,17,19,4),
    @(13,17,19,23,5), @(17,19,23,29,1), @(19,23,29,31,2), @(23,29,31,37,3),
    @(29,31,37,41,4), @(31,37,41,43,5), @(37,41,43,47,1)
)

function Get-NormVisibleDrops {
    param([Parameter(Mandatory)]$Counts, [Parameter(Mandatory)]$Hidden)
    $timeline = [System.Collections.Generic.Dictionary[int,System.Numerics.BigInteger]]::new()
    for ($k = 1; $k -le 7; $k++) { $timeline[1 - $k] = [System.Numerics.BigInteger]$Hidden[$k] }
    for ($i = 1; $i -le 46; $i++) {
        $p1 = $timeline[$i - 1]
        $p3 = $timeline[$i - 3]
        $p7 = $timeline[$i - 7]
        $row = $script:NormStoneTable[$i]
        $x = Get-NormSave ($row[1] * $Counts.action + $row[2] * $Counts.target + $row[3] * $Counts.distance + $row[4] * $Counts.connection + $row[5] * $Counts.direction + $p1 + 3 * $p3 + 5 * $p7 + $i)
        for ($g = 1; $g -le 11; $g++) {
            $oldX = $x
            $gr = $script:VisibleGrinds[$g]
            $x = Get-NormSave ($oldX * $oldX + $gr[0] * $oldX + $gr[1] * $p1 + $gr[2] * $p3 + $gr[3] * $p7 + $row[$gr[4]])
        }
        $timeline[$i] = $x
    }
    $visible = [object[]]::new(47)
    for ($i = 1; $i -le 46; $i++) { $visible[$i] = $timeline[$i] }
    return ,$visible
}

function Get-NormFactorial {
    param([Parameter(Mandatory)][int]$N)
    $r = [System.Numerics.BigInteger]::One
    for ($i = 2; $i -le $N; $i++) { $r *= $i }
    return $r
}

function Get-NormPermutationUnrank1 {
    param([Parameter(Mandatory)][System.Numerics.BigInteger]$Rank1, [Parameter(Mandatory)][int[]]$ItemsAscending)
    $remaining = [System.Collections.Generic.List[int]]::new()
    foreach ($v in $ItemsAscending) { $remaining.Add($v) }
    $result = [System.Collections.Generic.List[int]]::new()
    $rank0 = $Rank1 - 1
    while ($remaining.Count -gt 0) {
        $block = Get-NormFactorial ($remaining.Count - 1)
        $q = [int](Get-NormFloorDiv $rank0 $block)
        $rank0 = Get-NormRegularMod $rank0 $block
        $result.Add($remaining[$q])
        $remaining.RemoveAt($q)
    }
    return ,$result.ToArray()
}

function Get-NormBowlOrderFromDrop {
    param([Parameter(Mandatory)][System.Numerics.BigInteger]$DropValue)
    $rank = (Get-NormRegularMod ($DropValue - 1) 720) + 1
    return ,(Get-NormPermutationUnrank1 $rank ([int[]](1,2,3,4,5,6)))
}

function Get-NormInitialBowls {
    param([Parameter(Mandatory)]$Counts)
    $prime = @(0,17,19,23,29,31,37)
    $b = [object[]]::new(7)
    for ($id = 1; $id -le 6; $id++) {
        $s = $Counts.action + $Counts.target * $id + $Counts.distance + $Counts.connection + $Counts.direction + $prime[$id] * $prime[$id]
        $b[$id] = Get-NormSave ($s * $s + $id)
    }
    return ,$b
}

function Invoke-NormVisibleDropsToBowls {
    param([Parameter(Mandatory)]$Bowls, [Parameter(Mandatory)]$Visible)
    $stoneByPos = @(0,1,2,3,4,5,1)
    $current = [object[]]::new(7)
    for ($id = 1; $id -le 6; $id++) { $current[$id] = $Bowls[$id] }
    $order46 = $null
    for ($i = 1; $i -le 46; $i++) {
        $drop = $Visible[$i]
        $order = Get-NormBowlOrderFromDrop $drop
        $old = [object[]]::new(7)
        for ($id = 1; $id -le 6; $id++) { $old[$id] = $current[$id] }
        $pour = [object[]]::new(7)
        $pour[1] = Get-NormSave ($drop * $drop + $script:NormStoneTable[$i][1] * $old[$order[0]] + 3 * $i)
        $pour[2] = Get-NormSave ($drop * $drop + $script:NormStoneTable[$i][2] * $old[$order[1]] + 5 * $i)
        $pour[3] = Get-NormSave ($drop * $drop + $script:NormStoneTable[$i][3] * $old[$order[2]] + 7 * $i)
        $pour[4] = $script:BI0; $pour[5] = $script:BI0; $pour[6] = $script:BI0
        $nextBowls = [object[]]::new(7)
        for ($position = 1; $position -le 6; $position++) {
            $idx = $position - 1
            $id = $order[$idx]
            $prev = $order[(Get-NormWrap1 ($position - 1) 6) - 1]
            $next = $order[(Get-NormWrap1 ($position + 1) 6) - 1]
            $s = $old[$id] + 2 * $old[$prev] + 3 * $old[$next] + $pour[$position] + $drop + $script:NormStoneTable[$i][$stoneByPos[$position]]
            $nextBowls[$id] = Get-NormSave ($s * $s + 5 * $old[$prev] * $old[$next] + $i * $position)
        }
        $current = $nextBowls
        if ($i -eq 46) { $order46 = [int[]]$order.Clone() }
    }
    return [pscustomobject]@{ Bowls = $current; OrderAtDrop46 = $order46 }
}

function Invoke-NormPostStir12 {
    param([Parameter(Mandatory)]$Bowls)
    $current = [object[]]::new(7)
    for ($id = 1; $id -le 6; $id++) { $current[$id] = $Bowls[$id] }
    for ($stir = 1; $stir -le 12; $stir++) {
        $old = [object[]]::new(7)
        $sum = $script:BI0
        for ($id = 1; $id -le 6; $id++) { $old[$id] = $current[$id]; $sum += $old[$id] }
        $saved = Get-NormSave ($sum + 149 * $stir)
        $orderNumber = (Get-NormRegularMod ($saved - 1) 720) + 1
        $order = Get-NormPermutationUnrank1 $orderNumber ([int[]](1,2,3,4,5,6))
        $nextBowls = [object[]]::new(7)
        for ($position = 1; $position -le 6; $position++) {
            $id = $order[$position - 1]
            $prev = $order[(Get-NormWrap1 ($position - 1) 6) - 1]
            $next = $order[(Get-NormWrap1 ($position + 1) 6) - 1]
            $s = $old[$id] + 3 * $old[$prev] + 5 * $old[$next] + $saved + $stir + $position * $position
            $nextBowls[$id] = Get-NormSave ($s * $s + 7 * $old[$prev] * $old[$next])
        }
        $current = $nextBowls
    }
    return ,$current
}

function Invoke-NormSauce {
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$CalculationDay,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$TargetDay
    )
    $counts = Get-NormWorkCounts $CalculationDay $TargetDay
    $hidden = Get-NormHiddenDrops $counts
    $visible = Get-NormVisibleDrops $counts $hidden
    $initial = Get-NormInitialBowls $counts
    $after = Invoke-NormVisibleDropsToBowls $initial $visible
    $final = Invoke-NormPostStir12 $after.Bowls
    return [pscustomobject]@{ Bowls = $final; OrderAtDrop46 = [int[]]$after.OrderAtDrop46 }
}

function Get-NormNextBowlInDrop46Order {
    param([Parameter(Mandatory)]$SauceResult, [Parameter(Mandatory)][int]$QueriedBowlId)
    $order = $SauceResult.OrderAtDrop46
    $pos = [Array]::IndexOf($order, $QueriedBowlId)
    if ($pos -lt 0) { throw 'Hindi nakita ang bowl id sa order ng ika-46 na patak.' }
    return [int]$order[($pos + 1) % 6]
}

function Get-NormAnswerStream {
    param([Parameter(Mandatory)]$SauceResult, [Parameter(Mandatory)][int]$QueriedBowlId, [Parameter(Mandatory)][int]$Seal)
    $nextId = Get-NormNextBowlInDrop46Order $SauceResult $QueriedBowlId
    $firstBase = $SauceResult.Bowls[$QueriedBowlId] + $Seal + 181
    $first = Get-NormSave ($firstBase * $firstBase + 179 * $SauceResult.Bowls[$nextId] + $Seal)
    $dirBase = $first + $Seal + 1 + 193
    $directionNumber = Get-NormSave ($dirBase * $dirBase + 193 * $first + 197 * $SauceResult.Bowls[6])
    $step = -1
    if ((Get-NormRegularMod $directionNumber 2) -eq 1) { $step = 1 }
    return [pscustomobject]@{ First = $first; Step = $step }
}

function Get-NormAnswerAt {
    param([Parameter(Mandatory)]$Stream, [Parameter(Mandatory)][System.Numerics.BigInteger]$K)
    return [System.Numerics.BigInteger](1 + (Get-NormRegularMod ($Stream.First - 1 + $Stream.Step * $K) $script:M))
}

function Get-NormChooseRankShort {
    param([Parameter(Mandatory)]$Stream, [Parameter(Mandatory)][System.Numerics.BigInteger]$N)
    if ($N -lt 1 -or $N -gt $script:M) { throw 'Hindi wasto ang N para sa maikling pagpili.' }
    $limit = (Get-NormFloorDiv $script:M $N) * $N
    $k = $script:BI0
    while ($true) {
        $x = Get-NormAnswerAt $Stream $k
        if ($x -le $limit) { return [System.Numerics.BigInteger](1 + (Get-NormRegularMod ($x - 1) $N)) }
        $k += 1
    }
}

function Get-NormChooseRankWide {
    param([Parameter(Mandatory)]$Stream, [Parameter(Mandatory)][System.Numerics.BigInteger]$N)
    if ($N -le $script:M) { throw 'Ang malawak na pagpili ay para lamang sa N na higit sa M.' }
    $places = 1
    $space = $script:M
    while ($space -lt $N) { $places++; $space *= $script:M }
    $wide = $script:BI1
    $weight = $script:BI1
    for ($j = 0; $j -lt $places; $j++) {
        $wide += ((Get-NormAnswerAt $Stream ([System.Numerics.BigInteger]$j)) - 1) * $weight
        $weight *= $script:M
    }
    $limit = (Get-NormFloorDiv $space $N) * $N
    while ($wide -gt $limit) { $wide = 1 + (Get-NormRegularMod ($wide - 1 + $Stream.Step) $space) }
    return [System.Numerics.BigInteger](1 + (Get-NormRegularMod ($wide - 1) $N))
}

function Get-NormChooseRank {
    param([Parameter(Mandatory)]$Stream, [Parameter(Mandatory)][System.Numerics.BigInteger]$N)
    if ($N -lt 1) { throw 'Ang dami ng pagpipilian ay dapat positibo.' }
    if ($N -le $script:M) { return Get-NormChooseRankShort $Stream $N }
    return Get-NormChooseRankWide $Stream $N
}
