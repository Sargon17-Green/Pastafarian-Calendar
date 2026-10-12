use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib','t/lib';
use Pastafari::WeavingSuffix qw(countWeavingSuffixPolynomial);
use Pastafari::NormativeScroll qw(countWeavings);

# 每個前綴依序首次開啟第 1..m-1 月，僅有末月仍未開啟。
# 這些首月都已實際在前綴出現，故後續月 m 的首日自然較晚。
# 舊 Oracle 仍會驗證完整首次與末次序，作為獨立真值來源。
my $compared=0;
for my $m (2 .. 5) {
    my $generate;
    $generate = sub ($lengths) {
        if (@$lengths==$m) {
            my @prefix=(1 .. $m-1);
            my @remaining=@$lengths;
            $remaining[$_-1]-- for @prefix;
            my %stats;
            my $result=countWeavingSuffixPolynomial($lengths,\@prefix,\%stats);
            my $counter=Pastafari::NormativeScroll::_weave_counter($lengths);
            my $oracle=$counter->(\@remaining,$m-1,0);
            is("$result","$oracle",
                '只剩末月尚未首次開啟，乘積和規範計數一致：'
                    .join('-',@$lengths));
            is($stats{one_unopened_closed_form},1,
                '確實使用最後未開啟月份的精確乘積捷徑');
            ok(!exists $stats{full_open_closed_form},
                '未誤稱所有月份均已開啟');
            $compared++;
            return;
        }
        $generate->([@$lengths,$_]) for 2 .. 3;
    };
    $generate->([]);
}
cmp_ok($compared,'>=',60,'測試六十組具獨立 Oracle 的未開啟末月');

# 部分已開啟月份可能已依次結束，零值前綴亦應一致。
for my $lengths ([2,3,2,2],[3,3,2,3],[4,4,4,4]) {
    my @prefix=(1,2,3);
    push @prefix,(1)x($lengths->[0]-1);
    my @remaining=@$lengths;
    $remaining[$_-1]-- for @prefix;
    my %stats;
    my $got=countWeavingSuffixPolynomial($lengths,\@prefix,\%stats);
    my $oracle=Pastafari::NormativeScroll::_weave_counter($lengths);
    is("$got",''.$oracle->(\@remaining,3,1),
        '完成首月後，仍未開啟末月的閉式結果正確');
    is($stats{one_unopened_closed_form},1,
        '末月尚未開啟及已關閉前綴並存時仍使用閉式');
}
# 47 個月均長四日，只固定首 46 月的首日。
# 結果是正的大整數；此驗證不等同反排名中間位置通過。
my @months=(4)x47;
my @prefix=(1..46);
my %stats;
my $result=countWeavingSuffixPolynomial(\@months,\@prefix,\%stats);
cmp_ok($result,'>',0,'47 個月份之最後未開啟月仍有有效延伸');
is($stats{one_unopened_closed_form},1,
    '47 月份只有最後一月未開啟時採用精確閉式');
is($stats{days_remaining},142,'47x4 固定 46 日後，剩餘日數為 142');
done_testing;
