Set-StrictMode -Version Latest
# Read-only frozen Stage42 baseline reader/comparator. Never writes repository files.
# The versioned Stage43 state classifier may use this reader to verify immutable predecessor provenance; it does not activate Stage43 or create a seal.
. (Join-Path $PSScriptRoot 'StrictUtf8StageMetadata.ps1')

$script:FrozenStage42Blob = 'a3f53b67e4445bdc835179cd484fe27b3e2648f7'

function Get-FrozenStage42BlobBytes {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$RepositoryRoot)

    if (-not [System.IO.Directory]::Exists($RepositoryRoot) -or $RepositoryRoot.Contains('"')) {
        throw 'INVALID_REPOSITORY_ROOT'
    }
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = 'git'
    $psi.Arguments = '-C "' + $RepositoryRoot + '" cat-file blob ' + $script:FrozenStage42Blob
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $proc = [System.Diagnostics.Process]::new()
    $proc.StartInfo = $psi
    $buffer = [System.IO.MemoryStream]::new()
    try {
        if (-not $proc.Start()) { throw 'GIT_START_FAILED' }
        # Binary stdout: never pipe the UTF-8 Git blob through PowerShell text decoding.
        $proc.StandardOutput.BaseStream.CopyTo($buffer)
        $stderr = $proc.StandardError.ReadToEnd()
        $proc.WaitForExit()
        if ($proc.ExitCode -ne 0) { throw ('GIT_CAT_FILE_FAILED: ' + $stderr) }
        [byte[]]$result = $buffer.ToArray()
        return ,$result
    } finally {
        $buffer.Dispose()
        $proc.Dispose()
    }
}

function New-FrozenStage42ComparisonResult {
    param(
        [bool]$Success,
        [string]$ReasonCode,
        [string]$Key = $null,
        [string]$ParsedReason = $null
    )
    return [pscustomobject]@{
        Success = $Success
        ReasonCode = $ReasonCode
        Key = $Key
        ParsedReason = $ParsedReason
        PinnedGitBlob = $script:FrozenStage42Blob
    }
}

function Test-FrozenStage42MetadataBytes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][AllowNull()][AllowEmptyCollection()][byte[]]$CandidateBytes,
        [Parameter(Mandatory=$true)][AllowNull()][AllowEmptyString()][string]$RepositoryRoot
    )
    if ($null -eq $CandidateBytes) {
        return New-FrozenStage42ComparisonResult -Success $false -ReasonCode 'INVALID_INPUT'
    }

    try {
        [byte[]]$expectedBytes = Get-FrozenStage42BlobBytes -RepositoryRoot $RepositoryRoot
    } catch {
        return New-FrozenStage42ComparisonResult -Success $false -ReasonCode 'BASELINE_UNAVAILABLE'
    }
    $required = @('TOTAL_STAGES', 'CURRENT_STAGE', 'CURRENT_DISCOVERY',
        'LAST_COMPLETED_STAGE', 'STAGE42_RUNTIME_VERIFICATION', 'NATURAL_LANGUAGE')
    try {
        $frozen = ConvertFrom-StrictStageMetadataBytes -Bytes $expectedBytes -RequiredKeys $required
        if (-not $frozen.Success -or $frozen.Values.Count -ne 728) {
            return New-FrozenStage42ComparisonResult -Success $false -ReasonCode 'BASELINE_INVALID'
        }
        if ($frozen.Values['TOTAL_STAGES'] -cne '55' -or
            $frozen.Values['CURRENT_STAGE'] -cne '42' -or
            $frozen.Values['CURRENT_DISCOVERY'] -cne '27' -or
            $frozen.Values['LAST_COMPLETED_STAGE'] -cne '42' -or
            $frozen.Values['STAGE42_RUNTIME_VERIFICATION'] -cne 'EVIDENCE_ONLY_CONFIRMED') {
            return New-FrozenStage42ComparisonResult -Success $false -ReasonCode 'BASELINE_INVALID'
        }
        foreach ($key in $frozen.Values.Keys) {
            if ($key.StartsWith('STAGE43_', [System.StringComparison]::Ordinal)) {
                return New-FrozenStage42ComparisonResult -Success $false -ReasonCode 'BASELINE_INVALID'
            }
        }
    } catch {
        return New-FrozenStage42ComparisonResult -Success $false -ReasonCode 'BASELINE_INVALID'
    }

    try {
        # A parser must not be able to mutate the caller's original candidate array.
        [byte[]]$candidateSnapshot = [byte[]]$CandidateBytes.Clone()
        $candidate = ConvertFrom-StrictStageMetadataBytes -Bytes $candidateSnapshot -RequiredKeys @()
    } catch {
        return New-FrozenStage42ComparisonResult -Success $false -ReasonCode 'CANDIDATE_LEXICAL_INVALID' -ParsedReason 'PARSER_EXCEPTION'
    }
    if (-not $candidate.Success) {
        return New-FrozenStage42ComparisonResult -Success $false -ReasonCode 'CANDIDATE_LEXICAL_INVALID' -ParsedReason $candidate.ReasonCode
    }
    if ($candidate.Values.Count -ne $frozen.Values.Count) {
        return New-FrozenStage42ComparisonResult -Success $false -ReasonCode 'FROZEN_MAP_MISMATCH'
    }
    foreach ($key in $frozen.Values.Keys) {
        if (-not $candidate.Values.ContainsKey($key)) {
            return New-FrozenStage42ComparisonResult -Success $false -ReasonCode 'FROZEN_MAP_MISMATCH' -Key $key
        }
        if (-not [string]::Equals($candidate.Values[$key], $frozen.Values[$key], [System.StringComparison]::Ordinal)) {
            return New-FrozenStage42ComparisonResult -Success $false -ReasonCode 'FROZEN_MAP_MISMATCH' -Key $key
        }
    }
    return New-FrozenStage42ComparisonResult -Success $true -ReasonCode 'OK'
}
