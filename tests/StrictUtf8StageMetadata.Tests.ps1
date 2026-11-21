Set-StrictMode -Version Latest
$strictUtf8MetadataRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
. (Join-Path $strictUtf8MetadataRoot 'src/StrictUtf8StageMetadata.ps1')

function New-StrictUtf8TestBytes {
    param([string]$Text, [switch]$WithBom)
    $encoding = [System.Text.UTF8Encoding]::new($false, $true)
    [byte[]]$body = $encoding.GetBytes($Text)
    if (-not $WithBom) { return ,$body }

    [byte[]]$combined = New-Object byte[] ($body.Length + 3)
    $combined[0] = 0xEF
    $combined[1] = 0xBB
    $combined[2] = 0xBF
    if ($body.Length -gt 0) {
        [System.Array]::Copy($body, 0, $combined, 3, $body.Length)
    }
    return ,$combined
}

function Assert-StrictUtf8Failure {
    param(
        [object]$Result,
        [string]$ReasonCode,
        [string]$Name,
        [object]$LineNumber = $null,
        [string]$Key = $null
    )
    Assert-StageTrue -Condition (-not [bool]$Result.Success) -Name ($Name + ' rejected')
    Assert-StageEqual -Expected $ReasonCode -Actual $Result.ReasonCode -Name ($Name + ' reason')
    if ($null -ne $LineNumber) {
        Assert-StageEqual -Expected $LineNumber -Actual $Result.LineNumber -Name ($Name + ' line')
    }
    if ($null -ne $Key) {
        Assert-StageEqual -Expected $Key -Actual $Result.Key -Name ($Name + ' key')
    }
    Assert-StageEqual -Expected 0 -Actual $Result.Values.Count -Name ($Name + ' exposes no partial map')
}

$lf = [string][char]10
$cr = [string][char]13
$validText = 'A=1' + $lf + 'B=two' + $lf
$validBytes = New-StrictUtf8TestBytes -Text $validText
$validBefore = [System.Convert]::ToBase64String($validBytes)
$valid = ConvertFrom-StrictStageMetadataBytes -Bytes $validBytes -RequiredKeys @('A', 'B')
Assert-StageTrue -Condition $valid.Success -Name 'Valid LF input accepted'
Assert-StageEqual -Expected 'OK' -Actual $valid.ReasonCode -Name 'Valid LF reason'
Assert-StageEqual -Expected 'LF' -Actual $valid.LineEnding -Name 'LF detected'
Assert-StageEqual -Expected '1' -Actual $valid.Values['A'] -Name 'First value preserved'
Assert-StageEqual -Expected 'two' -Actual $valid.Values['B'] -Name 'Second value preserved'
Assert-StageEqual -Expected $validBefore -Actual ([System.Convert]::ToBase64String($validBytes)) -Name 'Parser does not mutate input bytes'

$crlfText = 'A=1' + $cr + $lf + 'B=2' + $cr + $lf
$crlf = ConvertFrom-StrictStageMetadataBytes -Bytes (New-StrictUtf8TestBytes -Text $crlfText) -RequiredKeys @('A', 'B')
Assert-StageTrue -Condition $crlf.Success -Name 'Valid CRLF input accepted'
Assert-StageEqual -Expected 'CRLF' -Actual $crlf.LineEnding -Name 'CRLF detected'

$bom = ConvertFrom-StrictStageMetadataBytes -Bytes (New-StrictUtf8TestBytes -Text $validText -WithBom) -RequiredKeys @('A', 'B')
Assert-StageTrue -Condition $bom.Success -Name 'One leading UTF-8 BOM accepted'
Assert-StageTrue -Condition $bom.BomPresent -Name 'Leading BOM recorded'

$noFinalNewline = ConvertFrom-StrictStageMetadataBytes -Bytes (New-StrictUtf8TestBytes -Text 'A=1') -RequiredKeys @('A')
Assert-StageTrue -Condition $noFinalNewline.Success -Name 'Missing final newline accepted'
Assert-StageEqual -Expected 'NONE' -Actual $noFinalNewline.LineEnding -Name 'No line ending identified'

