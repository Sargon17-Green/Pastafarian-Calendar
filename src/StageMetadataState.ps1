Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'FrozenStage42MetadataComparator.ps1')
. (Join-Path $PSScriptRoot 'Stage44MetadataState.ps1')

$script:StageMetadataSchemaVersion = 1
$script:StageMetadataSchemaId = 'STAGE43_TRANSITION_SCHEMA_V1'
$script:StageMetadataFrozenStage42Blob = 'a3f53b67e4445bdc835179cd484fe27b3e2648f7'
$script:StageMetadataBaselineCacheRoot = $null
$script:StageMetadataBaselineCache = $null

$script:Stage43CoreKeys = @(
    'STAGE43_DISCOVERY',
    'STAGE43_PLANNING_STATUS',
    'STAGE43_PLANNED_CONTEXTS',
    'STAGE43_PLANNED_CALC_DAYS',
    'STAGE43_PLANNED_GATES_PER_CONTEXT',
    'STAGE43_PLANNED_TARGET_OFFSETS',
    'STAGE43_PLANNED_TARGET_DAYS',
    'STAGE43_PLANNED_SEALS',
    'STAGE43_PLANNED_ENDPOINTS',
    'STAGE43_PLANNED_TARGET_PAIRS',
    'STAGE43_PLANNED_SEAL_PAIRS',
    'STAGE43_PLANNED_STRUCTURAL_GUARDS',
    'STAGE43_PLANNED_ASSERTIONS',
    'STAGE43_RUNTIME_VERIFICATION',
    'STAGE43_ACTIVATION',
    'STAGE43_NATIVE_ACCEPTANCE',
    'STAGE43_SEAL_COMMIT_NATIVE_RECHECK'
)

$script:Stage43PreflightKeys = @(
    'STAGE43_PREFLIGHT_CI_RUN',
    'STAGE43_PREFLIGHT_CI_SHA',
    'STAGE43_PREFLIGHT_JOBS',
    'STAGE43_PREFLIGHT_RUNTIME',
    'STAGE43_PREFLIGHT_ASSERTIONS_PASSED',
    'STAGE43_PREFLIGHT_ASSERTIONS_FAILED',
    'STAGE43_PREFLIGHT_ARTIFACT',
    'STAGE43_PREFLIGHT_ARTIFACT_SHA256',
    'STAGE43_PREFLIGHT_FINALIZER_ARTIFACT',
    'STAGE43_PREFLIGHT_STAGE42_SEAL_RECHECK',
    'STAGE43_PREFLIGHT_STAGE41_SEAL_RECHECK',
    'STAGE43_PREFLIGHT_STAGE40_SEAL_RECHECK',
    'STAGE43_PREFLIGHT_STAGE30_ASSERTIONS',
    'STAGE43_PREFLIGHT_CANONICAL_VERIFY',
    'STAGE43_PREFLIGHT_STAGE23_FINALIZER_IDEMPOTENCY',
    'STAGE43_PREFLIGHT_STAGE23_FINALIZER_SHA256'
)

$script:Stage43NativeKeys = @(
    'STAGE43_NATIVE_IMPLEMENTATION_ACCEPTED',
    'STAGE43_NATIVE_CI_SHA',
    'STAGE43_NATIVE_CI_RUN',
    'STAGE43_NATIVE_JOBS',
    'STAGE43_NATIVE_RUNTIME',
    'STAGE43_NATIVE_JOB',
    'STAGE43_NATIVE_ASSERTIONS_PASSED',
    'STAGE43_NATIVE_ASSERTIONS_FAILED',
    'STAGE43_NATIVE_ENDPOINTS',
    'STAGE43_NATIVE_TARGET_PAIRS',
    'STAGE43_NATIVE_SEAL_PAIRS',
    'STAGE43_NATIVE_STRUCTURAL_GUARDS',
    'STAGE43_NATIVE_ARTIFACT',
    'STAGE43_NATIVE_ARTIFACT_SHA256',
    'STAGE43_NATIVE_STAGE42_SEAL_RECHECK',
    'STAGE43_NATIVE_STAGE41_SEAL_RECHECK',
    'STAGE43_NATIVE_STAGE40_SEAL_RECHECK',
    'STAGE43_NATIVE_STAGE30_ASSERTIONS',
    'STAGE43_NATIVE_STAGE23_FINALIZER_IDEMPOTENCY',
    'STAGE43_NATIVE_STAGE23_FINALIZER_SHA256',
    'STAGE43_NATIVE_STAGE23_FINALIZER_ARTIFACT',
    'STAGE43_NATIVE_VERIFY'
)

