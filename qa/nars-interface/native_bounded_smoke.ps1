# On disposable GitHub-hosted Windows CI only. No code runs before exact pinned SHA.
# Status NEVER constitutes Stage1 PASS; tests clean LX canary only.
[CmdletBinding()]
param([string]$Evidence='native_smoke_evidence')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue'
New-Item -ItemType Directory -Force $Evidence | Out-Null
$Evidence=(Resolve-Path $Evidence).Path
$url='https://www.nars2000.org/download/binaries/w64/NARS2000-0.5.14.11.exe'
$hash='28e8d1dbcea13360a271e704196b5680f0c3e9461cfc38daa41b96dba202f11b'
$workspaceUrl='https://www.nars2000.org/download/workspaces/2by2.ws.nars'
$r=[ordered]@{schema='APL_GERMAN_NATIVE_LX_CI_SMOKE_V1';status='STARTED';installer_url=$url;expected_hash=$hash;release_hash_matched=$false;signature='UNASSESSED';silent_installer='NOT_RUN';nars_process='NOT_RUN';lx_canary='NOT_RUN';stage01='NOT_RUN';audit_evidence='NOT_PRODUCED';source_head='7161824b9fcbfaca91f20d1ea492417e77003ff4';errors=@()}
function Save { $r | ConvertTo-Json -Depth 10 | Set-Content -Encoding utf8 (Join-Path $Evidence 'native_smoke.json') }
function RunBounded([string]$exe,[string]$arguments,[string]$cwd,[int]$seconds) {
  $p=Start-Process -FilePath $exe -ArgumentList $arguments -WorkingDirectory $cwd -PassThru
  $beg=[DateTimeOffset]::UtcNow
  $deadline=[DateTime]::UtcNow.AddSeconds($seconds)
  while (-not $p.HasExited -and [DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 400; $p.Refresh() }
  $ended=$p.HasExited
  $code=if($ended){$p.ExitCode}else{$null}
  if(-not $ended){ & taskkill.exe /PID $p.Id /T /F 2>&1 | Out-Null }
  return [ordered]@{pid=$p.Id;exited=$ended;exit_code=$code;elapsed_seconds=[math]::Round(([DateTimeOffset]::UtcNow-$beg).TotalSeconds,2);timed_out=(-not $ended)}
}
try {
  if (-not $env:RUNNER_TEMP) { throw 'NOT_ON_GITHUB_RUNNER' }
  $file=Join-Path $env:RUNNER_TEMP 'NARS2000-exact.exe'
  Invoke-WebRequest -Uri $url -OutFile $file -MaximumRedirection 3 -TimeoutSec 100
  $sha=(Get-FileHash $file -Algorithm SHA256).Hash.ToLowerInvariant()
  $len=(Get-Item $file).Length
  $r.installer_size=$len; $r.installer_sha256=$sha
  if($len -ne 9430788 -or $sha -ne $hash){throw 'PINNED_OFFICIAL_RELEASE_MISMATCH'}
  $r.release_hash_matched=$true
  $r.signature=(Get-AuthenticodeSignature $file).Status.ToString()
  $dest=Join-Path $env:RUNNER_TEMP 'nars_setup_target'
  New-Item -ItemType Directory -Force $dest | Out-Null
  # Common NSIS SFX silent switches; deliberately only one bounded attempt.
  # If unsupported, record failure and do not automate installer GUI.
  $inst=RunBounded $file ("/S /D="+$dest) $env:RUNNER_TEMP 35
  $r.installer_result=$inst
  $exe=@(Get-ChildItem -LiteralPath $dest -Filter 'NARS2000.exe' -File -Recurse | Select-Object -First 2)
  $r.installer_inner_executables=$exe.Count
  if($exe.Count -ne 1) { $r.silent_installer='NOT_CONFIRMED'; $r.status='SILENT_SETUP_NOT_PROVEN'; return }
  $r.silent_installer='EXTRACTED_ONE_BINARY'
  $nars=$exe[0].FullName
  $r.nars_binary_sha256=(Get-FileHash $nars -Algorithm SHA256).Hash.ToLowerInvariant()
  $r.nars_file_version=$exe[0].VersionInfo.FileVersion
  $r.nars_signature=(Get-AuthenticodeSignature $nars).Status.ToString()
  $ws=Join-Path $env:RUNNER_TEMP 'nars_official_2by2.ws.nars'
  Invoke-WebRequest -Uri $workspaceUrl -OutFile $ws -MaximumRedirection 3 -TimeoutSec 100
  $r.reference_ws_sha256=(Get-FileHash $ws -Algorithm SHA256).Hash.ToLowerInvariant()
  $candidateBase=Join-Path $env:RUNNER_TEMP 'apl_lx_probe'
  $candidate=$candidateBase+'.ws.nars'
  $canary=Join-Path $env:RUNNER_TEMP 'lx_probe_canary.txt'
  $receipt=Join-Path $Evidence 'candidate_workspace_receipt.json'
  if(Test-Path -LiteralPath $canary){throw 'CANARY_PREEXISTS'}
  & python qa/nars-interface/lx_workspace_probe.py --source $ws --candidate $candidate --receipt $receipt --canary $canary
  if($LASTEXITCODE -ne 0){throw 'WORKSPACE_CANDIDATE_BUILDER_FAILED'}
  # In NARS, a non-switch command-line argument is a workspace base name.
  # Do not simulate any GUI keystrokes, messages, or clipboard operations.
  $p=Start-Process -FilePath $nars -ArgumentList ('"'+$candidateBase+'"') -WorkingDirectory (Split-Path $nars) -PassThru
  $r.nars_process=[ordered]@{pid=$p.Id;launched=$true;candidate_sha256=(Get-FileHash $candidate -Algorithm SHA256).Hash.ToLowerInvariant()}
  $deadline=[DateTime]::UtcNow.AddSeconds(28)
  while(-not (Test-Path -LiteralPath $canary) -and [DateTime]::UtcNow -lt $deadline){Start-Sleep -Milliseconds 400}
  $canaryExists=Test-Path -LiteralPath $canary
  $canaryText=if($canaryExists){[System.IO.File]::ReadAllText($canary)}else{''}
  if(-not $p.HasExited){ & taskkill.exe /PID $p.Id /T /F 2>&1 | Out-Null }
  $token='APL_LX_CANARY_REAL_NATIVE_0_5_14_11'
  $r.lx_canary=[ordered]@{exists=$canaryExists;matches_token=($canaryText -match [regex]::Escape($token));native_executable_sha256=$r.nars_binary_sha256}
  if($canaryExists -and $r.lx_canary.matches_token) { $r.status='NATIVE_LX_SMOKE_PASS_NOT_STAGE01' }
  else { $r.status='NATIVE_LX_SMOKE_NO_CANARY' }
} catch {
  $r.errors += $_.Exception.Message
  $r.status='FAIL_CLOSED'
  throw
} finally {
  Save
  Write-Output ('NARS_SMOKE='+$r.status)
  Write-Output ('EXACT_RELEASE_SHA_MATCH='+$r.release_hash_matched)
  Write-Output 'STAGE01=NOT_RUN'
}
