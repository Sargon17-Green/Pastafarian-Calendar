Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$stageStateRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
. (Join-Path $stageStateRoot 'src/StageMetadataState.ps1')

$script:StageMetadataStateCases = 0
$script:StageMetadataStateUtf8 = [System.Text.UTF8Encoding]::new($false, $true)
$lf = [string][char]10
$cr = [string][char]13

function New-StageMetadataStateTestBytes {
    param([Parameter(Mandatory=$true)][System.Collections.IDictionary]$Map)
    $lines = New-Object 'System.Collections.Generic.List[string]'
    foreach ($key in $Map.Keys) {
        $lines.Add(([string]$key + '=' + [string]$Map[$key]))
    }
    $text = [string]::Join($script:StageMetadataStateTestLf, $lines.ToArray()) + $script:StageMetadataStateTestLf
    [byte[]]$bytes = $script:StageMetadataStateUtf8.GetBytes($text)
    return ,$bytes
}

function Remove-StageMetadataStateTestKey {
    param([System.Collections.Generic.Dictionary[string,string]]$Map,[string]$Key)
    if (-not $Map.Remove($Key)) { throw ('Fixture key missing: ' + $Key) }
}

function New-Stage43MetadataStateFixture {
    param([ValidateSet('Pending','Implementing','Sealed')][string]$Profile)

    $map = New-StrictStageMetadataDictionary
    foreach ($key in $script:StageMetadataStateBaseline.Values.Keys) {
        $map.Add($key, $script:StageMetadataStateBaseline.Values[$key])
    }

    $map['CURRENT_STAGE'] = '43'
    $map['CURRENT_DISCOVERY'] = '28'
    $lastCompletedValue = if ($Profile -eq 'Pending') { '42' } else { '43' }
    $map['LAST_COMPLETED_STAGE'] = $lastCompletedValue
    $runtimeValue = if ($Profile -eq 'Pending') { 'PENDING_NATIVE' } else { 'EVIDENCE_ONLY_CONFIRMED' }
    $nativeAcceptanceValue = if ($Profile -eq 'Pending') { 'NOT_CLAIMED' } else { 'IMPLEMENTING_SHA_ACCEPTED' }
    $sealRecheckValue = if ($Profile -eq 'Pending') { 'NOT_RUN' } elseif ($Profile -eq 'Implementing') { 'PENDING_NEW_SHA' } else { 'PASS' }

    $core = @{
        STAGE43_DISCOVERY = 'NEIGHBOR_YEAR_GATE_RESPONSE'
        STAGE43_PLANNING_STATUS = 'IMPLEMENTED_PREFLIGHT_VERIFIED'
        STAGE43_PLANNED_CONTEXTS = '2'
        STAGE43_PLANNED_CALC_DAYS = '2'
        STAGE43_PLANNED_GATES_PER_CONTEXT = '4'
        STAGE43_PLANNED_TARGET_OFFSETS = '-1,0,1'
        STAGE43_PLANNED_TARGET_DAYS = '12'
        STAGE43_PLANNED_SEALS = '10'
        STAGE43_PLANNED_ENDPOINTS = '240'
        STAGE43_PLANNED_TARGET_PAIRS = '160'
        STAGE43_PLANNED_SEAL_PAIRS = '216'
        STAGE43_PLANNED_STRUCTURAL_GUARDS = '23'
        STAGE43_PLANNED_ASSERTIONS = '2215'
        STAGE43_RUNTIME_VERIFICATION = $runtimeValue
        STAGE43_ACTIVATION = $runtimeValue
        STAGE43_NATIVE_ACCEPTANCE = $nativeAcceptanceValue
        STAGE43_SEAL_COMMIT_NATIVE_RECHECK = $sealRecheckValue
    }
    foreach ($key in $core.Keys) { $map.Add($key, [string]$core[$key]) }

    $preflight = @{
        STAGE43_PREFLIGHT_CI_RUN = '45671193548'
        STAGE43_PREFLIGHT_CI_SHA = '781f63850cef28f000d696d3b77878b5cf282804'
        STAGE43_PREFLIGHT_JOBS = '17_OF_17_SUCCESS'
        STAGE43_PREFLIGHT_RUNTIME = '5.1.26100.33822'
        STAGE43_PREFLIGHT_ASSERTIONS_PASSED = '2215'
        STAGE43_PREFLIGHT_ASSERTIONS_FAILED = '0'
        STAGE43_PREFLIGHT_ARTIFACT = '15050865689'
        STAGE43_PREFLIGHT_ARTIFACT_SHA256 = '1cdb1f2783c132131f30e809413f08bbf03c08baf9d8e4abbf25162f24b25f00'
        STAGE43_PREFLIGHT_FINALIZER_ARTIFACT = '15049662294'
        STAGE43_PREFLIGHT_STAGE42_SEAL_RECHECK = 'SEALED_RECHECK_PASS'
        STAGE43_PREFLIGHT_STAGE41_SEAL_RECHECK = 'PASS'
        STAGE43_PREFLIGHT_STAGE40_SEAL_RECHECK = 'PASS'
        STAGE43_PREFLIGHT_STAGE30_ASSERTIONS = '96'
        STAGE43_PREFLIGHT_CANONICAL_VERIFY = 'SUCCESS'
        STAGE43_PREFLIGHT_STAGE23_FINALIZER_IDEMPOTENCY = 'PASS'
        STAGE43_PREFLIGHT_STAGE23_FINALIZER_SHA256 = '0e54874d8d8412185fa9f81f75a5528c820a76bd13c5d61657857ac438e013af'
    }
    foreach ($key in $preflight.Keys) { $map.Add($key, [string]$preflight[$key]) }

    if ($Profile -ne 'Pending') {
        $native = @{
            STAGE43_NATIVE_IMPLEMENTATION_ACCEPTED = 'YES'
            STAGE43_NATIVE_CI_SHA = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
            STAGE43_NATIVE_CI_RUN = '45680000001'
            STAGE43_NATIVE_JOBS = '17_OF_17_SUCCESS'
            STAGE43_NATIVE_RUNTIME = '5.1.26100.33822'
            STAGE43_NATIVE_JOB = '139400000001'
            STAGE43_NATIVE_ASSERTIONS_PASSED = '2215'
            STAGE43_NATIVE_ASSERTIONS_FAILED = '0'
            STAGE43_NATIVE_ENDPOINTS = '240'
            STAGE43_NATIVE_TARGET_PAIRS = '160'
            STAGE43_NATIVE_SEAL_PAIRS = '216'
            STAGE43_NATIVE_STRUCTURAL_GUARDS = '23'
            STAGE43_NATIVE_ARTIFACT = '15060000001'
            STAGE43_NATIVE_ARTIFACT_SHA256 = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
            STAGE43_NATIVE_STAGE42_SEAL_RECHECK = 'SEALED_RECHECK_PASS'
            STAGE43_NATIVE_STAGE41_SEAL_RECHECK = 'PASS'
            STAGE43_NATIVE_STAGE40_SEAL_RECHECK = 'PASS'
            STAGE43_NATIVE_STAGE30_ASSERTIONS = '96'
            STAGE43_NATIVE_STAGE23_FINALIZER_IDEMPOTENCY = 'PASS'
            STAGE43_NATIVE_STAGE23_FINALIZER_SHA256 = 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
            STAGE43_NATIVE_STAGE23_FINALIZER_ARTIFACT = '15060000002'
            STAGE43_NATIVE_VERIFY = 'SUCCESS'
        }
        foreach ($key in $native.Keys) { $map.Add($key, [string]$native[$key]) }
    }

    if ($Profile -eq 'Sealed') {
        $seal = @{
            STAGE43_SEAL_CI_RUN = '45680000002'
            STAGE43_SEAL_CI_SHA = 'dddddddddddddddddddddddddddddddddddddddd'
            STAGE43_SEAL_CI_JOBS = '17_OF_17_SUCCESS'
            STAGE43_SEAL_CI_STAGE43_ASSERTIONS = '2215'
            STAGE43_SEAL_CI_STAGE42_ASSERTIONS = '1657'
            STAGE43_SEAL_CI_STAGE41_ASSERTIONS = '481'
            STAGE43_SEAL_CI_STAGE40_ASSERTIONS = '425'
            STAGE43_SEAL_CI_STAGE30_ASSERTIONS = '96'
            STAGE43_SEAL_CI_ARTIFACT = '15060000003'
            STAGE43_SEAL_CI_FINALIZER_ARTIFACT = '15060000004'
            STAGE43_SEAL_CI_FINALIZER_SHA256 = 'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee'
            STAGE43_SEAL_CI_FINALIZER_IDEMPOTENCY = 'PASS'
            STAGE43_SEAL_CI_VERIFY = 'SUCCESS'
        }
        foreach ($key in $seal.Keys) { $map.Add($key, [string]$seal[$key]) }
    }
    return ,$map
}

