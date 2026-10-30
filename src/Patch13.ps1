Set-StrictMode -Version Latest
# Stage27 Patch13: short SAVE stream rejection; Discovery13 historic modulo remains intact.
# Wide N and the five canonical date components are outside this patch.
function Get-Patch13AcceptedRank {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$First,
        [Parameter(Mandatory)][int]$Step,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$N
    )
    $m = [System.Numerics.BigInteger]$script:Discovery01M
    if ($N -lt 1 -or $N -gt $m -or $First -lt 1 -or $First -gt $m) {
        throw 'Ang N at unang sagot ay dapat nasa 1..M sa Patch13.'
    }
    if ($Step -ne -1 -and $Step -ne 1) {
        throw 'Ang hakbang ng stream ay dapat +1 o -1.'
    }
    $limit = [System.Numerics.BigInteger](($m / $N) * $N)
    $accepted = [System.Numerics.BigInteger]$First
    $skipped = [System.Numerics.BigInteger]::Zero
    if ($First -gt $limit) {
        # Arithmetic skipping is identical to iterating a contiguous rejected suffix.
        if ($Step -eq -1) {
            $skipped = [System.Numerics.BigInteger]($First - $limit)
            $accepted = $limit
        } else {
            $skipped = [System.Numerics.BigInteger]($m - $First + 1)
            $accepted = [System.Numerics.BigInteger]::One
        }
    }
    return [pscustomobject]@{
        Rank = [System.Numerics.BigInteger](1 + (($accepted - 1) % $N))
        Accepted = [System.Numerics.BigInteger]$accepted
        RejectedAnswers = [System.Numerics.BigInteger]$skipped
        Limit = [System.Numerics.BigInteger]$limit
    }
}
function Invoke-Patch13RejectionRank {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$CalculationDay,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$TargetDay,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$N,
        [Parameter(Mandatory)][int]$Seal
    )
    # Real Stage25 producer exactly once via Stage26's existing witness.
    $old = Invoke-Discovery13HistoricalRank -CalculationDay $CalculationDay -TargetDay $TargetDay -N $N -Seal $Seal
    $fixed = Get-Patch13AcceptedRank -First $old.Stream.First -Step $old.Stream.Step -N $N
    Add-BaseMetric -Context $old.Context -Name 'patch13.rejectionSampling.calls'
    Add-BaseLog -Context $old.Context -Code 'monster.patch13.shortRejection' -Data ([pscustomobject]@{
        n = $N
        historicalFirstAnswerRank = $old.LegacyRank
        acceptedAnswer = $fixed.Accepted
        rejectedAnswers = $fixed.RejectedAnswers
        patchedRank = $fixed.Rank
        rejectionSamplingApplied = $true
    })
    return [pscustomobject]@{
        Context = $old.Context
        Stream = $old.Stream
        LegacyRank = $old.LegacyRank
        Rank = $fixed.Rank
        Accepted = $fixed.Accepted
        RejectedAnswers = $fixed.RejectedAnswers
        Status = 'PATCH13_SHORT_REJECTION_ACTIVE'
    }
}
