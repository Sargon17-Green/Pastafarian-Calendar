use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use Digest::SHA qw(sha256_hex);
use Math::BigInt;
use lib 'lib';
use Pastafari::Monster::WeavingPrimitive qw(count_weavings rank_weaving unrank_weaving);

# Independent enumerator: balanced-parenthesis paths mapped to first/last
# occurrence labels, without using the production suffix-state recurrence.
my @words;
my @path;
my $visit;
$visit = sub ($opens, $closes) {
    if ($closes == 11) {
        my ($opened, $closed) = (0, 0);
        my @word = map { $_ ? ++$opened : ++$closed } @path;
        push @words, \@word;
        return;
    }
    if ($opens < 11) {
        push @path, 1;
        $visit->($opens+1, $closes);
        pop @path;
    }
    if ($closes < $opens) {
        push @path, 0;
        $visit->($opens, $closes+1);
        pop @path;
    }
};
$visit->(0, 0);
@words = sort {
    for my $i (0 .. $#$a) {
        my $d = $a->[$i] <=> $b->[$i];
        return $d if $d;
    }
    return 0;
} @words;

is(scalar @words, 58786, 'independent Catalan11 cardinality');
my $checksum = sha256_hex(join('', map { join(',', @$_) . "\n" } @words));
is($checksum, '3b7ad5a789d66bfc799fbbc96669e79a46e551fa0d19453bdef7d228f8626c0c', 'independent sorted oracle hash');
my $pairs = [(2) x 11];
is(''.count_weavings($pairs), '58786', 'production exact count matches Catalan11');
is(''.count_weavings([(1) x 11]), '1', 'eleven one-day months accepted');
is_deeply(unrank_weaving([(1) x 11], 1), [1..11], 'eleven one-day months unique sequence');
is(''.rank_weaving([(1) x 11], [1..11]), '1', 'eleven one-day months unique rank');

my $shard = $ENV{STAGE20_SHARD};
die "STAGE20_SHARD must be 0..7\n" if defined($shard) && $shard !~ /\A[0-7]\z/;
my ($lo, $hi) = (0, $#words);
if (defined $shard) {
    # N=58786, two intervals of 7349 and six intervals of 7348.
    my $base = int(@words / 8);
    my $extra = @words % 8;
    $lo = $base * $shard + ($shard < $extra ? $shard : $extra);
    $hi = $lo + $base + ($shard < $extra ? 1 : 0) - 1;
} else {
    # Full oracle enumeration/hash on normal Stage01, but bounded spot
    # comparison. Dedicated native job checks all eight full-rank shards.
    my @sample = (0,1,2,3,7,16,32,99,999,7348,7349,14697,29392,44088,58783,58784,58785);
    for my $index (@sample) {
        my $rank = $index + 1;
        is_deeply(unrank_weaving($pairs, $rank), $words[$index], 'oracle sample unrank');
        is(''.rank_weaving($pairs, $words[$index]), "$rank", 'oracle sample rank');
    }
}
if (defined $shard) {
    for my $index ($lo .. $hi) {
        my $rank = $index + 1;
        is_deeply(unrank_weaving($pairs, $rank), $words[$index], 'independent lexicographic word');
        is(''.rank_weaving($pairs, $words[$index]), "$rank", 'independent lexicographic rank');
    }
}

for my $bad (undef, [], [(1) x 13], [49], [40,(1) x 9], [39,(1) x 10], [0], [-1], [1.5], ['02'], ['2x'], [undef], {}, [Math::BigInt->bone]) {
    ok(!eval { count_weavings($bad); 1 }, 'reject invalid Stage20 profile');
}
for my $bad (undef, 0, -1, 'NaN', '1.5', '0x10', 58787, Math::BigInt->new('9'x60), [], {}) {
    ok(!eval { unrank_weaving($pairs,$bad); 1 }, 'reject illegal Stage20 rank');
}
for my $bad (undef, [], [1,2], [(1)x22], [2,1,1,2,(3)x2,(4)x2,(5)x2,(6)x2,(7)x2,(8)x2,(9)x2,(10)x2,(11)x2], [1,2,2,1,(3)x2,(4)x2,(5)x2,(6)x2,(7)x2,(8)x2,(9)x2,(10)x2,(11)x2]) {
    ok(!eval { rank_weaving($pairs,$bad); 1 }, 'reject illegal Stage20 word');
}
my $profile = [(2)x11];
my $rank = Math::BigInt->new(2);
my $out = unrank_weaving($profile, $rank);
my $snapshot = [@$out];
$out->[0] = 999;
is_deeply(unrank_weaving($profile, $rank), $snapshot, 'no shared mutable output');
is(join(',', @$profile), join(',', (2)x11), 'input profile unchanged');
is("$rank", '2', 'input rank unchanged');
note('STAGE20_CATALAN11_DYCK_WORDS=58786');
note('STAGE20_ORACLE_HASH=' . $checksum);
note('STAGE20_ORACLE_COMPARE=' . (defined($shard) ? $hi-$lo+1 : 17));
note('STAGE20_SHARD=' . (defined($shard) ? $shard : 'smoke'));
note('STAGE20_FULL_YEAR_GENERATOR_NOT_VERIFIED');
done_testing;
