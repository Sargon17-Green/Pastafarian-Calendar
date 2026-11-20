use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib';
use Pastafari::Monster::WeavingPrimitive qw(count_weavings rank_weaving unrank_weaving);

# The ten-month all-single-day boundary has exactly one legal complete word.
my $ten_months = [(1) x 10];
is(''.count_weavings($ten_months), '1', '十個單日月份只有一個合法完整序列');
is_deeply(unrank_weaving($ten_months, 1), [1..10], '十月份邊界的唯一字典序序列');
is(''.rank_weaving($ten_months, [1..10]), '1', '十月份邊界唯一序列排名');

# Independent oracle B: Dyck paths, generated from open/close counters,
# then sorted lexicographically. No production transition or DP is used.
sub dyck_words ($pairs) {
    my @words;
    my @prefix;
    my $visit;
    $visit = sub ($opened, $closed) {
        if ($closed == $pairs) {
            push @words, [@prefix];
            return;
        }
        if ($opened < $pairs) {
            push @prefix, $opened + 1;
            $visit->($opened + 1, $closed);
            pop @prefix;
        }
        if ($closed < $opened) {
            push @prefix, $closed + 1;
            $visit->($opened, $closed + 1);
            pop @prefix;
        }
    };
    $visit->(0, 0);
    return [sort {
        my $cmp = 0;
        for my $position (0 .. $#$a) {
            $cmp = $a->[$position] <=> $b->[$position];
            last if $cmp;
        }
        $cmp;
    } @words];
}

my $catalan10 = Math::BigInt->new(20)->bfac;
$catalan10->bdiv(Math::BigInt->new(10)->bfac);
$catalan10->bdiv(Math::BigInt->new(11)->bfac);
is("$catalan10", '16796', 'Catalan(10) = 20!/(10! 11!)');
my $oracle = dyck_words(10);
is(scalar(@$oracle), 16796, '獨立 Dyck oracle 產生完整 16,796 個詞');
my $pairs = [(2) x 10];
is(''.count_weavings($pairs), "$catalan10", '十月份生產計數符合獨立 Catalan 閉式');
for my $index (0 .. $#$oracle) {
    my $rank = Math::BigInt->new($index + 1);
    is_deeply(unrank_weaving($pairs, $rank), $oracle->[$index], '全部 Catalan(10) 字典序反排名');
    is(''.rank_weaving($pairs, $oracle->[$index]), "$rank", '全部 Catalan(10) 雙向排名');
}

my $invalid_profiles = 0;
for my $bad (
    undef, [], [(1) x 12], [45], [36, (1) x 9], [(1) x 9, 36],
    [0], [-1], [1.5], ['02'], ['2x'], [undef], {}, [Math::BigInt->bone]
) {
    ok(!eval { count_weavings($bad); 1 }, '拒絕超過十月／四十日或非法 profile');
    ++$invalid_profiles;
}
my $invalid_ranks = 0;
for my $rank (undef, 0, -1, 'abc', 'NaN', '1.5', '0x10',
    Math::BigInt->new(16797), Math::BigInt->new('9' x 45), [], {}) {
    ok(!eval { unrank_weaving($pairs, $rank); 1 }, '拒絕非法或超限 BigInt rank');
    ++$invalid_ranks;
}
my $invalid_words = 0;
for my $word (
    undef, [], [1,2], [(1) x 20],
    [2,1,1,2,(3)x2,(4)x2,(5)x2,(6)x2,(7)x2,(8)x2,(9)x2,(10)x2],
    [1,2,2,1,(3)x2,(4)x2,(5)x2,(6)x2,(7)x2,(8)x2,(9)x2,(10)x2],
    [1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,'x'],
    [1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,11]
) {
    ok(!eval { rank_weaving($pairs, $word); 1 }, '拒絕非法月份標籤／數量／順序');
    ++$invalid_words;
}

my $saved_profile = [(2) x 10];
my $saved_rank = Math::BigInt->new(2);
my $word = unrank_weaving($saved_profile, $saved_rank);
my $copy = [@$word];
$word->[0] = 999;
is_deeply(unrank_weaving($saved_profile, $saved_rank), $copy, '回傳序列不共享可變狀態');
is("$saved_rank", '2', '傳入 BigInt rank 不被修改');
is(join(',', @$saved_profile), join(',', (2) x 10), '傳入月份 profile 不被修改');

note('STAGE19_CATALAN10_DYCK_WORDS=16796');
note('STAGE19_CATALAN10_RANKS=16796');
note("STAGE19_INVALID_PROFILES=$invalid_profiles");
note("STAGE19_INVALID_RANKS=$invalid_ranks");
note("STAGE19_INVALID_WORDS=$invalid_words");
note('STAGE19_FULL_YEAR_GENERATOR_NOT_VERIFIED');
done_testing;
