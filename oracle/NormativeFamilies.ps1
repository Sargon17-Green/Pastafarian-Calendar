Set-StrictMode -Version Latest

function Get-NormFallingFactorial {
    param([Parameter(Mandatory)][int]$N, [Parameter(Mandatory)][int]$K)
    if ($K -lt 0 -or $K -gt $N) { return [System.Numerics.BigInteger]::Zero }
    $r = [System.Numerics.BigInteger]::One
    for ($j = 0; $j -lt $K; $j++) { $r *= ($N - $j) }
    return $r
}

function Get-NormDistinctIndexUnrank {
    param(
        [Parameter(Mandatory)][int]$MasterCount,
        [Parameter(Mandatory)][int]$K,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$Rank1
    )
    $remaining = [System.Collections.Generic.List[int]]::new()
    for ($i = 1; $i -le $MasterCount; $i++) { $remaining.Add($i) }
    $out = [System.Collections.Generic.List[int]]::new()
    $r = $Rank1
    for ($position = 1; $position -le $K; $position++) {
        $suffixLength = $K - $position
        $block = Get-NormFallingFactorial ($remaining.Count - 1) $suffixLength
        $chosen = -1
        for ($candidate = 0; $candidate -lt $remaining.Count; $candidate++) {
            if ($r -gt $block) { $r -= $block }
            else { $chosen = $candidate; break }
        }
        if ($chosen -lt 0) { throw 'Lumampas ang rank sa distinct-name family.' }
        $out.Add($remaining[$chosen])
        $remaining.RemoveAt($chosen)
    }
    return ,$out.ToArray()
}

function Get-NormBoundedCompositionCountInternal {
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$Rem,
        [Parameter(Mandatory)][int]$Slots,
        [Parameter(Mandatory)][int]$Lo,
        [Parameter(Mandatory)][int]$Hi,
        [Parameter(Mandatory)][hashtable]$Memo
    )
    if ($Slots -eq 0) {
        if ($Rem -eq 0) { return [System.Numerics.BigInteger]::One }
        return [System.Numerics.BigInteger]::Zero
    }
    if ($Rem -lt $Slots * $Lo -or $Rem -gt $Slots * $Hi) { return [System.Numerics.BigInteger]::Zero }
    $key = "$Rem|$Slots"
    if ($Memo.ContainsKey($key)) { return [System.Numerics.BigInteger]$Memo[$key] }
    $sum = [System.Numerics.BigInteger]::Zero
    for ($x = $Lo; $x -le $Hi; $x++) {
        $sum += Get-NormBoundedCompositionCountInternal ($Rem - $x) ($Slots - 1) $Lo $Hi $Memo
    }
    $Memo[$key] = $sum
    return $sum
}

function Get-NormBoundedCompositionCount {
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$Total,
        [Parameter(Mandatory)][int]$Slots,
        [Parameter(Mandatory)][int]$Lo,
        [Parameter(Mandatory)][int]$Hi
    )
    $memo = @{}
    return Get-NormBoundedCompositionCountInternal $Total $Slots $Lo $Hi $memo
}

function Get-NormBoundedCompositionUnrank {
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$Total,
        [Parameter(Mandatory)][int]$Slots,
        [Parameter(Mandatory)][int]$Lo,
        [Parameter(Mandatory)][int]$Hi,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$Rank1
    )
    $memo = @{}
    $all = Get-NormBoundedCompositionCountInternal $Total $Slots $Lo $Hi $memo
    if ($Rank1 -lt 1 -or $Rank1 -gt $all) { throw 'Hindi wasto ang rank sa bounded-composition family.' }
    $r = $Rank1
    $rem = $Total
    $out = [System.Collections.Generic.List[int]]::new()
    for ($position = 1; $position -le $Slots; $position++) {
        $picked = $false
        for ($x = $Lo; $x -le $Hi; $x++) {
            $block = Get-NormBoundedCompositionCountInternal ($rem - $x) ($Slots - $position) $Lo $Hi $memo
            if ($r -gt $block) { $r -= $block }
            else {
                $out.Add($x)
                $rem -= $x
                $picked = $true
                break
            }
        }
        if (-not $picked) { throw 'Hindi natagpuan ang lexicographic block sa bounded composition.' }
    }
    return ,$out.ToArray()
}

