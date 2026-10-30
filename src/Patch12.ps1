Set-StrictMode -Version Latest
# Stage25 Patch12 preserves the numeric legacy caller in Discovery12.
function Get-Patch12PositionalNext {
    [CmdletBinding()]
    param([AllowNull()][Parameter(Mandatory)][object]$Order,
          [Parameter(Mandatory)][object]$QueriedBowlId)
    if ($QueriedBowlId -isnot [int] -or $QueriedBowlId -lt 1 -or $QueriedBowlId -gt 6) {
        throw 'Ang bowl ID ay dapat integer 1..6.'
    }
    if ($null -eq $Order -or $Order -isnot [System.Array] -or $Order.Count -ne 6) {
        throw 'Kailangan ang anim na bowl ID sa drop46 latch.'
    }
    $seen = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($id in $Order) {
        if ($id -isnot [int] -or $id -lt 1 -or $id -gt 6 -or -not $seen.Add($id)) {
            throw 'Hindi balidong six-ID permutation.'
        }
    }
    $position = [Array]::IndexOf($Order,$QueriedBowlId)
    if ($position -lt 0) { throw 'Wala ang bowl ID sa latch.' }
    return [int]$Order[($position+1)%6]
}
function Invoke-Patch12PositionalSuccessor {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Context,
          [Parameter(Mandatory)][object]$QueriedBowlId)
    Assert-BaseContextOwnership -Context $Context | Out-Null
    if ($Context.discovery12InvocationCount -ne 0 -or $Context.patch12InvocationCount -ne 0) {
        throw 'Isang query lamang sa bawat invocation.'
    }
    # Historical wrong numeric caller must run before the repair.
    $wrong = Invoke-Discovery12NumericSuccessor -Context $Context -QueriedBowlId $QueriedBowlId
    if ($Context.discovery12InvocationCount -ne 1 -or
        $Context.patch11CapturedAtWrite -ne 46 -or $Context.legacyOrderMemoryWriteCount -ne 58) {
        throw 'Nawawala ang Stage24 historical path.'
    }
    $correct = Get-Patch12PositionalNext -Order $Context.orderAt46Latch -QueriedBowlId $QueriedBowlId
    $snapshot = Copy-Discovery11Order -Order $Context.orderAt46Latch
    $Context.patch12QueriedBowlId = [int]$QueriedBowlId
    $Context.patch12LegacyNumericNext = [int]$wrong
    $Context.patch12OrderSnapshot = $snapshot
    $Context.patch12Position0 = [Array]::IndexOf($snapshot,$QueriedBowlId)
    $Context.patch12CorrectedNext = [int]$correct
    $Context.patch12Status = 'POSITIONAL_SUCCESSOR_PATCH_ACTIVE'
    $Context.patch12InvocationCount++
    Add-BaseMetric -Context $Context -Name 'patch12.positionalSuccessor.calls'
    Add-BaseLog -Context $Context -Code 'monster.patch12.positionalSuccessor' -Data ([pscustomobject]@{
        queriedBowlId = [int]$QueriedBowlId
        oldNumericNext = [int]$wrong
        position0 = $Context.patch12Position0
        correctedNext = [int]$correct
        orderAt46Latch = (Copy-Discovery11Order -Order $snapshot)
    })
    return [int]$correct
}
