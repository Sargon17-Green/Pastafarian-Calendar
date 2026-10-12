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

my ($triggered_low,$triggered_high,$ranks)=(0,0,0);
for my $lengths ([2,2],[2,2,2],[3,3,3],[4,4,4],[4,4,4,4],[4,4,4,4,4]) {
    my $total=countWeavingsPolynomial($lengths);
    my @ranks=($total->copy->bdiv(2),$total->copy->bdiv(2)->badd(1),
               Math::BigInt->new(2),$total->copy->bsub(1));
    my %seen;
    for my $rank (@ranks) {
        next if $rank<=1 || $rank >= $total || $seen{"$rank"}++;
        my $before="$rank";
        my %stats=(stale=>1);
        my $got=unrankWeavingPolynomial($lengths,$rank,\%stats);
        is_deeply($got,unrankWeaving($lengths,$rank),
            '非極端排名在內部區塊套用貪婪尾段，仍符合規範：'
              .join('-',@$lengths)."/$rank");
        is("$rank",$before,'外部排名物件未被改動');
        is($stats{suffix_calls}+$stats{shortcut_steps},$stats{considered},
            '每個候選由多項式或無損推導涵蓋');
        cmp_ok($stats{tail_shortcut_days},'<=',$stats{days},
            '尾段直接構造長度不超過總日數');
        is($stats{first_rank_fastpath},0,'非全域第一名不走首名路徑');
        is($stats{last_rank_fastpath},0,'非全域最後名不走末名路徑');
        ok(!exists($stats{stale}),'沒有洩漏舊的診斷狀態');
        $triggered_low++ if $stats{tail_shortcut_kind}==1;
        $triggered_high++ if $stats{tail_shortcut_kind}==2;
        $ranks++;
    }
}
cmp_ok($ranks,'>=',12,'已核對多個中位及近極端排名');
cmp_ok($triggered_low,'>=',1,'存在以局部最小排名完成的真實例子');
cmp_ok($triggered_high,'>=',1,'存在以局部最大排名完成的真實例子');
done_testing;