$blankLines = ConvertFrom-StrictStageMetadataBytes -Bytes (New-StrictUtf8TestBytes -Text ($lf + 'A=1' + $lf + $lf + 'B=2' + $lf)) -RequiredKeys @('A', 'B')
Assert-StageTrue -Condition $blankLines.Success -Name 'Empty lines ignored'
Assert-StageEqual -Expected 2 -Actual $blankLines.Values.Count -Name 'Blank lines add no keys'

$equalsText = 'VALUE=alpha=beta=gamma'
$equalsResult = ConvertFrom-StrictStageMetadataBytes -Bytes (New-StrictUtf8TestBytes -Text $equalsText) -RequiredKeys @('VALUE')
Assert-StageEqual -Expected 'alpha=beta=gamma' -Actual $equalsResult.Values['VALUE'] -Name 'Split only at first equals'

$spaceText = 'VALUE= leading and trailing '
$spaceResult = ConvertFrom-StrictStageMetadataBytes -Bytes (New-StrictUtf8TestBytes -Text $spaceText) -RequiredKeys @('VALUE')
Assert-StageEqual -Expected ' leading and trailing ' -Actual $spaceResult.Values['VALUE'] -Name 'Value whitespace preserved exactly'

$hebrewValue = ([char]0x05D8).ToString() + [char]0x05D2 + [char]0x05DC + [char]0x05D5 + [char]0x05D2 + ' / Filipino'
$unicodeResult = ConvertFrom-StrictStageMetadataBytes -Bytes (New-StrictUtf8TestBytes -Text ('NATURAL_LANGUAGE=' + $hebrewValue)) -RequiredKeys @('NATURAL_LANGUAGE')
Assert-StageTrue -Condition $unicodeResult.Success -Name 'Unicode value accepted'
Assert-StageEqual -Expected $hebrewValue -Actual $unicodeResult.Values['NATURAL_LANGUAGE'] -Name 'Unicode value preserved ordinally'

$duplicateSame = ConvertFrom-StrictStageMetadataBytes -Bytes (New-StrictUtf8TestBytes -Text ('A=1' + $lf + 'A=1' + $lf)) -RequiredKeys @()
Assert-StrictUtf8Failure -Result $duplicateSame -ReasonCode 'DUPLICATE_KEY' -Name 'Identical duplicate' -LineNumber 2 -Key 'A'

$duplicateDifferent = ConvertFrom-StrictStageMetadataBytes -Bytes (New-StrictUtf8TestBytes -Text ('A=1' + $lf + 'A=2')) -RequiredKeys @()
Assert-StrictUtf8Failure -Result $duplicateDifferent -ReasonCode 'DUPLICATE_KEY' -Name 'Contradictory duplicate' -LineNumber 2 -Key 'A'

$malformed = ConvertFrom-StrictStageMetadataBytes -Bytes (New-StrictUtf8TestBytes -Text ('A=1' + $lf + 'not a pair' + $lf + 'B=2')) -RequiredKeys @()
Assert-StrictUtf8Failure -Result $malformed -ReasonCode 'MALFORMED_LINE' -Name 'Missing equals' -LineNumber 2

$leadingSpace = ConvertFrom-StrictStageMetadataBytes -Bytes (New-StrictUtf8TestBytes -Text ' A=1') -RequiredKeys @()
Assert-StrictUtf8Failure -Result $leadingSpace -ReasonCode 'MALFORMED_LINE' -Name 'Leading key whitespace' -LineNumber 1

$colon = ConvertFrom-StrictStageMetadataBytes -Bytes (New-StrictUtf8TestBytes -Text 'A:1') -RequiredKeys @()
Assert-StrictUtf8Failure -Result $colon -ReasonCode 'MALFORMED_LINE' -Name 'Colon separator' -LineNumber 1