$script:Stage43SealKeys = @(
    'STAGE43_SEAL_CI_RUN',
    'STAGE43_SEAL_CI_SHA',
    'STAGE43_SEAL_CI_JOBS',
    'STAGE43_SEAL_CI_STAGE43_ASSERTIONS',
    'STAGE43_SEAL_CI_STAGE42_ASSERTIONS',
    'STAGE43_SEAL_CI_STAGE41_ASSERTIONS',
    'STAGE43_SEAL_CI_STAGE40_ASSERTIONS',
    'STAGE43_SEAL_CI_STAGE30_ASSERTIONS',
    'STAGE43_SEAL_CI_ARTIFACT',
    'STAGE43_SEAL_CI_FINALIZER_ARTIFACT',
    'STAGE43_SEAL_CI_FINALIZER_SHA256',
    'STAGE43_SEAL_CI_FINALIZER_IDEMPOTENCY',
    'STAGE43_SEAL_CI_VERIFY'
)

function New-StageMetadataStateResult {
    param(
        [Parameter(Mandatory=$true)][bool]$Success,
        [Parameter(Mandatory=$true)][string]$ReasonCode,
        [Parameter(Mandatory=$true)][string]$Profile,
        [System.Collections.IDictionary]$Values = $null,
        [string]$Detail = $null
    )
    if ($null -eq $Values) { $Values = New-StrictStageMetadataDictionary }
    return [pscustomobject]@{
        Success = $Success
        ReasonCode = $ReasonCode
        Profile = $Profile
        SchemaVersion = $script:StageMetadataSchemaVersion
        SchemaId = $script:StageMetadataSchemaId
        Values = $Values
        Detail = $Detail
        FrozenStage42Blob = $script:StageMetadataFrozenStage42Blob
    }
}

function Test-Stage43FieldSet {
    param(
        [Parameter(Mandatory=$true)][System.Collections.Generic.Dictionary[string,string]]$Values,
        [Parameter(Mandatory=$true)][string[]]$Keys,
        [hashtable]$ExactValues = @{},
        [hashtable]$Patterns = @{},
        [string]$Prefix = 'EVIDENCE'
    )
    foreach ($key in $Keys) {
        if (-not $Values.ContainsKey($key)) {
            return [pscustomobject]@{ Success=$false; ReasonCode=($Prefix + '_MISSING_FIELD'); Detail=$key }
        }
    }
    foreach ($key in $ExactValues.Keys) {
        if (-not $Values.ContainsKey($key) -or $Values[$key] -cne [string]$ExactValues[$key]) {
            return [pscustomobject]@{ Success=$false; ReasonCode=($Prefix + '_INVALID_VALUE'); Detail=$key }
        }
    }
    foreach ($key in $Patterns.Keys) {
        if (-not $Values.ContainsKey($key) -or [string]$Values[$key] -cnotmatch [string]$Patterns[$key]) {
            return [pscustomobject]@{ Success=$false; ReasonCode=($Prefix + '_INVALID_FORMAT'); Detail=$key }
        }
    }
    return [pscustomobject]@{ Success=$true; ReasonCode='OK'; Detail=$null }
}

