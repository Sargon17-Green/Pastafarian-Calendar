use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib','t/lib';
use Pastafari::WeavingSuffixFactor qw(countWeavingSuffixFactored);
use Pastafari::WeavingSuffix qw(countWeavingSuffixPolynomial);
use Pastafari::NormativeScroll qw(unrankWeaving);
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);

# 直接取真正規範反排名的合法前綴，不用本模型產生前綴。
my $cases=0;
for my $lengths ([1,1,1],[2,2,2],[2,3,2],[3,3,3],
                 [4,4,4],[2,2,2,2],[4,4,4,4],[2,3,2,3]) {
    my $total=countWeavingsPolynomial($lengths);
    my @ranks=(1,2,$total->copy->bdiv(2)->badd(1),$total);
    my %seen;
    for my $rank (@ranks) {
        next if $rank<1 || $rank>$total || $seen{"$rank"}++;
        my $word=unrankWeaving($lengths,$rank);
        my $days=scalar @$word;
        for my $n (0 .. $days) {
            my @prefix=$n ? @$word[0 .. $n-1] : ();
            my %cache;
            my %stats;
            my $result=countWeavingSuffixFactored($lengths,\@prefix,
                                                  \%cache,\%stats);
            my $original=countWeavingSuffixPolynomial($lengths,\@prefix);
            is("$result","$original",
                '精確分解與原本完整多項式結果一致：'
                .join('-',@$lengths)."/$rank/$n");
            is($stats{factor_calls},1,'每個前綴精確計入一次因式分解');
            $cases++;
        }
    }
}
cmp_ok($cases,'>=',200,'分解已對比至少兩百個真實規範前綴');

# 兩個不同的合法前綴有相同已開啟月份數和相同 T 時，
# 未開啟後綴因子必相同，而已開啟的最後次序因子可不同。
my @lengths=(4,4,4,4,4,4);
my %shared;
my %diagnostic;
for my $prefix ([1,2,3,1],[1,2,3,2],[1,2,3,3]) {
    my $actual=countWeavingSuffixFactored(\@lengths,$prefix,
                                           \%shared,\%diagnostic);
    is("$actual",''.countWeavingSuffixPolynomial(\@lengths,$prefix),
        '相同 (opened,T) 的不同有效前綴共享未開啟因子');
}
is($diagnostic{future_cache_misses},1,'同類未開啟因子只計一次');
is($diagnostic{future_cache_hits},2,'後兩組命中私有快取');
my @other=(3,3,3,3,3,3);
countWeavingSuffixFactored(\@other,[1,2,3,1],\%shared,\%diagnostic);
is($diagnostic{future_cache_misses},2,'共用容器的不同月份長度不會誤命中');
my $snap=countWeavingSuffixFactored(\@lengths,[1,2,3,1],\%shared);
$snap->badd(999);
is(''.countWeavingSuffixFactored(\@lengths,[1,2,3,1],\%shared),
   ''.countWeavingSuffixPolynomial(\@lengths,[1,2,3,1]),
   '修改已回傳 BigInt 不得污染快取');

# 三個 47 月份且尚有至少 2 月未開啟的有效前綴；
# 這裡只比較精確完工數，不宣稱中位排名已能在時限內解碼。
for my $L ([(4)x47],[(6)x17,(5)x30]) {
    my @prefix=(1,2,3);
    is(''.countWeavingSuffixFactored($L,\@prefix),
       ''.countWeavingSuffixPolynomial($L,\@prefix),
       '47 月份兩種不同分布之中段前綴精確分解');
}
for my $bad ([2],[1,3],[1,2,2,2,2],[1,2,2,2,2,1]) {
    my $ok=eval {countWeavingSuffixFactored([4,4],$bad);1};
    ok(!$ok,'拒絕不合法前綴');
    like($@,qr/月份前綴/,'保留明確前綴拒絕說明');
}
done_testing;
