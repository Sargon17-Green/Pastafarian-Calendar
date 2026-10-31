use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib';
use Pastafari::Monster::MonthOccurrence qw(month_occurrence);
use Pastafari::Monster::WeavingPrimitive qw(count_weavings);

# 獨立基數編碼 oracle：枚舉所有 m^days 字串、完整字串才驗證。
# 不調用生產 DP／反排名演算法決定任何期待值。
sub enumerate_complete_words ($profile) {
    my $m = scalar @$profile;
    my $days = 0; $days += $_ for @$profile;
    my @accepted;
    for my $integer (0 .. $m ** $days - 1) {
        my $x = $integer;
        my @word = (0) x $days;
        for (my $i = $days - 1; $i >= 0; --$i) {
            $word[$i] = 1 + ($x % $m);
            $x = int($x / $m);
        }
        my @seen = (0) x $m;
        my @first = (-1) x $m;
        my @last = (-1) x $m;
        for my $i (0 .. $#word) {
            my $j = $word[$i] - 1;
            ++$seen[$j];
            $first[$j] = $i if $first[$j] == -1;
            $last[$j] = $i;
        }
        my $valid = 1;
        for my $j (0 .. $m - 1) {
            $valid = 0 if $seen[$j] != $profile->[$j];
            if ($j > 0) {
                $valid = 0 if $first[$j-1] >= $first[$j];
                $valid = 0 if $last[$j-1] >= $last[$j];
            }
        }
        push @accepted, \@word if $valid;
    }
    return \@accepted;
}

my $cases = 0;
for my $profile ([2,2], [2,2,2], [3,1,1], [1,2,2], [2,2,1,1], [2,2,2,2]) {
    my $oracle = enumerate_complete_words($profile);
    is("".count_weavings($profile), "".scalar(@$oracle), '獨立完整枚舉計數');
    for my $i (0 .. $#$oracle) {
        my $word = $oracle->[$i];
        my @prefix_counts = (0) x @$profile;
        for my $p (1 .. @$word) {
            my $expected_index = $word->[$p - 1];
            my $expected_day = ++$prefix_counts[$expected_index-1];
            my $actual = month_occurrence($profile, $i + 1, $p);
            is($actual->{monthIndex}, $expected_index, '規範月份索引');
            is("$actual->{dayInMonth}", "$expected_day", '月份內第幾日');
            ++$cases;
        }
    }
}
ok($cases >= 100, '至少一百個獨立位置投影');

my $p = [2,2];
for my $bad (0, -1, 5, 'x', '01', undef, [], Math::BigInt->new('9'x80)) {
    ok(!eval { month_occurrence($p,1,$bad); 1 }, '拒絕非法日位置');
}
for my $bad (0, -1, 'x', Math::BigInt->new('9'x80)) {
    ok(!eval { month_occurrence($p,$bad,1); 1 }, '拒絕非法排名');
}
for my $bad ([], [0], [25], [(1)x7]) {
    ok(!eval { month_occurrence($bad,1,1); 1 }, '拒絕非法月份配置');
}
my $immutable = [2,2,2];
my $orig = join ',', @$immutable;
my $big_rank = Math::BigInt->new(1);
my $big_position = Math::BigInt->new(3);
my $result = month_occurrence($immutable,$big_rank,$big_position);
is(join(',', @$immutable), $orig, '未改變傳入月份配置');
is("$big_rank", '1', '未改變傳入排名');
is("$big_position", '3', '未改變傳入日期位置');
$result->{dayInMonth}->badd(100);
is("$big_rank", '1', '輸出 BigInt 不與輸入共享可變記憶');

# 24 日只做有界首／末索引語意與邊界；不宣稱獨立全年 oracle。
my $large = [(4) x 6];
my $first = month_occurrence($large,1,1);
is($first->{monthIndex},1,'大案例首個標籤');
is("$first->{dayInMonth}",'1','大案例首日');
my $last = month_occurrence($large,1,24);
is($last->{monthIndex},6,'完整串末個月份標籤');
is("$last->{dayInMonth}",'4','完整串最後月份第 4 日');

note("STAGE04_MONTH_OCCURRENCE_SMALL_ORACLE_CASES=$cases");
note("STAGE04_FULL_CANONICAL_FIVE_FIELDS_NOT_VERIFIED");
done_testing;
