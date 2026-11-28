Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'StrictUtf8StageMetadata.ps1')

$script:Stage44TrustedEvidenceVersion = '1'
$script:Stage44TrustedEvidenceBranch = 'PowerShell+Tagalog'
$script:Stage44TrustedEvidenceFrozenBlob = '91f8dd0237903bc4db9131ba506bc398c92c3258'
$script:Stage44TrustedEvidenceJobName = 'Stage44 trusted evidence adjudication (preflight)'
$script:Stage44TrustedEvidenceManifestArtifact = 'powershell-tagalog-stage44-trusted-evidence'
$script:Stage44TrustedEvidenceManifestFile = 'stage44-trusted-evidence.txt'

$script:Stage44TrustedEvidenceRequiredJobs = @(
    'Stage31 bounded ordinal First/Step research',
    'Stage31 normative year-5000 boundary probe',
    'Stage35 bounded anisotropic nonunit cubes',
    'Stage42 Native: coupled year-gate seams under all ten seals',
    'Stage32 bounded adjacent target transitions',
    'Native Windows PowerShell 5.1 Stage29+Stage30 and regressions',
    'Stage31 bounded ordinal extension',
    'Stage39 preflight: bounded cross-context full-seal interactions',
    'Stage40 preflight: year-gate calculation crossings under six seals',
    'verify',
    'Stage36 bounded dual year-gate calculation-target cubes',
    'Stage37 Native: bounded nonunit seal response',
    'Stage38 Native preflight: all ten seals at foundation and distant contexts',
    'Stage34 bounded seal-axis cubic interaction',
    'Stage43 preflight: independent oracle at neighboring year gates',
    'Stage41 Native: coupled calculation/target year-gate seams',
    'Stage33 bounded calculation-target interaction',
    'Stage44 bounded moving-gate preflight (not activation) / stage44-preflight'
)

function Assert-Stage44EvidenceEqual {
    param(
        [AllowNull()][object]$Actual,
        [Parameter(Mandatory=$true)][string]$Expected,
        [Parameter(Mandatory=$true)][string]$Label
    )
    if ([string]$Actual -cne $Expected) {
        throw ('STAGE44_EVIDENCE_MISMATCH:' + $Label)
    }
}

function Get-Stage44UniqueLineValue {
    param(
        [Parameter(Mandatory=$true)][string]$Text,
        [Parameter(Mandatory=$true)][string]$Key
    )
    $pattern = '(?m)^' + [regex]::Escape($Key) + '=([^\r\n]*)\r?$'
    $found = [regex]::Matches($Text, $pattern)
    if ($found.Count -ne 1) {
        throw ('STAGE44_EVIDENCE_LINE_COUNT:' + $Key + ':' + $found.Count)
    }
    return $found[0].Groups[1].Value
}

function Get-Stage44TextFromBytes {
    param([Parameter(Mandatory=$true)][AllowEmptyCollection()][byte[]]$Bytes)
    $encoding = [System.Text.UTF8Encoding]::new($false, $true)
    try {
        $text = $encoding.GetString($Bytes)
    } catch {
        throw 'STAGE44_EVIDENCE_INVALID_UTF8'
    }
    if ($text.Length -gt 0 -and $text[0] -eq [char]0xFEFF) {
        $text = $text.Substring(1)
    }
    if ($text.IndexOf([char]0) -ge 0 -or $text.IndexOf([char]0xFEFF) -ge 0) {
        throw 'STAGE44_EVIDENCE_FORBIDDEN_TEXT_BYTE'
    }
    return $text
}

function ConvertFrom-Stage44EvidenceMetadataBytes {
    param(
        [Parameter(Mandatory=$true)][AllowEmptyCollection()][byte[]]$Bytes,
        [Parameter(Mandatory=$true)][string[]]$RequiredKeys
    )
    $parsed = ConvertFrom-StrictStageMetadataBytes -Bytes $Bytes -RequiredKeys $RequiredKeys
    if (-not $parsed.Success) {
        throw ('STAGE44_EVIDENCE_METADATA_REJECTED:' + $parsed.ReasonCode)
    }
    return ,$parsed.Values
}

function Read-Stage44ZipEntries {
    param([Parameter(Mandatory=$true)][AllowEmptyCollection()][byte[]]$Bytes)
    Add-Type -AssemblyName System.IO.Compression
    if ($Bytes.Length -gt 10485760) { throw 'STAGE44_EVIDENCE_ZIP_COMPRESSED_SIZE_LIMIT' }
    $memory = [System.IO.MemoryStream]::new()
    $memory.Write($Bytes, 0, $Bytes.Length)
    $memory.Position = 0
    $archive = $null
    $entries = [System.Collections.Generic.Dictionary[string,byte[]]]::new([System.StringComparer]::Ordinal)
    try {
        $archive = [System.IO.Compression.ZipArchive]::new(
            $memory,
            [System.IO.Compression.ZipArchiveMode]::Read,
            $false
        )
        if ($archive.Entries.Count -gt 64) { throw 'STAGE44_EVIDENCE_ZIP_ENTRY_LIMIT' }
        [long]$totalUncompressed = 0
        foreach ($entry in $archive.Entries) {
            $totalUncompressed += [long]$entry.Length
            if ([long]$entry.Length -gt 5242880 -or $totalUncompressed -gt 10485760) { throw 'STAGE44_EVIDENCE_ZIP_UNCOMPRESSED_SIZE_LIMIT' }
            $name = $entry.FullName.Replace('\', '/')
            if ($name.EndsWith('/')) { continue }
            if ([string]::IsNullOrWhiteSpace($name) -or
                $name.StartsWith('/') -or
                $name -match '^[A-Za-z]:' -or
                $name -match '(^|/)\.\.?(/|$)') {
                throw 'STAGE44_EVIDENCE_UNSAFE_ZIP_PATH'
            }
            if ($entries.ContainsKey($name)) {
                throw 'STAGE44_EVIDENCE_DUPLICATE_ZIP_ENTRY'
            }
            $stream = $entry.Open()
            $buffer = [System.IO.MemoryStream]::new()
            try {
                $stream.CopyTo($buffer)
                $entries.Add($name, $buffer.ToArray())
            } finally {
                $buffer.Dispose()
                $stream.Dispose()
            }
        }
    } finally {
        if ($null -ne $archive) { $archive.Dispose() }
        $memory.Dispose()
    }
    return ,$entries
}

function Assert-Stage44ExactEntrySet {
    param(
        [Parameter(Mandatory=$true)][System.Collections.IDictionary]$Entries,
        [Parameter(Mandatory=$true)][string[]]$ExpectedNames
    )
    $actualNames = @($Entries.Keys)
    if ($actualNames.Count -ne $ExpectedNames.Count) {
        throw 'STAGE44_EVIDENCE_ZIP_ENTRY_COUNT'
    }
    foreach ($name in $ExpectedNames) {
        if (@($Entries.Keys) -cnotcontains $name) {
            throw ('STAGE44_EVIDENCE_ZIP_ENTRY_MISSING:' + $name)
        }
    }
    foreach ($name in $actualNames) {
        if ($ExpectedNames -cnotcontains [string]$name) {
            throw ('STAGE44_EVIDENCE_ZIP_ENTRY_UNEXPECTED:' + $name)
        }
    }
}

function Assert-Stage44ArtifactBinding {
    param(
        [Parameter(Mandatory=$true)][object]$Artifact,
        [Parameter(Mandatory=$true)][long]$RunId,
        [Parameter(Mandatory=$true)][string]$ExpectedSha,
        [Parameter(Mandatory=$true)][string]$ExpectedBranch
    )
    if ($Artifact.expired -ne $false) { throw 'STAGE44_EVIDENCE_ARTIFACT_EXPIRED' }
    if ([long]$Artifact.workflow_run.repository_id -ne [long]$Artifact.workflow_run.head_repository_id) { throw 'STAGE44_EVIDENCE_ARTIFACT_REPOSITORY_MISMATCH' }
    if ([long]$Artifact.workflow_run.id -ne $RunId) { throw 'STAGE44_EVIDENCE_ARTIFACT_RUN_MISMATCH' }
    Assert-Stage44EvidenceEqual $Artifact.workflow_run.head_sha $ExpectedSha 'ARTIFACT_SHA'
    Assert-Stage44EvidenceEqual $Artifact.workflow_run.head_branch $ExpectedBranch 'ARTIFACT_BRANCH'
    if ([string]$Artifact.digest -cnotmatch '^sha256:[0-9a-f]{64}$') {
        throw 'STAGE44_EVIDENCE_ARTIFACT_DIGEST_FORMAT'
    }
}

function Assert-Stage44RequiredStep {
    param(
        [Parameter(Mandatory=$true)][object]$Job,
        [Parameter(Mandatory=$true)][string]$StepName
    )
    $matches = @($Job.steps | Where-Object { $_.name -ceq $StepName })
    if ($matches.Count -ne 1) {
        throw ('STAGE44_EVIDENCE_REQUIRED_STEP_COUNT:' + $StepName)
    }
    if ($matches[0].status -cne 'completed' -or $matches[0].conclusion -cne 'success') {
        throw ('STAGE44_EVIDENCE_REQUIRED_STEP_NOT_SUCCESS:' + $StepName)
    }
}

function Assert-Stage44EvidenceJobSet {
    param(
        [Parameter(Mandatory=$true)][object[]]$Jobs,
        [Parameter(Mandatory=$true)][long]$RunId,
        [switch]$CurrentRun
    )
    if ($Jobs.Count -ne 19) { throw 'STAGE44_EVIDENCE_CANONICAL_JOB_COUNT' }
    $byName = @{}
    foreach ($name in $script:Stage44TrustedEvidenceRequiredJobs) {
        $found = @($Jobs | Where-Object { $_.name -ceq $name })
        if ($found.Count -ne 1) { throw ('STAGE44_EVIDENCE_CANONICAL_JOB_MISSING_OR_DUPLICATE:' + $name) }
        if ([long]$found[0].run_id -ne $RunId) { throw ('STAGE44_EVIDENCE_JOB_RUN_MISMATCH:' + $name) }
        if ($found[0].status -cne 'completed' -or $found[0].conclusion -cne 'success') {
            throw ('STAGE44_EVIDENCE_CANONICAL_JOB_NOT_SUCCESS:' + $name)
        }
        $byName[$name] = $found[0]
    }
    $extras = @($Jobs | Where-Object { $script:Stage44TrustedEvidenceRequiredJobs -cnotcontains [string]$_.name })
    if ($extras.Count -ne 1 -or $extras[0].name -cne $script:Stage44TrustedEvidenceJobName) {
        throw 'STAGE44_EVIDENCE_UNEXPECTED_CANONICAL_JOB_SET'
    }
    if ([long]$extras[0].run_id -ne $RunId) { throw 'STAGE44_EVIDENCE_ADJUDICATOR_RUN_MISMATCH' }
    if ($CurrentRun) {
        if ($extras[0].status -cne 'in_progress' -or $null -ne $extras[0].conclusion) {
            throw 'STAGE44_EVIDENCE_CURRENT_ADJUDICATOR_STATE'
        }
    } else {
        if ($extras[0].status -cne 'completed' -or $extras[0].conclusion -cne 'success') {
            throw 'STAGE44_EVIDENCE_ADJUDICATOR_NOT_SUCCESS'
        }
    }
    $byName['evidence-adjudication'] = $extras[0]
    return $byName
}

function Get-Stage44UniqueArtifact {
    param(
        [Parameter(Mandatory=$true)][object[]]$Artifacts,
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][long]$RunId,
        [Parameter(Mandatory=$true)][string]$ExpectedSha,
        [Parameter(Mandatory=$true)][string]$ExpectedBranch
    )
    $found = @($Artifacts | Where-Object { $_.name -ceq $Name })
    if ($found.Count -ne 1) { throw ('STAGE44_EVIDENCE_ARTIFACT_COUNT:' + $Name) }
    Assert-Stage44ArtifactBinding -Artifact $found[0] -RunId $RunId -ExpectedSha $ExpectedSha -ExpectedBranch $ExpectedBranch
    return $found[0]
}

