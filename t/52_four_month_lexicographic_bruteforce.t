use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib','t/lib';
use Pastafari::WeavingFrontierOracle qw(countWeavingsFrontier);
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::NormativeScroll qw(unrankWeaving);
use Pastafari::WeavingUnrank qw(unrankWeavingPolynomial);
use Pastafari::WeavingRank qw(rankWeavingPolynomial);

# 不用任何受測排名／反排名器生成預期答案：依候選標籤的
# 升序完成每一個合法單詞；枚舉順序本身就是字典序。
sub enumerate_lexicographic ($lengths) {
    my @remaining=@$lengths;
    my $months=@$lengths;
    my $days=0; $days+=$_ for @remaining;
    my @words;
    my $walk;
    $walk=sub ($opened,$closed,$prefix) {
        if (@$prefix==$days) {
            die "枚舉到未關閉的葉節點\n" if $closed!=$months;
            push @words,[@$prefix];
            return;
        }
        my $limit=$opened<$months ? $opened+1 : $months;
        for my $j (1..$limit) {
            next if !$remaining[$j-1];
            next if $remaining[$j-1]==1 && $j!=$closed+1;
            my $next_opened=$j>$opened ? $j : $opened;
            $remaining[$j-1]--;
            my $next_closed=$remaining[$j-1]==0 ? $j : $closed;
            $walk->($next_opened,$next_closed,[@$prefix,$j]);
            $remaining[$j-1]++;
        }
    };
    $walk->(0,0,[]);
    return \@words;
}

my ($vectors,$comparisons,$full_ranks)=(0,0,0);
my $walk;
$walk=sub ($vector) {
    if (@$vector==4) {
        my $words=enumerate_lexicographic($vector);
        my $total=scalar @$words;
        my $label=join('-',@$vector);
        is("".countWeavingsFrontier($vector),"$total",
           "$label: 可重放前沿精確計數與枚舉字典數一致");
        is("".countWeavingsPolynomial($vector),"$total",
           "$label: 位置矩陣與獨立完整枚舉字典數一致");
        my @ranks;
        if ($total<=20) {
            @ranks=1..$total;
            $full_ranks+=$total;
        } else {
            @ranks=(1,2,int($total/4),int($total/2)+1,
                    int($total*3/4),$total-1,$total);
        }
        my %seen;
        @ranks=grep {!$seen{$_}++} @ranks;
        for my $rank (@ranks) {
            my $oracle=$words->[$rank-1];
            my $by_norm=unrankWeaving($vector,$rank);
            my $by_poly=unrankWeavingPolynomial($vector,$rank);
            is_deeply($by_norm,$oracle,
                "$label/$rank: 深度優先規範解碼與獨立完整枚舉字典序一致");
            is_deeply($by_poly,$oracle,
                "$label/$rank: 多項式解碼與獨立完整枚舉字典序一致");
            is("".rankWeavingPolynomial($vector,$oracle),"$rank",
                "$label/$rank: 獨立正向排名精確對照詞典原始序號");
            $comparisons++;
        }
        if ($label eq '3-3-3-3' || $label eq '2-2-2-2') {
            my $rank=int($total/2)+1;
            my $oracle=$words->[$rank-1];
            my $opts={
                profile_engine=>'stream-indexed',
                max_temp_file_bytes=>1048576,
            };
            my %unrank_stats;
            my $stream_word=unrankWeavingPolynomial(
                $vector,$rank,\%unrank_stats,$opts);
            is_deeply($stream_word,$oracle,
                "$label: 索引式解碼保持獨立枚舉字典序");
            my %rank_stats;
            is("".rankWeavingPolynomial($vector,$stream_word,\%rank_stats,$opts),
                "$rank","$label: 索引式正向排名重建原始字典序");
            is($unrank_stats{indexed_profile_builds}//0,1,
               "$label: 實際建有磁碟反序直方圖");
            is($rank_stats{indexed_profile_builds}//0,1,
               "$label: 正向流程獨立建表");
        }
        $vectors++;
        return;
    }
    for my $x (1..3) {
        $walk->([@$vector,$x]);
    }
};
$walk->([]);
is($vectors,81,'四個月份、每月 1..3 日：81 組全空間全部枚舉');
ok($comparisons>=81,'全部向量至少核對一項字典序排名');
ok($full_ranks>=42,'小規模向量按全部一基排名逐一核對');
done_testing;
