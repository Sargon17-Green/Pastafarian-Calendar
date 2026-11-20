# Ephemeral, version-pinned NARS2000 diagnostic: bounded locked-source prefix via ⎕FX.
[CmdletBinding()]
param([string]$Runtime='verified_runtime',[string]$Evidence='prefix_fx_evidence',[int]$Count=5)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
if($Count -lt 1 -or $Count -gt 95){throw 'PREFIX_COUNT_OUT_OF_BOUNDS'}
New-Item -ItemType Directory -Force $Evidence | Out-Null
$Evidence=(Resolve-Path -LiteralPath $Evidence).Path
$expectedExe='192b7bd3c06a64ef57bfe1ea7f04e5d5d511ae9cd07323cfd211710891e2069d'
$r=[ordered]@{
 schema='APL_GERMAN_NATIVE_STAGE01_FX_PREFIX_V2'
 fx_count=$Count
 status='STARTED'
 stage01='NOT_RUN'
 runtime_verified=$false
 native_started=$false
 native_fx='NOT_CONFIRMED'
 marker=[ordered]@{exists=$false;exact=$false;bytes=0;sha256=$null}
 errors=@()
}
try {
 if(-not $env:RUNNER_TEMP){throw 'RUNNER_TEMP_MISSING'}
 $runtimeRoot=(Resolve-Path -LiteralPath $Runtime).Path
 $exe=Join-Path $runtimeRoot 'NARS2000.exe'
 if((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash.ToLowerInvariant() -cne $expectedExe){throw 'NARS_EXE_SHA_MISMATCH'}
 if((Get-Item -LiteralPath $exe).VersionInfo.FileVersion -cne '0.5.14.11'){throw 'NARS_VERSION_MISMATCH'}
 $r['runtime_verified']=$true
 $ws=Join-Path $env:RUNNER_TEMP 'nars_reference_2by2.ws.nars'
 Invoke-WebRequest -Uri 'https://www.nars2000.org/download/workspaces/2by2.ws.nars' -OutFile $ws -TimeoutSec 90 -MaximumRedirection 3
 if((Get-Item $ws).Length -gt 25000000){throw 'WORKSPACE_SIZE_UNSAFE'}
 $prefix=Join-Path $env:RUNNER_TEMP ('apl_german_fx_prefix_'+$Count)
 $candidate=$prefix+'.ws.nars'
 $receipt=Join-Path $Evidence 'candidate.json'
 $marker=Join-Path $env:RUNNER_TEMP ('apl_stage01_prefix_fx_'+$Count+'.txt')
 if(Test-Path $marker){throw 'MARKER_PREEXISTING'}
 & python qa/nars-interface/stage01_fx_prefix_probe.py --repo-root . --source $ws --candidate $candidate --receipt $receipt --marker $marker --count $Count
 if($LASTEXITCODE -ne 0){throw 'PREFIX_GENERATOR_FAILED'}
 $meta=Get-Content $receipt -Raw | ConvertFrom-Json
 if($meta.status -ne 'GENERATED_NOT_NATIVE_VALIDATED' -or $meta.native_executed -ne $false -or $meta.fx_count -ne $Count -or $meta.fx_names.Count -ne $Count){throw 'PREFIX_METADATA_GATE_FAILED'}
 $csha=(Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash.ToLowerInvariant()
 if($csha -cne $meta.candidate_sha256){throw 'PREFIX_CANDIDATE_HASH_MISMATCH'}
 $r['candidate_sha256']=$csha
 $r['source_commit']=$meta.source_commit
 $r['fx_expected_names']=$meta.fx_names
 $r['candidate_bytes']=(Get-Item $candidate).Length
 $p=Start-Process -FilePath $exe -ArgumentList ('"'+$prefix+'"') -WorkingDirectory $runtimeRoot -PassThru
 $r['native_started']=$true
 $r['process_id']=$p.Id
 $expected=[System.Text.Encoding]::ASCII.GetBytes([string]$meta.marker_token)
 $deadline=[DateTime]::UtcNow.AddSeconds($(if($Count -le 5){45}else{90}))
 while([DateTime]::UtcNow -lt $deadline){
   if(Test-Path -LiteralPath $marker -PathType Leaf){
     if((Get-Item -LiteralPath $marker).Length -ge $expected.Length){break}
   }
   Start-Sleep -Milliseconds 250
   $p.Refresh()
   if($p.HasExited){break}
 }
 $p.Refresh()
 $wasRunning=-not $p.HasExited
 $r['diagnostic_screenshot']='NOT_NEEDED'
 if($wasRunning -and -not (Test-Path -LiteralPath $marker -PathType Leaf)){
   # Only record the isolated GitHub CI VM. Useful for Native APL errors;
   # never include the ephemeral font, process dumps or unredacted environment.
   try {
     Add-Type -AssemblyName System.Drawing -ErrorAction Stop
     Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
     $screen=[System.Windows.Forms.Screen]::PrimaryScreen
     if($null -eq $screen -or $screen.Bounds.Width -le 0 -or $screen.Bounds.Height -le 0){
       $r['diagnostic_screenshot']='SCREEN_UNAVAILABLE'
     }else{
       $area=$screen.Bounds
       $bitmap=New-Object System.Drawing.Bitmap($area.Width,$area.Height)
       try {
         $g=[System.Drawing.Graphics]::FromImage($bitmap)
         try { $g.CopyFromScreen($area.Location,[System.Drawing.Point]::Empty,$area.Size) } finally { $g.Dispose() }
         $bitmap.Save((Join-Path $Evidence 'prefix_native_failure_screen.png'),[System.Drawing.Imaging.ImageFormat]::Png)
         $r['diagnostic_screenshot']='SCREEN_CAPTURED'
       }finally{$bitmap.Dispose()}
     }
   }catch{
     $r['diagnostic_screenshot']='SCREEN_CAPTURE_FAILED'
     $r['screenshot_error_type']=$_.Exception.GetType().Name
   }
 }
 if($wasRunning){
   & taskkill.exe /PID $p.Id /T /F 2>&1 | Out-Null
   try{Wait-Process -Id $p.Id -Timeout 8 -ErrorAction Stop}catch{}
   $p.Refresh()
 }
 if(-not $p.HasExited){throw 'NARS_NOT_TERMINATED'}
 $exists=Test-Path -LiteralPath $marker -PathType Leaf
 [byte[]]$actual=@()
 if($exists){$actual=[System.IO.File]::ReadAllBytes($marker)}
 $exact=($actual.Length -eq $expected.Length) -and ([Convert]::ToBase64String($actual) -ceq [Convert]::ToBase64String($expected))
 $sha=if($exists){(Get-FileHash -LiteralPath $marker -Algorithm SHA256).Hash.ToLowerInvariant()}else{$null}
 $r['marker']=[ordered]@{exists=$exists;exact=$exact;bytes=$actual.Length;expected_bytes=$expected.Length;sha256=$sha;was_running=$wasRunning}
 $r['native_fx']=if($exact){'CONFIRMED'}else{'NOT_CONFIRMED'}
 $r['status']=if($exact){'NATIVE_FX_PREFIX'+$Count+'_CONFIRMED_NOT_STAGE01'}else{'NATIVE_FX_PREFIX'+$Count+'_NOT_CONFIRMED'}
}catch{
 $r['status']='FAIL_CLOSED'
 $r['errors']+=$_.Exception.Message
 throw
}finally{
 $r | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $Evidence 'native_prefix_fx.json') -Encoding utf8
 Write-Output ('PREFIX_NATIVE_STATUS='+$r['status'])
 Write-Output ('PREFIX_COUNT='+$Count)
 Write-Output ('PREFIX_SOURCE_COMMIT='+$r['source_commit'])
 Write-Output ('PREFIX_MARKER_EXACT='+$r['marker'].exact)
 Write-Output 'STAGE01=NOT_RUN'
}
