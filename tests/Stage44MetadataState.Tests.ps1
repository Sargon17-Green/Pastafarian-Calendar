Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
. (Join-Path $root 'src/Stage44MetadataState.ps1')
$baseline=ConvertFrom-StrictStageMetadataBytes -Bytes (Get-Stage44FrozenBytes -RepositoryRoot $root) -RequiredKeys @()
if (-not $baseline.Success -or $baseline.Values.Count -ne 796) { throw 'Invalid test baseline' }
function Copy44($map) {
    $copy=New-StrictStageMetadataDictionary
    foreach($key in $map.Keys) { $copy.Add($key,$map[$key]) }
    return ,$copy
}
function Encode44($map) {
    $lines=@(foreach($key in $map.Keys) { $key+'='+$map[$key] })
    return ,([Text.UTF8Encoding]::new($false).GetBytes(($lines -join [char]10)))
}
# Synthetic values are deliberately not real CI evidence.
function Fixture44([int]$count) {
    $m=Copy44 $baseline.Values
    $m['CURRENT_STAGE']='44'; $m['CURRENT_DISCOVERY']='29'
    $m['LAST_COMPLETED_STAGE']=if($count -eq 1){'43'}else{'44'}
    $core=@{
        DISCOVERY='MOVING_NEIGHBOR_YEAR_GATE_INTERACTION';PLANNING_STATUS='IMPLEMENTED_PREFLIGHT_VERIFIED'
        PLANNED_CALC_DAYS='6';PLANNED_GATES_PER_CONTEXT='4';PLANNED_TARGET_OFFSETS='-1,0,1';PLANNED_TARGET_DAYS='12'
        PLANNED_SEALS='10';PLANNED_ENDPOINTS='720';PLANNED_RECTANGLES='320';PLANNED_STRUCTURAL_GUARDS='67'
        PLANNED_SOURCE_CONTEXTS='72';PLANNED_ORACLE_CONTEXTS='72';PLANNED_ASSERTIONS='5027'
    }
    foreach($key in $core.Keys){$m.Add(('STAGE44_'+$key),$core[$key])}
    $runtime=if($count -eq 1){'PENDING_NATIVE'}else{'EVIDENCE_ONLY_CONFIRMED'}
    $m.Add('STAGE44_RUNTIME_VERIFICATION',$runtime);$m.Add('STAGE44_ACTIVATION',$runtime)
    $m.Add('STAGE44_NATIVE_ACCEPTANCE',$(if($count -eq 1){'NOT_CLAIMED'}else{'IMPLEMENTING_SHA_ACCEPTED'}))
    $m.Add('STAGE44_SEAL_COMMIT_NATIVE_RECHECK',@('NOT_RUN','PENDING_NEW_SHA','PASS')[$count-1])
    $names=@('PREFLIGHT','NATIVE','SEAL')
    for($i=0;$i -lt $count;$i++){
        $p='STAGE44_'+$names[$i]+'_'
        $fields=@{
            ASSERTIONS_PASSED='5027';ASSERTIONS_FAILED='0';ENDPOINTS='720';RECTANGLES='320';STRUCTURAL_GUARDS='67'
            SOURCE_CONTEXTS='72';ORACLE_CONTEXTS='72';CANONICAL_JOBS='17_OF_17_SUCCESS';STAGE43_ASSERTIONS='2215'
            FINALIZER_IDEMPOTENCY='PASS';CANONICAL_VERIFY='SUCCESS';CI_SHA=([string]($i+1)*40)
            DEDICATED_RUN=[string](100+$i*10);DEDICATED_JOB=[string](101+$i*10);CANONICAL_RUN=[string](102+$i*10)
            DEDICATED_ARTIFACT=[string](103+$i*10);DEDICATED_ARTIFACT_SHA256=('a'*64)
            FINALIZER_ARTIFACT=[string](104+$i*10);FINALIZER_SHA256=('b'*64);RUNTIME='5.1.12345.1'
        }
        foreach($key in $fields.Keys){$m.Add(($p+$key),$fields[$key])}
    }
    return ,$m
}
function State44($map){Get-Stage44MetadataState -Bytes (Encode44 $map) -RepositoryRoot $root}
$script:checks44=0
function Check44State([bool]$ok,[string]$label){if(-not $ok){throw ('Stage44 classifier: '+$label)};$script:checks44++}
foreach($n in 1..3){
    $m=Fixture44 $n
    $s=State44 $m
    Check44State ($s.Success -and $m.Count -eq (813+20*$n)) "positive $n"
    $trusted=New-StrictStageMetadataDictionary
    foreach($key in $m.Keys){
        if($key -cmatch '\ASTAGE44_(PREFLIGHT|NATIVE|SEAL)_' -and $key -cnotin @('STAGE44_NATIVE_ACCEPTANCE','STAGE44_SEAL_COMMIT_NATIVE_RECHECK')){$trusted.Add($key,$m[$key])}
    }
    Check44State (Test-Stage44PhaseEvidenceBinding -State $s -TrustedEvidence $trusted) "binding $n"
    foreach($key in @($trusted.Keys)){
        $changed=Copy44 $trusted;$changed[$key]='altered'
        Check44State (-not (Test-Stage44PhaseEvidenceBinding -State $s -TrustedEvidence $changed)) "binding mutation $key"
    }
    foreach($key in @('CURRENT_STAGE','CURRENT_DISCOVERY','CURRENT_KIND','CURRENT_PATCH','STAGE43_SEAL_COMMIT_NATIVE_RECHECK','STAGE44_PLANNED_ASSERTIONS','STAGE44_PREFLIGHT_ASSERTIONS_FAILED','STAGE44_PREFLIGHT_CI_SHA')){
        $bad=Copy44 $m;$bad[$key]='bad'
        Check44State (-not (State44 $bad).Success) "value mutation $key"
        $bad=Copy44 $m;[void]$bad.Remove($key)
        Check44State (-not (State44 $bad).Success) "missing $key"
    }
    $bad=Copy44 $m;[void]$bad.Remove('STAGE44_PREFLIGHT_RUNTIME');$bad.Add('STAGE44_PREFLIGHT_UNKNOWN','5.1.12345')
    Check44State (-not (State44 $bad).Success) 'same-cardinality substitution'
    $bad=Copy44 $m;$bad['STAGE44_PREFLIGHT_CANONICAL_RUN']=$bad['STAGE44_PREFLIGHT_DEDICATED_RUN']
    Check44State (-not (State44 $bad).Success) 'same-run reuse'
    if($n -gt 1){
        $bad=Copy44 $m;$bad['STAGE44_NATIVE_CI_SHA']=$bad['STAGE44_PREFLIGHT_CI_SHA']
        Check44State (-not (State44 $bad).Success) 'cross-phase SHA reuse'
        $bad=Copy44 $m;$bad['STAGE44_NATIVE_DEDICATED_ARTIFACT']=$bad['STAGE44_PREFLIGHT_FINALIZER_ARTIFACT']
        Check44State (-not (State44 $bad).Success) 'cross-phase artifact reuse'
    }
}