function Get-StageMetadataState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [byte[]]$Bytes,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$RepositoryRoot
    )

    $minimumKeys = @('TOTAL_STAGES','CURRENT_STAGE','CURRENT_KIND','CURRENT_DISCOVERY','LAST_COMPLETED_STAGE')
    $parsed = ConvertFrom-StrictStageMetadataBytes -Bytes $Bytes -RequiredKeys $minimumKeys
    if (-not $parsed.Success) {
        return New-StageMetadataStateResult -Success $false -ReasonCode ('PARSER_' + $parsed.ReasonCode) -Profile 'REJECT_STATE' -Detail ($parsed.Key + ':' + $parsed.LineNumber)
    }

    $values = $parsed.Values
    $stage43Keys = @($values.Keys | Where-Object { $_.StartsWith('STAGE43_', [System.StringComparison]::Ordinal) })
    $currentStage = 0
    $lastCompleted = 0
    if (-not [int]::TryParse($values['CURRENT_STAGE'], [ref]$currentStage) -or
        -not [int]::TryParse($values['LAST_COMPLETED_STAGE'], [ref]$lastCompleted)) {
        return New-StageMetadataStateResult -Success $false -ReasonCode 'INVALID_STAGE_POINTER' -Profile 'REJECT_STATE'
    }

    if ($stage43Keys.Count -eq 0) {
        if ($currentStage -lt 42) {
            return New-StageMetadataStateResult -Success $true -ReasonCode 'OK_LEGACY' -Profile 'LEGACY_UNCLASSIFIED' -Values $values
        }
        if ($currentStage -eq 42 -and
            $values['CURRENT_DISCOVERY'] -ceq '27' -and
            $lastCompleted -eq 42 -and
            $values['CURRENT_KIND'] -ceq 'DISCOVERY' -and
            $values.ContainsKey('STAGE42_RUNTIME_VERIFICATION') -and
            $values['STAGE42_RUNTIME_VERIFICATION'] -ceq 'EVIDENCE_ONLY_CONFIRMED') {
            $frozen = Test-FrozenStage42MetadataBytes -CandidateBytes $Bytes -RepositoryRoot $RepositoryRoot
            if ($frozen.Success) {
                return New-StageMetadataStateResult -Success $true -ReasonCode 'OK' -Profile 'RESEARCH_ONLY' -Values $values
            }
            return New-StageMetadataStateResult -Success $false -ReasonCode 'RESEARCH_BASELINE_MISMATCH' -Profile 'REJECT_STATE' -Detail $frozen.ReasonCode
        }
        return New-StageMetadataStateResult -Success $false -ReasonCode 'STAGE43_SCHEMA_REQUIRED' -Profile 'REJECT_STATE'
    }

    if ($currentStage -ne 43) {
        return New-StageMetadataStateResult -Success $false -ReasonCode 'STAGE43_KEYS_OUTSIDE_STAGE43' -Profile 'REJECT_STATE'
    }

    if (-not [System.IO.Directory]::Exists($RepositoryRoot)) {
        return New-StageMetadataStateResult -Success $false -ReasonCode 'BASELINE_UNAVAILABLE' -Profile 'REJECT_STATE'
    }

    $allowedStage43Keys = @($script:Stage43CoreKeys + $script:Stage43PreflightKeys + $script:Stage43NativeKeys + $script:Stage43SealKeys)
    foreach ($key in $stage43Keys) {
        if ($allowedStage43Keys -cnotcontains $key) {
            return New-StageMetadataStateResult -Success $false -ReasonCode 'UNKNOWN_STAGE43_KEY' -Profile 'REJECT_STATE' -Detail $key
        }
    }

    try {
        if ($null -eq $script:StageMetadataBaselineCache -or
            -not [string]::Equals([string]$script:StageMetadataBaselineCacheRoot, $RepositoryRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            [byte[]]$baselineBytes = Get-FrozenStage42BlobBytes -RepositoryRoot $RepositoryRoot
            $script:StageMetadataBaselineCache = ConvertFrom-StrictStageMetadataBytes -Bytes $baselineBytes -RequiredKeys @()
            $script:StageMetadataBaselineCacheRoot = $RepositoryRoot
        }
        $baseline = $script:StageMetadataBaselineCache
    } catch {
        return New-StageMetadataStateResult -Success $false -ReasonCode 'BASELINE_UNAVAILABLE' -Profile 'REJECT_STATE' -Detail $_.Exception.GetType().FullName
    }
    if (-not $baseline.Success -or $baseline.Values.Count -ne 728) {
        return New-StageMetadataStateResult -Success $false -ReasonCode 'BASELINE_INVALID' -Profile 'REJECT_STATE'
    }

    foreach ($key in $baseline.Values.Keys) {
        if (-not $values.ContainsKey($key)) {
            return New-StageMetadataStateResult -Success $false -ReasonCode 'BASELINE_KEY_MISSING' -Profile 'REJECT_STATE' -Detail $key
        }
        if ($key -ceq 'CURRENT_STAGE') {
            if ($values[$key] -cne '43') {
                return New-StageMetadataStateResult -Success $false -ReasonCode 'INVALID_STAGE43_POINTERS' -Profile 'REJECT_STATE' -Detail $key
            }
        } elseif ($key -ceq 'CURRENT_DISCOVERY') {
            if ($values[$key] -cne '28') {
                return New-StageMetadataStateResult -Success $false -ReasonCode 'INVALID_STAGE43_POINTERS' -Profile 'REJECT_STATE' -Detail $key
            }
        } elseif ($key -ceq 'LAST_COMPLETED_STAGE') {
            if ($values[$key] -cnotin @('42','43')) {
                return New-StageMetadataStateResult -Success $false -ReasonCode 'INVALID_STAGE43_POINTERS' -Profile 'REJECT_STATE' -Detail $key
            }
        } elseif (-not [string]::Equals([string]$values[$key], [string]$baseline.Values[$key], [System.StringComparison]::Ordinal)) {
            return New-StageMetadataStateResult -Success $false -ReasonCode 'BASELINE_VALUE_MISMATCH' -Profile 'REJECT_STATE' -Detail $key
        }
    }

    if ($values.Count -ne ($baseline.Values.Count + $stage43Keys.Count)) {
        return New-StageMetadataStateResult -Success $false -ReasonCode 'UNAUTHORIZED_EXTRA_KEY' -Profile 'REJECT_STATE'
    }

    foreach ($key in $script:Stage43CoreKeys) {
        if (-not $values.ContainsKey($key)) {
            return New-StageMetadataStateResult -Success $false -ReasonCode 'STAGE43_CORE_KEY_MISSING' -Profile 'REJECT_STATE' -Detail $key
        }
    }

    $planExact = @{
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
    }
    $planCheck = Test-Stage43FieldSet -Values $values -Keys $script:Stage43CoreKeys -ExactValues $planExact -Prefix 'STAGE43_PLAN'
    if (-not $planCheck.Success) {
        return New-StageMetadataStateResult -Success $false -ReasonCode $planCheck.ReasonCode -Profile 'REJECT_STATE' -Detail $planCheck.Detail
    }

    $preflightCount = @($stage43Keys | Where-Object { $script:Stage43PreflightKeys -ccontains $_ }).Count
    $nativeCount = @($stage43Keys | Where-Object { $script:Stage43NativeKeys -ccontains $_ }).Count
    $sealCount = @($stage43Keys | Where-Object { $script:Stage43SealKeys -ccontains $_ }).Count

    if ($preflightCount -eq 0) {
        return New-StageMetadataStateResult -Success $false -ReasonCode 'INCOMPLETE_PREFLIGHT_EVIDENCE' -Profile 'REJECT_STATE'
    }
    if ($preflightCount -ne $script:Stage43PreflightKeys.Count) {
        return New-StageMetadataStateResult -Success $false -ReasonCode 'PARTIAL_PREFLIGHT_EVIDENCE' -Profile 'REJECT_STATE'
    }
    if ($preflightCount -gt 0) {
        $preflightExact = @{
            STAGE43_PREFLIGHT_ASSERTIONS_PASSED = '2215'
            STAGE43_PREFLIGHT_ASSERTIONS_FAILED = '0'
            STAGE43_PREFLIGHT_STAGE30_ASSERTIONS = '96'
            STAGE43_PREFLIGHT_STAGE42_SEAL_RECHECK = 'SEALED_RECHECK_PASS'
            STAGE43_PREFLIGHT_STAGE41_SEAL_RECHECK = 'PASS'
            STAGE43_PREFLIGHT_STAGE40_SEAL_RECHECK = 'PASS'
            STAGE43_PREFLIGHT_CANONICAL_VERIFY = 'SUCCESS'
            STAGE43_PREFLIGHT_STAGE23_FINALIZER_IDEMPOTENCY = 'PASS'
        }
        $preflightPatterns = @{
            STAGE43_PREFLIGHT_CI_RUN = '^[0-9]+$'
            STAGE43_PREFLIGHT_CI_SHA = '^[0-9a-fA-F]{40}$'
            STAGE43_PREFLIGHT_JOBS = '^([1-9][0-9]*)_OF_\1_SUCCESS$'
            STAGE43_PREFLIGHT_RUNTIME = '^(WINDOWS_POWERSHELL_5\.1|5\.1\.[0-9]+(\.[0-9]+)?)$'
            STAGE43_PREFLIGHT_ARTIFACT = '^[0-9]+$'
            STAGE43_PREFLIGHT_ARTIFACT_SHA256 = '^[0-9a-fA-F]{64}$'
            STAGE43_PREFLIGHT_FINALIZER_ARTIFACT = '^[0-9]+$'
            STAGE43_PREFLIGHT_STAGE23_FINALIZER_SHA256 = '^[0-9a-fA-F]{64}$'
        }
        $preflightCheck = Test-Stage43FieldSet -Values $values -Keys $script:Stage43PreflightKeys -ExactValues $preflightExact -Patterns $preflightPatterns -Prefix 'PREFLIGHT'
        if (-not $preflightCheck.Success) {
            return New-StageMetadataStateResult -Success $false -ReasonCode $preflightCheck.ReasonCode -Profile 'REJECT_STATE' -Detail $preflightCheck.Detail
        }
    }

    if ($lastCompleted -eq 42) {
        if ($nativeCount -ne 0 -or $sealCount -ne 0) {
            return New-StageMetadataStateResult -Success $false -ReasonCode 'PREMATURE_NATIVE_OR_SEAL_EVIDENCE' -Profile 'REJECT_STATE'
        }
        $pendingExact = @{
            CURRENT_KIND = 'DISCOVERY'
            CURRENT_PATCH = '14'
            STAGE43_RUNTIME_VERIFICATION = 'PENDING_NATIVE'
            STAGE43_ACTIVATION = 'PENDING_NATIVE'
            STAGE43_NATIVE_ACCEPTANCE = 'NOT_CLAIMED'
            STAGE43_SEAL_COMMIT_NATIVE_RECHECK = 'NOT_RUN'
        }
        foreach ($key in $pendingExact.Keys) {
            if (-not $values.ContainsKey($key) -or $values[$key] -cne $pendingExact[$key]) {
                return New-StageMetadataStateResult -Success $false -ReasonCode 'PENDING_STATUS_MISMATCH' -Profile 'REJECT_STATE' -Detail $key
            }
        }
        return New-StageMetadataStateResult -Success $true -ReasonCode 'OK_SHAPE_ONLY' -Profile 'PENDING_SHAPE_ONLY' -Values $values
    }

    if ($lastCompleted -ne 43) {
        return New-StageMetadataStateResult -Success $false -ReasonCode 'INVALID_LAST_COMPLETED_STAGE' -Profile 'REJECT_STATE'
    }
    if ($nativeCount -ne $script:Stage43NativeKeys.Count) {
        return New-StageMetadataStateResult -Success $false -ReasonCode 'INCOMPLETE_NATIVE_EVIDENCE' -Profile 'REJECT_STATE'
    }

    $nativeExact = @{
        STAGE43_NATIVE_IMPLEMENTATION_ACCEPTED = 'YES'
        STAGE43_NATIVE_ASSERTIONS_PASSED = '2215'
        STAGE43_NATIVE_ASSERTIONS_FAILED = '0'
        STAGE43_NATIVE_ENDPOINTS = '240'
        STAGE43_NATIVE_TARGET_PAIRS = '160'
        STAGE43_NATIVE_SEAL_PAIRS = '216'
        STAGE43_NATIVE_STRUCTURAL_GUARDS = '23'
        STAGE43_NATIVE_STAGE42_SEAL_RECHECK = 'SEALED_RECHECK_PASS'
        STAGE43_NATIVE_STAGE41_SEAL_RECHECK = 'PASS'
        STAGE43_NATIVE_STAGE40_SEAL_RECHECK = 'PASS'
        STAGE43_NATIVE_STAGE30_ASSERTIONS = '96'
        STAGE43_NATIVE_STAGE23_FINALIZER_IDEMPOTENCY = 'PASS'
        STAGE43_NATIVE_VERIFY = 'SUCCESS'
        STAGE43_RUNTIME_VERIFICATION = 'EVIDENCE_ONLY_CONFIRMED'
        STAGE43_ACTIVATION = 'EVIDENCE_ONLY_CONFIRMED'
        STAGE43_NATIVE_ACCEPTANCE = 'IMPLEMENTING_SHA_ACCEPTED'
    }
    $nativePatterns = @{
        STAGE43_NATIVE_CI_SHA = '^[0-9a-fA-F]{40}$'
        STAGE43_NATIVE_CI_RUN = '^[0-9]+$'
        STAGE43_NATIVE_JOBS = '^([1-9][0-9]*)_OF_\1_SUCCESS$'
        STAGE43_NATIVE_RUNTIME = '^5\.1\.[0-9]+(\.[0-9]+)?$'
        STAGE43_NATIVE_JOB = '^[0-9]+$'
        STAGE43_NATIVE_ARTIFACT = '^[0-9]+$'
        STAGE43_NATIVE_ARTIFACT_SHA256 = '^[0-9a-fA-F]{64}$'
        STAGE43_NATIVE_STAGE23_FINALIZER_SHA256 = '^[0-9a-fA-F]{64}$'
        STAGE43_NATIVE_STAGE23_FINALIZER_ARTIFACT = '^[0-9]+$'
    }
    $nativeCheck = Test-Stage43FieldSet -Values $values -Keys $script:Stage43NativeKeys -ExactValues $nativeExact -Patterns $nativePatterns -Prefix 'NATIVE'
    if (-not $nativeCheck.Success) {
        return New-StageMetadataStateResult -Success $false -ReasonCode $nativeCheck.ReasonCode -Profile 'REJECT_STATE' -Detail $nativeCheck.Detail
    }
    if ($values['STAGE43_NATIVE_CI_SHA'] -ieq $values['STAGE43_PREFLIGHT_CI_SHA'] -or
        $values['STAGE43_NATIVE_CI_RUN'] -ceq $values['STAGE43_PREFLIGHT_CI_RUN']) {
        return New-StageMetadataStateResult -Success $false -ReasonCode 'NATIVE_NOT_DISTINCT_FROM_PREFLIGHT' -Profile 'REJECT_STATE'
    }

    if ($sealCount -eq 0) {
        if ($values['STAGE43_SEAL_COMMIT_NATIVE_RECHECK'] -cne 'PENDING_NEW_SHA') {
            return New-StageMetadataStateResult -Success $false -ReasonCode 'SEAL_STATUS_MISMATCH' -Profile 'REJECT_STATE'
        }
        return New-StageMetadataStateResult -Success $true -ReasonCode 'OK_SHAPE_ONLY' -Profile 'IMPLEMENTING_SHA_SHAPE_ONLY' -Values $values
    }
    if ($sealCount -ne $script:Stage43SealKeys.Count) {
        return New-StageMetadataStateResult -Success $false -ReasonCode 'PARTIAL_SEAL_EVIDENCE' -Profile 'REJECT_STATE'
    }

    $sealExact = @{
        STAGE43_SEAL_CI_STAGE43_ASSERTIONS = '2215'
        STAGE43_SEAL_CI_STAGE42_ASSERTIONS = '1657'
        STAGE43_SEAL_CI_STAGE41_ASSERTIONS = '481'
        STAGE43_SEAL_CI_STAGE40_ASSERTIONS = '425'
        STAGE43_SEAL_CI_STAGE30_ASSERTIONS = '96'
        STAGE43_SEAL_CI_FINALIZER_IDEMPOTENCY = 'PASS'
        STAGE43_SEAL_CI_VERIFY = 'SUCCESS'
    }
    $sealPatterns = @{
        STAGE43_SEAL_CI_RUN = '^[0-9]+$'
        STAGE43_SEAL_CI_SHA = '^[0-9a-fA-F]{40}$'
        STAGE43_SEAL_CI_JOBS = '^([1-9][0-9]*)_OF_\1_SUCCESS$'
        STAGE43_SEAL_CI_ARTIFACT = '^[0-9]+$'
        STAGE43_SEAL_CI_FINALIZER_ARTIFACT = '^[0-9]+$'
        STAGE43_SEAL_CI_FINALIZER_SHA256 = '^[0-9a-fA-F]{64}$'
    }
    $sealCheck = Test-Stage43FieldSet -Values $values -Keys $script:Stage43SealKeys -ExactValues $sealExact -Patterns $sealPatterns -Prefix 'SEAL'
    if (-not $sealCheck.Success) {
        return New-StageMetadataStateResult -Success $false -ReasonCode $sealCheck.ReasonCode -Profile 'REJECT_STATE' -Detail $sealCheck.Detail
    }
    if ($values['STAGE43_SEAL_COMMIT_NATIVE_RECHECK'] -cne 'PASS') {
        return New-StageMetadataStateResult -Success $false -ReasonCode 'SEAL_STATUS_MISMATCH' -Profile 'REJECT_STATE'
    }
    if ($values['STAGE43_SEAL_CI_SHA'] -ieq $values['STAGE43_NATIVE_CI_SHA'] -or
        $values['STAGE43_SEAL_CI_SHA'] -ieq $values['STAGE43_PREFLIGHT_CI_SHA'] -or
        $values['STAGE43_SEAL_CI_RUN'] -ceq $values['STAGE43_NATIVE_CI_RUN'] -or
        $values['STAGE43_SEAL_CI_RUN'] -ceq $values['STAGE43_PREFLIGHT_CI_RUN']) {
        return New-StageMetadataStateResult -Success $false -ReasonCode 'SEAL_NOT_DISTINCT_FROM_PRIOR_SHA' -Profile 'REJECT_STATE'
    }
    return New-StageMetadataStateResult -Success $true -ReasonCode 'OK_SHAPE_ONLY' -Profile 'SEALED_SHAPE_ONLY' -Values $values
}

