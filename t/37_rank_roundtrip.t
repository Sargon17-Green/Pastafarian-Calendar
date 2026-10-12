use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib','t/lib';
use Pastafari::WeavingRank qw(rankWeavingPolynomial);
use Pastafari::WeavingUnrank qw(unrankWeavingPolynomial);
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::NormativeScroll qw(unrankWeaving);

my $total_cases=0;
for my $lengths ([1],[1,1,1],[2,2],[2,3,2],[3,3,3],
                 [4,4,4],[2,2,2,2],[3,3,3,3],[4,4,4,4]) {
    my $maximum=countWeavingsPolynomial($lengths);
    my @ranks=(1,2,3,$maximum->copy->bdiv(2)->badd(1),
               $maximum->copy->bsub(1),$maximum->copy);
    my %seen;
    for my $rank (@ranks) {
        next if $rank<1 || $rank>$maximum || $seen{"$rank"}++;
        my $word=unrankWeaving($lengths,$rank);
        my @before=@$word;
        my %stats=(old=>1);
        my $actual=rankWeavingPolynomial($lengths,$word,\%stats);
        is("$actual","$rank",
            '獨立的逆向排名重建原始規範一基排名：'
                .join('-',@$lengths)."/$rank");
        is_deeply($word,\@before,'反向排名不修改既有完整月份序列');
        is($stats{days},scalar(@$word),'日數診斷與序列長度一致');
        ok(!exists($stats{old}),'診斷資料不保留上一呼叫的內容');
        is_deeply(unrankWeavingPolynomial($lengths,$actual),$word,
            '完整雙向往返等於規範 Oracle 的序列');
        $total_cases++;
    }
}
cmp_ok($total_cases,'>=',35,'已核對至少三十五個規範序列與其排名');

# 極大月份數，對最小字典序序列的反向排名必為一；
# 這不需要跑 47 個月份的指數型剩餘向量 DP。
for my $lengths ([(4)x47],[(6)x17,(5)x30]) {
    my @first;
    for my $j (1 .. @$lengths) {
        push @first,(($j)x$lengths->[$j-1]);
    }
    my $rank=rankWeavingPolynomial($lengths,\@first);
    is("$rank",'1','47 月份的最小字典序排名確定為一');
}
for my $invalid (
    [[2,2],[1,1,2]],
    [[2,2],[1,1,1,2]],
    [[2,2],[1,2,2,1]],
    [[2,2],[2,1,1,2]],
    [[2,2],[1,2,0,2]],
    [[2,2],[1,2,'NaN',2]]
) {
    my $ok=eval{rankWeavingPolynomial($invalid->[0],$invalid->[1]);1};
    ok(!$ok,'拒絕不合法的完整月份序列');
    like($@,qr/月份序列/,'給出精確的序列錯誤說明');
}
my @bigword=(Math::BigInt->bone,Math::BigInt->bone,
             Math::BigInt->new(2),Math::BigInt->new(2));
is(''.rankWeavingPolynomial([2,2],\@bigword),'1',
   '接受 Math::BigInt 標籤而不修改輸入');

done_testing;
