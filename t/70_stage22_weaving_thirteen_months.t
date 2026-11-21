use v5.40;
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib';
use Pastafari::Monster::WeavingPrimitive qw(count_weavings rank_weaving unrank_weaving);

# Independent ballot-path oracle. No producer DP, state encoding or fixture copied.
my %ways;
sub suffix ($o, $c) {
    return 1 if $c == 13;
    my $key = "$o,$c";
    return $ways{$key} if exists $ways{$key};
    my $v = 0;
    $v += suffix($o, $c + 1) if $c < $o;
    $v += suffix($o + 1, $c) if $o < 13;
    return $ways{$key} = $v;
}
sub reference_word ($r) {
    die 'bad oracle rank' if $r < 1 || $r > suffix(0, 0);
    my ($o, $c) = (0, 0);
    my @word;
    for (1 .. 26) {
        if ($c < $o) {
            my $close_ways = suffix($o, $c + 1);
            if ($r <= $close_ways) {
                push @word, $c + 1;
                ++$c;
                next;
            }
            $r -= $close_ways;
        }
        die 'bad ballot state' if $o >= 13;
        push @word, $o + 1;
        ++$o;
    }
    return \@word;
}

my $pairs = [(2) x 13];
is(suffix(0, 0), 742900, 'independent ballot count Catalan13');
is('' . count_weavings($pairs), '742900', 'producer Catalan13 count');
is('' . count_weavings([(1)x13]), '1', 'thirteen one-day months');
is('' . count_weavings([52]), '1', 'single 52-day month');
is('' . count_weavings([40, (1)x12]), '1', 'heterogeneous 52-day profile');
my $shard = $ENV{STAGE22_SHARD};
die "STAGE22_SHARD must be 0..31\n" if defined($shard) && $shard !~ /\A(?:[0-9]|[12][0-9]|3[01])\z/;
my @ranks;
if (defined $shard) {
    my $per = int(742900 / 32);
    my $extra = 742900 % 32;
    my $start = 1 + $shard*$per + ($shard<$extra?$shard:$extra);
    my $count = $per + ($shard<$extra?1:0);
    @ranks = ($start .. $start+$count-1);
} else {
    @ranks = (1,2,3,11,27,100,1000,12345,371450,500000,742899,742900);
}
for my $r (@ranks) {
    my $expected = reference_word($r);
    is_deeply(unrank_weaving($pairs, $r), $expected, 'independent numeric lexical unrank');
    is('' . rank_weaving($pairs, $expected), "$r", 'independent numeric lexical rank');
}
for my $bad (undef, [], [53], [(1)x14], [41, (1)x12], [44,(1)x9],
             [0],[-1],[1.5],['02'],['2x'],[undef],{},[Math::BigInt->bone]) {
    ok(!eval {count_weavings($bad); 1}, 'reject invalid 13/52 profile');
}
for my $bad (undef,0,-1,'NaN','1.5','0x10',742901,Math::BigInt->new('9'x60),[],{}) {
    ok(!eval {unrank_weaving($pairs,$bad); 1}, 'reject invalid rank');
}
for my $bad (undef, [], [1,2], [(1)x26], [2,1,1,2, (3)x2, (4)x2,
             (5)x2,(6)x2,(7)x2,(8)x2,(9)x2,(10)x2,(11)x2,(12)x2,(13)x2]) {
    ok(!eval {rank_weaving($pairs,$bad); 1}, 'reject invalid word');
}
my $r = Math::BigInt->new(2);
my $word = unrank_weaving($pairs,$r);
my $snapshot = [@$word];
$word->[0] = 99;
is_deeply(unrank_weaving($pairs,$r),$snapshot,'returned word is fresh');
is("$r",'2','rank BigInt not mutated');
is(join(',',@$pairs),join(',',(2)x13),'profile not mutated');
note('STAGE22_BALLOT_COUNT=742900');
note('STAGE22_ORACLE_COMPARED=' . scalar(@ranks));
note('STAGE22_SHARD=' . (defined($shard)?$shard:'smoke'));
note('STAGE22_FULL_YEAR_GENERATOR_NOT_VERIFIED');
done_testing;