function Get-NormCutletPartitionCountInternal {
    param(
        [Parameter(Mandatory)][int]$Rem,
        [Parameter(Mandatory)][int]$Slots,
        [Parameter(Mandatory)][int]$Cumulative,
        [Parameter(Mandatory)][bool]$HitBoundary,
        [AllowNull()][Nullable[int]]$RequiredBoundary,
        [Parameter(Mandatory)][hashtable]$Memo
    )
    if ($Slots -eq 0) {
        if ($Rem -ne 0) { return [System.Numerics.BigInteger]::Zero }
        if ($null -eq $RequiredBoundary) { return [System.Numerics.BigInteger]::One }
        if ($HitBoundary) { return [System.Numerics.BigInteger]::One }
        return [System.Numerics.BigInteger]::Zero
    }
    if ($Rem -lt $Slots) { return [System.Numerics.BigInteger]::Zero }
    $reqKey = if ($null -eq $RequiredBoundary) { 'none' } else { [string]$RequiredBoundary.Value }
    $key = "$Rem|$Slots|$Cumulative|$HitBoundary|$reqKey"
    if ($Memo.ContainsKey($key)) { return [System.Numerics.BigInteger]$Memo[$key] }
    $total = [System.Numerics.BigInteger]::Zero
    $maxX = $Rem - ($Slots - 1)
    for ($x = 1; $x -le $maxX; $x++) {
        $nextCumulative = $Cumulative + $x
        $nextHit = $HitBoundary
        if ($null -ne $RequiredBoundary -and -not $HitBoundary) {
            if ($nextCumulative -eq $RequiredBoundary.Value) { $nextHit = $true }
            elseif ($nextCumulative -gt $RequiredBoundary.Value) { continue }
        }
        $total += Get-NormCutletPartitionCountInternal ($Rem - $x) ($Slots - 1) $nextCumulative $nextHit $RequiredBoundary $Memo
    }
    $Memo[$key] = $total
    return $total
}

function Get-NormCutletPartitionCount {
    param([Parameter(Mandatory)][int]$G, [Parameter(Mandatory)][int]$K, [AllowNull()][Nullable[int]]$RequiredBoundary)
    $memo = @{}
    return Get-NormCutletPartitionCountInternal $G $K 0 $false $RequiredBoundary $memo
}

function Get-NormCutletPartitionUnrank {
    param(
        [Parameter(Mandatory)][int]$G,
        [Parameter(Mandatory)][int]$K,
        [AllowNull()][Nullable[int]]$RequiredBoundary,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$Rank1
    )
    $memo = @{}
    $all = Get-NormCutletPartitionCountInternal $G $K 0 $false $RequiredBoundary $memo
    if ($Rank1 -lt 1 -or $Rank1 -gt $all) { throw 'Hindi wasto ang rank sa cutlet-partition family.' }
    $r = $Rank1
    $rem = $G
    $slots = $K
    $cumulative = 0
    $hit = $false
    $out = [System.Collections.Generic.List[int]]::new()
    while ($slots -gt 0) {
        $maxX = $rem - ($slots - 1)
        $picked = $false
        for ($x = 1; $x -le $maxX; $x++) {
            $nextCumulative = $cumulative + $x
            $nextHit = $hit
            if ($null -ne $RequiredBoundary -and -not $hit) {
                if ($nextCumulative -eq $RequiredBoundary.Value) { $nextHit = $true }
                elseif ($nextCumulative -gt $RequiredBoundary.Value) { continue }
            }
            $block = Get-NormCutletPartitionCountInternal ($rem - $x) ($slots - 1) $nextCumulative $nextHit $RequiredBoundary $memo
            if ($r -gt $block) { $r -= $block }
            else {
                $out.Add($x)
                $rem -= $x
                $slots--
                $cumulative = $nextCumulative
                $hit = $nextHit
                $picked = $true
                break
            }
        }
        if (-not $picked) { throw 'Hindi natagpuan ang lexicographic cutlet partition.' }
    }
    return ,$out.ToArray()
}

function Test-NormWeaveMove {
    param([Parameter(Mandatory)][int[]]$Remaining, [Parameter(Mandatory)][int[]]$Lengths, [Parameter(Mandatory)][int]$OpenedUpTo, [Parameter(Mandatory)][int]$ClosedUpTo, [Parameter(Mandatory)][int]$J)
    $idx = $J - 1
    if ($Remaining[$idx] -eq 0) { return $false }
    $alreadyOpened = $Remaining[$idx] -lt $Lengths[$idx]
    if (-not $alreadyOpened -and $J -ne ($OpenedUpTo + 1)) { return $false }
    $willClose = $Remaining[$idx] -eq 1
    if ($willClose -and $J -ne ($ClosedUpTo + 1)) { return $false }
    return $true
}