function Assert-StageMetadataStateProfile {
    param([string]$Name,[byte[]]$Bytes,[string]$ExpectedProfile)
    $actual = Get-StageMetadataState -Bytes $Bytes -RepositoryRoot $stageStateRoot
    if (-not $actual.Success -or $actual.Profile -cne $ExpectedProfile -or
        $actual.SchemaVersion -ne 1 -or $actual.SchemaId -cne 'STAGE43_TRANSITION_SCHEMA_V1') {
        throw ($Name + ': expected ' + $ExpectedProfile + ', observed ' + $actual.Success + '/' + $actual.Profile + '/' + $actual.ReasonCode + '/' + $actual.Detail)
    }
    $script:StageMetadataStateCases++
    Write-Output ('CASE=' + $Name + ';STATUS=PASS;PROFILE=' + $ExpectedProfile + ';CLASSIFIER_ONLY=YES')
}

function Assert-StageMetadataStateReject {
    param([string]$Name,[byte[]]$Bytes,[string]$ExpectedReason = $null)
    $actual = Get-StageMetadataState -Bytes $Bytes -RepositoryRoot $stageStateRoot
    if ($actual.Success -or $actual.Profile -cne 'REJECT_STATE') {
        throw ($Name + ': expected reject, observed ' + $actual.Success + '/' + $actual.Profile + '/' + $actual.ReasonCode)
    }
    if ($null -ne $ExpectedReason -and $actual.ReasonCode -cne $ExpectedReason) {
        throw ($Name + ': expected reason ' + $ExpectedReason + ', observed ' + $actual.ReasonCode)
    }
    $script:StageMetadataStateCases++
    Write-Output ('CASE=' + $Name + ';STATUS=PASS;REJECT=' + $actual.ReasonCode)
}