$lowerKey = ConvertFrom-StrictStageMetadataBytes -Bytes (New-StrictUtf8TestBytes -Text 'lower=1') -RequiredKeys @()
Assert-StrictUtf8Failure -Result $lowerKey -ReasonCode 'MALFORMED_LINE' -Name 'Lowercase key rejected' -LineNumber 1

$missing = ConvertFrom-StrictStageMetadataBytes -Bytes (New-StrictUtf8TestBytes -Text 'A=1') -RequiredKeys @('A', 'B')
Assert-StrictUtf8Failure -Result $missing -ReasonCode 'MISSING_REQUIRED_KEY' -Name 'Required key missing' -Key 'B'

$invalidRequired = ConvertFrom-StrictStageMetadataBytes -Bytes (New-StrictUtf8TestBytes -Text 'A=1') -RequiredKeys @('bad-key')
Assert-StrictUtf8Failure -Result $invalidRequired -ReasonCode 'INVALID_REQUIRED_KEY' -Name 'Invalid required-key contract' -Key 'bad-key'

$empty = ConvertFrom-StrictStageMetadataBytes -Bytes ([byte[]]@()) -RequiredKeys @()
Assert-StrictUtf8Failure -Result $empty -ReasonCode 'EMPTY_INPUT' -Name 'Empty input'

$mixedText = 'A=1' + $cr + $lf + 'B=2' + $lf
$mixed = ConvertFrom-StrictStageMetadataBytes -Bytes (New-StrictUtf8TestBytes -Text $mixedText) -RequiredKeys @()
Assert-StrictUtf8Failure -Result $mixed -ReasonCode 'MIXED_LINE_ENDINGS' -Name 'Mixed LF and CRLF'

$standaloneCr = ConvertFrom-StrictStageMetadataBytes -Bytes (New-StrictUtf8TestBytes -Text ('A=1' + $cr + 'B=2')) -RequiredKeys @()
Assert-StrictUtf8Failure -Result $standaloneCr -ReasonCode 'STANDALONE_CR' -Name 'Standalone CR' -LineNumber 1

$tab = ConvertFrom-StrictStageMetadataBytes -Bytes (New-StrictUtf8TestBytes -Text ('A=1' + [char]9 + 'B=2')) -RequiredKeys @()
Assert-StrictUtf8Failure -Result $tab -ReasonCode 'FORBIDDEN_CONTROL' -Name 'Tab control rejected'

$nul = ConvertFrom-StrictStageMetadataBytes -Bytes (New-StrictUtf8TestBytes -Text ('A=1' + [char]0 + 'B=2')) -RequiredKeys @()
Assert-StrictUtf8Failure -Result $nul -ReasonCode 'FORBIDDEN_CONTROL' -Name 'NUL control rejected'

$del = ConvertFrom-StrictStageMetadataBytes -Bytes (New-StrictUtf8TestBytes -Text ('A=1' + [char]0x007F + 'B=2')) -RequiredKeys @()
Assert-StrictUtf8Failure -Result $del -ReasonCode 'FORBIDDEN_CONTROL' -Name 'DEL control rejected'

$nel = ConvertFrom-StrictStageMetadataBytes -Bytes (New-StrictUtf8TestBytes -Text ('A=1' + [char]0x0085 + 'B=2')) -RequiredKeys @()
Assert-StrictUtf8Failure -Result $nel -ReasonCode 'FORBIDDEN_CONTROL' -Name 'NEL separator rejected'

$lineSeparator = ConvertFrom-StrictStageMetadataBytes -Bytes (New-StrictUtf8TestBytes -Text ('A=1' + [char]0x2028 + 'B=2')) -RequiredKeys @()
Assert-StrictUtf8Failure -Result $lineSeparator -ReasonCode 'FORBIDDEN_CONTROL' -Name 'Unicode line separator rejected'

$paragraphSeparator = ConvertFrom-StrictStageMetadataBytes -Bytes (New-StrictUtf8TestBytes -Text ('A=1' + [char]0x2029 + 'B=2')) -RequiredKeys @()
Assert-StrictUtf8Failure -Result $paragraphSeparator -ReasonCode 'FORBIDDEN_CONTROL' -Name 'Unicode paragraph separator rejected'

