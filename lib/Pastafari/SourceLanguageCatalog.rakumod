unit module Pastafari::SourceLanguageCatalog;

our constant SOURCE_LANGUAGE_VERSION is export = 'et-EE-stage01-v1';
our constant SOURCE_LANGUAGE is export = 'eesti';

my constant @CUTLET_SOURCE = (
    { canonicalIndex => 1,  text => 'pronks' },
    { canonicalIndex => 2,  text => 'rebane' },
    { canonicalIndex => 3,  text => 'neer' },
    { canonicalIndex => 4,  text => 'Lagaš' },
    { canonicalIndex => 5,  text => 'mõte' },
    { canonicalIndex => 6,  text => 'neli üheksandikku' },
    { canonicalIndex => 7,  text => 'Palguraš' },
    { canonicalIndex => 8,  text => 'papüürus' },
    { canonicalIndex => 9,  text => 'kobar' },
    { canonicalIndex => 10, text => 'skorpion' },
    { canonicalIndex => 11, text => 'tuhk' },
    { canonicalIndex => 12, text => 'nisu' },
    { canonicalIndex => 13, text => 'jõgi' },
    { canonicalIndex => 14, text => 'naer' },
    { canonicalIndex => 15, text => 'Akad' },
    { canonicalIndex => 16, text => 'sarv' },
    { canonicalIndex => 17, text => 'tühi kann' },
);

my constant @MONTH_SOURCE = (
    { canonicalIndex => 1,  text => 'savi' },
    { canonicalIndex => 2,  text => 'granaatõun' },
    { canonicalIndex => 3,  text => 'küünarnukk' },
    { canonicalIndex => 4,  text => 'kadedus' },
    { canonicalIndex => 5,  text => 'Eridu' },
    { canonicalIndex => 6,  text => 'hambapasta' },
    { canonicalIndex => 7,  text => 'kolm viiendikku' },
    { canonicalIndex => 8,  text => 'Karšumav' },
    { canonicalIndex => 9,  text => 'leopard' },
    { canonicalIndex => 10, text => 'tina' },
    { canonicalIndex => 11, text => 'udu' },
    { canonicalIndex => 12, text => 'viiruk' },
    { canonicalIndex => 13, text => 'värten' },
    { canonicalIndex => 14, text => 'roie' },
    { canonicalIndex => 15, text => 'jaanikaun' },
    { canonicalIndex => 16, text => 'Uruk' },
    { canonicalIndex => 17, text => 'häbi' },
    { canonicalIndex => 18, text => 'kaamel' },
    { canonicalIndex => 19, text => 'vask' },
    { canonicalIndex => 20, text => 'kaev' },
    { canonicalIndex => 21, text => 'munakollane' },
    { canonicalIndex => 22, text => 'täht' },
    { canonicalIndex => 23, text => 'mesi' },
    { canonicalIndex => 24, text => 'põrn' },
    { canonicalIndex => 25, text => 'lubjakivi' },
    { canonicalIndex => 26, text => 'rõõm' },
    { canonicalIndex => 27, text => 'viigimari' },
    { canonicalIndex => 28, text => 'Niineve' },
    { canonicalIndex => 29, text => 'konn' },
    { canonicalIndex => 30, text => 'tõrv' },
    { canonicalIndex => 31, text => 'küünal' },
    { canonicalIndex => 32, text => 'suletud uks' },
    { canonicalIndex => 33, text => 'seesam' },
    { canonicalIndex => 34, text => 'kukal' },
    { canonicalIndex => 35, text => 'hõbe' },
    { canonicalIndex => 36, text => 'liilia' },
    { canonicalIndex => 37, text => 'torm' },
    { canonicalIndex => 38, text => 'eesel' },
    { canonicalIndex => 39, text => 'jahu' },
    { canonicalIndex => 40, text => 'kahetsus' },
    { canonicalIndex => 41, text => 'Babülon' },
    { canonicalIndex => 42, text => 'keel' },
    { canonicalIndex => 43, text => 'lina' },
    { canonicalIndex => 44, text => 'sool' },
    { canonicalIndex => 45, text => 'pirn' },
    { canonicalIndex => 46, text => 'vibu' },
    { canonicalIndex => 47, text => 'liiv' },
);

sub frozen-copy(@rows --> List) {
    @rows.map({ Map.new($_) }).List
}

sub cutlet-catalog(--> List) is export {
    frozen-copy(@CUTLET_SOURCE)
}

sub month-catalog(--> List) is export {
    frozen-copy(@MONTH_SOURCE)
}

sub cutlet-name(Int:D $canonical-index --> Str:D) is export {
    die "Tundmatu kotleti kanooniline indeks: $canonical-index"
        unless 1 <= $canonical-index <= 17;
    @CUTLET_SOURCE[$canonical-index - 1]<text>
}

sub month-name(Int:D $canonical-index --> Str:D) is export {
    die "Tundmatu kuu kanooniline indeks: $canonical-index"
        unless 1 <= $canonical-index <= 47;
    @MONTH_SOURCE[$canonical-index - 1]<text>
}
