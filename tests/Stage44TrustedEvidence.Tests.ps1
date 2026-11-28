Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $root 'src/Stage44TrustedEvidence.ps1')

$script:Stage44TrustedEvidencePassed = 0

function Confirm-Stage44EvidenceTest {
    param([bool]$Condition,[string]$Name)
    if (-not $Condition) { throw ('Stage44 trusted evidence test failed: ' + $Name) }
    $script:Stage44TrustedEvidencePassed++
}

function Expect-Stage44EvidenceThrow {
    param([scriptblock]$Action,[string]$Name)
    $thrown = $false
    try {
        & $Action
    } catch {
        $thrown = $true
    }
    if (-not $thrown) { throw ('Stage44 trusted evidence rejection test failed: ' + $Name) }
    $script:Stage44TrustedEvidencePassed++
}

function New-Stage44EvidenceTestZip {
    param([object[]]$Items)
    Add-Type -AssemblyName System.IO.Compression
    $memory = [System.IO.MemoryStream]::new()
    $archive = [System.IO.Compression.ZipArchive]::new(
        $memory,
        [System.IO.Compression.ZipArchiveMode]::Create,
        $true
    )
    try {
        foreach ($item in $Items) {
            $entry = $archive.CreateEntry([string]$item.Name)
            $stream = $entry.Open()
            try {
                $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes([string]$item.Text)
                $stream.Write($bytes, 0, $bytes.Length)
            } finally {
                $stream.Dispose()
            }
        }
    } finally {
        $archive.Dispose()
    }
    $bytes = $memory.ToArray()
    $memory.Dispose()
    return ,$bytes
}

$crlf = [string][char]13 + [char]10
$lf = [string][char]10
$lineText = 'A=one' + $crlf + 'B=two' + $crlf
Confirm-Stage44EvidenceTest ((Get-Stage44UniqueLineValue -Text $lineText -Key 'A') -ceq 'one') 'unique exact transcript key'
Expect-Stage44EvidenceThrow { Get-Stage44UniqueLineValue -Text ('A=one' + $lf + 'A=two' + $lf) -Key 'A' } 'duplicate transcript key'
Expect-Stage44EvidenceThrow { Get-Stage44UniqueLineValue -Text ('B=two' + $lf) -Key 'A' } 'missing transcript key'

$baseJobs = @()
foreach ($name in $script:Stage44TrustedEvidenceRequiredJobs) {
    $baseJobs += [pscustomobject]@{ name=$name; status='completed'; conclusion='success'; id=1; steps=@() }
}
$currentJobs = @($baseJobs + [pscustomobject]@{
    name=$script:Stage44TrustedEvidenceJobName; status='in_progress'; conclusion=$null; id=99; steps=@()
})
$completedJobs = @($baseJobs + [pscustomobject]@{
    name=$script:Stage44TrustedEvidenceJobName; status='completed'; conclusion='success'; id=99; steps=@()
})
$jobSet = Assert-Stage44EvidenceJobSet -Jobs $currentJobs -CurrentRun
Confirm-Stage44EvidenceTest ($jobSet.Count -eq 19) 'current exact 18+adjudicator job set'
$completedSet = Assert-Stage44EvidenceJobSet -Jobs $completedJobs
Confirm-Stage44EvidenceTest ($completedSet.Count -eq 19) 'completed exact 18+adjudicator job set'

$missingJob = @($currentJobs | Where-Object { $_.name -cne $script:Stage44TrustedEvidenceRequiredJobs[0] })
Expect-Stage44EvidenceThrow { Assert-Stage44EvidenceJobSet -Jobs $missingJob -CurrentRun } 'missing canonical job'
$failedJob = @($currentJobs)
$failedJob[0] = [pscustomobject]@{ name=$failedJob[0].name; status='completed'; conclusion='failure'; id=1; steps=@() }
Expect-Stage44EvidenceThrow { Assert-Stage44EvidenceJobSet -Jobs $failedJob -CurrentRun } 'failed canonical job'
$duplicateJob = @($currentJobs + $currentJobs[0])
Expect-Stage44EvidenceThrow { Assert-Stage44EvidenceJobSet -Jobs $duplicateJob -CurrentRun } 'duplicate canonical job'
$unknownJob = @($currentJobs)
$unknownJob[-1] = [pscustomobject]@{ name='unrecognized job'; status='in_progress'; conclusion=$null; id=99; steps=@() }
Expect-Stage44EvidenceThrow { Assert-Stage44EvidenceJobSet -Jobs $unknownJob -CurrentRun } 'unknown extra job'
$wrongCurrent = @($completedJobs)
Expect-Stage44EvidenceThrow { Assert-Stage44EvidenceJobSet -Jobs $wrongCurrent -CurrentRun } 'current adjudicator must be in progress'
Expect-Stage44EvidenceThrow { Assert-Stage44EvidenceJobSet -Jobs $currentJobs } 'completed adjudicator must be successful'

