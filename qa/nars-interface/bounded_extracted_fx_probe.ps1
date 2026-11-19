# Disposable GitHub-hosted Windows only. Tests ⎕EC + ⎕FX + actual function execution; NOT Stage1.
[CmdletBinding()]
param(
    [string]$Runtime = 'verified_runtime',
    [string]$Evidence = 'fx_probe_evidence'
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
    schema = 'APL_GERMAN_NATIVE_FX_EC_PROBE_V1'
    status = 'STARTED'
    binary_verified = $false
    version_verified = $false
    interpreter_executed = $false
    fx_probe = [ordered]@{ exists=$false; matches_exact=$false; bytes=0; sha256=$null }
    stage01 = 'NOT_RUN'
    audit_evidence = 'NOT_PRODUCED'
    errors = @()
}
function Save-Report {
    $r | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $Evidence 'native_fx_probe.json') -Encoding utf8
}
try {
    if (-not $env:RUNNER_TEMP) { throw 'GITHUB_RUNNER_TEMP_MISSING' }
    $root = (Resolve-Path -LiteralPath $Runtime).Path
    $files = @(Get-ChildItem -LiteralPath $root -File)
    if ($files.Count -ne 4) { throw ('RUNTIME_FILE_COUNT_INVALID:' + $files.Count) }
    foreach ($name in $expected.Keys) {
        $p = Join-Path $root $name
        if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { throw ('REQUIRED_RUNTIME_FILE_MISSING:' + $name) }
        $actual = (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actual -ne $expected[$name]) { throw ('EXTRACTED_FILE_SHA256_MISMATCH:' + $name) }
    }
    $r['binary_verified'] = $true
    $exe = Join-Path $root 'NARS2000.exe'
    $vi = (Get-Item -LiteralPath $exe).VersionInfo
    $versions = @([string]$vi.FileVersion,[string]$vi.ProductVersion) | ForEach-Object { $_ -replace '[, ]+', '.' }
    if (-not @($versions | Where-Object { $_ -match '(^|[^0-9])0?\.5\.14\.11([^0-9]|$)' }).Count) {
        $r['status'] = 'VERSIONINFO_NOT_EXACT'
        return
    }
    $r['version_verified'] = $true
    $wsUrl = 'https://www.nars2000.org/download/workspaces/2by2.ws.nars'
    $ws = Join-Path $env:RUNNER_TEMP 'nars_reference_2by2.ws.nars'
    Invoke-WebRequest -Uri $wsUrl -OutFile $ws -MaximumRedirection 3 -TimeoutSec 90
    $r['workspace_source'] = [ordered]@{url=$wsUrl;sha256=(Get-FileHash -LiteralPath $ws -Algorithm SHA256).Hash.ToLowerInvariant();bytes=(Get-Item $ws).Length}
    $prefix = Join-Path $env:RUNNER_TEMP 'apl_german_fx_probe'
    $candidate = $prefix + '.ws.nars'
    $receipt = Join-Path $Evidence 'workspace_candidate_receipt.json'
    $marker = Join-Path $env:RUNNER_TEMP 'apl_fx_probe_receipt.txt'
    if (Test-Path -LiteralPath $marker) { throw 'FX_PROBE_MARKER_PREEXISTS' }
    & python qa/nars-interface/fx_probe_workspace.py --source $ws --candidate $candidate --receipt $receipt --canary $marker
    if ($LASTEXITCODE -ne 0) { throw 'FX_PROBE_CANDIDATE_GENERATION_FAILED' }
    $meta = Get-Content -LiteralPath $receipt -Raw | ConvertFrom-Json
    if ($meta.status -ne 'GENERATED_NOT_NATIVE_VALIDATED' -or $meta.mode -ne 'fx_probe' -or $meta.native_executed -ne $false) { throw 'FX_PROBE_CANDIDATE_CONTRACT_MISMATCH' }
    if ($meta.canary_token -ne '42' -or $meta.canary_path -ine $marker) { throw 'FX_PROBE_TOKEN_OR_PATH_MISMATCH' }
    if ($meta.apl_statement.Contains("'") -or $meta.apl_statement.Contains('"')) { throw 'FX_PROBE_LX_NOT_QUOTE_FREE' }
    if (-not $meta.apl_statement.StartsWith('(⍕⊃⎕EC ⎕UCS ')) { throw 'FX_PROBE_LX_NOT_EC_UCS' }
    $diagnostic = [string]$meta.diagnostic_path
    if ($diagnostic -ine ($marker.Substring(0, $marker.Length - 4) + '.ec.txt')) { throw 'FX_PROBE_DIAG_PATH_MISMATCH' }
    if (Test-Path -LiteralPath $diagnostic) { throw 'FX_PROBE_DIAG_PREEXISTS' }
    $candidateSha = (Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($candidateSha -ne $meta.output_sha256) { throw 'FX_PROBE_CANDIDATE_SHA256_MISMATCH' }
    $r['candidate_sha256'] = $candidateSha
    $p = Start-Process -FilePath $exe -ArgumentList ('"' + $prefix + '"') -WorkingDirectory $root -PassThru
    $r['interpreter_executed'] = $true
    $r['process_id'] = $p.Id
    # NARS ⎕NCREATE makes a zero-byte file before ⎕NAPPEND writes the data.
    # Existence alone is NOT a completion signal and previously caused the
    # runner to terminate a still-writing NARS process prematurely.
    $deadline = [DateTime]::UtcNow.AddSeconds(25)
    # Only the post-⎕EC diagnostic file can signal completion of the
    # inner program. The primary marker may be created before its write.
    while ([DateTime]::UtcNow -lt $deadline) {
        if (Test-Path -LiteralPath $diagnostic -PathType Leaf) {
            if ((Get-Item -LiteralPath $diagnostic).Length -ge 1) { break }
        }
        Start-Sleep -Milliseconds 300
        $p.Refresh()
        if ($p.HasExited) { break }
    }
    $p.Refresh()
    $wasRunning = -not $p.HasExited
    if ($wasRunning) {
        & taskkill.exe /PID $p.Id /T /F 2>&1 | Out-Null
        try { Wait-Process -Id $p.Id -Timeout 5 -ErrorAction Stop } catch { }
        $p.Refresh()
    }
    if (-not $p.HasExited) { throw 'FX_PROBE_NARS_PROCESS_NOT_TERMINATED' }
    $exists = Test-Path -LiteralPath $marker -PathType Leaf
    $expectedBytes = [System.Text.Encoding]::ASCII.GetBytes([string]$meta.canary_token)
    [byte[]]$actualBytes = @()
    if ($exists) { $actualBytes = [System.IO.File]::ReadAllBytes($marker) }
    $exact = ($actualBytes.Length -eq $expectedBytes.Length) -and ([Convert]::ToBase64String($actualBytes) -ceq [Convert]::ToBase64String($expectedBytes))
    $markerSha = if ($exists) { (Get-FileHash -LiteralPath $marker -Algorithm SHA256).Hash.ToLowerInvariant() } else { $null }
    $ecExists = Test-Path -LiteralPath $diagnostic -PathType Leaf
    $ecCode = if ($ecExists) { [System.IO.File]::ReadAllText($diagnostic).Trim() } else { '' }
    $ecSha = if ($ecExists) { (Get-FileHash -LiteralPath $diagnostic -Algorithm SHA256).Hash.ToLowerInvariant() } else { $null }
    $r['ec_status'] = [ordered]@{exists=$ecExists;code=$ecCode;sha256=$ecSha;success=($ecCode -in @('1','2','3'))}
    $r['fx_probe'] = [ordered]@{exists=$exists;matches_exact=$exact;bytes=$actualBytes.Length;expected_bytes=$expectedBytes.Length;sha256=$markerSha;process_was_running_at_check=$wasRunning}
    $r['process_exit_code'] = if ($p.HasExited) { $p.ExitCode } else { $null }
    $r['status'] = if ($exact -and $r['ec_status'].success) { 'NATIVE_FX_EC_PROBE_CONFIRMED_NOT_STAGE01' } else { 'NATIVE_FX_EC_PROBE_NOT_OBSERVED' }
} catch {
    $r['status'] = 'FAIL_CLOSED'
    $r['errors'] += $_.Exception.Message
    throw
} finally {
    Save-Report
    Write-Output ('NATIVE_FX_EC_STATUS=' + $r['status'])
    Write-Output ('BINARY_SHA256_VERIFIED=' + $r['binary_verified'])
    Write-Output ('VERSION_VERIFIED=' + $r['version_verified'])
    Write-Output ('FX_PROBE_FILE_EXISTS=' + $r['fx_probe'].exists)
    Write-Output ('FX_PROBE_FILE_EXACT=' + $r['fx_probe'].matches_exact)
    if ($r.Contains('ec_status')) { Write-Output ('FX_PROBE_EC_CODE=' + $r['ec_status'].code) }
    Write-Output 'STAGE01=NOT_RUN'
}