function Get-Stage44ArtifactZipBytes {
    param(
        [Parameter(Mandatory=$true)][string]$Repository,
        [Parameter(Mandatory=$true)][long]$ArtifactId,
        [Parameter(Mandatory=$true)][string]$Token
    )
    $uri = 'https://api.github.com/repos/' + $Repository + '/actions/artifacts/' + $ArtifactId + '/zip'
    $request = [System.Net.HttpWebRequest]::Create($uri)
    $request.Method = 'GET'
    $request.Headers.Add('Authorization', ('Bearer ' + $Token))
    $request.Accept = 'application/vnd.github+json'
    $request.UserAgent = 'Stage44TrustedEvidence/1'
    $request.AllowAutoRedirect = $false
    $request.Timeout = 120000
    $response = $null
    try {
        try {
            $response = [System.Net.HttpWebResponse]$request.GetResponse()
        } catch [System.Net.WebException] {
            if ($null -eq $_.Exception.Response) { throw }
            $response = [System.Net.HttpWebResponse]$_.Exception.Response
        }
        $status = [int]$response.StatusCode
        if (@(301,302,303,307,308) -contains $status) {
            $location = $response.Headers['Location']
            if ([string]::IsNullOrWhiteSpace($location)) { throw 'STAGE44_EVIDENCE_ARTIFACT_REDIRECT_MISSING' }
            $target = [Uri]$location
            if ($target.Scheme -cne 'https' -or -not [string]::IsNullOrEmpty($target.UserInfo)) {
                throw 'STAGE44_EVIDENCE_ARTIFACT_REDIRECT_UNSAFE'
            }
            $response.Close()
            $response = $null
            $downloadRequest = [System.Net.HttpWebRequest]::Create($target)
            $downloadRequest.Method = 'GET'
            $downloadRequest.UserAgent = 'Stage44TrustedEvidence/1'
            $downloadRequest.AllowAutoRedirect = $true
            $downloadRequest.Timeout = 120000
            $response = [System.Net.HttpWebResponse]$downloadRequest.GetResponse()
            $status = [int]$response.StatusCode
        }
        if ($status -ne 200) { throw ('STAGE44_EVIDENCE_ARTIFACT_HTTP_STATUS:' + $status) }
        if ($response.ContentLength -gt 10485760) { throw 'STAGE44_EVIDENCE_ARTIFACT_DOWNLOAD_SIZE_LIMIT' }
        $stream = $response.GetResponseStream()
        $memory = [System.IO.MemoryStream]::new()
        try {
            $buffer = New-Object byte[] 65536
            while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                $memory.Write($buffer, 0, $read)
                if ($memory.Length -gt 10485760) { throw 'STAGE44_EVIDENCE_ARTIFACT_DOWNLOAD_SIZE_LIMIT' }
            }
            return ,$memory.ToArray()
        } finally {
            $memory.Dispose()
            $stream.Dispose()
        }
    } finally {
        if ($null -ne $response) { $response.Close() }
    }
}

function Get-Stage44ArtifactPayload {
    param(
        [Parameter(Mandatory=$true)][object]$Artifact,
        [Parameter(Mandatory=$true)][string]$Repository,
        [Parameter(Mandatory=$true)][string]$Token,
        [Parameter(Mandatory=$true)][scriptblock]$ArtifactDownload
    )
    $bytes = & $ArtifactDownload $Repository ([long]$Artifact.id) $Token
    if ($bytes -isnot [byte[]]) { throw 'STAGE44_EVIDENCE_ARTIFACT_DOWNLOAD_TYPE' }
    if ([long]$Artifact.size_in_bytes -le 0 -or [long]$Artifact.size_in_bytes -gt 10485760) { throw 'STAGE44_EVIDENCE_ARTIFACT_SIZE_LIMIT' }
    $hash = [System.Security.Cryptography.SHA256]::Create()
    try {
        $actualDigest = [System.BitConverter]::ToString($hash.ComputeHash($bytes)).Replace('-', '').ToLowerInvariant()
    } finally {
        $hash.Dispose()
    }
    $expectedDigest = ([string]$Artifact.digest).Substring(7)
    Assert-Stage44EvidenceEqual $actualDigest $expectedDigest 'ARTIFACT_ZIP_SHA256'
    $entries = Read-Stage44ZipEntries -Bytes $bytes
    return [pscustomobject]@{
        Artifact = $Artifact
        Digest = $actualDigest
        Entries = $entries
    }
}

function Assert-Stage44ManifestMatches {
    param(
        [Parameter(Mandatory=$true)][System.Collections.IDictionary]$Actual,
        [Parameter(Mandatory=$true)][System.Collections.IDictionary]$Expected
    )
    if ($Actual.Count -ne $Expected.Count) { throw 'STAGE44_EVIDENCE_MANIFEST_KEY_COUNT' }
    foreach ($key in $Expected.Keys) {
        if (@($Actual.Keys) -cnotcontains $key) { throw ('STAGE44_EVIDENCE_MANIFEST_KEY_MISSING:' + $key) }
        Assert-Stage44EvidenceEqual $Actual[$key] ([string]$Expected[$key]) ('MANIFEST_' + $key)
    }
}

function Invoke-Stage44ApiGet {
    param(
        [Parameter(Mandatory=$true)][string]$Uri,
        [Parameter(Mandatory=$true)][string]$Token
    )
    $headers = @{
        Authorization = 'Bearer ' + $Token
        Accept = 'application/vnd.github+json'
        'X-GitHub-Api-Version' = '2022-11-28'
    }
    return Invoke-RestMethod -Method Get -Uri $Uri -Headers $headers -ErrorAction Stop
}

