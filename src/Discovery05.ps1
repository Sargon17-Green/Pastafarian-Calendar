Set-StrictMode -Version Latest

$script:Discovery05LegacyCoeffReversed = @(
    $null,
    [int[]](15,22,30,32),
    [int[]](13,19,26,28),
    [int[]](11,16,22,24),
    [int[]](9,13,18,20),
    [int[]](7,10,14,16),
    [int[]](5,7,10,12),
    [int[]](3,4,6,8)
)

$script:Discovery05HiddenStoneKind = @(
    $null,
    0,
    1,
    2,
    3,
    4,
    0,
    1
)

function Get-Discovery05CoeffForHidden {
    [CmdletBinding()]
    param([Parameter(Mandatory)][int]$K)

    if ($K -lt 1 -or $K -gt 7) {
        throw 'Ang hidden-drop near-ness index ay dapat nasa 1..7.'
    }

    return ,([int[]]$script:Discovery05LegacyCoeffReversed[8 - $K])
}

function Get-Discovery05HiddenStoneKind {
    [CmdletBinding()]
    param([Parameter(Mandatory)][int]$Grind)

    if ($Grind -lt 1 -or $Grind -gt 7) {
        throw 'Ang hidden-drop grind index ay dapat nasa 1..7.'
    }

    return [int]$script:Discovery05HiddenStoneKind[$Grind]
}

function Get-Discovery05CountsFromContext {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Context)

    if ($null -eq $Context.patch02ActionDayTag) {
        throw 'Kailangang handa ang patched action day tag bago gumawa ng hidden drops.'
    }
    if ($null -eq $Context.patch02TargetDayTag) {
        throw 'Kailangang handa ang patched target day tag bago gumawa ng hidden drops.'
    }
    if ($null -eq $Context.patch03DistanceValue) {
        throw 'Kailangang handa ang patched distance bago gumawa ng hidden drops.'
    }

    $action = [System.Numerics.BigInteger]$Context.patch02ActionDayTag
    $target = [System.Numerics.BigInteger]$Context.patch02TargetDayTag
    $distance = [System.Numerics.BigInteger]$Context.patch03DistanceValue
    $connection = [System.Numerics.BigInteger]($action + $target)

    if ($Context.targetDay -lt $Context.calculationDay) {
        $direction = 1
    }
    elseif ($Context.targetDay -eq $Context.calculationDay) {
        $direction = 2
    }
    else {
        $direction = 3
    }

    return [pscustomobject]@{
        action = $action
        target = $target
        distance = $distance
        connection = $connection
        direction = $direction
    }
}

function Get-Discovery05HiddenValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$K,
        [Parameter(Mandatory)]$Counts,
        [Parameter(Mandatory)][System.Array]$Stones
    )

    if ($null -eq $Stones[$K]) {
        throw "Walang patched stone row para sa hidden drop k=$K."
    }

    $coeff = Get-Discovery05CoeffForHidden -K $K
    $row = $Stones[$K]

    $stoneSum = [System.Numerics.BigInteger]::Zero
    for ($i = 0; $i -lt 5; $i++) {
        $stoneSum += [System.Numerics.BigInteger]$row[$i]
    }

    $x = [System.Numerics.BigInteger](
        [System.Numerics.BigInteger]$Counts.action +
        [System.Numerics.BigInteger]$coeff[0] * [System.Numerics.BigInteger]$Counts.target +
        [System.Numerics.BigInteger]$coeff[1] * [System.Numerics.BigInteger]$Counts.distance +
        [System.Numerics.BigInteger]$coeff[2] * [System.Numerics.BigInteger]$Counts.connection +
        [System.Numerics.BigInteger]$coeff[3] * [System.Numerics.BigInteger]$Counts.direction +
        $stoneSum
    )
    $x = [System.Numerics.BigInteger](Get-Discovery04SavedValue -Value $x)

    for ($grind = 1; $grind -le 7; $grind++) {
        $beforeSquare = [System.Numerics.BigInteger]$x
        $stoneKind = Get-Discovery05HiddenStoneKind -Grind $grind
        $x = [System.Numerics.BigInteger](Get-Discovery04SavedValue -Value (
            $beforeSquare * $beforeSquare +
            3 * $beforeSquare +
            [System.Numerics.BigInteger]$row[$stoneKind] +
            $grind
        ))
    }

    return [System.Numerics.BigInteger]$x
}

