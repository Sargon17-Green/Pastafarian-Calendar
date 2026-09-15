Set-StrictMode -Version Latest

# Historical table: labing-isang totoong row lamang, pisikal na zero-based.
$script:LEGACY_VISIBLE_GRIND_TABLE_ZERO_BASED = [object[]]@(
    [pscustomobject]@{ a = 3;  b = 5;  c = 7;  d = 11; kind = 0; kindName = 'WHEAT'  },
    [pscustomobject]@{ a = 5;  b = 7;  c = 11; d = 13; kind = 1; kindName = 'BARLEY' },
    [pscustomobject]@{ a = 7;  b = 11; c = 13; d = 17; kind = 2; kindName = 'SALT'   },
    [pscustomobject]@{ a = 11; b = 13; c = 17; d = 19; kind = 3; kindName = 'BITTER' },
    [pscustomobject]@{ a = 13; b = 17; c = 19; d = 23; kind = 4; kindName = 'RED'    },
    [pscustomobject]@{ a = 17; b = 19; c = 23; d = 29; kind = 0; kindName = 'WHEAT'  },
    [pscustomobject]@{ a = 19; b = 23; c = 29; d = 31; kind = 1; kindName = 'BARLEY' },
    [pscustomobject]@{ a = 23; b = 29; c = 31; d = 37; kind = 2; kindName = 'SALT'   },
    [pscustomobject]@{ a = 29; b = 31; c = 37; d = 41; kind = 3; kindName = 'BITTER' },
    [pscustomobject]@{ a = 31; b = 37; c = 41; d = 43; kind = 4; kindName = 'RED'    },
    [pscustomobject]@{ a = 37; b = 41; c = 43; d = 47; kind = 0; kindName = 'WHEAT'  }
)

function Get-Discovery07LegacyVisibleGrindTable {
    [CmdletBinding()]
    param()

    # Ibabalik ang table reference bilang historical physical object.
    return ,$script:LEGACY_VISIBLE_GRIND_TABLE_ZERO_BASED
}

function legacyGrindRow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$Grind
    )

    if ($Grind -lt 1 -or $Grind -gt 11) {
        throw 'Ang legacy visible grind ordinal ay dapat nasa 1..11.'
    }

    # Historical defect:
    # one-based semantic ordinal ang Grind, ngunit direkta itong ginagamit
    # bilang zero-based physical index. Sa Grind=11, undefined ang access.
    try {
        return $script:LEGACY_VISIBLE_GRIND_TABLE_ZERO_BASED[$Grind]
    }
    catch [System.IndexOutOfRangeException] {
        return $null
    }
}

function Discovery07GrindIndexHandler {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][int]$Grind
    )

    Assert-BaseContextOwnership -Context $Context | Out-Null

    if ($Grind -lt 1 -or $Grind -gt 11) {
        throw 'Ang Discovery 07 grind ordinal ay dapat nasa 1..11.'
    }

    $directIndex = $Grind
    $row = legacyGrindRow -Grind $Grind
    $undefined = $null -eq $row

    Start-BaseSemanticTransaction -Context $Context
    try {
        $Context.semanticPending['legacyGrindRequestedOrdinal'] = $Grind
        $Context.semanticPending['legacyGrindDirectIndex'] = $directIndex
        $Context.semanticPending['legacyGrindRowValue'] = $row
        $Context.semanticPending['legacyGrindUndefined'] = $undefined

        Complete-BaseSemanticTransaction -Context $Context -Validator {
            param($pending)
            return (
                $pending.ContainsKey('legacyGrindRequestedOrdinal') -and
                $pending.ContainsKey('legacyGrindDirectIndex') -and
                $pending.ContainsKey('legacyGrindRowValue') -and
                $pending.ContainsKey('legacyGrindUndefined') -and
                $pending['legacyGrindRequestedOrdinal'] -ge 1 -and
                $pending['legacyGrindRequestedOrdinal'] -le 11 -and
                $pending['legacyGrindDirectIndex'] -eq $pending['legacyGrindRequestedOrdinal'] -and
                $pending['legacyGrindUndefined'] -eq ($null -eq $pending['legacyGrindRowValue'])
            )
        }
    }
    catch {
        Undo-BaseSemanticTransaction -Context $Context
        throw
    }

    $Context.legacyGrindRequestedOrdinal = $Grind
    $Context.legacyGrindDirectIndex = $directIndex
    $Context.legacyGrindRowValue = $row
    $Context.legacyGrindUndefined = $undefined
    $Context.discovery07Status = 'ZERO_BASED_DIRECT_ORDINAL_INDEX_ACTIVE'
    $Context.discovery07InvocationCount++

    Add-BaseMetric -Context $Context -Name 'discovery07.grind.row.reads'
    Add-BaseLog -Context $Context -Code 'monster.discovery07.legacyGrindRow' -Data ([pscustomobject]@{
        grind = $Grind
        directIndex = $directIndex
        undefined = $undefined
        row = $row
    })

    return $row
}

function LegacyGrindTableAdapter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][int]$Grind
    )

    return Discovery07GrindIndexHandler -Context $Context -Grind $Grind
}
