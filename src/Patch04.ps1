Set-StrictMode -Version Latest

function stonePatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$I,
        [Parameter(Mandatory)][hashtable]$State,
        [System.Collections.Generic.List[object]]$TraceCapture = $null,
        [scriptblock]$LegacyMutator = {
            param($RowNumber, $LegacyState)
            return mutateStonesWrong -I $RowNumber -State $LegacyState
        }
    )

    $old = Copy-Discovery04StoneState -State $State

    # Mahalaga ang tunay na legacy call: tumatakbo ito sa HIWALAY na clone.
    $garbage = & $LegacyMutator $I (Copy-Discovery04StoneState -State $State)
    if ($garbage -isnot [hashtable]) {
        throw 'Dapat hashtable stone state ang ibalik ng legacy mutator.'
    }

    $legacyGarbage = Copy-Discovery04StoneState -State $garbage

    # Lahat ng limang overwrite ay bumabasa LAMANG sa old snapshot.
    $garbage['w'] = Get-Discovery04SavedValue (
        $old['w'] * $old['w'] +
        3 * $old['b'] +
        $I
    )

    $garbage['b'] = Get-Discovery04SavedValue (
        $old['b'] * $old['b'] +
        5 * $old['s'] +
        $old['w']
    )

    $garbage['s'] = Get-Discovery04SavedValue (
        $old['s'] * $old['s'] +
        7 * $old['m'] +
        $old['b']
    )

    $garbage['m'] = Get-Discovery04SavedValue (
        $old['m'] * $old['m'] +
        11 * $old['r'] +
        $old['s']
    )

    $garbage['r'] = Get-Discovery04SavedValue (
        $old['r'] * $old['r'] +
        13 * $old['w'] +
        $old['m']
    )

    if ($null -ne $TraceCapture) {
        $TraceCapture.Add([pscustomobject]@{
            rowNumber = $I
            oldSnapshot = Get-Discovery04StoneRow -State $old
            legacyGarbage = Get-Discovery04StoneRow -State $legacyGarbage
            committed = Get-Discovery04StoneRow -State (Copy-Discovery04StoneState -State $garbage)
        })
    }

    return $garbage
}

function Get-Patch04StoneTableThroughLegacyBuilder {
    [CmdletBinding()]
    param([System.Collections.Generic.List[object]]$TraceCapture = $null)

    $state = New-Discovery04StoneState
    $table = [object[]]::new(47)
    $table[1] = Get-Discovery04StoneRow -State (Copy-Discovery04StoneState -State $state)

    for ($i = 2; $i -le 46; $i++) {
        $state = stonePatch -I $i -State $state -TraceCapture $TraceCapture
        $table[$i] = Get-Discovery04StoneRow -State (Copy-Discovery04StoneState -State $state)
    }

    return ,$table
}

function Invoke-Patch04StoneAdapter {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Context)

    Assert-BaseContextOwnership -Context $Context | Out-Null

    $trace = [System.Collections.Generic.List[object]]::new()
    $table = Get-Patch04StoneTableThroughLegacyBuilder -TraceCapture $trace

    if ($trace.Count -ne 45) {
        throw "Dapat eksaktong 45 rows ang dumaan sa stonePatch; nakuha: $($trace.Count)."
    }

    $last = $trace[$trace.Count - 1]

    Start-BaseSemanticTransaction -Context $Context
    try {
        $Context.semanticPending['legacyStoneTable'] = $table
        $Context.semanticPending['legacyStoneRowsBuilt'] = 46
        $Context.semanticPending['patch04RowsPatched'] = 45
        $Context.semanticPending['patch04LastOldStones'] = $last.oldSnapshot
        $Context.semanticPending['patch04LastLegacyGarbage'] = $last.legacyGarbage
        $Context.semanticPending['patch04LastCommittedStones'] = $last.committed

        Complete-BaseSemanticTransaction -Context $Context -Validator {
            param($pending)
            return (
                $pending.ContainsKey('legacyStoneTable') -and
                $pending.ContainsKey('legacyStoneRowsBuilt') -and
                $pending.ContainsKey('patch04RowsPatched') -and
                $pending.ContainsKey('patch04LastOldStones') -and
                $pending.ContainsKey('patch04LastLegacyGarbage') -and
                $pending.ContainsKey('patch04LastCommittedStones') -and
                $pending['legacyStoneTable'] -is [System.Array] -and
                $pending['legacyStoneTable'].Count -eq 47 -and
                $pending['legacyStoneRowsBuilt'] -eq 46 -and
                $pending['patch04RowsPatched'] -eq 45 -and
                $pending['patch04LastOldStones'].Count -eq 5 -and
                $pending['patch04LastLegacyGarbage'].Count -eq 5 -and
                $pending['patch04LastCommittedStones'].Count -eq 5
            )
        }
    }
    catch {
        Undo-BaseSemanticTransaction -Context $Context
        throw
    }

    $Context.legacyStoneTable = $table
    $Context.legacyStoneRowsBuilt = 46
    $Context.discovery04Status = 'HISTORICAL_STONE_SCAR_CAPTURED'
    $Context.discovery04InvocationCount++

    $Context.patch04RowsPatched = 45
    $Context.patch04LastOldStones = $last.oldSnapshot
    $Context.patch04LastLegacyGarbage = $last.legacyGarbage
    $Context.patch04LastCommittedStones = $last.committed
    $Context.patch04Status = 'STONE_PATCH_ACTIVE'
    $Context.patch04InvocationCount++

    Add-BaseMetric -Context $Context -Name 'patch04.stone.rows' -Amount ([System.Numerics.BigInteger]45)
    Add-BaseLog -Context $Context -Code 'monster.patch04.stone.adapter' -Data ([pscustomobject]@{
        rowsPatched = 45
        lastOld = $last.oldSnapshot
        lastLegacyGarbage = $last.legacyGarbage
        lastCommitted = $last.committed
    })

    return $Context
}
