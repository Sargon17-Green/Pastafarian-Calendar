# Disposable GitHub Windows VM only. Diagnostic checkpoints, NEVER Stage 1 acceptance.
[CmdletBinding()]
param([string]$Runtime='verified_runtime',[string]$Evidence='chunked_fx_evidence',[int]$Count=15)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
if($Count -notin @(15,20)){throw 'CHUNKED_COUNT_INVALID'}
New-Item -ItemType Directory -Force $Evidence | Out-Null
$Evidence=(Resolve-Path -LiteralPath $Evidence).Path
$expectedExe='192b7bd3c06a64ef57bfe1ea7f04e5d5d511ae9cd07323cfd211710891e2069d'
$source='7161824b9fcbfaca91f20d1ea492417e77003ff4'
$indices=if($Count -eq 15){@(5,10,15)}else{@(5,10,15,20)}
$r=[ordered]@{
 schema='APL_GERMAN_NATIVE_FX_CHUNKED_RUN_V1'
 status='STARTED'
 count=$Count
 stage01='NOT_RUN'
 source_commit=$source
 runtime_verified=$false
 candidate_sha256=$null
 interpreter_executed=$false
 final_marker=@{exists=$false;exact=$false}
 checkpoints=@()
 last_contiguous_after=-1
 noncontiguous_exact=$false
 errors=@()
}
try {
 if(-not $env:RUNNER_TEMP){throw 'RUNNER_TEMP_MISSING'}
 $root=(Resolve-Path -LiteralPath $Runtime).Path
 $exe=Join-Path $root 'NARS2000.exe'
 if(@(Get-ChildItem -LiteralPath $root -File).Count -ne 4){throw 'RUNTIME_FILE_COUNT_NOT_FOUR'}
 if((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash.ToLowerInvariant() -cne $expectedExe){throw 'NARS_EXE_SHA_MISMATCH'}
 if((Get-Item -LiteralPath $exe).VersionInfo.FileVersion -cne '0.5.14.11'){throw 'NARS_VERSION_MISMATCH'}
 $r['runtime_verified']=$true
 $ws=Join-Path $env:RUNNER_TEMP 'official_2by2_chunked.ws.nars'
 Invoke-WebRequest -Uri 'https://www.nars2000.org/download/workspaces/2by2.ws.nars' -OutFile $ws -MaximumRedirection 3 -TimeoutSec 90
 if((Get-Item -LiteralPath $ws).Length -lt 50 -or (Get-Item -LiteralPath $ws).Length -gt 25000000){throw 'REFERENCE_WORKSPACE_SIZE_OUT_OF_BOUNDS'}
 $r['workspace_source_sha256']=(Get-FileHash -LiteralPath $ws -Algorithm SHA256).Hash.ToLowerInvariant()
 $prefix=Join-Path $env:RUNNER_TEMP ('apl_german_chunked_fx_'+$Count)
 $candidate=$prefix+'.ws.nars'
 $receipt=Join-Path $Evidence 'progress_candidate.json'
 $marker=Join-Path $env:RUNNER_TEMP ('apl_german_chunked_fx_'+$Count+'.txt')
 if(Test-Path -LiteralPath $marker){throw 'FINAL_MARKER_PREEXISTS'}
 & python qa/nars-interface/chunked_fx_probe.py --repo-root . --source $ws --candidate $candidate --receipt $receipt --marker $marker --count $Count
 if($LASTEXITCODE -ne 0){throw 'PROGRESS_GENERATOR_FAILED'}
 $meta=Get-Content -LiteralPath $receipt -Raw | ConvertFrom-Json
 if($meta.status -cne 'GENERATED_NOT_NATIVE_VALIDATED' -or $meta.native_executed -ne $false -or $meta.stage01 -cne 'NOT_RUN' -or $meta.count -ne $Count -or $meta.chunk_size -ne 5 -or $meta.chunk_count -ne ($Count / 5) -or $meta.source_commit -cne $source){throw 'CANDIDATE_METADATA_CONTRACT_FAILED'}
 if($meta.marker_path -cne $marker -or $meta.stages.Count -ne ($Count / 5) -or $meta.names.Count -ne $Count -or @($meta.names | Sort-Object -Unique).Count -ne $Count){throw 'CANDIDATE_MANIFEST_COUNT_OR_PATH_INVALID'}
 foreach($i in 0..($indices.Count-1)){
   $point=$meta.stages[$i]
   $after=$indices[$i]
   $expectedPath=Join-Path $env:RUNNER_TEMP (('apl_german_chunked_fx_'+$Count+'_after_{0:D2}.txt') -f $after)
   if($point.after -ne $after -or $point.marker_path -cne $expectedPath){throw 'CHECKPOINT_PATH_OR_INDEX_MISMATCH'}
   if(Test-Path -LiteralPath $expectedPath){throw 'CHECKPOINT_PREEXISTS'}
   if($point.name -cne $meta.names[$after-1]){throw 'CHECKPOINT_NAME_MISMATCH'}
   [byte[]]$expectedToken=[Text.Encoding]::ASCII.GetBytes([string]$point.token)
   $tokenSha=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($expectedToken)).ToLowerInvariant()
   if($point.expected_bytes -ne $expectedToken.Length -or $point.token_sha256 -cne $tokenSha){throw 'CHECKPOINT_TOKEN_HASH_MISMATCH'}
   $expectedName=if($after -eq 0){'START'}else{[string]$meta.names[$after-1]}
   if($point.name -cne $expectedName){throw 'CHECKPOINT_FUNCTION_NAME_MISMATCH'}
 }
 $csha=(Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash.ToLowerInvariant()
 if($csha -cne $meta.candidate_sha256){throw 'CANDIDATE_HASH_MISMATCH'}
 $r['candidate_sha256']=$csha
 $r['checkpoint_manifest_sha256']=(Get-FileHash -LiteralPath $receipt -Algorithm SHA256).Hash.ToLowerInvariant()
 $r['outer_lx_chars']=[int]$meta.outer_lx_chars
 $p=Start-Process -FilePath $exe -ArgumentList ('"'+$prefix+'"') -WorkingDirectory $root -PassThru
 $r['interpreter_executed']=$true
 $r['process_id']=$p.Id
 $deadline=[DateTime]::UtcNow.AddSeconds(90)
 $want=[Text.Encoding]::ASCII.GetBytes([string]$meta.marker_token)
 while([DateTime]::UtcNow -lt $deadline){
   if(Test-Path -LiteralPath $marker -PathType Leaf){
     if((Get-Item -LiteralPath $marker).Length -ge $want.Length){break}
   }
   Start-Sleep -Milliseconds 250
   $p.Refresh()
   if($p.HasExited){break}
 }
 $p.Refresh()
 $wasRunning=-not $p.HasExited
 $r['process_was_running_at_cutoff']=$wasRunning
 $r['native_fx']='NOT_CONFIRMED'
 if($wasRunning){
   & taskkill.exe /PID $p.Id /T /F 2>&1 | Out-Null
   try{Wait-Process -Id $p.Id -Timeout 8 -ErrorAction Stop}catch{}
   $p.Refresh()
 }
 if(-not $p.HasExited){throw 'NARS_PROCESS_NOT_TERMINATED'}
 # File handles from ⎕NCREATE can remain exclusive until NARS exits.
 # Read and hash all native evidence ONLY after process termination.
 $target=Join-Path $Evidence 'checkpoint_files'
 New-Item -ItemType Directory -Force $target | Out-Null
 $gap=$false
 $last=-1
 $inconsistent=$false
 $rows=@()
 for($i=0;$i -lt $indices.Count;$i++){
   $point=$meta.stages[$i]
   $path=[string]$point.marker_path
   $exists=Test-Path -LiteralPath $path -PathType Leaf
   [byte[]]$bytes=@()
   if($exists){
     $bytes=[IO.File]::ReadAllBytes($path)
     Copy-Item -LiteralPath $path -Destination (Join-Path $target ('after_{0:D2}.txt' -f [int]$point.after)) -Force
   }
   [byte[]]$expected=[Text.Encoding]::ASCII.GetBytes([string]$point.token)
   $match=$exists -and $bytes.Length -eq $expected.Length -and ([Convert]::ToBase64String($bytes) -ceq [Convert]::ToBase64String($expected))
   if(-not $match){$gap=$true}
   if($match -and $gap){$inconsistent=$true}
   if($match -and -not $gap){$last=[int]$point.after}
   $sha=if($exists){(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()}else{$null}
   $rows+=@{after=[int]$point.after;name=[string]$point.name;exists=[bool]$exists;exact=[bool]$match;bytes=$bytes.Length;sha256=$sha}
 }
 $r['checkpoints']=$rows
 $r['last_contiguous_after']=$last
 $r['noncontiguous_exact']=$inconsistent
 $existsFinal=Test-Path -LiteralPath $marker -PathType Leaf
 [byte[]]$actualFinal=@()
 if($existsFinal){
   $actualFinal=[IO.File]::ReadAllBytes($marker)
   Copy-Item -LiteralPath $marker -Destination (Join-Path $Evidence 'final_native_marker.txt') -Force
 }
 $matchFinal=$existsFinal -and $actualFinal.Length -eq $want.Length -and ([Convert]::ToBase64String($actualFinal) -ceq [Convert]::ToBase64String($want))
 $finalSha=if($existsFinal){(Get-FileHash -LiteralPath $marker -Algorithm SHA256).Hash.ToLowerInvariant()}else{$null}
 $r['final_marker']=@{exists=[bool]$existsFinal;exact=[bool]$matchFinal;bytes=$actualFinal.Length;expected_bytes=$want.Length;sha256=$finalSha}
 $success=$matchFinal -and $last -eq $Count -and -not $inconsistent
 $r['native_fx']=if($success){'CONFIRMED'}else{'NOT_CONFIRMED'}
 $r['status']=if($success){'NATIVE_CHUNKED_FX'+$Count+'_CONFIRMED_NOT_STAGE01'}else{'NATIVE_CHUNKED_FX'+$Count+'_NOT_CONFIRMED'}
}catch{
 $r['status']='FAIL_CLOSED'
 $r['errors']+= $_.Exception.Message
 throw
}finally{
 $r | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath (Join-Path $Evidence 'native_fx_progress.json') -Encoding utf8
 Write-Output ('CHUNKED_FX_STATUS='+$r['status'])
 Write-Output ('CHUNKED_FX_LAST_CONTIGUOUS_AFTER='+$r['last_contiguous_after'])
 Write-Output ('CHUNKED_FX_NONCONTIGUOUS_EXACT='+$r['noncontiguous_exact'])
 Write-Output ('CHUNKED_FX_FINAL_MARKER_EXACT='+$r['final_marker'].exact)
 Write-Output 'STAGE01=NOT_RUN'
}