function Get-Stage44TrustedEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Repository,
        [Parameter(Mandatory=$true)][long]$RunId,
        [Parameter(Mandatory=$true)][string]$ExpectedSha,
        [Parameter(Mandatory=$true)][string]$ExpectedBranch,
        [Parameter(Mandatory=$true)][string]$Token,
        [Parameter(Mandatory=$true)][string]$RepositoryRoot,
        [switch]$CurrentRun,
        [scriptblock]$ApiGet = $null,
        [scriptblock]$ArtifactDownload = $null
    )
    if ($null -eq $ApiGet) {
        $ApiGet = { param($uri, $tokenValue) Invoke-Stage44ApiGet -Uri $uri -Token $tokenValue }
    }
    if ($null -eq $ArtifactDownload) {
        $ArtifactDownload = { param($repoValue, $artifactId, $tokenValue) Get-Stage44ArtifactZipBytes -Repository $repoValue -ArtifactId $artifactId -Token $tokenValue }
    }

    $base = 'https://api.github.com/repos/' + $Repository
    $run = & $ApiGet ($base + '/actions/runs/' + $RunId) $Token
    if ([long]$run.id -ne $RunId) { throw 'STAGE44_EVIDENCE_RUN_ID_MISMATCH' }
    Assert-Stage44EvidenceEqual $run.head_sha $ExpectedSha 'RUN_SHA'
    Assert-Stage44EvidenceEqual $run.head_branch $ExpectedBranch 'RUN_BRANCH'
    Assert-Stage44EvidenceEqual $run.event 'push' 'RUN_EVENT'
    Assert-Stage44EvidenceEqual $run.path '.github/workflows/canonical-names-lock.yml' 'RUN_WORKFLOW'
    if ($null -ne $run.PSObject.Properties['repository']) { Assert-Stage44EvidenceEqual $run.repository.full_name $Repository 'RUN_REPOSITORY' }
    if ($null -ne $run.PSObject.Properties['head_repository']) { Assert-Stage44EvidenceEqual $run.head_repository.full_name $Repository 'RUN_HEAD_REPOSITORY' }
    if ([int]$run.run_attempt -ne 1) { throw 'STAGE44_EVIDENCE_RUN_ATTEMPT_UNSUPPORTED' }
    if ($CurrentRun) {
        if ($run.status -cne 'in_progress' -or $null -ne $run.conclusion) {
            throw 'STAGE44_EVIDENCE_CURRENT_RUN_STATE'
        }
    } else {
        if ($run.status -cne 'completed' -or $run.conclusion -cne 'success') {
            throw 'STAGE44_EVIDENCE_COMPLETED_RUN_NOT_SUCCESS'
        }
    }

    $jobsResponse = & $ApiGet ($base + '/actions/runs/' + $RunId + '/jobs?per_page=100') $Token
    $jobs = @($jobsResponse.jobs)
    if ([int]$jobsResponse.total_count -ne $jobs.Count) { throw 'STAGE44_EVIDENCE_JOBS_PAGINATION_REQUIRED' }
    $jobSet = Assert-Stage44EvidenceJobSet -Jobs $jobs -RunId $RunId -CurrentRun:$CurrentRun

    Assert-Stage44RequiredStep -Job $jobSet['verify'] -StepName 'Verify canonical names lock'
    Assert-Stage44RequiredStep -Job $jobSet['Stage43 preflight: independent oracle at neighboring year gates'] -StepName 'Run 42-case fail-closed Stage43 metadata-state classifier regression'
    Assert-Stage44RequiredStep -Job $jobSet['Stage43 preflight: independent oracle at neighboring year gates'] -StepName 'Stage44 strict metadata classifier synthetic regression (not activation)'
    Assert-Stage44RequiredStep -Job $jobSet['Stage43 preflight: independent oracle at neighboring year gates'] -StepName 'Verify exact-SHA Windows PowerShell 5.1 Stage43 lifecycle profile and bounded oracle'
    Assert-Stage44RequiredStep -Job $jobSet['Stage43 preflight: independent oracle at neighboring year gates'] -StepName 'Require Stage43 lifecycle evidence files'
    Assert-Stage44RequiredStep -Job $jobSet['Stage43 preflight: independent oracle at neighboring year gates'] -StepName 'Retain Stage43 lifecycle regression evidence'
    Assert-Stage44RequiredStep -Job $jobSet['Stage44 bounded moving-gate preflight (not activation) / stage44-preflight'] -StepName 'Exact-SHA Stage44 bounded oracle preflight'
    Assert-Stage44RequiredStep -Job $jobSet['Stage44 bounded moving-gate preflight (not activation) / stage44-preflight'] -StepName 'Require evidence files'
    Assert-Stage44RequiredStep -Job $jobSet['Stage44 bounded moving-gate preflight (not activation) / stage44-preflight'] -StepName 'Retain Stage44 evidence'
    Assert-Stage44RequiredStep -Job $jobSet['Native Windows PowerShell 5.1 Stage29+Stage30 and regressions'] -StepName 'Verify sealed Stage 23 finalizer idempotency twice'
    Assert-Stage44RequiredStep -Job $jobSet['Native Windows PowerShell 5.1 Stage29+Stage30 and regressions'] -StepName 'Retain Stage 23 finalizer idempotency evidence'

    $artifactsResponse = & $ApiGet ($base + '/actions/runs/' + $RunId + '/artifacts?per_page=100') $Token
    $artifacts = @($artifactsResponse.artifacts)
    if ([int]$artifactsResponse.total_count -ne $artifacts.Count) { throw 'STAGE44_EVIDENCE_ARTIFACTS_PAGINATION_REQUIRED' }

    $stage44Artifact = Get-Stage44UniqueArtifact -Artifacts $artifacts -Name 'powershell-tagalog-stage44-moving-gate-preflight' -RunId $RunId -ExpectedSha $ExpectedSha -ExpectedBranch $ExpectedBranch
    $stage43Artifact = Get-Stage44UniqueArtifact -Artifacts $artifacts -Name 'powershell-tagalog-stage43-lifecycle-regression' -RunId $RunId -ExpectedSha $ExpectedSha -ExpectedBranch $ExpectedBranch
    $finalizerArtifact = Get-Stage44UniqueArtifact -Artifacts $artifacts -Name 'native-powershell-tagalog-stage23-finalizer-idempotency' -RunId $RunId -ExpectedSha $ExpectedSha -ExpectedBranch $ExpectedBranch
    $classifierArtifact = Get-Stage44UniqueArtifact -Artifacts $artifacts -Name 'powershell-tagalog-stage44-classifier-regression' -RunId $RunId -ExpectedSha $ExpectedSha -ExpectedBranch $ExpectedBranch
    $metadataStateArtifact = Get-Stage44UniqueArtifact -Artifacts $artifacts -Name 'powershell-tagalog-stage43-metadata-state-regression' -RunId $RunId -ExpectedSha $ExpectedSha -ExpectedBranch $ExpectedBranch

    $stage44Payload = Get-Stage44ArtifactPayload -Artifact $stage44Artifact -Repository $Repository -Token $Token -ArtifactDownload $ArtifactDownload
    $stage43Payload = Get-Stage44ArtifactPayload -Artifact $stage43Artifact -Repository $Repository -Token $Token -ArtifactDownload $ArtifactDownload
    $finalizerPayload = Get-Stage44ArtifactPayload -Artifact $finalizerArtifact -Repository $Repository -Token $Token -ArtifactDownload $ArtifactDownload
    $classifierPayload = Get-Stage44ArtifactPayload -Artifact $classifierArtifact -Repository $Repository -Token $Token -ArtifactDownload $ArtifactDownload
    $metadataStatePayload = Get-Stage44ArtifactPayload -Artifact $metadataStateArtifact -Repository $Repository -Token $Token -ArtifactDownload $ArtifactDownload

    Assert-Stage44ExactEntrySet -Entries $stage44Payload.Entries -ExpectedNames @('stage44-metadata.txt','stage44-transcript.txt','DEVELOPMENT_STAGE.md')
    Assert-Stage44ExactEntrySet -Entries $stage43Payload.Entries -ExpectedNames @('stage43-lifecycle-metadata.txt','stage43-lifecycle-transcript.txt','DEVELOPMENT_STAGE.md')
    Assert-Stage44ExactEntrySet -Entries $classifierPayload.Entries -ExpectedNames @('stage44-classifier-transcript.txt')
    Assert-Stage44ExactEntrySet -Entries $metadataStatePayload.Entries -ExpectedNames @('stage-metadata-state-metadata.txt','stage-metadata-state-transcript.txt','DEVELOPMENT_STAGE.md')

    $stage44MetadataKeys = @('PROJECT_ID','STAGE44_CHECKED_OUT_SHA','STAGE44_RUNTIME','STAGE43_METADATA_BLOB','STAGE44_PLANNED_ASSERTIONS','STAGE44_ACTIVATION','STAGE44_PREFLIGHT_RESULT')
    $stage44Metadata = ConvertFrom-Stage44EvidenceMetadataBytes -Bytes $stage44Payload.Entries['stage44-metadata.txt'] -RequiredKeys $stage44MetadataKeys
    Assert-Stage44EvidenceEqual $stage44Metadata['PROJECT_ID'] 'PC-BRANCH-POWERSHELL-TAGALOG' 'PROJECT_ID'
    Assert-Stage44EvidenceEqual $stage44Metadata['STAGE44_CHECKED_OUT_SHA'] $ExpectedSha 'STAGE44_METADATA_SHA'
    Assert-Stage44EvidenceEqual $stage44Metadata['STAGE43_METADATA_BLOB'] $script:Stage44TrustedEvidenceFrozenBlob 'STAGE43_FROZEN_BLOB'
    Assert-Stage44EvidenceEqual $stage44Metadata['STAGE44_PLANNED_ASSERTIONS'] '5027' 'STAGE44_PLANNED_ASSERTIONS'
    Assert-Stage44EvidenceEqual $stage44Metadata['STAGE44_ACTIVATION'] 'NOT_ACTIVATED' 'STAGE44_NOT_ACTIVATED'
    Assert-Stage44EvidenceEqual $stage44Metadata['STAGE44_PREFLIGHT_RESULT'] 'BOUNDED_ORACLE_PASS' 'STAGE44_PREFLIGHT_RESULT'
    if ([string]$stage44Metadata['STAGE44_RUNTIME'] -cnotmatch '^5\.1\.[0-9]+\.[0-9]+$') { throw 'STAGE44_EVIDENCE_RUNTIME_INVALID' }

    $stage44Text = Get-Stage44TextFromBytes -Bytes $stage44Payload.Entries['stage44-transcript.txt']
    $stage43Text = Get-Stage44TextFromBytes -Bytes $stage43Payload.Entries['stage43-lifecycle-transcript.txt']
    $classifierText = Get-Stage44TextFromBytes -Bytes $classifierPayload.Entries['stage44-classifier-transcript.txt']
    $metadataStateText = Get-Stage44TextFromBytes -Bytes $metadataStatePayload.Entries['stage-metadata-state-transcript.txt']

    $stage44Expected = [ordered]@{
        STAGE44_NUMERICAL_EXECUTION_ROUTE = 'RESEARCH_PREFLIGHT'
        STAGE44_SOURCE_CONTEXTS = '72'
        STAGE44_ORACLE_CONTEXTS = '72'
        STAGE44_ENDPOINTS = '720'
        STAGE44_RECTANGLES = '320'
        STAGE44_STRUCTURAL_GUARDS = '67'
        STAGE44_ASSERTIONS_PASSED = '5027'
        STAGE44_ASSERTIONS_FAILED = '0'
        STAGE44_PREFLIGHT = 'BOUNDED_ORACLE_PASS'
        STAGE44_ACTIVATION = 'NOT_ACTIVATED'
    }
    foreach ($key in $stage44Expected.Keys) {
        Assert-Stage44EvidenceEqual (Get-Stage44UniqueLineValue -Text $stage44Text -Key $key) $stage44Expected[$key] $key
    }

    $stage43MetadataKeys = @('PROJECT_ID','STAGE43_CHECKED_OUT_SHA','STAGE43_RUNTIME','STAGE43_PLANNED_ASSERTIONS','STAGE43_METADATA_PROFILE','STAGE43_RUNTIME_VERIFICATION','STAGE43_ACTIVATION','STAGE43_NATIVE_ACCEPTANCE','STAGE43_STAGE_SEAL','STAGE43_SEALED_STATE_REGRESSION')
    $stage43Metadata = ConvertFrom-Stage44EvidenceMetadataBytes -Bytes $stage43Payload.Entries['stage43-lifecycle-metadata.txt'] -RequiredKeys $stage43MetadataKeys
    Assert-Stage44EvidenceEqual $stage43Metadata['PROJECT_ID'] 'PC-BRANCH-POWERSHELL-TAGALOG' 'STAGE43_PROJECT_ID'
    Assert-Stage44EvidenceEqual $stage43Metadata['STAGE43_CHECKED_OUT_SHA'] $ExpectedSha 'STAGE43_METADATA_SHA'
    Assert-Stage44EvidenceEqual $stage43Metadata['STAGE43_PLANNED_ASSERTIONS'] '2215' 'STAGE43_PLANNED_ASSERTIONS'
    Assert-Stage44EvidenceEqual $stage43Metadata['STAGE43_METADATA_PROFILE'] 'SEALED_SHAPE_ONLY' 'STAGE43_PROFILE'
    Assert-Stage44EvidenceEqual $stage43Metadata['STAGE43_RUNTIME_VERIFICATION'] 'EVIDENCE_ONLY_CONFIRMED' 'STAGE43_RUNTIME_VERIFICATION'
    Assert-Stage44EvidenceEqual $stage43Metadata['STAGE43_ACTIVATION'] 'EVIDENCE_ONLY_CONFIRMED' 'STAGE43_ACTIVATION'
    Assert-Stage44EvidenceEqual $stage43Metadata['STAGE43_NATIVE_ACCEPTANCE'] 'IMPLEMENTING_SHA_ACCEPTED' 'STAGE43_NATIVE_ACCEPTANCE'
    Assert-Stage44EvidenceEqual $stage43Metadata['STAGE43_STAGE_SEAL'] 'CLAIM_RECORDED_NOT_REVALIDATED' 'STAGE43_STAGE_SEAL'
    Assert-Stage44EvidenceEqual $stage43Metadata['STAGE43_SEALED_STATE_REGRESSION'] 'PASS' 'STAGE43_SEALED_STATE_REGRESSION'
    Assert-Stage44EvidenceEqual $stage43Metadata['STAGE43_RUNTIME'] $stage44Metadata['STAGE44_RUNTIME'] 'STAGE43_STAGE44_RUNTIME'

    $stage43Expected = [ordered]@{
        STAGE43_ENDPOINTS = '240'
        STAGE43_TARGET_PAIRS = '160'
        STAGE43_SEAL_PAIRS = '216'
        STAGE43_STRUCTURAL_GUARDS = '23'
        STAGE43_ASSERTIONS_PASSED = '2215'
        STAGE43_ASSERTIONS_FAILED = '0'
        STAGE43_SEALED_STATE_REGRESSION = 'PASS'
        STAGE43_STAGE_SEAL = 'CLAIM_RECORDED_NOT_REVALIDATED'
    }
    foreach ($key in $stage43Expected.Keys) {
        Assert-Stage44EvidenceEqual (Get-Stage44UniqueLineValue -Text $stage43Text -Key $key) $stage43Expected[$key] $key
    }

    $classifierExpected = [ordered]@{
        STAGE44_BOUNDARY_ASSERTIONS_PASSED = '8'
        STAGE44_BOUNDARY_ASSERTIONS_FAILED = '0'
        STAGE44_CLASSIFIER_ASSERTIONS_PASSED = '240'
        STAGE44_CLASSIFIER_ASSERTIONS_FAILED = '0'
        STAGE44_CLASSIFIER_RESULT = 'PASS_SHAPE_ONLY'
    }
    foreach ($key in $classifierExpected.Keys) {
        Assert-Stage44EvidenceEqual (Get-Stage44UniqueLineValue -Text $classifierText -Key $key) $classifierExpected[$key] $key
    }
    $trustedCases = [int](Get-Stage44UniqueLineValue -Text $classifierText -Key 'STAGE44_TRUSTED_EVIDENCE_CASES_PASSED')
    Assert-Stage44EvidenceEqual (Get-Stage44UniqueLineValue -Text $classifierText -Key 'STAGE44_TRUSTED_EVIDENCE_CASES_FAILED') '0' 'STAGE44_TRUSTED_EVIDENCE_CASES_FAILED'
    Assert-Stage44EvidenceEqual (Get-Stage44UniqueLineValue -Text $classifierText -Key 'STAGE44_TRUSTED_EVIDENCE_RESULT') 'PASS_SYNTHETIC_GATES' 'STAGE44_TRUSTED_EVIDENCE_RESULT'
    if ($trustedCases -lt 20) { throw 'STAGE44_EVIDENCE_SYNTHETIC_CASE_COUNT' }

    $metadataStateMetadataKeys = @('PROJECT_ID','STAGE_METADATA_STATE_HEAD_SHA','STAGE_METADATA_STATE_RUNTIME','STAGE_METADATA_STATE_EXPECTED_CASES','STAGE_METADATA_STATE_REGRESSION')
    $metadataStateMetadata = ConvertFrom-Stage44EvidenceMetadataBytes -Bytes $metadataStatePayload.Entries['stage-metadata-state-metadata.txt'] -RequiredKeys $metadataStateMetadataKeys
    Assert-Stage44EvidenceEqual $metadataStateMetadata['PROJECT_ID'] 'PC-BRANCH-POWERSHELL-TAGALOG' 'METADATA_STATE_PROJECT_ID'
    Assert-Stage44EvidenceEqual $metadataStateMetadata['STAGE_METADATA_STATE_HEAD_SHA'] $ExpectedSha 'METADATA_STATE_SHA'
    Assert-Stage44EvidenceEqual $metadataStateMetadata['STAGE_METADATA_STATE_RUNTIME'] $stage44Metadata['STAGE44_RUNTIME'] 'METADATA_STATE_RUNTIME'
    Assert-Stage44EvidenceEqual $metadataStateMetadata['STAGE_METADATA_STATE_EXPECTED_CASES'] '42' 'METADATA_STATE_EXPECTED_CASES'
    Assert-Stage44EvidenceEqual $metadataStateMetadata['STAGE_METADATA_STATE_REGRESSION'] 'PASS' 'METADATA_STATE_REGRESSION'
    Assert-Stage44EvidenceEqual (Get-Stage44UniqueLineValue -Text $metadataStateText -Key 'STAGE_METADATA_STATE_CASES_PASSED') '42' 'METADATA_STATE_CASES_PASSED'
    Assert-Stage44EvidenceEqual (Get-Stage44UniqueLineValue -Text $metadataStateText -Key 'STAGE_METADATA_STATE_RESULT') 'PASS' 'METADATA_STATE_RESULT'
    Assert-Stage44EvidenceEqual (Get-Stage44UniqueLineValue -Text $metadataStateText -Key 'STAGE43_ACCEPTANCE') 'NOT_CLAIMED_BY_SHAPE_TESTS' 'STAGE43_ACCEPTANCE_NOT_CLAIMED'

    $stage44Dev = [Convert]::ToBase64String($stage44Payload.Entries['DEVELOPMENT_STAGE.md'])
    $stage43Dev = [Convert]::ToBase64String($stage43Payload.Entries['DEVELOPMENT_STAGE.md'])
    $metadataStateDev = [Convert]::ToBase64String($metadataStatePayload.Entries['DEVELOPMENT_STAGE.md'])
    Assert-Stage44EvidenceEqual $stage44Dev $stage43Dev 'STAGE43_STAGE44_METADATA_BYTES'
    Assert-Stage44EvidenceEqual $stage44Dev $metadataStateDev 'METADATA_STATE_METADATA_BYTES'

    $finalizerEntries = $finalizerPayload.Entries
    $summaryPaths = @($finalizerEntries.Keys | Where-Object { $_ -match '^Stage23-Finalize-Idempotency-[^/]+/summary\.txt$' })
    if ($summaryPaths.Count -ne 1) { throw 'STAGE44_EVIDENCE_FINALIZER_SUMMARY_COUNT' }
    $prefix = $summaryPaths[0].Substring(0, $summaryPaths[0].LastIndexOf('/') + 1)
    $finalizerNames = @(
        ($prefix + 'run1-stage-diff.txt'),
        ($prefix + 'run1-stderr.txt'),
        ($prefix + 'run1-stdout.txt'),
        ($prefix + 'run2-stage-diff.txt'),
        ($prefix + 'run2-stderr.txt'),
        ($prefix + 'run2-stdout.txt'),
        ($prefix + 'summary.txt')
    )
    Assert-Stage44ExactEntrySet -Entries $finalizerEntries -ExpectedNames $finalizerNames
    $finalizerSummaryKeys = @('TEST','PS_VERSION','BRANCH','HEAD','KNOWN_PATCH11_HEAD','SHA256_BEFORE','RUN_1_EXIT_CODE','RUN_1_ALREADY_FINALIZED','RUN_1_STDERR_LENGTH','RUN_1_SHA256_AFTER','RUN_2_EXIT_CODE','RUN_2_ALREADY_FINALIZED','RUN_2_STDERR_LENGTH','RUN_2_SHA256_AFTER','RESULT')
    $finalizerSummary = ConvertFrom-Stage44EvidenceMetadataBytes -Bytes $finalizerEntries[$summaryPaths[0]] -RequiredKeys $finalizerSummaryKeys
    Assert-Stage44EvidenceEqual $finalizerSummary['TEST'] 'STAGE23_FINALIZE_IDEMPOTENCY' 'FINALIZER_TEST'
    Assert-Stage44EvidenceEqual $finalizerSummary['BRANCH'] $ExpectedBranch 'FINALIZER_BRANCH'
    Assert-Stage44EvidenceEqual $finalizerSummary['HEAD'] $ExpectedSha 'FINALIZER_SHA'
    Assert-Stage44EvidenceEqual $finalizerSummary['KNOWN_PATCH11_HEAD'] '7e895d374962dbc57a68035eef02f76a365af440' 'FINALIZER_KNOWN_PATCH11_HEAD'
    Assert-Stage44EvidenceEqual $finalizerSummary['RUN_1_EXIT_CODE'] '0' 'FINALIZER_RUN1_EXIT'
    Assert-Stage44EvidenceEqual $finalizerSummary['RUN_2_EXIT_CODE'] '0' 'FINALIZER_RUN2_EXIT'
    Assert-Stage44EvidenceEqual $finalizerSummary['RUN_1_ALREADY_FINALIZED'] 'True' 'FINALIZER_RUN1_IDEMPOTENT'
    Assert-Stage44EvidenceEqual $finalizerSummary['RUN_2_ALREADY_FINALIZED'] 'True' 'FINALIZER_RUN2_IDEMPOTENT'
    Assert-Stage44EvidenceEqual $finalizerSummary['RUN_1_STDERR_LENGTH'] '0' 'FINALIZER_RUN1_STDERR'
    Assert-Stage44EvidenceEqual $finalizerSummary['RUN_2_STDERR_LENGTH'] '0' 'FINALIZER_RUN2_STDERR'
    Assert-Stage44EvidenceEqual $finalizerSummary['RUN_1_SHA256_AFTER'] $finalizerSummary['SHA256_BEFORE'] 'FINALIZER_RUN1_SHA'
    Assert-Stage44EvidenceEqual $finalizerSummary['RUN_2_SHA256_AFTER'] $finalizerSummary['SHA256_BEFORE'] 'FINALIZER_RUN2_SHA'
    Assert-Stage44EvidenceEqual $finalizerSummary['RESULT'] 'PASS' 'FINALIZER_RESULT'
    if ([string]$finalizerSummary['PS_VERSION'] -cnotmatch '^5\.1\.[0-9]+\.[0-9]+$') { throw 'STAGE44_EVIDENCE_FINALIZER_RUNTIME' }
    foreach ($name in @('run1-stderr.txt','run2-stderr.txt')) {
        if ($finalizerEntries[$prefix + $name].Length -ne 0) { throw ('STAGE44_EVIDENCE_FINALIZER_STDERR_FILE:' + $name) }
    }
    foreach ($name in @('run1-stage-diff.txt','run2-stage-diff.txt')) {
        if ((Get-Stage44TextFromBytes -Bytes $finalizerEntries[$prefix + $name]).Trim().Length -ne 0) {
            throw ('STAGE44_EVIDENCE_FINALIZER_STAGE_DIFF:' + $name)
        }
    }

    $gitBlob = ((& git -C $RepositoryRoot rev-parse ($ExpectedSha + ':DEVELOPMENT_STAGE.md')) -join '').Trim()
    if ($LASTEXITCODE -ne 0) { throw 'STAGE44_EVIDENCE_GIT_BLOB_LOOKUP_FAILED' }
    Assert-Stage44EvidenceEqual $gitBlob $script:Stage44TrustedEvidenceFrozenBlob 'GIT_FROZEN_STAGE43_BLOB'

    $evidence = [ordered]@{
        STAGE44_PREFLIGHT_ASSERTIONS_PASSED = '5027'
        STAGE44_PREFLIGHT_ASSERTIONS_FAILED = '0'
        STAGE44_PREFLIGHT_ENDPOINTS = '720'
        STAGE44_PREFLIGHT_RECTANGLES = '320'
        STAGE44_PREFLIGHT_STRUCTURAL_GUARDS = '67'
        STAGE44_PREFLIGHT_SOURCE_CONTEXTS = '72'
        STAGE44_PREFLIGHT_ORACLE_CONTEXTS = '72'
        STAGE44_PREFLIGHT_CANONICAL_JOBS = '18_OF_18_SUCCESS'
        STAGE44_PREFLIGHT_STAGE43_ASSERTIONS = '2215'
        STAGE44_PREFLIGHT_FINALIZER_IDEMPOTENCY = 'PASS'
        STAGE44_PREFLIGHT_CANONICAL_VERIFY = 'SUCCESS'
        STAGE44_PREFLIGHT_CI_SHA = [string]$run.head_sha
        STAGE44_PREFLIGHT_DEDICATED_RUN = [string]$run.id
        STAGE44_PREFLIGHT_DEDICATED_JOB = [string]$jobSet['Stage44 bounded moving-gate preflight (not activation) / stage44-preflight'].id
        STAGE44_PREFLIGHT_CANONICAL_RUN = [string]$run.id
        STAGE44_PREFLIGHT_DEDICATED_ARTIFACT = [string]$stage44Artifact.id
        STAGE44_PREFLIGHT_DEDICATED_ARTIFACT_SHA256 = $stage44Payload.Digest
        STAGE44_PREFLIGHT_FINALIZER_ARTIFACT = [string]$finalizerArtifact.id
        STAGE44_PREFLIGHT_FINALIZER_SHA256 = ([string]$finalizerSummary['SHA256_BEFORE']).ToLowerInvariant()
        STAGE44_PREFLIGHT_RUNTIME = [string]$stage44Metadata['STAGE44_RUNTIME']
    }

    $manifest = [ordered]@{
        PROJECT_ID = 'PC-BRANCH-POWERSHELL-TAGALOG'
        STAGE44_TRUSTED_EVIDENCE_VERSION = $script:Stage44TrustedEvidenceVersion
        STAGE44_PHASE = 'RESEARCH_PREFLIGHT'
        STAGE44_RUN_ID = [string]$run.id
        STAGE44_HEAD_SHA = [string]$run.head_sha
        STAGE44_BRANCH = [string]$run.head_branch
        STAGE44_EVIDENCE_STAGE43_ARTIFACT_SHA256 = $stage43Payload.Digest
        STAGE44_EVIDENCE_CLASSIFIER_ARTIFACT_SHA256 = $classifierPayload.Digest
        STAGE44_EVIDENCE_METADATA_STATE_ARTIFACT_SHA256 = $metadataStatePayload.Digest
        STAGE44_EVIDENCE_FINALIZER_ARTIFACT_ZIP_SHA256 = $finalizerPayload.Digest
    }
    foreach ($key in $evidence.Keys) { $manifest[$key] = [string]$evidence[$key] }

    if (-not $CurrentRun) {
        $manifestArtifact = Get-Stage44UniqueArtifact -Artifacts $artifacts -Name $script:Stage44TrustedEvidenceManifestArtifact -RunId $RunId -ExpectedSha $ExpectedSha -ExpectedBranch $ExpectedBranch
        $manifestPayload = Get-Stage44ArtifactPayload -Artifact $manifestArtifact -Repository $Repository -Token $Token -ArtifactDownload $ArtifactDownload
        Assert-Stage44ExactEntrySet -Entries $manifestPayload.Entries -ExpectedNames @($script:Stage44TrustedEvidenceManifestFile)
        $manifestKeys = @($manifest.Keys | ForEach-Object { [string]$_ })
        $actualManifest = ConvertFrom-Stage44EvidenceMetadataBytes -Bytes $manifestPayload.Entries[$script:Stage44TrustedEvidenceManifestFile] -RequiredKeys $manifestKeys
        Assert-Stage44ManifestMatches -Actual $actualManifest -Expected $manifest
    } else {
        $unexpectedManifest = @($artifacts | Where-Object { $_.name -ceq $script:Stage44TrustedEvidenceManifestArtifact })
        if ($unexpectedManifest.Count -ne 0) { throw 'STAGE44_EVIDENCE_MANIFEST_ALREADY_EXISTS_DURING_ADJUDICATION' }
    }

    return [pscustomobject]@{
        Evidence = $evidence
        ManifestValues = $manifest
        Run = $run
        JobSet = $jobSet
        ArtifactDigests = [ordered]@{
            Stage44 = $stage44Payload.Digest
            Stage43 = $stage43Payload.Digest
            Classifier = $classifierPayload.Digest
            MetadataState = $metadataStatePayload.Digest
            Finalizer = $finalizerPayload.Digest
        }
    }
}

    $found = [regex]::Matches($Text, $pattern)
    if ($found.Count -ne 1) {
        throw ('STAGE44_EVIDENCE_LINE_COUNT:' + $Key + ':' + $found.Count)
    }
    return $found[0].Groups[1].Value
}

