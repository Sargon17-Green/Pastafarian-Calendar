Set-StrictMode -Version Latest

$script:Discovery01M = [System.Numerics.BigInteger]::Parse('170141183460469231731687303715884105727')

function Get-Discovery01RegularMod {
    [CmdletBinding()]
    param([Parameter(Mandatory)][System.Numerics.BigInteger]$X)

    $r = $X % $script:Discovery01M
    if ($r -lt 0) {
        $r += $script:Discovery01M
    }
    return [System.Numerics.BigInteger]$r
}

function oldRemainder {
    [CmdletBinding()]
    param([Parameter(Mandatory)][System.Numerics.BigInteger]$X)

    return [System.Numerics.BigInteger](Get-Discovery01RegularMod -X $X)
}

function Invoke-Discovery01LegacyAdapter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$Value
    )

    Assert-BaseContextOwnership -Context $Context | Out-Null

    $legacy = [System.Numerics.BigInteger](oldRemainder -X $Value)

    Start-BaseSemanticTransaction -Context $Context
    try {
        $Context.semanticPending['legacyRemainderInput'] = [System.Numerics.BigInteger]$Value
        $Context.semanticPending['legacyRemainderValue'] = [System.Numerics.BigInteger]$legacy

        Complete-BaseSemanticTransaction -Context $Context -Validator {
            param($pending)
            return (
                $pending.ContainsKey('legacyRemainderInput') -and
                $pending.ContainsKey('legacyRemainderValue') -and
                $pending['legacyRemainderInput'] -is [System.Numerics.BigInteger] -and
                $pending['legacyRemainderValue'] -is [System.Numerics.BigInteger]
            )
        }
    }
    catch {
        Undo-BaseSemanticTransaction -Context $Context
        throw
    }

    $Context.legacyRemainderInput = [System.Numerics.BigInteger]$Value
    $Context.legacyRemainderValue = [System.Numerics.BigInteger]$legacy
    $Context.discovery01Status = 'LEGACY_REMAINDER_ACTIVE'
    $Context.discovery01InvocationCount++

    Add-BaseMetric -Context $Context -Name 'discovery01.legacyRemainder.calls'
    Add-BaseLog -Context $Context -Code 'monster.discovery01.legacy.adapter' -Data ([pscustomobject]@{
        input = [System.Numerics.BigInteger]$Value
        result = [System.Numerics.BigInteger]$legacy
    })

    return $Context
}
