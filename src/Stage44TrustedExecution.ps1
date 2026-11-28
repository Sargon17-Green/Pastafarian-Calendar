Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'StageMetadataState.ps1')

# Pure authorization boundary. The trusted map must come from independent
# adjudication, not candidate metadata. This function does not authenticate it.
function Assert-Stage44TrustedCandidateRoute {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][byte[]]$Bytes,
        [Parameter(Mandatory=$true)][string]$RepositoryRoot,
        [Parameter(Mandatory=$true)][ValidateSet('IMPLEMENTATION_CANDIDATE','NATIVE_EVIDENCE_CANDIDATE','SEAL_RECHECK_CANDIDATE')][string]$ExpectedRoute,
        [Parameter(Mandatory=$true)][System.Collections.Generic.Dictionary[string,string]]$TrustedEvidence
    )
    $route = Get-Stage44ExecutionRoute -Bytes $Bytes -RepositoryRoot $RepositoryRoot
    if ($route -cne $ExpectedRoute) { throw 'Stage44 candidate route mismatch' }
    $state = Get-Stage44MetadataState -Bytes $Bytes -RepositoryRoot $RepositoryRoot
    if (-not (Test-Stage44PhaseEvidenceBinding -State $state -TrustedEvidence $TrustedEvidence)) {
        throw 'Stage44 trusted phase evidence binding failed'
    }
    return $route
}

# Runtime gate: read the tracked metadata at the checkout, require exact HEAD,
# and require every already-recorded evidence SHA to be a strict ancestor.
# This neither adjudicates the historical runs nor marks a new phase accepted.
function Assert-Stage44TrustedExecution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$RepositoryRoot,
        [Parameter(Mandatory=$true)][ValidateSet('IMPLEMENTATION_CANDIDATE','NATIVE_EVIDENCE_CANDIDATE','SEAL_RECHECK_CANDIDATE')][string]$ExpectedRoute,
        [Parameter(Mandatory=$true)][ValidatePattern('\A[0-9a-f]{40}\z')][string]$ExpectedHead,
        [Parameter(Mandatory=$true)][System.Collections.Generic.Dictionary[string,string]]$TrustedEvidence
    )
    if ($PSVersionTable.PSVersion.Major -ne 5 -or $PSVersionTable.PSVersion.Minor -ne 1) {
        throw 'Stage44 candidate requires Windows PowerShell 5.1'
    }
    $head = ((& git -C $RepositoryRoot rev-parse HEAD) -join '').Trim()
    if ($LASTEXITCODE -ne 0 -or $head -cne $ExpectedHead) { throw 'Stage44 checkout SHA mismatch' }
    & git -C $RepositoryRoot diff --quiet HEAD -- DEVELOPMENT_STAGE.md
    if ($LASTEXITCODE -ne 0) { throw 'Stage44 metadata differs from checkout' }
    [byte[]]$bytes = [IO.File]::ReadAllBytes((Join-Path $RepositoryRoot 'DEVELOPMENT_STAGE.md'))
    $route = Assert-Stage44TrustedCandidateRoute -Bytes $bytes -RepositoryRoot $RepositoryRoot -ExpectedRoute $ExpectedRoute -TrustedEvidence $TrustedEvidence
    foreach ($key in @($TrustedEvidence.Keys | Where-Object { $_ -cmatch '\ASTAGE44_(PREFLIGHT|NATIVE|SEAL)_CI_SHA\z' })) {
        $prior = $TrustedEvidence[$key]
        if ($prior -cnotmatch '\A[0-9a-f]{40}\z' -or $prior -ceq $head) { throw 'Stage44 evidence SHA not a strict ancestor' }
        & git -C $RepositoryRoot merge-base --is-ancestor $prior $head
        if ($LASTEXITCODE -ne 0) { throw 'Stage44 evidence SHA not a strict ancestor' }
    }
    $after = ((& git -C $RepositoryRoot rev-parse HEAD) -join '').Trim()
    if ($LASTEXITCODE -ne 0 -or $after -cne $head) { throw 'Stage44 checkout changed during validation' }
    & git -C $RepositoryRoot diff --quiet HEAD -- DEVELOPMENT_STAGE.md
    if ($LASTEXITCODE -ne 0) { throw 'Stage44 metadata changed during validation' }
    return $route
}
