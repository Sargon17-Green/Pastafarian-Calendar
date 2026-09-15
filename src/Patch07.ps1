Set-StrictMode -Version Latest

$script:SENTINEL_GRIND_ROW = [pscustomobject]@{
    a = 0
    b = 0
    c = 0
    d = 0
    kind = $null
    kindName = 'NONE'
}

$legacyVisibleGrindRows = Get-Discovery07LegacyVisibleGrindTable
$script:GRIND_TABLE_WITH_SENTINEL = [object[]]::new(12)
$script:GRIND_TABLE_WITH_SENTINEL[0] = $script:SENTINEL_GRIND_ROW
for ($i = 0; $i -lt 11; $i++) {
    $script:GRIND_TABLE_WITH_SENTINEL[$i + 1] = $legacyVisibleGrindRows[$i]
}

function Get-Patch07GrindTableWithSentinel {
    [CmdletBinding()]
    param()

    return ,$script:GRIND_TABLE_WITH_SENTINEL
}

function grindRowWithSentinel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$Grind
    )

    if ($Grind -lt 1 -or $Grind -gt 11) {
        throw 'Ang patched visible grind ordinal ay dapat nasa 1..11.'
    }

    return $script:GRIND_TABLE_WITH_SENTINEL[$Grind]
}

function Invoke-Patch07GrindRowRepair {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][int]$Grind
    )

    Assert-BaseContextOwnership -Context $Context | Out-Null

    if ($Grind -lt 1 -or $Grind -gt 11) {
        throw 'Ang Patch 07 grind ordinal ay dapat nasa 1..11.'
    }

    # Preserved scar execution: dumaan muna sa tunay na Stage 14 adapter.
    $rawLegacyRow = LegacyGrindTableAdapter -Context $Context -Grind $Grind

    # Authoritative Patch 07 result comes only after the raw scar call.
    $correctedRow = grindRowWithSentinel -Grind $Grind

    Start-BaseSemanticTransaction -Context $Context
    try {
        $Context.semanticPending['patch07RequestedGrind'] = $Grind
        $Context.semanticPending['patch07SentinelIndex'] = $Grind
        $Context.semanticPending['patch07RawLegacyRow'] = $rawLegacyRow
        $Context.semanticPending['patch07CorrectedRow'] = $correctedRow
        $Context.semanticPending['patch07Applied'] = $true

        Complete-BaseSemanticTransaction -Context $Context -Validator {
            param($pending)
            return (
                $pending.ContainsKey('patch07RequestedGrind') -and
                $pending.ContainsKey('patch07SentinelIndex') -and
                $pending.ContainsKey('patch07RawLegacyRow') -and
                $pending.ContainsKey('patch07CorrectedRow') -and
                $pending.ContainsKey('patch07Applied') -and
                $pending['patch07RequestedGrind'] -ge 1 -and
                $pending['patch07RequestedGrind'] -le 11 -and
                $pending['patch07SentinelIndex'] -eq $pending['patch07RequestedGrind'] -and
                $pending['patch07Applied'] -eq $true -and
                $null -ne $pending['patch07CorrectedRow']
            )
        }
    }
    catch {
        Undo-BaseSemanticTransaction -Context $Context
        throw
    }

    $Context.patch07RequestedGrind = $Grind
    $Context.patch07SentinelIndex = $Grind
    $Context.patch07RawLegacyRow = $rawLegacyRow
    $Context.patch07CorrectedRow = $correctedRow
    $Context.patch07Applied = $true
    $Context.patch07Status = 'SENTINEL_GRIND_PATCH_ACTIVE'
    $Context.patch07InvocationCount++

    Add-BaseMetric -Context $Context -Name 'patch07.grind.repairs'
    Add-BaseLog -Context $Context -Code 'monster.patch07.grindRowRepair' -Data ([pscustomobject]@{
        grind = $Grind
        sentinelIndex = $Grind
        rawLegacyRow = $rawLegacyRow
        correctedRow = $correctedRow
    })

    return $correctedRow
}