$script:StageMetadataStateTestLf = [string][char]10
$script:StageMetadataStateBaselineBytes = Get-FrozenStage42BlobBytes -RepositoryRoot $stageStateRoot
$script:StageMetadataStateBaseline = ConvertFrom-StrictStageMetadataBytes -Bytes $script:StageMetadataStateBaselineBytes -RequiredKeys @()
if (-not $script:StageMetadataStateBaseline.Success -or $script:StageMetadataStateBaseline.Values.Count -ne 728) {
    throw 'StageMetadataState test baseline is not the pinned 728-key Stage42 blob'
}

[byte[]]$liveBytes = [System.IO.File]::ReadAllBytes((Join-Path $stageStateRoot 'DEVELOPMENT_STAGE.md'))
$liveState = Get-StageMetadataState -Bytes $liveBytes -RepositoryRoot $stageStateRoot
if (-not $liveState.Success -or @('RESEARCH_ONLY','PENDING_SHAPE_ONLY','IMPLEMENTING_SHA_SHAPE_ONLY','SEALED_SHAPE_ONLY') -cnotcontains $liveState.Profile) {
    throw ('Live metadata has no recognized Stage42/43 profile: ' + $liveState.ReasonCode)
}
$script:StageMetadataStateCases++
Write-Output ('CASE=L00-live-current-state;STATUS=PASS;PROFILE=' + $liveState.Profile)
Assert-StageMetadataStateProfile -Name 'P00-frozen-stage42' -Bytes $script:StageMetadataStateBaselineBytes -ExpectedProfile 'RESEARCH_ONLY'

