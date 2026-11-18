use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib';
use Pastafari::Monster::WeavingPrimitive qw(count_weavings rank_weaving unrank_weaving);

# Independent oracle: enumerate every distinct multiset permutation first;
# only complete words are checked for strictly increasing first/last positions.
sub complete_multiset_oracle ($profile) {
    my @remaining = @$profile;
    my @prefix;
    my @accepted;
    my $months = scalar @$profile;
    my $visit;
    $visit = sub {
        if (!grep { $_ } @remaining) {
            my (@first, @last);
            for my $position (0 .. $#prefix) {
                my $label = $prefix[$position] - 1;
                $first[$label] //= $position;
                $last[$label] = $position;
            }
            for my $label (1 .. $months - 1) {
                return if $first[$label - 1] >= $first[$label];
                return if $last[$label - 1] >= $last[$label];
            }
            push @accepted, [@prefix];
            return;
        }
        for my $label (1 .. $months) {
            next unless $remaining[$label - 1] > 0;
            --$remaining[$label - 1];
            push @prefix, $label;
            $visit->();
            pop @prefix;
            ++$remaining[$label - 1];
        }
    };
    $visit->();
    return \@accepted;
}

my ($profiles, $positions) = (0, 0);
for my $profile (
    [2, (1) x 8],
    [1,1,2,(1) x 6],
    [1,1,1,2,(1) x 5],
) {
    my $oracle = complete_multiset_oracle($profile);
    ++$profiles;
    is(''.count_weavings($profile), ''.scalar(@$oracle), '九月份小型多重集合獨立計數');
    for my $index (0 .. $#$oracle) {
        my $rank = Math::BigInt->new($index + 1);
        is_deeply(unrank_weaving($profile, $rank), $oracle->[$index], '小型獨立排列字典序反排名');
        is(''.rank_weaving($profile, $oracle->[$index]), "$rank", '小型獨立排列排名');
        ++$positions;
    }
}
note("STAGE19_EXHAUSTIVE_PROFILES=$profiles");
note("STAGE19_EXHAUSTIVE_POSITIONS=$positions");
done_testing;