$interiorBom = ConvertFrom-StrictStageMetadataBytes -Bytes (New-StrictUtf8TestBytes -Text ('A=1' + [char]0xFEFF + 'B=2')) -RequiredKeys @()
Assert-StrictUtf8Failure -Result $interiorBom -ReasonCode 'INTERIOR_BOM' -Name 'Interior BOM rejected'

$doubleBom = ConvertFrom-StrictStageMetadataBytes -Bytes (New-StrictUtf8TestBytes -Text ([char]0xFEFF + 'A=1') -WithBom) -RequiredKeys @()
Assert-StrictUtf8Failure -Result $doubleBom -ReasonCode 'INTERIOR_BOM' -Name 'Second leading BOM rejected'

$invalidSequences = @(
    [byte[]](0x80),
    [byte[]](0xE2, 0x82),
    [byte[]](0xC0, 0xAF),
    [byte[]](0xED, 0xA0, 0x80),
    [byte[]](0xF4, 0x90, 0x80, 0x80)
)
$invalidNames = @('Lone continuation byte', 'Truncated multibyte sequence', 'Overlong sequence', 'UTF-8 encoded surrogate', 'Code point above U+10FFFF')
for ($i = 0; $i -lt $invalidSequences.Count; $i++) {
    $invalidResult = ConvertFrom-StrictStageMetadataBytes -Bytes $invalidSequences[$i] -RequiredKeys @()
    Assert-StrictUtf8Failure -Result $invalidResult -ReasonCode 'INVALID_UTF8' -Name $invalidNames[$i]
}

$invalidAfterLf = [byte[]](0x41, 0x3D, 0x31, 0x0A, 0xFF)
$invalidLineResult = ConvertFrom-StrictStageMetadataBytes -Bytes $invalidAfterLf -RequiredKeys @()
Assert-StrictUtf8Failure -Result $invalidLineResult -ReasonCode 'INVALID_UTF8' -Name 'Invalid UTF-8 line location' -LineNumber 2

$invalidAfterTwoLines = [byte[]](0x41, 0x3D, 0x31, 0x0A, 0x42, 0x3D, 0x32, 0x0A, 0xFF)
$invalidThird = ConvertFrom-StrictStageMetadataBytes -Bytes $invalidAfterTwoLines -RequiredKeys @()
Assert-StrictUtf8Failure -Result $invalidThird -ReasonCode 'INVALID_UTF8' -Name 'Invalid UTF-8 after two lines' -LineNumber 3

$invalidFirst = ConvertFrom-StrictStageMetadataBytes -Bytes ([byte[]](0xFF, 0x0A, 0x41, 0x3D, 0x31)) -RequiredKeys @()
Assert-StrictUtf8Failure -Result $invalidFirst -ReasonCode 'INVALID_UTF8' -Name 'Invalid UTF-8 first line' -LineNumber 1

