Set-StrictMode -Version Latest

$script:MonsterSourceRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $script:MonsterSourceRoot 'Discovery01.ps1')
. (Join-Path $script:MonsterSourceRoot 'Patch01.ps1')
. (Join-Path $script:MonsterSourceRoot 'Discovery02.ps1')
. (Join-Path $script:MonsterSourceRoot 'Patch02.ps1')
. (Join-Path $script:MonsterSourceRoot 'Discovery03.ps1')
. (Join-Path $script:MonsterSourceRoot 'Patch03.ps1')
. (Join-Path $script:MonsterSourceRoot 'Discovery04.ps1')
. (Join-Path $script:MonsterSourceRoot 'Patch04.ps1')
. (Join-Path $script:MonsterSourceRoot 'Discovery05.ps1')
. (Join-Path $script:MonsterSourceRoot 'Patch05.ps1')
. (Join-Path $script:MonsterSourceRoot 'Discovery06.ps1')
. (Join-Path $script:MonsterSourceRoot 'Patch06.ps1')
. (Join-Path $script:MonsterSourceRoot 'Discovery07.ps1')
. (Join-Path $script:MonsterSourceRoot 'Patch07.ps1')
. (Join-Path $script:MonsterSourceRoot 'Discovery08.ps1')
. (Join-Path $script:MonsterSourceRoot 'Patch08.ps1')
. (Join-Path $script:MonsterSourceRoot 'Discovery09.ps1')
. (Join-Path $script:MonsterSourceRoot 'Patch09.ps1')
. (Join-Path $script:MonsterSourceRoot 'Discovery10.ps1')
. (Join-Path $script:MonsterSourceRoot 'Patch10.ps1')
. (Join-Path $script:MonsterSourceRoot 'Discovery11.ps1')