$pendingMap = New-Stage43MetadataStateFixture -Profile 'Pending'
[byte[]]$pendingBytes = New-StageMetadataStateTestBytes -Map $pendingMap
Assert-StageMetadataStateProfile -Name 'P01-pending-shape-only' -Bytes $pendingBytes -ExpectedProfile 'PENDING_SHAPE_ONLY'

$implementingMap = New-Stage43MetadataStateFixture -Profile 'Implementing'
[byte[]]$implementingBytes = New-StageMetadataStateTestBytes -Map $implementingMap
Assert-StageMetadataStateProfile -Name 'P02-implementing-sha-evidence-shape-only' -Bytes $implementingBytes -ExpectedProfile 'IMPLEMENTING_SHA_SHAPE_ONLY'

$sealedMap = New-Stage43MetadataStateFixture -Profile 'Sealed'
[byte[]]$sealedBytes = New-StageMetadataStateTestBytes -Map $sealedMap
Assert-StageMetadataStateProfile -Name 'P03-seal-rechecked-shape-only' -Bytes $sealedBytes -ExpectedProfile 'SEALED_SHAPE_ONLY'

$legacyLf = [string][char]10
$legacyText = 'TOTAL_STAGES=55' + $legacyLf + 'CURRENT_STAGE=23' + $legacyLf + 'CURRENT_KIND=PATCH' + $legacyLf + 'CURRENT_DISCOVERY=12' + $legacyLf + 'LAST_COMPLETED_STAGE=22' + $legacyLf
[byte[]]$legacyBytes = $script:StageMetadataStateUtf8.GetBytes($legacyText)
$legacyState = Get-StageMetadataState -Bytes $legacyBytes -RepositoryRoot $stageStateRoot
if (-not $legacyState.Success -or $legacyState.Profile -cne 'LEGACY_UNCLASSIFIED') { throw 'Legacy pre-Stage42 metadata was not preserved as legacy-unclassified' }
$script:StageMetadataStateCases++
Write-Output 'CASE=L01-legacy-stage;STATUS=PASS;PROFILE=LEGACY_UNCLASSIFIED'

$crlfText = $script:StageMetadataStateUtf8.GetString($script:StageMetadataStateBaselineBytes).Replace($lf, $cr + $lf)
[byte[]]$crlfBytes = $script:StageMetadataStateUtf8.GetBytes($crlfText)
[byte[]]$bomBytes = [byte[]](0xEF,0xBB,0xBF) + $crlfBytes
Assert-StageMetadataStateProfile -Name 'P04-frozen-stage42-bom-crlf' -Bytes $bomBytes -ExpectedProfile 'RESEARCH_ONLY'

$bad = New-Stage43MetadataStateFixture -Profile 'Pending'
$bad['STAGE43_ACTIVATION_CI_RUN'] = '1'
Assert-StageMetadataStateReject -Name 'N01-unknown-stage43-key' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'UNKNOWN_STAGE43_KEY'

$bad = New-Stage43MetadataStateFixture -Profile 'Pending'
$bad['UNAUTHORIZED_EXTRA_KEY'] = '1'
Assert-StageMetadataStateReject -Name 'N02-unknown-non-stage43-key' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'UNAUTHORIZED_EXTRA_KEY'

