use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use lib 'lib', 't/lib';
use Pastafari::NormativeScroll qw(countWeavings unrankWeaving);

# _weave_counter 的內部狀態介面只接受合法可達的狀態；
# 因此先以完整獨立列舉驗證所選前綴存在有效延伸。
# 以完全枚舉所有「剩餘日數」的多重集合排列作為獨立參考。
# 逐一把既定前綴加回後，才檢查所有月份的首次與末次出現順序。
# 此模型不使用 DP 的轉移、快取或二項式公式。
sub brute_suffix ($lengths, $prefix) {
    my @remaining = @$lengths;
    $remaining[$_-1]-- for @$prefix;
    die "前綴超出月份日數\n" if grep { $_ < 0 } @remaining;
    my @word = @$prefix;
    my $count = 0;
    my $m = @$lengths;
    my $enumerate;
    $enumerate = sub {
        my $left = 0; $left += $_ for @remaining;
        if (!$left) {
            my (@first,@last);
            for my $p (0 .. $#word) {
                my $i = $word[$p];
                $first[$i] //= $p;
                $last[$i] = $p;
            }
            for my $i (2 .. $m) {
                return if $first[$i-1] >= $first[$i];
                return if $last[$i-1] >= $last[$i];
            }
            $count++;
            return;
        }
        for my $i (1 .. $m) {
            next if !$remaining[$i-1];
            $remaining[$i-1]--;
            push @word, $i;
            $enumerate->();
            pop @word;
            $remaining[$i-1]++;
        }
    };
    $enumerate->();
    return $count;
}
sub state_from_prefix ($lengths, $prefix) {
    my @remaining = @$lengths;
    my $opened = 0;
    for my $id (@$prefix) {
        $remaining[$id-1]--;
        $opened = $id if $id > $opened;
    }
    my $closed = 0;
    for my $value (@remaining) {
        last if $value > 0;
        $closed++;
    }
    return (\@remaining,$opened,$closed);
}

for my $case (
    { lengths => [2,2,2,2],
      prefixes => [ [],[1],[1,2],[1,1,2],[1,2,1,3],
                    [1,2,3],[1,1,2,2,3],[1,1,2,2,3,3] ] },
    { lengths => [1,1,1,1,1],
      prefixes => [ [],[1],[1,2],[1,2,3],[1,2,3,4] ] },
    { lengths => [2,1,2,1,2],
      prefixes => [ [],[1],[1,1,2],[1,1,2,3],[1,1,2,3,3,4] ] },
) {
    my $lengths = $case->{lengths};
    my $counter = Pastafari::NormativeScroll::_weave_counter($lengths);
    for my $prefix (@{$case->{prefixes}}) {
        my ($remaining,$opened,$closed) = state_from_prefix($lengths,$prefix);
        my $expected = brute_suffix($lengths,$prefix);
        ok($expected > 0, '所選前綴至少有一個有效的延伸');
        my $actual = $counter->($remaining,$opened,$closed);
        is(''.$actual, "$expected",
            '尚有未開啟月份時，DP 與完整獨立列舉一致：'
                .join('-',@$lengths).'/'.join(',',@$prefix));
        is(''.$counter->($remaining,$opened,$closed),"$expected",
            '相同計數器的快取再次查詢不改變結果');
    }
}

# 47 個月皆為單日，唯一合法序列是依序開啟再關閉。
# 這是原型驗證，不表示單日月份符合正式的 4..123 日契約。
my @short = (1) x 47;
is(''.countWeavings(\@short),'1','47 個尚未開啟月份只產生唯一序列');
is_deeply(unrankWeaving(\@short,1),[1..47],
    '47 個尚未開啟月份的首列仍為正確的連續名稱次序');

# 47 個長度 4 的月份：前 46 個已完全結束，尚有第 47 月未開啟。
# 此狀態在實際合法序列中可到達，應只剩唯一的全部 4 日排列。
my @long = (4) x 47;
my @rem = ((0) x 46,4);
my $large_counter = Pastafari::NormativeScroll::_weave_counter(\@long);
is(''.$large_counter->(\@rem,46,46),'1',
    '47 月合法長度與尚未開啟最後月份的狀態得到正確計數');

done_testing;