$validArtifact = [pscustomobject]@{
    id=123
    expired=$false
    digest=('sha256:' + ('a' * 64))
    workflow_run=[pscustomobject]@{ id=456; head_sha=('b' * 40); head_branch='PowerShell+Tagalog' }
}
Assert-Stage44ArtifactBinding -Artifact $validArtifact -RunId 456 -ExpectedSha ('b' * 40) -ExpectedBranch 'PowerShell+Tagalog'
Confirm-Stage44EvidenceTest $true 'artifact run/SHA/branch/digest binding'
$wrongRun = [pscustomobject]@{ id=123; expired=$false; digest=$validArtifact.digest; workflow_run=[pscustomobject]@{ id=457; head_sha=('b' * 40); head_branch='PowerShell+Tagalog' } }
Expect-Stage44EvidenceThrow { Assert-Stage44ArtifactBinding -Artifact $wrongRun -RunId 456 -ExpectedSha ('b' * 40) -ExpectedBranch 'PowerShell+Tagalog' } 'artifact wrong run'
$wrongSha = [pscustomobject]@{ id=123; expired=$false; digest=$validArtifact.digest; workflow_run=[pscustomobject]@{ id=456; head_sha=('c' * 40); head_branch='PowerShell+Tagalog' } }
Expect-Stage44EvidenceThrow { Assert-Stage44ArtifactBinding -Artifact $wrongSha -RunId 456 -ExpectedSha ('b' * 40) -ExpectedBranch 'PowerShell+Tagalog' } 'artifact wrong SHA'
$wrongBranch = [pscustomobject]@{ id=123; expired=$false; digest=$validArtifact.digest; workflow_run=[pscustomobject]@{ id=456; head_sha=('b' * 40); head_branch='main' } }
Expect-Stage44EvidenceThrow { Assert-Stage44ArtifactBinding -Artifact $wrongBranch -RunId 456 -ExpectedSha ('b' * 40) -ExpectedBranch 'PowerShell+Tagalog' } 'artifact wrong branch'
$expiredArtifact = [pscustomobject]@{ id=123; expired=$true; digest=$validArtifact.digest; workflow_run=$validArtifact.workflow_run }
Expect-Stage44EvidenceThrow { Assert-Stage44ArtifactBinding -Artifact $expiredArtifact -RunId 456 -ExpectedSha ('b' * 40) -ExpectedBranch 'PowerShell+Tagalog' } 'expired artifact'
$badDigest = [pscustomobject]@{ id=123; expired=$false; digest='sha256:xyz'; workflow_run=$validArtifact.workflow_run }
Expect-Stage44EvidenceThrow { Assert-Stage44ArtifactBinding -Artifact $badDigest -RunId 456 -ExpectedSha ('b' * 40) -ExpectedBranch 'PowerShell+Tagalog' } 'malformed artifact digest'

$validEntries = [System.Collections.Generic.Dictionary[string,byte[]]]::new([System.StringComparer]::Ordinal)
$validEntries.Add('one.txt',[System.Text.UTF8Encoding]::new($false).GetBytes('1'))
$validEntries.Add('nested/two.txt',[System.Text.UTF8Encoding]::new($false).GetBytes('2'))
Assert-Stage44ExactEntrySet -Entries $validEntries -ExpectedNames @('one.txt','nested/two.txt')
Confirm-Stage44EvidenceTest $true 'exact ZIP entry set'
Expect-Stage44EvidenceThrow { Assert-Stage44ExactEntrySet -Entries $validEntries -ExpectedNames @('one.txt') } 'missing ZIP entry'
Expect-Stage44EvidenceThrow { Assert-Stage44ExactEntrySet -Entries $validEntries -ExpectedNames @('one.txt','nested/two.txt','extra.txt') } 'unexpected ZIP entry'

