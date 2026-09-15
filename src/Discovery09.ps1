Set-StrictMode -Version Latest

$script:Discovery09BowlPrime = @(
    $null,
    17,
    19,
    23,
    29,
    31,
    37
)

function Get-Discovery09InitialBowlsThroughOldFactory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Counts
    )

    $bowls = [System.Numerics.BigInteger[]]::new(7)
    # Historical tuple semantics: slot 0 remains numeric zero.

    for ($bowlId = 1; $bowlId -le 6; $bowlId++) {
        $prime = [System.Numerics.BigInteger]$script:Discovery09BowlPrime[$bowlId]
        $temp = [System.Numerics.BigInteger](
            [System.Numerics.BigInteger]$Counts.action +
            [System.Numerics.BigInteger]$Counts.target * $bowlId +
            [System.Numerics.BigInteger]$Counts.distance +
            [System.Numerics.BigInteger]$Counts.connection +
            [System.Numerics.BigInteger]$Counts.direction +
            $prime * $prime
        )

        $bowls[$bowlId] = [System.Numerics.BigInteger](
            Get-Discovery04SavedValue -Value (
                $temp * $temp + $bowlId
            )
        )
    }

    return ,$bowls
}

function Get-Discovery09VisibleDropTableThroughCurrentLayers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context
    )

    Assert-BaseContextOwnership -Context $Context | Out-Null

    if ($null -eq $Context.legacyStoneTable) {
        throw 'Kailangang handa ang patched stone table bago gumawa ng visible drops.'
    }
    if ($null -eq $Context.legacyHiddenStorage) {
        throw 'Kailangang handa ang hidden storage bago gumawa ng visible drops.'
    }

    $counts = Get-Discovery05CountsFromContext -Context $Context
    $dropStore = @{}
    $visible = [object[]]::new(47)

    for ($i = 1; $i -le 46; $i++) {
        $prev1 = [System.Numerics.BigInteger](
            priorPatch `
                -DropStore $dropStore `
                -LegacyHidden $Context.legacyHiddenStorage `
                -I $i `
                -Back 1
        )
        $prev3 = [System.Numerics.BigInteger](
            priorPatch `
                -DropStore $dropStore `
                -LegacyHidden $Context.legacyHiddenStorage `
                -I $i `
                -Back 3
        )
        $prev7 = [System.Numerics.BigInteger](
            priorPatch `
                -DropStore $dropStore `
                -LegacyHidden $Context.legacyHiddenStorage `
                -I $i `
                -Back 7
        )

        $stoneRow = $Context.legacyStoneTable[$i]
        if ($null -eq $stoneRow) {
            throw "Walang stone row para sa visible drop i=$i."
        }

        $x = [System.Numerics.BigInteger](
            Get-Discovery04SavedValue -Value (
                [System.Numerics.BigInteger]$stoneRow[0] * [System.Numerics.BigInteger]$counts.action +
                [System.Numerics.BigInteger]$stoneRow[1] * [System.Numerics.BigInteger]$counts.target +
                [System.Numerics.BigInteger]$stoneRow[2] * [System.Numerics.BigInteger]$counts.distance +
                [System.Numerics.BigInteger]$stoneRow[3] * [System.Numerics.BigInteger]$counts.connection +
                [System.Numerics.BigInteger]$stoneRow[4] * [System.Numerics.BigInteger]$counts.direction +
                $prev1 +
                3 * $prev3 +
                5 * $prev7 +
                $i
            )
        )

        for ($grind = 1; $grind -le 11; $grind++) {
            $row = grindRowWithSentinel -Grind $grind
            $oldX = [System.Numerics.BigInteger]$x
            $kind = [int]$row.kind

            $x = [System.Numerics.BigInteger](
                Get-Discovery04SavedValue -Value (
                    $oldX * $oldX +
                    [System.Numerics.BigInteger]$row.a * $oldX +
                    [System.Numerics.BigInteger]$row.b * $prev1 +
                    [System.Numerics.BigInteger]$row.c * $prev3 +
                    [System.Numerics.BigInteger]$row.d * $prev7 +
                    [System.Numerics.BigInteger]$stoneRow[$kind]
                )
            )
        }

        $dropStore[$i] = [System.Numerics.BigInteger]$x
        $visible[$i] = [System.Numerics.BigInteger]$x
    }

    $Context.legacyVisibleDropTable = $visible
    $Context.legacyVisibleDropCount = 46

    Add-BaseMetric -Context $Context -Name 'discovery09.visibleDrop.supportBuilds'
    Add-BaseLog -Context $Context -Code 'monster.discovery09.visibleDrop.supportBuild' -Data ([pscustomobject]@{
        count = 46
        drop1 = $visible[1]
        drop2 = $visible[2]
        drop3 = $visible[3]
        drop46 = $visible[46]
    })

    return ,$visible
}

