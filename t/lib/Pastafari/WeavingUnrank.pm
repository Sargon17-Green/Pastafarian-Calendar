package Pastafari::WeavingUnrank;
use v5.40;
use utf8;
use strict;
use warnings;
use Math::BigInt;
use Scalar::Util qw(blessed);
use Exporter 'import';
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::WeavingSuffixFactor qw(countWeavingSuffixFactored);

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
                       first_rank_fastpath => 1, last_rank_fastpath => 0);
        }
        return \@first;
    }
    # 字典序最後一名可貪婪地選擇「目前可用的最大月份」。
    # 任何符合局部首次/末次次序的前綴均有完工方法：
    # 先按次序結束所有已開啟月份，再依序開啟、結束其餘月份。
    # 因此最大合法下一月份的子樹必非空，可反覆選取而無須
    # 重新計算任何前綴完工數。
    if ($rank == $total) {
        my @last;
        for my $step (1 .. $days) {
            my $upper = $opened < $m ? $opened+1 : $m;
            my $selected;
            for (my $j = $upper; $j >= 1; $j--) {
                next if !$remaining[$j-1];
                next if $remaining[$j-1] == 1 && $j != $closed+1;
                $selected = $j;
                last;
            }
            die "交織最後排名無合法選擇\n" if !defined $selected;
            push @last,$selected;
            $opened = $selected if $selected > $opened;
            $remaining[$selected-1]--;
            $closed = $selected if !$remaining[$selected-1];
        }
        die "交織最後排名的月份尚未全部關閉\n" if $closed != $m;
        if (defined $stats) {
            %$stats = (days => $days, suffix_calls => 0,
                       considered => $days, shortcut_steps => $days,
                       first_rank_fastpath => 0, last_rank_fastpath => 1);
        }
        return \@last;
    }
    my @word;
    my $current_total = $total->copy;
    my ($calls,$considered,$shortcut_steps)=(0,0,0);
    my (%future_cache,%factor_diagnostics);
    my ($tail_shortcut_days,$tail_shortcut_kind)=(0,0);
    for my $step (1 .. $days) {
        # 即使最初排名並非 1 或總數，已接受某個較小的字典序
        # 區塊後，其剩餘的一基局部排名也可能恰為 1 或目前區塊
        # 總數。此時不再逐日重新計算後綴，而可在剩餘序列中
        # 按最小／最大合法下一標籤直接走到葉節點。
        if ($rank == 1 || $rank == $current_total) {
            my $choose_largest = $rank != 1;
            $tail_shortcut_kind = $choose_largest ? 2 : 1;
            for my $remaining_step ($step .. $days) {
                my $upper = $opened < $m ? $opened+1 : $m;
                my $chosen;
                if ($choose_largest) {
                    for (my $j=$upper; $j>=1; $j--) {
                        next if !$remaining[$j-1];
                        next if $remaining[$j-1]==1 && $j!=$closed+1;
                        $chosen=$j;
                        last;
                    }
                } else {
                    for my $j (1 .. $upper) {
                        next if !$remaining[$j-1];
                        next if $remaining[$j-1]==1 && $j!=$closed+1;
                        $chosen=$j;
                        last;
                    }
                }
                die "交織局部排名捷徑沒有合法延伸\n"
                    if !defined $chosen;
                push @word,$chosen;
                $opened=$chosen if $chosen>$opened;
                $remaining[$chosen-1]--;
                $closed=$chosen if !$remaining[$chosen-1];
                $considered++;
                $shortcut_steps++;
                $tail_shortcut_days++;
            }
            $current_total=Math::BigInt->bone;
            last;
        }
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
                $ways = countWeavingSuffixFactored(
                    $lengths,\@word,\%future_cache,\%factor_diagnostics
                );
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
                   first_rank_fastpath => 0, last_rank_fastpath => 0,
                   tail_shortcut_days => $tail_shortcut_days,
                   tail_shortcut_kind => $tail_shortcut_kind,
                   future_cache_hits => ($factor_diagnostics{future_cache_hits}//0),
                   future_cache_misses => ($factor_diagnostics{future_cache_misses}//0),
                   factored_suffix_calls => ($factor_diagnostics{factor_calls}//0),
                   reverse_histogram_builds => ($factor_diagnostics{profile_builds}//0));
    }
    return \@word;
}

1;
