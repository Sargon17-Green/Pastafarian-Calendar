use v5.40;
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib';
use Pastafari::Monster::WeavingPrimitive qw(count_weavings rank_weaving unrank_weaving);

# Independent multiset permutation enumeration. Filtering is performed only
# on completed permutations, never with a production-style suffix recurrence.
sub enumerate ($profile) {
    my @bag;
    for my $i (0..$#$profile) { push @bag, ($i+1) x $profile->[$i]; }
    my (@output,@word);
    my @used=(0)x@bag;
    my $visit;
    $visit=sub($depth) {
        if($depth==@bag) {
            my (%first,%last);
            for my $pos (0..$#word) {
                $first{$word[$pos]} //= $pos;
                $last{$word[$pos]} = $pos;
            }
            for my $j (1..$#$profile) {
                return if $first{$j}>=$first{$j+1} || $last{$j}>=$last{$j+1};
            }
            push @output, [@word];
            return;
        }
        my %seen;
        for my $k (0..$#bag) {
            next if $used[$k] || $seen{$bag[$k]}++;
            $used[$k]=1;
            push @word,$bag[$k];
            $visit->($depth+1);
            pop @word;
            $used[$k]=0;
        }
    };
    $visit->(0);
    return \@output; # positional order is numeric lexicographic
}

my @profiles=(
    [1], [2], [3], [4], [1,1], [1,2], [2,1], [1,3], [3,1], [2,2],
    [3,2], [2,3], [3,3], [1,1,1], [1,2,1], [2,1,2], [2,2,1],
    [1,2,2], [2,2,2], [3,2,1], [1,3,2], [2,1,3], [3,1,2],
    [2,2,2,1], [1,2,2,2], [2,1,2,2], [1,1,2,2], [2,2,1,1],
    [1,1,1,1,1], [2,2,2,2]
);
my $compared=0;
for my $profile (@profiles) {
    my $expected=enumerate($profile);
    is(''.count_weavings($profile),''.scalar(@$expected),'independent count');
    for my $i (0..$#$expected) {
        is_deeply(unrank_weaving($profile,$i+1),$expected->[$i], 'independent unrank');
        is(''.rank_weaving($profile,$expected->[$i]),''.($i+1),'independent rank');
        ++$compared;
    }
}
for my $p ([(2)x11], [(2)x12], [(1)x12], [48], [37,(1)x11]) {
    my $old = join(',',@$p);
    my $total=count_weavings($p);
    my $middle = $total->copy->badd(1)->bdiv(2);
    for my $r (1, $middle, $total) {
        my $word=unrank_weaving($p,$r);
        is(''.rank_weaving($p,$word), "$r",'large boundary inverse');
        is(join(',',@$p),$old,'no input mutation');
    }
}
note("STAGE21_INDEPENDENT_MIXED_WORDS=$compared");
note('STAGE21_FULL_YEAR_GENERATOR_NOT_VERIFIED');
done_testing;
