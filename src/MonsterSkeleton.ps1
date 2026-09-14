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
    throw 'Ang bootstrap entrypoint ay hindi calendar result path sa Stage 10.'
}

function Invoke-CalendarDateSpaghetti {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Numerics.BigInteger]$CalculationDay,
        [Parameter(Mandatory)][System.Numerics.BigInteger]$TargetDay
    )

    $ctx = New-BaseMonsterContext -CalculationDay $CalculationDay -TargetDay $TargetDay
    $ctx.phase = 'DISCOVERY05'
    $ctx.status = 'RUNNING'

    $dispatcher = New-BaseDispatcher
    Register-BaseHandler -Dispatcher $dispatcher -Phase 'DISCOVERY05' -Handler {
        param($Context)
        $withPatch01 = Invoke-Patch01SaveAdapter -Context $Context -Value $Context.calculationDay
        $withPatch02 = Invoke-Patch02DayTagAdapter -Context $withPatch01
        $withPatch03 = Invoke-Patch03DistanceAdapter -Context $withPatch02
        $withPatch04 = Invoke-Patch04StoneAdapter -Context $withPatch03
        $withDiscovery05 = Invoke-Discovery05LegacyHiddenAdapter -Context $withPatch04
        [void](Read-Discovery05LegacyHiddenByAssumedNearness -Context $withDiscovery05 -K 1)
        return $withDiscovery05
    }

    Add-BaseMetric -Context $ctx -Name 'calendarDateSpaghetti.calls'
    Add-BaseLog -Context $ctx -Code 'monster.discovery05.dispatch'
    Assert-BaseContextOwnership -Context $ctx | Out-Null

    $result = Invoke-BaseDispatch -Dispatcher $dispatcher -Context $ctx
    $result.status = 'DISCOVERY05_COMPLETE'
    return $result
}
