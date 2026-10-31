Set-StrictMode -Version Latest
# Stage29 / Patch14: bounded deterministic wide-composite compatibility.
# The previous short rejection Patch13 and legacy modulo Discovery13 remain untouched.
# This is NOT a guarantee of statistical-uniformity over a deterministic stream.

function Get-Patch14WideAcceptedRank {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$First,
        [Parameter(Mandatory)][int]$Step,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$N
    )
    $m = [System.Numerics.BigInteger]$script:Discovery01M
    $space = [System.Numerics.BigInteger]($m * $m)
    if ($First -lt 1 -or $First -gt $m) {
        throw 'Ang unang sagot ay dapat nasa 1..M.'
    }
    if ($Step -ne -1 -and $Step -ne 1) {
        throw 'Ang hakbang ay dapat +1 o -1.'
    }
    if ($N -le $m -or $N -gt $space) {
        throw 'Ang malawak na N ay dapat nasa M+1..M^2.'
    }

    $second = [System.Numerics.BigInteger](1 + (($First - 1 + $Step + $m) % $m))
    $composite = [System.Numerics.BigInteger](1 + ($First - 1) + $m * ($second - 1))
    $limit = [System.Numerics.BigInteger](($space / $N) * $N)
    $accepted = [System.Numerics.BigInteger]$composite
    $skipped = [System.Numerics.BigInteger]::Zero
    if ($composite -gt $limit) {
        # The rejected suffix is contiguous. Skip directly to its cyclic edge.
        if ($Step -eq -1) {
            $accepted = [System.Numerics.BigInteger]$limit
            $skipped = [System.Numerics.BigInteger]($composite - $limit)
        } else {
            $accepted = [System.Numerics.BigInteger]::One
            $skipped = [System.Numerics.BigInteger]($space - $composite + 1)
        }
    }
    return [pscustomobject]@{
        Rank = [System.Numerics.BigInteger](1 + (($accepted - 1) % $N))
        Accepted = [System.Numerics.BigInteger]$accepted
        RejectedCompositeWords = [System.Numerics.BigInteger]$skipped
        Limit = [System.Numerics.BigInteger]$limit
        Composite = [System.Numerics.BigInteger]$composite
        Space = [System.Numerics.BigInteger]$space
    }
}

function Invoke-Patch14WideRank {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$CalculationDay,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$TargetDay,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$N,
        [Parameter(Mandatory)][int]$Seal
    )
    $m = [System.Numerics.BigInteger]$script:Discovery01M
    if ($N -le $m -or $N -gt ($m * $m) -or $Seal -lt 1 -or $Seal -gt 10) {
        throw 'Hindi wasto ang wide family o seal sa Patch14.'
    }

    # Run the single established Stage25 predecessor, no second context.
    $context = Invoke-CalendarDateSpaghetti -CalculationDay $CalculationDay -TargetDay $TargetDay
    $stream = Get-Discovery13AnswerStreamFromContext -Context $context -QueriedBowlId 1 -Seal $Seal
    $fixed = Get-Patch14WideAcceptedRank -First $stream.First -Step $stream.Step -N $N
    Add-BaseMetric -Context $context -Name 'patch14.wideCompatibility.calls'
    Add-BaseLog -Context $context -Code 'monster.patch14.wideCompatibility' -Data ([pscustomobject]@{
        n = $N
        first = $stream.First
        step = $stream.Step
        composite = $fixed.Composite
        acceptedComposite = $fixed.Accepted
        rejectedCompositeWords = $fixed.RejectedCompositeWords
        patchedRank = $fixed.Rank
        statisticalUniformityClaimed = $false
    })
    return [pscustomobject]@{
        Context = $context
        Stream = $stream
        Rank = $fixed.Rank
        Accepted = $fixed.Accepted
        RejectedCompositeWords = $fixed.RejectedCompositeWords
        Status = 'PATCH14_WIDE_DETERMINISTIC_COMPATIBILITY'
    }
}
