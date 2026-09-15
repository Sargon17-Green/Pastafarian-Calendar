Set-StrictMode -Version Latest

function patchedOrderFromDrop {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$DropValue
    )

    $oneBased = [System.Numerics.BigInteger](
        (Get-Discovery08RegularMod -X ($DropValue - 1) -D ([System.Numerics.BigInteger]720)) + 1
    )
    $legacyRank0 = [System.Numerics.BigInteger]($oneBased - 1)

    return ,(oldPermutationUnrank0 -Rank0 $legacyRank0)
}

function Invoke-Patch08PermutationRankRepair {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][int]$DropIndex,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$DropValue
    )

    Assert-BaseContextOwnership -Context $Context | Out-Null

    if ($DropIndex -lt 1 -or $DropIndex -gt 46) {
        throw 'Ang visible drop index ay dapat nasa 1..46.'
    }

    $oneBased = [System.Numerics.BigInteger](
        (Get-Discovery08RegularMod -X ($DropValue - 1) -D ([System.Numerics.BigInteger]720)) + 1
    )
    $legacyRank0 = [System.Numerics.BigInteger]($oneBased - 1)

    # Preserved Discovery 08 scar: talagang patakbuhin muna ang wrong caller.
    $rawLegacyOrder = LegacyPermutationRankAdapter `
        -Context $Context `
        -DropValue $DropValue

    $rawLegacyUndefined = [bool]$Context.legacyPermutationUndefined
    $rawLegacyError = $null
    if ($rawLegacyUndefined) {
        $rawLegacyError = 'Ang lumang zero-based permutation rank ay wala sa saklaw.'
    }

    # Patch 08 authoritative chain:
    # oneBased -> legacyRank0 = oneBased - 1 -> oldPermutationUnrank0.
    $correctedOrder = oldPermutationUnrank0 -Rank0 $legacyRank0
    if ($null -eq $correctedOrder) {
        throw 'Hindi dapat maging undefined ang corrected Patch 08 permutation.'
    }

    Start-BaseSemanticTransaction -Context $Context
    try {
        $Context.semanticPending['patch08DropIndex'] = $DropIndex
        $Context.semanticPending['patch08DropValue'] = $DropValue
        $Context.semanticPending['patch08OneBasedOrdinal'] = $oneBased
        $Context.semanticPending['patch08LegacyRank0'] = $legacyRank0
        $Context.semanticPending['patch08LegacyWrongOrder'] = $rawLegacyOrder
        $Context.semanticPending['patch08LegacyWrongUndefined'] = $rawLegacyUndefined
        $Context.semanticPending['patch08LegacyWrongError'] = $rawLegacyError
        $Context.semanticPending['patch08CorrectedOrder'] = $correctedOrder
        $Context.semanticPending['patch08Applied'] = $true

        Complete-BaseSemanticTransaction -Context $Context -Validator {
            param($pending)
            return (
                $pending.ContainsKey('patch08DropIndex') -and
                $pending.ContainsKey('patch08DropValue') -and
                $pending.ContainsKey('patch08OneBasedOrdinal') -and
                $pending.ContainsKey('patch08LegacyRank0') -and
                $pending.ContainsKey('patch08LegacyWrongOrder') -and
                $pending.ContainsKey('patch08LegacyWrongUndefined') -and
                $pending.ContainsKey('patch08LegacyWrongError') -and
                $pending.ContainsKey('patch08CorrectedOrder') -and
                $pending.ContainsKey('patch08Applied') -and
                $pending['patch08DropIndex'] -ge 1 -and
                $pending['patch08DropIndex'] -le 46 -and
                $pending['patch08OneBasedOrdinal'] -ge 1 -and
                $pending['patch08OneBasedOrdinal'] -le 720 -and
                $pending['patch08LegacyRank0'] -eq ($pending['patch08OneBasedOrdinal'] - 1) -and
                $pending['patch08LegacyRank0'] -ge 0 -and
                $pending['patch08LegacyRank0'] -le 719 -and
                $null -ne $pending['patch08CorrectedOrder'] -and
                $pending['patch08Applied'] -eq $true
            )
        }
    }
    catch {
        Undo-BaseSemanticTransaction -Context $Context
        throw
    }

    $Context.patch08DropIndex = $DropIndex
    $Context.patch08DropValue = $DropValue
    $Context.patch08OneBasedOrdinal = $oneBased
    $Context.patch08LegacyRank0 = $legacyRank0
    $Context.patch08LegacyWrongOrder = $rawLegacyOrder
    $Context.patch08LegacyWrongUndefined = $rawLegacyUndefined
    $Context.patch08LegacyWrongError = $rawLegacyError
    $Context.patch08CorrectedOrder = $correctedOrder
    $Context.patch08Applied = $true
    $Context.patch08Status = 'PERMUTATION_RANK_PATCH_ACTIVE'
    $Context.patch08InvocationCount++

    Add-BaseMetric -Context $Context -Name 'patch08.permutation.repairs'
    Add-BaseLog -Context $Context -Code 'monster.patch08.permutationRankRepair' -Data ([pscustomobject]@{
        dropIndex = $DropIndex
        dropValue = $DropValue
        oneBased = $oneBased
        legacyRank0 = $legacyRank0
        rawLegacyUndefined = $rawLegacyUndefined
        rawLegacyOrder = $rawLegacyOrder
        correctedOrder = $correctedOrder
    })

    return ,$correctedOrder
}

function Invoke-Patch08BuildOrderTable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [AllowNull()][Parameter(Mandatory)][System.Array]$VisibleDrops
    )

    Assert-BaseContextOwnership -Context $Context | Out-Null

    if ($null -eq $VisibleDrops -or $VisibleDrops.Count -lt 47) {
        throw 'Kailangan ang 1-based visible-drop table na may slots 1..46.'
    }

    $orders = [object[]]::new(47)

    for ($i = 1; $i -le 46; $i++) {
        if ($null -eq $VisibleDrops[$i]) {
            throw "Walang visible drop value sa slot $i."
        }

        $orders[$i] = Invoke-Patch08PermutationRankRepair `
            -Context $Context `
            -DropIndex $i `
            -DropValue ([System.Numerics.BigInteger]$VisibleDrops[$i])
    }

    $Context.patch08OrderTable = $orders
    $Context.patch08OrderCount = 46

    return ,$orders
}
