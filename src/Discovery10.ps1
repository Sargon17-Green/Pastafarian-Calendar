Set-StrictMode -Version Latest

$script:Discovery10BowlStirStoneByPosition = [int[]](0,1,2,3,4,0)

function legacyInPlaceBowlUpdateWrong {
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
        throw "Walang stone row para sa legacy bowl update i=$I."
    }
    if ($null -eq $Bowls -or $Bowls.Count -lt 7) {
        throw 'Kailangan ang 1-based bowl table na may slots 1..6.'
    }

    # Historical defect: all reads and writes share this same working storage.
    $working = [object[]]::new(7)
    for ($bowlIdCopy = 1; $bowlIdCopy -le 6; $bowlIdCopy++) {
        $working[$bowlIdCopy] = [System.Numerics.BigInteger]$Bowls[$bowlIdCopy]
    }

    for ($position = 1; $position -le 6; $position++) {
        $bowlId = [int]$Order[$position - 1]
        $prevId = [int]$Order[(($position - 2 + 6) % 6)]
        $nextId = [int]$Order[($position % 6)]
        $kind = [int]$script:Discovery10BowlStirStoneByPosition[$position - 1]

        $s = [System.Numerics.BigInteger](
            [System.Numerics.BigInteger]$working[$bowlId] +
            2 * [System.Numerics.BigInteger]$working[$prevId] +
            3 * [System.Numerics.BigInteger]$working[$nextId] +
            [System.Numerics.BigInteger]$Pours[$position] +
            $Drop +
            [System.Numerics.BigInteger]$Stones[$I][$kind]
        )

        $working[$bowlId] = [System.Numerics.BigInteger](
            Get-Discovery04SavedValue -Value (
                $s * $s +
                5 * [System.Numerics.BigInteger]$working[$prevId] *
                    [System.Numerics.BigInteger]$working[$nextId] +
                $I * $position
            )
        )
    }

    return ,$working
}

function Invoke-Discovery10LegacyBowlUpdateAdapter {
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
        throw 'Kailangang handa ang stone table bago bowl update.'
    }
    if ($null -eq $Context.legacyVisibleDropTable) {
        throw 'Kailangang handa ang visible drops bago bowl update.'
    }
    if ($null -eq $Context.patch08OrderTable) {
        throw 'Kailangang handa ang corrected permutation orders bago bowl update.'
    }

    $drop = [System.Numerics.BigInteger]$Context.legacyVisibleDropTable[$I]
    $order = $Context.patch08OrderTable[$I]

    $result = legacyInPlaceBowlUpdateWrong `
        -I $I `
        -Drop $drop `
        -Order $order `
        -Pours $Pours `
        -Stones $Context.legacyStoneTable `
        -Bowls $Bowls

    Start-BaseSemanticTransaction -Context $Context
    try {
        $Context.semanticPending['legacyBowlUpdateLastDropIndex'] = $I
        $Context.semanticPending['legacyBowlUpdateLastInput'] = $Bowls
        $Context.semanticPending['legacyBowlUpdateLastPours'] = $Pours
        $Context.semanticPending['legacyBowlUpdateLastOrder'] = $order
        $Context.semanticPending['legacyBowlUpdateLastDrop'] = $drop
        $Context.semanticPending['legacyBowlUpdateLastResult'] = $result

        Complete-BaseSemanticTransaction -Context $Context -Validator {
            param($pending)
            return (
                $pending.ContainsKey('legacyBowlUpdateLastDropIndex') -and
                $pending.ContainsKey('legacyBowlUpdateLastInput') -and
                $pending.ContainsKey('legacyBowlUpdateLastPours') -and
                $pending.ContainsKey('legacyBowlUpdateLastOrder') -and
                $pending.ContainsKey('legacyBowlUpdateLastDrop') -and
                $pending.ContainsKey('legacyBowlUpdateLastResult') -and
                $pending['legacyBowlUpdateLastDropIndex'] -ge 1 -and
                $pending['legacyBowlUpdateLastDropIndex'] -le 46 -and
                $pending['legacyBowlUpdateLastInput'] -is [System.Array] -and
                $pending['legacyBowlUpdateLastPours'] -is [System.Array] -and
                $pending['legacyBowlUpdateLastOrder'] -is [System.Array] -and
                $pending['legacyBowlUpdateLastResult'] -is [System.Array]
            )
        }
    }
    catch {
        Undo-BaseSemanticTransaction -Context $Context
        throw
    }

    $Context.legacyBowlUpdateLastDropIndex = $I
    $Context.legacyBowlUpdateLastInput = $Bowls
    $Context.legacyBowlUpdateLastPours = $Pours
    $Context.legacyBowlUpdateLastOrder = $order
    $Context.legacyBowlUpdateLastDrop = $drop
    $Context.legacyBowlUpdateLastResult = $result
    $Context.discovery10Status = 'IN_PLACE_BOWL_UPDATE_CONTAMINATION_ACTIVE'
    $Context.discovery10InvocationCount++

    Add-BaseMetric -Context $Context -Name 'discovery10.inPlaceBowlUpdate.calls'
    Add-BaseLog -Context $Context -Code 'monster.discovery10.inPlaceBowlUpdate' -Data ([pscustomobject]@{
        i = $I
        drop = $drop
        order = $order
        result = $result
    })

    return ,$result
}
