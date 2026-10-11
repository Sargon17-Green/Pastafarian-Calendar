use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib', 't/lib';
use Pastafari::NormativeScroll qw(countWeavings unrankWeaving);

# 列舉全部多重集合排列，最後才以首次和末次出現順序篩選。
# 此測試模型刻意不使用生產計數器的開啟/關閉動態規劃。
sub enumerate_by_filter ($lengths) {
    my @remaining = @$lengths;
    my @sequence;
    my @valid;
    my $m = scalar @$lengths;
    my $walk;
    $walk = sub {
        my $left = 0;
        $left += $_ for @remaining;
        if ($left == 0) {
            my (@first, @last);
            for my $pos (0 .. $#sequence) {
                my $label = $sequence[$pos];
                $first[$label] //= $pos;
                $last[$label] = $pos;
            }
            for my $label (2 .. $m) {
                return if $first[$label - 1] >= $first[$label];
                return if $last[$label - 1] >= $last[$label];
            }
            push @valid, [@sequence];
            return;
        }
        for my $label (1 .. $m) {
            next if $remaining[$label - 1] <= 0;
            $remaining[$label - 1]--;
            push @sequence, $label;
            $walk->();
            pop @sequence;
            $remaining[$label - 1]++;
        }
    };
    $walk->();
    return \@valid;
}

sub binomial ($n, $k) {
    my $r = Math::BigInt->bone;
    for my $j (1 .. $k) {
        $r->bmul($n - $k + $j);
        $r->bdiv($j);
    }
    return $r;
}

for my $lengths (
    [1,1,1,1], [2,2,2,2], [3,2,2,2], [4,4,4],
) {
    my $label = join('-', @$lengths);
    my $reference = enumerate_by_filter($lengths);
    my $n = scalar @$reference;
    is(''.countWeavings($lengths), "$n", "完整多重排列篩選的計數 $label");
    my @ranks = $n <= 100 ? (1 .. $n)
       : (1, 2, int($n/3), int(2*$n/3), $n - 1, $n);
    my %seen;
    for my $rank (@ranks) {
        next if $seen{$rank}++;
        is_deeply(unrankWeaving($lengths,$rank), $reference->[$rank-1],
            "四月或三月交織的字典序反排名 $label/$rank");
    }
}

# 兩個非空月份：首日只能屬於月份 1，末日只能屬於月份 2。
# 中間位置自由交織，總數為 C(a+b-2,a-1)，不必建構任何 DP。
my $long_weaving_warnings = '';
{
    local $SIG{__WARN__} = sub { $long_weaving_warnings .= shift };
    for my $pair ([4,4], [4,123], [123,4], [123,123]) {
        my ($a,$b) = @$pair;
        my $expected = binomial($a+$b-2,$a-1);
        my $count = countWeavings($pair);
        is("$count","$expected","兩個合法月份 $a/$b 的組合數獨立公式");
        my $first = unrankWeaving($pair,1);
        my $last = unrankWeaving($pair,$count);
        is_deeply($first, [(1)x$a, (2)x$b],
            "兩個合法月份 $a/$b 的最小字典序列");
        is_deeply($last, [1,(2)x($b-1),(1)x($a-1),2],
            "兩個合法月份 $a/$b 的最大字典序列");
        my @actual_counts=(0,0);
        $actual_counts[$_-1]++ for @$last;
        is_deeply(\@actual_counts,[$a,$b],
            "兩個月份 $a/$b 的大排名保留全部日數");
    }
}
is($long_weaving_warnings, '', '合法長月份之計數與反排名不產生遞迴或其他警告');
done_testing;