# Stage44 is classified independently; predecessor consumers see only the frozen
# Stage43 map. Shape compatibility must not be interpreted as Stage44 acceptance.
function Get-Stage43PredecessorCompatibilityState {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][AllowNull()][AllowEmptyCollection()][byte[]]$Bytes,
          [Parameter(Mandatory=$true)][string]$RepositoryRoot)

    $parsed = ConvertFrom-StrictStageMetadataBytes -Bytes $Bytes -RequiredKeys @('CURRENT_STAGE')
    if (-not $parsed.Success) {
        return Get-StageMetadataState -Bytes $Bytes -RepositoryRoot $RepositoryRoot
    }
    $has44 = $parsed.Values['CURRENT_STAGE'] -ceq '44'
    foreach ($key in $parsed.Values.Keys) {
        if ($key.StartsWith('STAGE44_', [StringComparison]::Ordinal)) { $has44 = $true; break }
    }
    if (-not $has44) {
        return Get-StageMetadataState -Bytes $Bytes -RepositoryRoot $RepositoryRoot
    }
    $next = Get-Stage44MetadataState -Bytes $Bytes -RepositoryRoot $RepositoryRoot
    if (-not $next.Success) {
        return New-StageMetadataStateResult -Success $false -ReasonCode ('STAGE44_' + $next.ReasonCode) -Profile 'REJECT_STATE'
    }
    [byte[]]$frozen43 = Get-Stage44FrozenBytes -RepositoryRoot $RepositoryRoot
    $predecessor = Get-StageMetadataState -Bytes $frozen43 -RepositoryRoot $RepositoryRoot
    if (-not $predecessor.Success -or $predecessor.Profile -cne 'SEALED_SHAPE_ONLY') {
        return New-StageMetadataStateResult -Success $false -ReasonCode 'STAGE44_INVALID_PREDECESSOR' -Profile 'REJECT_STATE'
    }
    $predecessor | Add-Member -NotePropertyName Stage44Profile -NotePropertyValue $next.Profile
    return $predecessor
}

function Assert-Stage43MetadataCompatibility {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$RepositoryRoot
    )
    $path = Join-Path $RepositoryRoot 'DEVELOPMENT_STAGE.md'
    try {
        [byte[]]$bytes = [System.IO.File]::ReadAllBytes($path)
    } catch {
        throw ('STAGE_METADATA_READ_FAILED: ' + $_.Exception.GetType().FullName)
    }
    $state = Get-Stage43PredecessorCompatibilityState -Bytes $bytes -RepositoryRoot $RepositoryRoot
    if (-not $state.Success) {
        throw ('STAGE_METADATA_STATE_REJECTED: ' + $state.ReasonCode + ':' + $state.Detail)
    }
    return $state
}
