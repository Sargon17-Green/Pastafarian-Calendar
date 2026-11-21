Set-StrictMode -Version Latest

function New-StrictStageMetadataDictionary {
    return [System.Collections.Generic.Dictionary[string,string]]::new([System.StringComparer]::Ordinal)
}

function Get-StrictStageMetadataSha256 {
    param([Parameter(Mandatory=$true)][AllowEmptyCollection()][byte[]]$Bytes)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $digest = $sha.ComputeHash($Bytes)
    } finally {
        $sha.Dispose()
    }
    return [System.BitConverter]::ToString($digest).Replace('-', '').ToLowerInvariant()
}

function Get-StrictStageMetadataByteLineNumber {
    param([AllowEmptyCollection()][byte[]]$Bytes, [int]$ByteIndex)
    if ($ByteIndex -lt 0) { return $null }
    $limit = [Math]::Min($ByteIndex, $Bytes.Length)
    $line = 1
    for ($i = 0; $i -lt $limit; $i++) {
        if ($Bytes[$i] -eq 10) { $line++ }
    }
    return $line
}

function Get-StrictStageMetadataTextLineNumber {
    param([string]$Text, [int]$CharacterIndex)
    if ($CharacterIndex -lt 0) { return $null }
    $limit = [Math]::Min($CharacterIndex, $Text.Length)
    $line = 1
    for ($i = 0; $i -lt $limit; $i++) {
        if ($Text[$i] -eq [char]10) { $line++ }
    }
    return $line
}

function New-StrictStageMetadataResult {
    param(
        [Parameter(Mandatory=$true)][bool]$Success,
        [Parameter(Mandatory=$true)][string]$ReasonCode,
        [object]$Values = $null,
        [string]$Key = $null,
        [object]$LineNumber = $null,
        [bool]$BomPresent = $false,
        [string]$LineEnding = 'UNKNOWN',
        [string]$InputSha256 = $null,
        [string]$Detail = $null
    )
    if ($null -eq $Values) { $Values = New-StrictStageMetadataDictionary }
    return [pscustomobject]@{
        Success = $Success
        ReasonCode = $ReasonCode
        Key = $Key
        LineNumber = $LineNumber
        BomPresent = $BomPresent
        LineEnding = $LineEnding
        InputSha256 = $InputSha256
        Values = $Values
        Detail = $Detail
    }
}

