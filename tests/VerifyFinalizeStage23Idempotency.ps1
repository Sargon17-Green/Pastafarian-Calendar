# Stage 23 PATCH 11: native Windows PowerShell 5.1 idempotency evidence.
# This runner does not finalize a new stage or modify repository files.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$expectedBranch = 'PowerShell+Tagalog'
$expectedBaseHead = '7e895d374962dbc57a68035eef02f76a365af440'
$finalizer = Join-Path $root 'tests/FinalizeStage23.ps1'
$stageFile = Join-Path $root 'DEVELOPMENT_STAGE.md'
$downloads = Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Downloads'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$evidence = Join-Path $downloads ("Stage23-Finalize-Idempotency-" + $stamp)
New-Item -ItemType Directory -Path $evidence -Force | Out-Null
$summary = Join-Path $evidence 'summary.txt'

function Write-Evidence {
    param([string]$Message)
    Add-Content -LiteralPath $summary -Value $Message -Encoding UTF8
    Write-Host $Message
}
function Invoke-GitSafe {
    param([string[]]$GitArguments)
    $lines = @(& git.exe -C $root @GitArguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw ("git " + ($GitArguments -join ' ') + " failed: " + ($lines -join '; ')) }
    return $lines
}
function Test-CleanCheckout {
    $changes = @(Invoke-GitSafe -GitArguments @('status','--porcelain=v1','--untracked-files=all'))
    if ($changes.Count -ne 0) {
        throw ("Checkout changed: " + ($changes -join '; '))
    }
}

$passed = $false
try {
    Write-Evidence "TEST=STAGE23_FINALIZE_IDEMPOTENCY"
    Write-Evidence ("TIME_UTC=" + (Get-Date).ToUniversalTime().ToString('o'))
    Write-Evidence ("LOG_DIR=" + $evidence)
    Write-Evidence ("ROOT=" + $root)
    Write-Evidence ("PS_VERSION=" + $PSVersionTable.PSVersion.ToString())
    if ($PSVersionTable.PSVersion.Major -ne 5 -or $PSVersionTable.PSVersion.Minor -ne 1) {
        throw 'Required runtime is Windows PowerShell 5.1.'
    }
    if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) { throw 'git.exe is unavailable.' }
    if (-not (Test-Path -LiteralPath $finalizer -PathType Leaf)) { throw 'Finalizer missing.' }
    if (-not (Test-Path -LiteralPath $stageFile -PathType Leaf)) { throw 'Stage metadata missing.' }

    $branch = ((Invoke-GitSafe -GitArguments @('branch','--show-current')) -join '').Trim()
    $head = ((Invoke-GitSafe -GitArguments @('rev-parse','HEAD')) -join '').Trim()
    Write-Evidence ("BRANCH=" + $branch)
    Write-Evidence ("HEAD=" + $head)
    Write-Evidence ("KNOWN_PATCH11_HEAD=" + $expectedBaseHead)
    if ($branch -cne $expectedBranch) { throw 'Wrong branch.' }
    # HEAD may advance only through a recorded Stage23 QA-only commit.
    # The script never resets or mutates HEAD.
    Test-CleanCheckout

    $lines = @(Get-Content -LiteralPath $stageFile -Encoding UTF8)
    if (-not (($lines -contains 'LAST_COMPLETED_STAGE=23') -and
              ($lines -contains 'STAGE23_RUNTIME_VERIFICATION=GREEN_CONFIRMED') -and
              ($lines -contains 'CURRENT_STAGE=23'))) {
        throw 'Stage23 is not in the expected sealed state.'
    }
    $originalHash = (Get-FileHash -LiteralPath $stageFile -Algorithm SHA256).Hash
    Write-Evidence ("SHA256_BEFORE=" + $originalHash)

    $shell = Join-Path $PSHOME 'powershell.exe'
    if (-not (Test-Path -LiteralPath $shell)) { throw 'Windows PowerShell executable missing.' }
    $arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + $finalizer + '"'
    for ($iteration = 1; $iteration -le 2; $iteration++) {
        $stdout = Join-Path $evidence ("run" + $iteration + "-stdout.txt")
        $stderr = Join-Path $evidence ("run" + $iteration + "-stderr.txt")
        $process = Start-Process -FilePath $shell -ArgumentList $arguments -WorkingDirectory $root -Wait -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $output = Get-Content -LiteralPath $stdout -Raw -Encoding UTF8
        $errors = [string](Get-Content -LiteralPath $stderr -Raw -Encoding UTF8)
        Write-Evidence ("RUN_" + $iteration + "_EXIT_CODE=" + $process.ExitCode)
        Write-Evidence ("RUN_" + $iteration + "_ALREADY_FINALIZED=" + [bool]($output -match '(?m)^STAGE23_ALREADY_FINALIZED=YES\s*$'))
        Write-Evidence ("RUN_" + $iteration + "_STDERR_LENGTH=" + $errors.Length)
        $nowHash = (Get-FileHash -LiteralPath $stageFile -Algorithm SHA256).Hash
        Write-Evidence ("RUN_" + $iteration + "_SHA256_AFTER=" + $nowHash)
        $diff = @(Invoke-GitSafe -GitArguments @('diff','--binary','HEAD','--','DEVELOPMENT_STAGE.md'))
        $diffFile = Join-Path $evidence ("run" + $iteration + "-stage-diff.txt")
        Set-Content -LiteralPath $diffFile -Value $diff -Encoding UTF8
        Test-CleanCheckout
        if ($process.ExitCode -ne 0) { throw ("Finalizer run " + $iteration + " returned nonzero exit code.") }
        if ($output -notmatch '(?m)^STAGE23_ALREADY_FINALIZED=YES\s*$') {
            throw ("Run " + $iteration + " did not report STAGE23_ALREADY_FINALIZED=YES.")
        }
        if ($nowHash -cne $originalHash) { throw ("Stage metadata hash changed in run " + $iteration + ".") }
        if ($diff.Count -ne 0) { throw ("Stage metadata git diff detected in run " + $iteration + ".") }
    }

    $endHead = ((Invoke-GitSafe -GitArguments @('rev-parse','HEAD')) -join '').Trim()
    if ($endHead -cne $head) { throw 'Branch HEAD changed during verification.' }
    Write-Evidence 'RESULT=PASS'
    $passed = $true
}
catch {
    Write-Evidence ("RESULT=FAIL; REASON=" + $_.Exception.Message)
}
Write-Host ("EVIDENCE_DIRECTORY=" + $evidence)
if ($passed) { exit 0 }
exit 1
