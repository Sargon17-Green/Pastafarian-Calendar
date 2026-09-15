Set-StrictMode -Version Latest

function Get-Discovery08Factorial {
    [CmdletBinding()]
    param([Parameter(Mandatory)][int]$N)

    if ($N -lt 0) {
        throw 'Hindi maaaring negatibo ang factorial input.'
    }

    $result = [System.Numerics.BigInteger]::One
    for ($i = 2; $i -le $N; $i++) {
        $result *= $i
    }
    return [System.Numerics.BigInteger]$result
}

function Get-Discovery08RegularMod {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$X,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$D
    )

    if ($D -lt 1) {
        throw 'Ang modulus ay dapat positibo.'
    }

    $r = $X % $D
    if ($r -lt 0) {
        $r += $D
    }
    return [System.Numerics.BigInteger]$r
}

function oldPermutationUnrank0 {
    [CmdletBinding()]
    param([Parameter(Mandatory)][System.Numerics.BigInteger]$Rank0)

    # Historical helper: tunay na zero-based at valid lamang sa 0..719.
    if ($Rank0 -lt 0 -or $Rank0 -gt 719) {
        return $null
    }

    $remaining = [System.Collections.Generic.List[int]]::new()
    foreach ($item in ([int[]](1,2,3,4,5,6))) {
        $remaining.Add($item)
    }

    $result = [System.Collections.Generic.List[int]]::new()
    $workingRank = [System.Numerics.BigInteger]$Rank0

    while ($remaining.Count -gt 0) {
        $block = Get-Discovery08Factorial -N ($remaining.Count - 1)
        $q = [int]($workingRank / $block)
        $workingRank = [System.Numerics.BigInteger]($workingRank % $block)

        $result.Add($remaining[$q])
        $remaining.RemoveAt($q)
    }

    return ,$result.ToArray()
}

function Invoke-Discovery08LegacyPermutationCaller {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$DropValue
    )

    Assert-BaseContextOwnership -Context $Context | Out-Null

    $oneBasedOrdinal = [System.Numerics.BigInteger](
        (Get-Discovery08RegularMod -X ($DropValue - 1) -D ([System.Numerics.BigInteger]720)) + 1
    )

    # Historical defect: ang one-based ordinal ay direktang ipinapasa bilang rank0.
    $legacyRank0Input = [System.Numerics.BigInteger]$oneBasedOrdinal
    $legacyOrder = oldPermutationUnrank0 -Rank0 $legacyRank0Input
    $undefined = $null -eq $legacyOrder

    Start-BaseSemanticTransaction -Context $Context
    try {
        $Context.semanticPending['legacyPermutationDropValue'] = $DropValue
        $Context.semanticPending['legacyPermutationOneBasedOrdinal'] = $oneBasedOrdinal
        $Context.semanticPending['legacyPermutationRank0Input'] = $legacyRank0Input
        $Context.semanticPending['legacyPermutationOrder'] = $legacyOrder
        $Context.semanticPending['legacyPermutationUndefined'] = $undefined

        Complete-BaseSemanticTransaction -Context $Context -Validator {
            param($pending)
            return (
                $pending.ContainsKey('legacyPermutationDropValue') -and
                $pending.ContainsKey('legacyPermutationOneBasedOrdinal') -and
                $pending.ContainsKey('legacyPermutationRank0Input') -and
                $pending.ContainsKey('legacyPermutationOrder') -and
                $pending.ContainsKey('legacyPermutationUndefined') -and
                $pending['legacyPermutationOneBasedOrdinal'] -ge 1 -and
                $pending['legacyPermutationOneBasedOrdinal'] -le 720 -and
                $pending['legacyPermutationRank0Input'] -eq $pending['legacyPermutationOneBasedOrdinal'] -and
                $pending['legacyPermutationUndefined'] -eq ($null -eq $pending['legacyPermutationOrder'])
            )
        }
    }
    catch {
        Undo-BaseSemanticTransaction -Context $Context
        throw
    }

    $Context.legacyPermutationDropValue = $DropValue
    $Context.legacyPermutationOneBasedOrdinal = $oneBasedOrdinal
    $Context.legacyPermutationRank0Input = $legacyRank0Input
    $Context.legacyPermutationOrder = $legacyOrder
    $Context.legacyPermutationUndefined = $undefined
    $Context.discovery08Status = 'ONE_BASED_ORDINAL_AS_RANK0_ACTIVE'
    $Context.discovery08InvocationCount++

    Add-BaseMetric -Context $Context -Name 'discovery08.permutation.calls'
    Add-BaseLog -Context $Context -Code 'monster.discovery08.legacyPermutation' -Data ([pscustomobject]@{
        dropValue = $DropValue
        oneBasedOrdinal = $oneBasedOrdinal
        legacyRank0Input = $legacyRank0Input
        undefined = $undefined
        order = $legacyOrder
    })

    return ,$legacyOrder
}

function LegacyPermutationRankAdapter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$DropValue
    )

    return Invoke-Discovery08LegacyPermutationCaller -Context $Context -DropValue $DropValue
}
