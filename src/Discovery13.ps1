Set-StrictMode -Version Latest
# Discovery 13: preserve the historical first-answer modulo choice.
# This module does NOT implement rejection sampling or Patch 13.

function oldFirstAnswerModuloRank {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$First,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$N
    )
    $m = [System.Numerics.BigInteger]$script:Discovery01M
    if ($N -lt 1 -or $N -gt $m) {
        throw 'Ang N ay dapat nasa 1..M sa Discovery 13.'
    }
    if ($First -lt 1 -or $First -gt $m) {
        throw 'Ang unang sagot ay dapat nasa 1..M.'
    }
    return [System.Numerics.BigInteger](1 + (($First - 1) % $N))
}

function Get-Discovery13AnswerStreamFromContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][int]$QueriedBowlId,
        [Parameter(Mandatory)][int]$Seal
    )
    Assert-BaseContextOwnership -Context $Context | Out-Null
    if ($QueriedBowlId -ne 1 -or $Context.patch12QueriedBowlId -ne $QueriedBowlId -or
        $Context.patch12InvocationCount -ne 1 -or
        $Context.patch11CapturedAtWrite -ne 46 -or
        $Context.legacyOrderMemoryWriteCount -ne 58 -or
        $Context.patch12Status -ne 'POSITIONAL_SUCCESSOR_PATCH_ACTIVE' -or
        $null -eq $Context.legacyPostStirFinalBowls -or
        $Context.legacyPostStirFinalBowls.Count -ne 7) {
        throw 'Kailangan ang buong Stage25 predecessor na may queried bowl 1.'
    }
    if ($Seal -lt 1 -or $Seal -gt 10) {
        throw 'Ang ibinigay na Seal ay dapat nasa 1..10.'
    }
    $bowls = $Context.legacyPostStirFinalBowls
    $nextId = [int]$Context.patch12ProductionResult
    if ($nextId -lt 1 -or $nextId -gt 6) { throw 'Hindi wasto ang corrected bowl successor.' }
    $firstBase = [System.Numerics.BigInteger]($bowls[$QueriedBowlId] + $Seal + 181)
    $first = Get-Discovery04SavedValue -Value ($firstBase * $firstBase + 179 * $bowls[$nextId] + $Seal)
    $dirBase = [System.Numerics.BigInteger]($first + $Seal + 1 + 193)
    $directionNumber = Get-Discovery04SavedValue -Value ($dirBase * $dirBase + 193 * $first + 197 * $bowls[6])
    $step = -1
    if (($directionNumber % 2) -eq 1) { $step = 1 }
    return [pscustomobject]@{
        First = [System.Numerics.BigInteger]$first
        Step = [int]$step
        Seal = [int]$Seal
        QueriedBowlId = [int]$QueriedBowlId
    }
}

function Invoke-Discovery13HistoricalRank {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$CalculationDay,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$TargetDay,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$N,
        [Parameter(Mandatory)][int]$Seal
    )
    if ($N -lt 1 -or $N -gt $script:Discovery01M -or $Seal -lt 1 -or $Seal -gt 10) {
        throw 'Hindi wasto ang laki ng pamilya o seal sa Discovery 13.'
    }
    # The Stage25 producer already runs 46 drops, 12 stirs and patched successor.
    # Its existing single query addresses bowl 1; do not introduce another query.
    $context = Invoke-CalendarDateSpaghetti -CalculationDay $CalculationDay -TargetDay $TargetDay
    $stream = Get-Discovery13AnswerStreamFromContext -Context $context -QueriedBowlId 1 -Seal $Seal
    $rank = oldFirstAnswerModuloRank -First $stream.First -N $N
    Add-BaseMetric -Context $context -Name 'discovery13.oldModulo.calls'
    Add-BaseLog -Context $context -Code 'monster.discovery13.historicalModulo' -Data ([pscustomobject]@{
        n = $N
        first = $stream.First
        step = $stream.Step
        oldRank = $rank
        rejectionSamplingApplied = $false
    })
    return [pscustomobject]@{
        Context = $context
        Stream = $stream
        LegacyRank = [System.Numerics.BigInteger]$rank
        Status = 'HISTORICAL_NO_REJECTION_EXPECTED_RED'
    }
}