$bad = New-Stage43MetadataStateFixture -Profile 'Pending'
$bad['STAGE42_NATIVE_CI_SHA'] = '0000000000000000000000000000000000000000'
Assert-StageMetadataStateReject -Name 'N03-stage42-provenance-altered' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'BASELINE_VALUE_MISMATCH'

$bad = New-Stage43MetadataStateFixture -Profile 'Pending'
$bad['CURRENT_DISCOVERY'] = '27'
Assert-StageMetadataStateReject -Name 'N04-wrong-discovery-pointer' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'INVALID_STAGE43_POINTERS'

$bad = New-Stage43MetadataStateFixture -Profile 'Pending'
$bad['LAST_COMPLETED_STAGE'] = '43'
Assert-StageMetadataStateReject -Name 'N05-premature-last-completed' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'INCOMPLETE_NATIVE_EVIDENCE'

$bad = New-Stage43MetadataStateFixture -Profile 'Pending'
Remove-StageMetadataStateTestKey -Map $bad -Key 'STAGE43_PLANNED_ASSERTIONS'
Assert-StageMetadataStateReject -Name 'N06-missing-core-key' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'STAGE43_CORE_KEY_MISSING'

$bad = New-Stage43MetadataStateFixture -Profile 'Pending'
$bad['STAGE43_PLANNED_ASSERTIONS'] = '2214'
Assert-StageMetadataStateReject -Name 'N07-wrong-planned-assertions' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'STAGE43_PLAN_INVALID_VALUE'

$bad = New-Stage43MetadataStateFixture -Profile 'Pending'
Remove-StageMetadataStateTestKey -Map $bad -Key 'STAGE43_PREFLIGHT_ARTIFACT_SHA256'
Assert-StageMetadataStateReject -Name 'N08-partial-preflight-evidence' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'PARTIAL_PREFLIGHT_EVIDENCE'

$bad = New-Stage43MetadataStateFixture -Profile 'Implementing'
Remove-StageMetadataStateTestKey -Map $bad -Key 'STAGE43_NATIVE_ARTIFACT_SHA256'
Assert-StageMetadataStateReject -Name 'N09-partial-native-evidence' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'INCOMPLETE_NATIVE_EVIDENCE'

$bad = New-Stage43MetadataStateFixture -Profile 'Implementing'
$bad['STAGE43_NATIVE_CI_SHA'] = 'not-a-sha'
Assert-StageMetadataStateReject -Name 'N10-invalid-native-sha' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'NATIVE_INVALID_FORMAT'

$bad = New-Stage43MetadataStateFixture -Profile 'Implementing'
$bad['STAGE43_SEAL_COMMIT_NATIVE_RECHECK'] = 'PASS'
Assert-StageMetadataStateReject -Name 'N11-seal-pass-without-seal-run' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'SEAL_STATUS_MISMATCH'

$bad = New-Stage43MetadataStateFixture -Profile 'Sealed'
Remove-StageMetadataStateTestKey -Map $bad -Key 'STAGE43_SEAL_CI_ARTIFACT'
Assert-StageMetadataStateReject -Name 'N12-partial-seal-evidence' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'PARTIAL_SEAL_EVIDENCE'

$bad = New-Stage43MetadataStateFixture -Profile 'Pending'
$bad['CURRENT_KIND'] = 'PATCH'
Assert-StageMetadataStateReject -Name 'N13-current-kind-altered' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'BASELINE_VALUE_MISMATCH'

$bad = New-Stage43MetadataStateFixture -Profile 'Pending'
$bad['CURRENT_STAGE'] = '42'
Assert-StageMetadataStateReject -Name 'N14-stage43-keys-outside-current-stage' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'STAGE43_KEYS_OUTSIDE_STAGE43'

$bad = New-Stage43MetadataStateFixture -Profile 'Pending'
$bad['STAGE43_RUNTIME_VERIFICATION'] = 'EVIDENCE_ONLY_CONFIRMED'
Assert-StageMetadataStateReject -Name 'N15-hybrid-pending-status' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'PENDING_STATUS_MISMATCH'

