Set-StrictMode -Version Latest

function hiddenByNearness {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowNull()][System.Array]$LegacyHidden,
        [Parameter(Mandatory)][int]$K
    )

    if ($null -eq $LegacyHidden) {
        throw 'Hindi maaaring null ang legacy hidden storage.'
    }
    if ($K -lt 1 -or $K -gt 7) {
        throw 'Ang hidden-drop near-ness index ay dapat nasa 1..7.'
    }

    return [System.Numerics.BigInteger]$LegacyHidden[8 - $K]
}

function Invoke-Patch05HiddenNearnessRepair {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][int]$K
    )

    Assert-BaseContextOwnership -Context $Context | Out-Null

    if ($null -eq $Context.legacyHiddenStorage) {
        throw 'Kailangang mabuo muna ang backward hidden storage bago ang Patch 05 near-ness access.'
    }
    if ($K -lt 1 -or $K -gt 7) {
        throw 'Ang Patch 05 near-ness index ay dapat nasa 1..7.'
    }

    # Hindi inaalis ang historical defect: talagang patakbuhin muna ang maling direct accessor.
    $legacyDirect = [System.Numerics.BigInteger](
        legacyHiddenDirectByAssumedNearness -LegacyHidden $Context.legacyHiddenStorage -K $K
    )

    $translatedSlot = 8 - $K
    $corrected = [System.Numerics.BigInteger](
        hiddenByNearness -LegacyHidden $Context.legacyHiddenStorage -K $K
    )

    Start-BaseSemanticTransaction -Context $Context
    try {
        $Context.semanticPending['legacyHiddenLastRequestedK'] = $K
        $Context.semanticPending['legacyHiddenLastReturnedValue'] = $corrected
        $Context.semanticPending['patch05RequestedK'] = $K
        $Context.semanticPending['patch05TranslatedSlot'] = $translatedSlot
        $Context.semanticPending['patch05LegacyDirectValue'] = $legacyDirect
        $Context.semanticPending['patch05CorrectedValue'] = $corrected
        $Context.semanticPending['patch05Applied'] = $true

        Complete-BaseSemanticTransaction -Context $Context -Validator {
            param($pending)
            return (
                $pending.ContainsKey('legacyHiddenLastRequestedK') -and
                $pending.ContainsKey('legacyHiddenLastReturnedValue') -and
                $pending.ContainsKey('patch05RequestedK') -and
                $pending.ContainsKey('patch05TranslatedSlot') -and
                $pending.ContainsKey('patch05LegacyDirectValue') -and
                $pending.ContainsKey('patch05CorrectedValue') -and
                $pending.ContainsKey('patch05Applied') -and
                $pending['patch05RequestedK'] -ge 1 -and
                $pending['patch05RequestedK'] -le 7 -and
                $pending['patch05TranslatedSlot'] -eq (8 - $pending['patch05RequestedK']) -and
                $pending['patch05LegacyDirectValue'] -is [System.Numerics.BigInteger] -and
                $pending['patch05CorrectedValue'] -is [System.Numerics.BigInteger] -and
                $pending['legacyHiddenLastReturnedValue'] -eq $pending['patch05CorrectedValue'] -and
                $pending['patch05Applied'] -eq $true
            )
        }
    }
    catch {
        Undo-BaseSemanticTransaction -Context $Context
        throw
    }

    $Context.legacyHiddenLastRequestedK = $K
    $Context.legacyHiddenLastReturnedValue = $corrected
    $Context.patch05RequestedK = $K
    $Context.patch05TranslatedSlot = $translatedSlot
    $Context.patch05LegacyDirectValue = $legacyDirect
    $Context.patch05CorrectedValue = $corrected
    $Context.patch05Applied = $true
    $Context.patch05Status = 'HIDDEN_NEARNESS_PATCH_ACTIVE'
    $Context.patch05InvocationCount++

    Add-BaseMetric -Context $Context -Name 'patch05.hidden.nearness.reads'
    Add-BaseLog -Context $Context -Code 'monster.patch05.hidden.nearness' -Data ([pscustomobject]@{
        requestedK = $K
        translatedSlot = $translatedSlot
        legacyDirectValue = $legacyDirect
        correctedValue = $corrected
    })

    return [System.Numerics.BigInteger]$corrected
}
