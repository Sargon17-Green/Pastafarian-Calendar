use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib','t/lib';
use Pastafari::WeavingMemoOracle;
use Pastafari::WeavingSuffix qw(countWeavingSuffixPolynomial);
use Pastafari::WeavingFrontierOracle qw(countWeavingsFrontier);

# 已全部開啟的月份由獨立組合式直接給出，而不是
# 把每一個末月已開的狀態永久留在私有快取中。
for my $lengths (
    [2,2],
    [3,2,3],
    [3,2,4,2],
    [2,3,2,4],
) {
    my $c=Pastafari::WeavingMemoOracle->new($lengths);
    my $m=@$lengths;
    my @prefix=(1..$m);
    my $expected=countWeavingSuffixPolynomial($lengths,\@prefix);
    my $before=$c->diagnostics->{entries};
    my $first=$c->count_prefix(\@prefix);
    is("$first","$expected",'全開時的精確組合式符合另一套指定前綴模型');
    my $after=$c->diagnostics;
    is($after->{entries},$before,'全開後綴不會增加長期狀態快取項');
    ok($after->{closed_forms}>0,'全開確實呼叫精確直接公式');
    $first->badd(10_000);
    is(''.$c->count_prefix(\@prefix),"$expected",
       '直接公式回傳的 BigInt 變異不污染後續呼叫');
    my $repeated=$c->diagnostics;
    is($repeated->{entries},$before,
       '重複全開後綴查詢仍不加入可由公式得到的狀態');
    is(''.countWeavingsFrontier($lengths,undef,\@prefix),"$expected",
       '全開前綴還符合獨立逐層正向前沿模型');
}
# 極小零月和單月行為原先能快取；保留舊模型的
# 「至少一次真正快取命中」契約，避免改動既有 121 組全空間。
for my $v ([],[1],[3]) {
    my $counter=Pastafari::WeavingMemoOracle->new($v);
    $counter->count_prefix([]);
    $counter->count_prefix([]);
    ok($counter->diagnostics->{cache_hits}>0,
       '零／單月原本的可重入計數快取診斷仍然存在');
}
done_testing;