$bad = New-Stage43MetadataStateFixture -Profile 'Sealed'
$bad['STAGE43_SEAL_CI_SHA'] = 'short'
Assert-StageMetadataStateReject -Name 'N16-invalid-seal-sha' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'SEAL_INVALID_FORMAT'

$bad = New-Stage43MetadataStateFixture -Profile 'Pending'
$bad['STAGE43_PLANNED_TARGET_OFFSETS'] = '-1,0,1,2'
Assert-StageMetadataStateReject -Name 'N17-open-target-offset-list' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'STAGE43_PLAN_INVALID_VALUE'

$bad = New-Stage43MetadataStateFixture -Profile 'Pending'
$bad['STAGE43_RUNTIME_VERIFICATION'] = 'PENDING_NATIVE'
$bad['STAGE43_ACTIVATION'] = 'EVIDENCE_ONLY_CONFIRMED'
Assert-StageMetadataStateReject -Name 'N18-mixed-activation-runtime' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'PENDING_STATUS_MISMATCH'

$bad = New-Stage43MetadataStateFixture -Profile 'Pending'
$bad['CURRENT_STAGE'] = '44'
Assert-StageMetadataStateReject -Name 'N19-unknown-stage-pointer' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'STAGE43_KEYS_OUTSIDE_STAGE43'

[byte[]]$duplicateBytes = $script:StageMetadataStateUtf8.GetBytes($script:StageMetadataStateUtf8.GetString($pendingBytes) + 'STAGE43_RUNTIME_VERIFICATION=PENDING_NATIVE' + $lf)
Assert-StageMetadataStateReject -Name 'N20-duplicate-identical-key' -Bytes $duplicateBytes -ExpectedReason 'PARSER_DUPLICATE_KEY'

[byte[]]$badUtf8 = [byte[]](0xFF,0x0A)
Assert-StageMetadataStateReject -Name 'N21-malformed-utf8' -Bytes $badUtf8 -ExpectedReason 'PARSER_INVALID_UTF8'

$researchPlus43Text = $script:StageMetadataStateUtf8.GetString($script:StageMetadataStateBaselineBytes) + 'STAGE43_RUNTIME_VERIFICATION=PENDING_NATIVE' + $lf
[byte[]]$researchPlus43 = $script:StageMetadataStateUtf8.GetBytes($researchPlus43Text)
Assert-StageMetadataStateReject -Name 'N22-stage43-key-appended-to-research' -Bytes $researchPlus43 -ExpectedReason 'STAGE43_KEYS_OUTSIDE_STAGE43'

$bad = New-Stage43MetadataStateFixture -Profile 'Sealed'
$bad['STAGE43_NATIVE_STAGE42_SEAL_RECHECK'] = 'NOT_RUN'
Assert-StageMetadataStateReject -Name 'N23-native-predecessor-recheck-missing' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'NATIVE_INVALID_VALUE'

$bad = New-Stage43MetadataStateFixture -Profile 'Sealed'
$bad['STAGE43_SEAL_CI_FINALIZER_IDEMPOTENCY'] = 'PASS_ONCE'
Assert-StageMetadataStateReject -Name 'N24-finalizer-idempotency-not-pass' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'SEAL_INVALID_VALUE'

