Set-StrictMode -Version Latest

$script:Discovery02FoundationDay = [System.Numerics.BigInteger](-15055671)

function oldDayTag {
    [CmdletBinding()]
    param([Parameter(Mandatory)][System.Numerics.BigInteger]$Day)

    $delta = [System.Numerics.BigInteger]::Abs($Day - $script:Discovery02FoundationDay)
    return [System.Numerics.BigInteger](2 * $delta)
}

function Invoke-Discovery02LegacyDayTagAdapter {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Context)

    Assert-BaseContextOwnership -Context $Context | Out-Null

    $actionTag = [System.Numerics.BigInteger](oldDayTag -Day $Context.calculationDay)
    $targetTag = [System.Numerics.BigInteger](oldDayTag -Day $Context.targetDay)

    Start-BaseSemanticTransaction -Context $Context
    try {
        $Context.semanticPending['legacyActionDayTag'] = $actionTag
        $Context.semanticPending['legacyTargetDayTag'] = $targetTag

        Complete-BaseSemanticTransaction -Context $Context -Validator {
            param($pending)
            return (
                $pending.ContainsKey('legacyActionDayTag') -and
                $pending.ContainsKey('legacyTargetDayTag') -and
                $pending['legacyActionDayTag'] -is [System.Numerics.BigInteger] -and
                $pending['legacyTargetDayTag'] -is [System.Numerics.BigInteger] -and
                $pending['legacyActionDayTag'] -ge 0 -and
                $pending['legacyTargetDayTag'] -ge 0
            )
        }
    }
    catch {
        Undo-BaseSemanticTransaction -Context $Context
        throw
    }

    $Context.legacyActionDayTag = $actionTag
    $Context.legacyTargetDayTag = $targetTag
    $Context.discovery02Status = 'LEGACY_DAY_TAG_ACTIVE'
    $Context.discovery02InvocationCount++

    Add-BaseMetric -Context $Context -Name 'discovery02.legacyDayTag.calls'
    Add-BaseLog -Context $Context -Code 'monster.discovery02.daytag.adapter' -Data ([pscustomobject]@{
        action = $actionTag
        target = $targetTag
    })

    return $Context
}
