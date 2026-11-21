use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use Digest::SHA qw(sha256_hex);
use Math::BigInt;
use lib 'lib';
use Pastafari::Monster::WeavingPrimitive qw(count_weavings rank_weaving unrank_weaving);

# Independent ordinal open/close Dyck enumeration. No production DP/state
# recurrence is used to generate expected words or expected lexicographic ranks.
my (@paths, @words);
my $visit;
$visit = sub ($opened, $closed) {
    if ($closed == 12) {
        my ($first, $last) = (0,0);
        push @words, pack('C*', map { $_ ? ++$first : ++$last } @paths);
        return;
    }
    if ($opened < 12) {
        push @paths, 1;
        $visit->($opened+1,$closed);
        pop @paths;
    }
    if ($closed < $opened) {
        push @paths, 0;
        $visit->($opened,$closed+1);
        pop @paths;
    }
};
$visit->(0,0);
@words = sort @words;
my $hash = sha256_hex(join('', map { join(',',unpack('C*',$_)) . "\n" } @words));
is(scalar @words, 208012, 'independent Catalan12 cardinality');
is($hash, '0dbe36d23b6ffaa14822b1556d3eabc777d5961bdfd2fd79be39ee2daee76bbe', 'independent canonical lexical hash');
my $pairs = [(2) x 12];
is(''.count_weavings($pairs), '208012', 'production two-day count');
is(''.count_weavings([(1) x 12]), '1', 'twelve one-day months valid');
is_deeply(unrank_weaving([(1) x 12], 1), [1..12], 'twelve one-day months word');
is(''.rank_weaving([(1) x 12], [1..12]), '1', 'twelve one-day months rank');
is(''.count_weavings([48]), '1', 'single 48-day month');
is(''.count_weavings([37,(1)x11]), '1', 'legal 48-day heterogeneous boundary');
is(''.count_weavings([1,47]), '1', 'one-day followed by 47-day month');

my $shard = $ENV{STAGE21_SHARD};
die "STAGE21_SHARD must be 0..15\n" if defined($shard) && $shard !~ /\A(?:[0-9]|1[0-5])\z/;
my ($lo,$hi)=(0,$#words);
if (defined($shard)) {
    my $base=int(@words/16);
    my $extra=@words%16;
    $lo=$base*$shard+($shard<$extra?$shard:$extra);
    $hi=$lo+$base+($shard<$extra?1:0)-1;
    for my $i ($lo..$hi) {
        my $rank=$i+1;
        is_deeply(unrank_weaving($pairs,$rank),[unpack('C*',$words[$i])], 'ordinal oracle unrank');
        is(''.rank_weaving($pairs,[unpack('C*',$words[$i])]), "$rank", 'ordinal oracle rank');
    }
} else {
    for my $i (0,1,2,3,11,31,99,1012,13000,13001,26001,65002,104005,156008,195009,208010,208011) {
        my $rank=$i+1;
        is_deeply(unrank_weaving($pairs,$rank),[unpack('C*',$words[$i])], 'smoke oracle unrank');
        is(''.rank_weaving($pairs,[unpack('C*',$words[$i])]), "$rank", 'smoke oracle rank');
    }
}

for my $bad (undef, [], [53], [(1)x14], [42,(1)x11], [44,(1)x9],
             [0], [-1], [1.5], ['02'], ['2x'], [undef], {}, [Math::BigInt->bone]) {
    ok(!eval { count_weavings($bad); 1 }, 'reject invalid Stage21 profile');
}
for my $bad (undef, 0, -1, 'NaN', '1.5', '0x10', 208013, Math::BigInt->new('9'x60), [], {}) {
    ok(!eval { unrank_weaving($pairs,$bad); 1 }, 'reject invalid Stage21 rank');
}
for my $bad (undef, [], [1,2], [(1)x24], [1,2,2,1,(3)x2,(4)x2,(5)x2,(6)x2,(7)x2,(8)x2,(9)x2,(10)x2,(11)x2,(12)x2],
             [1,2,2,1,(3)x2,(4)x2,(5)x2,(6)x2,(7)x2,(8)x2,(9)x2,(10)x2,(11)x2,(12)x2]) {
    ok(!eval { rank_weaving($pairs,$bad); 1 }, 'reject invalid Stage21 word');
}
my $r = Math::BigInt->new(2);
my $out=unrank_weaving($pairs,$r);
my $copy=[@$out];
$out->[0]=999;
is_deeply(unrank_weaving($pairs,$r),$copy,'fresh output');
is(join(',',@$pairs),join(',',(2)x12),'profile unchanged');
is("$r",'2','rank unchanged');
note('STAGE21_CATALAN12_DYCK_WORDS=208012');
note('STAGE21_ORACLE_HASH=' . $hash);
note('STAGE21_ORACLE_COMPARE=' . (defined($shard)?$hi-$lo+1:17));
note('STAGE21_SHARD=' . (defined($shard)?$shard:'smoke'));
note('STAGE21_FULL_YEAR_GENERATOR_NOT_VERIFIED');
done_testing;