$strictMetadataPath = Join-Path $strictUtf8MetadataRoot 'DEVELOPMENT_STAGE.md'
[byte[]]$strictMetadataBytes = [System.IO.File]::ReadAllBytes($strictMetadataPath)
$strictMetadataResult = ConvertFrom-StrictStageMetadataBytes -Bytes $strictMetadataBytes -RequiredKeys @(
    'TOTAL_STAGES', 'CURRENT_STAGE', 'CURRENT_KIND', 'CURRENT_DISCOVERY',
    'LAST_COMPLETED_STAGE', 'NATURAL_LANGUAGE', 'STAGE42_RUNTIME_VERIFICATION'
)
Assert-StageTrue -Condition $strictMetadataResult.Success -Name 'Pinned Stage42 metadata parses'
Assert-StageEqual -Expected 728 -Actual $strictMetadataResult.Values.Count -Name 'Pinned metadata has exactly 728 keys'
Assert-StageEqual -Expected '55' -Actual $strictMetadataResult.Values['TOTAL_STAGES'] -Name 'Pinned total stage count'
Assert-StageEqual -Expected '42' -Actual $strictMetadataResult.Values['CURRENT_STAGE'] -Name 'Pinned current stage'
Assert-StageEqual -Expected 'DISCOVERY' -Actual $strictMetadataResult.Values['CURRENT_KIND'] -Name 'Pinned current kind'
Assert-StageEqual -Expected '27' -Actual $strictMetadataResult.Values['CURRENT_DISCOVERY'] -Name 'Pinned current discovery'
Assert-StageEqual -Expected '42' -Actual $strictMetadataResult.Values['LAST_COMPLETED_STAGE'] -Name 'Pinned completed stage'
Assert-StageEqual -Expected 'EVIDENCE_ONLY_CONFIRMED' -Actual $strictMetadataResult.Values['STAGE42_RUNTIME_VERIFICATION'] -Name 'Pinned Stage42 state'
Assert-StageEqual -Expected $hebrewValue -Actual $strictMetadataResult.Values['NATURAL_LANGUAGE'] -Name 'Pinned non-ASCII language value'
$stage43Keys = @($strictMetadataResult.Values.Keys | Where-Object { $_.StartsWith('STAGE43_', [System.StringComparison]::Ordinal) })
Assert-StageEqual -Expected 0 -Actual $stage43Keys.Count -Name 'Pinned Stage42 has no Stage43 lifecycle keys'
# Git checkout on Windows can materialize CRLF bytes from an LF Git blob.
# Verify the immutable blob identity from the commit, not the worktree bytes.
# The worktree bytes were parsed and checked independently above.
$gitBlobOutput = @(& git -C $strictUtf8MetadataRoot rev-parse 'HEAD:DEVELOPMENT_STAGE.md')
if ($LASTEXITCODE -ne 0 -or $gitBlobOutput.Count -ne 1) {
    throw 'Unable to resolve committed metadata blob from HEAD'
}
$metadataGitBlob = ([string]$gitBlobOutput[0]).Trim()
Assert-StageEqual -Expected 'a3f53b67e4445bdc835179cd484fe27b3e2648f7' -Actual $metadataGitBlob -Name 'Pinned Stage42 commit has exact metadata blob'

$tempMetadataPath = Join-Path ([System.IO.Path]::GetTempPath()) ('strict-stage-metadata-' + [guid]::NewGuid().ToString('N') + '.bin')
$missingMetadataPath = $tempMetadataPath + '.missing'
try {
    [System.IO.File]::WriteAllBytes($tempMetadataPath, $validBytes)
    $beforeRead = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($tempMetadataPath))
    $fileRead = Read-StrictStageMetadataFile -Path $tempMetadataPath -RequiredKeys @('A', 'B')
    $afterRead = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($tempMetadataPath))
    Assert-StageTrue -Condition $fileRead.Success -Name 'File reader accepts valid file'
    Assert-StageEqual -Expected $beforeRead -Actual $afterRead -Name 'Valid file remains byte-identical after read'

    [System.IO.File]::WriteAllBytes($tempMetadataPath, $invalidAfterLf)
    $beforeBadRead = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($tempMetadataPath))
    $badFileRead = Read-StrictStageMetadataFile -Path $tempMetadataPath -RequiredKeys @()
    $afterBadRead = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($tempMetadataPath))
    Assert-StrictUtf8Failure -Result $badFileRead -ReasonCode 'INVALID_UTF8' -Name 'Invalid file read'
    Assert-StageEqual -Expected $beforeBadRead -Actual $afterBadRead -Name 'Invalid file remains byte-identical after read'

    $ioFailure = Read-StrictStageMetadataFile -Path $missingMetadataPath -RequiredKeys @()
    Assert-StrictUtf8Failure -Result $ioFailure -ReasonCode 'IO_ERROR' -Name 'Missing file fails closed'
} finally {
    if ([System.IO.File]::Exists($tempMetadataPath)) {
        [System.IO.File]::Delete($tempMetadataPath)
    }
}