function New-BaseMonsterContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$CalculationDay,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$TargetDay
    )

    return [pscustomobject]@{
        calculationDay = $CalculationDay
        targetDay = $TargetDay
        phase = 'BOOT'
        subPhase = 0
        status = 'NEW'
        semanticCommitted = @{}
        semanticPending = $null
        rollbackSnapshot = $null
        logs = [System.Collections.Generic.List[object]]::new()
        metrics = @{}
        diagnostics = [System.Collections.Generic.List[object]]::new()
        validationFailures = [System.Collections.Generic.List[object]]::new()
        lastError = $null
        legacyRemainderInput = $null
        legacyRemainderValue = $null
        discovery01Status = 'HISTORICAL_SCAR_PRESENT'
        discovery01InvocationCount = 0
        patch01PatchedValue = $null
        patch01Status = 'NOT_RUN'
        patch01InvocationCount = 0
        legacyActionDayTag = $null
        legacyTargetDayTag = $null
        discovery02Status = 'HISTORICAL_SCAR_PRESENT'
        discovery02InvocationCount = 0
        patch02ActionDayTag = $null
        patch02TargetDayTag = $null
        patch02ActionApplied = $false
        patch02TargetApplied = $false
        patch02FoundationGuardSeen = $false
        patch02Status = 'NOT_RUN'
        patch02InvocationCount = 0
        legacyDistanceCalculationDay = $null
        legacyDistanceTargetDay = $null
        legacyDistanceValue = $null
        discovery03Status = 'HISTORICAL_SCAR_PRESENT'
        discovery03InvocationCount = 0
        patch03ChronologicalDistance = $null
        patch03DistanceValue = $null
        patch03LegacyReplaced = $false
        patch03Applied = $false
        patch03Status = 'NOT_RUN'
        patch03InvocationCount = 0
        legacyStoneTable = $null
        legacyStoneRowsBuilt = 0
        discovery04Status = 'HISTORICAL_SCAR_PRESENT'
        discovery04InvocationCount = 0
        patch04RowsPatched = 0
        patch04LastOldStones = $null
        patch04LastLegacyGarbage = $null
        patch04LastCommittedStones = $null
        patch04Status = 'NOT_RUN'
        patch04InvocationCount = 0
        legacyHiddenStorage = $null
        legacyHiddenCount = 0
        legacyHiddenLastRequestedK = $null
        legacyHiddenLastReturnedValue = $null
        discovery05Status = 'HISTORICAL_SCAR_PRESENT'
        discovery05InvocationCount = 0
        patch05RequestedK = $null
        patch05TranslatedSlot = $null
        patch05LegacyDirectValue = $null
        patch05CorrectedValue = $null
        patch05Applied = $false
        patch05Status = 'NOT_RUN'
        patch05InvocationCount = 0
        legacyPriorI = $null
        legacyPriorBack = $null
        legacyPriorSlot = $null
        legacyPriorValue = $null
        legacyPriorProbeValue = $null
        discovery06Status = 'HISTORICAL_SCAR_PRESENT'
        discovery06InvocationCount = 0
        patch06Slot = $null
        patch06UsedHidden = $false
        patch06HiddenK = $null
        patch06Value = $null
        patch06Applied = $false
        patch06Status = 'NOT_RUN'
        patch06InvocationCount = 0
        legacyGrindRequestedOrdinal = $null
        legacyGrindDirectIndex = $null
        legacyGrindRowValue = $null
        legacyGrindUndefined = $false
        legacyGrindProbeRow = $null
        discovery07Status = 'HISTORICAL_SCAR_PRESENT'
        discovery07InvocationCount = 0
        patch07RequestedGrind = $null
        patch07SentinelIndex = $null
        patch07RawLegacyRow = $null
        patch07CorrectedRow = $null
        patch07Applied = $false
        patch07Status = 'NOT_RUN'
        patch07InvocationCount = 0
        legacyPermutationDropValue = $null
        legacyPermutationOneBasedOrdinal = $null
        legacyPermutationRank0Input = $null
        legacyPermutationOrder = $null
        legacyPermutationUndefined = $false
        legacyPermutationProbeOrder = $null
        discovery08Status = 'HISTORICAL_SCAR_PRESENT'
        discovery08InvocationCount = 0
        patch08DropIndex = $null
        patch08DropValue = $null
        patch08OneBasedOrdinal = $null
        patch08LegacyRank0 = $null
        patch08LegacyWrongOrder = $null
        patch08LegacyWrongUndefined = $false
        patch08LegacyWrongError = $null
        patch08CorrectedOrder = $null
        patch08ProductionOrder = $null
        patch08OrderTable = $null
        patch08OrderCount = 0
        patch08Applied = $false
        patch08Status = 'NOT_RUN'
        patch08InvocationCount = 0
        legacyVisibleDropTable = $null
        legacyVisibleDropCount = 0
        legacyInitialBowls = $null
        legacyPourLastDropIndex = $null
        legacyPourLastDropValue = $null
        legacyPourLastOrder = $null
        legacyPourLastValues = $null
        legacyPourProbeValues = $null
        discovery09Status = 'HISTORICAL_SCAR_PRESENT'
        discovery09InvocationCount = 0
        patch09DropIndex = $null
        patch09BowlAlias = $null
        patch09LegacyFixedPours = $null
        patch09CorrectedPours = $null
        patch09ProductionPours = $null
        patch09Applied = $false
        patch09Status = 'NOT_RUN'
        patch09InvocationCount = 0
        legacyBowlUpdateLastDropIndex = $null
        legacyBowlUpdateLastInput = $null
        legacyBowlUpdateLastPours = $null
        legacyBowlUpdateLastOrder = $null
        legacyBowlUpdateLastDrop = $null
        legacyBowlUpdateLastResult = $null
        legacyBowlUpdateProductionResult = $null
        discovery10Status = 'HISTORICAL_SCAR_PRESENT'
        discovery10InvocationCount = 0
        patch10DropIndex = $null
        patch10VaultOld = $null
        patch10Pending = $null
        patch10LegacyWrongResult = $null
        patch10CorrectedResult = $null
        patch10ProductionResult = $null
        patch10CommitAfterSix = $false
        patch10Applied = $false
        patch10Status = 'NOT_RUN'
        patch10InvocationCount = 0
        legacyOverwritableOrderMemory = $null
        legacyOrderMemoryWriteCount = 0
        legacyOrderMemoryLastSource = $null
        legacyBowlsAfter46Drops = $null
        legacyPostStirLastSavedSum = $null
        legacyPostStirFinalBowls = $null
        legacyQueriedOrder = $null
        discovery11Status = 'HISTORICAL_SCAR_PRESENT'
        discovery11InvocationCount = 0
    }
}

