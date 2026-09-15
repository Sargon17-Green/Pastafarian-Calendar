Set-StrictMode -Version Latest

function installOrderAliases {
    [CmdletBinding()]
    param(
        [AllowNull()][Parameter(Mandatory)][System.Array]$Order
    )

    if ($null -eq $Order -or $Order.Count -ne 6) {
        throw 'Ang bowl order ay dapat may eksaktong anim na positions.'
    }

    $alias = [object[]]::new(7)
    $alias[0] = 0

    for ($position = 1; $position -le 6; $position++) {
        $bowlId = [int]$Order[$position - 1]
        if ($bowlId -lt 1 -or $bowlId -gt 6) {
            throw "Hindi wastong bowl ID sa order position $position."
        }
        $alias[$position] = $bowlId
    }

    return ,$alias
}

function bowlByLegacyPosition {
    [CmdletBinding()]
    param(
        [AllowNull()][Parameter(Mandatory)][System.Array]$OldBowls,
        [AllowNull()][Parameter(Mandatory)][System.Array]$BowlAlias,
        [Parameter(Mandatory)][int]$Position
    )

    if ($Position -lt 1 -or $Position -gt 6) {
        throw 'Ang legacy bowl position ay dapat nasa 1..6.'
    }
    if ($null -eq $OldBowls -or $OldBowls.Count -lt 7) {
        throw 'Kailangan ang 1-based old bowl table na may slots 1..6.'
    }
    if ($null -eq $BowlAlias -or $BowlAlias.Count -lt 7) {
        throw 'Kailangan ang 1-based bowl alias table na may positions 1..6.'
    }

    $bowlId = [int]$BowlAlias[$Position]
    if ($bowlId -lt 1 -or $bowlId -gt 6) {
        throw "Hindi wastong aliased bowl ID para sa position $Position."
    }

    return [System.Numerics.BigInteger]$OldBowls[$bowlId]
}

function aliasedPositionPours {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$I,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$Drop,
        [AllowNull()][Parameter(Mandatory)][System.Array]$Stones,
        [AllowNull()][Parameter(Mandatory)][System.Array]$OldBowls,
        [AllowNull()][Parameter(Mandatory)][System.Array]$BowlAlias
    )

    if ($I -lt 1 -or $I -gt 46) {
        throw 'Ang visible drop index ay dapat nasa 1..46.'
    }
    if ($null -eq $Stones -or $null -eq $Stones[$I]) {
        throw "Walang stone row para sa aliased pour i=$I."
    }

    $stoneRow = $Stones[$I]
    $pour = [System.Numerics.BigInteger[]]::new(7)
    # Historical tuple semantics: slots 0,4,5,6 remain numeric zero.

    $pour[1] = [System.Numerics.BigInteger](
        Get-Discovery04SavedValue -Value (
            $Drop * $Drop +
            [System.Numerics.BigInteger]$stoneRow[0] *
                (bowlByLegacyPosition -OldBowls $OldBowls -BowlAlias $BowlAlias -Position 1) +
            3 * $I
        )
    )
    $pour[2] = [System.Numerics.BigInteger](
        Get-Discovery04SavedValue -Value (
            $Drop * $Drop +
            [System.Numerics.BigInteger]$stoneRow[1] *
                (bowlByLegacyPosition -OldBowls $OldBowls -BowlAlias $BowlAlias -Position 2) +
            5 * $I
        )
    )
    $pour[3] = [System.Numerics.BigInteger](
        Get-Discovery04SavedValue -Value (
            $Drop * $Drop +
            [System.Numerics.BigInteger]$stoneRow[2] *
                (bowlByLegacyPosition -OldBowls $OldBowls -BowlAlias $BowlAlias -Position 3) +
            7 * $I
        )
    )

    return ,$pour
}

