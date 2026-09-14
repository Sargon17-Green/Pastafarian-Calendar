Set-StrictMode -Version Latest

function New-Discovery04StoneState {
    [CmdletBinding()]
    param()

    return @{
        w = [System.Numerics.BigInteger]17
        b = [System.Numerics.BigInteger]29
        s = [System.Numerics.BigInteger]43
        m = [System.Numerics.BigInteger]71
        r = [System.Numerics.BigInteger]101
    }
}

function Copy-Discovery04StoneState {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$State)

    return @{
        w = [System.Numerics.BigInteger]$State['w']
        b = [System.Numerics.BigInteger]$State['b']
        s = [System.Numerics.BigInteger]$State['s']
        m = [System.Numerics.BigInteger]$State['m']
        r = [System.Numerics.BigInteger]$State['r']
    }
}

function Get-Discovery04StoneRow {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$State)

    $row = [object[]]::new(5)
    $row[0] = [System.Numerics.BigInteger]$State['w']
    $row[1] = [System.Numerics.BigInteger]$State['b']
    $row[2] = [System.Numerics.BigInteger]$State['s']
    $row[3] = [System.Numerics.BigInteger]$State['m']
    $row[4] = [System.Numerics.BigInteger]$State['r']
    return ,$row
}

function Get-Discovery04SavedValue {
    [CmdletBinding()]
    param([Parameter(Mandatory)][System.Numerics.BigInteger]$Value)

    $legacy = [System.Numerics.BigInteger](oldRemainder -X $Value)
    return [System.Numerics.BigInteger](savePatch -LegacyRemainder $legacy)
}

function mutateStonesWrong {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$I,
        [Parameter(Mandatory)][hashtable]$State
    )

    $State['w'] = Get-Discovery04SavedValue (
        $State['w'] * $State['w'] +
        3 * $State['b'] +
        $I
    )

    $State['b'] = Get-Discovery04SavedValue (
        $State['b'] * $State['b'] +
        5 * $State['s'] +
        $State['w']
    )

    $State['s'] = Get-Discovery04SavedValue (
        $State['s'] * $State['s'] +
        7 * $State['m'] +
        $State['b']
    )

    $State['m'] = Get-Discovery04SavedValue (
        $State['m'] * $State['m'] +
        11 * $State['r'] +
        $State['s']
    )

    $State['r'] = Get-Discovery04SavedValue (
        $State['r'] * $State['r'] +
        13 * $State['w'] +
        $State['m']
    )

    return $State
}

function Get-Discovery04LegacyStoneTable {
    [CmdletBinding()]
    param()

    $state = New-Discovery04StoneState
    $table = [object[]]::new(47)
    $table[1] = Get-Discovery04StoneRow -State (Copy-Discovery04StoneState -State $state)

    for ($i = 2; $i -le 46; $i++) {
        $state = mutateStonesWrong -I $i -State $state
        $table[$i] = Get-Discovery04StoneRow -State (Copy-Discovery04StoneState -State $state)
    }

    return ,$table
}

function Invoke-Discovery04LegacyStoneAdapter {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Context)

    Assert-BaseContextOwnership -Context $Context | Out-Null

    $table = Get-Discovery04LegacyStoneTable

    Start-BaseSemanticTransaction -Context $Context
    try {
        $Context.semanticPending['legacyStoneTable'] = $table
        $Context.semanticPending['legacyStoneRowsBuilt'] = 46

        Complete-BaseSemanticTransaction -Context $Context -Validator {
            param($pending)
            return (
                $pending.ContainsKey('legacyStoneTable') -and
                $pending.ContainsKey('legacyStoneRowsBuilt') -and
                $pending['legacyStoneTable'] -is [System.Array] -and
                $pending['legacyStoneTable'].Count -eq 47 -and
                $pending['legacyStoneRowsBuilt'] -eq 46
            )
        }
    }
    catch {
        Undo-BaseSemanticTransaction -Context $Context
        throw
    }

    $Context.legacyStoneTable = $table
    $Context.legacyStoneRowsBuilt = 46
    $Context.discovery04Status = 'LEGACY_STONE_MUTATION_ACTIVE'
    $Context.discovery04InvocationCount++

    Add-BaseMetric -Context $Context -Name 'discovery04.legacyStoneTable.builds'
    Add-BaseLog -Context $Context -Code 'monster.discovery04.legacyStone.adapter' -Data ([pscustomobject]@{
        rowsBuilt = 46
        row2 = $table[2]
        row46 = $table[46]
    })

    return $Context
}
