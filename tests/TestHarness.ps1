Set-StrictMode -Version Latest

$script:StageTestPassed = 0
$script:StageTestFailed = 0

function Assert-StageTrue {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Name)
    if ($Condition) {
        $script:StageTestPassed++
        Write-Host "PASS: $Name"
        return
    }
    $script:StageTestFailed++
    Write-Host "FAIL: $Name"
}

function Assert-StageEqual {
    param([Parameter(Mandatory)]$Expected, [Parameter(Mandatory)]$Actual, [Parameter(Mandatory)][string]$Name)
    Assert-StageTrue -Condition ($Expected -eq $Actual) -Name $Name
}

function Assert-StageSequenceEqual {
    param([Parameter(Mandatory)]$Expected, [Parameter(Mandatory)]$Actual, [Parameter(Mandatory)][string]$Name)
    if ($Expected.Count -ne $Actual.Count) {
        Assert-StageTrue -Condition $false -Name $Name
        return
    }
    for ($i = 0; $i -lt $Expected.Count; $i++) {
        if ($Expected[$i] -ne $Actual[$i]) {
            Assert-StageTrue -Condition $false -Name $Name
            return
        }
    }
    Assert-StageTrue -Condition $true -Name $Name
}

function Complete-StageTestRun {
    if ($script:StageTestFailed -eq 0) {
        Write-Host "STAGE01_TESTS_PASSED=$script:StageTestPassed"
        Write-Host 'STAGE01_RESULT=PASS'
        return $true
    }
    Write-Host "STAGE01_TESTS_PASSED=$script:StageTestPassed"
    Write-Host "STAGE01_TESTS_FAILED=$script:StageTestFailed"
    Write-Host 'STAGE01_RESULT=FAIL'
    return $false
}