function Get-Stage44TextFromBytes {
    param([Parameter(Mandatory=$true)][AllowEmptyCollection()][byte[]]$Bytes)
    $encoding = [System.Text.UTF8Encoding]::new($false, $true)
    try {
        $text = $encoding.GetString($Bytes)
    } catch {
        throw 'STAGE44_EVIDENCE_INVALID_UTF8'
    }
    if ($text.Length -gt 0 -and $text[0] -eq [char]0xFEFF) {
        $text = $text.Substring(1)
    }
    if ($text.IndexOf([char]0) -ge 0 -or $text.IndexOf([char]0xFEFF) -ge 0) {
        throw 'STAGE44_EVIDENCE_FORBIDDEN_TEXT_BYTE'
    }
    return $text
}

function ConvertFrom-Stage44EvidenceMetadataBytes {
    param(
        [Parameter(Mandatory=$true)][AllowEmptyCollection()][byte[]]$Bytes,
        [Parameter(Mandatory=$true)][string[]]$RequiredKeys
    )
    $parsed = ConvertFrom-StrictStageMetadataBytes -Bytes $Bytes -RequiredKeys $RequiredKeys
    if (-not $parsed.Success) {
        throw ('STAGE44_EVIDENCE_METADATA_REJECTED:' + $parsed.ReasonCode)
    }
    return ,$parsed.Values
}

