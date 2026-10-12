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

# 數學上，全已開啟的剩餘月份若同長 k 且 m 個月份皆未結束，
# 其末次出現順序的所有相對次序因月份標籤置換完全對稱：
# (m*k)! / ((k!)^m * m!)。與下面的新二項乘積迭代無關。
sub factorial ($n) {
    my $result=Math::BigInt->bone;
    $result->bmul($_) for 2 .. $n;
    return $result;
}
sub independent_symmetric ($months,$remaining_each) {
    my $num=factorial($months*$remaining_each);
    my $den=factorial($remaining_each)->bpow($months)
        ->bmul(factorial($months));
    my $mod=$num->copy->bmod($den);
    die "對稱性商數竟非整數\n" unless $mod->is_zero;
    return $num->bdiv($den);
}
my $examples=0;
for my $m (2 .. 5) {
    my $generate;
    $generate=sub ($lengths) {
        if (@$lengths==$m) {
            my @prefix=(1 .. $m);
            my %stats;
            my $actual=countWeavingSuffixPolynomial($lengths,\@prefix,\%stats);
            my $expected=Pastafari::NormativeScroll::_weave_counter($lengths);
            my @remaining=map {$_-1} @$lengths;
            my $norm=$expected->(\@remaining,$m,0);
            is("$actual","$norm",
                '全已開啟後綴閉式與原始規範 DP 一致：'.join('-',@$lengths));
            is($stats{full_open_closed_form},1,'新精確閉式路徑已啟用');
            $examples++;
            return;
        }
        $generate->([@$lengths,$_]) for 2 .. 4;
    };
    $generate->([]);
}
cmp_ok($examples,'>=',100,'涵蓋一百個以上的全已開啟月份模式');

for my $m (3,6,17,47) {
    my $lengths=[(4)x$m];
    my @prefix=(1..$m);
    my %stats;
    my $result=countWeavingSuffixPolynomial($lengths,\@prefix,\%stats);
    my $expected=independent_symmetric($m,3);
    is("$result","$expected",
        "全 $m 月份已開啟，末次次序符合獨立多重集合對稱性");
    is($stats{full_open_closed_form},1,'47 月份依然能使用閉式公式');
    is($stats{days_remaining},3*$m,'仍正確記錄剩餘日數');
}
# 如果開啟的月份中已有一個依次結束，也應由相同乘積公式
# 對剩下月份作精確計數，不得依賴第一個仍未關閉的月份標籤。
for my $lengths ([2,2,2,2],[4,4,4],[4,5,6,4]) {
    my @prefix=(1..@$lengths);
    push @prefix,1 for 2 .. $lengths->[0];
    my %stats;
    my $actual=countWeavingSuffixPolynomial($lengths,\@prefix,\%stats);
    my @rem=@$lengths;
    $rem[$_-1]-- for @prefix;
    my $counter=Pastafari::NormativeScroll::_weave_counter($lengths);
    is("$actual",''.$counter->(\@rem,scalar(@$lengths),1),
        '首月已關閉後，末次順序閉式仍相等');
    is($stats{full_open_closed_form},1,'已關閉前綴也使用精確閉式');
}
done_testing;
