Set-StrictMode -Version Latest

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

    return [pscustomobject]@{
        handlers = @{}
    }
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

    # Wala pang normative production path sa Bootstrap. Sadyang hindi ito tumatawag sa oracle.
    $ctx = New-BaseMonsterContext -CalculationDay $CalculationDay -TargetDay $TargetDay
    Add-BaseMetric -Context $ctx -Name 'bootstrap.calls'
    Add-BaseLog -Context $ctx -Code 'bootstrap-enter'
    Assert-BaseContextOwnership -Context $ctx | Out-Null
    throw 'Hindi pa umiiral ang authoritative spaghetti calendar path sa Stage 1.'
}