function Read-Stage44ZipEntries {
    param([Parameter(Mandatory=$true)][AllowEmptyCollection()][byte[]]$Bytes)
    Add-Type -AssemblyName System.IO.Compression
    if ($Bytes.Length -gt 10485760) { throw 'STAGE44_EVIDENCE_ZIP_COMPRESSED_SIZE_LIMIT' }
    $memory = [System.IO.MemoryStream]::new()
    $memory.Write($Bytes, 0, $Bytes.Length)
    $memory.Position = 0
    $archive = $null
    $entries = [System.Collections.Generic.Dictionary[string,byte[]]]::new([System.StringComparer]::Ordinal)
    try {
        $archive = [System.IO.Compression.ZipArchive]::new(
            $memory,
            [System.IO.Compression.ZipArchiveMode]::Read,
            $false
        )
        if ($archive.Entries.Count -gt 64) { throw 'STAGE44_EVIDENCE_ZIP_ENTRY_LIMIT' }
        [long]$totalUncompressed = 0
        foreach ($entry in $archive.Entries) {
            $totalUncompressed += [long]$entry.Length
            if ([long]$entry.Length -gt 5242880 -or $totalUncompressed -gt 10485760) { throw 'STAGE44_EVIDENCE_ZIP_UNCOMPRESSED_SIZE_LIMIT' }
            $name = $entry.FullName.Replace('\', '/')
            if ($name.EndsWith('/')) { continue }
            if ([string]::IsNullOrWhiteSpace($name) -or
                $name.StartsWith('/') -or
                $name -match '^[A-Za-z]:' -or
                $name -match '(^|/)\.\.?(/|$)') {
                throw 'STAGE44_EVIDENCE_UNSAFE_ZIP_PATH'
            }
            if ($entries.ContainsKey($name)) {
                throw 'STAGE44_EVIDENCE_DUPLICATE_ZIP_ENTRY'
            }
            $stream = $entry.Open()
            $buffer = [System.IO.MemoryStream]::new()
            try {
                $stream.CopyTo($buffer)
                $entries.Add($name, $buffer.ToArray())
            } finally {
                $buffer.Dispose()
                $stream.Dispose()
            }
        }
    } finally {
        if ($null -ne $archive) { $archive.Dispose() }
        $memory.Dispose()
    }
    return ,$entries
}

function Assert-Stage44ExactEntrySet {
    param(
        [Parameter(Mandatory=$true)][System.Collections.IDictionary]$Entries,
        [Parameter(Mandatory=$true)][string[]]$ExpectedNames
    )
    $actualNames = @($Entries.Keys)
    if ($actualNames.Count -ne $ExpectedNames.Count) {
        throw 'STAGE44_EVIDENCE_ZIP_ENTRY_COUNT'
    }
    foreach ($name in $ExpectedNames) {
        if (@($Entries.Keys) -cnotcontains $name) {
            throw ('STAGE44_EVIDENCE_ZIP_ENTRY_MISSING:' + $name)
        }
    }
    foreach ($name in $actualNames) {
        if ($ExpectedNames -cnotcontains [string]$name) {
            throw ('STAGE44_EVIDENCE_ZIP_ENTRY_UNEXPECTED:' + $name)
        }
    }
}

function Assert-Stage44ArtifactBinding {
    param(
        [Parameter(Mandatory=$true)][object]$Artifact,
        [Parameter(Mandatory=$true)][long]$RunId,
        [Parameter(Mandatory=$true)][string]$ExpectedSha,
        [Parameter(Mandatory=$true)][string]$ExpectedBranch
    )
    if ($Artifact.expired -ne $false) { throw 'STAGE44_EVIDENCE_ARTIFACT_EXPIRED' }
    if ([long]$Artifact.workflow_run.repository_id -ne [long]$Artifact.workflow_run.head_repository_id) { throw 'STAGE44_EVIDENCE_ARTIFACT_REPOSITORY_MISMATCH' }
    if ([long]$Artifact.workflow_run.id -ne $RunId) { throw 'STAGE44_EVIDENCE_ARTIFACT_RUN_MISMATCH' }
    Assert-Stage44EvidenceEqual $Artifact.workflow_run.head_sha $ExpectedSha 'ARTIFACT_SHA'
    Assert-Stage44EvidenceEqual $Artifact.workflow_run.head_branch $ExpectedBranch 'ARTIFACT_BRANCH'
    if ([string]$Artifact.digest -cnotmatch '^sha256:[0-9a-f]{64}$') {
        throw 'STAGE44_EVIDENCE_ARTIFACT_DIGEST_FORMAT'
    }
}

function Assert-Stage44RequiredStep {
    param(
        [Parameter(Mandatory=$true)][object]$Job,
        [Parameter(Mandatory=$true)][string]$StepName
    )
    $matches = @($Job.steps | Where-Object { $_.name -ceq $StepName })
    if ($matches.Count -ne 1) {
        throw ('STAGE44_EVIDENCE_REQUIRED_STEP_COUNT:' + $StepName)
    }
    if ($matches[0].status -cne 'completed' -or $matches[0].conclusion -cne 'success') {
        throw ('STAGE44_EVIDENCE_REQUIRED_STEP_NOT_SUCCESS:' + $StepName)
    }
}

function Assert-Stage44EvidenceJobSet {
    param(
        [Parameter(Mandatory=$true)][object[]]$Jobs,
        [Parameter(Mandatory=$true)][long]$RunId,
        [switch]$CurrentRun
    )
    if ($Jobs.Count -ne 19) { throw 'STAGE44_EVIDENCE_CANONICAL_JOB_COUNT' }
    $byName = @{}
    foreach ($name in $script:Stage44TrustedEvidenceRequiredJobs) {
        $found = @($Jobs | Where-Object { $_.name -ceq $name })
        if ($found.Count -ne 1) { throw ('STAGE44_EVIDENCE_CANONICAL_JOB_MISSING_OR_DUPLICATE:' + $name) }
        if ([long]$found[0].run_id -ne $RunId) { throw ('STAGE44_EVIDENCE_JOB_RUN_MISMATCH:' + $name) }
        if ($found[0].status -cne 'completed' -or $found[0].conclusion -cne 'success') {
            throw ('STAGE44_EVIDENCE_CANONICAL_JOB_NOT_SUCCESS:' + $name)
        }
        $byName[$name] = $found[0]
    }
    $extras = @($Jobs | Where-Object { $script:Stage44TrustedEvidenceRequiredJobs -cnotcontains [string]$_.name })
    if ($extras.Count -ne 1 -or $extras[0].name -cne $script:Stage44TrustedEvidenceJobName) {
        throw 'STAGE44_EVIDENCE_UNEXPECTED_CANONICAL_JOB_SET'
    }
    if ([long]$extras[0].run_id -ne $RunId) { throw 'STAGE44_EVIDENCE_ADJUDICATOR_RUN_MISMATCH' }
    if ($CurrentRun) {
        if ($extras[0].status -cne 'in_progress' -or $null -ne $extras[0].conclusion) {
            throw 'STAGE44_EVIDENCE_CURRENT_ADJUDICATOR_STATE'
        }
    } else {
        if ($extras[0].status -cne 'completed' -or $extras[0].conclusion -cne 'success') {
            throw 'STAGE44_EVIDENCE_ADJUDICATOR_NOT_SUCCESS'
        }
    }
    $byName['evidence-adjudication'] = $extras[0]
    return $byName
}

function Get-Stage44UniqueArtifact {
    param(
        [Parameter(Mandatory=$true)][object[]]$Artifacts,
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][long]$RunId,
        [Parameter(Mandatory=$true)][string]$ExpectedSha,
        [Parameter(Mandatory=$true)][string]$ExpectedBranch
    )
    $found = @($Artifacts | Where-Object { $_.name -ceq $Name })
    if ($found.Count -ne 1) { throw ('STAGE44_EVIDENCE_ARTIFACT_COUNT:' + $Name) }
    Assert-Stage44ArtifactBinding -Artifact $found[0] -RunId $RunId -ExpectedSha $ExpectedSha -ExpectedBranch $ExpectedBranch
    return $found[0]
}

