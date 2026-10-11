use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use lib 'lib','t/lib';
use Pastafari::WeavingSuffix qw(countWeavingSuffixPolynomial);
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::NormativeScroll qw(countWeavings);

# 將原始「全部合法完成序列」直接完整枚舉，建立每個前綴的
# 完工數表。稽核模型只查表，沒有複用多項式模型的任何轉移。
sub brute_prefix_counts ($lengths) {
    my $m = scalar @$lengths;
    my @remaining = @$lengths;
    my @word;
    # Enumerate complete words and accumulate every prefix, not only leaves.
    my %prefix_count;
    my $complete;
    $complete = sub ($opened,$closed) {
        if (!grep { $_ } @remaining) {
            for my $n (0 .. $#word+1) {
                $prefix_count{join(',',@word[0 .. $n-1])}++ if $n > 0;
                $prefix_count{''}++ if $n == 0;
            }
            return;
        }
        for my $j (1 .. $m) {
            next if !$remaining[$j-1];
            my ($o,$c)=($opened,$closed);
            if ($remaining[$j-1] == $lengths->[$j-1]) {
                next if $j != $opened+1;
                $o = $j;
            }
            if ($remaining[$j-1] == 1) {
                next if $j != $closed+1;
                $c = $j;
            }
            $remaining[$j-1]--;
            push @word,$j;
            $complete->($o,$c);
            pop @word;
            $remaining[$j-1]++;
        }
    };
    $complete->(0,0);
    return \%prefix_count;
}

my $cases=0;
for my $m (1 .. 4) {
    my $generate;
    $generate = sub ($prefix) {
        if (@$prefix == $m) {
            my $ground = brute_prefix_counts($prefix);
            for my $key (keys %$ground) {
                my @selected = length($key) ? split(/,/,$key) : ();
                my %stats;
                my $got=countWeavingSuffixPolynomial($prefix,\@selected,\%stats);
                is("$got","$ground->{$key}",
                    '前綴完工數與完整枚舉一致：'
                     .join('-',@$prefix).' / '.$key);
                is($stats{days_remaining}+@selected,
                   do { my $days=0; $days+=$_ for @$prefix; $days },
                   '診斷中剩餘日數與原始總數守恆');
                $cases++;
            }
            return;
        }
        $generate->([@$prefix,$_]) for 1 .. 3;
    };
    $generate->([]);
}
cmp_ok($cases,'>=',1500,'至少比較 1500 組不同合法前綴');
for my $lengths (
    [4,4,4],
    [4,123,4],
    [(4)x47],
    [68,(4)x46],
) {
    my $all=countWeavingsPolynomial($lengths);
    is(''.countWeavingSuffixPolynomial($lengths,[]),"$all",
        '空前綴不影響多項式精確總數');
    my $first=countWeavingSuffixPolynomial($lengths,[1]);
    is("$first","$all",
        '第一日必屬首月，首日固定後總數保持不變');
}
for my $prefix (
    [2], [1,3], [1,2,2], [1,1,1,1,1],
    [1,2,2,1], [1,2,3,2,1,2],
) {
    my $ok=eval { countWeavingSuffixPolynomial([4,2,2],$prefix);1 };
    ok(!$ok,'無法出現的月份前綴會被拒絕');
    like($@,qr/月份前綴/,'前綴錯誤保留明確診斷');
}
for my $bad (undef,{},'hello') {
    my $ok=eval { countWeavingSuffixPolynomial([4,4],$bad);1 };
    ok(!$ok,'非陣列前綴會被拒絕');
}
done_testing;