function Add-BaseMetric {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][string]$Name,
        [System.Numerics.BigInteger]$Amount = [System.Numerics.BigInteger]::One
    )
    if (-not $Context.metrics.ContainsKey($Name)) {
        $Context.metrics[$Name] = [System.Numerics.BigInteger]::Zero
    }
    $Context.metrics[$Name] = [System.Numerics.BigInteger]$Context.metrics[$Name] + $Amount
}

function Add-BaseLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][string]$Code,
        [object]$Data = $null
    )
    $Context.logs.Add([pscustomobject]@{ code = $Code; data = $Data })
}

function New-BaseDispatcher {
    [CmdletBinding()]
    param()
    return [pscustomobject]@{ handlers = @{} }
}

function Register-BaseHandler {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Dispatcher,
        [Parameter(Mandatory)][string]$Phase,
        [Parameter(Mandatory)][scriptblock]$Handler
    )
    if ($Dispatcher.handlers.ContainsKey($Phase)) {
        throw "May nakarehistro nang handler para sa phase '$Phase'."
    }
    $Dispatcher.handlers[$Phase] = $Handler
}

function Invoke-BaseDispatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Dispatcher,
        [Parameter(Mandatory)]$Context
    )
    if (-not $Dispatcher.handlers.ContainsKey([string]$Context.phase)) {
        throw "Walang handler para sa phase '$($Context.phase)'."
    }
    return & $Dispatcher.handlers[[string]$Context.phase] $Context
}

function Assert-BaseContextOwnership {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Context)
    if ($null -eq $Context.semanticCommitted) {
        throw 'Walang committed semantic state ang invocation context.'
    }
    if ($Context.calculationDay -isnot [System.Numerics.BigInteger]) {
        throw 'Hindi eksaktong BigInteger ang calculationDay.'
    }
    if ($Context.targetDay -isnot [System.Numerics.BigInteger]) {
        throw 'Hindi eksaktong BigInteger ang targetDay.'
    }
    return $true
}

function Start-BaseSemanticTransaction {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Context)
    if ($null -ne $Context.semanticPending) {
        throw 'May bukas nang semantic transaction.'
    }
    $Context.rollbackSnapshot = @{} + $Context.semanticCommitted
    $Context.semanticPending = @{} + $Context.semanticCommitted
}

function Complete-BaseSemanticTransaction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][scriptblock]$Validator
    )
    if ($null -eq $Context.semanticPending) {
        throw 'Walang semantic transaction na maaaring i-commit.'
    }
    $ok = & $Validator $Context.semanticPending
    if ($ok -ne $true) {
        $Context.semanticPending = $null
        $Context.semanticCommitted = @{} + $Context.rollbackSnapshot
        $Context.rollbackSnapshot = $null
        throw 'Tinanggihan ng validator ang pending semantic state.'
    }
    $Context.semanticCommitted = @{} + $Context.semanticPending
    $Context.semanticPending = $null
    $Context.rollbackSnapshot = $null
}

function Undo-BaseSemanticTransaction {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Context)
    if ($null -ne $Context.rollbackSnapshot) {
        $Context.semanticCommitted = @{} + $Context.rollbackSnapshot
    }
    $Context.semanticPending = $null
    $Context.rollbackSnapshot = $null
}

function Wrap-BaseMonsterError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Exception]$Exception,
        [Parameter(Mandatory)][string]$Phase
    )
    return [System.InvalidOperationException]::new(
        "Nabigo ang monster base sa phase '$Phase': $($Exception.Message)",
        $Exception
    )
}

function Invoke-CalendarDateSpaghettiBootstrap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$CalculationDay,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$TargetDay
    )
    $ctx = New-BaseMonsterContext -CalculationDay $CalculationDay -TargetDay $TargetDay
    Add-BaseMetric -Context $ctx -Name 'bootstrap.calls'
    Add-BaseLog -Context $ctx -Code 'bootstrap-enter'
    Assert-BaseContextOwnership -Context $ctx | Out-Null
    throw 'Ang bootstrap entrypoint ay hindi calendar result path sa Stage 22.'
}

