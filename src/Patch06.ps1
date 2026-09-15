Set-StrictMode -Version Latest

function priorPatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][hashtable]$DropStore,
        [Parameter(Mandatory)][AllowNull()][System.Array]$LegacyHidden,
        [Parameter(Mandatory)][int]$I,
        [Parameter(Mandatory)][int]$Back
    )

    if ($null -eq $DropStore) {
        throw 'Hindi maaaring null ang visible drop store.'
    }
    if ($Back -lt 1) {
        throw 'Ang history distance ay dapat hindi bababa sa isa.'
    }

    $slot = $I - $Back

    if ($slot -ge 1) {
        return legacyPrior -DropStore $DropStore -I $I -Back $Back
    }

    if ($null -eq $LegacyHidden) {
        throw 'Kailangang handa ang hidden-drop storage bago ang nonpositive history access.'
    }

    $hiddenK = 1 - $slot
    return hiddenByNearness -LegacyHidden $LegacyHidden -K $hiddenK
}

function Invoke-Patch06LegacyPriorAdapter {
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

    # Preserve the Stage 12 coordinates before the patched read.
    $Context.legacyPriorI = $I
    $Context.legacyPriorBack = $Back
    $Context.legacyPriorSlot = $slot
    $Context.legacyPriorValue = $null

    $result = priorPatch `
        -DropStore $DropStore `
        -LegacyHidden $Context.legacyHiddenStorage `
        -I $I `
        -Back $Back

    $usedHidden = $slot -le 0
    $hiddenK = if ($usedHidden) { 1 - $slot } else { $null }

    Start-BaseSemanticTransaction -Context $Context
    try {
        $Context.semanticPending['legacyPriorI'] = $I
        $Context.semanticPending['legacyPriorBack'] = $Back
        $Context.semanticPending['legacyPriorSlot'] = $slot
        $Context.semanticPending['legacyPriorValue'] = $result
        $Context.semanticPending['patch06Slot'] = $slot
        $Context.semanticPending['patch06UsedHidden'] = $usedHidden
        $Context.semanticPending['patch06HiddenK'] = $hiddenK
        $Context.semanticPending['patch06Value'] = $result
        $Context.semanticPending['patch06Applied'] = $true

        Complete-BaseSemanticTransaction -Context $Context -Validator {
            param($pending)

            if (-not (
                $pending.ContainsKey('legacyPriorI') -and
                $pending.ContainsKey('legacyPriorBack') -and
                $pending.ContainsKey('legacyPriorSlot') -and
                $pending.ContainsKey('legacyPriorValue') -and
                $pending.ContainsKey('patch06Slot') -and
                $pending.ContainsKey('patch06UsedHidden') -and
                $pending.ContainsKey('patch06HiddenK') -and
                $pending.ContainsKey('patch06Value') -and
                $pending.ContainsKey('patch06Applied')
            )) {
                return $false
            }

            if ($pending['patch06Slot'] -ne (
                $pending['legacyPriorI'] - $pending['legacyPriorBack']
            )) {
                return $false
            }

            if ($pending['patch06UsedHidden']) {
                if ($pending['patch06HiddenK'] -ne (1 - $pending['patch06Slot'])) {
                    return $false
                }
            }
            else {
                if ($null -ne $pending['patch06HiddenK']) {
                    return $false
                }
            }

            return (
                $pending['legacyPriorValue'] -eq $pending['patch06Value'] -and
                $pending['patch06Applied'] -eq $true
            )
        }
    }
    catch {
        Undo-BaseSemanticTransaction -Context $Context
        throw
    }

    $Context.legacyPriorValue = $result
    $Context.discovery06Status = 'VISIBLE_ONLY_PRIOR_SCAR_PRESERVED'
    $Context.discovery06InvocationCount++
    $Context.patch06Slot = $slot
    $Context.patch06UsedHidden = $usedHidden
    $Context.patch06HiddenK = $hiddenK
    $Context.patch06Value = $result
    $Context.patch06Applied = $true
    $Context.patch06Status = 'PRIOR_PATCH_ACTIVE'
    $Context.patch06InvocationCount++

    Add-BaseMetric -Context $Context -Name 'discovery06.prior.reads'
    Add-BaseMetric -Context $Context -Name 'patch06.prior.repairs'
    Add-BaseLog -Context $Context -Code 'monster.patch06.prior' -Data ([pscustomobject]@{
        i = $I
        back = $Back
        slot = $slot
        usedHidden = $usedHidden
        hiddenK = $hiddenK
        value = $result
    })

    return $result
}
