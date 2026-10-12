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

# 在只剩一個合法候選的情況，每一日都直接用母前綴的計數。
for my $m (1,2,3,8,47) {
    my $lengths = [(1)x$m];
    my %stats;
    is_deeply(unrankWeavingPolynomial($lengths,1,\%stats), [1 .. $m],
        "單日 $m 月份依字典序唯一排序");
    is($stats{suffix_calls},0,"單日 $m 月份不必重算任何後綴");
    is($stats{shortcut_steps},$m,"單日 $m 月份皆可推導唯一分支");
    is($stats{considered},$m,"單日 $m 月份每一步只需一個候選");
}

# 在不同排名與合法月份長度之下保持與原有規範解碼完全相同。
for my $lengths ([2,2],[2,2,2],[3,3,3],[4,4,4],[4,4,4,4],[4,4,4,4,4]) {
    my $total=countWeavingsPolynomial($lengths);
    my @ranks = (1, 2, $total->copy->bdiv(2), $total->copy);
    my %seen;
    for my $rank (@ranks) {
        next if $rank < 1 || $rank > $total || $seen{"$rank"}++;
        my %stats;
        my $candidate=unrankWeavingPolynomial($lengths,$rank,\%stats);
        is_deeply($candidate,unrankWeaving($lengths,$rank),
            '保留獨立規範的字典序列：'.join('-',@$lengths)."/$rank");
        is($stats{suffix_calls}+$stats{shortcut_steps},$stats{considered},
            '所考察候選全數由真實或推導計數涵蓋');
        cmp_ok($stats{shortcut_steps},'>=',1,
            '至少最後一日可利用母前綴分割');
        cmp_ok($stats{suffix_calls},'<',$stats{considered},
            '相較逐一重算每一候選確實減少呼叫次數');
    }
}
# 包含無效輸入拒絕、以及外部 Math::BigInt 不被修改。
my $rank=Math::BigInt->new(2);
is_deeply(unrankWeavingPolynomial([2,2],$rank),[1,2,1,2],
    '大整數排名二不受捷徑影響');
is("$rank",'2','大整數排名物件保持原值');

done_testing;
