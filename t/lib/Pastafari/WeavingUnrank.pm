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
    # 字典序第一名可直接寫出每個月份的完整連續區塊：
    # 1..m 的月份標籤最小，先使用較小月份的全部日子
    # 永遠不會違反首次或末次出現次序。
    # 仍先執行全域精確計數及排名驗證，以確保錯誤契約不變。
    if ($rank == 1) {
        my @first;
        for my $j (1 .. $m) {
            push @first, (($j) x $remaining[$j-1]);
        }
        if (defined $stats) {
            %$stats = (days => $days, suffix_calls => 0,
                       considered => $days, shortcut_steps => $days,
                       first_rank_fastpath => 1);
        }
        return \@first;
    }
    my @word;
    my $current_total = $total->copy;
    my ($calls,$considered,$shortcut_steps)=(0,0,0);
    for my $step (1 .. $days) {
        my $upper = $opened < $m ? $opened+1 : $m;
        my @eligible;
        for my $j (1 .. $upper) {
            next if !$remaining[$j-1];
            next if $remaining[$j-1] == 1 && $j != $closed+1;
            push @eligible,$j;
        }
        die "交織字典序解碼無合法選擇\n" if !@eligible;
        # 子樹的大小把母前綴的完成集合劃分為互不相交的部分。
        # 最後一個候選之大小等於母前綴減去前面候選的大小；
        # 若只有一個候選，更可完全免去這一步的後綴 DP 計算。
        my $remaining_ways = $current_total->copy;
        my $accepted = 0;
        for my $i (0 .. $#eligible) {
            my $j = $eligible[$i];
            $considered++;
            push @word, $j;
            my $ways;
            if ($i == $#eligible) {
                $ways = $remaining_ways->copy;
                $shortcut_steps++;
            } else {
                $ways = countWeavingSuffixPolynomial($lengths,\@word);
                $calls++;
                $remaining_ways->bsub($ways);
            }
            die "交織候選分割計數不一致\n" if $ways < 0;
            if ($rank <= $ways) {
                $current_total = $ways->copy;
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
    die "交織解碼終點計數不為一\n" if $current_total != 1;
    if (defined $stats) {
        %$stats = (days => $days, suffix_calls => $calls,
                   considered => $considered, shortcut_steps => $shortcut_steps,
                   first_rank_fastpath => 0);
    }
    return \@word;
}

1;
