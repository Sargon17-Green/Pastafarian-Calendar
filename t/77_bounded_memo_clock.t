use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use lib 'lib','t/lib';
use Pastafari::WeavingMemoOracle;
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use FindBin qw($Bin);
use File::Spec;
my @vectors=([4,4,3,2],[5,4,3,2],[3,4,3,3]);
for my $len (@vectors) {
    my $fifo=Pastafari::WeavingMemoOracle->new(
        $len,{bounded_cache=>1,cache_limit=>4}
    );
    my $clock=Pastafari::WeavingMemoOracle->new(
        $len,{bounded_cache=>1,cache_limit=>4,cache_policy=>'clock'}
    );
    my $expected=countWeavingsPolynomial($len);
    is(''.$fifo->count_prefix([]),"$expected",
       '現有 FIFO 精確總數和多項式相等');
    is(''.$clock->count_prefix([]),"$expected",
       'clock 逐出和重新計數仍為相同精確 BigInt');
    for my $p ([],[1],[1,2],[1,2,1],[1,2,1,2]) {
        is(''.$clock->count_prefix($p),
           ''.$fifo->count_prefix($p),
           '每個指定前綴在兩種快取政策的 BigInt 相同');
    }
    my $d=$clock->diagnostics;
    is($d->{cache_policy},'clock','clock 由明確選項設定');
    cmp_ok($d->{entries},'<=',4,'任何時間最多四個 BigInt 快取狀態');
    cmp_ok($d->{evictions},'>',0,'小限額強迫 clock 進行真正逐出');
    cmp_ok($d->{second_chances},'>',0,'已有命中狀態曾獲 second-chance');
}
for my $bad (
    {cache_policy=>'clock'},
    {bounded_cache=>1,cache_policy=>'banana'},
    {bounded_cache=>1,cache_policy=>'clock',cache_limit=>200001},
) {
    my $ok=eval { Pastafari::WeavingMemoOracle->new([3,3,3,2],$bad);1 };
    ok(!$ok,'無效 clock 政策或超出 200000 的上限必須拒絕');
}
my $default=Pastafari::WeavingMemoOracle->new([2,2,2,2]);
is($default->diagnostics->{cache_policy},'fifo',
   '未指定 clock 的全部歷史工作仍沿用 FIFO');
done_testing;
