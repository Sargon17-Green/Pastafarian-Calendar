Set-StrictMode -Version Latest

function legacyPrior {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][hashtable]$DropStore,
        [Parameter(Mandatory)][int]$I,
        [Parameter(Mandatory)][int]$Back
    )

    if ($null -eq $DropStore) {
        throw 'Hindi maaaring null ang visible drop store.'
    }
    if ($Back -lt 1) {
        throw 'Ang history distance ay dapat hindi bababa sa isa.'
    }

    # Historical defect: visible store lamang ang alam nito.
    return $DropStore[$I - $Back]
}

function Invoke-Discovery06LegacyPriorAdapter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][AllowEmptyCollection()][hashtable]$DropStore,
        [Parameter(Mandatory)][int]$I,
        [Parameter(Mandatory)][int]$Back
    )

    Assert-BaseContextOwnership -Context $Context | Out-Null

    if ($null -eq $DropStore) {
        throw 'Hindi maaaring null ang visible drop store.'
    }
    if ($I -lt 1) {
        throw 'Ang visible drop index ay dapat hindi bababa sa isa.'
    }
    if ($Back -lt 1) {
        throw 'Ang history distance ay dapat hindi bababa sa isa.'
    }

    $slot = $I - $Back

    # Historical state is set before the lookup so a missing hidden-history slot
    # remains visible in the invocation context.
    $Context.legacyPriorI = $I
    $Context.legacyPriorBack = $Back
    $Context.legacyPriorSlot = $slot
    $Context.legacyPriorValue = $null

    $value = legacyPrior -DropStore $DropStore -I $I -Back $Back

    Start-BaseSemanticTransaction -Context $Context
    try {
        $Context.semanticPending['legacyPriorI'] = $I
        $Context.semanticPending['legacyPriorBack'] = $Back
        $Context.semanticPending['legacyPriorSlot'] = $slot
        $Context.semanticPending['legacyPriorValue'] = $value

        Complete-BaseSemanticTransaction -Context $Context -Validator {
            param($pending)
            return (
                $pending.ContainsKey('legacyPriorI') -and
                $pending.ContainsKey('legacyPriorBack') -and
                $pending.ContainsKey('legacyPriorSlot') -and
                $pending.ContainsKey('legacyPriorValue') -and
                $pending['legacyPriorI'] -ge 1 -and
                $pending['legacyPriorBack'] -ge 1 -and
                $pending['legacyPriorSlot'] -eq (
                    $pending['legacyPriorI'] - $pending['legacyPriorBack']
                )
            )
        }
    }
    catch {
        Undo-BaseSemanticTransaction -Context $Context
        throw
    }

    $Context.legacyPriorValue = $value
    $Context.discovery06Status = 'VISIBLE_ONLY_PRIOR_ACTIVE'
    $Context.discovery06InvocationCount++

    Add-BaseMetric -Context $Context -Name 'discovery06.prior.reads'
    Add-BaseLog -Context $Context -Code 'monster.discovery06.legacyPrior' -Data ([pscustomobject]@{
        i = $I
        back = $Back
        slot = $slot
        value = $value
    })

    return $value
}
