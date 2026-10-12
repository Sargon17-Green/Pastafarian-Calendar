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

my ($verified,$total_hits,$total_misses)=(0,0,0);
for my $lengths ([2,2],[2,2,2],[3,3,3],[4,4,4],
                 [3,3,3,3],[4,4,4,4],[4,4,4,4,4]) {
    my $maximum=countWeavingsPolynomial($lengths);
    my @rank=(
        Math::BigInt->new(2),
        $maximum->copy->bdiv(3),
        $maximum->copy->bdiv(2)->badd(1),
        $maximum->copy->bsub(1),
    );
    my %seen;
    for my $rank (@rank) {
        next if $rank<=1 || $rank>=$maximum || $seen{"$rank"}++;
        my %stats=(stale=>777);
        my $word=unrankWeavingPolynomial($lengths,$rank,\%stats);
        is_deeply($word,unrankWeaving($lengths,$rank),
            '因式分解與原始規範字典序完全一致：'
               .join('-',@$lengths)."/$rank");
        is($stats{factored_suffix_calls},$stats{suffix_calls},
            '每個實際後綴查詢都走精確因式分解');
        cmp_ok($stats{future_cache_hits},'>=',0,
            '每次反排名都有獨立的未開啟月份快取命中數');
        cmp_ok($stats{future_cache_misses},'>=',0,
            '每次反排名都有獨立的未開啟月份快取未命中數');
        cmp_ok($stats{future_cache_hits}+$stats{future_cache_misses},
               '<=',$stats{suffix_calls},
               '全開啟月份毋須未開啟月份快取，其他呼叫均有紀錄');
        ok(!exists $stats{stale},'不洩漏呼叫前的診斷內容');
        $total_hits+=$stats{future_cache_hits};
        $total_misses+=$stats{future_cache_misses};
        $verified++;
    }
}
cmp_ok($verified,'>=',16,'驗證至少 16 個真實非極端排名');
cmp_ok($total_hits,'>=',1,
    '相同次序解碼的兄弟候選確實重用至少一個未開啟因子');
cmp_ok($total_misses,'>=',1,'未見過的未開啟因子必經精確計算');
my $input=Math::BigInt->new(2);
unrankWeavingPolynomial([2,2],$input);
is("$input",'2','跨快取 BigInt 排名輸入仍不可變');
done_testing;
