Set-StrictMode -Version Latest

$script:Patch10BowlStirStoneByPosition = [int[]](0,1,2,3,4,0)

function snapshotBowlUpdatePatched {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$I,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$Drop,
        [AllowNull()][Parameter(Mandatory)][System.Array]$Order,
        [AllowNull()][Parameter(Mandatory)][System.Array]$Pours,
        [AllowNull()][Parameter(Mandatory)][System.Array]$Stones,
        [AllowNull()][Parameter(Mandatory)][System.Array]$Bowls
    )

    if ($I -lt 1 -or $I -gt 46) {
        throw 'Ang visible drop index ay dapat nasa 1..46.'
    }
    if ($null -eq $Order -or $Order.Count -ne 6) {
        throw 'Ang bowl order ay dapat may eksaktong anim na positions.'
    }
    if ($null -eq $Pours -or $Pours.Count -lt 7) {
        throw 'Kailangan ang 1-based pour table na may positions 1..6.'
    }
    if ($null -eq $Stones -or $null -eq $Stones[$I]) {
        throw "Walang stone row para sa snapshot bowl update i=$I."
    }
    if ($null -eq $Bowls -or $Bowls.Count -lt 7) {
        throw 'Kailangan ang 1-based bowl table na may slots 1..6.'
    }

    # Patch 10 core: clone once, then never read from pending during this drop.
    $vaultOld = [System.Numerics.BigInteger[]]::new(7)
    for ($copyId = 1; $copyId -le 6; $copyId++) {
        $vaultOld[$copyId] = [System.Numerics.BigInteger]$Bowls[$copyId]
    }

    $pending = [System.Numerics.BigInteger[]]::new(7)

    for ($position = 1; $position -le 6; $position++) {
        $bowlId = [int]$Order[$position - 1]
        $prevId = [int]$Order[(($position - 2 + 6) % 6)]
        $nextId = [int]$Order[($position % 6)]
        $kind = [int]$script:Patch10BowlStirStoneByPosition[$position - 1]

        $s = [System.Numerics.BigInteger](
            [System.Numerics.BigInteger]$vaultOld[$bowlId] +
            2 * [System.Numerics.BigInteger]$vaultOld[$prevId] +
            3 * [System.Numerics.BigInteger]$vaultOld[$nextId] +
            [System.Numerics.BigInteger]$Pours[$position] +
            $Drop +
            [System.Numerics.BigInteger]$Stones[$I][$kind]
        )

        $pending[$bowlId] = [System.Numerics.BigInteger](
            Get-Discovery04SavedValue -Value (
                $s * $s +
                5 * [System.Numerics.BigInteger]$vaultOld[$prevId] *
                    [System.Numerics.BigInteger]$vaultOld[$nextId] +
                $I * $position
            )
        )
    }

    # Commit is represented by returning the completed six-position pending table.
    return ,$pending
}