$safeZip = New-Stage44EvidenceTestZip -Items @(
    [pscustomobject]@{ Name='safe.txt'; Text='safe' },
    [pscustomobject]@{ Name='nested/value.txt'; Text='value' }
)
$safeEntries = Read-Stage44ZipEntries -Bytes $safeZip
Confirm-Stage44EvidenceTest ($safeEntries.Count -eq 2 -and (Get-Stage44TextFromBytes -Bytes $safeEntries['safe.txt']) -ceq 'safe') 'safe ZIP parsing'
$traversalZip = New-Stage44EvidenceTestZip -Items @([pscustomobject]@{ Name='../escape.txt'; Text='bad' })
Expect-Stage44EvidenceThrow { Read-Stage44ZipEntries -Bytes $traversalZip } 'ZIP path traversal'
$duplicateZip = New-Stage44EvidenceTestZip -Items @(
    [pscustomobject]@{ Name='same.txt'; Text='one' },
    [pscustomobject]@{ Name='same.txt'; Text='two' }
)
Expect-Stage44EvidenceThrow { Read-Stage44ZipEntries -Bytes $duplicateZip } 'duplicate ZIP entry'

$expectedManifest = [ordered]@{ PROJECT_ID='PC-BRANCH-POWERSHELL-TAGALOG'; STAGE44_PHASE='RESEARCH_PREFLIGHT'; STAGE44_PREFLIGHT_ASSERTIONS_PASSED='5027' }
$matchingManifest = [ordered]@{ PROJECT_ID='PC-BRANCH-POWERSHELL-TAGALOG'; STAGE44_PHASE='RESEARCH_PREFLIGHT'; STAGE44_PREFLIGHT_ASSERTIONS_PASSED='5027' }
Assert-Stage44ManifestMatches -Actual $matchingManifest -Expected $expectedManifest
Confirm-Stage44EvidenceTest $true 'exact manifest binding'
$mismatchedManifest = [ordered]@{ PROJECT_ID='PC-BRANCH-POWERSHELL-TAGALOG'; STAGE44_PHASE='RESEARCH_PREFLIGHT'; STAGE44_PREFLIGHT_ASSERTIONS_PASSED='5026' }
Expect-Stage44EvidenceThrow { Assert-Stage44ManifestMatches -Actual $mismatchedManifest -Expected $expectedManifest } 'manifest value mismatch'
$extraManifest = [ordered]@{ PROJECT_ID='PC-BRANCH-POWERSHELL-TAGALOG'; STAGE44_PHASE='RESEARCH_PREFLIGHT'; STAGE44_PREFLIGHT_ASSERTIONS_PASSED='5027'; EXTRA='unexpected' }
Expect-Stage44EvidenceThrow { Assert-Stage44ManifestMatches -Actual $extraManifest -Expected $expectedManifest } 'manifest extra key'

$validMetadataBytes = [System.Text.UTF8Encoding]::new($false).GetBytes('A=one' + $crlf + 'B=two' + $crlf)
$validMetadata = ConvertFrom-Stage44EvidenceMetadataBytes -Bytes $validMetadataBytes -RequiredKeys @('A','B')
Confirm-Stage44EvidenceTest ($validMetadata['A'] -ceq 'one' -and $validMetadata['B'] -ceq 'two') 'strict evidence metadata parsing'
$duplicateMetadataBytes = [System.Text.UTF8Encoding]::new($false).GetBytes('A=one' + $lf + 'A=two' + $lf)
Expect-Stage44EvidenceThrow { ConvertFrom-Stage44EvidenceMetadataBytes -Bytes $duplicateMetadataBytes -RequiredKeys @('A') } 'duplicate metadata key'
$invalidUtf8 = [byte[]](0xC3,0x28)
Expect-Stage44EvidenceThrow { Get-Stage44TextFromBytes -Bytes $invalidUtf8 } 'invalid UTF-8'
$bomText = [byte[]](0xEF,0xBB,0xBF,0x41,0x3D,0x31)
Confirm-Stage44EvidenceTest ((Get-Stage44TextFromBytes -Bytes $bomText) -ceq 'A=1') 'single leading UTF-8 BOM'

Write-Host ('STAGE44_TRUSTED_EVIDENCE_CASES_PASSED=' + $script:Stage44TrustedEvidencePassed)
Write-Host 'STAGE44_TRUSTED_EVIDENCE_CASES_FAILED=0'
Write-Host 'STAGE44_TRUSTED_EVIDENCE_RESULT=PASS_SYNTHETIC_GATES'
