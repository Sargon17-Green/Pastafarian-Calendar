# QA-only source-locked BoundedUnrank witness. NEVER Stage1 acceptance.
[CmdletBinding()]
param(
  [string]$Runtime='verified_runtime',
  [string]$Evidence='bounded_unrank_evidence'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$source='7161824b9fcbfaca91f20d1ea492417e77003ff4'
New-Item -ItemType Directory -Force $Evidence | Out-Null
$Evidence=(Resolve-Path -LiteralPath $Evidence).Path
$r=[ordered]@{
  schema='APL_GERMAN_NATIVE_BOUNDED_UNRANK_WITNESS_V1'
  source_commit=$source
  qa_commit=$env:GITHUB_SHA
  stage01='NOT_ACCEPTED'
  status='STARTED'
  native_executed=$false
  runtime_verified=$false
  process_stopped=$false
  elapsed_seconds=$null
  candidate_sha256=$null
  fx_last_contiguous=0
  fx_all_exact=$false
  fx_checkpoints=@()
  compile_exact=$false
  compile_name_exact=$false
  witness_start_exact=$false
  witness_captured_exact=$false
  final_marker_exact=$false
  original_ec_valid=$false
  original_ec=$null
  trace_ec_valid=$false
  trace_ec=$null
  trace_log_valid=$false
  trace_log=@()
  trace_last_stage=$null
  witness_files=[ordered]@{}
  errors=@()
}
$exitCode=0

function ReadExact([string]$path,[string]$wanted,[string]$dest){
  if(-not(Test-Path -LiteralPath $path -PathType Leaf)){
    return @{exact=$false;sha256=$null;bytes=0}
  }
  [byte[]]$data=[IO.File]::ReadAllBytes($path)
  Copy-Item -LiteralPath $path -Destination $dest -Force
  [byte[]]$expected=[Text.Encoding]::ASCII.GetBytes($wanted)
  $equal=($data.Length -eq $expected.Length) -and
    ([Convert]::ToBase64String($data) -ceq [Convert]::ToBase64String($expected))
  return @{
    exact=[bool]$equal
    sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    bytes=$data.Length
  }
}

function ReadNumbers([string]$path,[string]$dest){
  if(-not(Test-Path -LiteralPath $path -PathType Leaf)){
    return @{valid=$false;values=@();sha256=$null}
  }
  [byte[]]$data=[IO.File]::ReadAllBytes($path)
  Copy-Item -LiteralPath $path -Destination $dest -Force
  $sha=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
  if($data.Length -lt 1 -or $data.Length -gt 8192){
    return @{valid=$false;values=@();sha256=$sha}
  }
  $s=[Text.Encoding]::ASCII.GetString($data)
  if($s -cnotmatch '^\s*[¯-]?\d+[xX]?(\s+[¯-]?\d+[xX]?)*\s*
}

try {
  if(-not $env:RUNNER_TEMP){throw 'RUNNER_TEMP_MISSING'}
  $rt=(Resolve-Path -LiteralPath $Runtime).Path
  $exe=Join-Path $rt 'NARS2000.exe'
  if(@(Get-ChildItem $rt -File).Count -ne 4){throw 'RUNTIME_FILE_COUNT_INVALID'}
  if((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash.ToLowerInvariant() -cne '192b7bd3c06a64ef57bfe1ea7f04e5d5d511ae9cd07323cfd211710891e2069d'){throw 'NARS_EXE_SHA_MISMATCH'}
  if((Get-Item -LiteralPath $exe).VersionInfo.FileVersion -cne '0.5.14.11'){throw 'NARS_VERSION_MISMATCH'}
  $r['runtime_verified']=$true

  $official=Join-Path $env:RUNNER_TEMP 'nars_2by2_pair.ws.nars'
  Invoke-WebRequest -Uri 'https://www.nars2000.org/download/workspaces/2by2.ws.nars' -OutFile $official -TimeoutSec 90 -MaximumRedirection 3
  if((Get-FileHash -LiteralPath $official -Algorithm SHA256).Hash.ToLowerInvariant() -cne '2eba3f2eb9f826b992ffaf4054db9a09da38f4ae2687168173be4a16fd08b11b'){throw 'BASE_WORKSPACE_SHA_MISMATCH'}

  $prefix=Join-Path $env:RUNNER_TEMP 'apl_german_bounded_unrank_v27'
  $marker=$prefix+'.txt'
  $candidate=$prefix+'.ws.nars'
  $candidateReceipt=Join-Path $Evidence 'bounded_unrank_candidate.json'
  if(Test-Path -LiteralPath $marker){throw 'PREEXISTING_FINAL_MARKER'}
  & python qa/nars-interface/stage01_bounded_unrank_witness.py --repo-root . --source $official --candidate $candidate --receipt $candidateReceipt --marker $marker
  if($LASTEXITCODE -ne 0){throw 'BOUNDED_UNRANK_CANDIDATE_GENERATION_FAILED'}
  $m=Get-Content -LiteralPath $candidateReceipt -Raw | ConvertFrom-Json

  if($m.schema -cne 'APL_GERMAN_STAGE01_BOUNDED_UNRANK_WITNESS_V1' -or
     $m.status -cne 'GENERATED_NOT_NATIVE_VALIDATED' -or
     $m.stage01 -cne 'NOT_ACCEPTED' -or
     $m.source_commit -cne $source -or
     $m.function_count -ne 95 -or $m.chunk_count -ne 23 -or
     $m.chunk_records.Count -ne 23 -or $m.program_count -ne 26 -or
     $m.final_expression -cne 'BOUNDED_UNRANK_WITNESS_ONLY' -or
     $m.final_original_stage01_tests_executed -ne $false -or
     $m.original_entrypoint_invoked -ne $false -or
     $m.original_stage01_acceptance_token_present -ne $false -or
     $m.production_source_modified -ne $false -or
     $m.trace.source_function -cne 'BoundedUnrank' -or
     $m.trace.alias -cne 'QABoundedUnrankTrace' -or
     $m.trace.source_statements_preserved -ne $true -or
     $m.trace.source_lines.Count -ne 2 -or
     $m.trace.source_lines[0] -ne 388 -or $m.trace.source_lines[1] -ne 412 -or
     $m.witness.input.Count -ne 5 -or
     (($m.witness.input -join ',') -cne '12,3,4,4,1') -or
     $m.witness.expected_fixture -cne 'FIX_BOUNDED_444'){
    throw 'BOUNDED_UNRANK_CANDIDATE_CONTRACT_INVALID'
  }
  if((Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash.ToLowerInvariant() -cne $m.candidate_sha256){throw 'BOUNDED_UNRANK_CANDIDATE_SHA_MISMATCH'}
  $r['candidate_sha256']=$m.candidate_sha256

  $allPaths=@($m.marker_path,$m.witness.compile_marker_path,$m.witness.start_marker_path,$m.witness.captured_marker_path,$m.witness.compile_name_code_path)
  foreach($c in $m.chunk_records){$allPaths+=@($c.marker_path)}
  foreach($prop in $m.witness.paths.PSObject.Properties){$allPaths+=@([string]$prop.Value)}
  foreach($path in $allPaths){if(Test-Path -LiteralPath $path){throw 'PREEXISTING_BOUNDED_UNRANK_EVIDENCE'}}

  $startTime=[DateTime]::UtcNow
  $p=Start-Process -FilePath $exe -ArgumentList ('"'+$prefix+'"') -WorkingDirectory $rt -PassThru
  $r['native_executed']=$true
  $deadline=[DateTime]::UtcNow.AddSeconds(240)
  while([DateTime]::UtcNow -lt $deadline){
    if(Test-Path -LiteralPath $marker -PathType Leaf){
      if((Get-Item -LiteralPath $marker).Length -ge $m.marker_token.Length){break}
    }
    Start-Sleep -Milliseconds 250
    $p.Refresh()
    if($p.HasExited){break}
  }
  $p.Refresh()
  if(-not $p.HasExited){
    & taskkill.exe /PID $p.Id /T /F 2>&1 | Out-Null
    $r['process_stopped']=$true
    try{Wait-Process -Id $p.Id -Timeout 8 -ErrorAction Stop}catch{}
    $p.Refresh()
  }
  if(-not $p.HasExited){throw 'NARS_PROCESS_STILL_RUNNING'}
  $r['elapsed_seconds']=([DateTime]::UtcNow-$startTime).TotalSeconds

  $checkpointDir=Join-Path $Evidence 'checkpoint_files'
  $witnessDir=Join-Path $Evidence 'witness_files'
  New-Item -ItemType Directory -Force $checkpointDir,$witnessDir | Out-Null
  $expectedAfter=5
  $allFx=$true
  foreach($c in $m.chunk_records){
    $dest=Join-Path $checkpointDir ('after_{0:D2}.txt' -f [int]$c.after)
    $v=ReadExact $c.marker_path $c.token $dest
    $r['fx_checkpoints']+=@{after=[int]$c.after;exact=[bool]$v.exact;sha256=$v.sha256;bytes=$v.bytes}
    if($v.exact -and [int]$c.after -eq $expectedAfter){
      $r['fx_last_contiguous']=[int]$c.after
      if($expectedAfter -lt 90){$expectedAfter+=5}else{$expectedAfter+=1}
    }else{$allFx=$false}
  }
  $r['fx_all_exact']=($allFx -and $r['fx_checkpoints'].Count -eq 23 -and $r['fx_last_contiguous'] -eq 95)

  $compile=ReadExact $m.witness.compile_marker_path $m.witness.compile_token (Join-Path $Evidence 'bounded_unrank_compiled.txt')
  $r['compile_exact']=[bool]$compile.exact
  $name=ReadNumbers $m.witness.compile_name_code_path (Join-Path $Evidence 'bounded_unrank_compile_name_code.txt')
  $r['compile_name_exact']=[bool]($name.valid -and $name.values.Count -eq 1 -and [long]$name.values[0] -eq 1)

  $start=ReadExact $m.witness.start_marker_path $m.witness.start_token (Join-Path $Evidence 'bounded_unrank_start.txt')
  $captured=ReadExact $m.witness.captured_marker_path $m.witness.captured_token (Join-Path $Evidence 'bounded_unrank_captured.txt')
  $r['witness_start_exact']=[bool]$start.exact
  $r['witness_captured_exact']=[bool]$captured.exact

  foreach($prop in $m.witness.paths.PSObject.Properties){
    $key=$prop.Name
    $path=[string]$prop.Value
    $dest=Join-Path $witnessDir ($key+'.txt')
    $v=ReadNumbers $path $dest
    $r['witness_files'][$key]=@{valid=[bool]$v.valid;values=$v.values;sha256=$v.sha256}
  }

  $original=$r['witness_files']['original_ec']
  if($original.valid -and $original.values.Count -eq 1){$r['original_ec_valid']=$true;$r['original_ec']=[long]$original.values[0]}
  $trace=$r['witness_files']['trace_ec']
  if($trace.valid -and $trace.values.Count -eq 1){$r['trace_ec_valid']=$true;$r['trace_ec']=[long]$trace.values[0]}
  $log=$r['witness_files']['trace_log']
  if($log.valid -and $log.values.Count -ge 1 -and [long]$log.values[0] -eq 0){
    $r['trace_log_valid']=$true
    $r['trace_log']=$log.values
    $r['trace_last_stage']=[long]$log.values[-1]
  }

  $final=ReadExact $marker $m.marker_token (Join-Path $Evidence 'bounded_unrank_final_diagnostic_marker.txt')
  $r['final_marker_exact']=[bool]$final.exact

  $core=@('expected_values','expected_shape','expected_rank','expected_type','count_values','count_rank','count_type','trace_args','trace_dp_shape','trace_dp_values','trace_dp_type','trace_loop_state','trace_candidate_state','trace_out','trace_rem','trace_rank','trace_result')
  $coreValid=$true
  foreach($key in $core){if(-not $r['witness_files'][$key].valid){$coreValid=$false}}

  if($r['runtime_verified'] -and $r['native_executed'] -and $r['fx_all_exact'] -and
     $r['compile_exact'] -and $r['compile_name_exact'] -and
     $r['witness_start_exact'] -and $r['witness_captured_exact'] -and
     $r['original_ec_valid'] -and $r['trace_ec_valid'] -and
     $r['trace_log_valid'] -and $coreValid -and $r['final_marker_exact']){
    $r['status']='BOUNDED_UNRANK_WITNESS_CAPTURED_NOT_STAGE01'
  }else{
    $r['status']='BOUNDED_UNRANK_WITNESS_INCOMPLETE_NOT_STAGE01'
    $exitCode=1
  }
} catch {
  $r['errors']+=@($_.Exception.Message)
  if(-not $r['native_executed']){$r['status']='PRE_NATIVE_BOOTSTRAP_FAILURE'}else{$r['status']='BOUNDED_UNRANK_WITNESS_RUNNER_FAILURE'}
  $exitCode=1
} finally {
  $out=Join-Path $Evidence 'native_bounded_unrank.json'
  $r | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $out -Encoding utf8
  Write-Output ('BOUNDED_UNRANK_WITNESS_STATUS='+$r['status'])
  Write-Output ('FX_LAST_CONTIGUOUS='+$r['fx_last_contiguous'])
  Write-Output ('TRACE_LAST_STAGE='+$r['trace_last_stage'])
  Write-Output 'STAGE01_NOT_ACCEPTED'
}
if($exitCode -ne 0){exit 1}
){
    return @{valid=$false;values=@();sha256=$sha}
  }
  $tokens=$s.Trim() -split '\s+'
  $values=@($tokens | ForEach-Object {
    $token=$_.Replace('¯','-') -replace '[xX]
}

try {
  if(-not $env:RUNNER_TEMP){throw 'RUNNER_TEMP_MISSING'}
  $rt=(Resolve-Path -LiteralPath $Runtime).Path
  $exe=Join-Path $rt 'NARS2000.exe'
  if(@(Get-ChildItem $rt -File).Count -ne 4){throw 'RUNTIME_FILE_COUNT_INVALID'}
  if((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash.ToLowerInvariant() -cne '192b7bd3c06a64ef57bfe1ea7f04e5d5d511ae9cd07323cfd211710891e2069d'){throw 'NARS_EXE_SHA_MISMATCH'}
  if((Get-Item -LiteralPath $exe).VersionInfo.FileVersion -cne '0.5.14.11'){throw 'NARS_VERSION_MISMATCH'}
  $r['runtime_verified']=$true

  $official=Join-Path $env:RUNNER_TEMP 'nars_2by2_pair.ws.nars'
  Invoke-WebRequest -Uri 'https://www.nars2000.org/download/workspaces/2by2.ws.nars' -OutFile $official -TimeoutSec 90 -MaximumRedirection 3
  if((Get-FileHash -LiteralPath $official -Algorithm SHA256).Hash.ToLowerInvariant() -cne '2eba3f2eb9f826b992ffaf4054db9a09da38f4ae2687168173be4a16fd08b11b'){throw 'BASE_WORKSPACE_SHA_MISMATCH'}

  $prefix=Join-Path $env:RUNNER_TEMP 'apl_german_bounded_unrank_v27'
  $marker=$prefix+'.txt'
  $candidate=$prefix+'.ws.nars'
  $candidateReceipt=Join-Path $Evidence 'bounded_unrank_candidate.json'
  if(Test-Path -LiteralPath $marker){throw 'PREEXISTING_FINAL_MARKER'}
  & python qa/nars-interface/stage01_bounded_unrank_witness.py --repo-root . --source $official --candidate $candidate --receipt $candidateReceipt --marker $marker
  if($LASTEXITCODE -ne 0){throw 'BOUNDED_UNRANK_CANDIDATE_GENERATION_FAILED'}
  $m=Get-Content -LiteralPath $candidateReceipt -Raw | ConvertFrom-Json

  if($m.schema -cne 'APL_GERMAN_STAGE01_BOUNDED_UNRANK_WITNESS_V1' -or
     $m.status -cne 'GENERATED_NOT_NATIVE_VALIDATED' -or
     $m.stage01 -cne 'NOT_ACCEPTED' -or
     $m.source_commit -cne $source -or
     $m.function_count -ne 95 -or $m.chunk_count -ne 23 -or
     $m.chunk_records.Count -ne 23 -or $m.program_count -ne 26 -or
     $m.final_expression -cne 'BOUNDED_UNRANK_WITNESS_ONLY' -or
     $m.final_original_stage01_tests_executed -ne $false -or
     $m.original_entrypoint_invoked -ne $false -or
     $m.original_stage01_acceptance_token_present -ne $false -or
     $m.production_source_modified -ne $false -or
     $m.trace.source_function -cne 'BoundedUnrank' -or
     $m.trace.alias -cne 'QABoundedUnrankTrace' -or
     $m.trace.source_statements_preserved -ne $true -or
     $m.trace.source_lines.Count -ne 2 -or
     $m.trace.source_lines[0] -ne 388 -or $m.trace.source_lines[1] -ne 412 -or
     $m.witness.input.Count -ne 5 -or
     (($m.witness.input -join ',') -cne '12,3,4,4,1') -or
     $m.witness.expected_fixture -cne 'FIX_BOUNDED_444'){
    throw 'BOUNDED_UNRANK_CANDIDATE_CONTRACT_INVALID'
  }
  if((Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash.ToLowerInvariant() -cne $m.candidate_sha256){throw 'BOUNDED_UNRANK_CANDIDATE_SHA_MISMATCH'}
  $r['candidate_sha256']=$m.candidate_sha256

  $allPaths=@($m.marker_path,$m.witness.compile_marker_path,$m.witness.start_marker_path,$m.witness.captured_marker_path,$m.witness.compile_name_code_path)
  foreach($c in $m.chunk_records){$allPaths+=@($c.marker_path)}
  foreach($prop in $m.witness.paths.PSObject.Properties){$allPaths+=@([string]$prop.Value)}
  foreach($path in $allPaths){if(Test-Path -LiteralPath $path){throw 'PREEXISTING_BOUNDED_UNRANK_EVIDENCE'}}

  $startTime=[DateTime]::UtcNow
  $p=Start-Process -FilePath $exe -ArgumentList ('"'+$prefix+'"') -WorkingDirectory $rt -PassThru
  $r['native_executed']=$true
  $deadline=[DateTime]::UtcNow.AddSeconds(240)
  while([DateTime]::UtcNow -lt $deadline){
    if(Test-Path -LiteralPath $marker -PathType Leaf){
      if((Get-Item -LiteralPath $marker).Length -ge $m.marker_token.Length){break}
    }
    Start-Sleep -Milliseconds 250
    $p.Refresh()
    if($p.HasExited){break}
  }
  $p.Refresh()
  if(-not $p.HasExited){
    & taskkill.exe /PID $p.Id /T /F 2>&1 | Out-Null
    $r['process_stopped']=$true
    try{Wait-Process -Id $p.Id -Timeout 8 -ErrorAction Stop}catch{}
    $p.Refresh()
  }
  if(-not $p.HasExited){throw 'NARS_PROCESS_STILL_RUNNING'}
  $r['elapsed_seconds']=([DateTime]::UtcNow-$startTime).TotalSeconds

  $checkpointDir=Join-Path $Evidence 'checkpoint_files'
  $witnessDir=Join-Path $Evidence 'witness_files'
  New-Item -ItemType Directory -Force $checkpointDir,$witnessDir | Out-Null
  $expectedAfter=5
  $allFx=$true
  foreach($c in $m.chunk_records){
    $dest=Join-Path $checkpointDir ('after_{0:D2}.txt' -f [int]$c.after)
    $v=ReadExact $c.marker_path $c.token $dest
    $r['fx_checkpoints']+=@{after=[int]$c.after;exact=[bool]$v.exact;sha256=$v.sha256;bytes=$v.bytes}
    if($v.exact -and [int]$c.after -eq $expectedAfter){
      $r['fx_last_contiguous']=[int]$c.after
      if($expectedAfter -lt 90){$expectedAfter+=5}else{$expectedAfter+=1}
    }else{$allFx=$false}
  }
  $r['fx_all_exact']=($allFx -and $r['fx_checkpoints'].Count -eq 23 -and $r['fx_last_contiguous'] -eq 95)

  $compile=ReadExact $m.witness.compile_marker_path $m.witness.compile_token (Join-Path $Evidence 'bounded_unrank_compiled.txt')
  $r['compile_exact']=[bool]$compile.exact
  $name=ReadNumbers $m.witness.compile_name_code_path (Join-Path $Evidence 'bounded_unrank_compile_name_code.txt')
  $r['compile_name_exact']=[bool]($name.valid -and $name.values.Count -eq 1 -and [long]$name.values[0] -eq 1)

  $start=ReadExact $m.witness.start_marker_path $m.witness.start_token (Join-Path $Evidence 'bounded_unrank_start.txt')
  $captured=ReadExact $m.witness.captured_marker_path $m.witness.captured_token (Join-Path $Evidence 'bounded_unrank_captured.txt')
  $r['witness_start_exact']=[bool]$start.exact
  $r['witness_captured_exact']=[bool]$captured.exact

  foreach($prop in $m.witness.paths.PSObject.Properties){
    $key=$prop.Name
    $path=[string]$prop.Value
    $dest=Join-Path $witnessDir ($key+'.txt')
    $v=ReadNumbers $path $dest
    $r['witness_files'][$key]=@{valid=[bool]$v.valid;values=$v.values;sha256=$v.sha256}
  }

  $original=$r['witness_files']['original_ec']
  if($original.valid -and $original.values.Count -eq 1){$r['original_ec_valid']=$true;$r['original_ec']=[long]$original.values[0]}
  $trace=$r['witness_files']['trace_ec']
  if($trace.valid -and $trace.values.Count -eq 1){$r['trace_ec_valid']=$true;$r['trace_ec']=[long]$trace.values[0]}
  $log=$r['witness_files']['trace_log']
  if($log.valid -and $log.values.Count -ge 1 -and [long]$log.values[0] -eq 0){
    $r['trace_log_valid']=$true
    $r['trace_log']=$log.values
    $r['trace_last_stage']=[long]$log.values[-1]
  }

  $final=ReadExact $marker $m.marker_token (Join-Path $Evidence 'bounded_unrank_final_diagnostic_marker.txt')
  $r['final_marker_exact']=[bool]$final.exact

  $core=@('expected_values','expected_shape','expected_rank','expected_type','count_values','count_rank','count_type','trace_args','trace_dp_shape','trace_dp_values','trace_dp_type','trace_loop_state','trace_candidate_state','trace_out','trace_rem','trace_rank','trace_result')
  $coreValid=$true
  foreach($key in $core){if(-not $r['witness_files'][$key].valid){$coreValid=$false}}

  if($r['runtime_verified'] -and $r['native_executed'] -and $r['fx_all_exact'] -and
     $r['compile_exact'] -and $r['compile_name_exact'] -and
     $r['witness_start_exact'] -and $r['witness_captured_exact'] -and
     $r['original_ec_valid'] -and $r['trace_ec_valid'] -and
     $r['trace_log_valid'] -and $coreValid -and $r['final_marker_exact']){
    $r['status']='BOUNDED_UNRANK_WITNESS_CAPTURED_NOT_STAGE01'
  }else{
    $r['status']='BOUNDED_UNRANK_WITNESS_INCOMPLETE_NOT_STAGE01'
    $exitCode=1
  }
} catch {
  $r['errors']+=@($_.Exception.Message)
  if(-not $r['native_executed']){$r['status']='PRE_NATIVE_BOOTSTRAP_FAILURE'}else{$r['status']='BOUNDED_UNRANK_WITNESS_RUNNER_FAILURE'}
  $exitCode=1
} finally {
  $out=Join-Path $Evidence 'native_bounded_unrank.json'
  $r | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $out -Encoding utf8
  Write-Output ('BOUNDED_UNRANK_WITNESS_STATUS='+$r['status'])
  Write-Output ('FX_LAST_CONTIGUOUS='+$r['fx_last_contiguous'])
  Write-Output ('TRACE_LAST_STAGE='+$r['trace_last_stage'])
  Write-Output 'STAGE01_NOT_ACCEPTED'
}
if($exitCode -ne 0){exit 1}
,''
    [long]::Parse($token,[Globalization.CultureInfo]::InvariantCulture)
  })
  return @{valid=$true;values=$values;sha256=$sha}
}

try {
  if(-not $env:RUNNER_TEMP){throw 'RUNNER_TEMP_MISSING'}
  $rt=(Resolve-Path -LiteralPath $Runtime).Path
  $exe=Join-Path $rt 'NARS2000.exe'
  if(@(Get-ChildItem $rt -File).Count -ne 4){throw 'RUNTIME_FILE_COUNT_INVALID'}
  if((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash.ToLowerInvariant() -cne '192b7bd3c06a64ef57bfe1ea7f04e5d5d511ae9cd07323cfd211710891e2069d'){throw 'NARS_EXE_SHA_MISMATCH'}
  if((Get-Item -LiteralPath $exe).VersionInfo.FileVersion -cne '0.5.14.11'){throw 'NARS_VERSION_MISMATCH'}
  $r['runtime_verified']=$true

  $official=Join-Path $env:RUNNER_TEMP 'nars_2by2_pair.ws.nars'
  Invoke-WebRequest -Uri 'https://www.nars2000.org/download/workspaces/2by2.ws.nars' -OutFile $official -TimeoutSec 90 -MaximumRedirection 3
  if((Get-FileHash -LiteralPath $official -Algorithm SHA256).Hash.ToLowerInvariant() -cne '2eba3f2eb9f826b992ffaf4054db9a09da38f4ae2687168173be4a16fd08b11b'){throw 'BASE_WORKSPACE_SHA_MISMATCH'}

  $prefix=Join-Path $env:RUNNER_TEMP 'apl_german_bounded_unrank_v27'
  $marker=$prefix+'.txt'
  $candidate=$prefix+'.ws.nars'
  $candidateReceipt=Join-Path $Evidence 'bounded_unrank_candidate.json'
  if(Test-Path -LiteralPath $marker){throw 'PREEXISTING_FINAL_MARKER'}
  & python qa/nars-interface/stage01_bounded_unrank_witness.py --repo-root . --source $official --candidate $candidate --receipt $candidateReceipt --marker $marker
  if($LASTEXITCODE -ne 0){throw 'BOUNDED_UNRANK_CANDIDATE_GENERATION_FAILED'}
  $m=Get-Content -LiteralPath $candidateReceipt -Raw | ConvertFrom-Json

  if($m.schema -cne 'APL_GERMAN_STAGE01_BOUNDED_UNRANK_WITNESS_V1' -or
     $m.status -cne 'GENERATED_NOT_NATIVE_VALIDATED' -or
     $m.stage01 -cne 'NOT_ACCEPTED' -or
     $m.source_commit -cne $source -or
     $m.function_count -ne 95 -or $m.chunk_count -ne 23 -or
     $m.chunk_records.Count -ne 23 -or $m.program_count -ne 26 -or
     $m.final_expression -cne 'BOUNDED_UNRANK_WITNESS_ONLY' -or
     $m.final_original_stage01_tests_executed -ne $false -or
     $m.original_entrypoint_invoked -ne $false -or
     $m.original_stage01_acceptance_token_present -ne $false -or
     $m.production_source_modified -ne $false -or
     $m.trace.source_function -cne 'BoundedUnrank' -or
     $m.trace.alias -cne 'QABoundedUnrankTrace' -or
     $m.trace.source_statements_preserved -ne $true -or
     $m.trace.source_lines.Count -ne 2 -or
     $m.trace.source_lines[0] -ne 388 -or $m.trace.source_lines[1] -ne 412 -or
     $m.witness.input.Count -ne 5 -or
     (($m.witness.input -join ',') -cne '12,3,4,4,1') -or
     $m.witness.expected_fixture -cne 'FIX_BOUNDED_444'){
    throw 'BOUNDED_UNRANK_CANDIDATE_CONTRACT_INVALID'
  }
  if((Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash.ToLowerInvariant() -cne $m.candidate_sha256){throw 'BOUNDED_UNRANK_CANDIDATE_SHA_MISMATCH'}
  $r['candidate_sha256']=$m.candidate_sha256

  $allPaths=@($m.marker_path,$m.witness.compile_marker_path,$m.witness.start_marker_path,$m.witness.captured_marker_path,$m.witness.compile_name_code_path)
  foreach($c in $m.chunk_records){$allPaths+=@($c.marker_path)}
  foreach($prop in $m.witness.paths.PSObject.Properties){$allPaths+=@([string]$prop.Value)}
  foreach($path in $allPaths){if(Test-Path -LiteralPath $path){throw 'PREEXISTING_BOUNDED_UNRANK_EVIDENCE'}}

  $startTime=[DateTime]::UtcNow
  $p=Start-Process -FilePath $exe -ArgumentList ('"'+$prefix+'"') -WorkingDirectory $rt -PassThru
  $r['native_executed']=$true
  $deadline=[DateTime]::UtcNow.AddSeconds(240)
  while([DateTime]::UtcNow -lt $deadline){
    if(Test-Path -LiteralPath $marker -PathType Leaf){
      if((Get-Item -LiteralPath $marker).Length -ge $m.marker_token.Length){break}
    }
    Start-Sleep -Milliseconds 250
    $p.Refresh()
    if($p.HasExited){break}
  }
  $p.Refresh()
  if(-not $p.HasExited){
    & taskkill.exe /PID $p.Id /T /F 2>&1 | Out-Null
    $r['process_stopped']=$true
    try{Wait-Process -Id $p.Id -Timeout 8 -ErrorAction Stop}catch{}
    $p.Refresh()
  }
  if(-not $p.HasExited){throw 'NARS_PROCESS_STILL_RUNNING'}
  $r['elapsed_seconds']=([DateTime]::UtcNow-$startTime).TotalSeconds

  $checkpointDir=Join-Path $Evidence 'checkpoint_files'
  $witnessDir=Join-Path $Evidence 'witness_files'
  New-Item -ItemType Directory -Force $checkpointDir,$witnessDir | Out-Null
  $expectedAfter=5
  $allFx=$true
  foreach($c in $m.chunk_records){
    $dest=Join-Path $checkpointDir ('after_{0:D2}.txt' -f [int]$c.after)
    $v=ReadExact $c.marker_path $c.token $dest
    $r['fx_checkpoints']+=@{after=[int]$c.after;exact=[bool]$v.exact;sha256=$v.sha256;bytes=$v.bytes}
    if($v.exact -and [int]$c.after -eq $expectedAfter){
      $r['fx_last_contiguous']=[int]$c.after
      if($expectedAfter -lt 90){$expectedAfter+=5}else{$expectedAfter+=1}
    }else{$allFx=$false}
  }
  $r['fx_all_exact']=($allFx -and $r['fx_checkpoints'].Count -eq 23 -and $r['fx_last_contiguous'] -eq 95)

  $compile=ReadExact $m.witness.compile_marker_path $m.witness.compile_token (Join-Path $Evidence 'bounded_unrank_compiled.txt')
  $r['compile_exact']=[bool]$compile.exact
  $name=ReadNumbers $m.witness.compile_name_code_path (Join-Path $Evidence 'bounded_unrank_compile_name_code.txt')
  $r['compile_name_exact']=[bool]($name.valid -and $name.values.Count -eq 1 -and [long]$name.values[0] -eq 1)

  $start=ReadExact $m.witness.start_marker_path $m.witness.start_token (Join-Path $Evidence 'bounded_unrank_start.txt')
  $captured=ReadExact $m.witness.captured_marker_path $m.witness.captured_token (Join-Path $Evidence 'bounded_unrank_captured.txt')
  $r['witness_start_exact']=[bool]$start.exact
  $r['witness_captured_exact']=[bool]$captured.exact

  foreach($prop in $m.witness.paths.PSObject.Properties){
    $key=$prop.Name
    $path=[string]$prop.Value
    $dest=Join-Path $witnessDir ($key+'.txt')
    $v=ReadNumbers $path $dest
    $r['witness_files'][$key]=@{valid=[bool]$v.valid;values=$v.values;sha256=$v.sha256}
  }

  $original=$r['witness_files']['original_ec']
  if($original.valid -and $original.values.Count -eq 1){$r['original_ec_valid']=$true;$r['original_ec']=[long]$original.values[0]}
  $trace=$r['witness_files']['trace_ec']
  if($trace.valid -and $trace.values.Count -eq 1){$r['trace_ec_valid']=$true;$r['trace_ec']=[long]$trace.values[0]}
  $log=$r['witness_files']['trace_log']
  if($log.valid -and $log.values.Count -ge 1 -and [long]$log.values[0] -eq 0){
    $r['trace_log_valid']=$true
    $r['trace_log']=$log.values
    $r['trace_last_stage']=[long]$log.values[-1]
  }

  $final=ReadExact $marker $m.marker_token (Join-Path $Evidence 'bounded_unrank_final_diagnostic_marker.txt')
  $r['final_marker_exact']=[bool]$final.exact

  $core=@('expected_values','expected_shape','expected_rank','expected_type','count_values','count_rank','count_type','trace_args','trace_dp_shape','trace_dp_values','trace_dp_type','trace_loop_state','trace_candidate_state','trace_out','trace_rem','trace_rank','trace_result')
  $coreValid=$true
  foreach($key in $core){if(-not $r['witness_files'][$key].valid){$coreValid=$false}}

  if($r['runtime_verified'] -and $r['native_executed'] -and $r['fx_all_exact'] -and
     $r['compile_exact'] -and $r['compile_name_exact'] -and
     $r['witness_start_exact'] -and $r['witness_captured_exact'] -and
     $r['original_ec_valid'] -and $r['trace_ec_valid'] -and
     $r['trace_log_valid'] -and $coreValid -and $r['final_marker_exact']){
    $r['status']='BOUNDED_UNRANK_WITNESS_CAPTURED_NOT_STAGE01'
  }else{
    $r['status']='BOUNDED_UNRANK_WITNESS_INCOMPLETE_NOT_STAGE01'
    $exitCode=1
  }
} catch {
  $r['errors']+=@($_.Exception.Message)
  if(-not $r['native_executed']){$r['status']='PRE_NATIVE_BOOTSTRAP_FAILURE'}else{$r['status']='BOUNDED_UNRANK_WITNESS_RUNNER_FAILURE'}
  $exitCode=1
} finally {
  $out=Join-Path $Evidence 'native_bounded_unrank.json'
  $r | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $out -Encoding utf8
  Write-Output ('BOUNDED_UNRANK_WITNESS_STATUS='+$r['status'])
  Write-Output ('FX_LAST_CONTIGUOUS='+$r['fx_last_contiguous'])
  Write-Output ('TRACE_LAST_STAGE='+$r['trace_last_stage'])
  Write-Output 'STAGE01_NOT_ACCEPTED'
}
if($exitCode -ne 0){exit 1}
