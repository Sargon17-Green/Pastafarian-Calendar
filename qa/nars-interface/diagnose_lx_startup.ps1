# On ephemeral GitHub-hosted Windows only. Real EXE + workspace startup diagnostic, NOT Stage1.
[CmdletBinding()]
param([string]$Runtime='verified_runtime',[string]$Evidence='workspace_launch_evidence')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
New-Item -ItemType Directory -Force $Evidence | Out-Null
$Evidence=(Resolve-Path -LiteralPath $Evidence).Path
$sha='192b7bd3c06a64ef57bfe1ea7f04e5d5d511ae9cd07323cfd211710891e2069d'
$report=[ordered]@{
 schema='NARS2000_WORKSPACE_ARGUMENT_AND_WINDOW_DIAGNOSTIC_V1';
 source_run=44379437067;
 expected_binary_sha256=$sha;
 stage01='NOT_RUN';
 status='STARTED';
 trials=@();
 errors=@();
}
function Snap([string]$target){
  try {
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    $screen=[System.Windows.Forms.Screen]::PrimaryScreen
    if($null -eq $screen){return 'SCREEN_UNAVAILABLE'}
    $area=$screen.Bounds
    if($area.Width -le 0 -or $area.Height -le 0){return 'SCREEN_INVALID_SIZE'}
    $bmp=New-Object System.Drawing.Bitmap($area.Width,$area.Height)
    try {
      $g=[System.Drawing.Graphics]::FromImage($bmp)
      try{$g.CopyFromScreen($area.Location,[System.Drawing.Point]::Empty,$area.Size)}finally{$g.Dispose()}
      $bmp.Save($target,[System.Drawing.Imaging.ImageFormat]::Png)
    }finally{$bmp.Dispose()}
    return 'SCREEN_CAPTURED'
  }catch{return 'SCREEN_CAPTURE_FAILED:'+ $_.Exception.Message}
}
function TryMode([string]$mode,[string]$exe,[string]$base,[string]$marker,[int]$seconds){
  if(Test-Path -LiteralPath $marker){Remove-Item -LiteralPath $marker -Force}
  $args=if($mode -eq 'FULL_EXTENSION'){'"'+$base+'.ws.nars"'}else{'"'+$base+'"'}
  $trial=[ordered]@{mode=$mode;arguments=$args;process_started=$false;marker_found=$false;marker_exact=$false;window_titles=@();elapsed_seconds=0;process_exit_code=$null;screenshot='NOT_ATTEMPTED'}
  $p=$null;$timer=[Diagnostics.Stopwatch]::StartNew()
  try{
    $p=Start-Process -FilePath $exe -ArgumentList $args -WorkingDirectory (Split-Path -Parent $exe) -PassThru
    $trial['process_started']=$true;$trial['pid']=$p.Id
    $deadline=[DateTime]::UtcNow.AddSeconds($seconds)
    $sampled=$false
    while([DateTime]::UtcNow -lt $deadline){
      Start-Sleep -Milliseconds 350
      $p.Refresh()
      if($p.MainWindowTitle -and -not ($trial['window_titles'] -contains $p.MainWindowTitle)){$trial['window_titles']+= $p.MainWindowTitle}
      if(-not $sampled -and $timer.Elapsed.TotalSeconds -gt 3){
        $trial['screenshot']=Snap (Join-Path $Evidence ('screen_'+$mode+'.png'))
        $sampled=$true
      }
      if(Test-Path -LiteralPath $marker){break}
      if($p.HasExited){break}
    }
    $trial['marker_found']=Test-Path -LiteralPath $marker -PathType Leaf
    if($trial['marker_found']){
       $actual=[IO.File]::ReadAllText($marker)
       $trial['marker_exact']=($actual.Trim() -eq 'APL_LX_CANARY_REAL_NATIVE_0_5_14_11')
       $trial['marker_bytes']=(Get-Item $marker).Length
    }
    $p.Refresh()
    if($p.HasExited){$trial['process_exit_code']=$p.ExitCode}
  }catch{$trial['error']=$_.Exception.Message}
  finally{
    $timer.Stop();$trial['elapsed_seconds']=[math]::Round($timer.Elapsed.TotalSeconds,2)
    if($null -ne $p -and -not $p.HasExited){& taskkill.exe /PID $p.Id /T /F 2>&1 | Out-Null}
  }
  return $trial
}
try{
 if(-not $env:RUNNER_TEMP){throw 'RUNNER_TEMP_MISSING'}
 $dir=(Resolve-Path -LiteralPath $Runtime).Path
 $exe=Join-Path $dir 'NARS2000.exe'
 if(-not (Test-Path -LiteralPath $exe)){throw 'NARS_EXE_NOT_FOUND'}
 $actual=(Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash.ToLowerInvariant()
 if($actual -ne $sha){throw 'NARS_EXE_SHA256_MISMATCH'}
 $fi=(Get-Item -LiteralPath $exe).VersionInfo
 $report['file_version']=$fi.FileVersion
 if($fi.FileVersion -ne '0.5.14.11'){throw 'NARS_EXE_FILEVERSION_MISMATCH'}
 $reference=Join-Path $env:RUNNER_TEMP 'official_2by2.ws.nars'
 Invoke-WebRequest 'https://www.nars2000.org/download/workspaces/2by2.ws.nars' -OutFile $reference -TimeoutSec 90 -MaximumRedirection 3
 if((Get-Item $reference).Length -lt 50 -or (Get-Item $reference).Length -gt 25000000){throw 'REFERENCE_WORKSPACE_SIZE_UNSAFE'}
 $report['reference_workspace_sha256']=(Get-FileHash $reference -Algorithm SHA256).Hash.ToLowerInvariant()
 $marker=Join-Path $env:RUNNER_TEMP 'APL_LX_DIAG_receipt.txt'
 $report['marker_path']=$marker
 $base=Join-Path $env:RUNNER_TEMP 'nars_diagnostic_workspace'
 & python qa/nars-interface/lx_workspace_probe.py --source $reference --candidate ($base+'.ws.nars') --receipt (Join-Path $Evidence 'workspace_receipt.json') --canary $marker
 if($LASTEXITCODE -ne 0){throw 'CANDIDATE_BUILD_FAILED'}
 $report['candidate_sha256']=(Get-FileHash ($base+'.ws.nars') -Algorithm SHA256).Hash.ToLowerInvariant()
 foreach($mode in @('FULL_EXTENSION','BARE_BASE')){
   $trial=TryMode $mode $exe $base $marker 13
   $report['trials']+= $trial
   if($trial['marker_exact']){break}
 }
 $matched=@($report['trials']|Where-Object {$_['marker_exact']}).Count -gt 0
 $report['status']=if($matched){'LX_SENTINEL_CONFIRMED_NOT_STAGE01'}else{'NO_LX_SENTINEL_WITH_WINDOW_DIAGNOSTICS'}
}catch{
 $report['status']='FAIL_CLOSED';$report['errors']+= $_.Exception.Message
 throw
}finally{
 $report|ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $Evidence 'workspace_launch_diag.json') -Encoding utf8
 Write-Output ('WORKSPACE_LAUNCH_DIAG='+$report['status'])
 Write-Output 'STAGE01=NOT_RUN'
}
