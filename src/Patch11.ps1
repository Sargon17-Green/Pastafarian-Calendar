Set-StrictMode -Version Latest

function Invoke-Patch11OrderAt46Latch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][int]$DropIndex,
        [AllowNull()][Parameter(Mandatory)][System.Array]$Order
    )
    Assert-BaseContextOwnership -Context $Context | Out-Null
    if ($DropIndex -ne 46 -or $Context.legacyOrderMemoryWriteCount -ne 46) {
        throw 'Ang latch ay maaari lamang sa ika-46 na drop write.'
    }
    if ($null -eq $Context.legacyOrderMemoryLastSource -or
        $Context.legacyOrderMemoryLastSource.kind -ne 'drop' -or
        $Context.legacyOrderMemoryLastSource.index -ne 46) {
        throw 'Ang order memory ay hindi mula sa drop 46.'
    }
    if ($null -eq $Order -or $Order.Count -ne 6) {
        throw 'Ang drop-46 order ay dapat may anim na positions.'
    }
    $latched = Copy-Discovery11Order -Order $Order
    Start-BaseSemanticTransaction -Context $Context
    try {
        $Context.semanticPending['orderAt46Latch'] = $latched
        $Context.semanticPending['patch11CapturedAtWrite'] = 46
        Complete-BaseSemanticTransaction -Context $Context -Validator {
            param($pending)
            return ($pending.ContainsKey('orderAt46Latch') -and
                $pending['orderAt46Latch'] -is [System.Array] -and
                $pending['orderAt46Latch'].Count -eq 6 -and
                $pending['patch11CapturedAtWrite'] -eq 46)
        }
    }
    catch {
        Undo-BaseSemanticTransaction -Context $Context
        throw
    }
    $Context.orderAt46Latch = $latched
    $Context.patch11CapturedAtWrite = 46
    $Context.patch11Applied = $true
    $Context.patch11Status = 'DROP46_ORDER_LATCH_ACTIVE'
    $Context.patch11InvocationCount++
    Add-BaseMetric -Context $Context -Name 'patch11.drop46.latches'
    Add-BaseLog -Context $Context -Code 'monster.patch11.drop46Latched' -Data ([pscustomobject]@{
        dropIndex = 46
        writeIndex = 46
        order = (Copy-Discovery11Order -Order $latched)
    })
}

function Get-Patch11OrderAt46 {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Context)
    Assert-BaseContextOwnership -Context $Context | Out-Null
    if (-not $Context.patch11Applied -or $null -eq $Context.orderAt46Latch -or
        $Context.orderAt46Latch.Count -ne 6) {
        throw 'Hindi pa nakukuha ang drop-46 order latch.'
    }
    # Keep the old wrong semantic query physically callable and observable.
    $Context.patch11LegacyQueriedOrder = Copy-Discovery11Order -Order (
        Get-Discovery11LegacyQueriedOrder -Context $Context
    )
    return ,(Copy-Discovery11Order -Order $Context.orderAt46Latch)
}