function Get-Discovery05BackwardHiddenStorage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Counts,
        [Parameter(Mandatory)][System.Array]$Stones
    )

    $legacyHidden = [object[]]::new(8)

    for ($k = 1; $k -le 7; $k++) {
        $legacyHidden[8 - $k] = [System.Numerics.BigInteger](
            Get-Discovery05HiddenValue -K $k -Counts $Counts -Stones $Stones
        )
    }

    return ,$legacyHidden
}

function legacyHiddenDirectByAssumedNearness {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Array]$LegacyHidden,
        [Parameter(Mandatory)][int]$K
    )

    if ($K -lt 1 -or $K -gt 7) {
        throw 'Ang hidden-drop near-ness index ay dapat nasa 1..7.'
    }

    # Historical defect: backward physical storage is mistaken for near-ness order.
    return [System.Numerics.BigInteger]$LegacyHidden[$K]
}

function Invoke-Discovery05LegacyHiddenAdapter {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Context)

    Assert-BaseContextOwnership -Context $Context | Out-Null

    if ($null -eq $Context.legacyStoneTable) {
        throw 'Kailangang handa ang patched stone table bago gumawa ng hidden drops.'
    }

    $counts = Get-Discovery05CountsFromContext -Context $Context
    $storage = Get-Discovery05BackwardHiddenStorage -Counts $counts -Stones $Context.legacyStoneTable

    Start-BaseSemanticTransaction -Context $Context
    try {
        $Context.semanticPending['legacyHiddenStorage'] = $storage
        $Context.semanticPending['legacyHiddenCount'] = 7

        Complete-BaseSemanticTransaction -Context $Context -Validator {
            param($pending)
            return (
                $pending.ContainsKey('legacyHiddenStorage') -and
                $pending.ContainsKey('legacyHiddenCount') -and
                $pending['legacyHiddenStorage'] -is [System.Array] -and
                $pending['legacyHiddenStorage'].Count -eq 8 -and
                $pending['legacyHiddenCount'] -eq 7
            )
        }
    }
    catch {
        Undo-BaseSemanticTransaction -Context $Context
        throw
    }

    $Context.legacyHiddenStorage = $storage
    $Context.legacyHiddenCount = 7
    $Context.discovery05Status = 'BACKWARD_HIDDEN_STORAGE_ACTIVE'
    $Context.discovery05InvocationCount++

    Add-BaseMetric -Context $Context -Name 'discovery05.hidden.storage.builds'
    Add-BaseLog -Context $Context -Code 'monster.discovery05.hidden.storage' -Data ([pscustomobject]@{
        count = 7
        slot1 = $storage[1]
        slot4 = $storage[4]
        slot7 = $storage[7]
    })

    return $Context
}

function Read-Discovery05LegacyHiddenByAssumedNearness {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][int]$K
    )

    Assert-BaseContextOwnership -Context $Context | Out-Null

    if ($null -eq $Context.legacyHiddenStorage) {
        throw 'Kailangang mabuo muna ang backward hidden storage bago near-ness access.'
    }

    $value = [System.Numerics.BigInteger](
        legacyHiddenDirectByAssumedNearness -LegacyHidden $Context.legacyHiddenStorage -K $K
    )

    Start-BaseSemanticTransaction -Context $Context
    try {
        $Context.semanticPending['legacyHiddenLastRequestedK'] = $K
        $Context.semanticPending['legacyHiddenLastReturnedValue'] = $value

        Complete-BaseSemanticTransaction -Context $Context -Validator {
            param($pending)
            return (
                $pending.ContainsKey('legacyHiddenLastRequestedK') -and
                $pending.ContainsKey('legacyHiddenLastReturnedValue') -and
                $pending['legacyHiddenLastRequestedK'] -ge 1 -and
                $pending['legacyHiddenLastRequestedK'] -le 7 -and
                $pending['legacyHiddenLastReturnedValue'] -is [System.Numerics.BigInteger]
            )
        }
    }
    catch {
        Undo-BaseSemanticTransaction -Context $Context
        throw
    }

    $Context.legacyHiddenLastRequestedK = $K
    $Context.legacyHiddenLastReturnedValue = $value

    Add-BaseMetric -Context $Context -Name 'discovery05.hidden.directReads'
    Add-BaseLog -Context $Context -Code 'monster.discovery05.hidden.directRead' -Data ([pscustomobject]@{
        requestedK = $K
        returnedValue = $value
    })

    return [System.Numerics.BigInteger]$value
}
