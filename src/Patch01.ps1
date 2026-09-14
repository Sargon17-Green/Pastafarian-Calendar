Set-StrictMode -Version Latest

function savePatch {
    [CmdletBinding()]
    param([Parameter(Mandatory)][System.Numerics.BigInteger]$LegacyRemainder)

    if ($LegacyRemainder -lt 0 -or $LegacyRemainder -ge $script:Discovery01M) {
        throw 'Ang input ng savePatch ay dapat isang legacy remainder sa saklaw na 0..M-1.'
    }

    if ($LegacyRemainder -eq 0) {
        return [System.Numerics.BigInteger]$script:Discovery01M
    }

    return [System.Numerics.BigInteger]$LegacyRemainder
}

function Invoke-Patch01SaveAdapter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$Value
    )

    Assert-BaseContextOwnership -Context $Context | Out-Null

    $legacy = [System.Numerics.BigInteger](oldRemainder -X $Value)
    $patched = [System.Numerics.BigInteger](savePatch -LegacyRemainder $legacy)

    Start-BaseSemanticTransaction -Context $Context
    try {
        $Context.semanticPending['legacyRemainderInput'] = [System.Numerics.BigInteger]$Value
        $Context.semanticPending['legacyRemainderValue'] = [System.Numerics.BigInteger]$legacy
        $Context.semanticPending['patch01PatchedValue'] = [System.Numerics.BigInteger]$patched

        Complete-BaseSemanticTransaction -Context $Context -Validator {
            param($pending)
            return (
                $pending.ContainsKey('legacyRemainderInput') -and
                $pending.ContainsKey('legacyRemainderValue') -and
                $pending.ContainsKey('patch01PatchedValue') -and
                $pending['legacyRemainderInput'] -is [System.Numerics.BigInteger] -and
                $pending['legacyRemainderValue'] -is [System.Numerics.BigInteger] -and
                $pending['patch01PatchedValue'] -is [System.Numerics.BigInteger] -and
                $pending['legacyRemainderValue'] -ge 0 -and
                $pending['legacyRemainderValue'] -lt $script:Discovery01M -and
                $pending['patch01PatchedValue'] -ge 1 -and
                $pending['patch01PatchedValue'] -le $script:Discovery01M
            )
        }
    }
    catch {
        Undo-BaseSemanticTransaction -Context $Context
        throw
    }

    $Context.legacyRemainderInput = [System.Numerics.BigInteger]$Value
    $Context.legacyRemainderValue = [System.Numerics.BigInteger]$legacy
    $Context.patch01PatchedValue = [System.Numerics.BigInteger]$patched
    $Context.patch01Status = 'SAVE_PATCH_ACTIVE'
    $Context.patch01InvocationCount++

    Add-BaseMetric -Context $Context -Name 'patch01.save.calls'
    Add-BaseLog -Context $Context -Code 'monster.patch01.save.adapter' -Data ([pscustomobject]@{
        input = [System.Numerics.BigInteger]$Value
        legacy = [System.Numerics.BigInteger]$legacy
        patched = [System.Numerics.BigInteger]$patched
    })

    return $Context
}
