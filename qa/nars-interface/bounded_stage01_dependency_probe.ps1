# QA-only source-locked root-cause capture. Cannot accept Stage1.
[CmdletBinding()]
param([string]$Runtime='verified_runtime',[string]$Evidence='rootcause_probe_evidence')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$source='7161824b9fcbfaca91f20d1ea492417e77003ff4'
$r=[ordered]@{
 schema='APL_GERMAN_NATIVE_STAGE01_ROOTCAUSE_CAPTURE_V1';source_commit=$source;
 stage01='NOT_ACCEPTED';status='STARTED';runtime_verified=$false;native_executed=$false;
 fx_checkpoints=@();fx_last_contiguous=0;probes=@();dependency_probes=@();final_marker_exact=$false;
 process_running_after_receipt=$false;stopped_by_runner=$false;errors=@()
}
New-Item -ItemType Directory -Force $Evidence | Out-Null
$Evidence=(Resolve-Path -LiteralPath $Evidence).Path
function Read-Token([string]$path,[string]$token,[string]$dest){
 $exists=Test-Path -LiteralPath $path -PathType Leaf
 if(-not $exists){return @{exists=$false;exact=$false;sha256=$null}}
 [byte[]]$actual=[IO.File]::ReadAllBytes($path)
 [byte[]]$wanted=[Text.Encoding]::ASCII.GetBytes($token)
 Copy-Item -LiteralPath $path -Destination $dest -Force
 $equal=$actual.Length -eq $wanted.Length -and
   [Convert]::ToBase64String($actual) -ceq [Convert]::ToBase64String($wanted)
 return @{exists=$true;exact=[bool]$equal;sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()}
}
function Read-EcMessage([string]$path,[string]$dest){
 if(-not $path -or -not (Test-Path -LiteralPath $path -PathType Leaf)){
   return @{message=$null;sha256=$null;exists=$false}
 }
 [byte[]]$bytes=[IO.File]::ReadAllBytes($path)
 Copy-Item -LiteralPath $path -Destination $dest -Force
 $sha=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
 $message=$null
 $numeric=[Text.Encoding]::ASCII.GetString($bytes)
 if($bytes.Length -gt 0 -and $bytes.Length -le 8192 -and $numeric -cmatch '^\s*\d+(\s+\d+)*\s*$'){
   $points=@([regex]::Matches($numeric,'\d+') | ForEach-Object {[int]$_.Value})
   if($points.Count -gt 0 -and @($points | Where-Object {$_ -lt 0 -or $_ -gt 65535}).Count -eq 0){
     $message=-join @($points | ForEach-Object {[char]$_})
   }
 }
 return @{message=$message;sha256=$sha;exists=$true}
}
try{
 if(-not $env:RUNNER_TEMP){throw 'RUNNER_TEMP_MISSING'}
 $rt=(Resolve-Path -LiteralPath $Runtime).Path
 $exe=Join-Path $rt 'NARS2000.exe'
 if(@(Get-ChildItem $rt -File).Count -ne 4){throw 'RUNTIME_FILE_COUNT_INVALID'}
 if((Get-FileHash $exe -Algorithm SHA256).Hash.ToLowerInvariant() -cne '192b7bd3c06a64ef57bfe1ea7f04e5d5d511ae9cd07323cfd211710891e2069d'){throw 'NARS_EXE_SHA_MISMATCH'}
 if((Get-Item $exe).VersionInfo.FileVersion -cne '0.5.14.11'){throw 'NARS_VERSION_MISMATCH'}
 $r['runtime_verified']=$true
 $official=Join-Path $env:RUNNER_TEMP 'nars_2by2_ec.ws.nars'
 Invoke-WebRequest -Uri 'https://www.nars2000.org/download/workspaces/2by2.ws.nars' -OutFile $official -TimeoutSec 90 -MaximumRedirection 3
 if((Get-FileHash $official -Algorithm SHA256).Hash.ToLowerInvariant() -cne '2eba3f2eb9f826b992ffaf4054db9a09da38f4ae2687168173be4a16fd08b11b'){throw 'BASE_WORKSPACE_SHA_MISMATCH'}
 $prefix=Join-Path $env:RUNNER_TEMP 'apl_german_stage01_rootcause_capture'
 $marker=$prefix+'.txt'
 $candidate=$prefix+'.ws.nars'
 $receipt=Join-Path $Evidence 'rootcause_candidate.json'
 if(Test-Path $marker){throw 'PREEXISTING_MARKER'}
 & python qa/nars-interface/stage01_dependency_probe.py --repo-root . --source $official --candidate $candidate --receipt $receipt --marker $marker
 if($LASTEXITCODE -ne 0){throw 'ROOTCAUSE_CANDIDATE_FAILED'}
 $m=Get-Content $receipt -Raw | ConvertFrom-Json
 if($m.schema -cne 'APL_GERMAN_STAGE01_ROOTCAUSE_DIAGNOSTIC_V1' -or $m.stage01 -cne 'NOT_ACCEPTED' -or $m.source_commit -cne $source -or
    $m.function_count -ne 95 -or $m.chunk_count -ne 23 -or $m.calls.Count -ne 3 -or $m.tests.Count -ne 3 -or $m.dependency_probes.Count -ne 28 -or
    $m.program_count -ne 62 -or $m.final_original_stage01_tests_executed -ne $false -or $m.original_stage01_acceptance_token_present -ne $false){throw 'CANDIDATE_CONTRACT_INVALID'}
 if((Get-FileHash $candidate -Algorithm SHA256).Hash.ToLowerInvariant() -cne $m.candidate_sha256){throw 'CANDIDATE_SHA_MISMATCH'}
 $r['candidate_sha256']=$m.candidate_sha256
 foreach($c in $m.chunk_records){if(Test-Path $c.marker_path){throw 'OLD_FX_RECEIPT'}}
 foreach($collection in @($m.calls,$m.dependency_probes)){
  foreach($s in $collection){
   foreach($field in @('start_path','captured_path','code_path','message_code_path','message_path')){
    if($null -ne $s.$field -and (Test-Path -LiteralPath $s.$field)){throw 'OLD_PROBE_RECEIPT'}
   }
  }
 }
 $p=Start-Process -FilePath $exe -ArgumentList ('"'+$prefix+'"') -WorkingDirectory $rt -PassThru
 $r['native_executed']=$true
 $wanted=[Text.Encoding]::ASCII.GetBytes([string]$m.marker_token)
 $deadline=[DateTime]::UtcNow.AddSeconds(300)
 while([DateTime]::UtcNow -lt $deadline){
  if(Test-Path $marker -PathType Leaf){if((Get-Item $marker).Length -ge $wanted.Length){break}}
  Start-Sleep -Milliseconds 250
  $p.Refresh()
  if($p.HasExited){break}
 }
 $p.Refresh()
 $r['process_running_after_receipt']=(-not $p.HasExited) -and (Test-Path $marker)
 if(-not $p.HasExited){
   & taskkill.exe /PID $p.Id /T /F 2>&1 | Out-Null
   $r['stopped_by_runner']=$true
   try{Wait-Process -Id $p.Id -Timeout 8 -ErrorAction Stop}catch{}
   $p.Refresh()
 }
 if(-not $p.HasExited){throw 'NARS_PROCESS_STILL_RUNNING'}
 $checkDir=Join-Path $Evidence 'checkpoint_files'
 $probeDir=Join-Path $Evidence 'probe_files'
 $depDir=Join-Path $Evidence 'dependency_files'
 New-Item -ItemType Directory -Force $checkDir,$probeDir,$depDir | Out-Null
 foreach($c in $m.chunk_records){
  $v=Read-Token $c.marker_path $c.token (Join-Path $checkDir ('after_{0:D2}.txt' -f [int]$c.after))
  $r['fx_checkpoints']+=@{after=[int]$c.after;exact=[bool]$v.exact;sha256=$v.sha256}
  if($v.exact){$r['fx_last_contiguous']=[int]$c.after}
 }
 foreach($s in $m.calls){
  $start=Read-Token $s.start_path $s.start_token (Join-Path $probeDir ('ec_{0:D2}_start.txt' -f [int]$s.index))
  $captured=Read-Token $s.captured_path $s.captured_token (Join-Path $probeDir ('ec_{0:D2}_captured.txt' -f [int]$s.index))
  $code=$null;$hash=$null
  if(Test-Path $s.code_path -PathType Leaf){
   [byte[]]$bytes=[IO.File]::ReadAllBytes($s.code_path)
   Copy-Item $s.code_path (Join-Path $probeDir ('ec_{0:D2}_code.txt' -f [int]$s.index))
   $hash=(Get-FileHash $s.code_path -Algorithm SHA256).Hash.ToLowerInvariant()
   $t=[Text.Encoding]::ASCII.GetString($bytes)
   if($bytes.Length -ge 1 -and $bytes.Length -le 64 -and $t -cmatch '^[0-9 ]+$'){$code=$t.Trim()}
  }
  $msg=Read-EcMessage $s.message_code_path (Join-Path $probeDir ('ec_{0:D2}_message_codes.txt' -f [int]$s.index))
  $r['probes']+=@{index=[int]$s.index;name=$s.name;start_exact=[bool]$start.exact;captured_exact=[bool]$captured.exact;
    first_ec_code=$code;code_sha256=$hash;error_message=$msg.message;message_code_sha256=$msg.sha256}
  Write-Output ('NATIVE_STMT_EC_PROBE '+$s.index+' '+$s.name+' START='+$start.exact+' CAPTURED='+$captured.exact+' FIRST_CODE='+$code+' ERROR_MESSAGE='+$msg.message)
 }
 $sdir=Join-Path $Evidence 'statement_files'
 New-Item -ItemType Directory -Force $sdir | Out-Null
 $r['statement_tests']=@()
 foreach($test in $m.tests){
   $entries=@()
   foreach($line in $test.statements){
     $stem=('stmt_{0:D2}_{1:D3}' -f [int]$test.index,[int]$line.sequence)
     $a=Read-Token $line.start_path $line.start_token (Join-Path $sdir ($stem+'_start.txt'))
     $b=Read-Token $line.end_path $line.end_token (Join-Path $sdir ($stem+'_end.txt'))
     $entries+=@{sequence=[int]$line.sequence;source_line=[int]$line.source_line;source_sha256=$line.source_sha256;
                 started=[bool]$a.exact;ended=[bool]$b.exact}
   }
   $open=@($entries | Where-Object {$_.started -and -not $_.ended})
   $bad=@($entries | Where-Object {$_.ended -and -not $_.started})
   $first=$null
   if($open.Count -eq 1 -and $bad.Count -eq 0){
     $candidate=$open[0]
     if(@($entries | Where-Object {$_.sequence -gt $candidate.sequence -and ($_.started -or $_.ended)}).Count -eq 0){
       $first=@{sequence=$candidate.sequence;source_line=$candidate.source_line;source_sha256=$candidate.source_sha256}
     }
   }
   $r['statement_tests']+=@{index=[int]$test.index;name=$test.name;original_function_instrumented_copy_only=$true;
     first_unfinished=$first;line_receipts=$entries;open_count=$open.Count;invalid_end_count=$bad.Count}
   if($null -ne $first){Write-Output ('NATIVE_FIRST_UNFINISHED '+$test.name+' SOURCE_LINE='+$first.source_line+' SHA256='+$first.source_sha256)}
   else{Write-Output ('NATIVE_STATEMENT_NOT_ISOLATED '+$test.name)}
 }
 foreach($d in $m.dependency_probes){
   $start=Read-Token $d.start_path $d.start_token (Join-Path $depDir ('dep_{0:D2}_start.txt' -f [int]$d.index))
   $captured=Read-Token $d.captured_path $d.captured_token (Join-Path $depDir ('dep_{0:D2}_captured.txt' -f [int]$d.index))
   $code=$null;$codeSha=$null
   if(Test-Path -LiteralPath $d.code_path -PathType Leaf){
     [byte[]]$cb=[IO.File]::ReadAllBytes($d.code_path)
     Copy-Item -LiteralPath $d.code_path -Destination (Join-Path $depDir ('dep_{0:D2}_code.txt' -f [int]$d.index)) -Force
     $codeSha=(Get-FileHash -LiteralPath $d.code_path -Algorithm SHA256).Hash.ToLowerInvariant()
     $s=[Text.Encoding]::ASCII.GetString($cb)
     if($cb.Length -ge 1 -and $cb.Length -le 64 -and $s -cmatch '^[0-9 ]+$'){$code=$s.Trim()}
   }
   $valueSha=$null;$valueBytes=0;$valuePreview=$null
   if(Test-Path -LiteralPath $d.value_path -PathType Leaf){
     [byte[]]$vb=[IO.File]::ReadAllBytes($d.value_path)
     Copy-Item -LiteralPath $d.value_path -Destination (Join-Path $depDir ('dep_{0:D2}_value.bin' -f [int]$d.index)) -Force
     $valueSha=(Get-FileHash -LiteralPath $d.value_path -Algorithm SHA256).Hash.ToLowerInvariant()
     $valueBytes=$vb.Length
     if($vb.Length -ge 1 -and $vb.Length -le 256){
       $ascii=[Text.Encoding]::ASCII.GetString($vb)
       if($ascii -cmatch '^[\x20-\x7E]+$'){$valuePreview=$ascii}
     }
   }
   $msg=Read-EcMessage $d.message_path (Join-Path $depDir ('dep_{0:D2}_message_codes.txt' -f [int]$d.index))
   $r['dependency_probes']+=@{index=[int]$d.index;name=$d.name;source_file=$d.source_file;source_line=[int]$d.source_line;
     source_sha256=$d.source_sha256;start_exact=[bool]$start.exact;captured_exact=[bool]$captured.exact;
     first_ec_code=$code;code_sha256=$codeSha;value_sha256=$valueSha;value_bytes=$valueBytes;
     value_ascii_preview=$valuePreview;error_message=$msg.message;message_code_sha256=$msg.sha256;mode=$d.mode}
   Write-Output ('NATIVE_DEP_PROBE '+$d.index+' '+$d.name+' START='+$start.exact+' CAPTURED='+$captured.exact+
      ' EC_CODE='+$code+' VALUE_SHA='+$valueSha+' ERROR_MESSAGE='+$msg.message)
 }
 $fm=Read-Token $marker $m.marker_token (Join-Path $Evidence 'rootcause_final_marker.txt')
 $r['final_marker_exact']=[bool]$fm.exact
 $callErrorsComplete=(@($r['probes'] | Where-Object {$_.first_ec_code -eq '0' -and [string]::IsNullOrWhiteSpace($_.error_message)}).Count -eq 0)
 $depErrorsComplete=(@($r['dependency_probes'] | Where-Object {$_.first_ec_code -eq '0' -and [string]::IsNullOrWhiteSpace($_.error_message)}).Count -eq 0)
 $complete=($r['fx_checkpoints'].Count -eq 23) -and ($r['fx_last_contiguous'] -eq 95) -and
   (@($r['fx_checkpoints'] | Where-Object {$_.exact -ne $true}).Count -eq 0) -and $fm.exact -and
   (@($r['probes'] | Where-Object {$_.start_exact -ne $true -or $_.captured_exact -ne $true -or $null -eq $_.first_ec_code}).Count -eq 0) -and
   $callErrorsComplete -and ($r['statement_tests'].Count -eq 3) -and
   (@($r['statement_tests'] | Where-Object {$null -eq $_.first_unfinished}).Count -eq 0) -and
   ($r['dependency_probes'].Count -eq 28) -and
   (@($r['dependency_probes'] | Where-Object {$_.start_exact -ne $true -or $_.captured_exact -ne $true -or $null -eq $_.first_ec_code}).Count -eq 0) -and
   $depErrorsComplete
 $r['status']=if($complete){'ROOTCAUSE_CAPTURE_COMPLETE_DIAGNOSTIC_ONLY'}else{'ROOTCAUSE_CAPTURE_PARTIAL_DIAGNOSTIC_ONLY'}
 Write-Output ('NATIVE_DIAGNOSTIC='+$r['status'])
 Write-Output 'STAGE01=NOT_ACCEPTED'
}catch{
 $r['status']='FAIL_CLOSED_NOT_STAGE01'
 $r['errors']+=$_.Exception.Message
 throw
}finally{
 $r | ConvertTo-Json -Depth 40 | Set-Content -LiteralPath (Join-Path $Evidence 'native_rootcause_diag.json') -Encoding utf8
}
