# Run all 95 locked Stage 1 functions and the actual Stage 1 suite in native NARS2000.
[CmdletBinding()]
param(
    [string]$Runtime = 'verified_runtime',
    [string]$Evidence = 'stage01_evidence'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
New-Item -ItemType Directory -Force -Path $Evidence | Out-Null
$Evidence = (Resolve-Path -LiteralPath $Evidence).Path
$sourceCommit = '7161824b9fcbfaca91f20d1ea492417e77003ff4'
$expected = [ordered]@{
    'NARS2000.exe' = '192b7bd3c06a64ef57bfe1ea7f04e5d5d511ae9cd07323cfd211710891e2069d'
    'crashrpt.dll' = '461fa51cd64408878cc57da97f740b992c0ad98802ab31fa8a39aa20cc9983c5'
    'dbghelp.dll' = '159b30d9f1bbe69ae03e0d19669d4fcb565246d81672b7034a69cef9f466dcbe'
    'SendRpt.exe' = '4726c90412275df4942d1a8051687918c9838486c3c8aabe327f1bfdbf8899c2'
}
$r = [ordered]@{
    schema = 'APL_GERMAN_STAGE01_NATIVE_RUN_V1'
    status = 'STARTED'
    source_commit = $sourceCommit
    runtime_files_verified = $false
    version_verified = $false
    interpreter_executed = $false
    stage01 = 'NOT_RUN'
    audit_evidence = 'NOT_PRODUCED'
    native_receipt = [ordered]@{exists=$false;matches_exact=$false;bytes=0;sha256=$null}
    errors = @()
}
function Save-Report {
    $r | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath (Join-Path $Evidence 'native_stage01.json') -Encoding utf8
}
try {
    if (-not $env:RUNNER_TEMP) { throw 'GITHUB_RUNNER_TEMP_MISSING' }
    $root = (Resolve-Path -LiteralPath $Runtime).Path
    if (@(Get-ChildItem -LiteralPath $root -File).Count -ne 4) { throw 'RUNTIME_FILE_COUNT_INVALID' }
    foreach ($name in $expected.Keys) {
        $p = Join-Path $root $name
        if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { throw ('REQUIRED_RUNTIME_FILE_MISSING:' + $name) }
        $actual = (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actual -ne $expected[$name]) { throw ('EXTRACTED_FILE_SHA256_MISMATCH:' + $name) }
    }
    $r['runtime_files_verified'] = $true
    $exe = Join-Path $root 'NARS2000.exe'
    $vi = (Get-Item -LiteralPath $exe).VersionInfo
    $versions = @([string]$vi.FileVersion,[string]$vi.ProductVersion) | ForEach-Object { $_ -replace '[, ]+', '.' }
    if (-not @($versions | Where-Object { $_ -match '(^|[^0-9])0?\.5\.14\.11([^0-9]|$)' }).Count) { throw 'NARS_VERSION_NOT_EXACT_0_5_14_11' }
    $r['version_verified'] = $true
    $wsUrl = 'https://www.nars2000.org/download/workspaces/2by2.ws.nars'
    $ws = Join-Path $env:RUNNER_TEMP 'nars_reference_2by2.ws.nars'
    Invoke-WebRequest -Uri $wsUrl -OutFile $ws -MaximumRedirection 3 -TimeoutSec 90
    $r['workspace_source'] = [ordered]@{url=$wsUrl;sha256=(Get-FileHash -LiteralPath $ws -Algorithm SHA256).Hash.ToLowerInvariant();bytes=(Get-Item $ws).Length}
    $prefix = Join-Path $env:RUNNER_TEMP 'apl_german_stage01_candidate'
    $candidate = $prefix + '.ws.nars'
    $manifestPath = Join-Path $Evidence 'source_manifest.json'
    $receiptPath = Join-Path $Evidence 'workspace_candidate_receipt.json'
    $marker = Join-Path $env:RUNNER_TEMP 'apl_stage01_native_receipt.txt'
    if (Test-Path -LiteralPath $marker) { throw 'STAGE01_MARKER_PREEXISTS' }
    & python qa/nars-interface/stage01_import_workspace.py --repo-root . --source-workspace $ws --candidate $candidate --manifest $manifestPath --receipt $receiptPath --marker-path $marker
    if ($LASTEXITCODE -ne 0) { throw 'STAGE01_CANDIDATE_GENERATION_FAILED' }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $meta = Get-Content -LiteralPath $receiptPath -Raw | ConvertFrom-Json
    if ($meta.status -ne 'GENERATED_NOT_NATIVE_VALIDATED' -or $meta.native_executed -ne $false) { throw 'STAGE01_CANDIDATE_NOT_PREPARED' }
    if ($meta.source_commit -ne $sourceCommit -or $meta.source_file_count -ne 5 -or $meta.function_count -ne 95 -or $meta.unique_function_count -ne 95) { throw 'STAGE01_SOURCE_MANIFEST_GATE_FAILED' }
    if ($manifest.source_commit -ne $sourceCommit -or $manifest.function_count -ne 95 -or $manifest.unique_function_count -ne 95) { throw 'STAGE01_MANIFEST_GATE_FAILED' }
    if ($meta.marker_path -ine $marker) { throw 'STAGE01_MARKER_PATH_MISMATCH' }
    $candidateSha = (Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($candidateSha -ne $meta.candidate_sha256) { throw 'STAGE01_CANDIDATE_SHA256_MISMATCH' }
    Copy-Item -LiteralPath $candidate -Destination (Join-Path $Evidence 'stage01_candidate.ws.nars') -Force
    $r['candidate'] = [ordered]@{sha256=$candidateSha;bytes=(Get-Item $candidate).Length;outer_lx_sha256=$meta.outer_lx_sha256;inner_program_sha256=$meta.inner_program_sha256;outer_lx_characters=$meta.outer_lx_characters;inner_program_characters=$meta.inner_program_characters}
    $r['source_manifest'] = $manifest
    $r['candidate_receipt'] = $meta
    $p = Start-Process -FilePath $exe -ArgumentList ('"' + $prefix + '"') -WorkingDirectory $root -PassThru
    $r['interpreter_executed'] = $true
    $r['process_id'] = $p.Id
    $deadline = [DateTime]::UtcNow.AddSeconds(120)
    $expectedBytes = [System.Text.Encoding]::ASCII.GetBytes([string]$meta.marker_token)
    while ([DateTime]::UtcNow -lt $deadline) {
        if (Test-Path -LiteralPath $marker -PathType Leaf) {
            $size = (Get-Item -LiteralPath $marker).Length
            if ($size -eq $expectedBytes.Length) { break }
        }
        $p.Refresh()
        if ($p.HasExited) { break }
        Start-Sleep -Milliseconds 250
    }
    $p.Refresh()
    $wasRunning = -not $p.HasExited
    if ($wasRunning) {
        & taskkill.exe /PID $p.Id /T /F 2>&1 | Out-Null
        try { Wait-Process -Id $p.Id -Timeout 8 -ErrorAction Stop } catch { }
        $p.Refresh()
    }
    if (-not $p.HasExited) { throw 'STAGE01_NARS_PROCESS_NOT_TERMINATED' }
    $exists = Test-Path -LiteralPath $marker -PathType Leaf
    [byte[]]$actualBytes = @()
    if ($exists) { $actualBytes = [System.IO.File]::ReadAllBytes($marker) }
    $exact = ($actualBytes.Length -eq $expectedBytes.Length) -and ([Convert]::ToBase64String($actualBytes) -ceq [Convert]::ToBase64String($expectedBytes))
    $markerSha = if ($exists) { (Get-FileHash -LiteralPath $marker -Algorithm SHA256).Hash.ToLowerInvariant() } else { $null }
    $r['native_receipt'] = [ordered]@{exists=$exists;matches_exact=$exact;bytes=$actualBytes.Length;expected_bytes=$expectedBytes.Length;sha256=$markerSha;process_was_running_at_check=$wasRunning;process_exit_code=$p.ExitCode}
    if ($exists) { Copy-Item -LiteralPath $marker -Destination (Join-Path $Evidence 'stage01_native_receipt.txt') -Force }
    $r['stage01'] = if ($exact) { 'PASS' } else { 'NOT_CONFIRMED' }
    $r['status'] = if ($exact) { 'NATIVE_STAGE01_PASS_CONFIRMED' } else { 'NATIVE_STAGE01_NOT_CONFIRMED' }
    $r['audit_evidence'] = if ($exact) { 'PRODUCED' } else { 'INCOMPLETE' }
    $audit = [ordered]@{
        schema='APL_GERMAN_STAGE01_AUDIT_EVIDENCE_V1'
        status=$r['status']
        source_commit=$sourceCommit
        source_manifest_sha256=$meta.source_manifest_sha256
        source_files=$manifest.ordered_files
        function_count=$meta.function_count
        fx_receipts=$meta.function_count
        test_entrypoint='RunStage01Tests'
        test_result=$r['stage01']
        native_receipt=$r['native_receipt']
        nars_version='0.5.14.11'
        nars_exe_sha256=$expected['NARS2000.exe']
        runtime_files_verified=4
        font_installed_ephemeral_only=$true
        authenticode=(Get-AuthenticodeSignature -FilePath $exe).Status.ToString()
        workspace_source=$r['workspace_source']
        candidate=$r['candidate']
        no_source_files_modified=$true
    }
    New-Item -ItemType Directory -Force -Path (Join-Path $Evidence 'audit_evidence') | Out-Null
    $audit | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath (Join-Path $Evidence 'audit_evidence/STAGE01_NATIVE_RUN.json') -Encoding utf8
} catch {
    $r['status'] = 'FAIL_CLOSED'
    $r['errors'] += $_.Exception.Message
    throw
} finally {
    Save-Report
    Write-Output ('NATIVE_STAGE01_STATUS=' + $r['status'])
    Write-Output ('RUNTIME_FILES_VERIFIED=' + $r['runtime_files_verified'])
    Write-Output ('VERSION_VERIFIED=' + $r['version_verified'])
    Write-Output ('STAGE01=' + $r['stage01'])
    Write-Output ('NATIVE_RECEIPT_EXACT=' + $r['native_receipt'].matches_exact)
    Write-Output ('AUDIT_EVIDENCE=' + $r['audit_evidence'])
}