function ConvertFrom-StrictStageMetadataBytes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [byte[]]$Bytes,
        [AllowEmptyCollection()]
        [string[]]$RequiredKeys = @('TOTAL_STAGES', 'CURRENT_STAGE', 'LAST_COMPLETED_STAGE')
    )

    if ($null -eq $Bytes) {
        return New-StrictStageMetadataResult -Success $false -ReasonCode 'INVALID_INPUT'
    }

    $inputHash = Get-StrictStageMetadataSha256 -Bytes $Bytes
    if ($Bytes.Length -eq 0) {
        return New-StrictStageMetadataResult -Success $false -ReasonCode 'EMPTY_INPUT' -InputSha256 $inputHash
    }

    $bomPresent = $false
    $payloadOffset = 0
    if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF) {
        $bomPresent = $true
        $payloadOffset = 3
    }

    $payloadLength = $Bytes.Length - $payloadOffset
    [byte[]]$payload = New-Object byte[] $payloadLength
    if ($payloadLength -gt 0) {
        [System.Array]::Copy($Bytes, $payloadOffset, $payload, 0, $payloadLength)
    }

    $utf8 = [System.Text.UTF8Encoding]::new($false, $true)
    try {
        $text = $utf8.GetString($payload)
    } catch [System.Text.DecoderFallbackException] {
        $badLine = Get-StrictStageMetadataByteLineNumber -Bytes $payload -ByteIndex $_.Exception.Index
        return New-StrictStageMetadataResult -Success $false -ReasonCode 'INVALID_UTF8' -LineNumber $badLine -BomPresent $bomPresent -InputSha256 $inputHash -Detail ('byte_index=' + $_.Exception.Index)
    } catch {
        return New-StrictStageMetadataResult -Success $false -ReasonCode 'DECODE_ERROR' -BomPresent $bomPresent -InputSha256 $inputHash -Detail $_.Exception.GetType().FullName
    }

    $crlfCount = [System.Text.RegularExpressions.Regex]::Matches($text, "\r\n").Count
    $withoutCrlf = $text.Replace(([string][char]13 + [char]10), '')
    $standaloneCrIndex = $withoutCrlf.IndexOf([char]13)
    if ($standaloneCrIndex -ge 0) {
        $badLine = Get-StrictStageMetadataTextLineNumber -Text $withoutCrlf -CharacterIndex $standaloneCrIndex
        return New-StrictStageMetadataResult -Success $false -ReasonCode 'STANDALONE_CR' -LineNumber $badLine -BomPresent $bomPresent -InputSha256 $inputHash
    }

    $bareLfCount = [System.Text.RegularExpressions.Regex]::Matches($withoutCrlf, "\n").Count
    if ($crlfCount -gt 0 -and $bareLfCount -gt 0) {
        return New-StrictStageMetadataResult -Success $false -ReasonCode 'MIXED_LINE_ENDINGS' -BomPresent $bomPresent -LineEnding 'MIXED' -InputSha256 $inputHash
    }

    if ($crlfCount -gt 0) {
        $lineEnding = 'CRLF'
    } elseif ($bareLfCount -gt 0) {
        $lineEnding = 'LF'
    } else {
        $lineEnding = 'NONE'
    }

    $normalized = $text.Replace(([string][char]13 + [char]10), [string][char]10)
    $interiorBomIndex = $normalized.IndexOf([char]0xFEFF)
    if ($interiorBomIndex -ge 0) {
        $badLine = Get-StrictStageMetadataTextLineNumber -Text $normalized -CharacterIndex $interiorBomIndex
        return New-StrictStageMetadataResult -Success $false -ReasonCode 'INTERIOR_BOM' -LineNumber $badLine -BomPresent $bomPresent -LineEnding $lineEnding -InputSha256 $inputHash
    }

    $controlMatch = [System.Text.RegularExpressions.Regex]::Match($normalized, '[\x00-\x09\x0B-\x0C\x0E-\x1F\x7F\u0085\u2028\u2029]')
    if ($controlMatch.Success) {
        $badLine = Get-StrictStageMetadataTextLineNumber -Text $normalized -CharacterIndex $controlMatch.Index
        return New-StrictStageMetadataResult -Success $false -ReasonCode 'FORBIDDEN_CONTROL' -LineNumber $badLine -BomPresent $bomPresent -LineEnding $lineEnding -InputSha256 $inputHash
    }

    $values = New-StrictStageMetadataDictionary
    $lines = [System.Text.RegularExpressions.Regex]::Split($normalized, [string][char]10)
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        if ($line.Length -eq 0) { continue }

        $match = [System.Text.RegularExpressions.Regex]::Match(
            $line,
            '\A([A-Z][A-Z0-9_]*)=(.*)\z',
            [System.Text.RegularExpressions.RegexOptions]::CultureInvariant
        )
        if (-not $match.Success) {
            return New-StrictStageMetadataResult -Success $false -ReasonCode 'MALFORMED_LINE' -LineNumber ($i + 1) -BomPresent $bomPresent -LineEnding $lineEnding -InputSha256 $inputHash
        }

        $key = $match.Groups[1].Value
        if ($values.ContainsKey($key)) {
            return New-StrictStageMetadataResult -Success $false -ReasonCode 'DUPLICATE_KEY' -Key $key -LineNumber ($i + 1) -BomPresent $bomPresent -LineEnding $lineEnding -InputSha256 $inputHash
        }
        $values.Add($key, $match.Groups[2].Value)
    }

    foreach ($requiredKey in $RequiredKeys) {
        if ([string]::IsNullOrEmpty($requiredKey) -or -not [System.Text.RegularExpressions.Regex]::IsMatch(
            $requiredKey,
            '\A[A-Z][A-Z0-9_]*\z',
            [System.Text.RegularExpressions.RegexOptions]::CultureInvariant
        )) {
            return New-StrictStageMetadataResult -Success $false -ReasonCode 'INVALID_REQUIRED_KEY' -Key $requiredKey -BomPresent $bomPresent -LineEnding $lineEnding -InputSha256 $inputHash
        }
        if (-not $values.ContainsKey($requiredKey)) {
            return New-StrictStageMetadataResult -Success $false -ReasonCode 'MISSING_REQUIRED_KEY' -Key $requiredKey -BomPresent $bomPresent -LineEnding $lineEnding -InputSha256 $inputHash
        }
    }

    return New-StrictStageMetadataResult -Success $true -ReasonCode 'OK' -Values $values -BomPresent $bomPresent -LineEnding $lineEnding -InputSha256 $inputHash
}

function Read-StrictStageMetadataFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        [AllowEmptyCollection()]
        [string[]]$RequiredKeys = @('TOTAL_STAGES', 'CURRENT_STAGE', 'LAST_COMPLETED_STAGE')
    )

    try {
        [byte[]]$bytes = [System.IO.File]::ReadAllBytes($Path)
    } catch {
        return New-StrictStageMetadataResult -Success $false -ReasonCode 'IO_ERROR' -Detail $_.Exception.GetType().FullName
    }

    return ConvertFrom-StrictStageMetadataBytes -Bytes $bytes -RequiredKeys $RequiredKeys
}
