# QA-only bounded six-witness native evidence. Never accepts Stage1.
[CmdletBinding()]
param([string]$Runtime='verified_runtime',[string]$Evidence='counterfactual_probe_evidence')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$source='7161824b9fcbfaca91f20d1ea492417e77003ff4'
$r=[ordered]@{
 schema='APL_GERMAN_NATIVE_COUNTERFACTUAL_V1';source_commit=$source;
 stage01='NOT_ACCEPTED';status='STARTED';native_executed=$false;runtime_verified=$false;
 fx_last_contiguous=0;fx_checkpoints=@();witnesses=@();init_exact=$false;
 helper_exact=$false;final_marker_exact=$false;process_stopped=$false;errors=@()
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
 $official=Join-Path $env:RUNNER_TEMP 'nars_2by2_cf.ws.nars'
 Invoke-WebRequest -Uri 'https://www.nars2000.org/download/workspaces/2by2.ws.nars' -OutFile $official -TimeoutSec 90 -MaximumRedirection 3
 if((Get-FileHash -LiteralPath $official -Algorithm SHA256).Hash.ToLowerInvariant() -cne
   '2eba3f2eb9f826b992ffaf4054db9a09da38f4ae2687168173be4a16fd08b11b'){throw 'BASE_WORKSPACE_SHA_MISMATCH'}
 $prefix=Join-Path $env:RUNNER_TEMP 'apl_german_stage01_cf_v1'
 $marker=$prefix+'.txt'
 $candidate=$prefix+'.ws.nars'
 $receipt=Join-Path $Evidence 'counterfactual_candidate.json'
 if(Test-Path -LiteralPath $marker){throw 'PREEXISTING_FINAL_MARKER'}
 & python qa/nars-interface/stage01_counterfactual_probe.py --repo-root . --source $official --candidate $candidate --receipt $receipt --marker $marker
 if($LASTEXITCODE -ne 0){throw 'COUNTERFACTUAL_GENERATOR_FAILED'}
 $m=Get-Content -LiteralPath $receipt -Raw | ConvertFrom-Json
 if($m.schema -cne 'APL_GERMAN_COUNTERFACTUAL_CANDIDATE_V1' -or
    $m.stage01 -cne 'NOT_ACCEPTED' -or $m.source_commit -cne $source -or
    $m.function_count -ne 95 -or $m.chunk_count -ne 23 -or
    $m.chunk_records.Count -ne 23 -or $m.probes.Count -ne 6 -or
    $m.program_count -ne 32 -or $m.final_original_stage01_tests_executed -ne $false -or
    $m.original_stage01_acceptance_token_present -ne $false){throw 'CANDIDATE_CONTRACT_INVALID'}
 if((Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash.ToLowerInvariant() -cne $m.candidate_sha256){throw 'CANDIDATE_SHA_MISMATCH'}
 $r['candidate_sha256']=$m.candidate_sha256
 foreach($path in @($m.marker_path,$m.init_path,$m.helper_path)){
   if(Test-Path -LiteralPath $path){throw 'PREEXISTING_EVIDENCE'}
 }
 foreach($c in $m.chunk_records){if(Test-Path -LiteralPath $c.marker_path){throw 'PREEXISTING_FX_MARKER'}}
 foreach($w in $m.probes){
   foreach($field in @('start_path','captured_path','code_path','value_path','message_path')){
     if(Test-Path -LiteralPath $w.$field){throw 'PREEXISTING_WITNESS_FILE'}
   }
 }
 $p=Start-Process -FilePath $exe -ArgumentList ('"'+$prefix+'"') -WorkingDirectory $rt -PassThru
 $r['native_executed']=$true
 $deadline=[DateTime]::UtcNow.AddSeconds(250)
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
 $checkDir=Join-Path $Evidence 'checkpoint_files'
 $witDir=Join-Path $Evidence 'witness_files'
 New-Item -ItemType Directory -Force $checkDir,$witDir | Out-Null
 foreach($c in $m.chunk_records){
   $v=ReadExact $c.marker_path $c.token (Join-Path $checkDir ('after_{0:D2}.txt' -f [int]$c.after))
   $r['fx_checkpoints']+=@{after=[int]$c.after;exact=[bool]$v.exact;sha256=$v.sha256}
   if($v.exact){$r['fx_last_contiguous']=[int]$c.after}
 }
 $init=ReadExact $m.init_path $m.init_token (Join-Path $Evidence 'init_marker.txt')
 $help=ReadExact $m.helper_path $m.helper_token (Join-Path $Evidence 'helper_marker.txt')
 $r['init_exact']=[bool]$init.exact
 $r['helper_exact']=[bool]$help.exact
 foreach($w in $m.probes){
   $stem=('cf_{0:D2}' -f [int]$w.index)
   $start=ReadExact $w.start_path $w.start_token (Join-Path $witDir ($stem+'_start.txt'))
   $capt=ReadExact $w.captured_path $w.captured_token (Join-Path $witDir ($stem+'_captured.txt'))
   $code=ReadNumbers $w.code_path (Join-Path $witDir ($stem+'_code.txt'))
   $value=ReadNumbers $w.value_path (Join-Path $witDir ($stem+'_value.txt'))
   $matches=$value.valid -and (($value.values -join ',') -ceq (@($w.expected_values) -join ','))
   $ecValid=$code.valid -and $code.values.Count -eq 1 -and (@(1,2) -contains [long]$code.values[0])
   $r['witnesses']+=@{index=[int]$w.index;name=$w.name;start_exact=[bool]$start.exact;
     captured_exact=[bool]$capt.exact;ec_success=[bool]$ecValid;
     value_match=[bool]$matches;actual_values=@($value.values);
     expected_values=@($w.expected_values);code_sha256=$code.sha256;value_sha256=$value.sha256;
     source_sha256=$w.sha256}
   Write-Output ('CF_WITNESS '+$w.name+' START='+$start.exact+' CAPTURED='+$capt.exact+
     ' EC_SUCCESS='+$ecValid+' VALUE_MATCH='+$matches+' ACTUAL='+($value.values -join ','))
 }
 $final=ReadExact $marker $m.marker_token (Join-Path $Evidence 'counterfactual_final_marker.txt')
 $r['final_marker_exact']=[bool]$final.exact
 $all=($r['fx_last_contiguous'] -eq 95) -and $r['fx_checkpoints'].Count -eq 23 -and
   (@($r['fx_checkpoints'] | Where-Object {$_.exact -ne $true}).Count -eq 0) -and
   $r['init_exact'] -and $r['helper_exact'] -and $r['final_marker_exact'] -and
   ($r['witnesses'].Count -eq 6) -and
   (@($r['witnesses'] | Where-Object {$_.start_exact -ne $true -or $_.captured_exact -ne $true -or
      $_.ec_success -ne $true -or $_.value_match -ne $true}).Count -eq 0)
 $r['status']=if($all){'COUNTERFACTUAL_WITNESSES_CONFIRMED_DIAGNOSTIC_ONLY'}else{'COUNTERFACTUAL_INCOMPLETE_NOT_STAGE01'}
 Write-Output ('COUNTERFACTUAL_NATIVE_STATUS='+$r['status'])
 Write-Output 'STAGE01=NOT_ACCEPTED'
 if(-not $all){throw 'COUNTERFACTUAL_GATE_INCOMPLETE'}
}catch{
 $r['errors']+=$_.Exception.Message
 if($r['status'] -ne 'COUNTERFACTUAL_INCOMPLETE_NOT_STAGE01'){$r['status']='FAIL_CLOSED_NOT_STAGE01'}
 throw
}finally{
 $r | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath (Join-Path $Evidence 'native_counterfactual.json') -Encoding utf8
}
