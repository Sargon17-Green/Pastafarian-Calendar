Set-StrictMode -Version Latest

function Copy-Discovery11Order {
    [CmdletBinding()]
    param(
        [AllowNull()][Parameter(Mandatory)][System.Array]$Order
    )
    if ($null -eq $Order -or $Order.Count -ne 6) {
        throw 'Ang order ay dapat may eksaktong anim na positions.'
    }
    $copy = [int[]]::new(6)
    for ($j = 0; $j -lt 6; $j++) {
        $copy[$j] = [int]$Order[$j]
    }
    return ,$copy
}

function postStirRoundExact {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$Stir,
        [AllowNull()][Parameter(Mandatory)][System.Array]$Bowls
    )

    if ($Stir -lt 1 -or $Stir -gt 12) {
        throw 'Ang post-stir number ay dapat nasa 1..12.'
    }
    if ($null -eq $Bowls -or $Bowls.Count -lt 7) {
        throw 'Kailangan ang 1-based bowl table na may slots 1..6.'
    }

    $old = [System.Numerics.BigInteger[]]::new(7)
    $sum = [System.Numerics.BigInteger]::Zero
    for ($b = 1; $b -le 6; $b++) {
        $old[$b] = [System.Numerics.BigInteger]$Bowls[$b]
        $sum += [System.Numerics.BigInteger]$old[$b]
    }

    $savedStirSum = [System.Numerics.BigInteger](
        Get-Discovery04SavedValue -Value (
            $sum + 149 * $Stir
        )
    )

    $order = patchedOrderFromDrop -DropValue $savedStirSum
    $pending = [System.Numerics.BigInteger[]]::new(7)

    for ($position = 1; $position -le 6; $position++) {
        $bowlId = [int]$order[$position - 1]
        $prevId = [int]$order[(($position - 2 + 6) % 6)]
        $nextId = [int]$order[($position % 6)]

        $s = [System.Numerics.BigInteger](
            [System.Numerics.BigInteger]$old[$bowlId] +
            3 * [System.Numerics.BigInteger]$old[$prevId] +
            5 * [System.Numerics.BigInteger]$old[$nextId] +
            $savedStirSum +
            $Stir +
            $position * $position
        )

        $pending[$bowlId] = [System.Numerics.BigInteger](
            Get-Discovery04SavedValue -Value (
                $s * $s +
                7 * [System.Numerics.BigInteger]$old[$prevId] *
                    [System.Numerics.BigInteger]$old[$nextId]
            )
        )
    }

    return [pscustomobject]@{
        Bowls = $pending
        Order = $order
        SavedStirSum = $savedStirSum
    }
}

function Invoke-Discovery11OverwritableOrderMemory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context
    )

    Assert-BaseContextOwnership -Context $Context | Out-Null

    if ($null -eq $Context.legacyVisibleDropTable -or $Context.legacyVisibleDropTable.Count -lt 47) {
        throw 'Kailangang handa ang lahat ng 46 visible drops bago Discovery 11.'
    }
    if ($null -eq $Context.patch08OrderTable -or $Context.patch08OrderTable.Count -lt 47) {
        throw 'Kailangang handa ang lahat ng 46 corrected orders bago Discovery 11.'
    }

    if ($null -eq $Context.legacyInitialBowls) {
        $counts = Get-Discovery05CountsFromContext -Context $Context
        $Context.legacyInitialBowls = Get-Discovery09InitialBowlsThroughOldFactory -Counts $counts
    }

    $bowls = [System.Numerics.BigInteger[]]::new(7)
    for ($b = 1; $b -le 6; $b++) {
        $bowls[$b] = [System.Numerics.BigInteger]$Context.legacyInitialBowls[$b]
    }

    $Context.legacyOverwritableOrderMemory = $null
    $Context.legacyOrderMemoryWriteCount = 0
    $Context.legacyOrderMemoryLastSource = $null

    for ($i = 1; $i -le 46; $i++) {
        $pours = Invoke-Patch09BowlAliasRepairWithBowls `
            -Context $Context `
            -I $i `
            -OldBowls $bowls

        $bowls = Invoke-Patch10SnapshotBowlUpdateRepair `
            -Context $Context `
            -I $i `
            -Bowls $bowls `
            -Pours $pours

        # Discovery 11 defect, first half: one general order memory is reused.
        $Context.legacyOverwritableOrderMemory = Copy-Discovery11Order `
            -Order $Context.patch08OrderTable[$i]
        $Context.legacyOrderMemoryWriteCount++
        $Context.legacyOrderMemoryLastSource = [pscustomobject]@{
            kind = 'drop'
            index = $i
        }
    }

    $Context.legacyBowlsAfter46Drops = $bowls

    for ($stir = 1; $stir -le 12; $stir++) {
        $round = postStirRoundExact -Stir $stir -Bowls $bowls
        $bowls = $round.Bowls

        # Discovery 11 defect, second half: post-stir orders overwrite the
        # same general memory, so drop 46 is not latched separately.
        $Context.legacyOverwritableOrderMemory = Copy-Discovery11Order `
            -Order $round.Order
        $Context.legacyOrderMemoryWriteCount++
        $Context.legacyOrderMemoryLastSource = [pscustomobject]@{
            kind = 'stir'
            index = $stir
        }
        $Context.legacyPostStirLastSavedSum = [System.Numerics.BigInteger]$round.SavedStirSum
    }

    $Context.legacyPostStirFinalBowls = $bowls
    $Context.discovery11Status = 'OVERWRITABLE_ORDER_MEMORY_ACTIVE'
    $Context.discovery11InvocationCount++

    Add-BaseMetric -Context $Context -Name 'discovery11.orderMemory.fullPasses'
    Add-BaseLog -Context $Context -Code 'monster.discovery11.overwritableOrderMemory' -Data ([pscustomobject]@{
        writes = $Context.legacyOrderMemoryWriteCount
        lastSourceKind = $Context.legacyOrderMemoryLastSource.kind
        lastSourceIndex = $Context.legacyOrderMemoryLastSource.index
        finalOrder = $Context.legacyOverwritableOrderMemory
        finalBowls = $Context.legacyPostStirFinalBowls
    })

    return ,$bowls
}

function Get-Discovery11LegacyQueriedOrder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context
    )

    Assert-BaseContextOwnership -Context $Context | Out-Null

    if ($null -eq $Context.legacyOverwritableOrderMemory) {
        throw 'Hindi pa handa ang legacy overwritable order memory.'
    }

    # Historical Discovery 11 query still reads the last overwritten memory.
    return ,$Context.legacyOverwritableOrderMemory
}
