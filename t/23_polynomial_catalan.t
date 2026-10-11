use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib','t/lib';
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);

# 各標籤剛好出現兩次時，首次與末次出現皆依序，
# 等價於不允許巢狀配對的完美配對，數量是 Catalan 數。
sub catalan ($n) {
    my $answer=Math::BigInt->bone;
    for my $i (1 .. $n) {
        $answer->bmul($n+$i)->bdiv($i);
    }
    return $answer->bdiv($n+1);
}
for my $months (1 .. 12, 17, 47) {
    my $answer = countWeavingsPolynomial([(2)x$months]);
    is("$answer", ''.catalan($months),
        "月份數 $months 的二次出現序列完全符合獨立 Catalan 數");
}
my %stats;
my $valid = countWeavingsPolynomial([(4)x47],\%stats);
ok($valid > 0, '47 個合法四日月份的多項式精確計數為正');
is(length("$valid"),168,'47 個四日月份交織數為 168 位數');
is($stats{total_days},188,'47x4 共計 188 日');
is($stats{stages},46,'47 個月份逐次插入 46 次');
cmp_ok($stats{max_frontier}, '<=', 188*188,
    '狀態分布不超過二維尺寸的理論上界');
done_testing;
