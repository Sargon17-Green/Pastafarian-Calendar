use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib','t/lib';
use Pastafari::WeavingUnrank qw(unrankWeavingPolynomial);
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::NormativeScroll qw(unrankWeaving);

for my $lengths (
    [1], [1,1,1], [2,2], [4,4,4], [(4)x47],
    [68,(4)x46], [(4)x46,68], [(6)x17,(5)x30]
) {
    my @first;
    for my $j (1 .. @$lengths) {
        push @first, (($j) x $lengths->[$j-1]);
    }
    my @lengths_before = @$lengths;
    my $rank = Math::BigInt->bone;
    my %stats = (stale => 1);
    my $got = unrankWeavingPolynomial($lengths,$rank,\%stats);
    is_deeply($got,\@first,
        '第一名符合連續完整月份的最小字典序列：'.join('-',@$lengths));
    is($stats{first_rank_fastpath},1,'觸發第一名專用的非 DP 路徑');
    is($stats{suffix_calls},0,'第一名不呼叫任何多項式後綴計數');
    is($stats{shortcut_steps},$stats{days},'每個日子都可直接建構');
    is($stats{considered},$stats{days},'每個日子僅有一次建構步驟');
    is($stats{days},scalar(@$got),'回傳序列及診斷記錄日數相同');
    ok(!exists($stats{stale}),'不保留先前使用者診斷欄位');
    is("$rank",'1','第一名 BigInt 來源未被更改');
    is_deeply($lengths,\@lengths_before,'不修改月份長度輸入');
}

for my $lengths ([2,2],[2,2,2],[4,4,4]) {
    is_deeply(unrankWeavingPolynomial($lengths,1),
        unrankWeaving($lengths,1),'仍與規範 Oracle 的第一名一致');
}
my %second;
unrankWeavingPolynomial([2,2],2,\%second);
is($second{first_rank_fastpath},0,'非第一名仍走精確字典序分支演算');
done_testing;