# Byte-level adversaries must fail at the strict parser, not just at map comparison.
$enc44=[Text.UTF8Encoding]::new($false)
foreach($n in 1..3){
    $m=Fixture44 $n
    [byte[]]$raw44=Encode44 $m
    $txt44=$enc44.GetString($raw44)
    $lf44=[string][char]10
    $crlf44=[string][char]13+[char]10
    $cases44=@(
        @{ Label='duplicate'; Bytes=$enc44.GetBytes($txt44+$lf44+'CURRENT_STAGE=44'); Reason='PARSER_DUPLICATE_KEY' },
        @{ Label='lowercase key'; Bytes=$enc44.GetBytes($txt44.Replace('CURRENT_STAGE=44','current_stage=44')); Reason='PARSER_MALFORMED_LINE' },
        @{ Label='space key'; Bytes=$enc44.GetBytes($txt44.Replace('CURRENT_STAGE=44','CURRENT_STAGE =44')); Reason='PARSER_MALFORMED_LINE' },
        @{ Label='interior BOM'; Bytes=$enc44.GetBytes($txt44+$lf44+[char]0xFEFF); Reason='PARSER_INTERIOR_BOM' },
        @{ Label='NUL'; Bytes=$enc44.GetBytes($txt44+[char]0); Reason='PARSER_FORBIDDEN_CONTROL' },
        @{ Label='mixed EOL'; Bytes=$enc44.GetBytes($txt44+$crlf44); Reason='PARSER_MIXED_LINE_ENDINGS' },
        @{ Label='bare CR'; Bytes=$enc44.GetBytes($txt44+[char]13); Reason='PARSER_STANDALONE_CR' },
        @{ Label='invalid UTF8'; Bytes=[byte[]]($raw44+0xC0+0xAF); Reason='PARSER_INVALID_UTF8' }
    )
    foreach($case44 in $cases44){
        $state=Get-Stage44MetadataState -Bytes $case44.Bytes -RepositoryRoot $root
        Check44State (-not $state.Success -and $state.ReasonCode -ceq $case44.Reason) ("lexical "+$case44.Label+" profile "+$n)
    }
    $crlfState=Get-Stage44MetadataState -Bytes ($enc44.GetBytes($txt44.Replace($lf44,$crlf44))) -RepositoryRoot $root
    Check44State ($crlfState.Success) "CRLF control $n"
    $bomState=Get-Stage44MetadataState -Bytes ([byte[]](@(0xEF,0xBB,0xBF)+$raw44)) -RepositoryRoot $root
    Check44State ($bomState.Success) "BOM control $n"
    $trusted=New-StrictStageMetadataDictionary
    foreach($key in $m.Keys){
        if($key -cmatch '\ASTAGE44_(PREFLIGHT|NATIVE|SEAL)_' -and $key -cnotin @('STAGE44_NATIVE_ACCEPTANCE','STAGE44_SEAL_COMMIT_NATIVE_RECHECK')){$trusted.Add($key,$m[$key])}
    }
    $altered=Copy44 $m
    $altered['STAGE44_PREFLIGHT_DEDICATED_ARTIFACT_SHA256']='c'*64
    $alteredState=State44 $altered
    Check44State ($alteredState.Success -and -not (Test-Stage44PhaseEvidenceBinding -State $alteredState -TrustedEvidence $trusted)) "valid digest substitution $n"
    $altered=Copy44 $m
    $altered['STAGE44_PREFLIGHT_CI_SHA']='f'*40
    $alteredState=State44 $altered
    Check44State ($alteredState.Success -and -not (Test-Stage44PhaseEvidenceBinding -State $alteredState -TrustedEvidence $trusted)) "valid SHA substitution $n"
}

Write-Host ('STAGE44_CLASSIFIER_ASSERTIONS_PASSED='+$script:checks44)
Write-Host 'STAGE44_CLASSIFIER_ASSERTIONS_FAILED=0'
Write-Host 'STAGE44_CLASSIFIER_RESULT=PASS_SHAPE_ONLY'
