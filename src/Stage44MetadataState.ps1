Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'StrictUtf8StageMetadata.ps1')

# Shape validation is not historical CI adjudication.
$script:Stage44FrozenBlob = '91f8dd0237903bc4db9131ba506bc398c92c3258'

function Get-Stage44FrozenBytes {
    param([Parameter(Mandatory=$true)][string]$RepositoryRoot)
    if (-not [IO.Directory]::Exists($RepositoryRoot) -or $RepositoryRoot.Contains('"')) { throw 'INVALID_ROOT' }
    $psi = [Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = 'git'
    $psi.Arguments = '-C "' + $RepositoryRoot + '" cat-file blob ' + $script:Stage44FrozenBlob
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $p = [Diagnostics.Process]::new()
    $p.StartInfo = $psi
    $m = [IO.MemoryStream]::new()
    try {
        if (-not $p.Start()) { throw 'GIT_START_FAILED' }
        $p.StandardOutput.BaseStream.CopyTo($m)
        $err = $p.StandardError.ReadToEnd()
        $p.WaitForExit()
        if ($p.ExitCode -ne 0) { throw ('GIT_READ_FAILED: ' + $err) }
        [byte[]]$data = $m.ToArray()
        [byte[]]$header = [Text.Encoding]::ASCII.GetBytes(('blob ' + $data.Length + [char]0))
        $sha = [Security.Cryptography.SHA1]::Create()
        try {
            $digest = [BitConverter]::ToString($sha.ComputeHash([byte[]]($header + $data))).Replace('-','').ToLowerInvariant()
        } finally { $sha.Dispose() }
        if ($digest -cne $script:Stage44FrozenBlob) { throw 'FROZEN_BLOB_HASH_MISMATCH' }
        return ,$data
    } finally { $m.Dispose(); $p.Dispose() }
}

function New-Stage44Result {
    param([bool]$Success,[string]$Reason,[string]$Profile='REJECT_STATE',[object]$Values=$null)
    [pscustomobject]@{Success=$Success;ReasonCode=$Reason;Profile=$Profile;Values=$Values}
}

function Get-Stage44MetadataState {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][AllowNull()][AllowEmptyCollection()][byte[]]$Bytes,
          [Parameter(Mandatory=$true)][string]$RepositoryRoot)
    try {
        $frozen = ConvertFrom-StrictStageMetadataBytes -Bytes (Get-Stage44FrozenBytes -RepositoryRoot $RepositoryRoot) -RequiredKeys @()
        $candidate = ConvertFrom-StrictStageMetadataBytes -Bytes $Bytes -RequiredKeys @('CURRENT_STAGE','CURRENT_DISCOVERY','LAST_COMPLETED_STAGE','CURRENT_KIND','CURRENT_PATCH')
        if (-not $frozen.Success -or $frozen.Values.Count -ne 796 -or $frozen.Values['CURRENT_STAGE'] -cne '43' -or $frozen.Values['LAST_COMPLETED_STAGE'] -cne '43' -or $frozen.Values['STAGE43_SEAL_COMMIT_NATIVE_RECHECK'] -cne 'PASS') { return New-Stage44Result $false 'INVALID_BASELINE' }
        if (-not $candidate.Success) { return New-Stage44Result $false ('PARSER_' + $candidate.ReasonCode) }
        $v = $candidate.Values
        $expected = New-StrictStageMetadataDictionary
        foreach ($key in $frozen.Values.Keys) { $expected.Add($key,$frozen.Values[$key]) }
        $expected['CURRENT_STAGE']='44'
        $expected['CURRENT_DISCOVERY']='29'
        $plan = @{
            DISCOVERY='MOVING_NEIGHBOR_YEAR_GATE_INTERACTION'; PLANNING_STATUS='IMPLEMENTED_PREFLIGHT_VERIFIED'
            PLANNED_CALC_DAYS='6'; PLANNED_GATES_PER_CONTEXT='4'; PLANNED_TARGET_OFFSETS='-1,0,1'
            PLANNED_TARGET_DAYS='12'; PLANNED_SEALS='10'; PLANNED_ENDPOINTS='720'; PLANNED_RECTANGLES='320'
            PLANNED_STRUCTURAL_GUARDS='67'; PLANNED_SOURCE_CONTEXTS='72'; PLANNED_ORACLE_CONTEXTS='72'; PLANNED_ASSERTIONS='5027'
        }
        foreach ($key in $plan.Keys) { $expected.Add(('STAGE44_'+$key),$plan[$key]) }
        $profile = ''
        $phases = @()
        if ($v['LAST_COMPLETED_STAGE'] -ceq '43') {
            $profile='STAGE44_PENDING_SHAPE_ONLY'; $phases=@('PREFLIGHT')
            $runtime='PENDING_NATIVE'; $accept='NOT_CLAIMED'; $seal='NOT_RUN'
        } elseif ($v['LAST_COMPLETED_STAGE'] -ceq '44' -and $v.ContainsKey('STAGE44_SEAL_COMMIT_NATIVE_RECHECK')) {
            $runtime='EVIDENCE_ONLY_CONFIRMED'; $accept='IMPLEMENTING_SHA_ACCEPTED'
            if ($v['STAGE44_SEAL_COMMIT_NATIVE_RECHECK'] -ceq 'PENDING_NEW_SHA') {
                $profile='STAGE44_IMPLEMENTING_SHAPE_ONLY'; $phases=@('PREFLIGHT','NATIVE'); $seal='PENDING_NEW_SHA'
            } elseif ($v['STAGE44_SEAL_COMMIT_NATIVE_RECHECK'] -ceq 'PASS') {
                $profile='STAGE44_SEALED_SHAPE_ONLY'; $phases=@('PREFLIGHT','NATIVE','SEAL'); $seal='PASS'
            }
        }
        if ($profile -ceq '') { return New-Stage44Result $false 'INVALID_PROFILE' }
        $expected['LAST_COMPLETED_STAGE']=$v['LAST_COMPLETED_STAGE']
        $expected.Add('STAGE44_RUNTIME_VERIFICATION',$runtime)
        $expected.Add('STAGE44_ACTIVATION',$runtime)
        $expected.Add('STAGE44_NATIVE_ACCEPTANCE',$accept)
        $expected.Add('STAGE44_SEAL_COMMIT_NATIVE_RECHECK',$seal)
        $fixed=@{
            ASSERTIONS_PASSED='5027'; ASSERTIONS_FAILED='0'; ENDPOINTS='720'; RECTANGLES='320'
            STRUCTURAL_GUARDS='67'; SOURCE_CONTEXTS='72'; ORACLE_CONTEXTS='72'; CANONICAL_JOBS='18_OF_18_SUCCESS'
            STAGE43_ASSERTIONS='2215'; FINALIZER_IDEMPOTENCY='PASS'; CANONICAL_VERIFY='SUCCESS'
        }
        $patterns=@{
            CI_SHA='\A[0-9a-f]{40}\z'; DEDICATED_RUN='\A[1-9][0-9]*\z'; DEDICATED_JOB='\A[1-9][0-9]*\z'
            CANONICAL_RUN='\A[1-9][0-9]*\z'; DEDICATED_ARTIFACT='\A[1-9][0-9]*\z'; DEDICATED_ARTIFACT_SHA256='\A[0-9a-f]{64}\z'
            FINALIZER_ARTIFACT='\A[1-9][0-9]*\z'; FINALIZER_SHA256='\A[0-9a-f]{64}\z'; RUNTIME='\A5\.1\.[0-9]+(?:\.[0-9]+)?\z'
        }
        $shas=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        $runs=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        $jobs=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        $artifacts=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        foreach ($phase in $phases) {
            $prefix='STAGE44_'+$phase+'_'
            foreach ($key in $fixed.Keys) { $expected.Add(($prefix+$key),$fixed[$key]) }
            foreach ($key in $patterns.Keys) {
                $full=$prefix+$key
                if (-not $v.ContainsKey($full) -or $v[$full] -cnotmatch $patterns[$key]) { return New-Stage44Result $false ('INVALID_FIELD:'+$full) }
                $expected.Add($full,$v[$full])
            }
            # The reusable Stage44 job belongs to the canonical run; only cross-phase run reuse is forbidden.
            if ($v[$prefix+'DEDICATED_RUN'] -cne $v[$prefix+'CANONICAL_RUN']) { return New-Stage44Result $false 'RUN_TOPOLOGY_MISMATCH' }
            if (-not $shas.Add($v[$prefix+'CI_SHA']) -or -not $runs.Add($v[$prefix+'CANONICAL_RUN']) -or -not $jobs.Add($v[$prefix+'DEDICATED_JOB']) -or -not $artifacts.Add($v[$prefix+'DEDICATED_ARTIFACT']) -or -not $artifacts.Add($v[$prefix+'FINALIZER_ARTIFACT'])) { return New-Stage44Result $false 'REUSED_EVIDENCE_IDENTITY' }
        }
        if ($expected.Count -ne (813+20*$phases.Count) -or $v.Count -ne $expected.Count) { return New-Stage44Result $false 'KEY_COUNT_MISMATCH' }
        foreach ($key in $expected.Keys) {
            if (-not $v.ContainsKey($key) -or $v[$key] -cne $expected[$key]) { return New-Stage44Result $false ('MAP_MISMATCH:'+$key) }
        }
        return New-Stage44Result $true 'OK_SHAPE_ONLY' $profile $v
    } catch { return New-Stage44Result $false ('VALIDATION_EXCEPTION:'+$_.Exception.GetType().FullName) }
}

# Trusted evidence must come from external adjudication, never from candidate metadata.
# All 20 keys per accepted phase are compared, not merely their digest syntax.
function Test-Stage44PhaseEvidenceBinding {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][object]$State,
          [Parameter(Mandatory=$true)][System.Collections.Generic.Dictionary[string,string]]$TrustedEvidence)
    if (-not $State.Success -or $State.Profile -cnotin @('STAGE44_PENDING_SHAPE_ONLY','STAGE44_IMPLEMENTING_SHAPE_ONLY','STAGE44_SEALED_SHAPE_ONLY')) { return $false }
    $keys = @($State.Values.Keys | Where-Object { $_ -cmatch '\ASTAGE44_(PREFLIGHT|NATIVE|SEAL)_' -and $_ -cne 'STAGE44_NATIVE_ACCEPTANCE' -and $_ -cne 'STAGE44_SEAL_COMMIT_NATIVE_RECHECK' })
    if ($TrustedEvidence.Count -ne $keys.Count) { return $false }
    foreach ($key in $keys) {
        if (-not $TrustedEvidence.ContainsKey($key) -or $TrustedEvidence[$key] -cne $State.Values[$key]) { return $false }
    }
    return $true
}
