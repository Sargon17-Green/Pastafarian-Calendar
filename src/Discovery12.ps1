Set-StrictMode -Version Latest
# Stage 24/Discovery 12 retains the wrong numeric-ID successor.
# Patch 12 is deferred to Stage 25.
function oldNextBowlFixedName {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$QueriedBowlId)
    if ($QueriedBowlId -isnot [int] -or $QueriedBowlId -lt 1 -or $QueriedBowlId -gt 6) {
        throw 'Ang queried bowl ID ay dapat integer 1..6.'
    }
    return [int](($QueriedBowlId % 6) + 1)
}
function Invoke-Discovery12NumericSuccessor {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Context, [Parameter(Mandatory)][object]$QueriedBowlId)
    Assert-BaseContextOwnership -Context $Context | Out-Null
    $oldNext = oldNextBowlFixedName -QueriedBowlId $QueriedBowlId
    if (-not $Context.patch11Applied -or $Context.patch11CapturedAtWrite -ne 46 -or
        $Context.legacyOrderMemoryWriteCount -ne 58 -or
        $null -eq $Context.legacyOrderMemoryLastSource -or
        $Context.legacyOrderMemoryLastSource.kind -ne 'stir' -or
        $Context.legacyOrderMemoryLastSource.index -ne 12 -or
        $null -eq $Context.orderAt46Latch -or $Context.orderAt46Latch.Count -ne 6) {
        throw 'Kailangan ang buong Patch11, 46 drop + 12 stir.'
    }
    $snapshot = Copy-Discovery11Order -Order $Context.orderAt46Latch
    $seen = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($id in $snapshot) {
        if ($id -lt 1 -or $id -gt 6 -or -not $seen.Add([int]$id)) {
            throw 'Hindi balidong six-ID permutation.'
        }
    }
    $Context.discovery12QueriedBowlId = [int]$QueriedBowlId
    $Context.discovery12OldNumericNext = [int]$oldNext
    $Context.discovery12OrderAt46Snapshot = $snapshot
    $Context.discovery12Status = 'HISTORICAL_NUMERIC_SUCCESSOR_EXPECTED_RED'
    $Context.discovery12InvocationCount++
    Add-BaseMetric -Context $Context -Name 'discovery12.numericSuccessor.calls'
    Add-BaseLog -Context $Context -Code 'monster.discovery12.numericSuccessor' -Data ([pscustomobject]@{
        queriedBowlId = [int]$QueriedBowlId
        oldNumericNext = [int]$oldNext
        orderAt46Latch = (Copy-Discovery11Order -Order $snapshot)
        expectedRed = $true
    })
    return [int]$oldNext
}
