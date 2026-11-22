Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Isolated opt-in negative suite; not wired to Stage43 or CI.
$repo = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
. (Join-Path $repo 'src/FrozenStage42MetadataComparator.ps1')
$script:passed = 0
$pin = 'a3f53b67e4445bdc835179cd484fe27b3e2648f7'
$script:originalReader = (Get-Item Function:Get-FrozenStage42BlobBytes).ScriptBlock
$script:originalParser = (Get-Item Function:ConvertFrom-StrictStageMetadataBytes).ScriptBlock
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('frozen42_neg_' + [guid]::NewGuid().ToString('N'))

function Assert-FailClosed {
    param(
        [string]$Name,
        [AllowNull()][byte[]]$Candidate,
        [AllowNull()][string]$Root,
        [bool]$Success,
        [string]$Reason,
        [string]$Parsed = $null
    )
    $before = if ($null -eq $Candidate) { $null } else { [Convert]::ToBase64String($Candidate) }
    $actual = Test-FrozenStage42MetadataBytes -CandidateBytes $Candidate -RepositoryRoot $Root
    if ($null -eq $actual -or [bool]$actual.Success -ne $Success -or $actual.ReasonCode -cne $Reason) {
        throw ($Name + ': expected ' + $Success + '/' + $Reason +
            '; observed ' + $actual.Success + '/' + $actual.ReasonCode)
    }
    if ($null -ne $Parsed -and $actual.ParsedReason -cne $Parsed) {
        throw ($Name + ': incorrect parser failure reason: ' + $actual.ParsedReason)
    }
    if ($actual.PinnedGitBlob -cne $pin) {
        throw ($Name + ': pinned Git blob missing or changed')
    }
    $after = if ($null -eq $Candidate) { $null } else { [Convert]::ToBase64String($Candidate) }
    if ($after -cne $before) { throw ($Name + ': candidate mutated') }
    $script:passed++
    Write-Output ('CASE=' + $Name + ';STATUS=PASS;REASON=' + $Reason)
}

try {
    [byte[]]$valid = Get-FrozenStage42BlobBytes -RepositoryRoot $repo
    if ($valid.Length -eq 0) { throw 'Precondition: missing pinned baseline' }
    Assert-FailClosed 'F00-genuine-baseline' $valid $repo $true 'OK'
    Assert-FailClosed 'F01-null-candidate' $null $repo $false 'INVALID_INPUT'
    Assert-FailClosed 'F02-empty-candidate' ([byte[]]@()) $repo $false 'CANDIDATE_LEXICAL_INVALID' 'EMPTY_INPUT'
    Assert-FailClosed 'F03-missing-root' $valid (Join-Path $repo ('nonexistent_' + [guid]::NewGuid().ToString('N'))) $false 'BASELINE_UNAVAILABLE'
    Assert-FailClosed 'F04-file-as-root' $valid $PSCommandPath $false 'BASELINE_UNAVAILABLE'
    $null = New-Item -ItemType Directory -Path $temporaryRoot
    Assert-FailClosed 'F05-existing-nongit-dir' $valid $temporaryRoot $false 'BASELINE_UNAVAILABLE'
    Assert-FailClosed 'F06-quoted-invalid-root' $valid ($repo + '"') $false 'BASELINE_UNAVAILABLE'
    Assert-FailClosed 'F07-empty-root' $valid '' $false 'BASELINE_UNAVAILABLE'

    Set-Item Function:Get-FrozenStage42BlobBytes -Value {
        param([string]$RepositoryRoot)
        throw 'MOCK_GIT_CAT_FILE_UNREADABLE'
    }
    Assert-FailClosed 'F08-git-read-exception' $valid $repo $false 'BASELINE_UNAVAILABLE'

    Set-Item Function:Get-FrozenStage42BlobBytes -Value {
        param([string]$RepositoryRoot)
        return ,([byte[]]@(0xFF, 0xFE))
    }
    Assert-FailClosed 'F09-invalid-baseline-utf8' $valid $repo $false 'BASELINE_INVALID'

    Set-Item Function:Get-FrozenStage42BlobBytes -Value {
        param([string]$RepositoryRoot)
        return ,([System.Text.Encoding]::ASCII.GetBytes('UNRELATED_KEY=1'))
    }
    Assert-FailClosed 'F10-baseline-missing-keys' $valid $repo $false 'BASELINE_INVALID'

    $utf8 = [System.Text.UTF8Encoding]::new($false, $true)
    $baseText = $utf8.GetString($valid)
    if (-not $baseText.Contains('CURRENT_STAGE=42')) { throw 'Precondition: Stage42 baseline not found' }
    $script:badBaseline = $utf8.GetBytes($baseText.Replace('CURRENT_STAGE=42', 'CURRENT_STAGE=41'))
    Set-Item Function:Get-FrozenStage42BlobBytes -Value {
        param([string]$RepositoryRoot)
        return ,$script:badBaseline
    }
    Assert-FailClosed 'F11-baseline-wrong-seal' $valid $repo $false 'BASELINE_INVALID'

    Set-Item Function:Get-FrozenStage42BlobBytes -Value $script:originalReader
    Set-Item Function:ConvertFrom-StrictStageMetadataBytes -Value {
        param([byte[]]$Bytes, [string[]]$RequiredKeys)
        throw 'MOCK_BASELINE_PARSER_EXCEPTION'
    }
    Assert-FailClosed 'F12-baseline-parser-exception' $valid $repo $false 'BASELINE_INVALID'

    $script:parserCalls = 0
    Set-Item Function:ConvertFrom-StrictStageMetadataBytes -Value {
        param([byte[]]$Bytes, [string[]]$RequiredKeys)
        $script:parserCalls++
        if ($script:parserCalls -eq 2) { throw 'MOCK_CANDIDATE_PARSER_EXCEPTION' }
        & $script:originalParser -Bytes $Bytes -RequiredKeys $RequiredKeys
    }
    Assert-FailClosed 'F13-candidate-parser-exception' $valid $repo $false 'CANDIDATE_LEXICAL_INVALID' 'PARSER_EXCEPTION'
    if ($script:parserCalls -ne 2) { throw 'Candidate parser mock not reached exactly twice' }

    Set-Item Function:ConvertFrom-StrictStageMetadataBytes -Value $script:originalParser
    Assert-FailClosed 'F14-reader-parser-restored' $valid $repo $true 'OK'
    [byte[]]$changed = $utf8.GetBytes($baseText.Replace('CURRENT_STAGE=42', 'CURRENT_STAGE=41'))
    Assert-FailClosed 'F15-modified-candidate-immutable' $changed $repo $false 'FROZEN_MAP_MISMATCH'

    if ($script:passed -ne 16) { throw ('Wrong case count: ' + $script:passed) }
    Write-Output ('FROZEN_STAGE42_FAILCLOSED_CASES_PASSED=' + $script:passed)
    Write-Output 'FROZEN_STAGE42_FAILCLOSED_RESULT=PASS'
    Write-Output 'STAGE43_ACTIVATION=NOT_ACTIVATED'
} catch {
    [Console]::Error.WriteLine('FROZEN_STAGE42_FAILCLOSED_RESULT=FAIL;ERROR=' + $_.Exception.Message)
    exit 1
} finally {
    Set-Item Function:Get-FrozenStage42BlobBytes -Value $script:originalReader
    Set-Item Function:ConvertFrom-StrictStageMetadataBytes -Value $script:originalParser
    if ([System.IO.Directory]::Exists($temporaryRoot)) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}
