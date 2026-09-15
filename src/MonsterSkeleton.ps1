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
    throw 'Ang bootstrap entrypoint ay hindi calendar result path sa Stage 17.'
}

function Invoke-CalendarDateSpaghetti {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$CalculationDay,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$TargetDay
    )

    $ctx = New-BaseMonsterContext -CalculationDay $CalculationDay -TargetDay $TargetDay
    $ctx.phase = 'PATCH08'
    $ctx.status = 'RUNNING'

    $dispatcher = New-BaseDispatcher
    Register-BaseHandler -Dispatcher $dispatcher -Phase 'PATCH08' -Handler {
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

        return $withDiscovery05
    }

    Add-BaseMetric -Context $ctx -Name 'calendarDateSpaghetti.calls'
    Add-BaseLog -Context $ctx -Code 'monster.patch08.dispatch'
    Assert-BaseContextOwnership -Context $ctx | Out-Null

    $result = Invoke-BaseDispatch -Dispatcher $dispatcher -Context $ctx
    $result.status = 'PATCH08_COMPLETE'
    return $result
}