function legacyFixedBowlPours {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$I,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$Drop,
        [AllowNull()][Parameter(Mandatory)][System.Array]$Stones,
        [AllowNull()][Parameter(Mandatory)][System.Array]$OldBowls
    )

    if ($I -lt 1 -or $I -gt 46) {
        throw 'Ang visible drop index ay dapat nasa 1..46.'
    }
    if ($null -eq $Stones) {
        throw 'Hindi maaaring null ang stone table.'
    }
    if ($null -eq $OldBowls) {
        throw 'Hindi maaaring null ang old bowl table.'
    }
    if ($null -eq $Stones[$I]) {
        throw "Walang stone row para sa legacy pour i=$I."
    }

    $stoneRow = $Stones[$I]
    $pour = [System.Numerics.BigInteger[]]::new(7)
    # Historical tuple semantics: slots 0,4,5,6 remain numeric zero.

    # Historical defect: position 1,2,3 are mistaken for fixed bowl IDs 1,2,3.
    $pour[1] = [System.Numerics.BigInteger](
        Get-Discovery04SavedValue -Value (
            $Drop * $Drop +
            [System.Numerics.BigInteger]$stoneRow[0] * [System.Numerics.BigInteger]$OldBowls[1] +
            3 * $I
        )
    )
    $pour[2] = [System.Numerics.BigInteger](
        Get-Discovery04SavedValue -Value (
            $Drop * $Drop +
            [System.Numerics.BigInteger]$stoneRow[1] * [System.Numerics.BigInteger]$OldBowls[2] +
            5 * $I
        )
    )
    $pour[3] = [System.Numerics.BigInteger](
        Get-Discovery04SavedValue -Value (
            $Drop * $Drop +
            [System.Numerics.BigInteger]$stoneRow[2] * [System.Numerics.BigInteger]$OldBowls[3] +
            7 * $I
        )
    )

    return ,$pour
}

function Invoke-Discovery09LegacyPourAdapter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][int]$I
    )

    Assert-BaseContextOwnership -Context $Context | Out-Null

    if ($I -lt 1 -or $I -gt 46) {
        throw 'Ang visible drop index ay dapat nasa 1..46.'
    }
    if ($null -eq $Context.legacyStoneTable) {
        throw 'Kailangang handa ang stone table bago legacy pour access.'
    }
    if ($null -eq $Context.legacyVisibleDropTable) {
        throw 'Kailangang handa ang visible drops bago legacy pour access.'
    }
    if ($null -eq $Context.patch08OrderTable) {
        throw 'Kailangang handa ang corrected permutation order table bago legacy pour access.'
    }

    if ($null -eq $Context.legacyInitialBowls) {
        $counts = Get-Discovery05CountsFromContext -Context $Context
        $Context.legacyInitialBowls = Get-Discovery09InitialBowlsThroughOldFactory -Counts $counts
    }

    $drop = [System.Numerics.BigInteger]$Context.legacyVisibleDropTable[$I]
    $order = $Context.patch08OrderTable[$I]

    $pours = legacyFixedBowlPours `
        -I $I `
        -Drop $drop `
        -Stones $Context.legacyStoneTable `
        -OldBowls $Context.legacyInitialBowls

    Start-BaseSemanticTransaction -Context $Context
    try {
        $Context.semanticPending['legacyInitialBowls'] = $Context.legacyInitialBowls
        $Context.semanticPending['legacyPourLastDropIndex'] = $I
        $Context.semanticPending['legacyPourLastDropValue'] = $drop
        $Context.semanticPending['legacyPourLastOrder'] = $order
        $Context.semanticPending['legacyPourLastValues'] = $pours

        Complete-BaseSemanticTransaction -Context $Context -Validator {
            param($pending)
            return (
                $pending.ContainsKey('legacyInitialBowls') -and
                $pending.ContainsKey('legacyPourLastDropIndex') -and
                $pending.ContainsKey('legacyPourLastDropValue') -and
                $pending.ContainsKey('legacyPourLastOrder') -and
                $pending.ContainsKey('legacyPourLastValues') -and
                $pending['legacyInitialBowls'] -is [System.Array] -and
                $pending['legacyInitialBowls'].Count -eq 7 -and
                $pending['legacyPourLastDropIndex'] -ge 1 -and
                $pending['legacyPourLastDropIndex'] -le 46 -and
                $pending['legacyPourLastOrder'] -is [System.Array] -and
                $pending['legacyPourLastOrder'].Count -eq 6 -and
                $pending['legacyPourLastValues'] -is [System.Array] -and
                $pending['legacyPourLastValues'].Count -eq 7
            )
        }
    }
    catch {
        Undo-BaseSemanticTransaction -Context $Context
        throw
    }

    $Context.legacyPourLastDropIndex = $I
    $Context.legacyPourLastDropValue = $drop
    $Context.legacyPourLastOrder = $order
    $Context.legacyPourLastValues = $pours
    $Context.discovery09Status = 'FIXED_BOWL_ID_POURS_ACTIVE'
    $Context.discovery09InvocationCount++

    Add-BaseMetric -Context $Context -Name 'discovery09.fixedBowlPours.calls'
    Add-BaseLog -Context $Context -Code 'monster.discovery09.fixedBowlPours' -Data ([pscustomobject]@{
        i = $I
        drop = $drop
        order = $order
        fixedBowlIds = [int[]](1,2,3)
        pours = $pours
    })

    return ,$pours
}
