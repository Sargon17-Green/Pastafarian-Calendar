Set-StrictMode -Version Latest

function patchedCounts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$CalculationDay,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$TargetDay,
        [System.Collections.Generic.List[System.Numerics.BigInteger]]$LegacyCapture = $null
    )

    $legacy = [System.Numerics.BigInteger](oldDistance `
        -CalculationDay $CalculationDay `
        -TargetDay $TargetDay)

    if ($null -ne $LegacyCapture) {
        $LegacyCapture.Add($legacy)
    }

    $chronological = [System.Numerics.BigInteger]::Abs($TargetDay - $CalculationDay)

    if ($legacy -ne $chronological) {
        $legacy = $chronological
    }

    return [System.Numerics.BigInteger]($legacy + [System.Numerics.BigInteger]::One)
}

function Invoke-Patch03DistanceAdapter {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Context)

    Assert-BaseContextOwnership -Context $Context | Out-Null

    $capture = [System.Collections.Generic.List[System.Numerics.BigInteger]]::new()
    $patched = [System.Numerics.BigInteger](patchedCounts `
        -CalculationDay $Context.calculationDay `
        -TargetDay $Context.targetDay `
        -LegacyCapture $capture)

    if ($capture.Count -ne 1) {
        throw 'Dapat eksaktong isang raw legacy distance ang makuha ng Patch 03.'
    }

    $rawLegacy = [System.Numerics.BigInteger]$capture[0]
    $chronological = [System.Numerics.BigInteger]::Abs(
        $Context.targetDay - $Context.calculationDay
    )
    $replaced = [bool]($rawLegacy -ne $chronological)

    Start-BaseSemanticTransaction -Context $Context
    try {
        $Context.semanticPending['legacyDistanceCalculationDay'] = [System.Numerics.BigInteger]$Context.calculationDay
        $Context.semanticPending['legacyDistanceTargetDay'] = [System.Numerics.BigInteger]$Context.targetDay
        $Context.semanticPending['legacyDistanceValue'] = $rawLegacy
        $Context.semanticPending['patch03ChronologicalDistance'] = $chronological
        $Context.semanticPending['patch03DistanceValue'] = $patched
        $Context.semanticPending['patch03LegacyReplaced'] = [bool]$replaced
        $Context.semanticPending['patch03Applied'] = $true

        Complete-BaseSemanticTransaction -Context $Context -Validator {
            param($pending)
            return (
                $pending.ContainsKey('legacyDistanceCalculationDay') -and
                $pending.ContainsKey('legacyDistanceTargetDay') -and
                $pending.ContainsKey('legacyDistanceValue') -and
                $pending.ContainsKey('patch03ChronologicalDistance') -and
                $pending.ContainsKey('patch03DistanceValue') -and
                $pending.ContainsKey('patch03LegacyReplaced') -and
                $pending.ContainsKey('patch03Applied') -and
                $pending['legacyDistanceValue'] -is [System.Numerics.BigInteger] -and
                $pending['patch03ChronologicalDistance'] -is [System.Numerics.BigInteger] -and
                $pending['patch03DistanceValue'] -is [System.Numerics.BigInteger] -and
                $pending['patch03DistanceValue'] -ge 1 -and
                $pending['patch03Applied'] -eq $true
            )
        }
    }
    catch {
        Undo-BaseSemanticTransaction -Context $Context
        throw
    }

    $Context.legacyDistanceCalculationDay = [System.Numerics.BigInteger]$Context.calculationDay
    $Context.legacyDistanceTargetDay = [System.Numerics.BigInteger]$Context.targetDay
    $Context.legacyDistanceValue = $rawLegacy
    $Context.discovery03Status = 'HISTORICAL_SCAR_CAPTURED'
    $Context.discovery03InvocationCount++

    $Context.patch03ChronologicalDistance = $chronological
    $Context.patch03DistanceValue = $patched
    $Context.patch03LegacyReplaced = [bool]$replaced
    $Context.patch03Applied = $true
    $Context.patch03Status = 'DISTANCE_PATCH_ACTIVE'
    $Context.patch03InvocationCount++

    Add-BaseMetric -Context $Context -Name 'patch03.distance.calls'
    Add-BaseLog -Context $Context -Code 'monster.patch03.distance.adapter' -Data ([pscustomobject]@{
        rawLegacy = $rawLegacy
        chronological = $chronological
        patched = $patched
        replaced = [bool]$replaced
    })

    return $Context
}
