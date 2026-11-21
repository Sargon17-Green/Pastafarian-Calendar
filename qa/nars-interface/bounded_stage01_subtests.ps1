# Source-locked original APL subtest diagnosis on disposable Windows CI only.
# NEVER produces Stage 1 acceptance. 95 FX plus 7 original init/subtest calls.
[CmdletBinding()]
param([string]$Runtime='verified_runtime',[string]$Evidence='subtest_diag_evidence')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$expectedExe='192b7bd3c06a64ef57bfe1ea7f04e5d5d511ae9cd07323cfd211710891e2069d'
$source='7161824b9fcbfaca91f20d1ea492417e77003ff4'
$diagnosticToken='APL_GERMAN_SUBTEST_DIAGNOSTIC_EC_ENDED_NOT_STAGE01'
$boundaries=@((1..18 | ForEach-Object { $_ * 5 }) + @(91,92,93,94,95))
$r=[ordered]@{
 schema='APL_GERMAN_STAGE01_SUBTEST_NATIVE_EVIDENCE_V1'
 status='STARTED'
 stage01='NOT_ACCEPTED'
 source_commit=$source
 runtime_verified=$false
 native_executed=$false
 candidate_sha256=$null
 fx_checkpoints=@()
 fx_last_contiguous=-1
 probes=@()
 last_started_probe=0
 last_completed_probe=0
 final_diagnostic_marker=@{exists=$false;exact=$false}
 process_was_running_at_cutoff=$false
 errors=@()
}
New-Item -ItemType Directory -Force $Evidence | Out-Null
$Evidence=(Resolve-Path -LiteralPath $Evidence).Path
try {
 if(-not $env:RUNNER_TEMP){throw 'RUNNER_TEMP_MISSING'}
 $root=(Resolve-Path -LiteralPath $Runtime).Path
 $exe=Join-Path $root 'NARS2000.exe'
 if(@(Get-ChildItem -LiteralPath $root -File).Count -ne 4){throw 'RUNTIME_FILE_COUNT_NOT_FOUR'}
 if((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash.ToLowerInvariant() -cne $expectedExe){throw 'NARS_EXE_SHA_MISMATCH'}
 if((Get-Item -LiteralPath $exe).VersionInfo.FileVersion -cne '0.5.14.11'){throw 'NARS_VERSION_MISMATCH'}
 $r['runtime_verified']=$true
 $ws=Join-Path $env:RUNNER_TEMP 'official_2by2_stage01_subtest.ws.nars'
 Invoke-WebRequest -Uri 'https://www.nars2000.org/download/workspaces/2by2.ws.nars' -OutFile $ws -MaximumRedirection 3 -TimeoutSec 90
 if((Get-Item -LiteralPath $ws).Length -lt 50 -or (Get-Item -LiteralPath $ws).Length -gt 25000000){throw 'REFERENCE_WORKSPACE_SIZE_INVALID'}
 $r['workspace_source_sha256']=(Get-FileHash -LiteralPath $ws -Algorithm SHA256).Hash.ToLowerInvariant()
 $prefix=Join-Path $env:RUNNER_TEMP 'apl_german_stage01_subtest_diag'
 $candidate=$prefix+'.ws.nars'
 $receipt=Join-Path $Evidence 'subtest_candidate.json'
 $marker=Join-Path $env:RUNNER_TEMP 'apl_german_stage01_subtest_diag.txt'
 if(Test-Path -LiteralPath $marker){throw 'FINAL_MARKER_PREEXISTS'}
 & python qa/nars-interface/stage01_subtest_probe.py --repo-root . --source $ws --candidate $candidate --receipt $receipt --marker $marker
 if($LASTEXITCODE -ne 0){throw 'SUBTEST_PROBE_GENERATION_FAILED'}
 $m=Get-Content -LiteralPath $receipt -Raw | ConvertFrom-Json
 if($m.schema -cne 'APL_GERMAN_STAGE01_SUBTEST_DIAGNOSTIC_V1' -or $m.status -cne 'GENERATED_NOT_NATIVE_VALIDATED' -or $m.stage01 -cne 'NOT_ACCEPTED' -or $m.native_executed -ne $false -or $m.source_commit -cne $source -or $m.function_count -ne 95 -or $m.chunk_count -ne 23 -or $m.chunk_records.Count -ne 23 -or $m.probe_count -ne 7 -or $m.probes.Count -ne 7 -or $m.marker_path -cne $marker -or $m.marker_token -cne $diagnosticToken -or $m.final_original_stage01_tests_executed -ne $false -or $m.original_stage01_acceptance_token_present -ne $false){throw 'SUBTEST_DIAGNOSTIC_RECEIPT_INVALID'}
 for($i=0;$i -lt $boundaries.Count;$i++){
   $p=$m.chunk_records[$i]
   $after=$boundaries[$i]
   $path=Join-Path $env:RUNNER_TEMP ('apl_german_stage01_subtest_diag_after_{0:D2}.txt' -f $after)
   $previous=if($i -eq 0){0}else{$boundaries[$i-1]}
   if($p.after -ne $after -or $p.fx_in_chunk -ne ($after-$previous) -or $p.marker_path -cne $path){throw 'FX_CHUNK_LAYOUT_INVALID'}
   if(Test-Path -LiteralPath $path){throw 'CHUNK_MARKER_PREEXISTS'}
 }
 for($i=0;$i -lt $m.probes.Count;$i++){
   $p=$m.probes[$i]
   $n=$i+1
   if($p.index -ne $n){throw 'PROBE_SEQUENCE_MISMATCH'}
   foreach($phase in @('start','end')){
     $expected=Join-Path $env:RUNNER_TEMP ('apl_german_stage01_subtest_diag_probe_{0:D2}_{1}.txt' -f $n,$phase)
     $field=$phase+'_path'
     $tField=$phase+'_token'
     $hField=$phase+'_sha256'
     if($p.$field -cne $expected){throw 'PROBE_PATH_MISMATCH'}
     if(Test-Path -LiteralPath $expected){throw 'PROBE_MARKER_PREEXISTS'}
     $actualHash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::ASCII.GetBytes([string]$p.$tField))).ToLowerInvariant()
     if($actualHash -cne $p.$hField){throw 'PROBE_TOKEN_HASH_MISMATCH'}
   }
 }
 $candidateHash=(Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash.ToLowerInvariant()
 if($candidateHash -cne $m.candidate_sha256){throw 'DIAGNOSTIC_CANDIDATE_SHA_MISMATCH'}
 $r['candidate_sha256']=$candidateHash
 $r['manifest_sha256']=(Get-FileHash -LiteralPath $receipt -Algorithm SHA256).Hash.ToLowerInvariant()
 $p=Start-Process -FilePath $exe -ArgumentList ('"'+$prefix+'"') -WorkingDirectory $root -PassThru
 $r['native_executed']=$true
 $r['process_id']=$p.Id
 $deadline=[DateTime]::UtcNow.AddSeconds(300)
 $wanted=[Text.Encoding]::ASCII.GetBytes($diagnosticToken)
 while([DateTime]::UtcNow -lt $deadline){
   if(Test-Path -LiteralPath $marker -PathType Leaf){
     if((Get-Item -LiteralPath $marker).Length -ge $wanted.Length){break}
   }
   Start-Sleep -Milliseconds 250
   $p.Refresh()
   if($p.HasExited){break}
 }
 $p.Refresh()
 $wasRunning=-not $p.HasExited
 $r['process_was_running_at_cutoff']=$wasRunning
 if($wasRunning){
   try {
     Add-Type -AssemblyName System.Windows.Forms
     Add-Type -AssemblyName System.Drawing
     $bounds=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds
     $bmp=New-Object System.Drawing.Bitmap($bounds.Width,$bounds.Height)
     $g=[System.Drawing.Graphics]::FromImage($bmp)
     $g.CopyFromScreen($bounds.Location,[System.Drawing.Point]::Empty,$bounds.Size)
     $bmp.Save((Join-Path $Evidence 'native_at_cutoff.png'),[System.Drawing.Imaging.ImageFormat]::Png)
     $g.Dispose()
     $bmp.Dispose()
   } catch {
     $r['errors']+=('SCREENSHOT_UNAVAILABLE:'+ $_.Exception.Message)
   }
   & taskkill.exe /PID $p.Id /T /F 2>&1 | Out-Null
   try{Wait-Process -Id $p.Id -Timeout 8 -ErrorAction Stop}catch{}
   $p.Refresh()
 }
 if(-not $p.HasExited){throw 'NARS_PROCESS_NOT_TERMINATED'}
 $checkpointDir=Join-Path $Evidence 'checkpoint_files'
 $probeDir=Join-Path $Evidence 'probe_files'
 New-Item -ItemType Directory -Force $checkpointDir,$probeDir | Out-Null
 function Test-ExactMarker([string]$Path,[string]$Token,[string]$Archive) {
   $exists=Test-Path -LiteralPath $Path -PathType Leaf
   [byte[]]$actual=@()
   if($exists){
     $actual=[IO.File]::ReadAllBytes($Path)
     Copy-Item -LiteralPath $Path -Destination $Archive -Force
   }
   [byte[]]$expect=[Text.Encoding]::ASCII.GetBytes($Token)
   $exact=$exists -and $actual.Length -eq $expect.Length -and ([Convert]::ToBase64String($actual) -ceq [Convert]::ToBase64String($expect))
   return @{exists=[bool]$exists;exact=[bool]$exact;bytes=$actual.Length;
            sha256=if($exists){(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()}else{$null}}
 }
 $lastFx=0
 for($i=0;$i -lt $m.chunk_records.Count;$i++){
   $s=$m.chunk_records[$i]
   $check=Test-ExactMarker -Path $s.marker_path -Token $s.token -Archive (Join-Path $checkpointDir ('after_{0:D2}.txt' -f [int]$s.after))
   $r['fx_checkpoints']+=@{after=[int]$s.after;name=[string]$s.name;exact=[bool]$check.exact;exists=[bool]$check.exists;sha256=$check.sha256}
   if($check.exact -and $lastFx -eq $(if($i -eq 0){0}else{[int]$m.chunk_records[$i-1].after})){$lastFx=[int]$s.after}
 }
 $r['fx_last_contiguous']=$lastFx
 $lastStart=0
 $lastEnd=0
 for($i=0;$i -lt $m.probes.Count;$i++){
   $s=$m.probes[$i]
   $start=Test-ExactMarker -Path $s.start_path -Token $s.start_token -Archive (Join-Path $probeDir ('probe_{0:D2}_start.txt' -f $s.index))
   $end=Test-ExactMarker -Path $s.end_path -Token $s.end_token -Archive (Join-Path $probeDir ('probe_{0:D2}_end.txt' -f $s.index))
   $r['probes']+=@{index=[int]$s.index;name=[string]$s.name;start=$start;end=$end}
   if($start.exact){$lastStart=[int]$s.index}
   if($end.exact){$lastEnd=[int]$s.index}
 }
 $r['last_started_probe']=$lastStart
 $r['last_completed_probe']=$lastEnd
 $final=Test-ExactMarker -Path $marker -Token $diagnosticToken -Archive (Join-Path $Evidence 'diagnostic_final_marker.txt')
 $r['final_diagnostic_marker']=$final
 $complete=$lastFx -eq 95 -and $lastEnd -eq 7 -and $final.exact -and @($r['fx_checkpoints'] | Where-Object {$_.exact -ne $true}).Count -eq 0
 if($complete){$complete=@($r['probes'] | Where-Object { $_.start.exact -ne $true -or $_.end.exact -ne $true }).Count -eq 0}
 $r['status']=if($complete){'ALL_ORIGINAL_SUBTESTS_DIAGNOSTIC_COMPLETE_NOT_STAGE01'}else{'SUBTESTS_DIAGNOSTIC_PARTIAL_NOT_STAGE01'}
}catch{
 $r['status']='FAIL_CLOSED_NOT_STAGE01'
 $r['errors']+= $_.Exception.Message
 throw
}finally{
 $r | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath (Join-Path $Evidence 'native_subtest_diag.json') -Encoding utf8
 Write-Output ('STAGE01_DIAG_STATUS='+$r['status'])
 Write-Output ('STAGE01_DIAG_FX_LAST='+$r['fx_last_contiguous'])
 Write-Output ('STAGE01_DIAG_LAST_START='+$r['last_started_probe'])
 Write-Output ('STAGE01_DIAG_LAST_END='+$r['last_completed_probe'])
 Write-Output ('STAGE01_DIAG_FINAL='+$r['final_diagnostic_marker'].exact)
 Write-Output 'STAGE01=NOT_ACCEPTED'
}
