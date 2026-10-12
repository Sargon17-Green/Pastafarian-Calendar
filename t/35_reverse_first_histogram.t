use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib','t/lib';
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::WeavingSuffixFactor qw(countWeavingSuffixFactored);
use Pastafari::WeavingSuffix qw(countWeavingSuffixPolynomial);

# 獨立枚舉合法完整序列，而非呼叫多項式轉移。
sub brute_first_hist ($lengths) {
    my @rem=@$lengths;
    my @word;
    my %hist;
    my $m=@$lengths;
    my $walk;
    $walk=sub ($opened,$closed) {
        if (!grep { $_ } @rem) {
            for my $pos (0 .. $#word) {
                if ($word[$pos]==$m) {
                    $hist{$pos+1}++;
                    last;
                }
            }
            return;
        }
        for my $j (1 .. $m) {
            next if !$rem[$j-1];
            my ($o,$c)=($opened,$closed);
            if ($rem[$j-1]==$lengths->[$j-1]) {
                next if $j!=$opened+1;
                $o=$j;
            }
            if ($rem[$j-1]==1) {
                next if $j!=$closed+1;
                $c=$j;
            }
            $rem[$j-1]--;
            push @word,$j;
            $walk->($o,$c);
            pop @word;
            $rem[$j-1]++;
        }
    };
    $walk->(0,0);
    return \%hist;
}

my $checks=0;
for my $lengths ([1],[1,1],[2,1],[1,2],[2,2],[2,2,2],
                 [3,2,2],[2,3,2],[2,2,2,2],[3,2,3,2]) {
    my @all_hist;
    my $total=countWeavingsPolynomial($lengths,undef,\@all_hist);
    for my $stage (1 .. @$lengths) {
        my @prefix=@$lengths[0 .. $stage-1];
        my $independent=brute_first_hist(\@prefix);
        my $hist=$all_hist[$stage];
        my $reconstructed=Math::BigInt->bzero;
        for my $u (1 .. @$hist-1) {
            my $observed=$hist->[$u] // Math::BigInt->bzero;
            is("$observed",($independent->{$u}//0),
                '每個階段最後一月首日位置與獨立完整枚舉一致：'
                    .join('-',@prefix)."/$u");
            $reconstructed->badd($observed);
            $checks++;
        }
        is("$reconstructed",''.countWeavingsPolynomial(\@prefix),
            '邊際位置直方圖總量等於獨立全域計數');
    }
    my %details;
    countWeavingsPolynomial($lengths,\%details);
    is("$total",''.countWeavingsPolynomial($lengths),
        '有無位置側通道不改變任何全域數值');
}
cmp_ok($checks,'>=',60,'獨立驗證至少六十個首日位置數據');

# 共享直方圖只建立一次，且不同 (opened,T) 的後續計數
# 仍維持精確：本例 opened=3，T=8 與 7。
my @lengths=(4)x6;
my %shared;
my %diag;
for my $prefix ([1,2,3,1],[1,2,3,2],[1,2,3,3],
                [1,2,3,1,2]) {
    my $actual=countWeavingSuffixFactored(\@lengths,$prefix,
                                           \%shared,\%diag);
    is("$actual",''.countWeavingSuffixPolynomial(\@lengths,$prefix),
        '同一反序直方圖支援不同未開啟月份及不同 T 的前綴');
}
is($diag{profile_builds},1,'僅一次多項式反序 DP 建構全部階段直方圖');
cmp_ok($diag{future_cache_hits},'>=',2,'同狀態後綴因子精確重用');
cmp_ok($diag{future_cache_misses},'>=',2,'不同 T 以直方圖求得精確因子');

my @large=(4)x47;
my %large_cache;
my %large_diagnostics;
for my $prefix ([1,2,3],[1,2,3,1],[1,2,3,4]) {
    my $actual=countWeavingSuffixFactored(\@large,$prefix,
                                           \%large_cache,\%large_diagnostics);
    is("$actual",''.countWeavingSuffixPolynomial(\@large,$prefix),
        '47 月份的反序位置直方圖計數與原模型一致');
}
is($large_diagnostics{profile_builds},1,
    '47 月份不同前綴僅用一次原始反序 DP');
done_testing;
