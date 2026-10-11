package Pastafari::WeavingUnrank;
use v5.40;
use utf8;
use strict;
use warnings;
use Math::BigInt;
use Scalar::Util qw(blessed);
use Exporter 'import';
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::WeavingSuffix qw(countWeavingSuffixPolynomial);

our @EXPORT_OK = qw(unrankWeavingPolynomial);

# 第一階段驗證用，不是生產程式。對每一步按月份標籤字典序嘗試
# 合法候選，透過多項式「指定前綴的完工數」比較一基排名。
# 計數器的每次呼叫都獨立，不跨日期共用可變狀態。
sub unrankWeavingPolynomial ($lengths, $rank1, $stats = undef) {
    die "診斷記錄必須是雜湊參照\n"
        if defined($stats) && ref($stats) ne 'HASH';
    die "交織排名必須是正整數\n"
        if !defined($rank1)
        || (ref($rank1) && !(blessed($rank1) && $rank1->isa('Math::BigInt')))
        || "$rank1" !~ /\A[0-9]+\z/;
    my $rank = Math::BigInt->new("$rank1");
    my $total = countWeavingsPolynomial($lengths);
    die "交織排名超出範圍\n" if $rank < 1 || $rank > $total;

    my @remaining = map { 0+"$_" } @$lengths;
    my $m = scalar @remaining;
    my $days = 0; $days += $_ for @remaining;
    my ($opened,$closed) = (0,0);
    my @word;
    my ($calls,$considered)=(0,0);
    for my $step (1 .. $days) {
        my $upper = $opened < $m ? $opened+1 : $m;
        my $accepted = 0;
        for my $j (1 .. $upper) {
            next if !$remaining[$j-1];
            next if $remaining[$j-1] == 1 && $j != $closed+1;
            $considered++;
            push @word, $j;
            my $ways = countWeavingSuffixPolynomial($lengths,\@word);
            $calls++;
            if ($rank <= $ways) {
                $remaining[$j-1]--;
                $opened = $j if $j > $opened;
                $closed = $j if !$remaining[$j-1];
                $accepted = 1;
                last;
            }
            $rank->bsub($ways);
            pop @word;
        }
        die "交織字典序解碼無合法選擇\n" if !$accepted;
    }
    die "交織解碼後仍有月份未結束\n" if $closed != $m;
    if (defined $stats) {
        %$stats = (days => $days, suffix_calls => $calls,
                   considered => $considered);
    }
    return \@word;
}

1;
