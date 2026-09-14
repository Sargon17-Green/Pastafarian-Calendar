Set-StrictMode -Version Latest

function oldDistance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$CalculationDay,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$TargetDay
    )

    $calculationTag = [System.Numerics.BigInteger](dayTagWithFoundationScar -Day $CalculationDay)
    $targetTag = [System.Numerics.BigInteger](dayTagWithFoundationScar -Day $TargetDay)

    return [System.Numerics.BigInteger]::Abs($calculationTag - $targetTag)
}

function Invoke-Discovery03LegacyDistanceAdapter {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Context)

    Assert-BaseContextOwnership -Context $Context | Out-Null

    $legacy = [System.Numerics.BigInteger](oldDistance `
        -CalculationDay $Context.calculationDay `
        -TargetDay $Context.targetDay)

    Start-BaseSemanticTransaction -Context $Context
    try {
        $Context.semanticPending['legacyDistanceCalculationDay'] = [System.Numerics.BigInteger]$Context.calculationDay
        $Context.semanticPending['legacyDistanceTargetDay'] = [System.Numerics.BigInteger]$Context.targetDay
        $Context.semanticPending['legacyDistanceValue'] = $legacy

        Complete-BaseSemanticTransaction -Context $Context -Validator {
            param($pending)
            return (
                $pending.ContainsKey('legacyDistanceCalculationDay') -and
                $pending.ContainsKey('legacyDistanceTargetDay') -and
                $pending.ContainsKey('legacyDistanceValue') -and
                $pending['legacyDistanceCalculationDay'] -is [System.Numerics.BigInteger] -and
                $pending['legacyDistanceTargetDay'] -is [System.Numerics.BigInteger] -and
                $pending['legacyDistanceValue'] -is [System.Numerics.BigInteger] -and
                $pending['legacyDistanceValue'] -ge 0
            )
        }
    }
    catch {
        Undo-BaseSemanticTransaction -Context $Context
        throw
    }

    $Context.legacyDistanceCalculationDay = [System.Numerics.BigInteger]$Context.calculationDay
    $Context.legacyDistanceTargetDay = [System.Numerics.BigInteger]$Context.targetDay
    $Context.legacyDistanceValue = $legacy
    $Context.discovery03Status = 'LEGACY_DISTANCE_ACTIVE'
    $Context.discovery03InvocationCount++

    Add-BaseMetric -Context $Context -Name 'discovery03.legacyDistance.calls'
    Add-BaseLog -Context $Context -Code 'monster.discovery03.distance.adapter' -Data ([pscustomobject]@{
        calculationDay = [System.Numerics.BigInteger]$Context.calculationDay
        targetDay = [System.Numerics.BigInteger]$Context.targetDay
        legacyDistance = $legacy
    })

    return $Context
}
