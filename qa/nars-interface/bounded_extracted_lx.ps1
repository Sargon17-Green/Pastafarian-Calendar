# Disposable GitHub-hosted Windows only. Native LX sentinel, NOT Stage1 acceptance.
[CmdletBinding()]
param(
    [string]$Runtime = 'verified_runtime',
    [string]$Evidence = 'native_lx_evidence'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
New-Item -ItemType Directory -Force -Path $Evidence | Out-Null
$Evidence = (Resolve-Path -LiteralPath $Evidence).Path
$expected = [ordered]@{
    'NARS2000.exe' = '192b7bd3c06a64ef57bfe1ea7f04e5d5d511ae9cd07323cfd211710891e2069d'
    'crashrpt.dll' = '461fa51cd64408878cc57da97f740b992c0ad98802ab31fa8a39aa20cc9983c5'
    'dbghelp.dll' = '159b30d9f1bbe69ae03e0d19669d4fcb565246d81672b7034a69cef9f466dcbe'
    'SendRpt.exe' = '4726c90412275df4942d1a8051687918c9838486c3c8aabe327f1bfdbf8899c2'
}
$r = [ordered]@{
    schema = 'APL_GERMAN_EXTRACTED_NATIVE_LX_CANARY_V1'
    status = 'STARTED'
    source_installer_sha256 = '28e8d1dbcea13360a271e704196b5680f0c3e9461cfc38daa41b96dba202f11b'
    extractor_source_run = 44374156425
    expected_binary_sha256 = $expected['NARS2000.exe']
    binary_verified = $false
    version_verified = $false
    interpreter_executed = $false
    lx_canary = [ordered]@{ exists=$false; matches_exact=$false; marker_bytes=0; marker_sha256=$null; expected_bytes=0; process_exited=$false }
    stage01 = 'NOT_RUN'
    audit_evidence = 'NOT_PRODUCED'
    errors = @()
}
function Save-Report {
    $r | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $Evidence 'native_lx_canary.json') -Encoding utf8
}
try {
    if (-not $env:RUNNER_TEMP) { throw 'GITHUB_RUNNER_TEMP_MISSING' }
    $root = (Resolve-Path -LiteralPath $Runtime).Path
    $files = @(Get-ChildItem -LiteralPath $root -File)
    if ($files.Count -ne 4) { throw ('RUNTIME_FILE_COUNT_INVALID:'+$files.Count) }
    foreach ($name in $expected.Keys) {
        $p = Join-Path $root $name
        if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { throw ('REQUIRED_RUNTIME_FILE_MISSING:'+$name) }
        $actual = (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actual -ne $expected[$name]) { throw ('EXTRACTED_FILE_SHA256_MISMATCH:'+$name) }
    }
    $exe = Join-Path $root 'NARS2000.exe'
    $exeInfo = (Get-Item -LiteralPath $exe).VersionInfo
    $fileVersion = [string]$exeInfo.FileVersion
    $productVersion = [string]$exeInfo.ProductVersion
    $r['runtime'] = [ordered]@{
        path = $root
        file_version = $fileVersion
        product_version = $productVersion
        authenticode = (Get-AuthenticodeSignature -FilePath $exe).Status.ToString()
        matching_files = 4
    }
    $r['binary_verified'] = $true
    # Version must be explicitly evidenced by the executable's Win32 VERSIONINFO.
    # No inference of version solely from the installation filename.
    $versions = @($fileVersion,$productVersion) | ForEach-Object { $_ -replace '[, ]+', '.' }
    if (-not @($versions | Where-Object { $_ -match '(^|[^0-9])0?\.5\.14\.11([^0-9]|$)' }).Count) {
        $r['status'] = 'VERSIONINFO_NOT_EXACT'
        return
    }
    $r['version_verified'] = $true
    $wsUrl = 'https://www.nars2000.org/download/workspaces/2by2.ws.nars'
    $ws = Join-Path $env:RUNNER_TEMP 'nars_reference_2by2.ws.nars'
    Invoke-WebRequest -Uri $wsUrl -OutFile $ws -MaximumRedirection 3 -TimeoutSec 90
    $length = (Get-Item -LiteralPath $ws).Length
    if ($length -lt 50 -or $length -gt 25000000) { throw 'WORKSPACE_UNEXPECTED_SIZE' }
    $r['workspace_source'] = [ordered]@{ url=$wsUrl; bytes=$length; sha256=(Get-FileHash -LiteralPath $ws -Algorithm SHA256).Hash.ToLowerInvariant() }
    $prefix = Join-Path $env:RUNNER_TEMP 'apl_german_lx_canary'
    $candidate = $prefix + '.ws.nars'
    $receipt = Join-Path $Evidence 'workspace_candidate_receipt.json'
    $marker = Join-Path $env:RUNNER_TEMP 'apl_lx_receipt.txt'
    if (Test-Path -LiteralPath $marker) { throw 'CANARY_ALREADY_EXISTS' }
    & python qa/nars-interface/lx_workspace_probe.py --source $ws --candidate $candidate --receipt $receipt --canary $marker --mode file
    if ($LASTEXITCODE -ne 0) { throw 'WORKSPACE_CANDIDATE_GENERATOR_FAILED' }
    $candidateMeta = Get-Content -LiteralPath $receipt -Raw | ConvertFrom-Json
    if ($candidateMeta.status -ne 'GENERATED_NOT_NATIVE_VALIDATED' -or $candidateMeta.mode -ne 'file' -or $candidateMeta.native_executed -ne $false) { throw 'CANDIDATE_RECEIPT_CONTRACT_MISMATCH' }
    if ($candidateMeta.canary_path -ine $marker) { throw 'CANDIDATE_CANARY_PATH_MISMATCH' }
    if ($candidateMeta.input_sha256 -ne $r['workspace_source'].sha256) { throw 'CANDIDATE_INPUT_SHA256_MISMATCH' }
    if ($candidateMeta.apl_statement.Contains("'") -or $candidateMeta.apl_statement.Contains('"')) { throw 'CANDIDATE_LX_NOT_QUOTE_FREE' }
    if (-not $candidateMeta.apl_statement.Contains('⎕NAPPEND ((⎕UCS') -or -not $candidateMeta.apl_statement.Contains('⎕NCREATE 0)') -or -not $candidateMeta.apl_statement.Contains('⎕UCS')) { throw 'CANDIDATE_NATIVE_FILE_EXPRESSION_INCOMPLETE_OR_UNGROUPED' }
    $r['candidate_sha256'] = (Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($candidateMeta.output_sha256 -ne $r['candidate_sha256']) { throw 'CANDIDATE_OUTPUT_SHA256_MISMATCH' }
    # Single bounded native process; NO simulated keystrokes, windows messages or GUI automation.
    $p = Start-Process -FilePath $exe -ArgumentList ('"' + $prefix + '"') -WorkingDirectory $root -PassThru
    $r['interpreter_executed'] = $true
    $r['process_id'] = $p.Id
    $r['process_launch_utc'] = [DateTime]::UtcNow.ToString('o')
    $limit = [DateTime]::UtcNow.AddSeconds(25)
    while (-not (Test-Path -LiteralPath $marker -PathType Leaf) -and [DateTime]::UtcNow -lt $limit) {
        Start-Sleep -Milliseconds 350
        $p.Refresh()
        if ($p.HasExited) { break }
    }
    $token = 'APL_LX_CANARY_REAL_NATIVE_0_5_14_11'
    $expectedBytes = [System.Text.Encoding]::ASCII.GetBytes($token)
    $p.Refresh()
    $processWasRunningAtReceiptCheck = -not $p.HasExited
    # NARS keeps the native-file tie open after ⎕NAPPEND. Terminate the bounded
    # process first so Windows releases the handle before the independent byte read.
    if ($processWasRunningAtReceiptCheck) {
        & taskkill.exe /PID $p.Id /T /F 2>&1 | Out-Null
        try { Wait-Process -Id $p.Id -Timeout 5 -ErrorAction Stop } catch { }
        $p.Refresh()
    }
    if (-not $p.HasExited) { throw 'NARS_PROCESS_NOT_TERMINATED_AFTER_LX_RECEIPT' }
    $exists = Test-Path -LiteralPath $marker -PathType Leaf
    [byte[]]$actualBytes = @()
    if ($exists) { $actualBytes = [System.IO.File]::ReadAllBytes($marker) }
    $matchesExact = ($actualBytes.Length -eq $expectedBytes.Length) -and ([Convert]::ToBase64String($actualBytes) -ceq [Convert]::ToBase64String($expectedBytes))
    $markerSha = if ($exists) { (Get-FileHash -LiteralPath $marker -Algorithm SHA256).Hash.ToLowerInvariant() } else { $null }
    $r['lx_canary'] = [ordered]@{ exists=$exists; matches_exact=$matchesExact; marker_bytes=$actualBytes.Length; marker_sha256=$markerSha; expected_bytes=$expectedBytes.Length; process_exited=$p.HasExited; process_was_running_at_receipt_check=$processWasRunningAtReceiptCheck }
    $r['process_exit_code'] = if ($p.HasExited) { $p.ExitCode } else { $null }
    $r['status'] = if ($exists -and $matchesExact) { 'NATIVE_LX_RECEIPT_CONFIRMED_NOT_STAGE01' } else { 'NATIVE_LX_RECEIPT_NOT_OBSERVED' }
} catch {
    $r['status'] = 'FAIL_CLOSED'
    $r['errors'] += $_.Exception.Message
    throw
} finally {
    Save-Report
    Write-Output ('NATIVE_LX_STATUS=' + $r['status'])
    Write-Output ('BINARY_SHA256_VERIFIED=' + $r['binary_verified'])
    Write-Output ('VERSION_VERIFIED=' + $r['version_verified'])
    Write-Output ('LX_FILE_EXISTS=' + $r['lx_canary'].exists)
    Write-Output ('LX_FILE_EXACT=' + $r['lx_canary'].matches_exact)
    Write-Output 'STAGE01=NOT_RUN'
}
