use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use lib 'lib','t/lib';
use Pastafari::WeavingMemoOracle;
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
my @sets=([3,4,2,2],[4,4,3,2],[5,3,4,2]);
for my $lens (@sets) {
    my $unbounded=Pastafari::WeavingMemoOracle->new($lens);
    my $bounded=Pastafari::WeavingMemoOracle->new(
        $lens,{bounded_cache=>1,cache_limit=>4}
    );
    my $reference=countWeavingsPolynomial($lens);
    is(''.$unbounded->count_prefix([]),"$reference",
       '無驅逐原始 Oracle 等於位置多項式精確總數');
    is(''.$bounded->count_prefix([]),"$reference",
       '快取驅逐後所有組合完工數不變');
    my $d=$bounded->diagnostics;
    ok($d->{evictions}>0,'小型四月份刻意觸發 FIFO 逐出');
    cmp_ok($d->{entries},'<=',4,'任何時刻最多四項記憶式 BigInt');
    for my $prefix ([1],[1,1],[1,2],[1,2,1],[1,2,2],[1,2,3]) {
        my ($got,$old);
        my $ok=eval {
            $got=$bounded->count_prefix($prefix);
            $old=$unbounded->count_prefix($prefix);
            1;
        };
        ok($ok,'固定測試前綴全部合法且可成功被兩個 Oracle 查詢');
        next if !$ok;
        is("$got","$old",
           'FIFO 淘汰及重新遞迴後特定前綴完工數相同');
    }
    is(''.$bounded->count_prefix([]),"$reference",
       '多輪前綴查询之後完整總數依然不變');
    cmp_ok($bounded->diagnostics->{entries},'<=',4,
       '重入前綴查詢不突破私有快取硬上限');
}
for my $bad (
    {bounded_cache=>1,cache_limit=>0},
    {bounded_cache=>1,cache_limit=>200001},
    {bounded_cache=>1,cache_limit=>'abc'},
    {cache_limit=>10},
    {unexpected=>1},
) {
    my $ok=eval {
        Pastafari::WeavingMemoOracle->new([2,2,2,2],$bad);
        1;
    };
    ok(!$ok,'非法或未啟動的快取選項必須被拒絕');
}
my $default=Pastafari::WeavingMemoOracle->new([3,3,2,2]);
is($default->diagnostics->{cache_limit},200000,
   '舊有 Oracle 仍持有 200000 項嚴格 hard-fail 預設值');
is($default->diagnostics->{evictions},0,'舊有 Oracle 絕不靜默逐出快取');
done_testing;
