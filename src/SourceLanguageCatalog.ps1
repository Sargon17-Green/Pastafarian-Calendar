Set-StrictMode -Version Latest

# Ang tekstong Filipino ay presentation data lamang; canonicalIndex ang tanging normative identity.
$script:SourceLanguageCatalogVersion = '1.0.0-stage01'

$script:CutletSourceNames = @(
    'Bronse',
    'Soro',
    'Bato',
    'Lagash',
    'Kaisipan',
    'Apat na bahagi sa siyam',
    'Palgurash',
    'Tambo',
    'Kumpol',
    'Alakdan',
    'Abo',
    'Trigo',
    'Ilog',
    'Tawa',
    'Akkad',
    'Sungay',
    'Walang-lamang banga'
)

$script:MonthSourceNames = @(
    'Luwad',
    'Granada',
    'Siko',
    'Inggit',
    'Eridu',
    'Pasta ng ngipin',
    'Tatlong bahagi sa lima',
    'Karshumab',
    'Tigre',
    'Estanyo',
    'Hamog',
    'Kamanyang',
    'Ikiran',
    'Tadyang',
    'Karob',
    'Uruk',
    'Hiya',
    'Kamelyo',
    'Tanso',
    'Balon',
    'Pula ng itlog',
    'Bituin',
    'Pulot',
    'Pali',
    'Batong-apog',
    'Saya',
    'Igos',
    'Nineve',
    'Palaka',
    'Alkitran',
    'Kandila',
    'Saradong pinto',
    'Linga',
    'Batok',
    'Pilak',
    'Liryo',
    'Bagyo',
    'Asno',
    'Harina',
    'Pagsisisi',
    'Babilonia',
    'Dila',
    'Lino',
    'Asin',
    'Peras',
    'Bahaghari',
    'Buhangin'
)

function Get-SourceLanguageCatalogVersion {
    [CmdletBinding()]
    param()
    return $script:SourceLanguageCatalogVersion
}

function Get-CutletCatalog {
    [CmdletBinding()]
    param()

    $out = [System.Collections.Generic.List[object]]::new()
    for ($i = 0; $i -lt $script:CutletSourceNames.Count; $i++) {
        $out.Add([pscustomobject]@{
            canonicalIndex = $i + 1
            sourceString = [string]$script:CutletSourceNames[$i]
        })
    }
    return ,$out.ToArray()
}

function Get-MonthCatalog {
    [CmdletBinding()]
    param()

    $out = [System.Collections.Generic.List[object]]::new()
    for ($i = 0; $i -lt $script:MonthSourceNames.Count; $i++) {
        $out.Add([pscustomobject]@{
            canonicalIndex = $i + 1
            sourceString = [string]$script:MonthSourceNames[$i]
        })
    }
    return ,$out.ToArray()
}

function Resolve-CutletSourceString {
    [CmdletBinding()]
    param([Parameter(Mandatory)][int]$CanonicalIndex)

    if ($CanonicalIndex -lt 1 -or $CanonicalIndex -gt 17) {
        throw 'Ang canonicalIndex ng cutlet ay dapat nasa 1..17.'
    }
    return [string]$script:CutletSourceNames[$CanonicalIndex - 1]
}

function Resolve-MonthSourceString {
    [CmdletBinding()]
    param([Parameter(Mandatory)][int]$CanonicalIndex)

    if ($CanonicalIndex -lt 1 -or $CanonicalIndex -gt 47) {
        throw 'Ang canonicalIndex ng buwan ay dapat nasa 1..47.'
    }
    return [string]$script:MonthSourceNames[$CanonicalIndex - 1]
}
