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
            SOURCE_CONTEXTS='72';ORACLE_CONTEXTS='72';CANONICAL_JOBS='18_OF_18_SUCCESS';STAGE43_ASSERTIONS='2215'
            FINALIZER_IDEMPOTENCY='PASS';CANONICAL_VERIFY='SUCCESS';CI_SHA=([string]($i+1)*40)
            DEDICATED_RUN=[string](100+$i*10);DEDICATED_JOB=[string](101+$i*10);CANONICAL_RUN=[string](100+$i*10)
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
    $bad=Copy44 $m;$bad['STAGE44_PREFLIGHT_CANONICAL_RUN']='999999'
    $badState=State44 $bad
    Check44State (-not $badState.Success -and $badState.ReasonCode -ceq 'RUN_TOPOLOGY_MISMATCH') 'split-run rejection'
    $bad=Copy44 $m;$bad['STAGE44_PREFLIGHT_CANONICAL_JOBS']='17_OF_17_SUCCESS'
    Check44State (-not (State44 $bad).Success) 'stale canonical count'
    $bad=Copy44 $m;$bad['STAGE44_PREFLIGHT_FINALIZER_ARTIFACT']=$bad['STAGE44_PREFLIGHT_DEDICATED_ARTIFACT']
    Check44State (-not (State44 $bad).Success) 'same-phase artifact reuse'
    if($n -gt 1){
        $bad=Copy44 $m;$bad['STAGE44_NATIVE_CI_SHA']=$bad['STAGE44_PREFLIGHT_CI_SHA']
        Check44State (-not (State44 $bad).Success) 'cross-phase SHA reuse'
        $bad=Copy44 $m;$bad['STAGE44_NATIVE_CANONICAL_RUN']=$bad['STAGE44_PREFLIGHT_CANONICAL_RUN'];$bad['STAGE44_NATIVE_DEDICATED_RUN']=$bad['STAGE44_PREFLIGHT_DEDICATED_RUN']
        Check44State (-not (State44 $bad).Success) 'cross-phase run reuse'
        $bad=Copy44 $m;$bad['STAGE44_NATIVE_DEDICATED_JOB']=$bad['STAGE44_PREFLIGHT_DEDICATED_JOB']
        Check44State (-not (State44 $bad).Success) 'cross-phase job reuse'
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

# Predecessor-consumer gateway: synthetic shapes, not historical acceptance.
. (Join-Path $root 'src/StageMetadataState.ps1')
$control43=Get-Stage43PredecessorCompatibilityState -Bytes (Get-Stage44FrozenBytes -RepositoryRoot $root) -RepositoryRoot $root
Check44State ($control43.Success -and $control43.Profile -ceq 'SEALED_SHAPE_ONLY' -and $control43.Values.Count -eq 796) 'gateway unchanged Stage43 control'
foreach($n in 1..3){
    $m=Fixture44 $n
    $s=Get-Stage43PredecessorCompatibilityState -Bytes (Encode44 $m) -RepositoryRoot $root
    $want=@('STAGE44_PENDING_SHAPE_ONLY','STAGE44_IMPLEMENTING_SHAPE_ONLY','STAGE44_SEALED_SHAPE_ONLY')[$n-1]
    Check44State ($s.Success -and $s.Profile -ceq 'SEALED_SHAPE_ONLY' -and $s.Stage44Profile -ceq $want -and $s.Values.Count -eq 796 -and $s.Values['CURRENT_STAGE'] -ceq '43' -and $s.Values['STAGE23_RUNTIME_VERIFICATION'] -ceq 'GREEN_CONFIRMED') "gateway predecessor projection $n"
    $bad=Copy44 $m;$bad['STAGE43_SEAL_COMMIT_NATIVE_RECHECK']='PENDING_NEW_SHA'
    $rejected=Get-Stage43PredecessorCompatibilityState -Bytes (Encode44 $bad) -RepositoryRoot $root
    Check44State (-not $rejected.Success -and $rejected.Profile -ceq 'REJECT_STATE') "gateway frozen mutation $n"
    $bad=Copy44 $m;$bad['CURRENT_STAGE']='23'
    $rejected=Get-Stage43PredecessorCompatibilityState -Bytes (Encode44 $bad) -RepositoryRoot $root
    Check44State (-not $rejected.Success -and $rejected.Profile -ceq 'REJECT_STATE') "gateway wrong-stage injection $n"
}
# Exercise the exact callable gate used by the standalone numerical entry point.
# Keep classifier and boundary assertion counters separate.
$script:boundary44=0
function Check44Boundary([byte[]]$bytes,[string]$expected,[string]$label) {
    $actual=''
    try { Assert-Stage44PreflightMetadata -Bytes $bytes -RepositoryRoot $root }
    catch { $actual=$_.Exception.Message }
    if ($actual -cne $expected) { throw ('Stage44 boundary '+$label+': '+$actual) }
    $script:boundary44++
}
[byte[]]$frozen44=Get-Stage44FrozenBytes -RepositoryRoot $root
$strict44=[Text.UTF8Encoding]::new($false,$true)
$baseText44=$strict44.GetString($frozen44)
$lf44=[string][char]10
$crlf44=[string][char]13+[char]10
$shapeError44='Stage44 preflight requires sealed Stage43 shape'
$byteError44='Stage44 preflight requires frozen Stage43 metadata bytes (LF or uniform CRLF checkout)'
$activeError44='Stage44 phase-specific execution is not wired; preflight entry point refuses activated metadata'
Check44Boundary $frozen44 '' 'exact LF'
Check44Boundary ($strict44.GetBytes($baseText44.Replace($lf44,$crlf44))) '' 'uniform CRLF'
# A BOM is parser-valid but not a frozen checkout representation.
Check44Boundary ([byte[]](@(0xEF,0xBB,0xBF)+$frozen44)) $byteError44 'BOM mutation'
# A single extra blank line preserves the map but changes the frozen bytes.
Check44Boundary ($strict44.GetBytes($baseText44+$lf44)) $byteError44 'extra blank line'
Check44Boundary ($strict44.GetBytes($baseText44+$lf44+'CURRENT_STAGE=43')) $shapeError44 'duplicate pointer'
foreach($n in 1..3){
    Check44Boundary (Encode44 (Fixture44 $n)) $activeError44 "activated profile $n"
}
if($script:boundary44 -ne 8){throw ('Stage44 boundary count mismatch: '+$script:boundary44)}
Write-Host ('STAGE44_BOUNDARY_ASSERTIONS_PASSED='+$script:boundary44)
Write-Host 'STAGE44_BOUNDARY_ASSERTIONS_FAILED=0'
if($script:checks44 -ne 240){throw ('Stage44 classifier count mismatch: '+$script:checks44)}

Write-Host ('STAGE44_CLASSIFIER_ASSERTIONS_PASSED='+$script:checks44)
Write-Host 'STAGE44_CLASSIFIER_ASSERTIONS_FAILED=0'
Write-Host 'STAGE44_CLASSIFIER_RESULT=PASS_SHAPE_ONLY'

# Separate counters: preserve historical classifier and numerical assertion budgets.
$script:route44Checks=0
function Check44Route([byte[]]$bytes,[string]$expected) {
    $actual=''
    try { $actual=Get-Stage44ExecutionRoute -Bytes $bytes -RepositoryRoot $root }
    catch { $actual='REJECT' }
    if ($actual -cne $expected) { throw ('Stage44 route mismatch: '+$actual+' expected '+$expected) }
    $script:route44Checks++
}
Check44Route $frozen44 'RESEARCH_PREFLIGHT'
Check44Route ($strict44.GetBytes($baseText44.Replace($lf44,$crlf44))) 'RESEARCH_PREFLIGHT'
Check44Route ([byte[]](@(0xEF,0xBB,0xBF)+$frozen44)) 'REJECT'
Check44Route ($strict44.GetBytes($baseText44+$lf44)) 'REJECT'
Check44Route ($strict44.GetBytes($baseText44+$lf44+'CURRENT_STAGE=43')) 'REJECT'
Check44Route ([byte[]](0xC0,0xAF)) 'REJECT'
foreach($n in 1..3) {
    $m=Fixture44 $n
    Check44Route (Encode44 $m) @('IMPLEMENTATION_CANDIDATE','NATIVE_EVIDENCE_CANDIDATE','SEAL_RECHECK_CANDIDATE')[$n-1]
    $m['STAGE44_PLANNED_ASSERTIONS']='5026'
    Check44Route (Encode44 $m) 'REJECT'
}
if ($script:route44Checks -ne 12) { throw 'Stage44 route count mismatch' }
Write-Host 'STAGE44_ROUTE_ASSERTIONS_PASSED=12'
Write-Host 'STAGE44_ROUTE_ASSERTIONS_FAILED=0'
$script:pointerChecks=0
function CheckStagePointer([string]$source,[int]$expected) {
    $actual=-1
    try { $actual=Get-StrictCurrentStage -Bytes ($strict44.GetBytes($source)) } catch {}
    if ($actual -ne $expected) { throw ('Stage pointer mismatch: '+$actual+' expected '+$expected) }
    $script:pointerChecks++
}
foreach($n in @(22,23,43,44)) { CheckStagePointer ('CURRENT_STAGE='+$n) $n }
foreach($bad in @('OTHER=23','CURRENT_STAGE=abc','CURRENT_STAGE=023','CURRENT_STAGE=2147483648',('CURRENT_STAGE=22'+$lf44+'CURRENT_STAGE=44'))) {
    CheckStagePointer $bad -1
}
if ($script:pointerChecks -ne 9) { throw 'Stage pointer count mismatch' }
Write-Host 'STRICT_POINTER_ASSERTIONS_PASSED=9'
Write-Host 'STRICT_POINTER_ASSERTIONS_FAILED=0'

# Synthetic trust is for boundary QA only; never use it as CI provenance.
. (Join-Path $root 'src/Stage44TrustedExecution.ps1')
$script:trustedRouteChecks44=0
function CheckTrustedRoute44($map, $route, $trusted, [string]$expected) {
    $actual=''
    try { $actual=Assert-Stage44TrustedCandidateRoute -Bytes (Encode44 $map) -RepositoryRoot $root -ExpectedRoute $route -TrustedEvidence $trusted }
    catch { $actual='REJECT' }
    if ($actual -cne $expected) { throw ('Stage44 trusted route mismatch: '+$actual+' expected '+$expected) }
    $script:trustedRouteChecks44++
}
foreach ($n in 1..3) {
    $candidate=Fixture44 $n
    $route=@('IMPLEMENTATION_CANDIDATE','NATIVE_EVIDENCE_CANDIDATE','SEAL_RECHECK_CANDIDATE')[$n-1]
    $wrongRoute=@('NATIVE_EVIDENCE_CANDIDATE','SEAL_RECHECK_CANDIDATE','IMPLEMENTATION_CANDIDATE')[$n-1]
    $trusted=New-StrictStageMetadataDictionary
    foreach ($key in $candidate.Keys) {
        if ($key -cmatch '\ASTAGE44_(PREFLIGHT|NATIVE|SEAL)_' -and $key -cnotin @('STAGE44_NATIVE_ACCEPTANCE','STAGE44_SEAL_COMMIT_NATIVE_RECHECK')) { $trusted.Add($key,$candidate[$key]) }
    }
    CheckTrustedRoute44 $candidate $route $trusted $route
    CheckTrustedRoute44 $candidate $wrongRoute $trusted 'REJECT'
    $bad=Copy44 $trusted; [void]$bad.Remove('STAGE44_PREFLIGHT_CI_SHA')
    CheckTrustedRoute44 $candidate $route $bad 'REJECT'
    $bad=Copy44 $trusted; $bad['STAGE44_PREFLIGHT_CI_SHA']='f'*40
    CheckTrustedRoute44 $candidate $route $bad 'REJECT'
    $bad=Copy44 $trusted; $bad.Add('STAGE44_PREFLIGHT_UNKNOWN','extra')
    CheckTrustedRoute44 $candidate $route $bad 'REJECT'
    $bad=Copy44 $candidate; $bad['STAGE44_PLANNED_ASSERTIONS']='5026'
    CheckTrustedRoute44 $bad $route $trusted 'REJECT'
}
if ($script:trustedRouteChecks44 -ne 18) { throw 'Stage44 trusted route count mismatch' }
Write-Host 'STAGE44_TRUSTED_ROUTE_ASSERTIONS_PASSED=18'
Write-Host 'STAGE44_TRUSTED_ROUTE_ASSERTIONS_FAILED=0'
Write-Host 'STAGE44_TRUSTED_ROUTE_RESULT=PASS_SYNTHETIC_BINDING_ONLY'


# Runtime gate QA in an isolated real Git repository. No candidate is activated
# in the actual checkout; fixture trust is synthetic, not external CI evidence.
# Source adjudication: run 46138874657, 18/18 jobs, 20 exact-SHA artifacts;
# numerical 5027/0, classifier 240/0, boundary 8/0, route 12/0, pointer 9/0,
# synthetic binding 18/0, Stage43 2215/0, finalizer twice PASS.
# ZIP digests matched upload logs and API for five artifacts; not rehashed.
$script:runtime44Checks=0
function Invoke44TestGit([string[]]$arguments) {
    $output=@(& git -C $sandbox44 @arguments)
    if ($LASTEXITCODE -ne 0) { throw ('Fixture git failed: '+($arguments -join ' ')) }
    return ($output -join [char]10)
}
function Commit44TestMetadata([byte[]]$data,[string]$message) {
    [IO.File]::WriteAllBytes((Join-Path $sandbox44 'DEVELOPMENT_STAGE.md'),$data)
    [void](Invoke44TestGit @('add','--','DEVELOPMENT_STAGE.md'))
    [void](Invoke44TestGit @('commit','-q','-m',$message))
    return (Invoke44TestGit @('rev-parse','HEAD')).Trim()
}
function Check44Runtime([string]$head,[string]$route,$trusted,[string]$expected,[string]$label) {
    $actual=''
    try {
        $actual=Assert-Stage44TrustedExecution -RepositoryRoot $sandbox44 -ExpectedHead $head -ExpectedRoute $route -TrustedEvidence $trusted
    } catch { $actual=$_.Exception.Message }
    if ($actual -cne $expected) { throw ('Stage44 runtime '+$label+': expected '+$expected+' actual '+$actual) }
    $script:runtime44Checks++
}
$sandbox44=Join-Path ([IO.Path]::GetTempPath()) ('stage44-git-'+[Guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($sandbox44)
try {
    [void](Invoke44TestGit @('init','-q'))
    [void](Invoke44TestGit @('config','user.name','Stage44 QA'))
    [void](Invoke44TestGit @('config','user.email','stage44-qa@example.invalid'))
    [void](Invoke44TestGit @('config','core.autocrlf','false'))
    [void](Invoke44TestGit @('config','commit.gpgsign','false'))
    # Keep the frozen blob in this independent object database.
    $ancestor1=Commit44TestMetadata $frozen44 'frozen baseline'
    $ancestor2=Commit44TestMetadata ([byte[]]($frozen44+10)) 'synthetic historical native'
    $ancestor3=Commit44TestMetadata ([byte[]]($frozen44+10+10)) 'synthetic historical seal'
    $ancestors=@($ancestor1,$ancestor2,$ancestor3)
    $tree44=(Invoke44TestGit @('rev-parse','HEAD^{tree}')).Trim()
    # A separate root commit has a valid SHA but is not an ancestor.
    $unrelated44=(Invoke44TestGit @('commit-tree',$tree44,'-m','unrelated root')).Trim()
    foreach ($n in 1..3) {
        $candidate=Fixture44 $n
        $phaseNames=@('PREFLIGHT','NATIVE','SEAL')
        for ($i=0;$i -lt $n;$i++) {
            $candidate['STAGE44_'+$phaseNames[$i]+'_CI_SHA']=$ancestors[$i]
        }
        $trusted=New-StrictStageMetadataDictionary
        foreach ($key in $candidate.Keys) {
            if ($key -cmatch '\ASTAGE44_(PREFLIGHT|NATIVE|SEAL)_' -and $key -cnotin @('STAGE44_NATIVE_ACCEPTANCE','STAGE44_SEAL_COMMIT_NATIVE_RECHECK')) {
                $trusted.Add($key,$candidate[$key])
            }
        }
        $route=@('IMPLEMENTATION_CANDIDATE','NATIVE_EVIDENCE_CANDIDATE','SEAL_RECHECK_CANDIDATE')[$n-1]
        [byte[]]$clean44=Encode44 $candidate
        $candidateHead=Commit44TestMetadata $clean44 ('synthetic candidate '+$n)
        Check44Runtime $candidateHead $route $trusted $route "clean strict ancestors $n"
        Check44Runtime $ancestor1 $route $trusted 'Stage44 checkout SHA mismatch' "wrong checkout $n"
        [IO.File]::WriteAllBytes((Join-Path $sandbox44 'DEVELOPMENT_STAGE.md'),[byte[]]($clean44+10))
        Check44Runtime $candidateHead $route $trusted 'Stage44 metadata differs from checkout' "unstaged mutation $n"
        [void](Invoke44TestGit @('add','--','DEVELOPMENT_STAGE.md'))
        Check44Runtime $candidateHead $route $trusted 'Stage44 metadata differs from checkout' "staged mutation $n"
        [void](Invoke44TestGit @('reset','--hard','HEAD'))
        $badTrust=Copy44 $trusted
        $badTrust['STAGE44_PREFLIGHT_CI_SHA']=$unrelated44
        Check44Runtime $candidateHead $route $badTrust 'Stage44 trusted phase evidence binding failed' "external binding mismatch $n"
        # Match the metadata and trust map to isolate ancestry rejection.
        $badCandidate=Copy44 $candidate
        $badCandidate['STAGE44_PREFLIGHT_CI_SHA']=$unrelated44
        $badHead=Commit44TestMetadata (Encode44 $badCandidate) ('synthetic unrelated evidence '+$n)
        Check44Runtime $badHead $route $badTrust 'Stage44 evidence SHA not a strict ancestor' "unrelated existing commit $n"
    }
} finally {
    Remove-Item -LiteralPath $sandbox44 -Recurse -Force -ErrorAction Stop
}
if ($script:runtime44Checks -ne 18) { throw 'Stage44 runtime count mismatch' }
Write-Host 'STAGE44_RUNTIME_GATE_ASSERTIONS_PASSED=18'
Write-Host 'STAGE44_RUNTIME_GATE_ASSERTIONS_FAILED=0'
Write-Host 'STAGE44_RUNTIME_GATE_RESULT=PASS_SYNTHETIC_GIT_ONLY'
