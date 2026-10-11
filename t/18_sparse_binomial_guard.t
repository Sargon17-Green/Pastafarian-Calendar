use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib', 't/lib';
use Pastafari::NormativeScroll qw(countWeavings);

# 這是獨立乘法公式，沒有呼叫被測 Pascal 表或其快取。
sub choose_exact ($n, $k) {
    my $answer = Math::BigInt->bone;
    $k = $n-$k if $k > $n-$k;
    for my $i (1 .. $k) {
        $answer->bmul($n-$k+$i)->bdiv($i);
    }
    return $answer;
}

# 全部月份已經首次開啟，且最後出現次序固定。
# 以下呼叫刻意使用 _weave_counter 的測試專用狀態介面。
for my $pair (
    [4,4],
    [129,129],       # n=256 / Pascal 邊界
    [130,130],       # n=258 / 按需 BigInt 乘除
    [257,257],       # n=512 / 必須避開二次方表格
    [301,301],       # n=600 / 大於單位元組上限
) {
    my ($a,$b) = @$pair;
    my $lengths = [$a+1,$b+1];
    my $counter = Pastafari::NormativeScroll::_weave_counter($lengths);
    my $expected = choose_exact($a+$b-2,$a-1);
    my $actual = $counter->([$a,$b],2,0);
    is("$actual","$expected", "大整數及快取邊界的精確計數：$a/$b");
    my $first = "$actual";
    $actual->badd(777);
    is(''.$counter->([$a,$b],2,0),$first,
        "計數結果是私有副本：$a/$b");
}
my $open_count = countWeavings([4,123,4]);
ok($open_count > 0, '正式月份長度的完整 DP 仍返回正整數');
done_testing;
