use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib', 't/lib';
use Pastafari::NormativeScroll qw(countWeavings);
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);

# 兩套模型有各自獨立的狀態表示與轉移規則。
my @cases = ([],[1],[4],[2,2,2,2],[4,4,4],[4,123,4],
             [(4)x6],[(4)x8]);
for my $m (1 .. 4) {
    my $rec;
    $rec = sub ($list) {
        if (@$list == $m) {
            push @cases, [@$list];
            return;
        }
        $rec->([@$list,$_]) for 1 .. 4;
    };
    $rec->([]);
}
for my $lengths (@cases) {
    my %stats;
    my $got = countWeavingsPolynomial($lengths,\%stats);
    my $expected = countWeavings($lengths);
    is("$got","$expected",
        "首次/末次位置分布與逐日 DP 一致：".join('-',@$lengths));
    cmp_ok($stats{max_frontier},'>=',0,'非負稽核分布大小');
    my $days = 0; $days += $_ for @$lengths;
    is($stats{total_days}, $days, '模型記錄的總日數正確');
}
my %stats;
my $first = countWeavingsPolynomial([(4)x12],\%stats);
ok($first > 0, '12 個四日月份有可行解，無需指數型剩餘向量 DP');
is($stats{stages},11,'12 個月份正確執行 11 個插入階段');
cmp_ok($stats{max_frontier},'<',10000,'二維分布在 48 日以內有界');
my $second = countWeavingsPolynomial([(4)x12]);
is("$first","$second",'重複執行得到完全相同的大整數');
for my $bad ([0,4],[-1,4],['1.5',2],[{},1],[6000],[(4)x1500]) {
    my $ok=eval { countWeavingsPolynomial($bad);1 };
    ok(!$ok,'拒絕錯誤或超過稽核上限的長度');
    like($@,qr/月份長度|月份日數|總日數上限/,'保留明確的輸入拒絕原因');
}
done_testing;