function Invoke-Patch10SnapshotBowlUpdateRepair {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][int]$I,
        [AllowNull()][Parameter(Mandatory)][System.Array]$Bowls,
        [AllowNull()][Parameter(Mandatory)][System.Array]$Pours
    )

    Assert-BaseContextOwnership -Context $Context | Out-Null

    if ($I -lt 1 -or $I -gt 46) {
        throw 'Ang visible drop index ay dapat nasa 1..46.'
    }
    if ($null -eq $Context.legacyStoneTable) {
        throw 'Kailangang handa ang stone table bago Patch 10.'
    }
    if ($null -eq $Context.legacyVisibleDropTable) {
        throw 'Kailangang handa ang visible drops bago Patch 10.'
    }
    if ($null -eq $Context.patch08OrderTable) {
        throw 'Kailangang handa ang corrected permutation orders bago Patch 10.'
    }

    $drop = [System.Numerics.BigInteger]$Context.legacyVisibleDropTable[$I]
    $order = $Context.patch08OrderTable[$I]

    # Discovery 10 scar remains physical and really executes first.
    $legacyWrong = legacyInPlaceBowlUpdateWrong `
        -I $I `
        -Drop $drop `
        -Order $order `
        -Pours $Pours `
        -Stones $Context.legacyStoneTable `
        -Bowls $Bowls

    # Physical clone exposed as vaultOld for the patch record.
    $vaultOld = [System.Numerics.BigInteger[]]::new(7)
    for ($copyId = 1; $copyId -le 6; $copyId++) {
        $vaultOld[$copyId] = [System.Numerics.BigInteger]$Bowls[$copyId]
    }

    $corrected = snapshotBowlUpdatePatched `
        -I $I `
        -Drop $drop `
        -Order $order `
        -Pours $Pours `
        -Stones $Context.legacyStoneTable `
        -Bowls $Bowls

    $pending = $corrected

    Start-BaseSemanticTransaction -Context $Context
    try {
        $Context.semanticPending['legacyBowlUpdateLastDropIndex'] = $I
        $Context.semanticPending['legacyBowlUpdateLastInput'] = $Bowls
        $Context.semanticPending['legacyBowlUpdateLastPours'] = $Pours
        $Context.semanticPending['legacyBowlUpdateLastOrder'] = $order
        $Context.semanticPending['legacyBowlUpdateLastDrop'] = $drop
        $Context.semanticPending['legacyBowlUpdateLastResult'] = $corrected
        $Context.semanticPending['patch10DropIndex'] = $I
        $Context.semanticPending['patch10VaultOld'] = $vaultOld
        $Context.semanticPending['patch10Pending'] = $pending
        $Context.semanticPending['patch10LegacyWrongResult'] = $legacyWrong
        $Context.semanticPending['patch10CorrectedResult'] = $corrected
        $Context.semanticPending['patch10CommitAfterSix'] = $true
        $Context.semanticPending['patch10Applied'] = $true

        Complete-BaseSemanticTransaction -Context $Context -Validator {
            param($pendingState)
            return (
                $pendingState.ContainsKey('legacyBowlUpdateLastDropIndex') -and
                $pendingState.ContainsKey('legacyBowlUpdateLastResult') -and
                $pendingState.ContainsKey('patch10DropIndex') -and
                $pendingState.ContainsKey('patch10VaultOld') -and
                $pendingState.ContainsKey('patch10Pending') -and
                $pendingState.ContainsKey('patch10LegacyWrongResult') -and
                $pendingState.ContainsKey('patch10CorrectedResult') -and
                $pendingState.ContainsKey('patch10CommitAfterSix') -and
                $pendingState.ContainsKey('patch10Applied') -and
                $pendingState['patch10DropIndex'] -ge 1 -and
                $pendingState['patch10DropIndex'] -le 46 -and
                $pendingState['patch10VaultOld'] -is [System.Array] -and
                $pendingState['patch10VaultOld'].Count -eq 7 -and
                $pendingState['patch10Pending'] -is [System.Array] -and
                $pendingState['patch10Pending'].Count -eq 7 -and
                $pendingState['patch10LegacyWrongResult'] -is [System.Array] -and
                $pendingState['patch10CorrectedResult'] -is [System.Array] -and
                $pendingState['patch10CommitAfterSix'] -eq $true -and
                $pendingState['patch10Applied'] -eq $true
            )
        }
    }
    catch {
        Undo-BaseSemanticTransaction -Context $Context
        throw
    }

    # Preserve the predecessor scar as separately observable state.
    $Context.discovery10Status = 'IN_PLACE_BOWL_UPDATE_CONTAMINATION_PRESERVED'
    $Context.discovery10InvocationCount++

    $Context.legacyBowlUpdateLastDropIndex = $I
    $Context.legacyBowlUpdateLastInput = $Bowls
    $Context.legacyBowlUpdateLastPours = $Pours
    $Context.legacyBowlUpdateLastOrder = $order
    $Context.legacyBowlUpdateLastDrop = $drop
    $Context.legacyBowlUpdateLastResult = $corrected

    $Context.patch10DropIndex = $I
    $Context.patch10VaultOld = $vaultOld
    $Context.patch10Pending = $pending
    $Context.patch10LegacyWrongResult = $legacyWrong
    $Context.patch10CorrectedResult = $corrected
    $Context.patch10CommitAfterSix = $true
    $Context.patch10Applied = $true
    $Context.patch10Status = 'SNAPSHOT_BOWL_UPDATE_PATCH_ACTIVE'
    $Context.patch10InvocationCount++

    Add-BaseMetric -Context $Context -Name 'discovery10.inPlaceBowlUpdate.calls'
    Add-BaseMetric -Context $Context -Name 'patch10.snapshotBowlUpdate.repairs'
    Add-BaseLog -Context $Context -Code 'monster.patch10.snapshotBowlUpdateRepair' -Data ([pscustomobject]@{
        i = $I
        drop = $drop
        order = $order
        vaultOld = $vaultOld
        legacyWrong = $legacyWrong
        pending = $pending
        corrected = $corrected
        commitAfterSix = $true
    })

    return ,$corrected
}
