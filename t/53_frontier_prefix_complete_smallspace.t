use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib','t/lib';
use Pastafari::WeavingFrontierOracle qw(countWeavingsFrontier);
use Pastafari::WeavingSuffix qw(countWeavingSuffixPolynomial);

# 與模型不同的獨立 Oracle：逐字依首次／末次合法性枚舉
# 每條完整序列，再對每個曾經出現過的前綴直接計數。
# 測試前綴定義不依賴任何「指定前綴的完成數」演算法。
sub brute_prefix_histogram ($lengths) {
    my @remaining=@$lengths;
    my $months=@remaining;
    my $total=0; $total+=$_ for @remaining;
    my %counts;
    my $walk;
    $walk=sub ($opened,$closed,$prefix) {
        if (@$prefix==$total) {
            die "枚舉到尚未全部結束的月份\n" if $closed!=$months;
            for my $end (0..$#$prefix+1) {
                $counts{join(',',@$prefix[0..$end-1])}++;
            }
            return;
        }
        my $limit=$opened<$months ? $opened+1 : $months;
        for my $j (1..$limit) {
            next if !$remaining[$j-1];
            next if $remaining[$j-1]==1 && $j!=$closed+1;
            $remaining[$j-1]--;
            $walk->($j>$opened ? $j : $opened,
                    $remaining[$j-1]==0 ? $j : $closed,
                    [@$prefix,$j]);
            $remaining[$j-1]++;
        }
    };
    $walk->(0,0,[]);
    return \%counts;
}

my ($vectors,$prefix_checks)=(0,0);
for my $m (0..4) {
    my $walk;
    $walk=sub ($vec) {
        if (@$vec==$m) {
            my $counts=brute_prefix_histogram($vec);
            my $label=join('-',@$vec);
            for my $key (sort keys %$counts) {
                my @prefix=length($key) ? split(/,/,$key) : ();
                my %stats;
                my $actual=countWeavingsFrontier($vec,\%stats,\@prefix);
                is("$actual","$counts->{$key}",
                   "$label: 完整枚舉前綴 [$key] 的精確完成數");
                is("$actual","".countWeavingSuffixPolynomial($vec,\@prefix),
                   "$label: 第二種指定前綴多項式也吻合獨立枚舉");
                is($stats{total_days},(do {my $days=0;$days+=$_ for @$vec;$days}),
                   "$label: 診斷總日數仍是整個原始輸入");
                $prefix_checks++;
            }
            $vectors++;
            return;
        }
        for my $k (1..3) {
            $walk->([@$vec,$k]);
        }
    };
    $walk->([]);
}
is($vectors,121,'零至四個月、每月一至三日的 121 組全空間完成');
ok($prefix_checks>500,'實際比對超過五百個合法前綴');

my @L=(4,3,2,2);
my @source=(map {Math::BigInt->new($_)} @L);
my @snapshot=map {"$_"} @source;
for my $prefix (
    [2],             # 未按首次順序開啟第二月份
    [1,2,3,4,4],     # 最後月份企圖先於第一月份關閉
    [1,1,1,1,1],     # 同一月份超出其日數
    [0],[-1],[1.5],[Math::BigInt->new(5)],
) {
    my $ok=eval {countWeavingsFrontier(\@source,undef,$prefix);1};
    ok(!$ok,'拒絕非法前綴');
}
for my $bad (undef,{},42) {
    next if !defined($bad);
    my $ok=eval {countWeavingsFrontier(\@source,undef,$bad);1};
    ok(!$ok,'拒絕非 ARRAY 的前綴參數');
}
is_deeply([map {"$_"} @source],\@snapshot,
          '非法前綴不污染 BigInt 來源月份長度');
for my $prefix (
    [1,1,1,1,2,2,2,3,3,4,4],
    [1,2,1,1,1,2,2,3,3,4,4],
) {
    my $actual=countWeavingsFrontier(\@source,undef,$prefix);
    is("$actual",'1','完整合法前綴應只有一種空後綴');
}
done_testing;
