Set-StrictMode -Version Latest

function dayTagWithFoundationScar {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$Day,
        [System.Collections.Generic.List[System.Numerics.BigInteger]]$LegacyCapture = $null
    )

    # Hindi binabago ang historical helper; ang patch ay nasa ibabaw nito.
    $n = [System.Numerics.BigInteger](oldDayTag -Day $Day)

    if ($null -ne $LegacyCapture) {
        $LegacyCapture.Add($n)
    }

    if ($Day -ge $script:Discovery02FoundationDay) {
        $n += [System.Numerics.BigInteger]::One
    }

    # Pisikal na historical scar: redundant sa kasalukuyang oldDayTag ngunit hindi inaalis.
    if ($Day -eq $script:Discovery02FoundationDay -and $n -ne [System.Numerics.BigInteger]::One) {
        $n = [System.Numerics.BigInteger]::One
    }

    return [System.Numerics.BigInteger]$n
}

function Invoke-Patch02DayTagAdapter {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Context)

    Assert-BaseContextOwnership -Context $Context | Out-Null

    $actionCapture = [System.Collections.Generic.List[System.Numerics.BigInteger]]::new()
    $targetCapture = [System.Collections.Generic.List[System.Numerics.BigInteger]]::new()

    $actionPatched = [System.Numerics.BigInteger](dayTagWithFoundationScar -Day $Context.calculationDay -LegacyCapture $actionCapture)
    $targetPatched = [System.Numerics.BigInteger](dayTagWithFoundationScar -Day $Context.targetDay -LegacyCapture $targetCapture)

    if ($actionCapture.Count -ne 1 -or $targetCapture.Count -ne 1) {
        throw 'Dapat eksaktong isang raw legacy day tag ang makuha para sa action at target path.'
    }

    $actionLegacy = [System.Numerics.BigInteger]$actionCapture[0]
    $targetLegacy = [System.Numerics.BigInteger]$targetCapture[0]
    $guardSeen = (
        $Context.calculationDay -eq $script:Discovery02FoundationDay -or
        $Context.targetDay -eq $script:Discovery02FoundationDay
    )

    Start-BaseSemanticTransaction -Context $Context
    try {
        $Context.semanticPending['legacyActionDayTag'] = $actionLegacy
        $Context.semanticPending['legacyTargetDayTag'] = $targetLegacy
        $Context.semanticPending['patch02ActionDayTag'] = $actionPatched
        $Context.semanticPending['patch02TargetDayTag'] = $targetPatched
        $Context.semanticPending['patch02FoundationGuardSeen'] = [bool]$guardSeen

        Complete-BaseSemanticTransaction -Context $Context -Validator {
            param($pending)
            return (
                $pending.ContainsKey('legacyActionDayTag') -and
                $pending.ContainsKey('legacyTargetDayTag') -and
                $pending.ContainsKey('patch02ActionDayTag') -and
                $pending.ContainsKey('patch02TargetDayTag') -and
                $pending.ContainsKey('patch02FoundationGuardSeen') -and
                $pending['legacyActionDayTag'] -is [System.Numerics.BigInteger] -and
                $pending['legacyTargetDayTag'] -is [System.Numerics.BigInteger] -and
                $pending['patch02ActionDayTag'] -is [System.Numerics.BigInteger] -and
                $pending['patch02TargetDayTag'] -is [System.Numerics.BigInteger] -and
                $pending['patch02ActionDayTag'] -ge 1 -and
                $pending['patch02TargetDayTag'] -ge 1
            )
        }
    }
    catch {
        Undo-BaseSemanticTransaction -Context $Context
        throw
    }

    $Context.legacyActionDayTag = $actionLegacy
    $Context.legacyTargetDayTag = $targetLegacy
    $Context.discovery02Status = 'HISTORICAL_SCAR_CAPTURED'
    $Context.discovery02InvocationCount++

    $Context.patch02ActionDayTag = $actionPatched
    $Context.patch02TargetDayTag = $targetPatched
    $Context.patch02ActionApplied = $true
    $Context.patch02TargetApplied = $true
    $Context.patch02FoundationGuardSeen = [bool]$guardSeen
    $Context.patch02Status = 'DAY_TAG_PATCH_ACTIVE'
    $Context.patch02InvocationCount++

    Add-BaseMetric -Context $Context -Name 'patch02.dayTag.calls'
    Add-BaseLog -Context $Context -Code 'monster.patch02.daytag.adapter' -Data ([pscustomobject]@{
        actionLegacy = $actionLegacy
        actionPatched = $actionPatched
        targetLegacy = $targetLegacy
        targetPatched = $targetPatched
        foundationGuardSeen = [bool]$guardSeen
    })

    return $Context
}
