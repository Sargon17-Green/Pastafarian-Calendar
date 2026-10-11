use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib', 't/lib';
use Pastafari::NormativeScroll qw(countWeavings unrankWeaving);

# 針對「所有月份已經出現」狀態，直接完整列舉剩餘日子；
# 此枚舉完全不依賴 DP、二項係數或受測狀態計數器。
sub brute_last_order ($remaining) {
    my @counts = @$remaining;
    my @word;
    my $valid = 0;
    my $walk;
    $walk = sub {
        my $n = 0;
        $n += $_ for @counts;
        if ($n == 0) {
            my @last;
            for my $i (0 .. $#word) {
                $last[$word[$i]] = $i;
            }
            my $previous = -1;
            for my $j (0 .. $#$remaining) {
                next if $remaining->[$j] == 0;
                return if $last[$j] <= $previous;
                $previous = $last[$j];
            }
            $valid++;
            return;
        }
        for my $j (0 .. $#counts) {
            next if $counts[$j] == 0;
            $counts[$j]--;
            push @word, $j;
            $walk->();
            pop @word;
            $counts[$j]++;
        }
    };
    $walk->();
    return $valid;
}

for my $original ([3,3,3], [3,3,3,3]) {
    my $m = scalar @$original;
    my $counter = Pastafari::NormativeScroll::_weave_counter($original);
    my @vectors;
    if ($m == 3) {
        for my $a (1 .. 3) {
            for my $b (1 .. 3) {
                for my $c (1 .. 3) {
                    push @vectors, [$a,$b,$c];
                }
            }
        }
    } else {
        @vectors = ([2,2,2,2],[0,2,2,2],[0,0,2,2],[0,0,0,2]);
    }
    for my $remaining (@vectors) {
        # closed 是已歸零的最長前綴；opened=m 表示首次出現條件已滿足。
        my $closed = 0;
        for my $n (@$remaining) {
            last if $n != 0;
            $closed++;
        }
        my $expected = brute_last_order($remaining);
        my $actual = $counter->($remaining,$m,$closed);
        is("$actual", "$expected",
            '所有月份已開啟時，閉式乘積與完整排列列舉相同：'
                . join('-', @$remaining));
    }
}

# 額外檢查尚未全數開啟的入口仍返回原始的規範語意。
for my $lengths ([1,1,1],[2,2,2],[4,4,4],[4,123,4]) {
    my $total = countWeavings($lengths);
    ok($total >= 1, '來源月份交織計數仍為正');
    my $first = unrankWeaving($lengths,1);
    my $last = unrankWeaving($lengths,$total);
    is(scalar(@$first),scalar(@$last),'首末排名輸出的總長度一致');
}

# 所有月份剩餘日數相等時，各種「最後一次出現」的相對排序
# 透過月份標籤置換形成等勢集合；完整排列數正好平均分成 m! 類。
# 此為獨立的對稱性證明，而非受測二項係數乘積的重寫。
sub factorial ($n) {
    my $result = Math::BigInt->bone;
    $result->bmul($_) for 2 .. $n;
    return $result;
}
for my $months (3,5,17,47) {
    my @lengths = (4) x $months;
    my @remaining = (3) x $months;
    my $expected = factorial(3*$months);
    my $divisor = Math::BigInt->new(6)->bpow($months);
    $divisor->bmul(factorial($months));
    my $remainder = $expected->copy->bmod($divisor);
    is("$remainder", '0', "月份數 $months：對稱性推導有整數商");
    $expected->bdiv($divisor);
    my $counter = Pastafari::NormativeScroll::_weave_counter(\@lengths);
    my $actual = $counter->(\@remaining, $months, 0);
    is("$actual", "$expected",
        "月份數 $months：所有月份已開啟時，計數符合多重集合排列的對稱性");
}

done_testing;
