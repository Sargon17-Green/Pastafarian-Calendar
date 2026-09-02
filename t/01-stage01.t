use Test;
use lib 'lib';
use lib 't/lib';

use Pastafari::Bootstrap;
use Pastafari::SourceLanguageCatalog;
use Pastafari::Normative::Oracle;
use Pastafari::Fixtures::Stage01;

is TABLETS_DAY - FOUNDATION_DAY, 14777149, 'Tahvlite ja aluse päeva vahe on täpne';
is M, 170141183460469231731687303715884105727, 'Suur loendur on täpne';

for @DAY_COUNT_CASES -> @case {
    is day-count(@case[0]), @case[1], "Päevaloendur sobib fikstuuriga {@case[0]}";
}

for @WORK_COUNT_CASES -> @case {
    my $w = work-counts(@case[0], @case[1]);
    is-deeply [$w.action,$w.target,$w.distance,$w.connection,$w.direction], @case[2],
        "Tööloendurid sobivad fikstuuriga {@case[0]} -> {@case[1]}";
}

is save(1), 1, 'SAVE jätab ühe muutmata';
is save(M - 1), M - 1, 'SAVE jätab M-1 muutmata';
is save(M), M, 'SAVE kirjutab M-i M-na';
is save(M + 1), 1, 'SAVE murrab M+1 üheks';
is save(2 * M), M, 'SAVE kirjutab 2M-i M-na';
is save(3 * M), M, 'SAVE kirjutab 3M-i M-na';
is regular-mod(-1, M), M - 1, 'Eukleidiline jääk on negatiivsel sisendil korrektne';

my @stones = build-stones();
is-deeply @stones[2], @STONE_ROW_2, 'Teine kivirida kasutab ainult esimese rea hetktõmmist';

is-deeply bowl-order-from-number(1), [1,2,3,4,5,6], 'Permutatsiooni esimene aste on identiteet';
is-deeply bowl-order-from-number(720), [6,5,4,3,2,1], 'Permutatsiooni aste 720 on pöördjärjestus';
is falling-factorial(17,6), 8910720, 'Osalise permutatsiooni arv on täpne';

my $foundation-counts = work-counts(FOUNDATION_DAY, FOUNDATION_DAY);
my @bowls = initial-bowls($foundation-counts);
is @bowls[1], @INITIAL_BOWL_PREFIX_FOUNDATION[1], 'Esimese kausi algväärtus on fikseeritud';
is @bowls[2], @INITIAL_BOWL_PREFIX_FOUNDATION[2], 'Teise kausi algväärtus on fikseeritud';

my $bounded-a = BoundedCompositionFamily.new(total => 8, slots => 2, lo => 4, hi => 123);
is $bounded-a.count, 1, 'Piiratud kompositsiooni triviaalse pere suurus on üks';
is-deeply $bounded-a.unrank1(1), [4,4], 'Piiratud kompositsiooni ainus liige on õige';

my $bounded-b = BoundedCompositionFamily.new(total => 9, slots => 2, lo => 4, hi => 5);
is $bounded-b.count, 2, 'Kaheelemendilise piiratud pere suurus on kaks';
is-deeply $bounded-b.unrank1(1), [4,5], 'Piiratud pere esimene leksikograafiline liige on õige';
is-deeply $bounded-b.unrank1(2), [5,4], 'Piiratud pere teine leksikograafiline liige on õige';

my $cutlet-a = CutletPartitionFamily.new(gaps => 7, parts => 3, required => -1);
is $cutlet-a.count, 15, 'Positiivsete kompositsioonide arv 7 kolmeks osaks on 15';
my $cutlet-b = CutletPartitionFamily.new(gaps => 7, parts => 3, required => 2);
is $cutlet-b.count, 5, 'Nõutud sisepiiriga kompositsioonide arv on viis';
is-deeply $cutlet-b.unrank1(1), [1,1,5], 'Filtreeritud pere esimene leksikograafiline liige on õige';
is-deeply $cutlet-b.unrank1(2), [2,1,4], 'Filtreeritud pere teine leksikograafiline liige on õige';

my $weave-a = WeavingFamily.new(lengths => [1,1]);
is $weave-a.count, 1, 'Ühe kaupa kahe kuu põiming on ühene';
is-deeply $weave-a.unrank1(1), [1,2], 'Ühe kaupa kahe kuu põiming on õige';
my $weave-b = WeavingFamily.new(lengths => [2,2]);
is $weave-b.count, 2, 'Kahe ja kahe pikkusega põiminguid on kaks';
is-deeply $weave-b.unrank1(1), [1,1,2,2], 'Põimingu esimene aste on õige';
is-deeply $weave-b.unrank1(2), [1,2,1,2], 'Põimingu teine aste on õige';

my @cutlets = cutlet-catalog();
my @months = month-catalog();
is @cutlets.elems, 17, 'Kotletikataloogis on täpselt 17 kirjet';
is @months.elems, 47, 'Kuukataloogis on täpselt 47 kirjet';
is-deeply @cutlets.map(*<canonicalIndex>).Array, [1..17], 'Kotleti kanoonilised indeksid on katkematud';
is-deeply @months.map(*<canonicalIndex>).Array, [1..47], 'Kuu kanoonilised indeksid on katkematud';
is @cutlets.map(*<text>).unique.elems, 17, 'Kõik kotletinimed on selles kataloogis erinevad';
is @months.map(*<text>).unique.elems, 47, 'Kõik kuunimed on selles kataloogis erinevad';
is cutlet-name(12), 'nisu', 'Nisu nimi lahendatakse kanoonilisest indeksist';
is month-name(44), 'sool', 'Soola nimi lahendatakse kanoonilisest indeksist';

my $ctx-a = prepare-monster-context(FOUNDATION_DAY, FOUNDATION_DAY + 1);
my $ctx-b = prepare-monster-context(FOUNDATION_DAY, FOUNDATION_DAY + 1);
is $ctx-a.status, 'READY', 'Neutraalne põhikontekst jõuab valmisolekusse';
is-deeply $ctx-a.branchTrace, ['BOOTSTRAP_ENTER','BOOTSTRAP_READY'], 'Põhidispetšeri jälg on deterministlik';
ok !($ctx-a =:= $ctx-b), 'Kaks väljakutset ei jaga MonsterContexti objekti';
is $ctx-a.metrics{'bootstrap.calls'}, 1, 'Mõõdik on ainult vaatlusseisund';

done-testing;