function Get-Stage44ArtifactZipBytes {
    param(
        [Parameter(Mandatory=$true)][string]$Repository,
        [Parameter(Mandatory=$true)][long]$ArtifactId,
        [Parameter(Mandatory=$true)][string]$Token
    )
    $uri = 'https://api.github.com/repos/' + $Repository + '/actions/artifacts/' + $ArtifactId + '/zip'
    $request = [System.Net.HttpWebRequest]::Create($uri)
    $request.Method = 'GET'
    $request.Headers.Add('Authorization', ('Bearer ' + $Token))
    $request.Accept = 'application/vnd.github+json'
    $request.UserAgent = 'Stage44TrustedEvidence/1'
    $request.AllowAutoRedirect = $false
    $request.Timeout = 120000
    $response = $null
    try {
        try {
            $response = [System.Net.HttpWebResponse]$request.GetResponse()
        } catch [System.Net.WebException] {
            if ($null -eq $_.Exception.Response) { throw }
            $response = [System.Net.HttpWebResponse]$_.Exception.Response
        }
        $status = [int]$response.StatusCode
        if (@(301,302,303,307,308) -contains $status) {
            $location = $response.Headers['Location']
            if ([string]::IsNullOrWhiteSpace($location)) { throw 'STAGE44_EVIDENCE_ARTIFACT_REDIRECT_MISSING' }
            $target = [Uri]$location
            if ($target.Scheme -cne 'https' -or -not [string]::IsNullOrEmpty($target.UserInfo)) {
                throw 'STAGE44_EVIDENCE_ARTIFACT_REDIRECT_UNSAFE'
            }
            $response.Close()
            $response = $null
            $downloadRequest = [System.Net.HttpWebRequest]::Create($target)
            $downloadRequest.Method = 'GET'
            $downloadRequest.UserAgent = 'Stage44TrustedEvidence/1'
            $downloadRequest.AllowAutoRedirect = $true
            $downloadRequest.Timeout = 120000
            $response = [System.Net.HttpWebResponse]$downloadRequest.GetResponse()
            $status = [int]$response.StatusCode
        }
        if ($status -ne 200) { throw ('STAGE44_EVIDENCE_ARTIFACT_HTTP_STATUS:' + $status) }
        if ($response.ContentLength -gt 10485760) { throw 'STAGE44_EVIDENCE_ARTIFACT_DOWNLOAD_SIZE_LIMIT' }
        $stream = $response.GetResponseStream()
        $memory = [System.IO.MemoryStream]::new()
        try {
            $buffer = New-Object byte[] 65536
            while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                $memory.Write($buffer, 0, $read)
                if ($memory.Length -gt 10485760) { throw 'STAGE44_EVIDENCE_ARTIFACT_DOWNLOAD_SIZE_LIMIT' }
            }
            return ,$memory.ToArray()
        } finally {
            $memory.Dispose()
            $stream.Dispose()
        }
    } finally {
        if ($null -ne $response) { $response.Close() }
    }
}

function Get-Stage44ArtifactPayload {
    param(
        [Parameter(Mandatory=$true)][object]$Artifact,
        [Parameter(Mandatory=$true)][string]$Repository,
        [Parameter(Mandatory=$true)][string]$Token,
        [Parameter(Mandatory=$true)][scriptblock]$ArtifactDownload
    )
    $bytes = & $ArtifactDownload $Repository ([long]$Artifact.id) $Token
    if ($bytes -isnot [byte[]]) { throw 'STAGE44_EVIDENCE_ARTIFACT_DOWNLOAD_TYPE' }
    if ([long]$Artifact.size_in_bytes -le 0 -or [long]$Artifact.size_in_bytes -gt 10485760) { throw 'STAGE44_EVIDENCE_ARTIFACT_SIZE_LIMIT' }
    $hash = [System.Security.Cryptography.SHA256]::Create()
    try {
        $actualDigest = [System.BitConverter]::ToString($hash.ComputeHash($bytes)).Replace('-', '').ToLowerInvariant()
    } finally {
        $hash.Dispose()
    }
    $expectedDigest = ([string]$Artifact.digest).Substring(7)
    Assert-Stage44EvidenceEqual $actualDigest $expectedDigest 'ARTIFACT_ZIP_SHA256'
    $entries = Read-Stage44ZipEntries -Bytes $bytes
    return [pscustomobject]@{
        Artifact = $Artifact
        Digest = $actualDigest
        Entries = $entries
    }
}

function Assert-Stage44ManifestMatches {
    param(
        [Parameter(Mandatory=$true)][System.Collections.IDictionary]$Actual,
        [Parameter(Mandatory=$true)][System.Collections.IDictionary]$Expected
    )
    if ($Actual.Count -ne $Expected.Count) { throw 'STAGE44_EVIDENCE_MANIFEST_KEY_COUNT' }
    foreach ($key in $Expected.Keys) {
        if (@($Actual.Keys) -cnotcontains $key) { throw ('STAGE44_EVIDENCE_MANIFEST_KEY_MISSING:' + $key) }
        Assert-Stage44EvidenceEqual $Actual[$key] ([string]$Expected[$key]) ('MANIFEST_' + $key)
    }
}

function Invoke-Stage44ApiGet {
    param(
        [Parameter(Mandatory=$true)][string]$Uri,
        [Parameter(Mandatory=$true)][string]$Token
    )
    $headers = @{
        Authorization = 'Bearer ' + $Token
        Accept = 'application/vnd.github+json'
        'X-GitHub-Api-Version' = '2022-11-28'
    }
    return Invoke-RestMethod -Method Get -Uri $Uri -Headers $headers -ErrorAction Stop
}