function Invoke-CalendarDateSpaghetti {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$CalculationDay,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$TargetDay
    )

    $ctx = New-BaseMonsterContext -CalculationDay $CalculationDay -TargetDay $TargetDay
    $ctx.phase = 'DISCOVERY11'
    $ctx.status = 'RUNNING'

    $dispatcher = New-BaseDispatcher
    Register-BaseHandler -Dispatcher $dispatcher -Phase 'DISCOVERY11' -Handler {
        param($Context)
        $withPatch01 = Invoke-Patch01SaveAdapter -Context $Context -Value $Context.calculationDay
        $withPatch02 = Invoke-Patch02DayTagAdapter -Context $withPatch01
        $withPatch03 = Invoke-Patch03DistanceAdapter -Context $withPatch02
        $withPatch04 = Invoke-Patch04StoneAdapter -Context $withPatch03
        $withDiscovery05 = Invoke-Discovery05LegacyHiddenAdapter -Context $withPatch04
        [void](Invoke-Patch05HiddenNearnessRepair -Context $withDiscovery05 -K 1)

        # Discovery 06 production probe: valid visible slot only.
        # It proves legacyPrior is on the real path but does not feed calendar semantics.
        $probeStore = @{
            1 = [System.Numerics.BigInteger]$withDiscovery05.patch05CorrectedValue
        }
        $withDiscovery05.legacyPriorProbeValue = Invoke-Patch06LegacyPriorAdapter `
            -Context $withDiscovery05 `
            -DropStore $probeStore `
            -I 2 `
            -Back 1

        Add-BaseMetric -Context $withDiscovery05 -Name 'patch06.prior.probes'
        Add-BaseLog -Context $withDiscovery05 -Code 'monster.patch06.productionProbe' -Data ([pscustomobject]@{
            i = 2
            back = 1
            slot = 1
            value = $withDiscovery05.legacyPriorProbeValue
        })

        # Patch 07 production probe: ang wrapper mismo ang talagang tumatawag
        # muna sa raw Stage 14 adapter bago magbalik ng corrected grind row.
        $withDiscovery05.legacyGrindProbeRow = Invoke-Patch07GrindRowRepair `
            -Context $withDiscovery05 `
            -Grind 1

        Add-BaseMetric -Context $withDiscovery05 -Name 'patch07.grind.probes'
        Add-BaseLog -Context $withDiscovery05 -Code 'monster.patch07.productionProbe' -Data ([pscustomobject]@{
            grind = 1
            sentinelIndex = 1
            rawLegacyRow = $withDiscovery05.patch07RawLegacyRow
            correctedRow = $withDiscovery05.legacyGrindProbeRow
        })

        # Patch 08 neutral production probe. Ang wrapper mismo ang talagang
        # nagpapatakbo muna sa raw Discovery 08 caller bago mag-correct.
        $withDiscovery05.patch08ProductionOrder = Invoke-Patch08PermutationRankRepair `
            -Context $withDiscovery05 `
            -DropIndex 1 `
            -DropValue ([System.Numerics.BigInteger]1)

        # Keep the raw Stage 16 production scar observable.
        $withDiscovery05.legacyPermutationProbeOrder = $withDiscovery05.patch08LegacyWrongOrder

        Add-BaseMetric -Context $withDiscovery05 -Name 'discovery08.permutation.probes'
        Add-BaseMetric -Context $withDiscovery05 -Name 'patch08.permutation.probes'
        Add-BaseLog -Context $withDiscovery05 -Code 'monster.patch08.productionProbe' -Data ([pscustomobject]@{
            dropIndex = 1
            dropValue = 1
            oneBasedOrdinal = $withDiscovery05.patch08OneBasedOrdinal
            legacyRank0 = $withDiscovery05.patch08LegacyRank0
            rawOrder = $withDiscovery05.patch08LegacyWrongOrder
            correctedOrder = $withDiscovery05.patch08ProductionOrder
        })

        # Stage 18 expands the real path to the full visible-drop/order plumbing.
        $withDiscovery05.legacyVisibleDropTable = Get-Discovery09VisibleDropTableThroughCurrentLayers `
            -Context $withDiscovery05

        $withDiscovery05.patch08OrderTable = Invoke-Patch08BuildOrderTable `
            -Context $withDiscovery05 `
            -VisibleDrops $withDiscovery05.legacyVisibleDropTable

        # Patch 09 production probe: talagang pinapatakbo muna ng wrapper ang
        # Discovery 09 fixed-bowl scar, saka ini-install ang order aliases.
        $withDiscovery05.patch09ProductionPours = Invoke-Patch09BowlAliasRepair `
            -Context $withDiscovery05 `
            -I 1

        # Panatilihing hiwalay at observable ang raw Discovery 09 predecessor scar.
        $withDiscovery05.legacyPourProbeValues = $withDiscovery05.patch09LegacyFixedPours

        Add-BaseMetric -Context $withDiscovery05 -Name 'discovery09.pour.probes'
        Add-BaseMetric -Context $withDiscovery05 -Name 'patch09.pour.probes'
        Add-BaseLog -Context $withDiscovery05 -Code 'monster.patch09.productionProbe' -Data ([pscustomobject]@{
            i = 1
            drop = $withDiscovery05.legacyPourLastDropValue
            order = $withDiscovery05.legacyPourLastOrder
            bowlAlias = $withDiscovery05.patch09BowlAlias
            legacyFixed = $withDiscovery05.patch09LegacyFixedPours
            corrected = $withDiscovery05.patch09ProductionPours
        })

        # Patch 10 production probe: the wrapper really executes the raw
        # Discovery 10 in-place scar first, then computes all six positions
        # from a frozen snapshot and commits the completed pending table.
        $withDiscovery05.patch10ProductionResult = Invoke-Patch10SnapshotBowlUpdateRepair `
            -Context $withDiscovery05 `
            -I 1 `
            -Bowls $withDiscovery05.legacyInitialBowls `
            -Pours $withDiscovery05.patch09ProductionPours

        # Keep the raw predecessor result separately observable.
        $withDiscovery05.legacyBowlUpdateProductionResult = $withDiscovery05.patch10LegacyWrongResult

        Add-BaseMetric -Context $withDiscovery05 -Name 'discovery10.bowlUpdate.probes'
        Add-BaseMetric -Context $withDiscovery05 -Name 'patch10.bowlUpdate.probes'
        Add-BaseLog -Context $withDiscovery05 -Code 'monster.patch10.productionProbe' -Data ([pscustomobject]@{
            i = 1
            drop = $withDiscovery05.legacyBowlUpdateLastDrop
            order = $withDiscovery05.legacyBowlUpdateLastOrder
            vaultOld = $withDiscovery05.patch10VaultOld
            legacyWrong = $withDiscovery05.patch10LegacyWrongResult
            pending = $withDiscovery05.patch10Pending
            corrected = $withDiscovery05.patch10ProductionResult
            commitAfterSix = $withDiscovery05.patch10CommitAfterSix
        })

        # Discovery 11 expands the real path through all 46 exact drop bowl
        # rounds and all 12 exact post-stir rounds. One general order memory
        # is intentionally reused and overwritten throughout the whole pass.
        [void](Invoke-Discovery11OverwritableOrderMemory -Context $withDiscovery05)

        $withDiscovery05.legacyQueriedOrder = Get-Discovery11LegacyQueriedOrder `
            -Context $withDiscovery05

        Add-BaseMetric -Context $withDiscovery05 -Name 'discovery11.orderMemory.queries'
        Add-BaseLog -Context $withDiscovery05 -Code 'monster.discovery11.productionQuery' -Data ([pscustomobject]@{
            writes = $withDiscovery05.legacyOrderMemoryWriteCount
            lastSourceKind = $withDiscovery05.legacyOrderMemoryLastSource.kind
            lastSourceIndex = $withDiscovery05.legacyOrderMemoryLastSource.index
            queriedOrder = $withDiscovery05.legacyQueriedOrder
            expectedDrop46Order = $withDiscovery05.patch08OrderTable[46]
        })

        return $withDiscovery05
    }

    Add-BaseMetric -Context $ctx -Name 'calendarDateSpaghetti.calls'
    Add-BaseLog -Context $ctx -Code 'monster.discovery11.dispatch'
    Assert-BaseContextOwnership -Context $ctx | Out-Null

    $result = Invoke-BaseDispatch -Dispatcher $dispatcher -Context $ctx
    $result.status = 'DISCOVERY11_COMPLETE'
    return $result
}