function Get-NormWeaveNextState {
    param([Parameter(Mandatory)][int[]]$Remaining, [Parameter(Mandatory)][int[]]$Lengths, [Parameter(Mandatory)][int]$OpenedUpTo, [Parameter(Mandatory)][int]$ClosedUpTo, [Parameter(Mandatory)][int]$J)
    $nextRemaining = [int[]]$Remaining.Clone()
    $nextOpened = $OpenedUpTo
    $nextClosed = $ClosedUpTo
    $idx = $J - 1
    if ($nextRemaining[$idx] -eq $Lengths[$idx]) { $nextOpened = $J }
    $nextRemaining[$idx]--
    if ($nextRemaining[$idx] -eq 0) { $nextClosed = $J }
    return [pscustomobject]@{ Remaining = $nextRemaining; OpenedUpTo = $nextOpened; ClosedUpTo = $nextClosed }
}

function Get-NormWeavingCountInternal {
    param(
        [Parameter(Mandatory)][int[]]$Remaining,
        [Parameter(Mandatory)][int[]]$Lengths,
        [Parameter(Mandatory)][int]$OpenedUpTo,
        [Parameter(Mandatory)][int]$ClosedUpTo,
        [Parameter(Mandatory)][hashtable]$Memo
    )
    $left = 0
    foreach ($v in $Remaining) { $left += $v }
    if ($left -eq 0) { return [System.Numerics.BigInteger]::One }
    $key = ([string]::Join(',', $Remaining)) + "|$OpenedUpTo|$ClosedUpTo"
    if ($Memo.ContainsKey($key)) { return [System.Numerics.BigInteger]$Memo[$key] }
    $total = [System.Numerics.BigInteger]::Zero
    for ($j = 1; $j -le $Lengths.Count; $j++) {
        if (-not (Test-NormWeaveMove $Remaining $Lengths $OpenedUpTo $ClosedUpTo $j)) { continue }
        $next = Get-NormWeaveNextState $Remaining $Lengths $OpenedUpTo $ClosedUpTo $j
        $total += Get-NormWeavingCountInternal $next.Remaining $Lengths $next.OpenedUpTo $next.ClosedUpTo $Memo
    }
    $Memo[$key] = $total
    return $total
}

function Get-NormWeavingCount {
    param([Parameter(Mandatory)][int[]]$Lengths)
    $memo = @{}
    $remaining = [int[]]$Lengths.Clone()
    return Get-NormWeavingCountInternal $remaining $Lengths 0 0 $memo
}

function Get-NormWeavingUnrank {
    param([Parameter(Mandatory)][int[]]$Lengths, [Parameter(Mandatory)][System.Numerics.BigInteger]$Rank1)
    $memo = @{}
    $remaining = [int[]]$Lengths.Clone()
    $all = Get-NormWeavingCountInternal $remaining $Lengths 0 0 $memo
    if ($Rank1 -lt 1 -or $Rank1 -gt $all) { throw 'Hindi wasto ang rank sa month-weaving family.' }
    $r = $Rank1
    $opened = 0
    $closed = 0
    $totalLength = 0
    foreach ($v in $Lengths) { $totalLength += $v }
    $out = [System.Collections.Generic.List[int]]::new()
    while ($out.Count -lt $totalLength) {
        $picked = $false
        for ($j = 1; $j -le $Lengths.Count; $j++) {
            if (-not (Test-NormWeaveMove $remaining $Lengths $opened $closed $j)) { continue }
            $next = Get-NormWeaveNextState $remaining $Lengths $opened $closed $j
            $block = Get-NormWeavingCountInternal $next.Remaining $Lengths $next.OpenedUpTo $next.ClosedUpTo $memo
            if ($r -gt $block) { $r -= $block }
            else {
                $out.Add($j)
                $remaining = $next.Remaining
                $opened = $next.OpenedUpTo
                $closed = $next.ClosedUpTo
                $picked = $true
                break
            }
        }
        if (-not $picked) { throw 'Hindi natagpuan ang lexicographic weaving block.' }
    }
    return ,$out.ToArray()
}