function Get-Stage44TrustedEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Repository,
        [Parameter(Mandatory=$true)][long]$RunId,
        [Parameter(Mandatory=$true)][string]$ExpectedSha,
        [Parameter(Mandatory=$true)][string]$ExpectedBranch,
        [Parameter(Mandatory=$true)][string]$Token,
        [Parameter(Mandatory=$true)][string]$RepositoryRoot,
        [switch]$CurrentRun,
        [scriptblock]$ApiGet = $null,
        [scriptblock]$ArtifactDownload = $null
    )
    if ($null -eq $ApiGet) {
        $ApiGet = { param($uri, $tokenValue) Invoke-Stage44ApiGet -Uri $uri -Token $tokenValue }
    }
    if ($null -eq $ArtifactDownload) {
        $ArtifactDownload = { param($repoValue, $artifactId, $tokenValue) Get-Stage44ArtifactZipBytes -Repository $repoValue -ArtifactId $artifactId -Token $tokenValue }
    }

    $base = 'https://api.github.com/repos/' + $Repository
    $run = & $ApiGet ($base + '/actions/runs/' + $RunId) $Token
    if ([long]$run.id -ne $RunId) { throw 'STAGE44_EVIDENCE_RUN_ID_MISMATCH' }
    Assert-Stage44EvidenceEqual $run.head_sha $ExpectedSha 'RUN_SHA'
    Assert-Stage44EvidenceEqual $run.head_branch $ExpectedBranch 'RUN_BRANCH'
    Assert-Stage44EvidenceEqual $run.event 'push' 'RUN_EVENT'
    Assert-Stage44EvidenceEqual $run.path '.github/workflows/canonical-names-lock.yml' 'RUN_WORKFLOW'
    if ($null -ne $run.PSObject.Properties['repository']) { Assert-Stage44EvidenceEqual $run.repository.full_name $Repository 'RUN_REPOSITORY' }
    if ($null -ne $run.PSObject.Properties['head_repository']) { Assert-Stage44EvidenceEqual $run.head_repository.full_name $Repository 'RUN_HEAD_REPOSITORY' }
    if ([int]$run.run_attempt -ne 1) { throw 'STAGE44_EVIDENCE_RUN_ATTEMPT_UNSUPPORTED' }
    if ($CurrentRun) {
        if ($run.status -cne 'in_progress' -or $null -ne $run.conclusion) {
            throw 'STAGE44_EVIDENCE_CURRENT_RUN_STATE'
        }
    } else {
        if ($run.status -cne 'completed' -or $run.conclusion -cne 'success') {
            throw 'STAGE44_EVIDENCE_COMPLETED_RUN_NOT_SUCCESS'
        }
    }

    $jobsResponse = & $ApiGet ($base + '/actions/runs/' + $RunId + '/jobs?per_page=100') $Token
    $jobs = @($jobsResponse.jobs)
    if ([int]$jobsResponse.total_count -ne $jobs.Count) { throw 'STAGE44_EVIDENCE_JOBS_PAGINATION_REQUIRED' }
    $jobSet = Assert-Stage44EvidenceJobSet -Jobs $jobs -RunId $RunId -CurrentRun:$CurrentRun

    Assert-Stage44RequiredStep -Job $jobSet['verify'] -StepName 'Verify canonical names lock'
    Assert-Stage44RequiredStep -Job $jobSet['Stage43 preflight: independent oracle at neighboring year gates'] -StepName 'Run 42-case fail-closed Stage43 metadata-state classifier regression'
    Assert-Stage44RequiredStep -Job $jobSet['Stage43 preflight: independent oracle at neighboring year gates'] -StepName 'Stage44 strict metadata classifier synthetic regression (not activation)'
    Assert-Stage44RequiredStep -Job $jobSet['Stage43 preflight: independent oracle at neighboring year gates'] -StepName 'Verify exact-SHA Windows PowerShell 5.1 Stage43 lifecycle profile and bounded oracle'
    Assert-Stage44RequiredStep -Job $jobSet['Stage43 preflight: independent oracle at neighboring year gates'] -StepName 'Require Stage43 lifecycle evidence files'
    Assert-Stage44RequiredStep -Job $jobSet['Stage43 preflight: independent oracle at neighboring year gates'] -StepName 'Retain Stage43 lifecycle regression evidence'
    Assert-Stage44RequiredStep -Job $jobSet['Stage44 bounded moving-gate preflight (not activation) / stage44-preflight'] -StepName 'Exact-SHA Stage44 bounded oracle preflight'
    Assert-Stage44RequiredStep -Job $jobSet['Stage44 bounded moving-gate preflight (not activation) / stage44-preflight'] -StepName 'Require evidence files'
    Assert-Stage44RequiredStep -Job $jobSet['Stage44 bounded moving-gate preflight (not activation) / stage44-preflight'] -StepName 'Retain Stage44 evidence'
    Assert-Stage44RequiredStep -Job $jobSet['Native Windows PowerShell 5.1 Stage29+Stage30 and regressions'] -StepName 'Verify sealed Stage 23 finalizer idempotency twice'
    Assert-Stage44RequiredStep -Job $jobSet['Native Windows PowerShell 5.1 Stage29+Stage30 and regressions'] -StepName 'Retain Stage 23 finalizer idempotency evidence'

    $artifactsResponse = & $ApiGet ($base + '/actions/runs/' + $RunId + '/artifacts?per_page=100') $Token
    $artifacts = @($artifactsResponse.artifacts)
    if ([int]$artifactsResponse.total_count -ne $artifacts.Count) { throw 'STAGE44_EVIDENCE_ARTIFACTS_PAGINATION_REQUIRED' }

    $stage44Artifact = Get-Stage44UniqueArtifact -Artifacts $artifacts -Name 'powershell-tagalog-stage44-moving-gate-preflight' -RunId $RunId -ExpectedSha $ExpectedSha -ExpectedBranch $ExpectedBranch
    $stage43Artifact = Get-Stage44UniqueArtifact -Artifacts $artifacts -Name 'powershell-tagalog-stage43-lifecycle-regression' -RunId $RunId -ExpectedSha $ExpectedSha -ExpectedBranch $ExpectedBranch
    $finalizerArtifact = Get-Stage44UniqueArtifact -Artifacts $artifacts -Name 'native-powershell-tagalog-stage23-finalizer-idempotency' -RunId $RunId -ExpectedSha $ExpectedSha -ExpectedBranch $ExpectedBranch
    $classifierArtifact = Get-Stage44UniqueArtifact -Artifacts $artifacts -Name 'powershell-tagalog-stage44-classifier-regression' -RunId $RunId -ExpectedSha $ExpectedSha -ExpectedBranch $ExpectedBranch
    $metadataStateArtifact = Get-Stage44UniqueArtifact -Artifacts $artifacts -Name 'powershell-tagalog-stage43-metadata-state-regression' -RunId $RunId -ExpectedSha $ExpectedSha -ExpectedBranch $ExpectedBranch

    $stage44Payload = Get-Stage44ArtifactPayload -Artifact $stage44Artifact -Repository $Repository -Token $Token -ArtifactDownload $ArtifactDownload
    $stage43Payload = Get-Stage44ArtifactPayload -Artifact $stage43Artifact -Repository $Repository -Token $Token -ArtifactDownload $ArtifactDownload
    $finalizerPayload = Get-Stage44ArtifactPayload -Artifact $finalizerArtifact -Repository $Repository -Token $Token -ArtifactDownload $ArtifactDownload
    $classifierPayload = Get-Stage44ArtifactPayload -Artifact $classifierArtifact -Repository $Repository -Token $Token -ArtifactDownload $ArtifactDownload
    $metadataStatePayload = Get-Stage44ArtifactPayload -Artifact $metadataStateArtifact -Repository $Repository -Token $Token -ArtifactDownload $ArtifactDownload

    Assert-Stage44ExactEntrySet -Entries $stage44Payload.Entries -ExpectedNames @('stage44-metadata.txt','stage44-transcript.txt','DEVELOPMENT_STAGE.md')
    Assert-Stage44ExactEntrySet -Entries $stage43Payload.Entries -ExpectedNames @('stage43-lifecycle-metadata.txt','stage43-lifecycle-transcript.txt','DEVELOPMENT_STAGE.md')
    Assert-Stage44ExactEntrySet -Entries $classifierPayload.Entries -ExpectedNames @('stage44-classifier-transcript.txt')
    Assert-Stage44ExactEntrySet -Entries $metadataStatePayload.Entries -ExpectedNames @('stage-metadata-state-metadata.txt','stage-metadata-state-transcript.txt','DEVELOPMENT_STAGE.md')

    $stage44MetadataKeys = @('PROJECT_ID','STAGE44_CHECKED_OUT_SHA','STAGE44_RUNTIME','STAGE43_METADATA_BLOB','STAGE44_PLANNED_ASSERTIONS','STAGE44_ACTIVATION','STAGE44_PREFLIGHT_RESULT')
    $stage44Metadata = ConvertFrom-Stage44EvidenceMetadataBytes -Bytes $stage44Payload.Entries['stage44-metadata.txt'] -RequiredKeys $stage44MetadataKeys
    Assert-Stage44EvidenceEqual $stage44Metadata['PROJECT_ID'] 'PC-BRANCH-POWERSHELL-TAGALOG' 'PROJECT_ID'
    Assert-Stage44EvidenceEqual $stage44Metadata['STAGE44_CHECKED_OUT_SHA'] $ExpectedSha 'STAGE44_METADATA_SHA'
    Assert-Stage44EvidenceEqual $stage44Metadata['STAGE43_METADATA_BLOB'] $script:Stage44TrustedEvidenceFrozenBlob 'STAGE43_FROZEN_BLOB'
    Assert-Stage44EvidenceEqual $stage44Metadata['STAGE44_PLANNED_ASSERTIONS'] '5027' 'STAGE44_PLANNED_ASSERTIONS'
    Assert-Stage44EvidenceEqual $stage44Metadata['STAGE44_ACTIVATION'] 'NOT_ACTIVATED' 'STAGE44_NOT_ACTIVATED'
    Assert-Stage44EvidenceEqual $stage44Metadata['STAGE44_PREFLIGHT_RESULT'] 'BOUNDED_ORACLE_PASS' 'STAGE44_PREFLIGHT_RESULT'
    if ([string]$stage44Metadata['STAGE44_RUNTIME'] -cnotmatch '^5\.1\.[0-9]+\.[0-9]+$') { throw 'STAGE44_EVIDENCE_RUNTIME_INVALID' }

    $stage44Text = Get-Stage44TextFromBytes -Bytes $stage44Payload.Entries['stage44-transcript.txt']
    $stage43Text = Get-Stage44TextFromBytes -Bytes $stage43Payload.Entries['stage43-lifecycle-transcript.txt']
    $classifierText = Get-Stage44TextFromBytes -Bytes $classifierPayload.Entries['stage44-classifier-transcript.txt']
    $metadataStateText = Get-Stage44TextFromBytes -Bytes $metadataStatePayload.Entries['stage-metadata-state-transcript.txt']

    $stage44Expected = [ordered]@{
        STAGE44_NUMERICAL_EXECUTION_ROUTE = 'RESEARCH_PREFLIGHT'
        STAGE44_SOURCE_CONTEXTS = '72'
        STAGE44_ORACLE_CONTEXTS = '72'
        STAGE44_ENDPOINTS = '720'
        STAGE44_RECTANGLES = '320'
        STAGE44_STRUCTURAL_GUARDS = '67'
        STAGE44_ASSERTIONS_PASSED = '5027'
        STAGE44_ASSERTIONS_FAILED = '0'
        STAGE44_PREFLIGHT = 'BOUNDED_ORACLE_PASS'
        STAGE44_ACTIVATION = 'NOT_ACTIVATED'
    }
    foreach ($key in $stage44Expected.Keys) {
        Assert-Stage44EvidenceEqual (Get-Stage44UniqueLineValue -Text $stage44Text -Key $key) $stage44Expected[$key] $key
    }

    $stage43MetadataKeys = @('PROJECT_ID','STAGE43_CHECKED_OUT_SHA','STAGE43_RUNTIME','STAGE43_PLANNED_ASSERTIONS','STAGE43_METADATA_PROFILE','STAGE43_RUNTIME_VERIFICATION','STAGE43_ACTIVATION','STAGE43_NATIVE_ACCEPTANCE','STAGE43_STAGE_SEAL','STAGE43_SEALED_STATE_REGRESSION')
    $stage43Metadata = ConvertFrom-Stage44EvidenceMetadataBytes -Bytes $stage43Payload.Entries['stage43-lifecycle-metadata.txt'] -RequiredKeys $stage43MetadataKeys
    Assert-Stage44EvidenceEqual $stage43Metadata['PROJECT_ID'] 'PC-BRANCH-POWERSHELL-TAGALOG' 'STAGE43_PROJECT_ID'
    Assert-Stage44EvidenceEqual $stage43Metadata['STAGE43_CHECKED_OUT_SHA'] $ExpectedSha 'STAGE43_METADATA_SHA'
    Assert-Stage44EvidenceEqual $stage43Metadata['STAGE43_PLANNED_ASSERTIONS'] '2215' 'STAGE43_PLANNED_ASSERTIONS'
    Assert-Stage44EvidenceEqual $stage43Metadata['STAGE43_METADATA_PROFILE'] 'SEALED_SHAPE_ONLY' 'STAGE43_PROFILE'
    Assert-Stage44EvidenceEqual $stage43Metadata['STAGE43_RUNTIME_VERIFICATION'] 'EVIDENCE_ONLY_CONFIRMED' 'STAGE43_RUNTIME_VERIFICATION'
    Assert-Stage44EvidenceEqual $stage43Metadata['STAGE43_ACTIVATION'] 'EVIDENCE_ONLY_CONFIRMED' 'STAGE43_ACTIVATION'
    Assert-Stage44EvidenceEqual $stage43Metadata['STAGE43_NATIVE_ACCEPTANCE'] 'IMPLEMENTING_SHA_ACCEPTED' 'STAGE43_NATIVE_ACCEPTANCE'
    Assert-Stage44EvidenceEqual $stage43Metadata['STAGE43_STAGE_SEAL'] 'CLAIM_RECORDED_NOT_REVALIDATED' 'STAGE43_STAGE_SEAL'
    Assert-Stage44EvidenceEqual $stage43Metadata['STAGE43_SEALED_STATE_REGRESSION'] 'PASS' 'STAGE43_SEALED_STATE_REGRESSION'
    Assert-Stage44EvidenceEqual $stage43Metadata['STAGE43_RUNTIME'] $stage44Metadata['STAGE44_RUNTIME'] 'STAGE43_STAGE44_RUNTIME'

    $stage43Expected = [ordered]@{
        STAGE43_ENDPOINTS = '240'
        STAGE43_TARGET_PAIRS = '160'
        STAGE43_SEAL_PAIRS = '216'
        STAGE43_STRUCTURAL_GUARDS = '23'
        STAGE43_ASSERTIONS_PASSED = '2215'
        STAGE43_ASSERTIONS_FAILED = '0'
        STAGE43_SEALED_STATE_REGRESSION = 'PASS'
        STAGE43_STAGE_SEAL = 'CLAIM_RECORDED_NOT_REVALIDATED'
    }
    foreach ($key in $stage43Expected.Keys) {
        Assert-Stage44EvidenceEqual (Get-Stage44UniqueLineValue -Text $stage43Text -Key $key) $stage43Expected[$key] $key
    }

    $classifierExpected = [ordered]@{
        STAGE44_BOUNDARY_ASSERTIONS_PASSED = '8'
        STAGE44_BOUNDARY_ASSERTIONS_FAILED = '0'
        STAGE44_CLASSIFIER_ASSERTIONS_PASSED = '240'
        STAGE44_CLASSIFIER_ASSERTIONS_FAILED = '0'
        STAGE44_CLASSIFIER_RESULT = 'PASS_SHAPE_ONLY'
    }
    foreach ($key in $classifierExpected.Keys) {
        Assert-Stage44EvidenceEqual (Get-Stage44UniqueLineValue -Text $classifierText -Key $key) $classifierExpected[$key] $key
    }
    $trustedCases = [int](Get-Stage44UniqueLineValue -Text $classifierText -Key 'STAGE44_TRUSTED_EVIDENCE_CASES_PASSED')
    Assert-Stage44EvidenceEqual (Get-Stage44UniqueLineValue -Text $classifierText -Key 'STAGE44_TRUSTED_EVIDENCE_CASES_FAILED') '0' 'STAGE44_TRUSTED_EVIDENCE_CASES_FAILED'
    Assert-Stage44EvidenceEqual (Get-Stage44UniqueLineValue -Text $classifierText -Key 'STAGE44_TRUSTED_EVIDENCE_RESULT') 'PASS_SYNTHETIC_GATES' 'STAGE44_TRUSTED_EVIDENCE_RESULT'
    if ($trustedCases -lt 20) { throw 'STAGE44_EVIDENCE_SYNTHETIC_CASE_COUNT' }

    $metadataStateMetadataKeys = @('PROJECT_ID','STAGE_METADATA_STATE_HEAD_SHA','STAGE_METADATA_STATE_RUNTIME','STAGE_METADATA_STATE_EXPECTED_CASES','STAGE_METADATA_STATE_REGRESSION')
    $metadataStateMetadata = ConvertFrom-Stage44EvidenceMetadataBytes -Bytes $metadataStatePayload.Entries['stage-metadata-state-metadata.txt'] -RequiredKeys $metadataStateMetadataKeys
    Assert-Stage44EvidenceEqual $metadataStateMetadata['PROJECT_ID'] 'PC-BRANCH-POWERSHELL-TAGALOG' 'METADATA_STATE_PROJECT_ID'
    Assert-Stage44EvidenceEqual $metadataStateMetadata['STAGE_METADATA_STATE_HEAD_SHA'] $ExpectedSha 'METADATA_STATE_SHA'
    Assert-Stage44EvidenceEqual $metadataStateMetadata['STAGE_METADATA_STATE_RUNTIME'] $stage44Metadata['STAGE44_RUNTIME'] 'METADATA_STATE_RUNTIME'
    Assert-Stage44EvidenceEqual $metadataStateMetadata['STAGE_METADATA_STATE_EXPECTED_CASES'] '42' 'METADATA_STATE_EXPECTED_CASES'
    Assert-Stage44EvidenceEqual $metadataStateMetadata['STAGE_METADATA_STATE_REGRESSION'] 'PASS' 'METADATA_STATE_REGRESSION'
    Assert-Stage44EvidenceEqual (Get-Stage44UniqueLineValue -Text $metadataStateText -Key 'STAGE_METADATA_STATE_CASES_PASSED') '42' 'METADATA_STATE_CASES_PASSED'
    Assert-Stage44EvidenceEqual (Get-Stage44UniqueLineValue -Text $metadataStateText -Key 'STAGE_METADATA_STATE_RESULT') 'PASS' 'METADATA_STATE_RESULT'
    Assert-Stage44EvidenceEqual (Get-Stage44UniqueLineValue -Text $metadataStateText -Key 'STAGE43_ACCEPTANCE') 'NOT_CLAIMED_BY_SHAPE_TESTS' 'STAGE43_ACCEPTANCE_NOT_CLAIMED'

    $stage44Dev = [Convert]::ToBase64String($stage44Payload.Entries['DEVELOPMENT_STAGE.md'])
    $stage43Dev = [Convert]::ToBase64String($stage43Payload.Entries['DEVELOPMENT_STAGE.md'])
    $metadataStateDev = [Convert]::ToBase64String($metadataStatePayload.Entries['DEVELOPMENT_STAGE.md'])
    Assert-Stage44EvidenceEqual $stage44Dev $stage43Dev 'STAGE43_STAGE44_METADATA_BYTES'
    Assert-Stage44EvidenceEqual $stage44Dev $metadataStateDev 'METADATA_STATE_METADATA_BYTES'

    $finalizerEntries = $finalizerPayload.Entries
    $summaryPaths = @($finalizerEntries.Keys | Where-Object { $_ -match '^Stage23-Finalize-Idempotency-[^/]+/summary\.txt$' })
    if ($summaryPaths.Count -ne 1) { throw 'STAGE44_EVIDENCE_FINALIZER_SUMMARY_COUNT' }
    $prefix = $summaryPaths[0].Substring(0, $summaryPaths[0].LastIndexOf('/') + 1)
    $finalizerNames = @(
        ($prefix + 'run1-stage-diff.txt'),
        ($prefix + 'run1-stderr.txt'),
        ($prefix + 'run1-stdout.txt'),
        ($prefix + 'run2-stage-diff.txt'),
        ($prefix + 'run2-stderr.txt'),
        ($prefix + 'run2-stdout.txt'),
        ($prefix + 'summary.txt')
    )
    Assert-Stage44ExactEntrySet -Entries $finalizerEntries -ExpectedNames $finalizerNames
    $finalizerSummaryKeys = @('TEST','PS_VERSION','BRANCH','HEAD','KNOWN_PATCH11_HEAD','SHA256_BEFORE','RUN_1_EXIT_CODE','RUN_1_ALREADY_FINALIZED','RUN_1_STDERR_LENGTH','RUN_1_SHA256_AFTER','RUN_2_EXIT_CODE','RUN_2_ALREADY_FINALIZED','RUN_2_STDERR_LENGTH','RUN_2_SHA256_AFTER','RESULT')
    $finalizerSummary = ConvertFrom-Stage44EvidenceMetadataBytes -Bytes $finalizerEntries[$summaryPaths[0]] -RequiredKeys $finalizerSummaryKeys
    Assert-Stage44EvidenceEqual $finalizerSummary['TEST'] 'STAGE23_FINALIZE_IDEMPOTENCY' 'FINALIZER_TEST'
    Assert-Stage44EvidenceEqual $finalizerSummary['BRANCH'] $ExpectedBranch 'FINALIZER_BRANCH'
    Assert-Stage44EvidenceEqual $finalizerSummary['HEAD'] $ExpectedSha 'FINALIZER_SHA'
    Assert-Stage44EvidenceEqual $finalizerSummary['KNOWN_PATCH11_HEAD'] '7e895d374962dbc57a68035eef02f76a365af440' 'FINALIZER_KNOWN_PATCH11_HEAD'
    Assert-Stage44EvidenceEqual $finalizerSummary['RUN_1_EXIT_CODE'] '0' 'FINALIZER_RUN1_EXIT'
    Assert-Stage44EvidenceEqual $finalizerSummary['RUN_2_EXIT_CODE'] '0' 'FINALIZER_RUN2_EXIT'
    Assert-Stage44EvidenceEqual $finalizerSummary['RUN_1_ALREADY_FINALIZED'] 'True' 'FINALIZER_RUN1_IDEMPOTENT'
    Assert-Stage44EvidenceEqual $finalizerSummary['RUN_2_ALREADY_FINALIZED'] 'True' 'FINALIZER_RUN2_IDEMPOTENT'
    Assert-Stage44EvidenceEqual $finalizerSummary['RUN_1_STDERR_LENGTH'] '0' 'FINALIZER_RUN1_STDERR'
    Assert-Stage44EvidenceEqual $finalizerSummary['RUN_2_STDERR_LENGTH'] '0' 'FINALIZER_RUN2_STDERR'
    Assert-Stage44EvidenceEqual $finalizerSummary['RUN_1_SHA256_AFTER'] $finalizerSummary['SHA256_BEFORE'] 'FINALIZER_RUN1_SHA'
    Assert-Stage44EvidenceEqual $finalizerSummary['RUN_2_SHA256_AFTER'] $finalizerSummary['SHA256_BEFORE'] 'FINALIZER_RUN2_SHA'
    Assert-Stage44EvidenceEqual $finalizerSummary['RESULT'] 'PASS' 'FINALIZER_RESULT'
    if ([string]$finalizerSummary['PS_VERSION'] -cnotmatch '^5\.1\.[0-9]+\.[0-9]+$') { throw 'STAGE44_EVIDENCE_FINALIZER_RUNTIME' }
    foreach ($name in @('run1-stderr.txt','run2-stderr.txt')) {
        if ($finalizerEntries[$prefix + $name].Length -ne 0) { throw ('STAGE44_EVIDENCE_FINALIZER_STDERR_FILE:' + $name) }
    }
    foreach ($name in @('run1-stage-diff.txt','run2-stage-diff.txt')) {
        if ((Get-Stage44TextFromBytes -Bytes $finalizerEntries[$prefix + $name]).Trim().Length -ne 0) {
            throw ('STAGE44_EVIDENCE_FINALIZER_STAGE_DIFF:' + $name)
        }
    }

    $gitBlob = ((& git -C $RepositoryRoot rev-parse ($ExpectedSha + ':DEVELOPMENT_STAGE.md')) -join '').Trim()
    if ($LASTEXITCODE -ne 0) { throw 'STAGE44_EVIDENCE_GIT_BLOB_LOOKUP_FAILED' }
    Assert-Stage44EvidenceEqual $gitBlob $script:Stage44TrustedEvidenceFrozenBlob 'GIT_FROZEN_STAGE43_BLOB'

    $evidence = [ordered]@{
        STAGE44_PREFLIGHT_ASSERTIONS_PASSED = '5027'
        STAGE44_PREFLIGHT_ASSERTIONS_FAILED = '0'
        STAGE44_PREFLIGHT_ENDPOINTS = '720'
        STAGE44_PREFLIGHT_RECTANGLES = '320'
        STAGE44_PREFLIGHT_STRUCTURAL_GUARDS = '67'
        STAGE44_PREFLIGHT_SOURCE_CONTEXTS = '72'
        STAGE44_PREFLIGHT_ORACLE_CONTEXTS = '72'
        STAGE44_PREFLIGHT_CANONICAL_JOBS = '18_OF_18_SUCCESS'
        STAGE44_PREFLIGHT_STAGE43_ASSERTIONS = '2215'
        STAGE44_PREFLIGHT_FINALIZER_IDEMPOTENCY = 'PASS'
        STAGE44_PREFLIGHT_CANONICAL_VERIFY = 'SUCCESS'
        STAGE44_PREFLIGHT_CI_SHA = [string]$run.head_sha
        STAGE44_PREFLIGHT_DEDICATED_RUN = [string]$run.id
        STAGE44_PREFLIGHT_DEDICATED_JOB = [string]$jobSet['Stage44 bounded moving-gate preflight (not activation) / stage44-preflight'].id
        STAGE44_PREFLIGHT_CANONICAL_RUN = [string]$run.id
        STAGE44_PREFLIGHT_DEDICATED_ARTIFACT = [string]$stage44Artifact.id
        STAGE44_PREFLIGHT_DEDICATED_ARTIFACT_SHA256 = $stage44Payload.Digest
        STAGE44_PREFLIGHT_FINALIZER_ARTIFACT = [string]$finalizerArtifact.id
        STAGE44_PREFLIGHT_FINALIZER_SHA256 = ([string]$finalizerSummary['SHA256_BEFORE']).ToLowerInvariant()
        STAGE44_PREFLIGHT_RUNTIME = [string]$stage44Metadata['STAGE44_RUNTIME']
    }

    $manifest = [ordered]@{
        PROJECT_ID = 'PC-BRANCH-POWERSHELL-TAGALOG'
        STAGE44_TRUSTED_EVIDENCE_VERSION = $script:Stage44TrustedEvidenceVersion
        STAGE44_PHASE = 'RESEARCH_PREFLIGHT'
        STAGE44_RUN_ID = [string]$run.id
        STAGE44_HEAD_SHA = [string]$run.head_sha
        STAGE44_BRANCH = [string]$run.head_branch
        STAGE44_EVIDENCE_STAGE43_ARTIFACT_SHA256 = $stage43Payload.Digest
        STAGE44_EVIDENCE_CLASSIFIER_ARTIFACT_SHA256 = $classifierPayload.Digest
        STAGE44_EVIDENCE_METADATA_STATE_ARTIFACT_SHA256 = $metadataStatePayload.Digest
        STAGE44_EVIDENCE_FINALIZER_ARTIFACT_ZIP_SHA256 = $finalizerPayload.Digest
    }
    foreach ($key in $evidence.Keys) { $manifest[$key] = [string]$evidence[$key] }

    if (-not $CurrentRun) {
        $manifestArtifact = Get-Stage44UniqueArtifact -Artifacts $artifacts -Name $script:Stage44TrustedEvidenceManifestArtifact -RunId $RunId -ExpectedSha $ExpectedSha -ExpectedBranch $ExpectedBranch
        $manifestPayload = Get-Stage44ArtifactPayload -Artifact $manifestArtifact -Repository $Repository -Token $Token -ArtifactDownload $ArtifactDownload
        Assert-Stage44ExactEntrySet -Entries $manifestPayload.Entries -ExpectedNames @($script:Stage44TrustedEvidenceManifestFile)
        $manifestKeys = @($manifest.Keys | ForEach-Object { [string]$_ })
        $actualManifest = ConvertFrom-Stage44EvidenceMetadataBytes -Bytes $manifestPayload.Entries[$script:Stage44TrustedEvidenceManifestFile] -RequiredKeys $manifestKeys
        Assert-Stage44ManifestMatches -Actual $actualManifest -Expected $manifest
    } else {
        $unexpectedManifest = @($artifacts | Where-Object { $_.name -ceq $script:Stage44TrustedEvidenceManifestArtifact })
        if ($unexpectedManifest.Count -ne 0) { throw 'STAGE44_EVIDENCE_MANIFEST_ALREADY_EXISTS_DURING_ADJUDICATION' }
    }

    return [pscustomobject]@{
        Evidence = $evidence
        ManifestValues = $manifest
        Run = $run
        JobSet = $jobSet
        ArtifactDigests = [ordered]@{
            Stage44 = $stage44Payload.Digest
            Stage43 = $stage43Payload.Digest
            Classifier = $classifierPayload.Digest
            MetadataState = $metadataStatePayload.Digest
            Finalizer = $finalizerPayload.Digest
        }
    }
}
