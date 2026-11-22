Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
. (Join-Path $repo 'src/FrozenStage42MetadataComparator.ps1')
$passed = 0
$utf8 = [System.Text.UTF8Encoding]::new($false, $true)
$lf = [string][char]10
$cr = [string][char]13

function To-TestBytes {
    param([Parameter(Mandatory=$true)][AllowEmptyString()][string]$Text)
    [byte[]]$b = $utf8.GetBytes($Text)
    return ,$b
}

function Replace-TestValue {
    param([string]$Text, [string]$Key, [string]$Value)
    $prefix = $Key + '='
    [string[]]$lines = $Text.Split([char]10)
    $seen = 0
    for ($i=0; $i -lt $lines.Length; $i++) {
        if ($lines[$i].StartsWith($prefix, [System.StringComparison]::Ordinal)) {
            $lines[$i] = $prefix + $Value
            $seen++
        }
    }
    if ($seen -ne 1) { throw ('Test fixture key not unique: ' + $Key) }
    return [string]::Join($lf, $lines)
}

function Remove-TestKey {
    param([string]$Text, [string]$Key)
    $prefix = $Key + '='
    $lines = [System.Collections.Generic.List[string]]::new()
    $removed = 0
    foreach ($line in $Text.Split([char]10)) {
        if ($line.StartsWith($prefix, [System.StringComparison]::Ordinal)) { $removed++ }
        else { $lines.Add($line) }
    }
    if ($removed -ne 1) { throw ('Test fixture key not unique: ' + $Key) }
    return [string]::Join($lf, $lines.ToArray())
}

function Assert-FrozenCase {
    param([string]$Name, [byte[]]$Bytes, [bool]$ExpectSuccess, [string]$Reason)
    $before = [System.Convert]::ToBase64String($Bytes)
    $actual = Test-FrozenStage42MetadataBytes -CandidateBytes $Bytes -RepositoryRoot $repo
    if ([bool]$actual.Success -ne $ExpectSuccess -or $actual.ReasonCode -cne $Reason) {
        throw ($Name + ': expected ' + $ExpectSuccess + '/' + $Reason +
            ', observed ' + $actual.Success + '/' + $actual.ReasonCode +
            '/' + $actual.ParsedReason)
    }
    if ([System.Convert]::ToBase64String($Bytes) -cne $before) {
        throw ($Name + ': input bytes mutated')
    }
    $script:passed++
    Write-Output ('CASE=' + $Name + ';STATUS=PASS;REASON=' + $actual.ReasonCode)
}

try {
    [byte[]]$baseline = Get-FrozenStage42BlobBytes -RepositoryRoot $repo
    $baseParsed = ConvertFrom-StrictStageMetadataBytes -Bytes $baseline -RequiredKeys @()
    if (-not $baseParsed.Success -or $baseParsed.Values.Count -ne 728) {
        throw 'Invalid frozen test fixture'
    }
    $text = $utf8.GetString($baseline)
    if ($text.Contains($cr)) { throw 'Unexpected CR in baseline Git blob' }

    Assert-FrozenCase 'C00-original' $baseline $true 'OK'
    Assert-FrozenCase 'C01-crlf' (To-TestBytes ($text.Replace($lf, $cr + $lf))) $true 'OK'
    [byte[]]$bom = [byte[]](0xEF,0xBB,0xBF) + $baseline
    Assert-FrozenCase 'C02-leading-bom' $bom $true 'OK'
    Assert-FrozenCase 'C03-blank-line' (To-TestBytes ($text + $lf)) $true 'OK'
    Assert-FrozenCase 'C04-no-final-lf' (To-TestBytes ($text.TrimEnd([char]10))) $true 'OK'
    [byte[]]$bomCrlf = [byte[]](0xEF,0xBB,0xBF) + (To-TestBytes ($text.Replace($lf, $cr + $lf)))
    Assert-FrozenCase 'C05-bom-crlf' $bomCrlf $true 'OK'

    $longKey = 'MONSTER_ARCHITECTURE_GROWTH'
    $oldVal = $baseParsed.Values[$longKey]
    Assert-FrozenCase 'X01-value-same-count' (To-TestBytes (Replace-TestValue $text $longKey 'SYNTHETIC_BAD')) $false 'FROZEN_MAP_MISMATCH'
    Assert-FrozenCase 'X02-key-swap-same-count' (To-TestBytes ((Remove-TestKey $text $longKey) + $lf + 'UNAUTHORIZED_KEY=1')) $false 'FROZEN_MAP_MISMATCH'
    Assert-FrozenCase 'X03-current-patch' (To-TestBytes (Replace-TestValue $text 'CURRENT_PATCH' '15')) $false 'FROZEN_MAP_MISMATCH'
    Assert-FrozenCase 'X04-stage43-append' (To-TestBytes ($text + $lf + 'STAGE43_RUNTIME_VERIFICATION=PENDING_NATIVE')) $false 'FROZEN_MAP_MISMATCH'
    Assert-FrozenCase 'X05-duplicate' (To-TestBytes ($text + $lf + 'TOTAL_STAGES=55')) $false 'CANDIDATE_LEXICAL_INVALID'
    Assert-FrozenCase 'X06-language' (To-TestBytes (Replace-TestValue $text 'NATURAL_LANGUAGE' 'Filipino')) $false 'FROZEN_MAP_MISMATCH'
    Assert-FrozenCase 'X07-extra-equals' (To-TestBytes (Replace-TestValue $text $longKey ($oldVal + '=ADDED'))) $false 'FROZEN_MAP_MISMATCH'
    Assert-FrozenCase 'X08-malformed-line' (To-TestBytes ($text + $lf + 'BadMissingEquals')) $false 'CANDIDATE_LEXICAL_INVALID'
    Assert-FrozenCase 'X09-mixed-newlines' (To-TestBytes ($text.Replace($lf, $cr + $lf).Replace(('TOTAL_STAGES=55' + $cr + $lf), ('TOTAL_STAGES=55' + $lf)))) $false 'CANDIDATE_LEXICAL_INVALID'
    Assert-FrozenCase 'X10-standalone-cr' (To-TestBytes ($text + $cr + 'BAD=1')) $false 'CANDIDATE_LEXICAL_INVALID'
    Assert-FrozenCase 'X11-interior-bom' (To-TestBytes ($text + $lf + 'BAD=' + [char]0xFEFF)) $false 'CANDIDATE_LEXICAL_INVALID'
    [byte[]]$badUtf8 = [byte[]](0xFF,0x0A) + $baseline
    Assert-FrozenCase 'X12-invalid-utf8' $badUtf8 $false 'CANDIDATE_LEXICAL_INVALID'
    Assert-FrozenCase 'X13-missing-key' (To-TestBytes (Remove-TestKey $text $longKey)) $false 'FROZEN_MAP_MISMATCH'
    Assert-FrozenCase 'X14-whitespace-only' (To-TestBytes ($text + $lf + '  ')) $false 'CANDIDATE_LEXICAL_INVALID'

    if ($passed -ne 20) { throw ('Wrong number of executed cases: ' + $passed) }
    Write-Output ('FROZEN_STAGE42_OPTIN_CASES_PASSED=' + $passed)
    Write-Output 'FROZEN_STAGE42_OPTIN_RESULT=PASS'
    Write-Output 'STAGE43_ACTIVATION=NOT_ACTIVATED'
} catch {
    [Console]::Error.WriteLine('FROZEN_STAGE42_OPTIN_RESULT=FAIL;ERROR=' + $_.Exception.Message)
    exit 1
}
