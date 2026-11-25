# QA-only bounded NARS residual suite statement receipts. NEVER Stage1 acceptance.
[CmdletBinding()]
param([string]$Runtime='verified_runtime',[string]$Evidence='residual_evidence')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$source='7161824b9fcbfaca91f20d1ea492417e77003ff4'
$r=[ordered]@{
 schema='APL_GERMAN_NATIVE_RESIDUAL_STATEMENT_V1';source_commit=$source;
 stage01='NOT_ACCEPTED';status='STARTED';native_executed=$false;runtime_verified=$false;
 fx_last_contiguous=0;fx_checkpoints=@();copies=@();suite_start_exact=$false;
 suite_captured_exact=$false;suite_ec_valid=$false;suite_ec_first=$null;
 suite_no_error=$false;final_marker_exact=$false;process_stopped=$false;errors=@();
 compile_exact=$false;compile_name_exact=$false;statement_receipts=@();first_incomplete=$null;statement_started=0;statement_ended=0
}
New-Item -ItemType Directory -Force $Evidence | Out-Null
$Evidence=(Resolve-Path -LiteralPath $Evidence).Path
function ReadExact([string]$path,[string]$wanted,[string]$dest){
 if(-not(Test-Path -LiteralPath $path -PathType Leaf)){return @{exact=$false;sha256=$null;bytes=0}}
 [byte[]]$data=[IO.File]::ReadAllBytes($path)
 Copy-Item -LiteralPath $path -Destination $dest -Force
 [byte[]]$expected=[Text.Encoding]::ASCII.GetBytes($wanted)
 $equal=($data.Length -eq $expected.Length) -and
   ([Convert]::ToBase64String($data) -ceq [Convert]::ToBase64String($expected))
 return @{exact=[bool]$equal;sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant();bytes=$data.Length}
}
function ReadNumbers([string]$path,[string]$dest){
 if(-not(Test-Path -LiteralPath $path -PathType Leaf)){return @{valid=$false;values=@();sha256=$null}}
 [byte[]]$data=[IO.File]::ReadAllBytes($path)
 Copy-Item -LiteralPath $path -Destination $dest -Force
 $sha=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
 if($data.Length -lt 1 -or $data.Length -gt 1024){return @{valid=$false;values=@();sha256=$sha}}
 $s=[Text.Encoding]::ASCII.GetString($data)
 if($s -cnotmatch '^\s*\d+(\s+\d+)*\s*$'){return @{valid=$false;values=@();sha256=$sha}}
 $values=@([regex]::Matches($s,'\d+') | ForEach-Object {[long]$_.Value})
 return @{valid=$true;values=$values;sha256=$sha}
}
try {
 if(-not $env:RUNNER_TEMP){throw 'RUNNER_TEMP_MISSING'}
 $rt=(Resolve-Path -LiteralPath $Runtime).Path
 $exe=Join-Path $rt 'NARS2000.exe'
 if(@(Get-ChildItem $rt -File).Count -ne 4){throw 'RUNTIME_FILE_COUNT_INVALID'}
 if((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash.ToLowerInvariant() -cne
   '192b7bd3c06a64ef57bfe1ea7f04e5d5d511ae9cd07323cfd211710891e2069d'){throw 'NARS_EXE_SHA_MISMATCH'}
 if((Get-Item -LiteralPath $exe).VersionInfo.FileVersion -cne '0.5.14.11'){throw 'NARS_VERSION_MISMATCH'}
 $r['runtime_verified']=$true
 $official=Join-Path $env:RUNNER_TEMP 'nars_2by2_pair.ws.nars'
 Invoke-WebRequest -Uri 'https://www.nars2000.org/download/workspaces/2by2.ws.nars' -OutFile $official -TimeoutSec 90 -MaximumRedirection 3
 if((Get-FileHash -LiteralPath $official -Algorithm SHA256).Hash.ToLowerInvariant() -cne
   '2eba3f2eb9f826b992ffaf4054db9a09da38f4ae2687168173be4a16fd08b11b'){throw 'BASE_WORKSPACE_SHA_MISMATCH'}
 $prefix=Join-Path $env:RUNNER_TEMP 'apl_german_stage01_residual_v17'
 $marker=$prefix+'.txt'
 $candidate=$prefix+'.ws.nars'
 $receipt=Join-Path $Evidence 'residual_candidate.json'
 if(Test-Path -LiteralPath $marker){throw 'PREEXISTING_FINAL_MARKER'}
 & python qa/nars-interface/stage01_residual_probe.py --repo-root . --source $official --candidate $candidate --receipt $receipt --marker $marker
 if($LASTEXITCODE -ne 0){throw 'RESIDUAL_GENERATOR_FAILED'}
 $m=Get-Content -LiteralPath $receipt -Raw | ConvertFrom-Json
 if($m.schema -cne 'APL_GERMAN_STAGE01_RESIDUAL_STATEMENT_DIAGNOSTIC_V1' -or
    $m.stage01 -cne 'NOT_ACCEPTED' -or $m.source_commit -cne $source -or
    $m.function_count -ne 95 -or $m.chunk_count -ne 23 -or
    $m.chunk_records.Count -ne 23 -or $m.copies.Count -ne 2 -or
    $m.program_count -ne 28 -or $m.probe_count -ne 8 -or
    $m.instrumentation_mode -cne 'line180_181_counterfactual_focus_180_187' -or $m.original_entrypoint_invoked -ne $false -or $m.production_source_modified -ne $false -or
    $m.source_statements_preserved -ne $false -or (($m.qa_only_patches.source_line -join ',') -cne '180,181') -or $m.prior_line181_witness_run -ne 45551684196 -or
    $m.original_unmodified_suite_proven -ne $false -or
    $m.original_stage01_acceptance_token_present -ne $false){throw 'CANDIDATE_CONTRACT_INVALID'}
 if((Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash.ToLowerInvariant() -cne $m.candidate_sha256){throw 'CANDIDATE_SHA_MISMATCH'}
 $r['candidate_sha256']=$m.candidate_sha256
 foreach($path in @($m.marker_path,$m.suite.start_path,$m.suite.captured_path,$m.suite.code_path,$m.suite.message_path)){
   if(Test-Path -LiteralPath $path){throw 'PREEXISTING_RESIDUAL_SUITE_EVIDENCE'}
 }
 foreach($c in $m.chunk_records){if(Test-Path -LiteralPath $c.marker_path){throw 'PREEXISTING_FX_MARKER'}}
 foreach($c in $m.copies){
   foreach($field in @('path','name_code_path')){if(Test-Path -LiteralPath $c.$field){throw 'PREEXISTING_COPY_RECEIPT'}}
 }
 foreach($field in @('path','name_code_path')){if(Test-Path -LiteralPath $m.compiled.$field){throw 'PREEXISTING_COMPILE_RECEIPT'}}
 foreach($s in $m.probes){
   foreach($phase in @('start','end')){if(Test-Path -LiteralPath $s.($phase+'_path')){throw 'PREEXISTING_STATEMENT_RECEIPT'}}
 }
 $startTime=[DateTime]::UtcNow
 $p=Start-Process -FilePath $exe -ArgumentList ('"'+$prefix+'"') -WorkingDirectory $rt -PassThru
 $r['native_executed']=$true
 $deadline=[DateTime]::UtcNow.AddSeconds(360)
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
 $checkDir=Join-Path $Evidence 'checkpoint_files'
 $copyDir=Join-Path $Evidence 'copy_files'
 New-Item -ItemType Directory -Force $checkDir,$copyDir | Out-Null
 foreach($c in $m.chunk_records){
   $v=ReadExact $c.marker_path $c.token (Join-Path $checkDir ('after_{0:D2}.txt' -f [int]$c.after))
   $r['fx_checkpoints']+=@{after=[int]$c.after;exact=[bool]$v.exact;sha256=$v.sha256}
   if($v.exact){$r['fx_last_contiguous']=[int]$c.after}
 }
 foreach($c in $m.copies){
   $stem=('copy_{0:D2}' -f [int]$c.index)
   $markerResult=ReadExact $c.path $c.token (Join-Path $copyDir ($stem+'_marker.txt'))
   $nameResult=ReadNumbers $c.name_code_path (Join-Path $copyDir ($stem+'_name_code.txt'))
   $nameExact=$nameResult.valid -and $nameResult.values.Count -eq 1 -and [long]$nameResult.values[0] -eq 1
   $r['copies']+=@{index=[int]$c.index;name=$c.name;marker_exact=[bool]$markerResult.exact;
      name_exact=[bool]$nameExact;definition_sha256=$c.copy_definition_sha256}
   Write-Output ('QA_COPY '+$c.name+' MARKER='+$markerResult.exact+' NAME='+$nameExact)
 }
 $compileMark=ReadExact $m.compiled.path $m.compiled.token (Join-Path $Evidence 'residual_compiled.txt')
 $compileName=ReadNumbers $m.compiled.name_code_path (Join-Path $Evidence 'residual_compile_name_code.txt')
 $r['compile_exact']=[bool]$compileMark.exact
 $r['compile_name_exact']=[bool]($compileName.valid -and $compileName.values.Count -eq 1 -and [long]$compileName.values[0] -eq 1)
 $statDir=Join-Path $Evidence 'statement_files'
 New-Item -ItemType Directory -Force $statDir | Out-Null
 foreach($s in $m.probes){
   $tag=('{0:D3}' -f [int]$s.index)
   $sv=ReadExact $s.start_path $s.start_token (Join-Path $statDir ($tag+'_start.txt'))
   $ev=ReadExact $s.end_path $s.end_token (Join-Path $statDir ($tag+'_end.txt'))
   $r['statement_receipts']+=@{index=[int]$s.index;kind=$s.kind;
     first_line=[int]$s.first_line;last_line=[int]$s.last_line;
     start_exact=[bool]$sv.exact;end_exact=[bool]$ev.exact;
     start_sha256=$sv.sha256;end_sha256=$ev.sha256;source_sha256=$s.source_sha256}
   if($sv.exact){$r['statement_started']++}
   if($ev.exact){$r['statement_ended']++}
   if($sv.exact -and -not $ev.exact -and $null -eq $r['first_incomplete']){
     $r['first_incomplete']=@{index=[int]$s.index;first_line=[int]$s.first_line;
         last_line=[int]$s.last_line;kind=$s.kind}
   }
 }
 Write-Output ('RESIDUAL_STATEMENTS|STARTED='+$r['statement_started']+
   '|ENDED='+$r['statement_ended']+'|FIRST_INCOMPLETE='+($r['first_incomplete']|ConvertTo-Json -Compress))
 $start=ReadExact $m.suite.start_path $m.suite.start_token (Join-Path $Evidence 'suite_start.txt')
 $captured=ReadExact $m.suite.captured_path $m.suite.captured_token (Join-Path $Evidence 'suite_captured.txt')
 $ec=ReadNumbers $m.suite.code_path (Join-Path $Evidence 'suite_ec_first.txt')
 if(Test-Path -LiteralPath $m.suite.message_path){Copy-Item -LiteralPath $m.suite.message_path -Destination (Join-Path $Evidence 'suite_error_message_codepoints.txt') -Force}
 $r['suite_start_exact']=[bool]$start.exact
 $r['suite_captured_exact']=[bool]$captured.exact
 $r['suite_ec_valid']=[bool]($ec.valid -and $ec.values.Count -eq 1 -and
    (@(0,1,2,3) -contains [long]$ec.values[0]))
 if($r['suite_ec_valid']){
   $r['suite_ec_first']=[long]$ec.values[0]
   $r['suite_no_error']=([long]$ec.values[0] -ne 0)
 }
 $final=ReadExact $marker $m.marker_token (Join-Path $Evidence 'residual_final_diagnostic_marker.txt')
 $r['final_marker_exact']=[bool]$final.exact
 $r['prior_line181_witness_run']=45551684196
 $all= ($r['fx_last_contiguous'] -eq 95) -and $r['fx_checkpoints'].Count -eq 23 -and
   (@($r['fx_checkpoints'] | Where-Object {$_.exact -ne $true}).Count -eq 0) -and
   ($r['copies'].Count -eq 2) -and
   (@($r['copies'] | Where-Object {$_.marker_exact -ne $true -or $_.name_exact -ne $true}).Count -eq 0) -and
   $r['suite_start_exact'] -and $r['suite_captured_exact'] -and
   $r['suite_ec_valid'] -and $r['final_marker_exact'] -and
   $r['compile_exact'] -and $r['compile_name_exact'] -and
   $r['statement_receipts'].Count -eq $m.probe_count -and $r['statement_started'] -ge 3 -and
   $r['statement_receipts'][0].first_line -eq 180 -and $r['statement_receipts'][0].end_exact -and
   $r['statement_receipts'][1].first_line -eq 181 -and $r['statement_receipts'][1].start_exact -and $r['statement_receipts'][1].end_exact -and
   $r['statement_receipts'][2].first_line -eq 182 -and $r['statement_receipts'][2].start_exact
 $r['status']=if(-not $all){'INCOMPLETE_RESIDUAL_DIAGNOSTIC_NOT_STAGE01'}elseif($r['suite_no_error']){
    'RESIDUAL_SUITE_NO_ERROR_DIAGNOSTIC_ONLY'
 }else{'RESIDUAL_SUITE_ERROR_DIAGNOSTIC_ONLY'}
 Write-Output ('RESIDUAL_NATIVE_STATUS='+$r['status']+' EC_FIRST='+$r['suite_ec_first'])
 Write-Output 'STAGE01=NOT_ACCEPTED'
 if(-not $all){throw 'RESIDUAL_RECEIPTS_INCOMPLETE'}
}catch{
 $r['errors']+=$_.Exception.Message
 if($r['status'] -ne 'INCOMPLETE_RESIDUAL_DIAGNOSTIC_NOT_STAGE01'){$r['status']='FAIL_CLOSED_NOT_STAGE01'}
 throw
}finally{
 $r | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath (Join-Path $Evidence 'native_residual.json') -Encoding utf8
}
