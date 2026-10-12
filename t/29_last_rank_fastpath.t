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

sub check_valid ($lengths,$word) {
    my $m=@$lengths;
    my @occ=(0)x$m;
    my (@first,@last);
    for my $pos (0 .. $#$word) {
        my $id=$word->[$pos];
        return 0 if $id<1 || $id>$m;
        $occ[$id-1]++;
        $first[$id] //= $pos;
        $last[$id]=$pos;
    }
    for my $j (1 .. $m) {
        return 0 if $occ[$j-1] != $lengths->[$j-1];
        if ($j>1) {
            return 0 unless $first[$j-1] < $first[$j];
            return 0 unless $last[$j-1] < $last[$j];
        }
    }
    return 1;
}

# 對所有小規模有效解直接與規範 Oracle 的最高排名比較。
for my $lengths (
    [1], [1,1,1], [2,2], [3,2,2], [4,4,4],
    [2,2,2,2], [4,4,4,4], [4,4,4,4,4]
) {
    my $rank=countWeavingsPolynomial($lengths);
    my %stats=(stale=>1);
    my $word=unrankWeavingPolynomial($lengths,$rank,\%stats);
    is_deeply($word,unrankWeaving($lengths,$rank),
        "字典序最後一名等於規範 Oracle：".join('-',@$lengths));
    ok(check_valid($lengths,$word),'最大排名序列符合全部規範順序與月份日數');
    is($stats{suffix_calls},0,'最大排名無須執行任何後綴計數');
    is($stats{shortcut_steps},$stats{days},'每個位置都由貪婪演算法完成');
    is($stats{considered},$stats{days},'貪婪演算法各步只選一個月份');
    is($stats{first_rank_fastpath}+$stats{last_rank_fastpath},1,
        '恰有一個極端排名捷徑，唯一排名時先選最小路徑');
    ok(!exists($stats{stale}),'稽核紀錄不保留舊狀態');
}

# 47 個合法月份、252 日，最高排名是超大 BigInt，
# 但貪婪建構不對每一日重新計算 47 月份後綴。
for my $lengths ([(4)x47], [68,(4)x46], [(4)x46,68],[(6)x17,(5)x30]) {
    my $rank=countWeavingsPolynomial($lengths);
    my $input=$rank->copy;
    my %stats;
    my $word=unrankWeavingPolynomial($lengths,$input,\%stats);
    ok(check_valid($lengths,$word),'47 月份最高排名合法：'.join('-',@$lengths));
    is($stats{suffix_calls},0,'47 月份的最高排名不呼叫後綴計數');
    is($stats{shortcut_steps},scalar(@$word),'47 月份每一步皆為貪婪選擇');
    is("$input","$rank",'輸入 BigInt 排名完全不變');
    is($stats{last_rank_fastpath},1,'啟動 47 月份最後排名捷徑');
}
done_testing;
