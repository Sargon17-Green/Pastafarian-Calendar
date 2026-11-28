# Disposable GitHub Windows VM. Stage1 acceptance only with original suite and independent byte gate.
[CmdletBinding()]
param([string]$Runtime='verified_runtime',[string]$Evidence='stage01_chunked_evidence')
$Count=95
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
if($Count -ne 95){throw 'STAGE01_95_REQUIRED'}
New-Item -ItemType Directory -Force $Evidence | Out-Null
$Evidence=(Resolve-Path -LiteralPath $Evidence).Path
$expectedExe='192b7bd3c06a64ef57bfe1ea7f04e5d5d511ae9cd07323cfd211710891e2069d'
$source='8712a5242e8626f7878a2415d4a2d907d3961486'
$indices=@((1..18 | ForEach-Object { $_ * 5 }) + @(91,92,93,94,95))
if($indices.Count -ne 23 -or $indices[-1] -ne 95){throw 'STAGE01_TAIL_CHUNK_BOUNDARIES_INVALID'}
$acceptToken='APL_GERMAN_STAGE01_NATIVE_PASS_V1|SOURCE=8712a5242e8626f7878a2415d4a2d907d3961486|FILES=5|FX=95|TEST=STAGE01_PASS'
$r=[ordered]@{
 schema='APL_GERMAN_STAGE01_NATIVE_CHUNKED_V1'
 status='STARTED'
 count=$Count
 stage01='NOT_ACCEPTED'
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
 $ws=Join-Path $env:RUNNER_TEMP 'official_2by2_chunked_stage01.ws.nars'
 Invoke-WebRequest -Uri 'https://www.nars2000.org/download/workspaces/2by2.ws.nars' -OutFile $ws -MaximumRedirection 3 -TimeoutSec 90
 if((Get-Item -LiteralPath $ws).Length -lt 50 -or (Get-Item -LiteralPath $ws).Length -gt 25000000){throw 'REFERENCE_WORKSPACE_SIZE_OUT_OF_BOUNDS'}
 $r['workspace_source_sha256']=(Get-FileHash -LiteralPath $ws -Algorithm SHA256).Hash.ToLowerInvariant()
 $prefix=Join-Path $env:RUNNER_TEMP 'apl_german_stage01_chunked_candidate'
 $candidate=$prefix+'.ws.nars'
 $receipt=Join-Path $Evidence 'progress_candidate.json'
 $marker=Join-Path $env:RUNNER_TEMP 'apl_german_stage01_chunked.txt'
 if(Test-Path -LiteralPath $marker){throw 'FINAL_MARKER_PREEXISTS'}
 & python qa/nars-interface/stage01_authorized_import.py --repo-root . --source $ws --candidate $candidate --receipt $receipt --marker $marker
 if($LASTEXITCODE -ne 0){throw 'PROGRESS_GENERATOR_FAILED'}
 $meta=Get-Content -LiteralPath $receipt -Raw | ConvertFrom-Json
 if($meta.schema -cne 'APL_GERMAN_STAGE01_CHUNKED_CANDIDATE_V1' -or $meta.status -cne 'GENERATED_NOT_NATIVE_VALIDATED' -or $meta.native_executed -ne $false -or $meta.stage01 -cne 'NOT_ACCEPTED' -or $meta.function_count -ne 95 -or $meta.unique_function_count -ne 95 -or $meta.source_file_count -ne 5 -or $meta.chunk_size -ne 5 -or $meta.tail_start -ne 90 -or $meta.tail_chunk_size -ne 1 -or $meta.chunk_count -ne 23 -or $meta.source_commit -cne $source -or $meta.test_entrypoint -cne 'RunStage01Tests' -or $meta.final_expression -cne 'SAME_EC_AFTER_TEST'){throw 'STAGE01_CANDIDATE_METADATA_CONTRACT_FAILED'}
 if($meta.marker_token -cne $acceptToken){throw 'STAGE01_ACCEPTANCE_TOKEN_MISMATCH'}
 if($meta.marker_path -cne $marker -or $meta.chunk_records.Count -ne 23 -or $meta.function_names.Count -ne 95 -or @($meta.function_names | Sort-Object -Unique).Count -ne 95){throw 'STAGE01_CANDIDATE_MANIFEST_INVALID'}
 foreach($i in 0..($indices.Count-1)){
   $point=$meta.chunk_records[$i]
   $after=$indices[$i]
   $expectedPath=Join-Path $env:RUNNER_TEMP (('apl_german_stage01_chunked_after_{0:D2}.txt') -f $after)
   $previous=if($i -eq 0){0}else{[int]$indices[$i-1]}
   if($point.fx_in_chunk -ne ($after-$previous)){throw 'CHECKPOINT_FUNCTIONS_PER_CHUNK_MISMATCH'}
   if($point.after -ne $after -or $point.marker_path -cne $expectedPath){throw 'CHECKPOINT_PATH_OR_INDEX_MISMATCH'}
   if(Test-Path -LiteralPath $expectedPath){throw 'CHECKPOINT_PREEXISTS'}
   if($point.name -cne $meta.function_names[$after-1]){throw 'CHECKPOINT_NAME_MISMATCH'}
   [byte[]]$expectedToken=[Text.Encoding]::ASCII.GetBytes([string]$point.token)
   $tokenSha=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($expectedToken)).ToLowerInvariant()
   if($point.expected_bytes -ne $expectedToken.Length -or $point.token_sha256 -cne $tokenSha){throw 'CHECKPOINT_TOKEN_HASH_MISMATCH'}
   $expectedName=if($after -eq 0){'START'}else{[string]$meta.function_names[$after-1]}
   if($point.name -cne $expectedName){throw 'CHECKPOINT_FUNCTION_NAME_MISMATCH'}
 }
 $csha=(Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash.ToLowerInvariant()
 if($csha -cne $meta.candidate_sha256){throw 'CANDIDATE_HASH_MISMATCH'}
 $r['candidate_sha256']=$csha
 $r['checkpoint_manifest_sha256']=(Get-FileHash -LiteralPath $receipt -Algorithm SHA256).Hash.ToLowerInvariant()
 $r['outer_lx_chars']=[int]$meta.outer_lx_chars
 foreach($key in @('start','return','ec','et','payload','done','trace_helper_fx','trace_main_fx','trace_run_fx','trace','trace_ec','trace_et','trace_payload','trace_def_count','trace_compile_ec','trace_compile_et','trace_compile_payload','probe_actual_ec','probe_actual_et','probe_actual_payload','probe_rank_ec','probe_rank_et','probe_rank_payload','probe_type_ec','probe_type_et','probe_type_payload','probe_match_ec','probe_match_et','probe_match_payload','probe_explicit_ec','probe_explicit_et','probe_explicit_payload','probe_production_actual_ec','probe_production_actual_et','probe_production_actual_payload','probe_production_explicit_ec','probe_production_explicit_et','probe_production_explicit_payload','probe_assert_ec','probe_assert_et','probe_assert_payload')) {
   $expectedPath=Join-Path $env:RUNNER_TEMP ('apl_german_stage01_chunked_suite_'+$key+'.txt')
   if($meta.suite_paths.$key -cne $expectedPath -or (Test-Path -LiteralPath $expectedPath)){throw 'SUITE_RECEIPT_PATH_INVALID_OR_PREEXISTS'}
 }
 $r['qa_commit']=$env:GITHUB_SHA
 $p=Start-Process -FilePath $exe -ArgumentList ('"'+$prefix+'"') -WorkingDirectory $root -PassThru
 $r['interpreter_executed']=$true
 $r['process_id']=$p.Id
 $deadline=[DateTime]::UtcNow.AddSeconds(600)
 $want=[Text.Encoding]::ASCII.GetBytes([string]$meta.marker_token)
 while([DateTime]::UtcNow -lt $deadline){
   if(Test-Path -LiteralPath $meta.suite_paths.done -PathType Leaf){
     if((Get-Item -LiteralPath $meta.suite_paths.done).Length -ge 1){break}
   }
   Start-Sleep -Milliseconds 250
   $p.Refresh()
   if($p.HasExited){break}
 }
 $p.Refresh()
 $wasRunning=-not $p.HasExited
 $r['process_was_running_at_cutoff']=$wasRunning
 $r['deadline_elapsed']=([DateTime]::UtcNow -ge $deadline)
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
   $point=$meta.chunk_records[$i]
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
 $suite=@{}
 foreach($key in @('start','return','ec','et','payload','done','trace_helper_fx','trace_main_fx','trace_run_fx','trace','trace_ec','trace_et','trace_payload','trace_def_count','trace_compile_ec','trace_compile_et','trace_compile_payload','probe_actual_ec','probe_actual_et','probe_actual_payload','probe_rank_ec','probe_rank_et','probe_rank_payload','probe_type_ec','probe_type_et','probe_type_payload','probe_match_ec','probe_match_et','probe_match_payload','probe_explicit_ec','probe_explicit_et','probe_explicit_payload','probe_production_actual_ec','probe_production_actual_et','probe_production_actual_payload','probe_production_explicit_ec','probe_production_explicit_et','probe_production_explicit_payload','probe_assert_ec','probe_assert_et','probe_assert_payload')){
   $path=[string]$meta.suite_paths.$key
   if(Test-Path -LiteralPath $path -PathType Leaf){
     Copy-Item -LiteralPath $path -Destination (Join-Path $Evidence ('suite_'+$key+'.txt')) -Force
     $suite[$key]=[IO.File]::ReadAllText($path)
   }else{$suite[$key]=$null}
 }
 $r['suite_start_exact']=($suite.start -ceq ('APL_GERMAN_STAGE01_START|SOURCE='+$source))
 $r['suite_return_exact']=($suite.return -ceq ('APL_GERMAN_STAGE01_RETURN|SOURCE='+$source))
 $r['suite_receipts_attempted_exact']=($suite.done -ceq ('APL_GERMAN_STAGE01_RECEIPTS_ATTEMPTED|SOURCE='+$source))
 $r['suite_ec']=$suite.ec
 $r['suite_error_type']=$suite.et
 $r['suite_payload']=$suite.payload
 # Diagnostics never participate in acceptance. Validate the raw trace as
 # an exact prefix of its source-anchored ordered token manifest.
 $r['trace_definition_count']=$suite.trace_def_count
 $r['trace_compile_ec']=$suite.trace_compile_ec
 $r['trace_compile_et']=$suite.trace_compile_et
 $r['trace_compile_payload']=$suite.trace_compile_payload
 $r['trace_compile_exact']=($suite.trace_helper_fx -ceq 'QAS01T' -and $suite.trace_main_fx -ceq 'QAS01TraceMain' -and $suite.trace_run_fx -ceq 'QAS01TraceRun' -and $suite.trace_def_count -ceq [string]$meta.trace_definition_lines -and $suite.trace_compile_ec -cin @('1','2'))
 $r['trace_ec']=$suite.trace_ec
 $r['trace_et']=$suite.trace_et
 $r['trace_payload']=$suite.trace_payload
 $r['trace_prefix_exact']=$false
 $r['trace_events']=@()
 $r['trace_next_expected']=$null
 $traceHeader=('APL_GERMAN_STAGE01_TRACE_V1|SOURCE='+$source+'|')
 if($meta.trace_header -cne $traceHeader -or $meta.trace_diagnostic_only -ne $true -or $meta.trace_tokens.Count -ne 100){throw 'TRACE_METADATA_CONTRACT_FAILED'}
 if($null -ne $suite.trace -and $suite.trace.StartsWith($traceHeader,[StringComparison]::Ordinal)){
   $body=$suite.trace.Substring($traceHeader.Length)
   if($body.Length % 5 -eq 0 -and $body.Length -le 5*$meta.trace_tokens.Count){
     $n=[int]($body.Length/5)
     $valid=$true
     $events=@()
     for($i=0;$i -lt $n;$i++){
       $event=$body.Substring(5*$i,5)
       $events+= $event
       if($event -cne $meta.trace_tokens[$i]){$valid=$false}
     }
     $r['trace_prefix_exact']=$valid
     $r['trace_events']=$events
     if($valid -and $n -lt $meta.trace_tokens.Count){$r['trace_next_expected']=$meta.trace_tokens[$n]}
   }
 }
 $ecValue=([string]$suite.ec).Trim()
 $r['suite_status']=if($ecValue -cin @('1','2')){'RETURNED_SUCCESS'}elseif($ecValue -ceq '0'){'RETURNED_ERROR'}elseif($r['suite_receipts_attempted_exact'] -or $null -ne $suite.payload -or $null -ne $suite.et){'RECEIPT_CAPTURE_FAILURE'}elseif($r['deadline_elapsed']){'TIMEOUT_NO_EC'}else{'NO_EC_RECEIPT'}
 $fxOK=(($last -eq 95) -and (-not $inconsistent) -and (@($rows | Where-Object { $_.exact -ne $true }).Count -eq 0))
 $success=($matchFinal -and $fxOK -and $r['suite_start_exact'] -and $r['suite_return_exact'] -and $r['suite_receipts_attempted_exact'] -and $r['suite_status'] -ceq 'RETURNED_SUCCESS' -and $want.Length -eq 113)
 $r['native_fx']=if($fxOK){'CONFIRMED'}else{'NOT_CONFIRMED'}
 $r['stage01']=if($success){'ACCEPTED'}else{'NOT_ACCEPTED'}
 $r['status']=if($success){'NATIVE_STAGE01_CHUNKED_ACCEPTED'}else{'NATIVE_STAGE01_CHUNKED_NOT_ACCEPTED'}
}catch{
 $r['status']='FAIL_CLOSED'
 $r['errors']+= $_.Exception.Message
 throw
}finally{
 $r | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath (Join-Path $Evidence 'native_fx_progress.json') -Encoding utf8
 Write-Output ('STAGE01_CHUNKED_STATUS='+$r['status'])
 Write-Output ('STAGE01_FX_LAST_CONTIGUOUS_AFTER='+$r['last_contiguous_after'])
 Write-Output ('STAGE01_FX_NONCONTIGUOUS_EXACT='+$r['noncontiguous_exact'])
 Write-Output ('STAGE01_FINAL_MARKER_EXACT='+$r['final_marker'].exact)
 Write-Output ('STAGE01='+$r['stage01'])
}
