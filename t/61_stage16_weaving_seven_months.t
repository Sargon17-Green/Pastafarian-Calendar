use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib';
use Pastafari::Monster::WeavingPrimitive qw(count_weavings rank_weaving unrank_weaving);

# An independent reference: enumerate all distinct multiset permutations,
# applying the first/last-occurrence rules ONLY to complete words.
# No production recurrence, suffix cache, or prefix pruning is used.
sub reference_words ($profile) {
    my @remaining = @$profile;
    my @word;
    my @accepted;
    my $m = scalar @$profile;
    my $visit;
    $visit = sub {
        if (!grep { $_ } @remaining) {
            my (@first, @last);
            for my $position (0 .. $#word) {
                my $index = $word[$position] - 1;
                $first[$index] //= $position;
                $last[$index] = $position;
            }
            for my $index (1 .. $m - 1) {
                return if $first[$index - 1] >= $first[$index];
                return if $last[$index - 1] >= $last[$index];
            }
            push @accepted, [@word];
            return;
        }
        for my $symbol (1 .. $m) {
            next unless $remaining[$symbol - 1] > 0;
            --$remaining[$symbol - 1];
            push @word, $symbol;
            $visit->();
            pop @word;
            ++$remaining[$symbol - 1];
        }
    };
    $visit->();
    return \@accepted;
}

my $exhaustive_positions = 0;
my $exhaustive_profiles = 0;
for my $profile (
    [2,2], [2,3,2], [2,2,2,2],
    [(1) x 7], [2, (1) x 6], [2,2,(1) x 5],
    [3,2,(1) x 5], [2,2,2,(1) x 4],
) {
    my $expected = reference_words($profile);
    ++$exhaustive_profiles;
    is(''.count_weavings($profile), ''.scalar(@$expected), '直接列舉的總數一致');
    for my $index (0 .. $#$expected) {
        my $rank = Math::BigInt->new($index + 1);
        is_deeply(unrank_weaving($profile, $rank), $expected->[$index], '反排名與完整排列 oracle 相同');
        is(''.rank_weaving($profile, $expected->[$index]), "$rank", '排名與完整排列 oracle 相同');
        ++$exhaustive_positions;
    }
}

# Catalan(7) = 14! / (7! * 8!), derived independently of the DP.
my $cat7 = Math::BigInt->new(14)->bfac;
$cat7->bdiv(Math::BigInt->new(7)->bfac);
$cat7->bdiv(Math::BigInt->new(8)->bfac);
is("$cat7", '429', '獨立 Catalan(7) 閉式');
my $seven_pairs = [(2) x 7];
is(''.count_weavings($seven_pairs), "$cat7", '七月份每月兩日計數');
for my $rank (1 .. 429) {
    my $word = unrank_weaving($seven_pairs, $rank);
    is(scalar(@$word), 14, '十四日的完整排列');
    is(''.rank_weaving($seven_pairs, $word), "$rank", 'Catalan 全部排名一基往返');
}

# Old limits must remain semantically unchanged.
is(''.count_weavings([(2) x 6]), '132', '保留六月份 Catalan(6)');
is_deeply(unrank_weaving([2,2], 2), [1,2,1,2], '保留既有字典序');
is(''.rank_weaving([2,2], [1,1,2,2]), '1', '保留一基排名');

my $large_profiles = 0;
for my $profile (
    [(4) x 7], [10,3,3,3,3,3,3], [22,(1) x 6],
    [(4) x 6], [24]
) {
    my $days = 0; $days += $_ for @$profile;
    my $total = count_weavings($profile);
    isa_ok($total, 'Math::BigInt');
    cmp_ok($total, '>=', 1, '精確計數為正');
    my $middle = $total->copy->badd(1)->bdiv(2);
    for my $rank (Math::BigInt->bone, $middle, $total->copy) {
        my $snapshot_rank = "$rank";
        my $snapshot_profile = join(',', @$profile);
        my $word = unrank_weaving($profile, $rank);
        is(scalar(@$word), $days, '完整長度輸出');
        is(''.rank_weaving($profile, $word), $snapshot_rank, '精確首中末 BigInt 往返');
        is("$rank", $snapshot_rank, '外部 BigInt 未被修改');
        is(join(',', @$profile), $snapshot_profile, '月份設定未被修改');
    }
    ++$large_profiles;
}

my $invalid_profiles = 0;
for my $profile (
    undef, [], [(1) x 8], [29], [23,(1) x 6],
    [0], [-1], [1.5], ['2x'], ['03'], [undef],
    [1,1,1,1,1,1,23], {}, [Math::BigInt->bone],
) {
    ok(!eval { count_weavings($profile); 1 }, '拒絕非法月份數／日數／資料型態');
    ++$invalid_profiles;
}
my $invalid_ranks = 0;
for my $rank (undef, 0, -1, 'abc', '1.5', '0x10',
               Math::BigInt->new(430), Math::BigInt->new('9' x 40), [], {}) {
    ok(!eval { unrank_weaving($seven_pairs, $rank); 1 }, '拒絕不合法或超限排名');
    ++$invalid_ranks;
}
my $invalid_words = 0;
for my $word (
    undef, [], [1,2], [(1) x 14],
    [2,1,1,2, (3) x 2, (4) x 2, (5) x 2, (6) x 2, (7) x 2],
    [1,2,2,1, (3) x 2, (4) x 2, (5) x 2, (6) x 2, (7) x 2],
    [1,1,2,2,3,3,4,4,5,5,6,6,7,'x'],
    [1,1,2,2,3,3,4,4,5,5,6,6,7,8],
) {
    ok(!eval { rank_weaving($seven_pairs, $word); 1 }, '拒絕非法交織序列');
    ++$invalid_words;
}

# A returned word must not be shared with internal cached state.
my $input = [(4) x 7];
my $rank = Math::BigInt->new(2);
my $out = unrank_weaving($input, $rank);
my $before = [@$out];
$out->[0] = 999;
is_deeply(unrank_weaving($input, $rank), $before, '輸出陣列與內部資料不共用可變狀態');
is("$rank", '2', '重新測試後原 rank 仍不可變');

note("STAGE16_EXHAUSTIVE_PROFILES=$exhaustive_profiles");
note("STAGE16_EXHAUSTIVE_POSITIONS=$exhaustive_positions");
note('STAGE16_CATALAN7_RANKS=429');
note("STAGE16_LARGE_PROFILES=$large_profiles");
note("STAGE16_INVALID_PROFILES=$invalid_profiles");
note("STAGE16_INVALID_RANKS=$invalid_ranks");
note("STAGE16_INVALID_WORDS=$invalid_words");
note('STAGE16_FULL_YEAR_GENERATOR_NOT_VERIFIED');
done_testing;