$preflightFixtureKeys = @(
    'STAGE43_PREFLIGHT_CI_RUN','STAGE43_PREFLIGHT_CI_SHA','STAGE43_PREFLIGHT_JOBS','STAGE43_PREFLIGHT_RUNTIME',
    'STAGE43_PREFLIGHT_ASSERTIONS_PASSED','STAGE43_PREFLIGHT_ASSERTIONS_FAILED','STAGE43_PREFLIGHT_ARTIFACT',
    'STAGE43_PREFLIGHT_ARTIFACT_SHA256','STAGE43_PREFLIGHT_FINALIZER_ARTIFACT','STAGE43_PREFLIGHT_STAGE42_SEAL_RECHECK',
    'STAGE43_PREFLIGHT_STAGE41_SEAL_RECHECK','STAGE43_PREFLIGHT_STAGE40_SEAL_RECHECK','STAGE43_PREFLIGHT_STAGE30_ASSERTIONS',
    'STAGE43_PREFLIGHT_CANONICAL_VERIFY','STAGE43_PREFLIGHT_STAGE23_FINALIZER_IDEMPOTENCY','STAGE43_PREFLIGHT_STAGE23_FINALIZER_SHA256'
)
$bad = New-Stage43MetadataStateFixture -Profile 'Pending'
foreach ($key in $preflightFixtureKeys) { Remove-StageMetadataStateTestKey -Map $bad -Key $key }
Assert-StageMetadataStateReject -Name 'N25-missing-complete-preflight-ledger' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'INCOMPLETE_PREFLIGHT_EVIDENCE'

$bad = New-Stage43MetadataStateFixture -Profile 'Implementing'
$bad['STAGE43_NATIVE_CI_SHA'] = $bad['STAGE43_PREFLIGHT_CI_SHA']
Assert-StageMetadataStateReject -Name 'N26-native-sha-reuses-preflight-sha' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'NATIVE_NOT_DISTINCT_FROM_PREFLIGHT'

$bad = New-Stage43MetadataStateFixture -Profile 'Implementing'
$bad['STAGE43_NATIVE_CI_RUN'] = $bad['STAGE43_PREFLIGHT_CI_RUN']
Assert-StageMetadataStateReject -Name 'N27-native-run-reuses-preflight-run' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'NATIVE_NOT_DISTINCT_FROM_PREFLIGHT'

$bad = New-Stage43MetadataStateFixture -Profile 'Sealed'
$bad['STAGE43_SEAL_CI_SHA'] = $bad['STAGE43_NATIVE_CI_SHA']
Assert-StageMetadataStateReject -Name 'N28-seal-sha-reuses-native-sha' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'SEAL_NOT_DISTINCT_FROM_PRIOR_SHA'

$bad = New-Stage43MetadataStateFixture -Profile 'Sealed'
$bad['STAGE43_SEAL_CI_RUN'] = $bad['STAGE43_NATIVE_CI_RUN']
Assert-StageMetadataStateReject -Name 'N29-seal-run-reuses-native-run' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'SEAL_NOT_DISTINCT_FROM_PRIOR_SHA'

$bad = New-Stage43MetadataStateFixture -Profile 'Sealed'
$bad['STAGE43_SEAL_CI_SHA'] = $bad['STAGE43_PREFLIGHT_CI_SHA']
Assert-StageMetadataStateReject -Name 'N30-seal-sha-reuses-preflight-sha' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'SEAL_NOT_DISTINCT_FROM_PRIOR_SHA'

$bad = New-Stage43MetadataStateFixture -Profile 'Sealed'
$bad['STAGE43_SEAL_CI_RUN'] = $bad['STAGE43_PREFLIGHT_CI_RUN']
Assert-StageMetadataStateReject -Name 'N31-seal-run-reuses-preflight-run' -Bytes (New-StageMetadataStateTestBytes -Map $bad) -ExpectedReason 'SEAL_NOT_DISTINCT_FROM_PRIOR_SHA'

if ($script:StageMetadataStateCases -ne 38)
    throw ('StageMetadataState case count mismatch: ' + $script:StageMetadataStateCases)
}
Write-Output ('STAGE_METADATA_STATE_CASES_PASSED=' + $script:StageMetadataStateCases)
Write-Output 'STAGE_METADATA_STATE_RESULT=PASS'
Write-Output 'STAGE43_ACCEPTANCE=NOT_CLAIMED_BY_SHAPE_TESTS'
