# Static analysis only. No downloaded executable is launched.
[CmdletBinding()]
param([string]$Evidence = "native_release_evidence")
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
New-Item -ItemType Directory -Force -Path $Evidence | Out-Null
$Evidence = (Resolve-Path $Evidence).Path
$expectedSha = '28e8d1dbcea13360a271e704196b5680f0c3e9461cfc38daa41b96dba202f11b'
$expectedBytes = 9430788L
$url = 'https://www.nars2000.org/download/binaries/w64/NARS2000-0.5.14.11.exe'
$wsUrl = 'https://www.nars2000.org/download/workspaces/2by2.ws.nars'
$r = [ordered]@{schema='NARS2000_PINNED_RELEASE_STATIC_V1';version='0.5.14.11';status='STARTED';url=$url;expected_sha256=$expectedSha;expected_bytes=$expectedBytes; matched_previous_v20=$false; native_executed=$false;cli_supported='UNDETERMINED';extracted=@();workspace=$null;errors=@()}
try {
  if (-not $env:RUNNER_TEMP) { throw 'RUNNER_TEMP_NOT_AVAILABLE' }
  $file = Join-Path $env:RUNNER_TEMP 'NARS2000-0.5.14.11.exe'
  Invoke-WebRequest -Uri $url -OutFile $file -MaximumRedirection 3 -TimeoutSec 100
  $r.actual_bytes = (Get-Item -LiteralPath $file).Length
  $r.actual_sha256 = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($r.actual_bytes -ne $expectedBytes) { throw 'EXACT_RELEASE_SIZE_MISMATCH' }
  if ($r.actual_sha256 -ne $expectedSha) { throw 'EXACT_RELEASE_SHA256_MISMATCH_AGAINST_V20' }
  $r.matched_previous_v20 = $true
  $sign = Get-AuthenticodeSignature -FilePath $file
  $r.installer_signature = [ordered]@{ status=$sign.Status.ToString();signer=if ($sign.SignerCertificate) { $sign.SignerCertificate.Subject } else { $null } }
  $seven = 'C:\Program Files\7-Zip\7z.exe'
  if (-not (Test-Path -LiteralPath $seven)) { throw '7ZIP_NOT_INSTALLED_ON_RUNNER' }
  & $seven l -slt $file | Out-File -Encoding utf8 (Join-Path $Evidence 'archive_listing.txt')
  if ($LASTEXITCODE -ne 0) { throw 'EXE_ARCHIVE_NOT_LISTABLE' }
  $target = Join-Path $env:RUNNER_TEMP 'nars_static_extract'
  New-Item -ItemType Directory -Force -Path $target | Out-Null
  & $seven x "-o$target" -y $file | Out-File -Encoding utf8 (Join-Path $Evidence 'extract_log.txt')
  if ($LASTEXITCODE -ne 0) { throw 'EXE_ARCHIVE_NOT_EXTRACTABLE' }
  $files = @(Get-ChildItem -LiteralPath $target -File -Recurse)
  if ($files.Count -gt 15000) { throw 'EXTRACTED_FILES_EXCEED_LIMIT' }
  foreach ($i in $files) {
    $rel = $i.FullName.Substring($target.Length).TrimStart('\','/')
    $digest = (Get-FileHash -LiteralPath $i.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    $r.extracted += [ordered]@{path=$rel;bytes=$i.Length;sha256=$digest}
  }
  $r.inner_exe_detected = @($files | Where-Object {$_.Name -ieq 'NARS2000.exe'}).Count -gt 0
  try {
    $ws = Join-Path $env:RUNNER_TEMP '2by2.ws.nars'
    Invoke-WebRequest -Uri $wsUrl -OutFile $ws -MaximumRedirection 3 -TimeoutSec 100
    $raw = [System.IO.File]::ReadAllBytes($ws)
    if ($raw.Length -gt 25000000) { throw 'WORKSPACE_TOO_LARGE' }
    $txt = [System.Text.Encoding]::GetEncoding(1252).GetString($raw)
    $headers = @([regex]::Matches($txt,'(?m)^\[[^\]\r\n]+\]\s*$') | ForEach-Object {$_.Value})
    $r.workspace = [ordered]@{url=$wsUrl;bytes=$raw.Length;sha256=(Get-FileHash -LiteralPath $ws -Algorithm SHA256).Hash.ToLowerInvariant();section_count=$headers.Count;section_samples=@($headers | Select-Object -First 18);lx_reference_present=($txt -match '(?i)\{quad\}lx');status='DOWNLOADED_ONLY_NOT_EXECUTED'}
    $headers | Set-Content -Encoding utf8 (Join-Path $Evidence 'workspace_sections.txt')
  } catch { $r.workspace=[ordered]@{url=$wsUrl;status='NOT_AVAILABLE';error=$_.Exception.Message} }
  $r.status='PINNED_RELEASE_EXTRACTED_STATIC_ONLY'
} catch {
  $r.status='FAIL_CLOSED'
  $r.errors += $_.Exception.Message
  throw
} finally {
  $r | ConvertTo-Json -Depth 12 | Set-Content -Encoding utf8 (Join-Path $Evidence 'release_inventory.json')
  Write-Output ('RELEASE_STATUS='+$r.status)
  Write-Output ('MATCH_PREVIOUS_WINDOWS_V20='+$r.matched_previous_v20)
  Write-Output 'NATIVE_EXECUTED=FALSE'
}
