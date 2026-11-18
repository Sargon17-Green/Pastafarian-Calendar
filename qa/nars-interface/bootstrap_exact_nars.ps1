# Ephemeral GitHub-hosted Windows runner ONLY. Extract verified publisher installer with
# independently SHA-pinned innoextract, install font locally; never upload font data.
[CmdletBinding()]
param([string]$Evidence='font_bootstrap_evidence', [string]$Runtime='verified_runtime')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
New-Item -ItemType Directory -Force $Evidence | Out-Null
$Evidence=(Resolve-Path -LiteralPath $Evidence).Path
$r=[ordered]@{schema='APL_GERMAN_EXACT_NARS_EPHEMERAL_FONT_BOOTSTRAP_V1';status='STARTED';native_executed=$false;stage01='NOT_RUN';font_file_distributed=$false;errors=@()}
$installerExpected='28e8d1dbcea13360a271e704196b5680f0c3e9461cfc38daa41b96dba202f11b'
$innoExpected='6989342c9b026a00a72a38f23b62a8e6a22cc5de69805cf47d68ac2fec993065'
$fontExpected='d8737961e978646c80bf2cf49269592195be2727325180cf2dbabc2ce71c76f9'
$expectedFiles=[ordered]@{
 'NARS2000.exe'='192b7bd3c06a64ef57bfe1ea7f04e5d5d511ae9cd07323cfd211710891e2069d'
 'crashrpt.dll'='461fa51cd64408878cc57da97f740b992c0ad98802ab31fa8a39aa20cc9983c5'
 'dbghelp.dll'='159b30d9f1bbe69ae03e0d19669d4fcb565246d81672b7034a69cef9f466dcbe'
 'sendrpt.exe'='4726c90412275df4942d1a8051687918c9838486c3c8aabe327f1bfdbf8899c2'
}
function Sha([string]$f){return (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash.ToLowerInvariant()}
try {
 if(-not $env:RUNNER_TEMP){throw 'GITHUB_RUNNER_TEMP_MISSING'}
 $installer='pinned_release/verified_release/NARS2000-0.5.14.11.exe'
 if(-not (Test-Path -LiteralPath $installer -PathType Leaf)){throw 'OFFICIAL_INSTALLER_ARTIFACT_MISSING'}
 if((Get-Item -LiteralPath $installer).Length -ne 9430788 -or (Sha $installer) -ne $installerExpected){throw 'OFFICIAL_INSTALLER_SHA_SIZE_INVALID'}
 $r['installer_sha256_verified']=$true
 $toolZip=Join-Path $env:RUNNER_TEMP 'innoextract-1.9-windows.zip'
 $toolUrl='https://github.com/dscharrer/innoextract/releases/download/1.9/innoextract-1.9-windows.zip'
 Invoke-WebRequest -Uri $toolUrl -OutFile $toolZip -MaximumRedirection 3 -TimeoutSec 90
 $r['tool_zip_sha256']=Sha $toolZip
 if($r['tool_zip_sha256'] -ne $innoExpected){throw 'INNOEXTRACT_TOOL_HASH_MISMATCH'}
 $toolDir=Join-Path $env:RUNNER_TEMP 'innoextract_tool'
 Expand-Archive -LiteralPath $toolZip -DestinationPath $toolDir -Force
 $inno=@(Get-ChildItem -LiteralPath $toolDir -Filter 'innoextract.exe' -File -Recurse)
 if($inno.Count -ne 1){throw ('INNOEXTRACT_BINARY_COUNT='+$inno.Count)}
 $unpack=Join-Path $env:RUNNER_TEMP 'nars_inno_unpacked'
 New-Item -ItemType Directory -Force -Path $unpack | Out-Null
 & $inno[0].FullName --extract --output-dir $unpack $installer 2>&1 | Out-File -LiteralPath (Join-Path $Evidence 'extractor.log') -Encoding utf8
 if($LASTEXITCODE -ne 0){throw ('INNOEXTRACT_EXIT_CODE='+$LASTEXITCODE)}
 $app=Join-Path $unpack 'app'
 $runtimeAbs=Join-Path ((Get-Location).Path) $Runtime
 New-Item -ItemType Directory -Force -Path $runtimeAbs | Out-Null
 foreach($filename in $expectedFiles.Keys){
   $source=Join-Path $app $filename
   if(-not (Test-Path -LiteralPath $source -PathType Leaf)){throw ('MISSING_EXTRACTED_RUNTIME_FILE='+$filename)}
   if((Sha $source) -ne $expectedFiles[$filename]){throw ('EXTRACTED_RUNTIME_SHA_MISMATCH='+$filename)}
   Copy-Item -LiteralPath $source -Destination (Join-Path $runtimeAbs $filename) -Force
 }
 if(@(Get-ChildItem -LiteralPath $runtimeAbs -File).Count -ne 4){throw 'RUNTIME_FILE_SET_NOT_EXACT'}
 $r['runtime_files_verified']=4
 $font=Join-Path $app 'SImPL-Medium.ttf'
 if(-not (Test-Path -LiteralPath $font -PathType Leaf)){throw 'OFFICIAL_APL_FONT_MISSING'}
 if((Sha $font) -ne $fontExpected){throw 'OFFICIAL_APL_FONT_SHA_MISMATCH'}
 $r['font_sha256_verified']=$true
 # On this disposable CI VM, install the exact bundled font using documented
 # Windows font registration. Do not copy, upload, or surface TTF as an artifact.
 $dest=Join-Path $env:WINDIR 'Fonts\SImPL-Medium.ttf'
 Copy-Item -LiteralPath $font -Destination $dest -Force
 $key='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
 New-ItemProperty -Path $key -Name 'SImPL Medium (TrueType)' -Value 'SImPL-Medium.ttf' -PropertyType String -Force | Out-Null
 Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class CI_FontGdi {
 [DllImport("gdi32.dll", CharSet=CharSet.Unicode)]
 public static extern int AddFontResource(string file);
}
'@ -ErrorAction Stop
 $registered=[CI_FontGdi]::AddFontResource($dest)
 $r['gdi_registration_result']=$registered
 if($registered -lt 1){throw 'GDI_ADD_FONT_RESOURCE_FAILED'}
 $r['font_installed_on_disposable_CI_VM']=$true
 $r['status']='EXACT_4_RUNTIME_AND_FONT_READY_FOR_NATIVE_LX'
} catch {
 $r['errors']+= $_.Exception.Message
 $r['status']='FAIL_CLOSED'
 throw
} finally {
 $r | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $Evidence 'font_bootstrap.json') -Encoding utf8
 Write-Output ('CI_FONT_BOOTSTRAP_STATUS='+$r['status'])
 Write-Output 'FONT_TTF_NOT_INCLUDED_IN_EVIDENCE=TRUE'
}
