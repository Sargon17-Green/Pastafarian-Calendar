use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib';
use Pastafari::Monster::WeavingPrimitive qw(count_weavings rank_weaving unrank_weaving);

my $large_profiles = 0;
for my $profile (
    [(3) x 10], [(4) x 10], [31, (1) x 9], [40]
) {
    my $days = 0;
    $days += $_ for @$profile;
    is(scalar(@$profile) <= 10 && $days <= 40 ? 1 : 0, 1, 'profile 位於十月／四十日邊界內');
    my $count = count_weavings($profile);
    isa_ok($count, 'Math::BigInt');
    cmp_ok($count, '>=', 1, '精確計數為正');
    my $middle = $count->copy->badd(1);
    $middle->bdiv(2);
    my @ranks = (Math::BigInt->bone, $middle, $count->copy);
    my $snapshot = join(',', @$profile);
    for my $rank (@ranks) {
        my $saved_rank = "$rank";
        my $word = unrank_weaving($profile, $rank);
        is(scalar(@$word), $days, '完整輸出長度');
        is(''.rank_weaving($profile, $word), $saved_rank, 'BigInt 首／中／末 rank-unrank roundtrip');
        is("$rank", $saved_rank, '傳入 BigInt 不被修改');
        is(join(',', @$profile), $snapshot, '傳入 profile 不被修改');
    }
    ++$large_profiles;
}
note("STAGE19_LARGE_PROFILES=$large_profiles");
note('STAGE19_LARGE_PROFILE_COUNTS_ARE_ROUNDTRIP_ONLY_NOT_INDEPENDENT_ORACLES');
note('STAGE19_FULL_YEAR_GENERATOR_NOT_VERIFIED');
done_testing;
