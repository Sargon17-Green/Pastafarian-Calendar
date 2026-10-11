use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib', 't/lib';
use Pastafari::NormativeScroll qw(countWeavings unrankWeaving);

# 對照無須 DP 的二月份公式。
sub binomial ($n, $k) {
    my $x = Math::BigInt->bone;
    for my $i (1 .. $k) {
        $x->bmul($n-$k+$i);
        $x->bdiv($i);
    }
    return $x;
}

for my $lengths (
    [4,4], [123,123], [255,1], [256,1], [256,2], [1,256], [257,1],
) {
    my ($a,$b) = @$lengths;
    my $expected = binomial($a+$b-2,$a-1);
    is(''.countWeavings($lengths), "$expected",
        "二月份的壓縮與非壓縮索引鍵，計數都正確：$a/$b");
    is_deeply(unrankWeaving($lengths,1),
        [(1)x$a,(2)x$b],
        "首列無論使用何種鍵格式都正確：$a/$b");
    my $last = unrankWeaving($lengths,$expected);
    is_deeply($last,[1,(2)x($b-1),(1)x($a-1),2],
        "末列無論使用何種鍵格式都正確：$a/$b");
}

for my $n (1,4,123,255,256,257) {
    is(''.countWeavings([$n]), '1',
        "單月份鍵長度過渡後，計數為一：$n");
    is_deeply(unrankWeaving([$n],1), [(1)x$n],
        "單月份鍵長度過渡後，列為連續日：$n");
}

for my $lengths ([1,1,1],[2,3,4],[4,4,4],[4,123,4],[4,4,4,4]) {
    my $original = [@$lengths];
    my $a = countWeavings($lengths);
    my $first = unrankWeaving($lengths,1);
    my $last = unrankWeaving($lengths,$a);
    is_deeply($lengths,$original,'鍵壓縮不修改來源月份長度');
    is(scalar(@$first),scalar(@$last),'首末列擁有相同總日數');
    my $stable = "$a";
    $a->badd(99);
    is(''.countWeavings($lengths),$stable,'外部修改計數副本不改變後續計數');
}
done_testing;