function Invoke-Patch09BowlAliasRepairWithBowls {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][int]$I,
        [AllowNull()][Parameter(Mandatory)][System.Array]$OldBowls
    )

    Assert-BaseContextOwnership -Context $Context | Out-Null

    if ($I -lt 1 -or $I -gt 46) {
        throw 'Ang visible drop index ay dapat nasa 1..46.'
    }
    if ($null -eq $Context.legacyStoneTable) {
        throw 'Kailangang handa ang stone table bago Patch 09.'
    }
    if ($null -eq $Context.legacyVisibleDropTable) {
        throw 'Kailangang handa ang visible drops bago Patch 09.'
    }
    if ($null -eq $Context.patch08OrderTable) {
        throw 'Kailangang handa ang corrected permutation order table bago Patch 09.'
    }
    if ($null -eq $OldBowls -or $OldBowls.Count -lt 7) {
        throw 'Kailangan ang current 1-based bowl table na may slots 1..6.'
    }

    $drop = [System.Numerics.BigInteger]$Context.legacyVisibleDropTable[$I]
    $order = $Context.patch08OrderTable[$I]

    # Preserved Discovery 09 scar: run the fixed bowl-ID predecessor on the
    # actual bowls entering this drop, exactly as the historical call_with_bowls path did.
    $legacyFixed = legacyFixedBowlPours `
        -I $I `
        -Drop $drop `
        -Stones $Context.legacyStoneTable `
        -OldBowls $OldBowls

    $bowlAlias = installOrderAliases -Order $order

    $corrected = aliasedPositionPours `
        -I $I `
        -Drop $drop `
        -Stones $Context.legacyStoneTable `
        -OldBowls $OldBowls `
        -BowlAlias $bowlAlias

    Start-BaseSemanticTransaction -Context $Context
    try {
        $Context.semanticPending['legacyInitialBowls'] = $Context.legacyInitialBowls
        $Context.semanticPending['legacyPourLastDropIndex'] = $I
        $Context.semanticPending['legacyPourLastDropValue'] = $drop
        $Context.semanticPending['legacyPourLastOrder'] = $order
        $Context.semanticPending['legacyPourLastValues'] = $corrected
        $Context.semanticPending['patch09DropIndex'] = $I
        $Context.semanticPending['patch09BowlAlias'] = $bowlAlias
        $Context.semanticPending['patch09LegacyFixedPours'] = $legacyFixed
        $Context.semanticPending['patch09CorrectedPours'] = $corrected
        $Context.semanticPending['patch09Applied'] = $true

        Complete-BaseSemanticTransaction -Context $Context -Validator {
            param($pending)
            return (
                $pending.ContainsKey('legacyInitialBowls') -and
                $pending.ContainsKey('legacyPourLastDropIndex') -and
                $pending.ContainsKey('legacyPourLastDropValue') -and
                $pending.ContainsKey('legacyPourLastOrder') -and
                $pending.ContainsKey('legacyPourLastValues') -and
                $pending.ContainsKey('patch09DropIndex') -and
                $pending.ContainsKey('patch09BowlAlias') -and
                $pending.ContainsKey('patch09LegacyFixedPours') -and
                $pending.ContainsKey('patch09CorrectedPours') -and
                $pending.ContainsKey('patch09Applied') -and
                $pending['patch09DropIndex'] -ge 1 -and
                $pending['patch09DropIndex'] -le 46 -and
                $pending['patch09BowlAlias'] -is [System.Array] -and
                $pending['patch09BowlAlias'].Count -eq 7 -and
                $pending['patch09LegacyFixedPours'] -is [System.Array] -and
                $pending['patch09LegacyFixedPours'].Count -eq 7 -and
                $pending['patch09CorrectedPours'] -is [System.Array] -and
                $pending['patch09CorrectedPours'].Count -eq 7 -and
                $pending['patch09Applied'] -eq $true
            )
        }
    }
    catch {
        Undo-BaseSemanticTransaction -Context $Context
        throw
    }

    $Context.discovery09Status = 'FIXED_BOWL_ID_POURS_ACTIVE'
    $Context.discovery09InvocationCount++
    $Context.legacyPourLastDropIndex = $I
    $Context.legacyPourLastDropValue = $drop
    $Context.legacyPourLastOrder = $order
    $Context.legacyPourLastValues = $corrected

    $Context.patch09DropIndex = $I
    $Context.patch09BowlAlias = $bowlAlias
    $Context.patch09LegacyFixedPours = $legacyFixed
    $Context.patch09CorrectedPours = $corrected
    $Context.patch09Applied = $true
    $Context.patch09Status = 'BOWL_ALIAS_PATCH_ACTIVE'
    $Context.patch09InvocationCount++

    Add-BaseMetric -Context $Context -Name 'discovery09.fixedBowlPours.calls'
    Add-BaseMetric -Context $Context -Name 'patch09.bowlAlias.repairs'
    Add-BaseLog -Context $Context -Code 'monster.patch09.bowlAliasRepair' -Data ([pscustomobject]@{
        i = $I
        drop = $drop
        order = $order
        bowlAlias = $bowlAlias
        legacyFixed = $legacyFixed
        corrected = $corrected
    })

    return ,$corrected
}

function Invoke-Patch09BowlAliasRepair {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][int]$I
    )

    Assert-BaseContextOwnership -Context $Context | Out-Null

    if ($null -eq $Context.legacyInitialBowls) {
        $counts = Get-Discovery05CountsFromContext -Context $Context
        $Context.legacyInitialBowls = Get-Discovery09InitialBowlsThroughOldFactory -Counts $counts
    }

    return ,(Invoke-Patch09BowlAliasRepairWithBowls `
        -Context $Context `
        -I $I `
        -OldBowls $Context.legacyInitialBowls)
}
