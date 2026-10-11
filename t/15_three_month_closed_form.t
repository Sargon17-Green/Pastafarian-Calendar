use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib', 't/lib';
use Pastafari::NormativeScroll qw(countWeavings unrankWeaving);

# 獨立閉式求和：刪去全部月份 3，月份 1/2 的序列必始於 1 而終於 2。
# 若前 k 日皆屬月份 1，首個 2 位在 k+1。將月份 3 插入其後空隙，
# 同時使最後一個空隙至少包含一個 3，便保持首次與末次順序。
sub binomial ($n, $k) {
    return Math::BigInt->bzero if $n < 0 || $k < 0 || $k > $n;
    my $result = Math::BigInt->bone;
    for my $i (1 .. $k) {
        $result->bmul($n-$k+$i);
        $result->bdiv($i);
    }
    return $result;
}
sub independent_three ($a,$b,$c) {
    my $sum = Math::BigInt->bzero;
    for my $k (1 .. $a) {
        my $base = $b == 1
            ? Math::BigInt->new($k == $a ? 1 : 0)
            : binomial($a-$k+$b-2,$a-$k);
        my $gaps = $a+$b-$k-1;
        my $inserts = binomial($c+$gaps-1,$gaps);
        $sum->badd($base->bmul($inserts));
    }
    return $sum;
}

for my $a (1 .. 5) {
    for my $b (1 .. 5) {
        for my $c (1 .. 5) {
            is(''.countWeavings([$a,$b,$c]),
                ''.independent_three($a,$b,$c),
                "三月求和與 DP 一致：$a/$b/$c");
        }
    }
}
for my $lengths ([4,4,4], [4,123,4], [12,12,12], [24,24,24]) {
    my ($a,$b,$c) = @$lengths;
    my $count = countWeavings($lengths);
    is("$count", ''.independent_three($a,$b,$c),
        "長月份求和完全一致：$a/$b/$c");
    is_deeply(unrankWeaving($lengths,1),
        [(1)x$a,(2)x$b,(3)x$c],
        "長月份最小字典序列：$a/$b/$c");
    is_deeply(unrankWeaving($lengths,$count),
        [1,2,(3)x($c-1),(2)x($b-2),(1)x($a-1),2,3],
        "長月份最大字典序列：$a/$b/$c");
}
done_testing;
